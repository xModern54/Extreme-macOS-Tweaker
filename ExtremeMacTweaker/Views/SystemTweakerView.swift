import SwiftUI

struct SystemTweakerView: View {
  @State private var selectedFeatureID = SystemTweakFeature.previewData[0].id
  @State private var choices: [String: SystemTweakChoice] = [:]

  private let features = SystemTweakFeature.previewData

  private var selectedFeature: SystemTweakFeature {
    features.first(where: { $0.id == selectedFeatureID }) ?? features[0]
  }

  var body: some View {
    GeometryReader { geometry in
      let inspectorWidth = min(260, max(210, geometry.size.width * 0.34))

      HStack(spacing: 0) {
        featureBrowser
          .frame(
            width: max(0, geometry.size.width - inspectorWidth - 1),
            height: geometry.size.height
          )

        Divider()

        SystemTweakInspector(
          feature: selectedFeature,
          choice: choices[selectedFeature.id, default: .keepEnabled]
        )
        .frame(width: inspectorWidth, height: geometry.size.height)
      }
    }
  }

  private var featureBrowser: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 6) {
        Text("System Tweaker")
          .font(.title2.weight(.semibold))

        Text("Select the macOS features you use.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(.horizontal, 24)
      .padding(.top, 20)
      .padding(.bottom, 16)

      Divider()

      ScrollView {
        LazyVStack(alignment: .leading, spacing: 20) {
          ForEach(SystemTweakCategory.allCases) { category in
            let categoryFeatures = features.filter { $0.category == category }

            VStack(alignment: .leading, spacing: 9) {
              Label(category.title, systemImage: category.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

              VStack(spacing: 0) {
                ForEach(Array(categoryFeatures.enumerated()), id: \.element.id) { index, feature in
                  SystemTweakFeatureRow(
                    feature: feature,
                    choice: binding(for: feature),
                    isSelected: selectedFeatureID == feature.id
                  )
                  .contentShape(Rectangle())
                  .onTapGesture {
                    selectedFeatureID = feature.id
                  }

                  if index < categoryFeatures.count - 1 {
                    Divider()
                      .padding(.leading, 54)
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
        }
        .padding(20)
      }
    }
  }

  private func binding(for feature: SystemTweakFeature) -> Binding<SystemTweakChoice> {
    Binding(
      get: { choices[feature.id, default: .keepEnabled] },
      set: { newValue in
        choices[feature.id] = newValue
        selectedFeatureID = feature.id
      }
    )
  }
}

private struct SystemTweakFeatureRow: View {
  let feature: SystemTweakFeature
  @Binding var choice: SystemTweakChoice
  let isSelected: Bool

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: feature.systemImage)
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(isSelected ? Color.white : Color.accentColor)
        .frame(width: 32, height: 32)
        .background(
          isSelected ? Color.accentColor : Color.accentColor.opacity(0.1),
          in: RoundedRectangle(cornerRadius: 8)
        )

      VStack(alignment: .leading, spacing: 2) {
        Text(feature.title)
          .font(.body.weight(.medium))
          .lineLimit(1)
      }

      Spacer(minLength: 8)

      Toggle("", isOn: keepEnabledBinding)
        .labelsHidden()
        .toggleStyle(.checkbox)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
  }

  private var keepEnabledBinding: Binding<Bool> {
    Binding(
      get: { choice == .keepEnabled },
      set: { choice = $0 ? .keepEnabled : .disable }
    )
  }
}

private struct SystemTweakInspector: View {
  let feature: SystemTweakFeature
  let choice: SystemTweakChoice

  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          inspectorHeader
          impactSection
          guidanceSection
          servicesSection
        }
        .frame(
          width: max(0, geometry.size.width - 32),
          alignment: .leading
        )
        .padding(16)
      }
    }
    .background(Color(nsColor: .controlBackgroundColor).opacity(0.72))
  }

  private var inspectorHeader: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: feature.systemImage)
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(Color.accentColor)
          .frame(width: 42, height: 42)
          .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

        VStack(alignment: .leading, spacing: 4) {
          Text(feature.title)
            .font(.headline)
            .lineLimit(2)
            .minimumScaleFactor(0.8)

          Text(choice == .disable ? "Selected for disabling" : "Kept enabled")
            .font(.caption.weight(.medium))
            .foregroundStyle(choice == .disable ? Color.orange : Color.green)
        }
      }

      Text(feature.question)
        .font(.subheadline.weight(.medium))
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)

      Text(feature.description)
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var impactSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionTitle("Estimated Impact")

      HStack(spacing: 7) {
        Image(systemName: "memorychip")
          .foregroundStyle(Color.accentColor)
        Text(feature.memoryEstimate)
          .font(.subheadline.weight(.medium).monospacedDigit())
        Text("·")
          .foregroundStyle(.tertiary)
        Text("\(feature.processEstimate) process\(feature.processEstimate == 1 ? "" : "es")")
          .font(.subheadline.monospacedDigit())
          .foregroundStyle(.secondary)
      }
    }
  }

  private var guidanceSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      sectionTitle("When to Disable")

      Text(feature.disableGuidance)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var servicesSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        sectionTitle("Related Services")
        Spacer()
        Text("\(feature.services.count)")
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
      }

      VStack(alignment: .leading, spacing: 7) {
        ForEach(feature.services, id: \.self) { service in
          Text(service)
            .font(.caption2.monospaced())
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
  }

  private func sectionTitle(_ title: String) -> some View {
    Text(title)
      .font(.caption.weight(.semibold))
      .foregroundStyle(.secondary)
      .textCase(.uppercase)
  }
}

