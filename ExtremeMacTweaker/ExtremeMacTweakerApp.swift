import SwiftUI

@main
struct ExtremeMacTweakerApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
        .frame(minWidth: 880, minHeight: 540)
    }
    .defaultSize(width: 1200, height: 660)
    .windowResizability(.contentMinSize)
    .windowToolbarStyle(.unified)
    .commands {
      SidebarCommands()
    }
  }
}
