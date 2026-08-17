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

          HStack(alignment: .top, spacing: 12) {
            DashboardStatGroupTile(
              title: "Specs",
              systemImage: "cpu",
              items: [
                .init(value: "Apple M4 Pro", label: "Processor"),
                .init(value: "14", label: "Cores"),
                .init(value: "24 GB", label: "Memory"),
              ]
            )

            DashboardStatGroupTile(
              title: "Runtime",
              systemImage: "waveform.path.ecg",
              items: [
                .init(value: "384", label: "Processes"),
                .init(value: "1,842", label: "Threads"),
                .init(value: "11.6 GB", label: "Used"),
              ]
            )
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

private struct DashboardStatGroupTile: View {
  struct Item: Identifiable {
    let value: String
    let label: String
    var id: String { label }
  }

  let title: String
  let systemImage: String
  let items: [Item]

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

      HStack(alignment: .top, spacing: 0) {
        ForEach(items) { item in
          VStack(alignment: .leading, spacing: 3) {
            Text(item.value)
              .font(.title2.weight(.semibold).monospacedDigit())
              .lineLimit(1)
              .minimumScaleFactor(0.65)

            Text(item.label)
              .font(.caption)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
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
