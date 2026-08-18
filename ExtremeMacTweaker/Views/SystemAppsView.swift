import AppKit
import SwiftUI

struct SystemAppsView: View {
  @StateObject private var model = SystemAppsViewModel()
  @EnvironmentObject private var optimizationStore: OptimizationStore

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

          Text("You can delete or hide any of the \(model.applications.count) system applications.")
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
              .environmentObject(optimizationStore)
          }
        }
        .padding(24)
      }
    }
  }
}

private struct SystemApplicationCard: View {
  let application: SystemApplication
  @EnvironmentObject private var optimizationStore: OptimizationStore
  @State private var isActionsPresented = false

  private var pendingAction: SystemApplicationAction? {
    optimizationStore.pendingSystemApplicationAction(for: application.id)
  }

  var body: some View {
    VStack(spacing: 5.25) {
      SystemApplicationIcon(path: application.url.path)
        .opacity(application.state == .disabled ? 0.42 : 1)
        .overlay(alignment: .bottomTrailing) {
          if let pendingAction {
            Image(systemName: pendingAction.systemImage)
              .font(.caption.weight(.semibold))
              .foregroundStyle(.white)
              .padding(5)
              .background(pendingAction == .delete ? Color.red : Color.accentColor, in: Circle())
              .overlay(Circle().stroke(.white, lineWidth: 1.5))
          }
        }

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
    .contentShape(Rectangle())
    .onTapGesture { isActionsPresented = true }
    .popover(isPresented: $isActionsPresented, arrowEdge: .trailing) {
      SystemApplicationActions(
        application: application,
        pendingAction: pendingAction,
        dismiss: { isActionsPresented = false }
      )
      .environmentObject(optimizationStore)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(application.name)
    .accessibilityValue(application.formattedSize ?? "Size is being calculated")
  }
}

private struct SystemApplicationActions: View {
  let application: SystemApplication
  let pendingAction: SystemApplicationAction?
  let dismiss: () -> Void
  @EnvironmentObject private var optimizationStore: OptimizationStore

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(application.name)
        .font(.headline)

      if application.state == .installed {
        actionButton(.disable)
      } else {
        actionButton(.restore)
      }
      actionButton(.delete, role: .destructive)

      if let pendingAction {
        Divider()
        Button("Cancel \(pendingAction.title)") {
          optimizationStore.removeChange(withID: "system-app:\(application.id)")
          dismiss()
        }
      }
    }
    .buttonStyle(.plain)
    .padding(16)
    .frame(width: 220, alignment: .leading)
  }

  private func actionButton(
    _ action: SystemApplicationAction,
    role: ButtonRole? = nil
  ) -> some View {
    Button(role: role) {
      optimizationStore.toggle(action, for: application)
      dismiss()
    } label: {
      HStack {
        Label(action.title, systemImage: action.systemImage)
        Spacer()
        if pendingAction == action {
          Image(systemName: "checkmark")
        }
      }
      .contentShape(Rectangle())
    }
  }
}

private struct SystemApplicationIcon: View {
  let path: String

  var body: some View {
    Group {
      if let icon = IconCache.shared.cachedApplicationIcon(forPath: path) {
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
  }
}

#Preview {
  SystemAppsView()
    .environmentObject(OptimizationStore())
    .frame(width: 688, height: 592)
}
