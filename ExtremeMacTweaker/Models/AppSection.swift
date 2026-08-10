import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
  case systemTweaker
  case systemApps
  case systemDebloat
  case security

  var id: Self { self }

  var title: String {
    switch self {
    case .systemTweaker:
      "System Tweaker"
    case .systemApps:
      "System Apps"
    case .systemDebloat:
      "System Debloat"
    case .security:
      "Security"
    }
  }

  var systemImage: String {
    switch self {
    case .systemTweaker:
      "slider.horizontal.3"
    case .systemApps:
      "square.grid.2x2"
    case .systemDebloat:
      "shippingbox"
    case .security:
      "shield.lefthalf.filled"
    }
  }
}
