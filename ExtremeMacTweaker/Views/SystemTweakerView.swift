import SwiftUI

struct SystemTweakerView: View {
  @EnvironmentObject private var catalogStore: TweakCatalogStore
  @EnvironmentObject private var optimizationStore: OptimizationStore
  @State private var selectedFeatureID: String?
  @State private var areIconsPrepared = false

  private var categories: [TweakCatalogCategory] {
    catalogStore.catalog?.categories.sorted { $0.order < $1.order } ?? []
  }

  private var features: [TweakCatalogFeature] {
    catalogStore.catalog?.features.sorted { $0.order < $1.order } ?? []
  }

  private var selectedFeature: TweakCatalogFeature? {
    features.first(where: { $0.id == selectedFeatureID }) ?? features.first
  }

  var body: some View {
    Group {
      if let selectedFeature, areIconsPrepared {
        workspace(selectedFeature: selectedFeature)
      } else if let error = catalogStore.loadingError {
        ContentUnavailableView(
          "Unable to Load Tweak Catalog",
          systemImage: "doc.badge.gearshape",
          description: Text(error)
        )
      } else {
        ProgressView("Loading Tweak Catalog…")
          .controlSize(.small)
      }
    }
    .onAppear {
      selectFirstFeatureIfNeeded()
      reconcileLegacyPendingChanges()
    }
    .onChange(of: catalogStore.catalog?.catalogVersion) {
      selectFirstFeatureIfNeeded()
      reconcileLegacyPendingChanges()
    }
    .task(id: catalogStore.catalog?.catalogVersion) {
      areIconsPrepared = false
      if let catalog = catalogStore.catalog {
        let symbolNames = Set(
          catalog.categories.map(\.systemImage) + catalog.features.map(\.systemImage)
        )
        await IconCache.shared.preloadSystemSymbols(named: Array(symbolNames))
        guard !Task.isCancelled else { return }
        areIconsPrepared = true
      }

      while !Task.isCancelled {
        await optimizationStore.refreshLaunchServiceStates(
          catalogStore.catalog?.services ?? []
        )
        try? await Task.sleep(nanoseconds: 5_000_000_000)
      }
    }
  }

  private func workspace(selectedFeature: TweakCatalogFeature) -> some View {
    GeometryReader { geometry in
      let inspectorWidth = min(260, max(210, geometry.size.width * 0.34))

      HStack(spacing: 0) {
        featureBrowser
          .frame(
            width: max(0, geometry.size.width - inspectorWidth - 1),
            height: geometry.size.height
          )

        Divider()

        SystemTweakInspector(
          feature: selectedFeature,
          services: catalogStore.services(for: selectedFeature),
          choice: choice(for: selectedFeature)
        )
        .frame(width: inspectorWidth, height: geometry.size.height)
      }
    }
  }

  private var featureBrowser: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 6) {
        Text("System Tweaker")
          .font(.title2.weight(.semibold))

        Text("Select the macOS features you use.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 24)
      .padding(.top, 20)
      .padding(.bottom, 16)

      Divider()

      ScrollView {
        LazyVStack(alignment: .leading, spacing: 20) {
          ForEach(categories) { category in
            let categoryFeatures = features.filter { $0.categoryID == category.id }

            if !categoryFeatures.isEmpty {
              VStack(alignment: .leading, spacing: 9) {
                Label {
                  Text(category.localizedTitle)
                } icon: {
                  CachedSystemSymbol(name: category.systemImage)
                }
                  .font(.caption.weight(.semibold))
                  .foregroundStyle(.secondary)
                  .textCase(.uppercase)

                VStack(spacing: 0) {
                  ForEach(Array(categoryFeatures.enumerated()), id: \.element.id) { index, feature in
                    SystemTweakFeatureRow(
                      feature: feature,
                      choice: binding(for: feature),
                      isSelected: selectedFeatureID == feature.id
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { selectedFeatureID = feature.id }

                    if index < categoryFeatures.count - 1 {
                      Divider().padding(.leading, 54)
                    }
                  }
                }
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                  RoundedRectangle(cornerRadius: 10)
                    .stroke(.separator.opacity(0.45), lineWidth: 1)
                }
              }
            }
          }
        }
        .padding(20)
      }
    }
  }

  private func choice(for feature: TweakCatalogFeature) -> SystemTweakChoice {
    let services = catalogStore.services(for: feature)
    return optimizationStore.launchServicesAreEnabled(
      services,
      defaultEnabled: feature.defaultEnabled
    ) ? .keepEnabled : .disable
  }

  private func binding(for feature: TweakCatalogFeature) -> Binding<SystemTweakChoice> {
    Binding(
      get: { choice(for: feature) },
      set: { newValue in
        selectedFeatureID = feature.id
        optimizationStore.setLaunchServices(
          catalogStore.services(for: feature),
          enabled: newValue == .keepEnabled,
          defaultEnabled: feature.defaultEnabled,
          featureID: feature.id,
          featureTitle: feature.localizedTitle
        )
      }
    )
  }

  private func selectFirstFeatureIfNeeded() {
    guard !features.isEmpty else {
      selectedFeatureID = nil
      return
    }
    if !features.contains(where: { $0.id == selectedFeatureID }) {
      selectedFeatureID = features[0].id
    }
  }

  private func reconcileLegacyPendingChanges() {
    for feature in features {
      optimizationStore.reconcileLegacyLaunchFeature(
        feature,
        services: catalogStore.services(for: feature)
      )
    }
  }
}

