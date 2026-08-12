import SwiftUI

struct SystemDebloatView: View {
  @StateObject private var model = SystemDebloatViewModel()
  @EnvironmentObject private var optimizationStore: OptimizationStore

  private var selectedSizeInBytes: Int64 {
    model.items.reduce(0) { total, item in
      total + (optimizationStore.isSystemComponentSelected(item.id) ? item.sizeInBytes : 0)
    }
  }

  var body: some View {
    Group {
      if model.isLoading {
        ProgressView("Scanning Optional System Assets…")
          .controlSize(.small)
      } else if model.items.isEmpty {
        ContentUnavailableView(
          "No Removable Assets Found",
          systemImage: "shippingbox",
          description: Text("This Mac does not currently have any supported optional asset packages installed.")
        )
      } else {
        content
      }
    }
    .task { await model.load() }
    .onChange(of: optimizationStore.executionPhase) { _, phase in
      guard phase == .succeeded else { return }
      Task { await model.load() }
    }
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
      Divider()

      ScrollView {
        LazyVStack(alignment: .leading, spacing: 20) {
          warning

          ForEach(SystemDebloatComponent.Category.allCases, id: \.self) { category in
            let categoryItems = model.items.filter { $0.component.category == category }
            if !categoryItems.isEmpty {
              componentSection(category: category, items: categoryItems)
            }
          }
        }
        .padding(20)
      }
    }
  }

  private var header: some View {
    HStack(alignment: .center, spacing: 18) {
      VStack(alignment: .leading, spacing: 4) {
        Text("System Debloat")
          .font(.title2.weight(.semibold))

        Text("Remove optional macOS assets stored on the Data volume.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 3) {
        Text(formattedSize(selectedSizeInBytes))
          .font(.headline.monospacedDigit())
          .foregroundStyle(selectedSizeInBytes > 0 ? Color.accentColor : Color.secondary)
        Text(selectedSizeInBytes > 0 ? "Selected to remove" : "Nothing selected")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Button(allItemsAreSelected ? "Clear" : "Select All") {
        setAllSelected(!allItemsAreSelected)
      }
      .disabled(model.items.isEmpty)
    }
    .padding(.horizontal, 24)
    .padding(.top, 20)
    .padding(.bottom, 16)
  }

  private var warning: some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.orange)

      VStack(alignment: .leading, spacing: 3) {
        Text("Features may stop working until macOS downloads their assets again.")
          .font(.subheadline.weight(.medium))
        Text("Applying these changes requires System Integrity Protection to be disabled. The System volume and boot snapshot are not modified.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    .overlay {
      RoundedRectangle(cornerRadius: 10)
        .stroke(Color.orange.opacity(0.22), lineWidth: 1)
    }
  }

  private func componentSection(
    category: SystemDebloatComponent.Category,
    items: [SystemDebloatItem]
  ) -> some View {
    VStack(alignment: .leading, spacing: 9) {
      Text(category.title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      VStack(spacing: 0) {
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
          SystemDebloatRow(item: item)
            .environmentObject(optimizationStore)

          if index < items.count - 1 {
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

  private var allItemsAreSelected: Bool {
    !model.items.isEmpty && model.items.allSatisfy {
      optimizationStore.isSystemComponentSelected($0.id)
    }
  }

  private func setAllSelected(_ selected: Bool) {
    for item in model.items {
      optimizationStore.setSystemComponent(item.component, selected: selected)
    }
  }

  private func formattedSize(_ bytes: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
  }
}

private struct SystemDebloatRow: View {
  let item: SystemDebloatItem
  @EnvironmentObject private var optimizationStore: OptimizationStore

  private var isSelected: Bool {
    optimizationStore.isSystemComponentSelected(item.id)
  }

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      Image(systemName: item.component.systemImage)
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(isSelected ? Color.white : Color.accentColor)
        .frame(width: 34, height: 34)
        .background(
          isSelected ? Color.accentColor : Color.accentColor.opacity(0.1),
          in: RoundedRectangle(cornerRadius: 8)
        )

      VStack(alignment: .leading, spacing: 3) {
        Text(item.component.title)
          .font(.body.weight(.medium))

        Text(item.component.summary)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)

        if isSelected {
          Text(item.component.consequence)
            .font(.caption2)
            .foregroundStyle(.orange)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      Spacer(minLength: 10)

      Text(ByteCountFormatter.string(fromByteCount: item.sizeInBytes, countStyle: .file))
        .font(.caption.weight(.semibold).monospacedDigit())
        .foregroundStyle(Color.accentColor)
        .padding(.horizontal, 9)
        .frame(height: 24)
        .background(Color.accentColor.opacity(0.1), in: Capsule())
        .fixedSize()

      Toggle("", isOn: selectionBinding)
        .labelsHidden()
        .toggleStyle(.checkbox)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(isSelected ? Color.accentColor.opacity(0.05) : Color.clear)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(item.component.title)
    .accessibilityValue(
      "\(ByteCountFormatter.string(fromByteCount: item.sizeInBytes, countStyle: .file)), "
        + (isSelected ? "selected for removal" : "kept")
    )
  }

  private var selectionBinding: Binding<Bool> {
    Binding(
      get: { isSelected },
      set: { optimizationStore.setSystemComponent(item.component, selected: $0) }
    )
  }
}

#Preview {
  SystemDebloatView()
    .environmentObject(OptimizationStore())
    .frame(width: 820, height: 620)
}
