//
//  ProjectNavigatorViewController.swift
//  structra
//
//  Created by Nanashi Li on 6/22/25.
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
    private var contextMenu: ProjectNavigatorMenu!

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

        outlineView.headerView = nil
        outlineView.rowHeight = rowHeight

        outlineView.autosaveExpandedItems = true
        outlineView.autosaveName =
            workspaceManager?
            .currentSession?.projectURL.path

        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.registerForDraggedTypes([.fileURL])
        outlineView.doubleAction = #selector(onItemDoubleClicked(_:))

        if let workspaceManager = self.workspaceManager {
            contextMenu = ProjectNavigatorMenu(
                sender: outlineView,
                workspaceManager: workspaceManager
            )
            outlineView.menu = contextMenu
        }

        let col = NSTableColumn(identifier: .init("Cell"))
        col.title = ""
        outlineView.addTableColumn(col)

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

        session.treeModel.$rootNodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.outlineView.reloadData()
                self?.restoreExpansionState()
            }
            .store(in: &cancelables)

        session.treeModel.changePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                self?.handleTreeChange(change)
            }
            .store(in: &cancelables)

        session.$selectedNodeID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] nodeId in
                self?.updateSelection(to: nodeId)
            }
            .store(in: &cancelables)
    }

    // MARK: - Change Handling

    private func handleTreeChange(_ change: NodeChangeEvent) {
        outlineView.beginUpdates()
        switch change {
        case .added(let node, let parentID):
            if let parent = parentID.flatMap({ treeModel?.node(withID: $0) }),
                let index = parent.children.firstIndex(where: {
                    $0.id == node.id
                })
            {
                outlineView.insertItems(
                    at: [index],
                    inParent: parent,
                    withAnimation: .effectFade
                )
            } else if let index = rootNodes.firstIndex(where: {
                $0.id == node.id
            }) {
                outlineView.insertItems(
                    at: [index],
                    inParent: nil,
                    withAnimation: .effectFade
                )
            }

        case .removed(_, let parentID, let fromIndex):
            let parentItem = parentID.flatMap { treeModel?.node(withID: $0) }

            outlineView.removeItems(
                at: [fromIndex],
                inParent: parentItem,
                withAnimation: .effectFade
            )

        case .moved(let nodeID, let fromParentID, let toParentID):
            if treeModel?.node(withID: nodeID) != nil {
                let fromParent = fromParentID.flatMap {
                    treeModel?.node(withID: $0)
                }
                let toParent = toParentID.flatMap {
                    treeModel?.node(withID: $0)
                }
                outlineView.reloadItem(fromParent, reloadChildren: true)
                outlineView.reloadItem(toParent, reloadChildren: true)
            }

        case .renamed(let nodeID, _, _), .metadataUpdated(let nodeID, _):
            if let node = treeModel?.node(withID: nodeID) {
                outlineView.reloadItem(node, reloadChildren: false)
            }

        case .reloaded(let parentID):
            let parent = parentID.flatMap { treeModel?.node(withID: $0) }
            outlineView.reloadItem(parent, reloadChildren: true)
        }
        outlineView.endUpdates()
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
            if outlineView.isItemExpanded(node) {
                outlineView.collapseItem(node)
                node.isExpanded = false
            } else {
                outlineView.expandItem(node)
                node.isExpanded = true
            }
        } else {
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
        node.isExpanded = outlineView.isItemExpanded(node)
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
            outlineView.expandItem(node, expandChildren: false)
        } else {
            outlineView.collapseItem(node, collapseChildren: false)
        }
        node.children.forEach { restoreExpansion(for: $0) }
    }

    // MARK: – Selection Sync

    public func updateSelection(to nodeId: UUID?) {
        guard !isUpdatingSelection else { return }

        guard let id = nodeId, let node = treeModel?.node(withID: id) else {
            outlineView.deselectAll(nil)
            return
        }

        let row = outlineView.row(forItem: node)

        // If row is -1, the item might be inside a collapsed folder.
        // We need to expand its parents first.
        if row < 0 {
            var currentParent = node.parent
            while let parent = currentParent {
                outlineView.expandItem(parent)
                currentParent = parent.parent
            }
        }

        let finalRow = outlineView.row(forItem: node)
        guard finalRow >= 0 else { return }

        isUpdatingSelection = true
        outlineView.selectRowIndexes([finalRow], byExtendingSelection: false)
        outlineView.scrollRowToVisible(finalRow)
        isUpdatingSelection = false
    }
}
