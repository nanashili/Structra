//
//  EditorWindowController.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/26/25.
//


import SwiftUI
import Combine

/// The window controller for Aurora Editor.
@MainActor
final class EditorWindowController: NSWindowController {

    /// The set of cancelables.
    var cancelables: Set<AnyCancellable> = .init()

    /// The split view controller.
    var splitViewController: EditorSplitViewController! {
        get { contentViewController as? EditorSplitViewController }
        set { contentViewController = newValue }
    }

    /// Creates a new instance of the window controller.
    /// 
    /// - Parameter window: The window.
    /// - Parameter workspace: The workspace document.
    init(window: NSWindow) {
        super.init(window: window)

        setupSplitView()

        updateLayoutOfWindowAndSplitView()
    }

    /// Creates a new instance of the window controller.
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Setup split view.
    /// 
    /// - Parameter workspace: The workspace document.
    private func setupSplitView() {
        let splitVC = EditorSplitViewController()
        splitVC.splitView.autosaveName = "MainSplitView"
        splitVC.splitView.dividerStyle = .thin
        splitVC.splitView.isVertical = true

        // Navigator Sidebar
        let navigatorView = NavigatorSidebar()
        let navigationViewController = NSHostingController(
            rootView: navigatorView
        )
        let navigator = NSSplitViewItem(
            sidebarWithViewController: navigationViewController
        )
        navigator.titlebarSeparatorStyle = .none
        navigator.minimumThickness = 200
        navigator.maximumThickness = 400
        navigator.collapseBehavior = .useConstraints
        navigator.canCollapse = true
        navigator.isSpringLoaded = true
        navigator.holdingPriority = NSLayoutConstraint.Priority(
            NSLayoutConstraint.Priority.defaultLow.rawValue + 1
        )
        splitVC.addSplitViewItem(navigator)

        // Workspace (Main Content)
        let workspaceView = WorkspaceView()
        let workspaceViewController = NSHostingController(
            rootView: workspaceView
        )
        let mainContent = NSSplitViewItem(
            viewController: workspaceViewController
        )
        mainContent.titlebarSeparatorStyle = .line
        mainContent.holdingPriority = .defaultLow
        splitVC.addSplitViewItem(mainContent)

        // Inspector Sidebar
        let inspectorView = InspectorSidebar()
        let inspectorViewController = NSHostingController(
            rootView: inspectorView
        )
        let inspector = NSSplitViewItem(
            inspectorWithViewController: inspectorViewController
        )
        inspector.titlebarSeparatorStyle = .none
        inspector.minimumThickness = 200
        inspector.maximumThickness = 400
        inspector.canCollapse = true
        inspector.collapseBehavior = .useConstraints
        inspector.isSpringLoaded = true
        inspector.isCollapsed = false
        inspector.holdingPriority = NSLayoutConstraint.Priority(
            NSLayoutConstraint.Priority.defaultLow.rawValue + 1
        )
        splitVC.addSplitViewItem(inspector)

        // Set up the initial sidebar states
        splitVC.toggleSidebar(navigator)
        splitVC.toggleSidebar(inspector)

        self.splitViewController = splitVC
    }

    /// Close the window.
    override func close() {
        super.close()
        cancelables.forEach({ $0.cancel() })
    }

    /// Update the layout of the window and split view.
    @objc
    private func updateLayoutOfWindowAndSplitView() {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            let navigationSidebarWidth = 350.0
            let workspaceSidebarWidth = 350.0
            let firstDividerPos = navigationSidebarWidth
            let secondDividerPos = navigationSidebarWidth + workspaceSidebarWidth

            self.splitViewController.splitView.setPosition(firstDividerPos, ofDividerAt: 0)
            self.splitViewController.splitView.setPosition(secondDividerPos, ofDividerAt: 1)
            self.splitViewController.splitView.layoutSubtreeIfNeeded()
        }
    }
}
