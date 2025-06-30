//
//  ProjectNavigatorViewController.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/22/25.
//

import AppKit
import Combine
import OSLog

/// Renders the project navigator sidebar as an NSOutlineView of `ProjectNode`s.
/// Subscribes to your `WorkspaceSession` → `ProjectTreeModel` for live updates,
/// persists expansion state in each node, and wires selection back into
/// your session’s `selectedNodeID`.
final class ProjectNavigatorViewController: NSViewController {

    // MARK: – Dependencies

    /// Inject the shared workspace manager from outside
    weak var workspaceManager: WorkspaceManager?

    /// Convenience accessor for the current session’s tree
    public var treeModel: ProjectTreeModel? {
        workspaceManager?.currentSession?.treeModel
    }

    // MARK: – UI

    private var scrollView: NSScrollView!
    private var outlineView: NSOutlineView!

    // MARK: – State

    public let dragType: NSPasteboard.PasteboardType = .fileURL
    private var cancelables = Set<AnyCancellable>()
    public var isUpdatingSelection = false
    public let logger = Logger(
        subsystem: "com.structra.app",
        category: "ProjectNavigator"
    )

    /// Row height for each item.
    var rowHeight: CGFloat = 22 {
        didSet {
            outlineView.rowHeight = rowHeight
            outlineView.reloadData()
        }
    }

    // MARK: – View Lifecycle

    override func loadView() {
        // 1) Build scrollView + outlineView
        scrollView = NSScrollView()
        outlineView = NSOutlineView(frame: .zero)
        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.scrollerStyle = .overlay
        scrollView.contentView.automaticallyAdjustsContentInsets = false
        scrollView.contentView.contentInsets = NSEdgeInsets(
            top: 10,
            left: 0,
            bottom: 0,
            right: 0
        )
        scrollView.autohidesScrollers = true
        self.view = scrollView

        // 2) Configure outlineView
        outlineView.headerView = nil
        outlineView.rowHeight = rowHeight

        // autosave expansions under a key unique per-project
        outlineView.autosaveExpandedItems = true
        outlineView.autosaveName =
            workspaceManager?
            .currentSession?.projectURL.path

        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.registerForDraggedTypes([.fileURL])
        outlineView.doubleAction = #selector(onItemDoubleClicked(_:))

        // Single, invisible column
        let col = NSTableColumn(identifier: .init("Cell"))
        col.title = ""
        outlineView.addTableColumn(col)

        // 3) Wire model & selection subscriptions
        subscribeToModel()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        cancelables.forEach { $0.cancel() }
        cancelables.removeAll()
    }

    // MARK: – Model Binding

    private func subscribeToModel() {
        guard let session = workspaceManager?.currentSession else { return }

        // 1) Reload & restore expansion whenever rootNodes array changes
        session.treeModel.$rootNodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.outlineView.reloadData()
                self?.restoreExpansionState()
            }
            .store(in: &cancelables)

        // 2) Incremental updates on file events
        session.treeModel.changePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.outlineView.reloadData()
            }
            .store(in: &cancelables)

        // 3) Reflect session.selectedNodeID in the outline selection
        session.$selectedNodeID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] nodeId in
                self?.updateSelection(to: nodeId)
            }
            .store(in: &cancelables)
    }

    // MARK: – Data Helpers

    /// Top‐level nodes of the outline view.
    var rootNodes: [ProjectNode] {
        treeModel?.rootNodes ?? []
    }

    // MARK: – Double‐Click Handler

    /// Toggle folder expansion or ask session to open files.
    @objc private func onItemDoubleClicked(_ sender: Any) {
        let row = outlineView.clickedRow
        guard row >= 0,
            let node = outlineView.item(atRow: row) as? ProjectNode
        else { return }

        if node.type.isFolder {
            // Expand/collapse & persist
            if outlineView.isItemExpanded(node) {
                outlineView.collapseItem(node)
                node.isExpanded = false
            } else {
                outlineView.expandItem(node)
                node.isExpanded = true
            }
        } else {
            // Leaf: open in editor
            workspaceManager?.currentSession?.openFile(at: node.url)
        }
    }

    // MARK: – Expansion State

    /// Walks the entire tree and writes each node’s current
    /// NSOutlineView expansion into `node.isExpanded`.
    public func saveExpansionState() {
        for node in rootNodes {
            saveExpansion(for: node)
        }
    }

    private func saveExpansion(for node: ProjectNode) {
        guard node.type.isFolder else { return }
        // Record whether the outline is currently expanded
        node.isExpanded = outlineView.isItemExpanded(node)
        // Recurse into children
        for child in node.children {
            saveExpansion(for: child)
        }
    }

    /// Re-applies each node’s `isExpanded` flag to the outline.
    private func restoreExpansionState() {
        for node in rootNodes {
            restoreExpansion(for: node)
        }
    }

    private func restoreExpansion(for node: ProjectNode) {
        guard node.type.isFolder else { return }
        if node.isExpanded {
            outlineView.expandItem(node)
        } else {
            outlineView.collapseItem(node)
        }
        node.children.forEach { restoreExpansion(for: $0) }
    }

    // MARK: – Selection Sync

    public func updateSelection(to nodeId: UUID?) {
        guard !isUpdatingSelection else { return }
        guard let id = nodeId else {
            outlineView.deselectAll(nil)
            return
        }
        select(nodeId: id, in: rootNodes)
    }

    private func select(nodeId: UUID, in nodes: [ProjectNode]) {
        for node in nodes {
            if node.id == nodeId {
                let row = outlineView.row(forItem: node)
                guard row >= 0 else { continue }
                isUpdatingSelection = true
                outlineView.selectRowIndexes([row], byExtendingSelection: false)
                outlineView.scrollRowToVisible(row)
                isUpdatingSelection = false
                return
            }
            select(nodeId: nodeId, in: node.children)
        }
    }
}
