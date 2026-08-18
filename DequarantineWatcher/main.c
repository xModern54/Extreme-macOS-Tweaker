#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <dispatch/dispatch.h>

#include <errno.h>
#include <fts.h>
#include <limits.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/xattr.h>
#include <unistd.h>

static const char *kQuarantineXattr = "com.apple.quarantine";

// Batch a download burst into one wakeup. NoDefer is intentionally off so
// the process stays asleep until this window closes.
static const CFTimeInterval kEventLatencySeconds = 1.0;

static char *g_watch_path = NULL;

static bool is_skippable_name(const char *name);
static const char *last_path_component(const char *path);
static void set_thread_disk_policy(int policy);
static void scrub_one(const char *path);
static void scrub_tree(const char *root);
static void fs_callback(
    ConstFSEventStreamRef stream,
    void *info,
    size_t count,
    void *eventPaths,
    const FSEventStreamEventFlags flags[],
    const FSEventStreamEventId ids[]
);

static const char *last_path_component(const char *path) {
    const char *slash = strrchr(path, '/');
    return slash ? slash + 1 : path;
}

static bool is_skippable_name(const char *name) {
    if (name == NULL || name[0] == '\0') {
        return false;
    }
    if (strcmp(name, ".DS_Store") == 0
        || strcmp(name, ".localized") == 0
        || strcmp(name, "Icon\r") == 0) {
        return true;
    }

    static const char *suffixes[] = {
        ".crdownload",
        ".part",
        ".partial",
        ".download",
    };
    size_t name_len = strlen(name);
    for (size_t index = 0; index < sizeof(suffixes) / sizeof(suffixes[0]); index++) {
        size_t suffix_len = strlen(suffixes[index]);
        if (name_len > suffix_len
            && strcmp(name + name_len - suffix_len, suffixes[index]) == 0) {
            return true;
        }
    }
    return false;
}

static void set_thread_disk_policy(int policy) {
    (void)setiopolicy_np(IOPOL_TYPE_DISK, IOPOL_SCOPE_THREAD, policy);
}

static void scrub_one(const char *path) {
    if (removexattr(path, kQuarantineXattr, XATTR_NOFOLLOW) == 0) {
        return;
    }
    if (errno != ENOATTR && errno != ENOENT && errno != EPERM && errno != EACCES) {
        fprintf(stderr, "removexattr(%s): %s\n", path, strerror(errno));
    }
}

static void scrub_tree(const char *root) {
    char path_buf[PATH_MAX];
    if (root == NULL || root[0] == '\0') {
        return;
    }
    if (strlcpy(path_buf, root, sizeof(path_buf)) >= sizeof(path_buf)) {
        fprintf(stderr, "path too long: %s\n", root);
        return;
    }

    char *paths[] = { path_buf, NULL };
    FTS *fts = fts_open(paths, FTS_PHYSICAL | FTS_NOCHDIR | FTS_XDEV, NULL);
    if (fts == NULL) {
        if (errno != ENOENT) {
            fprintf(stderr, "fts_open(%s): %s\n", root, strerror(errno));
        }
        return;
    }

    errno = 0;
    FTSENT *entry;
    while ((entry = fts_read(fts)) != NULL) {
        switch (entry->fts_info) {
            case FTS_D:
            case FTS_F:
            case FTS_SL:
            case FTS_SLNONE:
            case FTS_DEFAULT:
                if (entry->fts_level > 0 && is_skippable_name(entry->fts_name)) {
                    if (entry->fts_info == FTS_D) {
                        (void)fts_set(fts, entry, FTS_SKIP);
                    }
                    continue;
                }
                if (entry->fts_info == FTS_D || entry->fts_info == FTS_F
                    || entry->fts_info == FTS_SL || entry->fts_info == FTS_SLNONE) {
                    scrub_one(entry->fts_accpath);
                }
                break;
            default:
                break;
        }
    }
    if (errno != 0 && errno != ENOENT) {
        fprintf(stderr, "fts_read(%s): %s\n", root, strerror(errno));
    }
    (void)fts_close(fts);
}

