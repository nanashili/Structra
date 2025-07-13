//
//  EditorWindowController.swift
//  structra
//
//  Created by Nanashi Li on 6/26/25.
//

import Combine
import SwiftUI

final class EditorWindowController: NSWindowController {

    private var cancellables: Set<AnyCancellable> = .init()

    // MARK: - Initialization

    init(window: NSWindow) {
        super.init(window: window)
        window.delegate = self

        self.contentViewController = Self.createSplitViewController()
        setupToolbar()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func close() {
        super.close()
        cancellables.forEach { $0.cancel() }
    }

    // MARK: - Toolbar Setup

    private func setupToolbar() {
        guard let window = self.window else { return }

        let toolbar = NSToolbar(identifier: "StructraEditorToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .labelOnly

        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = true

        window.toolbar = toolbar
        window.toolbarStyle = .unifiedCompact
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = false
    }

    // MARK: - View Factory Methods

    private static func createSplitViewController() -> NSSplitViewController {
        let splitVC = NSSplitViewController()
        splitVC.splitView.autosaveName = "MainSplitView"
        splitVC.splitView.dividerStyle = .thin
        splitVC.splitView.isVertical = true
        splitVC.addSplitViewItem(makeNavigatorItem())
        splitVC.addSplitViewItem(makeMainContentItem())
        splitVC.addSplitViewItem(makeInspectorItem())
        return splitVC
    }

    private static func makeNavigatorItem() -> NSSplitViewItem {
        let navigatorView = NavigatorSidebar()
        let viewController = NSHostingController(
            rootView: navigatorView
        )
        viewController.identifier = .navigatorSidebar
        let splitViewItem = NSSplitViewItem(
            sidebarWithViewController: viewController
        )
        splitViewItem.minimumThickness = 200
        splitViewItem.maximumThickness = 400
        splitViewItem.canCollapse = true
        splitViewItem.isCollapsed = false
        splitViewItem.holdingPriority = .defaultLow + 1
        return splitViewItem
    }

    private static func makeMainContentItem() -> NSSplitViewItem {
        let workspace = WorkspaceManager.shared
        let rootView: AnyView
        if let session = workspace.currentSession {
            rootView = AnyView(
                WorkspaceView(session: session).environmentObject(workspace)
            )
        } else {
            rootView = AnyView(
                Text("No Workspace Open").font(.title).foregroundColor(
                    .secondary
                )
            )
        }
        let viewController = NSHostingController(rootView: rootView)
        let splitViewItem = NSSplitViewItem(viewController: viewController)
        splitViewItem.titlebarSeparatorStyle = .line
        splitViewItem.holdingPriority = .defaultLow
        return splitViewItem
    }

    private static func makeInspectorItem() -> NSSplitViewItem {
        let inspectorView = InspectorSidebar()
        let viewController = NSHostingController(
            rootView: inspectorView
        )
        viewController.identifier = .inspectorSidebar
        let splitViewItem = NSSplitViewItem(
            inspectorWithViewController: viewController
        )
        splitViewItem.minimumThickness = 200
        splitViewItem.maximumThickness = 400
        splitViewItem.canCollapse = true
        splitViewItem.isCollapsed = true
        splitViewItem.holdingPriority = .defaultLow + 1
        return splitViewItem
    }
}

// MARK: - NSWindowDelegate
extension EditorWindowController: NSWindowDelegate {

    func windowWillReturnToolbar(_ window: NSWindow) -> NSToolbar? {
        return window.toolbar
    }

    func windowDidBecomeKey(_ notification: Notification) {
        // Ensure toolbar items are properly validated when window becomes key
        window?.toolbar?.validateVisibleItems()
    }

    func windowDidResignKey(_ notification: Notification) {}
}

extension NSLayoutConstraint.Priority {
    fileprivate static func + (left: NSLayoutConstraint.Priority, right: Float)
        -> NSLayoutConstraint.Priority
    {
        return NSLayoutConstraint.Priority(left.rawValue + right)
    }
}
