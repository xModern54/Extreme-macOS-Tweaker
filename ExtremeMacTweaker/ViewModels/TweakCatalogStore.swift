import Combine
import Foundation

@MainActor
final class TweakCatalogStore: ObservableObject {
  @Published private(set) var catalog: TweakCatalog?
  @Published private(set) var sourceDescription = ""
  @Published private(set) var catalogSHA256 = ""
  @Published private(set) var loadingError: String?

  private let loader: TweakCatalogLoader
  private var externalSignature: String
  private var monitor: AnyCancellable?

  init(loader: TweakCatalogLoader = TweakCatalogLoader()) {
    self.loader = loader
    externalSignature = loader.externalSignature()
    reload()

    monitor = Timer.publish(every: 1, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] _ in
        self?.reloadIfExternalCatalogChanged()
      }
  }

  func reload() {
    do {
      let loaded = try loader.load()
      catalog = loaded.catalog
      catalogSHA256 = loaded.sha256
      sourceDescription = switch loaded.source {
      case .bundled: "Bundled catalog"
      case .external(let url): url.path
      }
      loadingError = nil
      externalSignature = loader.externalSignature()
    } catch {
      // Keep the last successfully decoded catalog while a development edit is incomplete.
      loadingError = error.localizedDescription
    }
  }

  func services(for feature: TweakCatalogFeature) -> [TweakCatalogService] {
    guard let catalog else { return [] }

    let groups = Dictionary(uniqueKeysWithValues: catalog.serviceGroups.map { ($0.id, $0) })
    let services = Dictionary(uniqueKeysWithValues: catalog.services.map { ($0.id, $0) })
    let serviceIDs = feature.disableServiceGroups.flatMap { groups[$0]?.services ?? [] }
    return serviceIDs.compactMap { services[$0] }
  }

  private func reloadIfExternalCatalogChanged() {
    let newSignature = loader.externalSignature()
    guard newSignature != externalSignature else { return }
    externalSignature = newSignature
    reload()
  }
}
