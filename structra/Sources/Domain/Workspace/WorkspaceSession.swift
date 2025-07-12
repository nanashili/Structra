//
//  WorkspaceSession.swift
//  structra
//
//  Created by Nanashi Li on 6/26/25.
//

import AppKit
import Combine
import Foundation
import OSLog
import SwiftUI

/// Holds one open project: its tree model, file watcher, and any other
/// per-project services (indexer, search, etc.).
/// We've removed @MainActor and will manage thread safety explicitly.
/// This class is an ObservableObject and must be used on the main thread.
public final class WorkspaceSession: ObservableObject {
    // MARK: – Public API

    public let projectURL: URL
    public let projectName: String
    public let treeModel: ProjectTreeModel

    @Published public var selectedNodeID: UUID?
    @Published public private(set) var projectGraph: ProjectGraph?
    @Published public private(set) var isParsing: Bool = false
    @Published public private(set) var parsingError: String?

    /// Returns the `ProjectNode` that corresponds to the currently selected ID.
    /// Returns `nil` if no node is selected or if the ID is invalid.
    public var selectedNode: ProjectNode? {
        guard let selectedID = selectedNodeID else {
            return nil  // No ID is selected
        }
        // Ask the treeModel to find the node with this ID.
        return treeModel.node(withID: selectedID)
    }

    private let parser = HyperParser()
    private let logger = Logger(
        subsystem: "com.structra.workspace.session",
        category: "WorkspaceSession"
    )

    // MARK: – Private
    private lazy var watcher: FileSystemWatcher = {
        let watcher = FileSystemWatcher(paths: [projectURL.path]) {
            [weak self] events in
            self?.treeModel.handleFileEvents(events)
        }
        return watcher
    }()
    private var autosaveCancellable: AnyCancellable?
    private var windowController: EditorWindowController? {
        didSet {
            oldValue?.close()
        }
    }
    private var excludePatterns: [String]?

    // MARK: – Initialization

    public init(
        projectURL: URL,
        excludePatterns: [String] = ["node_modules", ".git", "build", "dist"]
    ) {
        precondition(
            Thread.isMainThread,
            "WorkspaceSession must be initialized on the main thread."
        )

        self.projectURL = projectURL
        self.projectName = projectURL.lastPathComponent
        self.treeModel = ProjectTreeModel(rootURLs: [projectURL])
        self.excludePatterns = excludePatterns

        // Restore selection state
        restoreSelectionState()

        // Autosave selection state on change. RunLoop.main is the correct scheduler here.
        autosaveCancellable =
            $selectedNodeID
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                // This sink is guaranteed to run on the main thread.
                self?.saveSelectionState()
            }

