import Foundation

struct SystemDebloatComponent: Identifiable, Hashable, Sendable {
  enum RemovalBehavior: Hashable, Sendable {
    case removeDirectory
    case removeContents
    case removeVolatileContents
  }

  enum Category: String, CaseIterable, Sendable {
    case intelligence
    case languageAndSpeech
    case searchAndReference
    case diagnostics
    case developer
    case updates
    case appearance

    var title: String {
      switch self {
      case .intelligence: "Intelligence"
      case .languageAndSpeech: "Language & Speech"
      case .searchAndReference: "Search & Reference"
      case .diagnostics: "Diagnostics"
      case .developer: "Developer"
      case .updates: "Updates"
      case .appearance: "Appearance"
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
  private static let dataAssetsRoot = "/System/Volumes/Data/System/Library/AssetsV2"
  private static let spatialPhotosManifestPath = dataAssetsRoot
    + "/manifests/com_apple_MobileAsset_UAF_Photos_SpatialPhotosRelive"
  private static let anedCachePath = "/Library/Caches/com.apple.aned"
  private static let iconCachePath = "/Library/Caches/com.apple.iconservices.store"
  private static let trialDataPath = "/Library/Trial"
  private static let aerialsPath = "~/Library/Application Support/com.apple.wallpaper/aerials"
  private static let personalIntelligencePaths: Set<String> = [
    "~/Library/Containers/com.apple.mediaanalysisd",
    "~/Library/Metadata/CoreSpotlight",
    "~/Library/Group Containers/group.com.apple.SiriTTS",
    "~/Library/DuetExpertCenter",
    "~/Library/Biome",
  ]
  private static let preloadedUpdatePaths: Set<String> = [
    "/System/Volumes/Data/macOS Install Data",
    "/Library/Updates",
    "/System/Volumes/Data/MobileSoftwareUpdate",
  ]
  private static let logAndAnalyticsCachePaths: Set<String> = [
    "/Library/Logs/DiagnosticReports",
    "/private/var/db/diagnostics",
    "/private/var/db/uuidtext",
    "/private/var/db/DiagnosticPipeline",
    "/private/var/db/Spotlight-V100/BootVolume",
    "/private/var/db/systemstats",
    "/private/var/db/analyticsd",
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
      id: "spatial-photos-models",
      title: "Spatial Photos Models",
      summary: "Downloaded machine-learning assets used to relive and process spatial photos.",
      consequence: "Spatial Photos processing may be unavailable until macOS downloads the models again.",
      systemImage: "photo.stack",
      category: .intelligence,
      paths: dataAssetPaths([
        "com_apple_MobileAsset_UAF_Photos_SpatialPhotosRelive"
      ]) + [spatialPhotosManifestPath]
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
      id: "siri-voice-caches",
      title: "Siri Voice Caches",
      summary: "Voice-trigger, speaker-recognition, and speech-endpoint assets used by Siri.",
      consequence: "Remove these assets only if you do not use Siri; voice activation and recognition may stop working until macOS downloads them again.",
      systemImage: "waveform.badge.mic",
      category: .intelligence,
      paths: dataAssetPaths([
        "com_apple_MobileAsset_VoiceTriggerAssetsASMac",
        "com_apple_MobileAsset_VoiceTriggerAssets",
        "com_apple_MobileAsset_VoiceTriggerAssetsStudioDisplay",
        "com_apple_MobileAsset_SpeakerRecognitionASMacAssets",
        "com_apple_MobileAsset_SpeechEndpointMacOSAssets",
        "com_apple_MobileAsset_VoiceTriggerAssetsMac",
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
      ]) + dataAssetPaths([
        "com_apple_MobileAsset_UAF_Translation_Assets"
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
      ]) + dataAssetPaths([
        "com_apple_MobileAsset_UAF_LinguisticData"
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
      id: "spotlight-and-siri-caches",
      title: "Spotlight and Siri Caches",
      summary: "Downloaded query-understanding, suggestion, and Spotlight resource models.",
      consequence: "Spotlight and Siri suggestions may be reduced until macOS downloads these assets again.",
      systemImage: "magnifyingglass.circle",
      category: .intelligence,
      paths: dataAssetPaths([
        "com_apple_MobileAsset_UAF_SearchQueryUnderstanding",
        "com_apple_MobileAsset_CoreSuggestions",
        "com_apple_MobileAsset_UAF_SearchQueryUnderstandingOverrides",
        "com_apple_MobileAsset_CoreSuggestionsModels",
        "com_apple_MobileAsset_SpotlightResources",
      ])
    ),
    SystemDebloatComponent(
      id: "shortcuts-generator-model",
      title: "Shortcuts Generator Model",
      summary: "Downloaded generative model assets used to create and suggest shortcuts.",
      consequence: "Shortcuts generation and intelligent suggestions may be unavailable until the model is downloaded again.",
      systemImage: "wand.and.stars",
      category: .intelligence,
      paths: dataAssetPaths([
        "com_apple_MobileAsset_UAF_Shortcuts_Generator"
      ])
    ),
    SystemDebloatComponent(
      id: "npu-graph-caches",
      title: "NPU Graph Caches",
      summary: "Compiled neural-network graphs used by Siri, Apple Intelligence, and other system models.",
      consequence: "macOS will recompile neural graphs as affected intelligence features are used again.",
      systemImage: "cpu",
      category: .intelligence,
      paths: [anedCachePath],
      removalBehavior: .removeContents
    ),
    SystemDebloatComponent(
      id: "personal-intelligence-data",
      title: "Personal Intelligence Data",
      summary: "On-device media analysis, Spotlight indexes, Siri speech data, and personalized activity models.",
      consequence: "Photos and Spotlight may reindex data, Siri voices may be downloaded again, and personalized suggestions may be temporarily reset.",
      systemImage: "person.crop.circle.badge.sparkles",
      category: .intelligence,
      paths: Array(personalIntelligencePaths).sorted(),
      removalBehavior: .removeVolatileContents
    ),
    SystemDebloatComponent(
      id: "log-and-analytics-caches",
      title: "Log and Analytics Caches",
      summary: "Persistent system logs, diagnostics, analytics, system statistics, and Spotlight index data.",
      consequence: "Historical logs, reports, statistics, and index data will be discarded and may be recreated by macOS.",
      systemImage: "waveform.path.ecg",
      category: .diagnostics,
      paths: Array(logAndAnalyticsCachePaths).sorted(),
      removalBehavior: .removeVolatileContents
    ),
    SystemDebloatComponent(
      id: "apple-feature-experiment-data",
      title: "Apple Feature Experiment Data",
      summary: "Downloaded data used by Apple's Trial framework for feature experiments.",
      consequence: "",
      systemImage: "testtube.2",
      category: .diagnostics,
      paths: [trialDataPath],
      removalBehavior: .removeVolatileContents
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
      category: .appearance,
      paths: [aerialsPath],
      removalBehavior: .removeContents
    ),
    SystemDebloatComponent(
      id: "icon-caches",
      title: "Icon Caches",
      summary: "Compiled icon data used by macOS to display application and system icons.",
      consequence: "Icons may appear slowly or temporarily blank while macOS rebuilds the cache.",
      systemImage: "app.dashed",
      category: .appearance,
      paths: [iconCachePath],
      removalBehavior: .removeVolatileContents
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
      guard path.hasPrefix("~/") else { return path }
      return homeDirectory.appendingPathComponent(String(path.dropFirst(2))).path
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
      if component.id == "spatial-photos-models",
        standardizedPath == spatialPhotosManifestPath
      {
        return true
      }
      return isDirectChild(standardizedPath, of: assetsRoot)
        || isDirectChild(standardizedPath, of: dataAssetsRoot)
    case .removeContents, .removeVolatileContents:
      if component.id == "macos-preloaded-update" {
        return preloadedUpdatePaths.contains(standardizedPath)
      }
      if component.id == "downloaded-dynamic-wallpapers" {
        let allowedPath = resolvedUserPath(aerialsPath, homeDirectory: homeDirectory)
        return standardizedPath == allowedPath
      }
      if component.id == "npu-graph-caches" {
        return standardizedPath == anedCachePath
      }
      if component.id == "icon-caches" {
        return standardizedPath == iconCachePath
      }
      if component.id == "log-and-analytics-caches" {
        return logAndAnalyticsCachePaths.contains(standardizedPath)
      }
      if component.id == "apple-feature-experiment-data" {
        return standardizedPath == trialDataPath
      }
      if component.id == "personal-intelligence-data" {
        let allowedPaths = Set(personalIntelligencePaths.map {
          resolvedUserPath($0, homeDirectory: homeDirectory)
        })
        return allowedPaths.contains(standardizedPath)
      }
      return false
    }
  }

  private static func assetPaths(_ directoryNames: [String]) -> [String] {
    directoryNames.map { assetsRoot + "/" + $0 }
  }

  private static func dataAssetPaths(_ directoryNames: [String]) -> [String] {
    directoryNames.map { dataAssetsRoot + "/" + $0 }
  }

  private static func isDirectChild(_ path: String, of root: String) -> Bool {
    path.hasPrefix(root + "/")
      && !path.dropFirst(root.count + 1).contains("/")
  }

  private static func resolvedUserPath(_ path: String, homeDirectory: URL) -> String {
    homeDirectory
      .appendingPathComponent(String(path.dropFirst(2)))
      .standardizedFileURL.path
  }
}
