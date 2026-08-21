import CleanSweepCore
import Foundation

enum CLIError: Error, CustomStringConvertible {
  case usage(String)
  case missingOption(String)
  case unknownCommand(String)

  var description: String {
    switch self {
    case .usage(let message):
      message
    case .missingOption(let name):
      "Missing --\(name)."
    case .unknownCommand(let command):
      "Unknown command: \(command)."
    }
  }

  var exitCode: Int32 { 2 }
}

@main
enum CleanSweepCLI {
  static func main() {
    do {
      try run(Array(CommandLine.arguments.dropFirst()))
    } catch let error as CLIError {
      fputs("error: \(error)\n", stderr)
      if case .usage = error {
        fputs(usage, stderr)
      }
      exit(error.exitCode)
    } catch let error as CleanSweepError {
      fputs("error: \(error)\n", stderr)
      exit(20)
    } catch {
      fputs("error: \(error.localizedDescription)\n", stderr)
      exit(1)
    }
  }

  static func run(_ arguments: [String]) throws {
    guard let command = arguments.first else {
      throw CLIError.usage("No command specified.")
    }

    let rest = Array(arguments.dropFirst())
    switch command {
    case "help", "-h", "--help":
      fputs(usage, stdout)
    case "inspect":
      try inspect(options: parseOptions(rest))
    case "verify":
      try verify(options: parseOptions(rest))
    case "neutralize":
      try neutralize(options: parseOptions(rest))
    case "restore":
      try restore(options: parseOptions(rest))
    case "diff":
      try diff(options: parseOptions(rest))
    default:
      throw CLIError.unknownCommand(command)
    }
  }

  static func inspect(options: [String: [String]]) throws {
    let cache = try LaunchdServiceCache(contentsOf: requiredURL("cache", in: options))
    print("VersionNumber \(cache.versionNumber)")
    print("jobs \(cache.jobCount)")
    print("unique labels \(cache.uniqueLabelCount)")
    for item in cache.pathPrefixCounts {
      print("prefix \(item.count)  \(item.prefix)")
    }
    if let labels = options["label"] {
      for label in labels {
        let jobs = cache.jobs(label: label)
        if jobs.isEmpty {
          print("label \(label)  not found")
        } else {
          for job in jobs {
            print("label \(job.label)  \(job.cacheKey)  keys \(job.entry.count)")
          }
        }
      }
    }
  }

  static func verify(options: [String: [String]]) throws {
    let url = try requiredURL("cache", in: options)
    let cache = try LaunchdServiceCache(contentsOf: url)
    print("ok  VersionNumber \(cache.versionNumber)  jobs \(cache.jobCount)")
  }

  static func neutralize(options: [String: [String]]) throws {
    let input = try requiredURL("cache", in: options)
    let output = try requiredURL("out", in: options)
    let stashURL = try requiredURL("stash", in: options)
    let selectors = try selectors(from: options)
    let enforcePolicy = !flag("allow-critical", in: options)

    let before = try LaunchdServiceCache(contentsOf: input)
    let (after, extracted) = try before.neutralize(
      selectors: selectors,
      enforcePolicy: enforcePolicy
    )
    try after.writeAtomically(to: output)
    try extracted.writeAtomically(to: stashURL)

    let diff = CacheDiff.compare(before: before, after: after)
    print("neutralized \(extracted.jobs.count)")
    print("jobs \(before.jobCount) -> \(after.jobCount)")
    print(diff.summary)
  }

  static func restore(options: [String: [String]]) throws {
    let input = try requiredURL("cache", in: options)
    let output = try requiredURL("out", in: options)
    let stash = try ExtractedJobs(contentsOf: try requiredURL("stash", in: options))
    let before = try LaunchdServiceCache(contentsOf: input)
    let after = try before.restore(stash)
    try after.writeAtomically(to: output)
    let diff = CacheDiff.compare(before: before, after: after)
    print("restored \(stash.jobs.count)")
    print("jobs \(before.jobCount) -> \(after.jobCount)")
    print(diff.summary)
  }

  static func diff(options: [String: [String]]) throws {
    let before = try LaunchdServiceCache(contentsOf: try requiredURL("before", in: options))
    let after = try LaunchdServiceCache(contentsOf: try requiredURL("after", in: options))
    print(CacheDiff.compare(before: before, after: after).summary)
  }

  static func selectors(from options: [String: [String]]) throws -> [JobSelector] {
    var result: [JobSelector] = []
    for label in options["label"] ?? [] {
      result.append(.label(label))
    }
    for key in options["key"] ?? [] {
      result.append(.cacheKey(key))
    }
    guard !result.isEmpty else {
      throw CLIError.usage("Specify at least one --label or --key.")
    }
    return result
  }

  static func parseOptions(_ arguments: [String]) throws -> [String: [String]] {
    var options: [String: [String]] = [:]
    var index = 0
    while index < arguments.count {
      let argument = arguments[index]
      guard argument.hasPrefix("--") else {
        throw CLIError.usage("Unexpected argument: \(argument)")
      }
      let name = String(argument.dropFirst(2))
      if name == "allow-critical" {
        options[name, default: []].append("true")
        index += 1
        continue
      }
      index += 1
      guard index < arguments.count else {
        throw CLIError.missingOption(name)
      }
      options[name, default: []].append(arguments[index])
      index += 1
    }
    return options
  }

  static func requiredURL(_ name: String, in options: [String: [String]]) throws -> URL {
    guard let value = options[name]?.last, !value.isEmpty else {
      throw CLIError.missingOption(name)
    }
    return URL(fileURLWithPath: value)
  }

  static func flag(_ name: String, in options: [String: [String]]) -> Bool {
    options[name] != nil
  }

  static let usage = """
    usage: cleansweep <command> [options]

    commands:
      inspect     --cache <plist> [--label <label>]...
      verify      --cache <plist>
      neutralize  --cache <plist> --out <plist> --stash <plist>
                  (--label <label> | --key <path>)... [--allow-critical]
      restore     --cache <plist> --out <plist> --stash <plist>
      diff        --before <plist> --after <plist>

    """
}
