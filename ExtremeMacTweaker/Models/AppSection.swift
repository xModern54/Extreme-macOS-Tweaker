import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
  case tweaker
  case systemApps

  var id: Self { self }

  var title: String {
    switch self {
    case .tweaker:
      "Tweaker"
    case .systemApps:
      "System Apps"
    }
  }

  var subtitle: String {
    switch self {
    case .tweaker:
      "macOS Optimization"
    case .systemApps:
      "Removal & Disabling"
    }
  }

  var systemImage: String {
    switch self {
    case .tweaker:
      "slider.horizontal.3"
    case .systemApps:
      "square.grid.2x2"
    }
  }
}
