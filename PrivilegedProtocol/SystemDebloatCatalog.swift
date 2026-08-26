import Foundation

struct SystemDebloatComponent: Identifiable, Hashable, Sendable {
  enum RemovalBehavior: Hashable, Sendable {
    case removeDirectory
    case removeContents
  }

  enum Category: String, CaseIterable, Sendable {
    case intelligence
    case languageAndSpeech
    case searchAndReference
    case developer
    case updates
    case wallpapers

    var title: String {
      switch self {
      case .intelligence: "Intelligence"
      case .languageAndSpeech: "Language & Speech"
      case .searchAndReference: "Search & Reference"
      case .developer: "Developer"
      case .updates: "Updates"
      case .wallpapers: "Wallpapers"
      }
    }
  }

  let id: String
  let title: String
  let summary: String
  let consequence: String
  let systemImage: String
  let category: Category
  let paths: [String]
  let removalBehavior: RemovalBehavior

  init(
    id: String,
    title: String,
    summary: String,
    consequence: String,
    systemImage: String,
    category: Category,
    paths: [String],
    removalBehavior: RemovalBehavior = .removeDirectory
  ) {
    self.id = id
    self.title = title
    self.summary = summary
    self.consequence = consequence
    self.systemImage = systemImage
    self.category = category
    self.paths = paths
    self.removalBehavior = removalBehavior
  }
}

enum SystemDebloatCatalog {
  private static let assetsRoot = "/System/Library/AssetsV2"
  private static let aerialsPath = "~/Library/Application Support/com.apple.wallpaper/aerials"
  private static let aerialsRelativePath = "Library/Application Support/com.apple.wallpaper/aerials"
  private static let preloadedUpdatePaths: Set<String> = [
    "/System/Volumes/Data/macOS Install Data",
    "/Library/Updates",
    "/System/Volumes/Data/MobileSoftwareUpdate",
  ]

