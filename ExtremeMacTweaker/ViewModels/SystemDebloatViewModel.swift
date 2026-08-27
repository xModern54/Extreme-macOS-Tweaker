import Combine
import Foundation

@MainActor
final class SystemDebloatViewModel: ObservableObject {
  @Published private(set) var items: [SystemDebloatItem] = []
  @Published private(set) var isLoading = true

  var totalSizeInBytes: Int64 {
    items.reduce(0) { $0 + $1.sizeInBytes }
  }

  func load() async {
    isLoading = true
    items = await Task.detached(priority: .utility) {
      SystemDebloatScanner.requestAppDataAccess()
      return SystemDebloatScanner.scan()
    }.value
    isLoading = false
  }
}
