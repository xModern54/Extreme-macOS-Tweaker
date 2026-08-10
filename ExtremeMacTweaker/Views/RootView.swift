import SwiftUI

struct RootView: View {
  @State private var selection: AppSection? = .systemTweaker

  var body: some View {
    NavigationSplitView(columnVisibility: .constant(.all)) {
      SidebarView(selection: $selection)
        .navigationSplitViewColumnWidth(min: 200, ideal: 232, max: 272)
        .toolbar(removing: .sidebarToggle)
    } detail: {
      DetailWorkspace(section: selection ?? .systemTweaker)
    }
    .navigationSplitViewStyle(.balanced)
    .tint(.accentColor)
  }
}

private struct DetailWorkspace: View {
  let section: AppSection

  var body: some View {
    ZStack {
      Color(nsColor: .windowBackgroundColor)
        .ignoresSafeArea()

      switch section {
      case .systemTweaker:
        SystemTweakerView()
      case .systemApps:
        SystemAppsView()
      case .systemDebloat:
        SystemDebloatView()
      case .security:
        SecurityView()
      }
    }
    .navigationTitle("Tweaker")
    .toolbarTitleDisplayMode(.inline)
  }
}

#Preview {
  RootView()
    .environmentObject(OptimizationStore())
    .frame(width: 920, height: 592)
}
