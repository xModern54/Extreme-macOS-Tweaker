import AppKit
import SwiftUI

private enum RecoveryMacKind: String, CaseIterable, Identifiable {
  case appleSilicon
  case intel

  var id: Self { self }

  var title: String {
    switch self {
    case .appleSilicon: "Apple Silicon"
    case .intel: "Intel"
    }
  }
}

struct ProtectionGuideView: View {
  @State private var macKind: RecoveryMacKind = .appleSilicon
  @State private var copiedCommand: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
      Divider()

      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          introCard

          Picker("Mac type", selection: $macKind) {
            ForEach(RecoveryMacKind.allCases) { kind in
              Text(kind.title).tag(kind)
            }
          }
          .pickerStyle(.segmented)
          .labelsHidden()

          ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
            stepCard(number: index + 1, step: step)
          }

          afterCard
        }
        .padding(20)
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Disable SIP")
        .font(.title2.weight(.semibold))

      Text("Step-by-step Recovery guide for System Integrity Protection and Authenticated Root.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 24)
    .padding(.top, 20)
    .padding(.bottom, 16)
  }

  private var introCard: some View {
    guidePanel {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.orange)
          .frame(width: 32, height: 32)
          .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

        VStack(alignment: .leading, spacing: 4) {
          Text("Do this in macOS Recovery, not in the normal desktop.")
            .font(.subheadline.weight(.semibold))
          Text("Tweaker cannot change the system volume while these two locks are on.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding(14)
    }
  }

  private var afterCard: some View {
    guidePanel {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: "arrow.uturn.backward.circle.fill")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(Color.accentColor)
          .frame(width: 32, height: 32)
          .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

        VStack(alignment: .leading, spacing: 4) {
          Text("Come back here after the restart.")
            .font(.subheadline.weight(.semibold))
          Text("Open Extreme macOS Tweaker, press Apply again, and the protection check should pass.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding(14)
    }
  }

  private func stepCard(number: Int, step: GuideStep) -> some View {
    guidePanel {
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .top, spacing: 12) {
          Text("\(number)")
            .font(.subheadline.weight(.bold).monospacedDigit())
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(Color.accentColor, in: Circle())

          VStack(alignment: .leading, spacing: 4) {
            Text(step.title)
              .font(.headline)
            Text(step.detail)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
        }

        if let command = step.command {
          commandRow(command)
        }
      }
      .padding(14)
    }
  }

  private func commandRow(_ command: String) -> some View {
    HStack(spacing: 10) {
      Text(command)
        .font(.system(.body, design: .monospaced))
        .textSelection(.enabled)
        .lineLimit(1)
        .minimumScaleFactor(0.7)

      Spacer(minLength: 8)

      Button(copiedCommand == command ? "Copied" : "Copy") {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
        copiedCommand = command
      }
      .buttonStyle(.bordered)
      .controlSize(.small)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 9)
    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
  }

  private var steps: [GuideStep] {
    switch macKind {
    case .appleSilicon:
      [
        GuideStep(
          title: "Shut down the Mac",
          detail: "Open the Apple menu and choose Shut Down. Wait until the screen is fully black."
        ),
        GuideStep(
          title: "Enter Recovery",
          detail: "Press and hold the power button until you see “Loading startup options”. Click Options, then Continue. Sign in if macOS asks."
        ),
        GuideStep(
          title: "Open Terminal",
          detail: "In the menu bar choose Utilities, then Terminal. You should see a command prompt, not the regular desktop."
        ),
        GuideStep(
          title: "Turn off System Integrity Protection",
          detail: "Paste this command and press Return. If it asks for confirmation, type y and press Return.",
          command: "csrutil disable"
        ),
        GuideStep(
          title: "Turn off Authenticated Root",
          detail: "Paste this command and press Return. Confirm again if it asks. Skip this only if you are not editing system apps.",
          command: "csrutil authenticated-root disable"
        ),
        GuideStep(
          title: "Restart",
          detail: "Paste this command and press Return. The Mac boots back into the normal desktop.",
          command: "reboot"
        ),
      ]
    case .intel:
      [
        GuideStep(
          title: "Restart the Mac",
          detail: "Open the Apple menu and choose Restart."
        ),
        GuideStep(
          title: "Enter Recovery",
          detail: "Immediately hold Command (⌘) and R until the Apple logo or a globe appears. Sign in if macOS asks."
        ),
        GuideStep(
          title: "Open Terminal",
          detail: "In the menu bar choose Utilities, then Terminal. You should see a command prompt, not the regular desktop."
        ),
        GuideStep(
          title: "Turn off System Integrity Protection",
          detail: "Paste this command and press Return. If it asks for confirmation, type y and press Return.",
          command: "csrutil disable"
        ),
        GuideStep(
          title: "Turn off Authenticated Root",
          detail: "Paste this command and press Return. Confirm again if it asks. Skip this only if you are not editing system apps.",
          command: "csrutil authenticated-root disable"
        ),
        GuideStep(
          title: "Restart",
          detail: "Paste this command and press Return. The Mac boots back into the normal desktop.",
          command: "reboot"
        ),
      ]
    }
  }
}

private struct GuideStep {
  let title: String
  let detail: String
  var command: String?
}

private struct GuidePanel<Content: View>: View {
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

private func guidePanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
  GuidePanel(content: content)
}

#Preview {
  ProtectionGuideView()
    .frame(width: 688, height: 592)
}
