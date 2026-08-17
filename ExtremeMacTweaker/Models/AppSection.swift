import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
  case dashboard
  case systemTweaker
  case systemApps
  case systemDebloat
  case security
  case recoveryGuide

  var id: Self { self }

  static var featureCases: [AppSection] {
    [.systemTweaker, .systemApps, .systemDebloat, .security]
  }

  static var helpCases: [AppSection] {
    [.recoveryGuide]
  }

  var title: String {
    switch self {
    case .dashboard:
      "Dashboard"
    case .systemTweaker:
      "System Tweaker"
    case .systemApps:
      "System Apps"
    case .systemDebloat:
      "System Debloat"
    case .security:
      "Security"
    case .recoveryGuide:
      "Disable SIP"
    }
  }

  var systemImage: String {
    switch self {
    case .dashboard:
      "gauge.with.needle"
    case .systemTweaker:
      "slider.horizontal.3"
    case .systemApps:
      "square.grid.2x2"
    case .systemDebloat:
      "shippingbox"
    case .security:
      "shield.lefthalf.filled"
    case .recoveryGuide:
      "lock.open"
    }
  }
}