private struct SystemTweakFeatureRow: View {
  let feature: TweakCatalogFeature
  @Binding var choice: SystemTweakChoice
  let isSelected: Bool

  var body: some View {
    HStack(spacing: 12) {
      CachedSystemSymbol(name: feature.systemImage)
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(isSelected ? Color.white : Color.accentColor)
        .frame(width: 32, height: 32)
        .background(
          isSelected ? Color.accentColor : Color.accentColor.opacity(0.1),
          in: RoundedRectangle(cornerRadius: 8)
        )

      Text(feature.localizedTitle)
        .font(.body.weight(.medium))
        .lineLimit(1)

      Spacer(minLength: 8)

      EstimatedMemoryPill(memoryMB: feature.impact.estimatedMemoryMB)

      Toggle("", isOn: keepEnabledBinding)
        .labelsHidden()
        .toggleStyle(.checkbox)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
  }

  private var keepEnabledBinding: Binding<Bool> {
    Binding(
      get: { choice == .keepEnabled },
      set: { choice = $0 ? .keepEnabled : .disable }
    )
  }
}

private struct EstimatedMemoryPill: View {
  let memoryMB: Int

  var body: some View {
    HStack(spacing: 5) {
      Image(systemName: "memorychip")
        .font(.system(size: 10, weight: .semibold))

      Text("~\(memoryMB) MB")
        .font(.caption.weight(.semibold).monospacedDigit())
    }
    .foregroundStyle(Color.accentColor)
    .padding(.horizontal, 9)
    .frame(height: 24)
    .background(Color.accentColor.opacity(0.1), in: Capsule())
    .fixedSize()
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Estimated memory freed when disabled")
    .accessibilityValue("Approximately \(memoryMB) megabytes")
    .help("Estimated memory freed when disabled")
  }
}

private struct SystemTweakInspector: View {
  @EnvironmentObject private var optimizationStore: OptimizationStore
  let feature: TweakCatalogFeature
  let services: [TweakCatalogService]
  let choice: SystemTweakChoice

  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          inspectorHeader
          impactSection
          guidanceSection
          servicesSection
        }
        .frame(width: max(0, geometry.size.width - 32), alignment: .leading)
        .padding(16)
      }
    }
    .background(Color(nsColor: .controlBackgroundColor).opacity(0.72))
  }

  private var inspectorHeader: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top, spacing: 12) {
        CachedSystemSymbol(name: feature.systemImage)
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(Color.accentColor)
          .frame(width: 42, height: 42)
          .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

        VStack(alignment: .leading, spacing: 4) {
          Text(feature.localizedTitle)
            .font(.headline)
            .lineLimit(2)
            .minimumScaleFactor(0.8)

          Text(choice == .disable ? "Selected for disabling" : "Kept enabled")
            .font(.caption.weight(.medium))
            .foregroundStyle(choice == .disable ? Color.orange : Color.green)
        }
      }

      Text(feature.localizedQuestion)
        .font(.subheadline.weight(.medium))
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)

      Text(feature.localizedDescription)
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var impactSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionTitle("Estimated Impact")

      HStack(spacing: 7) {
        Image(systemName: "memorychip").foregroundStyle(Color.accentColor)
        Text("~\(feature.impact.estimatedMemoryMB) MB")
          .font(.subheadline.weight(.medium).monospacedDigit())
        Text("·").foregroundStyle(.tertiary)
        Text(
          "\(feature.impact.estimatedProcessReduction) process"
            + (feature.impact.estimatedProcessReduction == 1 ? "" : "es")
        )
        .font(.subheadline.monospacedDigit())
        .foregroundStyle(.secondary)
      }
    }
  }

  private var guidanceSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionTitle("When to Disable")

      Text(feature.localizedDisableGuidance)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var servicesSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        sectionTitle("Related Services")
        Spacer()
        Text("\(activeServiceCount)/\(services.count) active")
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
      }

      VStack(alignment: .leading, spacing: 7) {
        ForEach(services) { service in
          HStack(spacing: 6) {
            Circle()
              .fill(serviceStateColor(service))
              .frame(width: 6, height: 6)

            Text(service.label)
              .font(.caption2.monospaced())
              .foregroundStyle(.secondary)
              .textSelection(.enabled)
              .lineLimit(1)
              .minimumScaleFactor(0.65)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      }
    }
  }

  private var activeServiceCount: Int {
    services.count { service in
      optimizationStore.observedLaunchServiceStates[service.id]?.isEffectivelyActive ?? true
    }
  }

  private func serviceStateColor(_ service: TweakCatalogService) -> Color {
    guard let state = optimizationStore.observedLaunchServiceStates[service.id] else {
      return .secondary
    }
    return state.isEffectivelyActive ? .green : .red
  }

  private func sectionTitle(_ title: String) -> some View {
    Text(title)
      .font(.caption.weight(.semibold))
      .foregroundStyle(.secondary)
      .textCase(.uppercase)
  }
}

private enum SystemTweakChoice {
  case keepEnabled
  case disable
}

private struct CachedSystemSymbol: View {
  let name: String

  var body: some View {
    if let image = IconCache.shared.cachedSystemSymbol(named: name) {
      Image(nsImage: image)
    } else {
      Image(systemName: name)
    }
  }
}

#Preview {
  SystemTweakerView()
    .environmentObject(TweakCatalogStore())
    .environmentObject(OptimizationStore())
    .frame(width: 900, height: 620)
}
