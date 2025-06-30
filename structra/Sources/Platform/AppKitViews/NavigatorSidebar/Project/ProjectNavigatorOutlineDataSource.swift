import AppKit
import OSLog

// MARK: – NSOutlineViewDataSource

extension ProjectNavigatorViewController: NSOutlineViewDataSource {
    /// Number of children under a given node (or root).
    func outlineView(
        _ outlineView: NSOutlineView,
        numberOfChildrenOfItem item: Any?
    ) -> Int {
        if let node = item as? ProjectNode {
            logger.info(
                "numberOfChildrenOfItem: \(node.name, privacy: .public) -> \(node.children.count)"
            )
            return node.children.count
        }
        logger.info("numberOfChildrenOfItem: root -> \(self.rootNodes.count)")
        return rootNodes.count
    }

    /// Child node at index under a given node (or root).
    func outlineView(
        _ outlineView: NSOutlineView,
        child index: Int,
        ofItem item: Any?
    ) -> Any {
        if let node = item as? ProjectNode {
            let child = node.children[index]
            logger.info(
                "child: \(node.name, privacy: .public) [\(index)] -> \(child.name, privacy: .public)"
            )
            return child
        }
        let child = rootNodes[index]
        logger.info("child: root [\(index)] -> \(child.name, privacy: .public)")
        return child
    }

    /// Folders are expandable; files are not.
    func outlineView(
        _ outlineView: NSOutlineView,
        isItemExpandable item: Any
    ) -> Bool {
        guard let node = item as? ProjectNode else {
            logger.info("isItemExpandable: (not a ProjectNode) -> false")
            return false
        }
        let expandable = node.type.isFolder
        logger.info(
            "isItemExpandable: \(node.name, privacy: .public) -> \(expandable)"
        )
        return expandable
    }

    // MARK: – Drag & Drop

    /// Provide a pasteboard writer (file path) for dragging.
    func outlineView(
        _ outlineView: NSOutlineView,
        pasteboardWriterForItem item: Any
    ) -> NSPasteboardWriting? {
        guard let node = item as? ProjectNode else {
            logger.fault("Drag: item is not ProjectNode")
            return nil
        }
        let pboard = NSPasteboardItem()
        pboard.setString(node.url.path, forType: dragType)
        return pboard
    }

    /// Validate whether a drop can occur on the proposed node.
    func outlineView(
        _ outlineView: NSOutlineView,
        validateDrop info: NSDraggingInfo,
        proposedItem item: Any?,
        proposedChildIndex index: Int
    ) -> NSDragOperation {
        guard
            let target = item as? ProjectNode,
            target.type.isFolder,
            let draggedPath = info.draggingPasteboard.string(forType: dragType)
        else {
            return []
        }

        let draggedURL = URL(fileURLWithPath: draggedPath)

        // Prevent dropping onto itself or inside its own subtree,
        // or into the same parent folder.
        let isSubtree = draggedPath.hasPrefix(target.url.path)
        let sameParent = draggedURL.deletingLastPathComponent() == target.url

        guard !isSubtree && !sameParent else {
            return []
        }

        return .move
    }

    /// Perform the move on disk. FileSystemWatcher will pick up and update the model.
    func outlineView(
        _ outlineView: NSOutlineView,
        acceptDrop info: NSDraggingInfo,
        item: Any?,
        childIndex index: Int
    ) -> Bool {
        guard
            let target = item as? ProjectNode,
            let draggedPath = info.draggingPasteboard.string(forType: dragType)
        else {
            return false
        }

        let srcURL = URL(fileURLWithPath: draggedPath)
        let dstURL = target.url.appendingPathComponent(srcURL.lastPathComponent)

        do {
            try FileManager.default.moveItem(at: srcURL, to: dstURL)
            return true
        } catch {
            logger.fault("Failed moving \(srcURL) → \(dstURL): \(error)")
            return false
        }
    }
}
