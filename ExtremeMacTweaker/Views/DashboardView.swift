import SwiftUI

struct DashboardView: View {
  @EnvironmentObject private var optimizationStore: OptimizationStore
  @EnvironmentObject private var catalogStore: TweakCatalogStore
  @StateObject private var hostMetrics = HostMetricsStore()

  private let metricColumns = [
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
      Divider()

      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          optimizationCard

          HStack(alignment: .top, spacing: 12) {
            DashboardSplitStatTile(
              title: "Specs",
              systemImage: "cpu",
              primary: .init(value: metrics?.processorName ?? "—", label: "Processor"),
              secondary: [
                .init(value: metrics?.formattedCoreCount ?? "—", label: "Cores"),
                .init(value: metrics?.formattedMemory ?? "—", label: "Memory"),
              ]
            )

            DashboardSplitStatTile(
              title: "Runtime",
              systemImage: "waveform.path.ecg",
              primary: .init(value: metrics?.formattedUsedMemory ?? "—", label: "Used"),
              secondary: [
                .init(value: metrics?.formattedProcessCount ?? "—", label: "Processes"),
                .init(value: metrics?.formattedThreadCount ?? "—", label: "Threads"),
              ]
            )
          }

          dashboardSection("Estimated Savings") {
            let savings = optimizationStore.appliedTweakSavings(
              catalog: catalogStore.catalog,
              store: catalogStore
            )

            LazyVGrid(columns: metricColumns, spacing: 12) {
              DashboardMetricTile(
                title: "Memory",
                value: formattedSavingsMemory(savings.memoryMB),
                detail: "Resident memory reclaimed",
                systemImage: "memorychip"
              )
              DashboardMetricTile(
                title: "Storage",
                value: formattedSavingsBytes(optimizationStore.savedStorageBytes),
                detail: "Apps and assets removed",
                systemImage: "internaldrive"
              )
              DashboardMetricTile(
                title: "Processes",
                value: savings.processes.formatted(),
                detail: "Fewer background processes",
                systemImage: "gearshape.2"
              )
            }
          }
        }
        .padding(20)
      }
    }
    .task {
      await hostMetrics.startUpdating()
    }
    .task(id: catalogStore.catalog?.catalogVersion) {
      while !Task.isCancelled {
        await optimizationStore.refreshLaunchServiceStates(
          catalogStore.catalog?.services ?? [],
          catalog: catalogStore.catalog
        )
        try? await Task.sleep(nanoseconds: 5_000_000_000)
      }
    }
  }

  private var metrics: HostMetrics? {
    hostMetrics.metrics
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Dashboard")
        .font(.title2.weight(.semibold))

      Text("A snapshot of optimization, hardware, and estimated savings.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 24)
    .padding(.top, 20)
    .padding(.bottom, 16)
  }

  private var optimizationCard: some View {
    let progress = optimizationStore.appliedTweakProgress(
      catalog: catalogStore.catalog,
      store: catalogStore
    )
    let percent = progress.total == 0
      ? 0
      : Int((Double(progress.applied) / Double(progress.total) * 100).rounded())

    return DashboardPanel {
      VStack(alignment: .leading, spacing: 14) {
        HStack(alignment: .top, spacing: 12) {
          Image(systemName: "gauge.with.needle")
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(Color.accentColor)
            .frame(width: 42, height: 42)
            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

          VStack(alignment: .leading, spacing: 3) {
            Text("Optimization Level")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.secondary)
              .textCase(.uppercase)

            Text(optimizationRankTitle(for: percent))
              .font(.title3.weight(.semibold))
          }

          Spacer(minLength: 8)

          Text("\(percent)%")
            .font(.title.weight(.semibold).monospacedDigit())
            .foregroundStyle(Color.accentColor)
        }

        DashboardProgressBar(progress: progress.total == 0 ? 0 : Double(progress.applied) / Double(progress.total))

        Text("\(progress.applied) of \(progress.total) tweaks are applied.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(16)
    }
  }

  private func optimizationRankTitle(for percent: Int) -> String {
    switch percent {
    case ..<5:
      "Apple Soyboy"
    case ..<20:
      "Vanilla Enjoyer"
    case ..<40:
      "Casual Tweaker"
    case ..<60:
      "Power User"
    case ..<80:
      "Service Slayer"
    case ..<95:
      "Extreme"
    case ..<100:
      "Ultimate"
    default:
      "Absolute"
    }
  }

  private func formattedSavingsMemory(_ megabytes: Int) -> String {
    formattedSavingsGigabytes(Double(megabytes) / 1024)
  }

  private func formattedSavingsBytes(_ bytes: Int64) -> String {
    formattedSavingsGigabytes(Double(bytes) / 1_073_741_824)
  }

  private func formattedSavingsGigabytes(_ gigabytes: Double) -> String {
    let formatter = NumberFormatter()
    formatter.locale = .current
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    let number = formatter.string(from: NSNumber(value: gigabytes)) ?? "0.00"
    return "\(number) GB"
  }

  private func dashboardSection<Content: View>(
    _ title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 9) {
      Text(title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      content()
    }
  }
}

private struct DashboardPanel<Content: View>: View {
  @ViewBuilder var content: Content

  var body: some View {
    content
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
      .overlay {
        RoundedRectangle(cornerRadius: 10)
          .stroke(.separator.opacity(0.45), lineWidth: 1)
      }
  }
}

private struct DashboardMetricTile: View {
  let title: String
  let value: String
  let detail: String
  let systemImage: String

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Image(systemName: systemImage)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(Color.accentColor)
          .frame(width: 24, height: 24)
          .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))

        Text(title)
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
          .textCase(.uppercase)
      }

      Text(value)
        .font(.title2.weight(.semibold).monospacedDigit())
        .lineLimit(1)
        .minimumScaleFactor(0.7)

      Text(detail)
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(14)
    .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    .overlay {
      RoundedRectangle(cornerRadius: 10)
        .stroke(.separator.opacity(0.45), lineWidth: 1)
    }
  }
}

private struct DashboardCardHeader: View {
  let title: String
  let systemImage: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: systemImage)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(Color.accentColor)
        .frame(width: 24, height: 24)
        .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))

      Text(title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
    }
  }
}

private struct DashboardSplitStatTile: View {
  struct Item: Identifiable {
    let value: String
    let label: String
    var id: String { label }
  }

  let title: String
  let systemImage: String
  let primary: Item
  let secondary: [Item]

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      DashboardCardHeader(title: title, systemImage: systemImage)

      labeledValue(primary, monospaced: false)

      HStack(alignment: .top, spacing: 12) {
        ForEach(secondary) { item in
          labeledValue(item, monospaced: true)
        }
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    .overlay {
      RoundedRectangle(cornerRadius: 10)
        .stroke(.separator.opacity(0.45), lineWidth: 1)
    }
  }

  private func labeledValue(_ item: Item, monospaced: Bool) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(item.value)
        .font(monospaced ? .title2.weight(.semibold).monospacedDigit() : .title2.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, alignment: .leading)

      Text(item.label)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct DashboardProgressBar: View {
  let progress: CGFloat

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(Color.accentColor.opacity(0.12))

        Capsule()
          .fill(Color.accentColor)
          .frame(width: max(8, geometry.size.width * min(max(progress, 0), 1)))
      }
    }
    .frame(height: 8)
  }
}

#Preview {
  DashboardView()
    .environmentObject(OptimizationStore())
    .environmentObject(TweakCatalogStore())
    .frame(width: 688, height: 592)
}
