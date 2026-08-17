import AppKit
import SwiftUI

struct SidebarView: View {
  @Binding var selection: AppSection?
  @EnvironmentObject private var optimizationStore: OptimizationStore

  var body: some View {
    VStack(spacing: 0) {
      Color.clear
        .frame(height: 28)

      Text("Tweaker")
        .font(.title2.weight(.bold))
        .padding(.horizontal, 18)
        .padding(.top, 2)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)

      List(selection: $selection) {
        SidebarRow(section: .dashboard)
          .tag(AppSection.dashboard)

        Section("Features") {
          ForEach(AppSection.featureCases) { section in
            SidebarRow(section: section)
              .tag(section)
          }
        }
      }
      .listStyle(.sidebar)
      .scrollContentBackground(.hidden)
      .background(.clear)
      .environment(\.defaultMinListRowHeight, 34)

      Rectangle()
        .fill(Color.primary.opacity(0.08))
        .frame(height: 1)

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
    .background {
      VisualEffectView(
        material: .underWindowBackground,
        blendingMode: .behindWindow,
        state: .followsWindowActiveState
      )
      .ignoresSafeArea()
    }
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
        ForEach(optimizationStore.pendingChangeSummaries) { change in
          Text(change.title)
        }
      }

      if optimizationStore.executionPlan.requiresSystemProtectionCheck {
        systemProtectionRequirements
      }

      Section("Execution Plan") {
        ForEach(optimizationStore.executionPlan.steps) { step in
          Label(step.description, systemImage: "chevron.right")
        }
      }
    }
    .listStyle(.inset)
  }

  @ViewBuilder
  private var systemProtectionRequirements: some View {
    Section("Required System Protection Settings") {
      switch optimizationStore.systemProtectionCheck {
      case .notRequired, .checking:
        HStack(spacing: 10) {
          ProgressView().controlSize(.small)
          Text("Checking system protection status…")
            .foregroundStyle(.secondary)
        }

      case .checked(let status):
        if optimizationStore.executionPlan.requiresSystemIntegrityProtectionDisabled {
          protectionStatusRow(
            title: "System Integrity Protection",
            isDisabled: status.systemIntegrityProtectionDisabled
          )
        }
        if optimizationStore.executionPlan.requiresAuthenticatedRootDisabled {
          protectionStatusRow(
            title: "Authenticated Root",
            isDisabled: status.authenticatedRootDisabled
          )
        }

        if !optimizationStore.canStartExecution {
          Label(
            "Disable the required protections from macOS Recovery before applying these changes.",
            systemImage: "exclamationmark.triangle.fill"
          )
          .foregroundStyle(.red)
        }

      case .failed(let message):
        Label(message, systemImage: "exclamationmark.triangle.fill")
          .foregroundStyle(.red)
      }

      Button("Check Again") {
        Task { await optimizationStore.refreshSystemProtectionStatus() }
      }
      .disabled(optimizationStore.systemProtectionCheck == .checking)
    }
  }

  private func protectionStatusRow(title: String, isDisabled: Bool) -> some View {
    Label(
      "\(title): \(isDisabled ? "Disabled" : "Enabled")",
      systemImage: isDisabled ? "checkmark.circle.fill" : "xmark.octagon.fill"
    )
    .foregroundStyle(isDisabled ? Color.green : Color.red)
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

      if optimizationStore.executionPhase == .succeeded,
        optimizationStore.executionRequiresReboot
      {
        Label("A restart is required to load the new system snapshot.", systemImage: "restart")
          .foregroundStyle(.orange)
      }

      if optimizationStore.executionPhase == .succeeded,
        optimizationStore.gatekeeperConfirmationRequired
      {
        Label(
          "macOS requires confirmation in Privacy & Security before applications from anywhere are allowed.",
          systemImage: "hand.tap"
        )
        .foregroundStyle(.orange)
      }

      if let error = optimizationStore.executionError {
        Label(error, systemImage: "exclamationmark.triangle.fill")
          .foregroundStyle(.red)
      }
    }
  }

  private var footer: some View {
    HStack {
      if !optimizationStore.isExecuting {
        Button(optimizationStore.executionPhase == .idle ? "Cancel" : "Done") {
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
        .disabled(!optimizationStore.canStartExecution)
      } else if optimizationStore.executionPhase == .failed {
        Button("Try Again") {
          Task { await optimizationStore.applyPendingChanges() }
        }
        .buttonStyle(.borderedProminent)
        .disabled(!optimizationStore.canStartExecution)
      } else if optimizationStore.executionPhase == .succeeded,
        optimizationStore.gatekeeperConfirmationRequired
      {
        Button("Open Privacy & Security") {
          openPrivacyAndSecuritySettings()
        }
        .buttonStyle(.borderedProminent)
      } else if optimizationStore.executionPhase == .succeeded,
        optimizationStore.executionRequiresReboot
      {
        Button("Restart Now") {
          Task { await optimizationStore.restartSystemWithoutReopeningApplications() }
        }
        .tint(.red)
        .buttonStyle(.borderedProminent)
        .disabled(optimizationStore.restartInProgress)
      }
    }
  }

  private func openPrivacyAndSecuritySettings() {
    guard let url = URL(
      string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension"
    ) else { return }
    NSWorkspace.shared.open(url)
  }

  private var headerTitle: String {
    switch optimizationStore.executionPhase {
    case .idle: "Review Changes"
    case .authorizing: "Administrator Authorization"
    case .running: "Applying Changes"
    case .succeeded:
      optimizationStore.gatekeeperConfirmationRequired ? "Confirmation Required" : "Changes Applied"
    case .failed: "Apply Failed"
    }
  }

  private var headerSubtitle: String {
    switch optimizationStore.executionPhase {
    case .idle:
      optimizationStore.executionPlan.requiresReboot
        ? "The selected changes will modify the macOS system snapshot."
        : "The selected system settings will be updated with administrator privileges."
    case .authorizing:
      "Tweaker needs administrator privileges to continue."
    case .running:
      optimizationStore.executionRequiresReboot
        ? "Do not quit Tweaker while the system snapshot is being modified."
        : "Do not quit Tweaker while system settings are being updated."
    case .succeeded:
      if optimizationStore.gatekeeperConfirmationRequired {
        "Finish allowing applications from anywhere in macOS System Settings."
      } else if optimizationStore.executionRequiresReboot {
        "The new bootable snapshot has been created successfully."
      } else {
        "The selected system settings were updated successfully."
      }
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
  @Previewable @State var selection: AppSection? = .dashboard

  SidebarView(selection: $selection)
    .environmentObject(OptimizationStore())
    .frame(width: 232, height: 592)
}