static void fs_callback(
    ConstFSEventStreamRef stream,
    void *info,
    size_t count,
    void *eventPaths,
    const FSEventStreamEventFlags flags[],
    const FSEventStreamEventId ids[]
) {
    (void)stream;
    (void)info;
    (void)ids;

    char **paths = eventPaths;
    for (size_t index = 0; index < count; index++) {
        const char *path = paths[index];
        FSEventStreamEventFlags eventFlags = flags[index];

        if (eventFlags & kFSEventStreamEventFlagRootChanged) {
            scrub_tree(g_watch_path);
            continue;
        }

        if (eventFlags & (
                kFSEventStreamEventFlagMustScanSubDirs
                | kFSEventStreamEventFlagKernelDropped
                | kFSEventStreamEventFlagUserDropped
                | kFSEventStreamEventFlagEventIdsWrapped
            )) {
            const char *target = (path != NULL && path[0] != '\0') ? path : g_watch_path;
            scrub_tree(target);
            continue;
        }

        if (eventFlags & (
                kFSEventStreamEventFlagMount
                | kFSEventStreamEventFlagUnmount
            )) {
            if (path != NULL && path[0] != '\0') {
                scrub_one(path);
            }
            continue;
        }

        const FSEventStreamEventFlags interesting =
            kFSEventStreamEventFlagItemCreated
            | kFSEventStreamEventFlagItemRenamed
            | kFSEventStreamEventFlagItemXattrMod;
        if ((eventFlags & interesting) == 0) {
            continue;
        }

        if (path == NULL || path[0] == '\0') {
            continue;
        }
        if (is_skippable_name(last_path_component(path))) {
            continue;
        }

        const bool is_dir = (eventFlags & kFSEventStreamEventFlagItemIsDir) != 0;
        const bool arrived = (eventFlags & (
                kFSEventStreamEventFlagItemCreated
                | kFSEventStreamEventFlagItemRenamed
            )) != 0;

        // A directory that just appeared may already contain files that do
        // not get their own events. An xattr-only change on a folder must
        // not walk the subtree — Finder tags would otherwise rescan Downloads.
        if (is_dir && arrived) {
            scrub_tree(path);
        } else {
            scrub_one(path);
        }
    }
}

static int resolve_watch_path(const char *input) {
    char resolved[PATH_MAX];
    if (realpath(input, resolved) == NULL) {
        fprintf(stderr, "not a directory: %s\n", input);
        return 1;
    }

    struct stat watch_info;
    if (stat(resolved, &watch_info) != 0 || !S_ISDIR(watch_info.st_mode)) {
        fprintf(stderr, "not a directory: %s\n", resolved);
        return 1;
    }

    g_watch_path = strdup(resolved);
    if (g_watch_path == NULL) {
        fprintf(stderr, "strdup failed\n");
        return 1;
    }
    return 0;
}

int main(int argc, char **argv) {
    bool once = false;
    const char *input_path = NULL;
    if (argc == 3 && strcmp(argv[1], "--once") == 0) {
        once = true;
        input_path = argv[2];
    } else if (argc == 2) {
        input_path = argv[1];
    } else {
        fprintf(stderr, "usage: %s [--once] <directory>\n", argv[0]);
        return 1;
    }

    if (resolve_watch_path(input_path) != 0) {
        return 1;
    }

    if (once) {
        set_thread_disk_policy(IOPOL_UTILITY);
        scrub_tree(g_watch_path);
        return 0;
    }

    CFStringRef path = CFStringCreateWithCString(NULL, g_watch_path, kCFStringEncodingUTF8);
    if (!path) {
        fprintf(stderr, "CFStringCreateWithCString failed\n");
        return 1;
    }

    const void *values[] = { path };
    CFArrayRef paths = CFArrayCreate(NULL, values, 1, &kCFTypeArrayCallBacks);
    CFRelease(path);
    if (!paths) {
        fprintf(stderr, "CFArrayCreate failed\n");
        return 1;
    }

    FSEventStreamCreateFlags create_flags =
        kFSEventStreamCreateFlagFileEvents
        | kFSEventStreamCreateFlagIgnoreSelf
        | kFSEventStreamCreateFlagWatchRoot;
    FSEventStreamRef stream = FSEventStreamCreate(
        NULL,
        fs_callback,
        NULL,
        paths,
        kFSEventStreamEventIdSinceNow,
        kEventLatencySeconds,
        create_flags
    );
    CFRelease(paths);
    if (!stream) {
        fprintf(stderr, "FSEventStreamCreate failed\n");
        return 1;
    }

    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(
        DISPATCH_QUEUE_SERIAL,
        QOS_CLASS_UTILITY,
        0
    );
    dispatch_queue_t queue = dispatch_queue_create(
        "com.extrememactweaker.dequarantine",
        attr
    );
    FSEventStreamSetDispatchQueue(stream, queue);

    if (!FSEventStreamStart(stream)) {
        fprintf(stderr, "FSEventStreamStart failed\n");
        return 1;
    }

    dispatch_async(queue, ^{
        set_thread_disk_policy(IOPOL_UTILITY);
        scrub_tree(g_watch_path);
        set_thread_disk_policy(IOPOL_DEFAULT);
    });

    dispatch_main();
    return 0;
}
