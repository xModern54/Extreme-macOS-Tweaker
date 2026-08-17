import Combine
import Foundation

@MainActor
final class HostMetricsStore: ObservableObject {
  @Published private(set) var metrics: HostMetrics?

  func startUpdating() async {
    await refresh()

    while !Task.isCancelled {
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      guard !Task.isCancelled else { return }
      await refresh()
    }
  }

  private func refresh() async {
    metrics = await HostMetricsScanner.snapshot()
  }
}
