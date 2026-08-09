import SwiftUI

@main
struct ExtremeMacTweakerApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
        .frame(minWidth: 880, minHeight: 540)
        .background(
          InitialWindowConfiguration(width: 920, height: 592)
        )
    }
    .defaultSize(width: 920, height: 592)
    .windowResizability(.contentMinSize)
    .windowToolbarStyle(.unified)
  }
}
