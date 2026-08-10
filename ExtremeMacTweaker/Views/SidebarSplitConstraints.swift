import AppKit
import SwiftUI

struct SidebarSplitConstraints: NSViewRepresentable {
  let minimumWidth: CGFloat
  let maximumWidth: CGFloat

  func makeNSView(context: Context) -> SidebarConstraintMarkerView {
    SidebarConstraintMarkerView(
      minimumWidth: minimumWidth,
      maximumWidth: maximumWidth
    )
  }

  func updateNSView(_ nsView: SidebarConstraintMarkerView, context: Context) {
    nsView.minimumWidth = minimumWidth
    nsView.maximumWidth = maximumWidth
    nsView.scheduleConfiguration()
  }
}

final class SidebarConstraintMarkerView: NSView {
  var minimumWidth: CGFloat
  var maximumWidth: CGFloat

  private weak var splitView: NSSplitView?
  private weak var sidebarContainer: NSView?
  private var splitItemIndex: Int?
  private var resizeObserver: NSObjectProtocol?
  private var isEnforcingWidth = false

  init(minimumWidth: CGFloat, maximumWidth: CGFloat) {
    self.minimumWidth = minimumWidth
    self.maximumWidth = maximumWidth
    super.init(frame: .zero)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    if let resizeObserver {
      NotificationCenter.default.removeObserver(resizeObserver)
    }
  }

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    scheduleConfiguration()
  }

  func scheduleConfiguration() {
    DispatchQueue.main.async { [weak self] in
      self?.configureSplitView()
    }
  }

  private func configureSplitView() {
    var descendant: NSView = self
    var ancestor = superview

    while let current = ancestor {
      if let enclosingSplitView = current as? NSSplitView,
         let index = enclosingSplitView.arrangedSubviews.firstIndex(where: { $0 === descendant }) {
        installConstraints(
          on: enclosingSplitView,
          sidebarContainer: descendant,
          itemIndex: index
        )
        return
      }

      descendant = current
      ancestor = current.superview
    }
  }

  private func installConstraints(
    on splitView: NSSplitView,
    sidebarContainer: NSView,
    itemIndex: Int
  ) {
    self.splitView = splitView
    self.sidebarContainer = sidebarContainer
    splitItemIndex = itemIndex

    if let splitViewController = splitView.delegate as? NSSplitViewController,
       splitViewController.splitViewItems.indices.contains(itemIndex) {
      let sidebarItem = splitViewController.splitViewItems[itemIndex]
      sidebarItem.canCollapse = false
      sidebarItem.minimumThickness = minimumWidth
      sidebarItem.maximumThickness = maximumWidth
      sidebarItem.isCollapsed = false
      sidebarItem.holdingPriority = .defaultHigh
    }

    if resizeObserver == nil {
      resizeObserver = NotificationCenter.default.addObserver(
        forName: NSSplitView.didResizeSubviewsNotification,
        object: splitView,
        queue: .main
      ) { [weak self] _ in
        Task { @MainActor in
          self?.enforceMinimumWidth()
        }
      }
    }

    enforceMinimumWidth()
  }

  private func enforceMinimumWidth() {
    guard
      !isEnforcingWidth,
      let splitView,
      let sidebarContainer,
      let splitItemIndex,
      sidebarContainer.frame.width < minimumWidth
    else {
      return
    }

    isEnforcingWidth = true
    defer { isEnforcingWidth = false }

    if splitItemIndex == 0, splitView.arrangedSubviews.count > 1 {
      splitView.setPosition(minimumWidth, ofDividerAt: 0)
    } else if splitItemIndex > 0 {
      let dividerIndex = splitItemIndex - 1
      let position = splitView.bounds.width - minimumWidth
      splitView.setPosition(position, ofDividerAt: dividerIndex)
    }
  }
}
