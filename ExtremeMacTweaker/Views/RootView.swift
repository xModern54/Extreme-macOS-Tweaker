import SwiftUI

struct RootView: View {
  @State private var selection: AppSection? = .tweaker
  @State private var columnVisibility: NavigationSplitViewVisibility = .all

  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      SidebarView(selection: $selection)
        .navigationSplitViewColumnWidth(min: 200, ideal: 232, max: 272)
    } detail: {
      DetailWorkspace(section: selection ?? .tweaker)
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
      case .tweaker:
        TweakerView()
      case .systemApps:
        SystemAppsView()
      }
    }
    .navigationTitle("Mac Extreme Tweaker")
    .toolbarTitleDisplayMode(.inline)
  }
}

#Preview {
  RootView()
    .frame(width: 970, height: 592)
}
