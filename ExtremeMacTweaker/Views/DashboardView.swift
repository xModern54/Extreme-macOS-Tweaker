import SwiftUI

struct DashboardView: View {
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

          dashboardSection("Hardware") {
            HStack(alignment: .top, spacing: 12) {
              DashboardMetricTile(
                title: "Processor",
                value: "Apple M4 Pro",
                detail: "This Mac",
                systemImage: "cpu"
              )

              DashboardActivityTile(
                processCount: 384,
                threadCount: 1_842
              )
            }
          }

          dashboardSection("Estimated Savings") {
            LazyVGrid(columns: metricColumns, spacing: 12) {
              DashboardMetricTile(
                title: "Memory",
                value: "1.4 GB",
                detail: "Resident memory reclaimed",
                systemImage: "memorychip"
              )
              DashboardMetricTile(
                title: "Storage",
                value: "6.2 GB",
                detail: "Apps and assets removed",
                systemImage: "internaldrive"
              )
              DashboardMetricTile(
                title: "Processes",
                value: "37",
                detail: "Fewer background processes",
                systemImage: "gearshape.2"
              )
            }
          }

          dashboardSection("Applied Changes") {
            DashboardPanel {
              VStack(spacing: 0) {
                DashboardBreakdownRow(
                  title: "Launch Services",
                  value: "48 disabled",
                  detail: "of 126 catalog services",
                  systemImage: "switch.2"
                )
                divider
                DashboardBreakdownRow(
                  title: "System Apps",
                  value: "6 removed",
                  detail: "from /System/Applications",
                  systemImage: "square.grid.2x2"
                )
                divider
                DashboardBreakdownRow(
                  title: "System Debloat",
                  value: "3 packages",
                  detail: "optional assets deleted",
                  systemImage: "shippingbox"
                )
                divider
                DashboardBreakdownRow(
                  title: "Security",
                  value: "1 disabled",
                  detail: "protection system turned off",
                  systemImage: "shield.lefthalf.filled"
                )
              }
            }
          }

          dashboardSection("System Status") {
            DashboardPanel {
              VStack(spacing: 0) {
                DashboardStatusRow(
                  title: "System Integrity Protection",
                  value: "Disabled",
                  isReady: true
                )
                divider
                DashboardStatusRow(
                  title: "Authenticated Root",
                  value: "Disabled",
                  isReady: true
                )
                divider
                DashboardStatusRow(
                  title: "Boot Snapshot",
                  value: "Ready",
                  isReady: true
                )
              }
            }
          }
        }
        .padding(20)
      }
    }
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
    DashboardPanel {
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

            Text("Balanced")
              .font(.title3.weight(.semibold))
          }

          Spacer(minLength: 8)

          Text("68%")
            .font(.title.weight(.semibold).monospacedDigit())
            .foregroundStyle(Color.accentColor)
        }

        DashboardProgressBar(progress: 0.68)

        Text("48 of 126 catalog services are currently disabled.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(16)
    }
  }

  private var divider: some View {
    Divider().padding(.leading, 54)
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

private struct DashboardActivityTile: View {
  let processCount: Int
  let threadCount: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Image(systemName: "waveform.path.ecg")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(Color.accentColor)
          .frame(width: 24, height: 24)
          .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))

        Text("Activity")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
          .textCase(.uppercase)
      }

      HStack(alignment: .top, spacing: 0) {
        activityValue(processCount, label: "Processes")
        activityValue(threadCount, label: "Threads")
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    .overlay {
      RoundedRectangle(cornerRadius: 10)
        .stroke(.separator.opacity(0.45), lineWidth: 1)
    }
  }

  private func activityValue(_ value: Int, label: String) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(value.formatted())
        .font(.title2.weight(.semibold).monospacedDigit())
        .lineLimit(1)
        .minimumScaleFactor(0.7)

      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct DashboardBreakdownRow: View {
  let title: String
  let value: String
  let detail: String
  let systemImage: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: systemImage)
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(Color.accentColor)
        .frame(width: 32, height: 32)
        .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.body.weight(.medium))

        Text(detail)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 8)

      Text(value)
        .font(.caption.weight(.semibold).monospacedDigit())
        .foregroundStyle(Color.accentColor)
        .padding(.horizontal, 9)
        .frame(height: 24)
        .background(Color.accentColor.opacity(0.1), in: Capsule())
        .fixedSize()
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
  }
}

private struct DashboardStatusRow: View {
  let title: String
  let value: String
  let isReady: Bool

  var body: some View {
    HStack(spacing: 12) {
      Circle()
        .fill(isReady ? Color.green : Color.orange)
        .frame(width: 8, height: 8)
        .padding(.leading, 12)

      Text(title)
        .font(.body.weight(.medium))

      Spacer(minLength: 8)

      Text(value)
        .font(.caption.weight(.medium))
        .foregroundStyle(isReady ? Color.green : Color.orange)
        .padding(.trailing, 12)
    }
    .padding(.vertical, 11)
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
    .frame(width: 688, height: 592)
}
