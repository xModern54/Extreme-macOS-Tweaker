import SwiftUI

struct SidebarView: View {
  @Binding var selection: AppSection?

  var body: some View {
    VStack(spacing: 0) {
      List(selection: $selection) {
        Section("TOOLS") {
          ForEach(AppSection.allCases) { section in
            NavigationLink(value: section) {
              SidebarRow(section: section)
            }
          }
        }
      }
      .listStyle(.sidebar)
      .scrollContentBackground(.hidden)

      Divider()

      VStack(alignment: .leading, spacing: 12) {
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
      .padding(16)
      .background(.ultraThinMaterial)
    }
    .navigationTitle("Mac Extreme Tweaker")
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
        .font(.system(size: 15, weight: .semibold))
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(Color.accentColor)
        .frame(width: 24, height: 24)

      VStack(alignment: .leading, spacing: 1) {
        Text(section.title)
          .fontWeight(.medium)

        Text(section.subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 0)
    }
    .padding(.vertical, 3)
  }
}

#Preview {
  @Previewable @State var selection: AppSection? = .tweaker

  SidebarView(selection: $selection)
    .frame(width: 280, height: 720)
}
