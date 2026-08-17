import SwiftUI

struct RootView: View {
  @EnvironmentObject private var optimizationStore: OptimizationStore
  @State private var selection: AppSection? = .dashboard

  var body: some View {
    HStack(spacing: 0) {
      SidebarView(selection: $selection)
        .frame(width: 232)
        .overlay(alignment: .trailing) {
          Rectangle()
            .fill(Color(nsColor: .separatorColor).opacity(0.35))
            .frame(width: 1)
            .ignoresSafeArea()
        }

      DetailWorkspace(section: selection ?? .dashboard)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .ignoresSafeArea()
    .containerBackground(.clear, for: .window)
    .tint(Color(nsColor: .controlAccentColor))
    .onChange(of: optimizationStore.shouldOpenRecoveryGuide) { _, shouldOpen in
      guard shouldOpen else { return }
      selection = .recoveryGuide
      optimizationStore.shouldOpenRecoveryGuide = false
    }
  }
}

private struct DetailWorkspace: View {
  let section: AppSection

  var body: some View {
    ZStack {
      Color(nsColor: .windowBackgroundColor)
        .ignoresSafeArea()

      switch section {
      case .dashboard:
        DashboardView()
      case .systemTweaker:
        SystemTweakerView()
      case .systemApps:
        SystemAppsView()
      case .systemDebloat:
        SystemDebloatView()
      case .security:
        SecurityView()
      case .recoveryGuide:
        ProtectionGuideView()
      }
    }
  }
}

#Preview {
  RootView()
    .environmentObject(OptimizationStore())
    .environmentObject(TweakCatalogStore())
    .frame(width: 920, height: 592)
}
