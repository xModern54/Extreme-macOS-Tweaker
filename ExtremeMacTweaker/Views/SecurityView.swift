import SwiftUI

struct SecurityView: View {
  @EnvironmentObject private var optimizationStore: OptimizationStore
  @State private var selectedProtectionID = SecurityProtectionCatalog.protections.first?.id
  @State private var disableConfirmation: SecurityProtection?

  private var protections: [SecurityProtection] {
    SecurityProtectionCatalog.protections
  }

  private var selectedProtection: SecurityProtection? {
    protections.first(where: { $0.id == selectedProtectionID }) ?? protections.first
  }

  var body: some View {
    Group {
      if let selectedProtection {
        workspace(selectedProtection: selectedProtection)
      } else {
        ContentUnavailableView("No Protection Controls", systemImage: "shield.slash")
      }
    }
    .task {
      while !Task.isCancelled {
        await optimizationStore.refreshSecurityProtectionStates()
        try? await Task.sleep(nanoseconds: 5_000_000_000)
      }
    }
    .onChange(of: optimizationStore.executionPhase) { _, phase in
      guard phase == .succeeded else { return }
      Task { await optimizationStore.refreshSecurityProtectionStates() }
    }
    .alert(
      "Apply \(disableConfirmation?.title ?? "this override")?",
      isPresented: Binding(
        get: { disableConfirmation != nil },
        set: { if !$0 { disableConfirmation = nil } }
      )
    ) {
      Button("Apply", role: .destructive) {
        if let protection = disableConfirmation {
          optimizationStore.setSecurityTweak(protection, applied: true)
        }
        disableConfirmation = nil
      }
      Button("Cancel", role: .cancel) {
        disableConfirmation = nil
      }
    } message: {
      Text(confirmationMessage)
    }
  }

  private func workspace(selectedProtection: SecurityProtection) -> some View {
    GeometryReader { geometry in
      let inspectorWidth = min(280, max(225, geometry.size.width * 0.36))

      HStack(spacing: 0) {
        protectionBrowser
          .frame(
            width: max(0, geometry.size.width - inspectorWidth - 1),
            height: geometry.size.height
          )

        Divider()

        SecurityProtectionInspector(
          protection: selectedProtection,
          isApplied: optimizationStore.securityTweakIsApplied(selectedProtection)
        )
        .frame(width: inspectorWidth, height: geometry.size.height)
      }
    }
  }

  private var protectionBrowser: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 6) {
        Text("Security")
          .font(.title2.weight(.semibold))

        Text("Choose which security overrides to apply. All of them are off by default.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 24)
      .padding(.top, 20)
      .padding(.bottom, 16)

      Divider()

      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          VStack(alignment: .leading, spacing: 9) {
            Text("Overrides")
              .font(.caption.weight(.semibold))
              .foregroundStyle(.secondary)
              .textCase(.uppercase)

            VStack(spacing: 0) {
              ForEach(Array(protections.enumerated()), id: \.element.id) { index, protection in
                SecurityProtectionRow(
                  protection: protection,
                  isApplied: binding(for: protection),
                  isSelected: selectedProtectionID == protection.id
                )
                .contentShape(Rectangle())
                .onTapGesture { selectedProtectionID = protection.id }

                if index < protections.count - 1 {
                  Divider().padding(.leading, 58)
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
        .padding(20)
      }
    }
  }

  private func binding(for protection: SecurityProtection) -> Binding<Bool> {
    Binding(
      get: { optimizationStore.securityTweakIsApplied(protection) },
      set: { applied in
        selectedProtectionID = protection.id
        if applied,
          protection.confirmsBeforeDisable,
          !optimizationStore.securityTweakIsApplied(protection)
        {
          disableConfirmation = protection
          return
        }
        optimizationStore.setSecurityTweak(protection, applied: applied)
      }
    )
  }

  private var confirmationMessage: String {
    switch disableConfirmation?.id {
    case "download-whitelist":
      "This writes a system LaunchDaemon onto the signed system volume that strips the quarantine flag from files in Downloads. A restart is required."
    case "system-policy":
      "This stops syspolicyd, turns off LaunchServices quarantine, and also turns on Global Item Whitelist. Power users only."
    case "user-autostarts":
      "This fully disables user-space software autostarts. Other apps will not be able to add LaunchAgents, and existing user-space launch agents will stop starting."
    default:
      disableConfirmation?.disableConsequence
        ?? "This applies a security override."
    }
  }
}

private struct SecurityProtectionRow: View {
  let protection: SecurityProtection
  @Binding var isApplied: Bool
  let isSelected: Bool

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: protection.systemImage)
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(isSelected ? Color.white : Color.accentColor)
        .frame(width: 32, height: 32)
        .background(
          isSelected ? Color.accentColor : Color.accentColor.opacity(0.1),
          in: RoundedRectangle(cornerRadius: 8)
        )

      Text(protection.title)
        .font(.body.weight(.medium))
        .lineLimit(1)

      Spacer(minLength: 8)

      Text(isApplied ? "On" : "Off")
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.accentColor)
        .padding(.horizontal, 9)
        .frame(height: 24)
        .background(Color.accentColor.opacity(0.1), in: Capsule())
        .fixedSize()

      Toggle("", isOn: $isApplied)
        .labelsHidden()
        .toggleStyle(.checkbox)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
  }
}