  static let components: [SystemDebloatComponent] = [
    SystemDebloatComponent(
      id: "apple-intelligence-models",
      title: "Apple Intelligence Models",
      summary: "On-device foundation, visual intelligence, and planning models.",
      consequence: "Apple Intelligence and Writing Tools will stop working until macOS downloads the models again.",
      systemImage: "apple.intelligence",
      category: .intelligence,
      paths: assetPaths([
        "com_apple_MobileAsset_UAF_FM_GenerativeModels",
        "com_apple_MobileAsset_UAF_FM_Visual",
        "com_apple_MobileAsset_UAF_FM_Overrides",
        "com_apple_MobileAsset_UAF_IF_Planner",
        "com_apple_MobileAsset_UAF_IF_PlannerOverrides",
        "com_apple_MobileAsset_UAF_SummarizationKitConfiguration",
        "com_apple_MobileAsset_UAF_TKModelMessages",
      ])
    ),
    SystemDebloatComponent(
      id: "photos-clean-up-models",
      title: "Photos Clean Up Models",
      summary: "Machine-learning assets used to remove objects from photos.",
      consequence: "Clean Up in Photos will be unavailable until its models are downloaded again.",
      systemImage: "photo",
      category: .intelligence,
      paths: assetPaths([
        "com_apple_MobileAsset_UAF_Photos_MagicCleanup"
      ])
    ),
    SystemDebloatComponent(
      id: "siri-offline-models",
      title: "Siri Offline Models",
      summary: "Language understanding, dialog, and text-to-speech assets for Siri.",
      consequence: "Siri may lose offline features or become unavailable until macOS restores these assets.",
      systemImage: "waveform",
      category: .intelligence,
      paths: assetPaths([
        "com_apple_MobileAsset_UAF_Siri_Understanding",
        "com_apple_MobileAsset_UAF_Siri_UnderstandingASRHammer",
        "com_apple_MobileAsset_UAF_Siri_UnderstandingNLOverrides",
        "com_apple_MobileAsset_UAF_Siri_TextToSpeech",
        "com_apple_MobileAsset_UAF_Siri_PlatformAssets",
        "com_apple_MobileAsset_UAF_Siri_DialogAssets",
        "com_apple_MobileAsset_UAF_Siri_FindMyConfigurationFiles",
      ])
    ),
    SystemDebloatComponent(
      id: "speech-recognition-models",
      title: "Speech Recognition Models",
      summary: "Downloaded assets for on-device dictation and speech recognition.",
      consequence: "Offline Dictation and other speech-to-text features may stop working until redownloaded.",
      systemImage: "mic",
      category: .languageAndSpeech,
      paths: assetPaths([
        "com_apple_MobileAsset_UAF_Speech_AutomaticSpeechRecognition"
      ])
    ),
    SystemDebloatComponent(
      id: "translation-models",
      title: "Translation Models",
      summary: "Downloaded language models used for on-device translation.",
      consequence: "Offline translation will be unavailable for removed languages until downloaded again.",
      systemImage: "translate",
      category: .languageAndSpeech,
      paths: assetPaths([
        "com_apple_MobileAsset_UAF_Translation_MMAssets"
      ])
    ),
    SystemDebloatComponent(
      id: "linguistic-data",
      title: "Additional Linguistic Data",
      summary: "Downloaded spelling, tokenization, and language-processing resources.",
      consequence: "Typing suggestions, spelling, and language-aware features may be reduced until restored.",
      systemImage: "character.book.closed",
      category: .languageAndSpeech,
      paths: assetPaths([
        "com_apple_MobileAsset_LinguisticData"
      ])
    ),
    SystemDebloatComponent(
      id: "accessibility-speech-assets",
      title: "Accessibility Speech Assets",
      summary: "Downloaded voices and text-to-speech model resources.",
      consequence: "VoiceOver and spoken-content voices may be unavailable until macOS downloads them again.",
      systemImage: "accessibility",
      category: .languageAndSpeech,
      paths: assetPaths([
        "com_apple_MobileAsset_TTSAXResourceModelAssets",
        "com_apple_MobileAsset_VoiceServices_CombinedVocalizerVoices",
        "com_apple_MobileAsset_VoiceServices_CustomVoice",
        "com_apple_MobileAsset_MacinTalkVoiceAssets",
      ])
    ),
    SystemDebloatComponent(
      id: "downloaded-dictionaries",
      title: "Downloaded Dictionaries",
      summary: "Dictionary definitions and reference data installed by macOS.",
      consequence: "Dictionary definitions may be missing until macOS downloads the assets again.",
      systemImage: "books.vertical",
      category: .searchAndReference,
      paths: assetPaths([
        "com_apple_MobileAsset_DictionaryServices_dictionary3macOS"
      ])
    ),
    SystemDebloatComponent(
      id: "spotlight-resources",
      title: "Spotlight Resources",
      summary: "Downloaded resources used by Spotlight search and suggestions.",
      consequence: "Spotlight results and suggestions may be reduced while resources are absent.",
      systemImage: "magnifyingglass",
      category: .searchAndReference,
      paths: assetPaths([
        "com_apple_MobileAsset_SpotlightResources"
      ])
    ),
    SystemDebloatComponent(
      id: "ios-simulator-runtimes",
      title: "iOS Simulator Runtimes",
      summary: "Downloaded iOS runtime images used by Simulator and Xcode.",
      consequence: "Affected Simulator devices will not boot until Xcode downloads their runtimes again.",
      systemImage: "iphone.gen3",
      category: .developer,
      paths: assetPaths([
        "com_apple_MobileAsset_iOSSimulatorRuntime"
      ])
    ),
    SystemDebloatComponent(
      id: "macos-preloaded-update",
      title: "macOS Preloaded Update",
      summary: "Downloaded macOS update and installation data staged for a future update.",
      consequence: "macOS may need to download the update data again before installing an update.",
      systemImage: "arrow.down.circle",
      category: .updates,
      paths: Array(preloadedUpdatePaths).sorted(),
      removalBehavior: .removeContents
    ),
    SystemDebloatComponent(
      id: "downloaded-dynamic-wallpapers",
      title: "Downloaded Dynamic Wallpapers",
      summary: "Downloaded aerial and dynamic wallpaper videos for the current user.",
      consequence: "Removed wallpapers will need to be downloaded again before they can be used.",
      systemImage: "photo.on.rectangle.angled",
      category: .wallpapers,
      paths: [aerialsPath],
      removalBehavior: .removeContents
    ),
  ]

  static func component(withID id: String) -> SystemDebloatComponent? {
    components.first(where: { $0.id == id })
  }

  static func resolvedPaths(
    for component: SystemDebloatComponent,
    homeDirectory: URL
  ) -> [String] {
    component.paths.map { path in
      guard path == aerialsPath else { return path }
      return homeDirectory.appendingPathComponent(aerialsRelativePath).path
    }
  }

  static func isAllowedPath(
    _ path: String,
    for component: SystemDebloatComponent,
    homeDirectory: URL
  ) -> Bool {
    let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
    switch component.removalBehavior {
    case .removeDirectory:
      return standardizedPath.hasPrefix(assetsRoot + "/")
        && !standardizedPath.dropFirst(assetsRoot.count + 1).contains("/")
    case .removeContents:
      if component.id == "macos-preloaded-update" {
        return preloadedUpdatePaths.contains(standardizedPath)
      }
      if component.id == "downloaded-dynamic-wallpapers" {
        let allowedPath = homeDirectory
          .appendingPathComponent(aerialsRelativePath)
          .standardizedFileURL.path
        return standardizedPath == allowedPath
      }
      return false
    }
  }

  private static func assetPaths(_ directoryNames: [String]) -> [String] {
    directoryNames.map { assetsRoot + "/" + $0 }
  }
}
