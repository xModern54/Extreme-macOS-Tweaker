import Foundation

struct HostMetrics: Sendable {
  let processorName: String
  let coreCount: Int
  let memoryBytes: UInt64
  let usedMemoryBytes: UInt64
  let processCount: Int
  let threadCount: Int

  var formattedCoreCount: String {
    coreCount.formatted()
  }

  var formattedMemory: String {
    Self.gigabytes(memoryBytes)
  }

  var formattedUsedMemory: String {
    Self.gigabytes(usedMemoryBytes)
  }

  var formattedProcessCount: String {
    processCount.formatted()
  }

  var formattedThreadCount: String {
    threadCount.formatted()
  }

  private static func gigabytes(_ bytes: UInt64) -> String {
    let formatter = NumberFormatter()
    formatter.locale = .current
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    let value = Double(bytes) / 1_073_741_824
    let number = formatter.string(from: NSNumber(value: value)) ?? "0.00"
    return "\(number) GB"
  }
}
