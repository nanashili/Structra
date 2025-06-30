//
//  ProjectNavigatorMenu.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/22/25.
//

import AppKit
import OSLog
import UniformTypeIdentifiers

final class ProjectNavigatorMenu: NSMenu {
    typealias Node = ProjectNode

    /// The node this menu is targeting.
    var node: Node?

    /// The application's workspace manager.
    weak var workspaceManager: WorkspaceManager?

    /// The outline view hosting this menu.
    private let outlineView: NSOutlineView?

    private let logger = Logger(
        subsystem: "com.structra.app",
        category: "ProjectNavigatorMenu"
    )

    nonisolated override init(title: String) {
        self.outlineView = nil
        self.workspaceManager = nil
        super.init(title: title)
    }

    init(sender outline: NSOutlineView, workspaceManager: WorkspaceManager) {
        self.outlineView = outline
        self.workspaceManager = workspaceManager
        super.init(title: "Options")
    }

    @available(*, unavailable)
    required nonisolated init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupMenu() {
        guard let node = node else { return }
        let isFolder = node.type.isFolder
        let session = workspaceManager?.currentSession

        // Reveal in Finder
        addItem(menuItem("Show in Finder", action: #selector(showInFinder)))

        addItem(.separator())

        // Open
        addItem(menuItem("Open in Tab", action: #selector(openInTab)))
        if !isFolder {
            addItem(
                menuItem(
                    "Open in New Window",
                    action: #selector(openInNewWindow)
                )
            )
        }
        addItem(
            menuItem(
                "Open with External Editor",
                action: #selector(openWithExternalEditor)
            )
        )
        if isFolder {
            addItem(
                menuItem(
                    "Open in Integrated Terminal",
                    action: #selector(openInIntegratedTerminal)
                )
            )
        }

        addItem(.separator())

        // Create
        addItem(menuItem("New File…", action: #selector(newFile)))
        addItem(menuItem("New Folder…", action: #selector(newFolder)))

        addItem(.separator())

        // Rename / Duplicate / Delete
        addItem(menuItem("Rename", action: #selector(renameItem)))
        addItem(menuItem("Duplicate", action: #selector(duplicateItem)))
        addItem(menuItem("Delete", action: #selector(deleteItem)))

        addItem(.separator())

        // Document‐editor actions (files only)
        if !isFolder {
            addItem(
                menuItem("Format Document", action: #selector(formatDocument))
            )
            addItem(
                menuItem(
                    "Generate Documentation",
                    action: #selector(generateDocumentation)
                )
            )
            addItem(menuItem("Copy Path", action: #selector(copyPath)))
        }

        addItem(.separator())

        // Sorting (folders only)
        let sortByNameItem = menuItem(
            "Sort by Name",
            action: #selector(sortByName)
        )
        sortByNameItem.isEnabled = isFolder
        addItem(sortByNameItem)

        let sortByTypeItem = menuItem(
            "Sort by Type",
            action: #selector(sortByType)
        )
        sortByTypeItem.isEnabled = isFolder
        addItem(sortByTypeItem)
    }

    private func menuItem(_ title: String, action: Selector?) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    // MARK: – Actions

    @objc private func showInFinder() {
        guard let node = node else { return }
        NSWorkspace.shared.activateFileViewerSelecting([node.url])
    }

    @objc private func openInTab() {
        guard let node = node else { return }
        workspaceManager?.currentSession?.openFile(at: node.url)
    }

    @objc private func openInNewWindow() {
        guard let node = node else { return }
        // Fallback: open with default app in a new window
        NSWorkspace.shared.open(node.url)
    }

    @objc private func openWithExternalEditor() {
        guard let node = node else { return }
        NSWorkspace.shared.open(node.url)
    }

    @objc private func openInIntegratedTerminal() {
        guard let node = node, node.type.isFolder else { return }
        NotificationCenter.default.post(
            name: .openInTerminal,
            object: node.url
        )
    }

    @objc private func newFile() {
        guard let node = node else { return }
        let dirURL =
            node.type.isFolder
            ? node.url
            : node.url.deletingLastPathComponent()
        let newURL = dirURL.appendingPathComponent("untitled.txt")
        FileManager.default.createFile(
            atPath: newURL.path,
            contents: Data(),
            attributes: nil
        )
    }

    @objc private func newFolder() {
        guard let node = node else { return }
        let dirURL =
            node.type.isFolder
            ? node.url
            : node.url.deletingLastPathComponent()
        let newURL = dirURL.appendingPathComponent("New Folder")
        do {
            try FileManager.default.createDirectory(
                at: newURL,
                withIntermediateDirectories: false,
                attributes: nil
            )
        } catch {
            logger.error(
                "Failed to create folder: \(error.localizedDescription)"
            )
        }
    }

    @objc private func renameItem() {
        guard let node = node, let outlineView = outlineView else { return }
        let row = outlineView.row(forItem: node)
        guard row >= 0,
            let cell = outlineView.view(
                atColumn: 0,
                row: row,
                makeIfNecessary: false
            ) as? FileSystemTableViewCell
        else { return }
        outlineView.window?.makeFirstResponder(cell.textField)
    }

    @objc private func duplicateItem() {
        guard let node = node else { return }
        let src = node.url
        let dst = src.deletingLastPathComponent()
            .appendingPathComponent("\(node.name) copy")
        do {
            try FileManager.default.copyItem(at: src, to: dst)
        } catch {
            logger.error("Duplicate failed: \(error.localizedDescription)")
        }
    }

    @objc private func deleteItem() {
        guard let node = node else { return }
        let alert = NSAlert()
        alert.messageText = "Move \"\(node.name)\" to the Trash?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Trash")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            do {
                try FileManager.default.trashItem(
                    at: node.url,
                    resultingItemURL: nil
                )
            } catch {
                logger.error("Delete failed: \(error.localizedDescription)")
            }
        }
    }

    @objc private func formatDocument() {
        guard let node = node else { return }
        NotificationCenter.default.post(
            name: .formatDocument,
            object: node.url
        )
    }

    @objc private func generateDocumentation() {
        guard let node = node else { return }
        NotificationCenter.default.post(
            name: .generateDocumentation,
            object: node.url
        )
    }

    @objc private func copyPath() {
        guard let node = node else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(node.url.path, forType: .string)
    }

    @objc private func sortByName() {
        // TODO: implement treeModel.sortByName()
    }

    @objc private func sortByType() {
        // TODO: implement treeModel.sortByType()
    }
}

extension Notification.Name {
    static let openInTerminal = Notification.Name("OpenInTerminal")
    static let formatDocument = Notification.Name("FormatDocument")
    static let generateDocumentation = Notification.Name(
        "GenerateDocumentation"
    )
}

