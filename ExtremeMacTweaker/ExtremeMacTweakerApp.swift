import SwiftUI

@main
struct ExtremeMacTweakerApp: App {
  var body: some Scene {
    WindowGroup {
      RootView()
        .frame(minWidth: 920, minHeight: 600)
    }
    .defaultSize(width: 1180, height: 760)
    .windowResizability(.contentMinSize)
    .commands {
      SidebarCommands()
    }
  }
}