private struct SecurityProtectionInspector: View {
  let protection: SecurityProtection
  let isApplied: Bool

  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          inspectorHeader
          behaviorSection
          implementationSection
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
        Image(systemName: protection.systemImage)
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(Color.accentColor)
          .frame(width: 42, height: 42)
          .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

        VStack(alignment: .leading, spacing: 4) {
          Text(protection.title)
            .font(.headline)

          Text(isApplied ? "On" : "Off")
            .font(.caption.weight(.medium))
            .foregroundStyle(isApplied ? Color.orange : Color.secondary)
        }
      }

      Text(protection.question)
        .font(.subheadline.weight(.medium))
        .fixedSize(horizontal: false, vertical: true)

      Text(protection.summary)
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var behaviorSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionTitle(isApplied ? "When Applied" : "Default")

      Text(isApplied ? protection.disableConsequence : idleDescription)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var implementationSection: some View {
    VStack(alignment: .leading, spacing: 9) {
      sectionTitle(protection.services.isEmpty ? "System Control" : "Related Services")

      if protection.services.isEmpty {
        Text(implementationDetail)
          .font(.caption.monospaced())
          .foregroundStyle(.secondary)
          .textSelection(.enabled)
      } else {
        ForEach(protection.services) { service in
          HStack(alignment: .firstTextBaseline, spacing: 6) {
            Circle()
              .fill(isApplied ? Color.accentColor : Color.secondary.opacity(0.45))
              .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 1) {
              Text(service.label)
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
              Text(service.domain.rawValue)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
          }
        }
      }
    }
  }

  private var idleDescription: String {
    switch protection.kind {
    case .gatekeeper:
      "Gatekeeper stays on and assesses downloaded applications before they open."
    case .launchServices:
      "The related macOS protection services keep running."
    case .dequarantine:
      "Downloads keep the quarantine flag that macOS assigns to them."
    }
  }

  private var implementationDetail: String {
    switch protection.kind {
    case .gatekeeper:
      "spctl --global-\(isApplied ? "disable" : "enable")"
    case .dequarantine:
      "/usr/libexec/extrememactweaker.dequarantine"
    case .launchServices:
      ""
    }
  }

  private func sectionTitle(_ title: String) -> some View {
    Text(title)
      .font(.caption.weight(.semibold))
      .foregroundStyle(.secondary)
      .textCase(.uppercase)
  }
}

#Preview {
  SecurityView()
    .environmentObject(OptimizationStore())
    .frame(width: 900, height: 620)
}
