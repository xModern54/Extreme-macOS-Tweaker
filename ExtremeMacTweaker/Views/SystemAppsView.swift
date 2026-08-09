import AppKit
import SwiftUI

struct SystemAppsView: View {
  @StateObject private var model = SystemAppsViewModel()

  private let columns = [
    GridItem(.adaptive(minimum: 104, maximum: 138), spacing: 18, alignment: .top)
  ]

  var body: some View {
    Group {
      if model.isLoading {
        ProgressView("Loading System Applications…")
          .controlSize(.small)
      } else if let errorMessage = model.errorMessage {
        ContentUnavailableView(
          "Unable to Load Applications",
          systemImage: "exclamationmark.triangle",
          description: Text(errorMessage)
        )
      } else {
        applicationsContent
      }
    }
    .task {
      await model.load()
    }
  }

  private var applicationsContent: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 3) {
          Text("System Applications")
            .font(.title2.weight(.semibold))

          Text("\(model.applications.count) apps in /System/Applications")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Spacer()

        if model.isCalculatingSizes {
          ProgressView()
            .controlSize(.small)
            .help("Calculating application sizes")
        }
      }
      .padding(.horizontal, 24)
      .padding(.top, 20)
      .padding(.bottom, 16)

      Divider()

      ScrollView {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 24) {
          ForEach(model.applications) { application in
            SystemApplicationCard(application: application)
          }
        }
        .padding(24)
      }
    }
  }
}

private struct SystemApplicationCard: View {
  let application: SystemApplication

  var body: some View {
    VStack(spacing: 5.25) {
      SystemApplicationIcon(path: application.url.path)

      Group {
        if let sizeInBytes = application.sizeInBytes {
          Text(ByteCountFormatter.string(fromByteCount: sizeInBytes, countStyle: .file))
        } else {
          Text("Calculating…")
        }
      }
      .font(.caption2)
      .foregroundStyle(.secondary)
      .lineLimit(1)

      Text(application.name)
        .font(.system(size: 13))
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .frame(maxWidth: .infinity, minHeight: 32, alignment: .top)
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(application.name)
    .accessibilityValue(application.formattedSize ?? "Size is being calculated")
  }
}

private struct SystemApplicationIcon: View {
  let path: String

  @State private var icon: NSImage?

  var body: some View {
    Group {
      if let icon {
        Image(nsImage: icon)
          .resizable()
          .scaledToFit()
      } else {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
          .fill(.quaternary)
          .overlay {
            Image(systemName: "app.dashed")
              .font(.title2)
              .foregroundStyle(.secondary)
          }
      }
    }
    .frame(width: 72, height: 72)
    .task(id: path) {
      icon = NSWorkspace.shared.icon(forFile: path)
    }
  }
}

#Preview {
  SystemAppsView()
    .frame(width: 688, height: 592)
}
