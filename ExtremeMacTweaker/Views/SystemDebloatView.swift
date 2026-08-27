import AppKit
import SwiftUI

struct SystemDebloatView: View {
  @StateObject private var model = SystemDebloatViewModel()
  @EnvironmentObject private var optimizationStore: OptimizationStore

  private var selectedSizeInBytes: Int64 {
    model.items.reduce(0) { total, item in
      total + (optimizationStore.isSystemComponentSelected(item.id) ? item.sizeInBytes : 0)
    }
  }

  private var selectedSizeIsIncomplete: Bool {
    model.items.contains {
      $0.sizeIsIncomplete && optimizationStore.isSystemComponentSelected($0.id)
    }
  }

  private var hasIncompleteSizes: Bool {
    model.items.contains(where: \.requiresDataAccess)
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
      if hasIncompleteSizes {
        incompleteSizeNotice
      }
      Divider()

      ScrollView {
        LazyVStack(alignment: .leading, spacing: 20) {
          ForEach(SystemDebloatComponent.Category.allCases, id: \.self) { category in
            let categoryItems = model.items.filter { $0.component.category == category }
            if !categoryItems.isEmpty {
              categorySection(category: category, items: categoryItems)
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

        Text("Review optional macOS downloads, models, indexes, and caches.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 3) {
        Text((selectedSizeIsIncomplete ? "At least " : "") + formattedSize(selectedSizeInBytes))
          .font(.headline.monospacedDigit())
          .foregroundStyle(selectedSizeInBytes > 0 ? Color.accentColor : Color.secondary)
        Text(
          selectedSizeIsIncomplete
            ? "Selected size is incomplete"
            : (selectedSizeInBytes > 0 ? "Selected to remove" : "Nothing selected")
        )
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

  private var incompleteSizeNotice: some View {
    HStack(spacing: 10) {
      Image(systemName: "externaldrive.badge.exclamationmark")
        .foregroundStyle(.orange)

      VStack(alignment: .leading, spacing: 2) {
        Text("Data Access Required")
          .font(.caption.weight(.semibold))
        Text("Please allow Tweaker to access other app data in Privacy & Security to show protected asset sizes.")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Button("Open Privacy Settings") {
        openPrivacyAndSecuritySettings()
      }
      .controlSize(.small)
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 10)
    .background(Color.orange.opacity(0.08))
  }

  private func categorySection(
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
      optimizationStore.setSystemComponent(
        item.component,
        sizeInBytes: item.sizeInBytes,
        selected: selected
      )
    }
  }

  private func formattedSize(_ bytes: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
  }

  private func openPrivacyAndSecuritySettings() {
    guard let url = URL(
      string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension"
    ) else { return }
    NSWorkspace.shared.open(url)
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

        if isSelected, !item.component.consequence.isEmpty {
          Text(item.component.consequence)
            .font(.caption2)
            .foregroundStyle(.orange)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      Spacer(minLength: 10)

      if let sizeLabel {
        Text(sizeLabel)
          .font(.caption.weight(.semibold).monospacedDigit())
          .foregroundStyle(item.requiresDataAccess ? Color.orange : Color.accentColor)
          .padding(.horizontal, 9)
          .frame(height: 24)
          .background(
            (item.requiresDataAccess ? Color.orange : Color.accentColor).opacity(0.1),
            in: Capsule()
          )
          .fixedSize()
      }

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
      (item.requiresDataAccess
        ? "Data access required, "
        : sizeLabel.map { "\($0), " } ?? "")
        + (isSelected ? "selected for removal" : "kept")
    )
  }

  private var sizeLabel: String? {
    if item.requiresDataAccess {
      return "Access Required"
    }
    if item.sizeIsIncomplete {
      return nil
    }
    return ByteCountFormatter.string(fromByteCount: item.sizeInBytes, countStyle: .file)
  }

  private var selectionBinding: Binding<Bool> {
    Binding(
      get: { isSelected },
      set: {
        optimizationStore.setSystemComponent(
          item.component,
          sizeInBytes: item.sizeInBytes,
          selected: $0
        )
      }
    )
  }
}

#Preview {
  SystemDebloatView()
    .environmentObject(OptimizationStore())
    .frame(width: 820, height: 620)
}
