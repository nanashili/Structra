//
//  WorkspaceSession.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/26/25.
//  Updated on 2025/06/26 to add `openFile(at:)` and `selectedNodeID` support.
//

import Combine
import Foundation
import AppKit
import SwiftUI

/// Holds one open project: its tree model, file watcher, and any other
/// per-project services (indexer, search, etc.).
@MainActor
public final class WorkspaceSession: ObservableObject {
    // MARK: – Public API

    public let projectURL: URL
    public let projectName: String
    public let treeModel: ProjectTreeModel
    @Published public var selectedNodeID: UUID?

    // MARK: – Private

    private let watcher: FileSystemWatcher
    private var autosaveCancellable: AnyCancellable?
    private var windowController: EditorWindowController?

    // MARK: – Initialization

    public init(
        projectURL: URL,
        excludePatterns: [String] = ["node_modules", ".git", "build", "dist"]
    ) {
        self.projectURL = projectURL
        self.projectName = projectURL.lastPathComponent
        self.treeModel = ProjectTreeModel(rootURLs: [projectURL])

        // File watcher setup
        let model = self.treeModel
        self.watcher = FileSystemWatcher(
            paths: [projectURL.path],
            excludePatterns: excludePatterns
        ) { events in
            Task { @MainActor in
                model.handleFileEvents(events)
            }
        }
        self.watcher.start()

        // Restore selection state
        restoreSelectionState()

        // Autosave selection state on change
        autosaveCancellable = $selectedNodeID
            .sink { [weak self] _ in self?.saveSelectionState() }
    }

    // MARK: – Window Management

    public func showWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.minSize = CGSize(width: 1000, height: 600)
        window.title = projectName

        let controller = EditorWindowController(window: window)
        self.windowController = controller
        controller.showWindow(self)
        window.center()
    }

    public func closeWindow() {
        windowController?.close()
        windowController = nil
    }

    // MARK: – State Persistence

    private func saveSelectionState() {
        let key = projectURL.path.sha256()
        if let data = try? PropertyListEncoder().encode(selectedNodeID) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func restoreSelectionState() {
        let key = projectURL.path.sha256()
        if let data = UserDefaults.standard.data(forKey: key),
           let id = try? PropertyListDecoder().decode(UUID?.self, from: data) {
            selectedNodeID = id
        }
    }

    // MARK: – Clean Up

    public func close() {
        saveSelectionState()
        watcher.cleanup()
        autosaveCancellable?.cancel()
        closeWindow()
    }

    // MARK: – Navigator Integration

    public func openFile(at url: URL) {
        if let node = treeModel.node(forPath: url.path) {
            selectedNodeID = node.id
        } else {
            selectedNodeID = nil
        }
    }
}