private enum SystemTweakChoice: String, CaseIterable, Identifiable {
  case keepEnabled
  case disable

  var id: Self { self }

  var title: String {
    switch self {
    case .keepEnabled: "Keep"
    case .disable: "Disable"
    }
  }
}

private enum SystemTweakCategory: String, CaseIterable, Identifiable {
  case searchAndIntelligence
  case connectivity
  case systemServices

  var id: Self { self }

  var title: String {
    switch self {
    case .searchAndIntelligence: "Search & Intelligence"
    case .connectivity: "Connectivity"
    case .systemServices: "System Services"
    }
  }

  var systemImage: String {
    switch self {
    case .searchAndIntelligence: "sparkles"
    case .connectivity: "antenna.radiowaves.left.and.right"
    case .systemServices: "gearshape.2"
    }
  }
}

private struct SystemTweakFeature: Identifiable {
  let id: String
  let title: String
  let question: String
  let description: String
  let disableGuidance: String
  let memoryEstimate: String
  let processEstimate: Int
  let systemImage: String
  let category: SystemTweakCategory
  let services: [String]

  static let previewData: [SystemTweakFeature] = [
    SystemTweakFeature(
      id: "spotlight",
      title: "Spotlight Search",
      question: "Do you use Spotlight to find files and applications?",
      description: "Indexes files, application metadata, messages, and other searchable content across macOS.",
      disableGuidance: "Disable this only if you use another launcher and do not rely on Finder or Spotlight content search.",
      memoryEstimate: "~120 MB",
      processEstimate: 4,
      systemImage: "magnifyingglass",
      category: .searchAndIntelligence,
      services: [
        "com.apple.metadata.mds",
        "com.apple.metadata.mds.index",
        "com.apple.metadata.mds.scan",
        "com.apple.Spotlight",
      ]
    ),
    SystemTweakFeature(
      id: "siri",
      title: "Siri & Dictation",
      question: "Do you use Siri or voice dictation?",
      description: "Provides voice activation, speech recognition, Siri suggestions, and system-wide dictation services.",
      disableGuidance: "Disable this when you never use Siri, voice shortcuts, or the dictation key in text fields.",
      memoryEstimate: "~85 MB",
      processEstimate: 3,
      systemImage: "waveform",
      category: .searchAndIntelligence,
      services: [
        "com.apple.assistantd",
        "com.apple.siriactionsd",
        "com.apple.DictationIM",
      ]
    ),
    SystemTweakFeature(
      id: "airplay",
      title: "AirPlay Receiver",
      question: "Do you stream content to this Mac with AirPlay?",
      description: "Allows nearby Apple devices to discover this Mac as an AirPlay audio and video destination.",
      disableGuidance: "Disable this if this Mac is never used as an AirPlay receiver or wireless presentation display.",
      memoryEstimate: "~45 MB",
      processEstimate: 2,
      systemImage: "airplayvideo",
      category: .connectivity,
      services: [
        "com.apple.AirPlayXPCHelper",
        "com.apple.airplayreceiverd",
      ]
    ),
    SystemTweakFeature(
      id: "icloud",
      title: "iCloud Synchronization",
      question: "Do you synchronize files and application data with iCloud?",
      description: "Keeps iCloud Drive, CloudKit data, documents, and supported application state synchronized.",
      disableGuidance: "Disable this only on a Mac that does not use iCloud Drive, CloudKit applications, or Apple device synchronization.",
      memoryEstimate: "~160 MB",
      processEstimate: 5,
      systemImage: "icloud",
      category: .connectivity,
      services: [
        "com.apple.bird",
        "com.apple.cloudd",
        "com.apple.cloudpaird",
        "com.apple.cloudphotod",
        "com.apple.icloud.findmydeviced",
      ]
    ),
    SystemTweakFeature(
      id: "screen-time",
      title: "Screen Time",
      question: "Do you use usage reports or application limits?",
      description: "Collects device usage statistics and enforces downtime, content restrictions, and application limits.",
      disableGuidance: "Disable this if you do not review Screen Time reports and do not use parental or application restrictions.",
      memoryEstimate: "~35 MB",
      processEstimate: 2,
      systemImage: "hourglass",
      category: .systemServices,
      services: [
        "com.apple.ScreenTimeAgent",
        "com.apple.screentimediagnose",
      ]
    ),
    SystemTweakFeature(
      id: "location",
      title: "Location Services",
      question: "Do applications need the location of this Mac?",
      description: "Determines the approximate location of this Mac for applications, time zones, Find My, and system suggestions.",
      disableGuidance: "Disable this only if maps, automatic time zones, Find My, and location-aware applications are unnecessary.",
      memoryEstimate: "~30 MB",
      processEstimate: 1,
      systemImage: "location",
      category: .systemServices,
      services: [
        "com.apple.locationd",
      ]
    ),
  ]
}

#Preview {
  SystemTweakerView()
    .frame(width: 900, height: 620)
}
