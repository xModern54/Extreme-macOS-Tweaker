import Foundation

struct SystemDebloatItem: Identifiable, Sendable {
  let component: SystemDebloatComponent
  let sizeInBytes: Int64
  let sizeIsIncomplete: Bool
  let requiresFullDiskAccess: Bool

  var id: String { component.id }
}
