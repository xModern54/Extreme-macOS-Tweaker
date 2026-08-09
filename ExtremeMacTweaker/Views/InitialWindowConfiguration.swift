import AppKit
import SwiftUI

struct InitialWindowConfiguration: NSViewRepresentable {
  let width: CGFloat
  let height: CGFloat

  func makeNSView(context: Context) -> NSView {
    InitialWindowConfigurationView(
      targetSize: NSSize(width: width, height: height)
    )
  }

  func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class InitialWindowConfigurationView: NSView {
  private let targetSize: NSSize
  private var hasConfiguredWindow = false

  init(targetSize: NSSize) {
    self.targetSize = targetSize
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()

    guard !hasConfiguredWindow, let window else { return }
    hasConfiguredWindow = true

    window.isOpaque = false
    window.backgroundColor = .clear
    window.titlebarAppearsTransparent = true

    var frame = window.frame
    frame.size = targetSize

    if let visibleFrame = window.screen?.visibleFrame {
      frame.origin.x = visibleFrame.midX - targetSize.width / 2
      frame.origin.y = visibleFrame.midY - targetSize.height / 2
    }

    window.setFrame(frame, display: true)
  }
}
