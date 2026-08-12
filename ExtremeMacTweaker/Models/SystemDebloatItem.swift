import Foundation

struct SystemDebloatItem: Identifiable, Sendable {
  let component: SystemDebloatComponent
  let sizeInBytes: Int64

  var id: String { component.id }
}
