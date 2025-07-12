//
//  ProjectNavigatorOutlineDataSource.swift
//  structra
//
//  Created by Nanashi Li on 6/22/25.
//

import AppKit
import OSLog

extension ProjectNavigatorViewController: NSOutlineViewDataSource {

    /// Returns the number of children for a given node (or root if nil).
    func outlineView(
        _ outlineView: NSOutlineView,
        numberOfChildrenOfItem item: Any?
    ) -> Int {
        if let node = item as? ProjectNode {
            return node.children.count
        }
        return rootNodes.count
    }

    /// Returns the child node at a specific index for the given item.
    func outlineView(
        _ outlineView: NSOutlineView,
        child index: Int,
        ofItem item: Any?
    ) -> Any {
        if let node = item as? ProjectNode {
            return node.children[index]
        }
        return rootNodes[index]
    }

    /// Determines whether a node is expandable (i.e., is a folder).
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any)
        -> Bool
    {
        guard let node = item as? ProjectNode else { return false }
        return node.type.isFolder
    }

    // MARK: – Drag & Drop

    /// Provides drag data representing a node's file path.
    func outlineView(
        _ outlineView: NSOutlineView,
        pasteboardWriterForItem item: Any
    ) -> NSPasteboardWriting? {
        guard let node = item as? ProjectNode else {
            logger.fault("Drag: item is not ProjectNode")
            return nil
        }
        let pboardItem = NSPasteboardItem()
        pboardItem.setString(node.url.path, forType: dragType)
        return pboardItem
    }

    /// Validates whether a drop operation is allowed for the given target.
    func outlineView(
        _ outlineView: NSOutlineView,
        validateDrop info: NSDraggingInfo,
        proposedItem item: Any?,
        proposedChildIndex index: Int
    ) -> NSDragOperation {
        guard let targetNode = item as? ProjectNode, targetNode.type.isFolder
        else {
            return []
        }
        guard let sourcePath = info.draggingPasteboard.string(forType: dragType)
        else {
            return []
        }

        let sourceURL = URL(fileURLWithPath: sourcePath)

        // Prevent invalid drops: into self, or into parent folder
        if targetNode.url.path.hasPrefix(sourceURL.path)
            || sourceURL.deletingLastPathComponent() == targetNode.url
        {
            return []
        }

        return .move
    }

    /// Accepts and performs a valid drop by moving the file in the filesystem.
    func outlineView(
        _ outlineView: NSOutlineView,
        acceptDrop info: NSDraggingInfo,
        item: Any?,
        childIndex index: Int
    ) -> Bool {
        guard let targetNode = item as? ProjectNode,
            let sourcePath = info.draggingPasteboard.string(forType: dragType)
        else {
            return false
        }

        let sourceURL = URL(fileURLWithPath: sourcePath)
        let destinationURL = targetNode.url.appendingPathComponent(
            sourceURL.lastPathComponent
        )

        do {
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
            return true
        } catch {
            logger.error(
                "Failed to move item during drop: \(error.localizedDescription)"
            )
            return false
        }
    }
}
