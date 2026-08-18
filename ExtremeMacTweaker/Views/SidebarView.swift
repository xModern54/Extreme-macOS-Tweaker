import AppKit
import SwiftUI

struct SidebarView: View {
  @Binding var selection: AppSection?
  @EnvironmentObject private var optimizationStore: OptimizationStore
  @EnvironmentObject private var catalogStore: TweakCatalogStore

  var body: some View {
    VStack(spacing: 0) {
      Color.clear
        .frame(height: 40)

      VStack(alignment: .leading, spacing: 2) {
        Text("Tweaker")
          .font(.title2.weight(.bold))

        Text(appVersion)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 18)
      .padding(.top, 4)
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

        if appliedTweakCount > 0 {
          Button(action: restoreAppliedChanges) {
            Label("Restore Changes", systemImage: "arrow.uturn.backward")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)
          .controlSize(.large)
          .disabled(!canRestoreAppliedChanges || optimizationStore.isExecuting)
          .help(restoreHelp)
          .transition(.opacity.combined(with: .move(edge: .bottom)))
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
      .animation(.easeInOut(duration: 0.2), value: appliedTweakCount > 0)
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

  private func restoreAppliedChanges() {
    optimizationStore.queueRestoreAppliedLaunchTweaks(using: catalogStore)
  }

  private var appVersion: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
      ?? "0.1.0"
  }

  private var pendingChangesLabel: String {
    let count = optimizationStore.pendingCount
    return count == 0 ? "No Pending Changes" : "\(count) Pending Change\(count == 1 ? "" : "s")"
  }

  private var appliedTweakCount: Int {
    optimizationStore.appliedTweakProgress(
      catalog: catalogStore.catalog,
      store: catalogStore
    ).applied
  }

  private var canRestoreAppliedChanges: Bool {
    optimizationStore.canQueueRestoreAppliedLaunchTweaks(
      catalog: catalogStore.catalog,
      store: catalogStore
    )
  }

  private var restoreHelp: String {
    let count = appliedTweakCount
    return "Queue a rollback of \(count) applied System Tweaker change"
      + (count == 1 ? "" : "s")
      + ". Apply to put the services back."
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
    HStack(spacing: 10) {
      Label(
        "\(title): \(isDisabled ? "Disabled" : "Enabled")",
        systemImage: isDisabled ? "checkmark.circle.fill" : "xmark.octagon.fill"
      )
      .foregroundStyle(isDisabled ? Color.green : Color.red)

      if !isDisabled {
        Spacer(minLength: 8)
        Button("Help") {
          optimizationStore.presentRecoveryGuide()
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(Color.accentColor)
      }
    }
  }

  private var executionContent: some View {
    VStack(alignment: .leading, spacing: 14) {
      ProgressView(value: optimizationStore.executionProgress)

      Text(optimizationStore.executionMessage)
        .font(.headline)

      ScrollViewReader { proxy in
        List(optimizationStore.executionLog.indices, id: \.self) { index in
          Label(
            optimizationStore.executionLog[index],
            systemImage: index == optimizationStore.executionLog.indices.last
              ? "chevron.right.circle.fill"
              : "checkmark.circle"
          )
          .foregroundStyle(
            index == optimizationStore.executionLog.indices.last ? .primary : .secondary
          )
          .id(index)
        }
        .listStyle(.inset)
        .defaultScrollAnchor(.bottom)
        .onChange(of: optimizationStore.executionLog.count) { _, count in
          guard count > 0 else { return }
          proxy.scrollTo(count - 1, anchor: .bottom)
        }
      }

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
        VStack(alignment: .leading, spacing: 8) {
          Label(error, systemImage: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)

          if isProtectionError(error) {
            Button("Help") {
              optimizationStore.presentRecoveryGuide()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(Color.accentColor)
          }
        }
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
      } else if optimizationStore.executionPhase == .succeeded {
        if optimizationStore.gatekeeperConfirmationRequired {
          Button("Open Privacy & Security") {
            openPrivacyAndSecuritySettings()
          }
        }
        Button("Restart Now") {
          Task { await optimizationStore.restartSystemWithoutReopeningApplications() }
        }
        .help("Restart without restoring other apps. Tweaker opens after login.")
        .tint(.red)
        .buttonStyle(.borderedProminent)
        .disabled(optimizationStore.restartInProgress)
      }
    }
  }

  private func isProtectionError(_ message: String) -> Bool {
    let lowercased = message.lowercased()
    return lowercased.contains("system integrity protection")
      || lowercased.contains("authenticated root")
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
    .environmentObject(TweakCatalogStore())
    .frame(width: 232, height: 592)
}
