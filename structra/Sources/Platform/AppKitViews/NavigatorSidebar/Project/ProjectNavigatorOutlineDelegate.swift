//
//  ProjectNavigatorOutlineDelegate.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/22/25.
//  Updated 2025/06/26 to use ProjectNode & WorkspaceSession.
//

import AppKit
import OSLog

extension ProjectNavigatorViewController: NSOutlineViewDelegate {

    /// Always allow the cell to show a tooltip on truncated text.
    func outlineView(
        _ outlineView: NSOutlineView,
        shouldShowCellExpansionFor tableColumn: NSTableColumn?,
        item: Any
    ) -> Bool {
        return true
    }

    /// Always show the standard outline‐disclosure triangle.
    func outlineView(
        _ outlineView: NSOutlineView,
        shouldShowOutlineCellForItem item: Any
    ) -> Bool {
        return true
    }

    /// Returns your custom cell view, now driven by `ProjectNode`.
    func outlineView(
        _ outlineView: NSOutlineView,
        viewFor tableColumn: NSTableColumn?,
        item: Any
    ) -> NSView? {
        guard
            let tableColumn = tableColumn,
            let node = item as? ProjectNode
        else {
            return nil
        }

        let frameRect = NSRect(
            x: 0,
            y: 0,
            width: tableColumn.width,
            height: rowHeight
        )

        return FileSystemTableViewCell(
            frame: frameRect,
            node: node,
            isEditable: true
        )
    }

    /// Syncs selection back into your session, and opens files on click. 
    func outlineViewSelectionDidChange(_ notification: Notification) {
        // 1) Don’t react to programmatic selections
        guard !isUpdatingSelection,
              let session = workspaceManager?.currentSession,
              let outline = notification.object as? NSOutlineView
        else {
          return
        }

        let row = outline.selectedRow
        // 2) No selection?
        guard row >= 0,
              let node = outline.item(atRow: row) as? ProjectNode
        else {
          session.selectedNodeID = nil
          return
        }

        // 3) Publish the new selection ID
        session.selectedNodeID = node.id

        // 4) If it’s a file (not a folder), open it
        if !node.type.isFolder {
          session.openFile(at: node.url)
          logger.info("Opened file: \(node.url.path)")
        }
      }

    /// Row height.
    func outlineView(
        _ outlineView: NSOutlineView,
        heightOfRowByItem item: Any
    ) -> CGFloat {
        return rowHeight
    }

    /// Save expansion whenever an item expands.
    func outlineViewItemDidExpand(_ notification: Notification) {
        saveExpansionState()
    }

    /// Save expansion whenever an item collapses.
    func outlineViewItemDidCollapse(_ notification: Notification) {
        saveExpansionState()
    }

    // MARK: - Persistence

    /// Given a persisted UUID, return the matching `ProjectNode`.
    func outlineView(
        _ outlineView: NSOutlineView,
        itemForPersistentObject object: Any
    ) -> Any? {
        // Accept both UUID and String (for flexibility)
        let uuid: UUID?
        if let id = object as? UUID {
            uuid = id
        } else if let idString = object as? String {
            uuid = UUID(uuidString: idString)
        } else {
            uuid = nil
        }
        guard let id = uuid,
              let node = treeModel?.node(withID: id)
        else {
            return nil
        }
        return node
    }

    /// Store each node’s UUID string for autosave / collapse/expand state.
    func outlineView(
        _ outlineView: NSOutlineView,
        persistentObjectForItem item: Any?
    ) -> Any? {
        guard let node = item as? ProjectNode else {
            return nil
        }
        // Return as String for UserDefaults compatibility
        return node.id.uuidString
    }
}
