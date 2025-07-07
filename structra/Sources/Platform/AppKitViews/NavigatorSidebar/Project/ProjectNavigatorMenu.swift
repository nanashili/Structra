//
//  ProjectNavigatorMenu.swift
//  structra
//
//  Created by Nanashi Li on 6/22/25.
//

import AppKit
import OSLog
import UniformTypeIdentifiers

final class ProjectNavigatorMenu: NSMenu, NSMenuDelegate {
    typealias Node = ProjectNode

    /// The node this menu is targeting. Set dynamically when the menu is about to open.
    private var targetNode: Node?

    /// The application's workspace manager.
    private weak var workspaceManager: WorkspaceManager?

    /// The outline view hosting this menu.
    private weak var outlineView: NSOutlineView?

    private let logger = Logger(
        subsystem: "com.structra.app",
        category: "ProjectNavigatorMenu"
    )

    init(sender outline: NSOutlineView, workspaceManager: WorkspaceManager) {
        self.outlineView = outline
        self.workspaceManager = workspaceManager
        super.init(title: "Options")
        self.delegate = self
    }

    @available(*, unavailable)
    override init(title: String) {
        fatalError(
            "This initializer is not supported. Use init(sender:workspaceManager:) instead."
        )
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// This delegate method is called by AppKit right before the menu is shown.
    /// It's the perfect place to configure which items are enabled and visible.
    func menuNeedsUpdate(_ menu: NSMenu) {
        // Clear out any previous items to rebuild fresh.
        removeAllItems()

        guard let outlineView = outlineView else { return }
        let clickedRow = outlineView.clickedRow

        guard clickedRow >= 0,
            let node = outlineView.item(atRow: clickedRow) as? Node
        else {
            return
        }
        self.targetNode = node

        setupMenu()
    }

    private func setupMenu() {
        guard let node = targetNode else { return }
        let isFolder = node.type.isFolder

        // Reveal in Finder
        addItem(menuItem("Show in Finder", action: #selector(showInFinder)))
        addItem(.separator())

        // Create
        addItem(menuItem("New File…", action: #selector(newFile)))
        addItem(menuItem("New Folder…", action: #selector(newFolder)))
        addItem(.separator())

        // AI Actions
        let generateDocItem = menuItem(
            "Generate Document…",
            action: #selector(generateDocument)
        )
        generateDocItem.isEnabled = isFolder  // Only enable for folders
        addItem(generateDocItem)
        addItem(.separator())

        // Rename / Duplicate / Delete
        addItem(menuItem("Rename", action: #selector(renameItem)))
        addItem(menuItem("Duplicate", action: #selector(duplicateItem)))
        addItem(menuItem("Delete", action: #selector(deleteItem)))
        addItem(.separator())

        setupSortMenu()

        addItem(menuItem("Copy Path", action: #selector(copyPath)))
    }

    private func setupSortMenu() {
        guard let node = targetNode, node.type.isFolder else { return }

        let sortMenu = NSMenu(title: "Sort Children By")

        // Create menu items for each sort descriptor
        let nameItem = sortMenuItem("Name", descriptor: .name)
        let dateItem = sortMenuItem("Date Modified", descriptor: .dateModified)
        let sizeItem = sortMenuItem("Size", descriptor: .size)
        let typeItem = sortMenuItem("Type", descriptor: .type)

        // Add a checkmark to the currently active sort item
        if node.sortDescriptor == .name { nameItem.state = .on }
        if node.sortDescriptor == .dateModified { dateItem.state = .on }
        if node.sortDescriptor == .size { sizeItem.state = .on }
        if node.sortDescriptor == .type { typeItem.state = .on }

        sortMenu.addItem(nameItem)
        sortMenu.addItem(dateItem)
        sortMenu.addItem(sizeItem)
        sortMenu.addItem(typeItem)

        let sortMenuItem = NSMenuItem(
            title: "Sort Children By",
            action: nil,
            keyEquivalent: ""
        )
        sortMenuItem.submenu = sortMenu
        addItem(sortMenuItem)
        addItem(.separator())
    }

    private func menuItem(_ title: String, action: Selector?) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func sortMenuItem(_ title: String, descriptor: SortDescriptor)
        -> NSMenuItem
    {
        let item = NSMenuItem(
            title: title,
            action: #selector(applySort(_:)),
            keyEquivalent: ""
        )
        item.target = self
        item.representedObject = descriptor
        return item
    }

    // MARK: – Actions

    @objc private func showInFinder() {
        guard let node = targetNode else { return }
        NSWorkspace.shared.activateFileViewerSelecting([node.url])
    }

    @objc private func copyPath() {
        guard let node = targetNode else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(node.url.path, forType: .string)
    }

    @objc private func renameItem() {
        guard let node = targetNode, let outlineView = outlineView else {
            return
        }
        let row = outlineView.row(forItem: node)
        guard row >= 0,
            let cell = outlineView.view(
                atColumn: 0,
                row: row,
                makeIfNecessary: false
            ) as? FileSystemTableViewCell
        else { return }

        cell.beginEditing()
    }

    @objc private func generateDocument() {
        guard let node = targetNode else { return }
        workspaceManager?.initiateDocumentationGeneration(for: node, detailLevel: "exhaustive")
    }

    // MARK: - Asynchronous File I/O Actions

    @objc private func newFile() {
        guard let node = targetNode else { return }
        let dirURL =
            node.type.isFolder ? node.url : node.url.deletingLastPathComponent()
        let newURL = dirURL.appendingPathComponent("untitled.txt")

        DispatchQueue.global(qos: .userInitiated).async {
            FileManager.default.createFile(
                atPath: newURL.path,
                contents: Data(),
                attributes: nil
            )
        }
    }

    @objc private func newFolder() {
        guard let node = targetNode else { return }
        let dirURL =
            node.type.isFolder ? node.url : node.url.deletingLastPathComponent()
        let newURL = dirURL.appendingPathComponent("New Folder")

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try FileManager.default.createDirectory(
                    at: newURL,
                    withIntermediateDirectories: false,
                    attributes: nil
                )
            } catch {
                self.logger.error(
                    "Failed to create folder: \(error.localizedDescription, privacy: .public)"
                )
            }
        }
    }

    @objc private func duplicateItem() {
        guard let node = targetNode else { return }
        let src = node.url
        let dst = src.deletingLastPathComponent().appendingPathComponent(
            "\(node.name) copy"
        )

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try FileManager.default.copyItem(at: src, to: dst)
            } catch {
                self.logger.error(
                    "Duplicate failed: \(error.localizedDescription, privacy: .public)"
                )
            }
        }
    }

    @objc private func deleteItem() {
        guard let node = targetNode else { return }

        let alert = NSAlert()
        alert.messageText =
            "Are you sure you want to move \"\(node.name)\" to the Trash?"
        alert.informativeText = "This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Move to Trash")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try FileManager.default.trashItem(
                    at: node.url,
                    resultingItemURL: nil
                )
            } catch {
                self.logger.error(
                    "Delete failed: \(error.localizedDescription, privacy: .public)"
                )
            }
        }
    }

    // MARK: - Sorting Actions

    @objc private func applySort(_ sender: NSMenuItem) {
        guard let node = targetNode,
            let descriptor = sender.representedObject as? SortDescriptor,
            let treeModel = workspaceManager?.currentSession?.treeModel
        else { return }

        let newDirection: SortDirection
        if node.sortDescriptor == descriptor {
            newDirection =
                (node.sortDirection == .ascending) ? .descending : .ascending
        } else {
            newDirection = .ascending
        }

        treeModel.sortChildren(
            of: node,
            by: descriptor,
            direction: newDirection
        )
    }
}
