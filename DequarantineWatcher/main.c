#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <dispatch/dispatch.h>

#include <errno.h>
#include <ftw.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/xattr.h>
#include <unistd.h>

static const char *kQuarantineXattr = "com.apple.quarantine";

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

static int nftw_callback(
    const char *path,
    const struct stat *info,
    int typeflag,
    struct FTW *ftw
) {
    (void)info;
    (void)ftw;
    if (typeflag == FTW_F || typeflag == FTW_D || typeflag == FTW_DP
        || typeflag == FTW_SL || typeflag == FTW_SLN) {
        scrub_one(path);
    }
    return 0;
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
    if (nftw(root, nftw_callback, 16, FTW_PHYS) != 0 && errno != ENOENT) {
        fprintf(stderr, "nftw(%s): %s\n", root, strerror(errno));
    }
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

        if (eventFlags & kFSEventStreamEventFlagMustScanSubDirs) {
            scrub_tree(path);
            continue;
        }

        const FSEventStreamEventFlags interesting =
            kFSEventStreamEventFlagItemCreated
            | kFSEventStreamEventFlagItemRenamed
            | kFSEventStreamEventFlagItemXattrMod;
        if ((eventFlags & interesting) == 0) {
            continue;
        }

        if (!(eventFlags & kFSEventStreamEventFlagItemIsFile)
            && !(eventFlags & kFSEventStreamEventFlagItemIsDir)
            && !(eventFlags & kFSEventStreamEventFlagItemIsSymlink)) {
            scrub_tree(path);
            continue;
        }

        if (eventFlags & kFSEventStreamEventFlagItemIsDir) {
            scrub_tree(path);
        } else {
            scrub_one(path);
        }
    }
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s <directory>\n", argv[0]);
        return 1;
    }

    const char *watchPath = argv[1];
    struct stat watchInfo;
    if (stat(watchPath, &watchInfo) != 0 || !S_ISDIR(watchInfo.st_mode)) {
        fprintf(stderr, "not a directory: %s\n", watchPath);
        return 1;
    }

    CFStringRef path = CFStringCreateWithCString(NULL, watchPath, kCFStringEncodingUTF8);
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

    FSEventStreamCreateFlags createFlags =
        kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer;
    FSEventStreamRef stream = FSEventStreamCreate(
        NULL,
        fs_callback,
        NULL,
        paths,
        kFSEventStreamEventIdSinceNow,
        0.1,
        createFlags
    );
    CFRelease(paths);
    if (!stream) {
        fprintf(stderr, "FSEventStreamCreate failed\n");
        return 1;
    }

    dispatch_queue_t queue = dispatch_queue_create(
        "com.extrememactweaker.dequarantine",
        DISPATCH_QUEUE_SERIAL
    );
    FSEventStreamSetDispatchQueue(stream, queue);

    if (!FSEventStreamStart(stream)) {
        fprintf(stderr, "FSEventStreamStart failed\n");
        return 1;
    }

    dispatch_async(queue, ^{
        scrub_tree(watchPath);
    });

    dispatch_main();
    return 0;
}
