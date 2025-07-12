//
//  ProjectNavigatorViewController.swift
//  structra
//
//  Created by Nanashi Li on 6/22/25.
//

import AppKit
import Combine
import OSLog

/// Manages the file explorer sidebar for browsing project structure.
final class ProjectNavigatorViewController: NSViewController {

    // MARK: – Dependencies

    weak var workspaceManager: WorkspaceManager?

    /// Access to current tree model
    var treeModel: ProjectTreeModel? {
        workspaceManager?.currentSession?.treeModel
    }

    // MARK: – UI Components

    private var scrollView: NSScrollView!
    private var outlineView: NSOutlineView!
    private var contextMenu: ProjectNavigatorMenu!

    // MARK: – State

    public let cellIdentifier = NSUserInterfaceItemIdentifier("FileSystemCell")
    public let dragType: NSPasteboard.PasteboardType = .fileURL
    private var cancellables = Set<AnyCancellable>()
    public var isUpdatingSelection = false
    public let logger = Logger(
        subsystem: "com.structra.app",
        category: "ProjectNavigator"
    )
    private let signatureChecker = SignatureConsistencyChecker()

    /// Allows dynamic adjustment of row height
    var rowHeight: CGFloat = 22 {
        didSet {
            outlineView.rowHeight = rowHeight
        }
    }

    // MARK: – View Lifecycle

    override func loadView() {
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.scrollerStyle = .overlay
        scrollView.autohidesScrollers = true
        scrollView.contentView.contentInsets = NSEdgeInsets(
            top: 10,
            left: 0,
            bottom: 0,
            right: 0
        )

        outlineView = NSOutlineView(frame: .zero)
        outlineView.headerView = nil
        outlineView.rowHeight = rowHeight
        outlineView.doubleAction = #selector(onItemDoubleClicked(_:))

        scrollView.documentView = outlineView
        self.view = scrollView

        let col = NSTableColumn(identifier: .init("Cell"))
        col.title = ""
        outlineView.addTableColumn(col)

        outlineView.dataSource = self
        outlineView.delegate = self

        outlineView.autosaveExpandedItems = true
        outlineView.autosaveName =
            workspaceManager?.currentSession?.projectURL.path
        outlineView.registerForDraggedTypes([.fileURL])

        // Attach context menu
        if let workspaceManager = self.workspaceManager {
            contextMenu = ProjectNavigatorMenu(
                sender: outlineView,
                workspaceManager: workspaceManager
            )
            outlineView.menu = contextMenu
        }

        subscribeToModel()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    // MARK: – Model Binding

    /// Binds tree model and selection changes reactively.
    private func subscribeToModel() {
        guard let session = workspaceManager?.currentSession else { return }

        session.treeModel.changePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                self?.handleTreeChange(change)
            }
            .store(in: &cancellables)

        session.$selectedNodeID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] nodeId in
                self?.updateSelection(to: nodeId)
            }
            .store(in: &cancellables)
    }

    // MARK: – Change Handling

    /// Handles incremental updates to the tree structure.
    private func handleTreeChange(_ change: NodeChangeEvent) {
        guard let treeModel = self.treeModel else { return }

        outlineView.beginUpdates()
        switch change {
        case .added(let node, let parentID):
            let parent = parentID.flatMap { treeModel.node(withID: $0) }
            let children = parent?.children ?? treeModel.rootNodes
            if let index = children.firstIndex(where: { $0.id == node.id }) {
                outlineView.insertItems(
                    at: [index],
                    inParent: parent,
                    withAnimation: .effectFade
                )
            }

        case .removed(_, let parentID, let fromIndex):
            let parent = parentID.flatMap { treeModel.node(withID: $0) }
            outlineView.removeItems(
                at: [fromIndex],
                inParent: parent,
                withAnimation: .effectFade
            )

        case .moved(
            _,
            let fromParentID,
            let toParentID,
            let fromIndex,
            let toIndex
        ):
            let fromParent = fromParentID.flatMap { treeModel.node(withID: $0) }
            let toParent = toParentID.flatMap { treeModel.node(withID: $0) }
            outlineView.moveItem(
                at: fromIndex,
                inParent: fromParent,
                to: toIndex,
                inParent: toParent
            )

        case .renamed(let nodeID, _, _), .metadataUpdated(let nodeID, _):
            if let node = treeModel.node(withID: nodeID) {
                if !node.type.isFolder {
                    runSignatureCheck(for: node)
                }
                outlineView.reloadItem(node, reloadChildren: false)
            }

        case .reloaded(let parentID):
            let parent = parentID.flatMap { treeModel.node(withID: $0) }
            outlineView.reloadItem(parent, reloadChildren: true)
        }
        outlineView.endUpdates()
    }

    // MARK: – Signature Consistency

    /// Performs a signature check to mark stale documentation.
    private func runSignatureCheck(for node: ProjectNode) {
        guard let language = Language(url: node.url) else {
            if node.isDocumentationStale { node.isDocumentationStale = false }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileContent = try String(
                    contentsOf: node.url,
                    encoding: .utf8
                )
                let inconsistencies = self.signatureChecker.checkConsistency(
                    code: fileContent,
                    documentation: fileContent,
                    language: language
                )
                let isStale = !inconsistencies.isEmpty

                DispatchQueue.main.async {
                    if node.isDocumentationStale != isStale {
                        node.isDocumentationStale = isStale
                        self.outlineView.reloadItem(node, reloadChildren: false)
                    }
                }
            } catch {
                self.logger.error(
                    "Failed to read file for consistency check: \(node.url.path). Error: \(error.localizedDescription)"
                )
            }
        }
    }

    // MARK: – Data Helpers

    /// Returns root-level nodes from the tree.
    var rootNodes: [ProjectNode] {
        treeModel?.rootNodes ?? []
    }

    // MARK: – Double‐Click Handler

    /// Expands/collapses folders or opens file on double click.
    @objc private func onItemDoubleClicked(_ sender: Any) {
        let row = outlineView.clickedRow
        guard row >= 0, let node = outlineView.item(atRow: row) as? ProjectNode
        else { return }

        if node.type.isFolder {
            if outlineView.isItemExpanded(node) {
                outlineView.collapseItem(node)
            } else {
                outlineView.expandItem(node)
            }
        } else {
            workspaceManager?.currentSession?.openFile(at: node.url)
        }
    }

    // MARK: – Selection Sync

    /// Updates the UI selection to match model’s selected node.
    public func updateSelection(to nodeId: UUID?) {
        guard !isUpdatingSelection else { return }
        guard let id = nodeId, let node = treeModel?.node(withID: id) else {
            outlineView.deselectAll(nil)
            return
        }

        let row = outlineView.row(forItem: node)
        if row >= 0 {
            isUpdatingSelection = true
            outlineView.selectRowIndexes([row], byExtendingSelection: false)
            outlineView.scrollRowToVisible(row)
            isUpdatingSelection = false
        } else {
            // Expand collapsed parents so node becomes visible.
            var parent = node.parent
            while let p = parent {
                outlineView.expandItem(p)
                parent = p.parent
            }
            // Retry selection after expansion.
            let finalRow = outlineView.row(forItem: node)
            if finalRow >= 0 {
                isUpdatingSelection = true
                outlineView.selectRowIndexes(
                    [finalRow],
                    byExtendingSelection: false
                )
                outlineView.scrollRowToVisible(finalRow)
                isUpdatingSelection = false
            }
        }
    }
}
