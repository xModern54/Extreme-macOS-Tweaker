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
    optimizationStore.isReviewPresented = true
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
      VStack(alignment: .leading, spacing: 5) {
        Text("Review Changes")
          .font(.title2.weight(.semibold))
        Text("The execution engine and privileged helper will be connected next.")
          .foregroundStyle(.secondary)
      }

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

      HStack {
        Button("Cancel") { dismiss() }
          .keyboardShortcut(.cancelAction)
        Spacer()
        Button("Apply Changes") {}
          .buttonStyle(.borderedProminent)
          .disabled(true)
          .help("Privileged execution is not connected yet")
      }
    }
    .padding(24)
    .frame(width: 560, height: 480)
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
