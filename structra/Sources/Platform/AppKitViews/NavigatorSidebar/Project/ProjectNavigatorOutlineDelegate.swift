//
//  ProjectNavigatorOutlineDelegate.swift
//  structra
//
//  Created by Nanashi Li on 6/22/25.
//

import AppKit
import OSLog

extension ProjectNavigatorViewController: NSOutlineViewDelegate {

    /// Always allow cell expansion tooltips.
    func outlineView(
        _ outlineView: NSOutlineView,
        shouldShowCellExpansionFor tableColumn: NSTableColumn?,
        item: Any
    ) -> Bool {
        return true
    }

    /// Always show disclosure triangle for items (folders/files).
    func outlineView(
        _ outlineView: NSOutlineView,
        shouldShowOutlineCellForItem item: Any
    ) -> Bool {
        return true
    }

    /// Provides a custom view for each row representing a `ProjectNode`.
    func outlineView(
        _ outlineView: NSOutlineView,
        viewFor tableColumn: NSTableColumn?,
        item: Any
    ) -> NSView? {
        guard let node = item as? ProjectNode else { return nil }

        // Try to reuse a registered cell
        guard
            let cell = outlineView.makeView(
                withIdentifier: cellIdentifier,
                owner: self
            ) as? FileSystemTableViewCell
        else {
            // Fallback if registration failed (should not happen)
            let newCell = FileSystemTableViewCell(frame: .zero)
            newCell.identifier = cellIdentifier
            newCell.configure(with: node, isEditable: true)
            return newCell
        }

        cell.configure(with: node, isEditable: true)
        return cell
    }

    /// Handles selection changes and file opening.
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard !isUpdatingSelection,
            let session = workspaceManager?.currentSession,
            let outline = notification.object as? NSOutlineView
        else { return }

        let row = outline.selectedRow

        guard row >= 0,
            let node = outline.item(atRow: row) as? ProjectNode
        else {
            session.selectedNodeID = nil
            return
        }

        session.selectedNodeID = node.id

        // Open file if it's not a folder
        if !node.type.isFolder {
            session.openFile(at: node.url)
            logger.info("Opened file: \(node.url.path)")
        }
    }

    /// Defines fixed row height for all outline items.
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any)
        -> CGFloat
    {
        return rowHeight
    }

    // MARK: - Persistence

    /// Resolves a saved UUID to a tree node object.
    func outlineView(
        _ outlineView: NSOutlineView,
        itemForPersistentObject object: Any
    ) -> Any? {
        let uuid: UUID?
        if let id = object as? UUID {
            uuid = id
        } else if let idString = object as? String {
            uuid = UUID(uuidString: idString)
        } else {
            uuid = nil
        }
        return uuid.flatMap { treeModel?.node(withID: $0) }
    }

    /// Returns UUID string for a node to support state restoration.
    func outlineView(
        _ outlineView: NSOutlineView,
        persistentObjectForItem item: Any?
    ) -> Any? {
        return (item as? ProjectNode)?.id.uuidString
    }
}
