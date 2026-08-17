import Foundation

enum SystemProtectionOutputParser {
  static func systemIntegrityProtectionAllowsModifications(_ output: String) -> Bool {
    let lines = output.split(separator: "\n").map {
      $0.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    guard let statusLine = lines.first(where: {
      $0.localizedCaseInsensitiveContains("System Integrity Protection status:")
    }) else {
      return false
    }

    let isCustom = statusLine.localizedCaseInsensitiveContains("Custom Configuration")
    let statusDisabled = statusLine.range(
      of: #"status:\s*disabled"#,
      options: [.regularExpression, .caseInsensitive]
    ) != nil

    if statusDisabled, !isCustom {
      return true
    }

    guard isCustom else { return false }
    return lines.contains { line in
      line.localizedCaseInsensitiveContains("Filesystem Protections:")
        && line.range(
          of: #"Filesystem Protections:\s*disabled"#,
          options: [.regularExpression, .caseInsensitive]
        ) != nil
    }
  }

  static func authenticatedRootIsDisabled(_ output: String) -> Bool {
    let lines = output.split(separator: "\n").map {
      $0.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    let statusLine = lines.first(where: {
      $0.localizedCaseInsensitiveContains("Authenticated Root status:")
    }) ?? lines.first(where: {
      $0.localizedCaseInsensitiveContains("status:")
    })
    guard let statusLine else { return false }
    return statusLine.range(
      of: #"status:\s*disabled"#,
      options: [.regularExpression, .caseInsensitive]
    ) != nil
  }
}
