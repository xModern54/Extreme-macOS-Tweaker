public enum CleanSweepPolicy {
  public static let forbiddenLabels: Set<String> = [
    "com.apple.WindowServer",
    "com.apple.loginwindow",
    "com.apple.opendirectoryd",
    "com.apple.logd",
    "com.apple.notifyd",
    "com.apple.configd",
    "com.apple.runningboardd",
    "com.apple.UserEventAgent-System",
    "com.apple.coreservicesd",
    "com.apple.kernelmanagerd",
    "com.apple.securityd",
    "com.apple.trustd",
    "com.apple.security.cryptexd",
    "com.apple.watchdogd",
  ]

  public static func forbids(label: String) -> Bool {
    forbiddenLabels.contains(label)
  }
}
