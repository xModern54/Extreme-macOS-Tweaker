import SwiftUI

@main
struct ExtremeMacTweakerApp: App {
  @StateObject private var optimizationStore = OptimizationStore()
  @StateObject private var catalogStore = TweakCatalogStore()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(optimizationStore)
        .environmentObject(catalogStore)
        .frame(minWidth: 880, minHeight: 540)
        .background(
          InitialWindowConfiguration(width: 920, height: 592)
        )
    }
    .defaultSize(width: 920, height: 592)
    .windowResizability(.contentMinSize)
    .windowStyle(.hiddenTitleBar)
  }
}