        self.watcher.start()
        self.startProjectParsing()
    }

    // MARK: - Project Parsing

    private func startProjectParsing() {
        self.isParsing = true
        self.parsingError = nil

        logger.info(
            "Kicking off background parse for project: \(self.projectName)"
        )

        Task(priority: .userInitiated) {
            do {

                let rules: [ExclusionRule] = [
                    // Exclude all directories named "node_modules" and ".git"
                    .name("node_modules"),
                    .name(".git"),
                    .path("build"),
                    .path("dist"),
                ]

                // 1. The heavy work happens on background threads inside the actor.
                let graph = try await self.parser.parse(
                    projectURL: self.projectURL,
                    excluding: rules
                )

                // 2. NEW: Save the resulting graph to a JSON file in the background.
                await self.saveGraphToDisk(graph)

                // 3. Update the UI state back on the main thread.
                await MainActor.run {
                    self.projectGraph = graph
                    self.isParsing = false
                    self.logger.info(
                        "Project graph successfully generated and cached."
                    )
                }

            } catch {
                let errorMessage =
                    "Failed to parse project: \(error.localizedDescription)"
                self.logger.error("\(errorMessage)")

                // Update the UI state with the error on the main thread.
                await MainActor.run {
                    self.parsingError = errorMessage
                    self.isParsing = false
                }
            }
        }
    }

    // MARK: - Graph Caching

    /// Returns the URL for the cached JSON graph file for this specific project.
    private func graphCacheURL() throws -> URL {
        // Get the app's support directory
        guard
            let supportDir = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else {
            throw NSError(
                domain: "WorkspaceSessionError",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Could not find application support directory."
                ]
            )
        }

        // Create a subdirectory for your app's cache
        let cacheDir = supportDir.appendingPathComponent(
            "com.structra.cache/ProjectGraphs"
        )

        // Ensure the directory exists
        try FileManager.default.createDirectory(
            at: cacheDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Create a unique filename based on a hash of the project's path
        let projectHash = self.projectURL.path.sha256()
        return cacheDir.appendingPathComponent("\(projectHash).json")
    }

    /// Encodes the project graph to JSON and saves it to a file asynchronously.
    private func saveGraphToDisk(_ graph: ProjectGraph) async {
        do {
            let destinationURL = try graphCacheURL()

            // Configure the encoder for readability
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            // Encode the graph object into JSON data
            let data = try encoder.encode(graph)

            if let jsonString = String(data: data, encoding: .utf8) {
                logger.debug(
                    """

                    --- BEGIN PROJECT GRAPH JSON ---
                    \(jsonString)
                    ---  END PROJECT GRAPH JSON  ---

                    """
                )
            } else {
                logger.warning(
                    "Could not convert graph JSON data to a string for logging."
                )
            }
            // --- END NEW CODE ---

            // Write the data to the file. This is an async-friendly operation.
            try data.write(to: destinationURL, options: .atomic)

            logger.info(
                "Successfully saved project graph to: \(destinationURL.path)"
            )

        } catch {
            // Log any errors during the saving process.
            // We don't throw here because failing to cache shouldn't crash the app.
            logger.error(
                "Failed to save project graph to disk: \(error.localizedDescription)"
            )
        }
    }

    // MARK: – Window Management

    public func showWindow() {
        precondition(
            Thread.isMainThread,
            "UI operations must be performed on the main thread."
        )

        let initialSize = CGSize(width: 1000, height: 600)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: initialSize),
            styleMask: [
                .titled, .closable, .miniaturizable, .resizable,
                .fullSizeContentView,
            ],
            backing: .buffered,
            defer: false
        )
        window.title = projectName
        window.minSize = CGSize(width: 600, height: 400)

        let controller = EditorWindowController(window: window)

        self.windowController = controller

        window.delegate = controller
        controller.showWindow(self)

        window.setContentSize(initialSize)
        window.center()

        // Debug: Verify the controller is retained
        print(
            "Window controller retained: \(String(describing: self.windowController))"
        )
    }

    public func closeWindow() {
        precondition(
            Thread.isMainThread,
            "UI operations must be performed on the main thread."
        )
        windowController?.close()
        windowController = nil
    }

    // MARK: – State Persistence

    private func saveSelectionState() {
        // This is called from a main-thread Combine sink, so we're safe.
        let key = "selection-\(projectURL.path.sha256())"
        guard let id = selectedNodeID else {
            UserDefaults.standard.removeObject(forKey: key)
            return
        }

        if let data = try? PropertyListEncoder().encode(id) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func restoreSelectionState() {
        // This is called from init, which we've enforced is on the main thread.
        let key = "selection-\(projectURL.path.sha256())"
        if let data = UserDefaults.standard.data(forKey: key),
            let id = try? PropertyListDecoder().decode(UUID.self, from: data)
        {
            // Modifying a @Published property must be done on the main thread.
            selectedNodeID = id
        }
    }

    // MARK: – Clean Up

    public func close() {
        precondition(
            Thread.isMainThread,
            "Cleanup must be initiated from the main thread."
        )
        saveSelectionState()
        watcher.stop()
        autosaveCancellable?.cancel()
        closeWindow()  // This will set windowController to nil
    }

    // MARK: – Navigator Integration

    public func openFile(at url: URL) {
        precondition(
            Thread.isMainThread,
            "File selection changes must be made on the main thread."
        )
        if let node = treeModel.node(forPath: url.path) {
            selectedNodeID = node.id
        } else {
            selectedNodeID = nil
        }
    }
}
