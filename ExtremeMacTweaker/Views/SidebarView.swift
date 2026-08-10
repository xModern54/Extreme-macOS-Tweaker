import SwiftUI

struct SidebarView: View {
  @Binding var selection: AppSection?
  @EnvironmentObject private var optimizationStore: OptimizationStore

  var body: some View {
    ZStack {
      VisualEffectView(
        material: .sidebar,
        blendingMode: .behindWindow,
        state: .followsWindowActiveState
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {
        List(selection: $selection) {
          Section("Features") {
            ForEach(AppSection.allCases) { section in
              NavigationLink(value: section) {
                SidebarRow(section: section)
              }
            }
          }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 34)

        Divider()
          .opacity(0.65)

        VStack(alignment: .leading, spacing: 10) {
          HStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
              .foregroundStyle(.secondary)

            Text(pendingChangesLabel)
              .font(.caption)
              .foregroundStyle(.secondary)

            Spacer(minLength: 0)
          }

          Button(action: applyChanges) {
            Label("Apply", systemImage: "checkmark.circle.fill")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .disabled(!optimizationStore.canApply)
          .help("Review and apply pending changes")
        }
        .padding(14)
      }
    }
    .navigationTitle("")
    .sheet(isPresented: $optimizationStore.isReviewPresented) {
      ApplyReviewView()
        .environmentObject(optimizationStore)
    }
  }

  private func applyChanges() {
    optimizationStore.presentReview()
  }

  private var pendingChangesLabel: String {
    let count = optimizationStore.pendingCount
    return count == 0 ? "No Pending Changes" : "\(count) Pending Change\(count == 1 ? "" : "s")"
  }
}

private struct ApplyReviewView: View {
  @EnvironmentObject private var optimizationStore: OptimizationStore
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      header

      if optimizationStore.executionPhase == .idle {
        reviewList
      } else {
        executionContent
      }

      footer
    }
    .padding(24)
    .frame(width: 560, height: 480)
    .interactiveDismissDisabled(optimizationStore.isExecuting)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(headerTitle)
        .font(.title2.weight(.semibold))
      Text(headerSubtitle)
        .foregroundStyle(.secondary)
    }
  }

  private var reviewList: some View {
    List {
      Section("Selected Changes") {
        ForEach(optimizationStore.pendingChanges) { change in
          Text(change.title)
        }
      }

      Section("Execution Plan") {
        ForEach(optimizationStore.executionPlan.steps) { step in
          Label(step.description, systemImage: "chevron.right")
        }
      }
    }
    .listStyle(.inset)
  }

  private var executionContent: some View {
    VStack(alignment: .leading, spacing: 14) {
      ProgressView(value: optimizationStore.executionProgress)

      Text(optimizationStore.executionMessage)
        .font(.headline)

      List(optimizationStore.executionLog.indices, id: \.self) { index in
        Label(
          optimizationStore.executionLog[index],
          systemImage: index == optimizationStore.executionLog.indices.last
            ? "chevron.right.circle.fill"
            : "checkmark.circle"
        )
        .foregroundStyle(index == optimizationStore.executionLog.indices.last ? .primary : .secondary)
      }
      .listStyle(.inset)

      if optimizationStore.executionPhase == .succeeded {
        Label("A restart is required to load the new system snapshot.", systemImage: "restart")
          .foregroundStyle(.orange)
      } else if let error = optimizationStore.executionError {
        Label(error, systemImage: "exclamationmark.triangle.fill")
          .foregroundStyle(.red)
      }
    }
  }

  private var footer: some View {
    HStack {
      if !optimizationStore.isExecuting {
        Button(optimizationStore.executionPhase == .idle ? "Cancel" : "Close") {
          dismiss()
        }
        .keyboardShortcut(.cancelAction)
      }

      Spacer()

      if optimizationStore.executionPhase == .idle {
        Button("Apply Changes") {
          Task { await optimizationStore.applyPendingChanges() }
        }
        .buttonStyle(.borderedProminent)
      } else if optimizationStore.executionPhase == .failed {
        Button("Try Again") {
          Task { await optimizationStore.applyPendingChanges() }
        }
        .buttonStyle(.borderedProminent)
      } else if optimizationStore.executionPhase == .succeeded {
        Button("Done") { dismiss() }
          .buttonStyle(.borderedProminent)
      }
    }
  }

  private var headerTitle: String {
    switch optimizationStore.executionPhase {
    case .idle: "Review Changes"
    case .authorizing: "Administrator Authorization"
    case .running: "Applying Changes"
    case .succeeded: "Changes Applied"
    case .failed: "Apply Failed"
    }
  }

  private var headerSubtitle: String {
    switch optimizationStore.executionPhase {
    case .idle:
      "The selected changes will modify the macOS system snapshot."
    case .authorizing:
      "Tweaker needs administrator privileges to continue."
    case .running:
      "Do not quit Tweaker while the system snapshot is being modified."
    case .succeeded:
      "The new bootable snapshot has been created successfully."
    case .failed:
      "The operation stopped before all changes were applied."
    }
  }
}

private struct SidebarRow: View {
  let section: AppSection

  var body: some View {
    HStack(spacing: 11) {
      Image(systemName: section.systemImage)
        .font(.system(size: 16, weight: .medium))
        .symbolRenderingMode(.monochrome)
        .foregroundStyle(Color.accentColor)
        .frame(width: 22, height: 22)

      Text(section.title)
        .font(.body)

      Spacer(minLength: 0)
    }
    .padding(.vertical, 2)
  }
}

#Preview {
  @Previewable @State var selection: AppSection? = .tweaker

  SidebarView(selection: $selection)
    .environmentObject(OptimizationStore())
    .frame(width: 232, height: 592)
}
