import SwiftUI

struct SidebarView: View {
  @Binding var selection: AppSection?

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

            Text("No Pending Changes")
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
          .disabled(true)
          .help("This button becomes available after selecting tweaks")
        }
        .padding(14)
      }
    }
    .navigationTitle("")
  }

  private func applyChanges() {
    // The system change pipeline will be connected after the tweak model is defined.
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
    .frame(width: 232, height: 592)
}
