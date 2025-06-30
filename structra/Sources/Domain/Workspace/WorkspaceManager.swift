//
//  WorkspaceManager.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/26/25.
//

import Combine
import Foundation

/// The singleton app‐wide manager to open/close projects.
/// UI binds to `currentSession` to show a Welcome or Editor view.
@MainActor
public final class WorkspaceManager: ObservableObject {
    public static let shared = WorkspaceManager()

    /// The active workspace session (nil = no project open).
    @Published public private(set) var currentSession: WorkspaceSession?

    private init() {}

    /// Close existing session (if any), then open a new project.
    public func openProject(at url: URL) {
        currentSession?.close()
        currentSession = WorkspaceSession(projectURL: url)
    }

    /// Create a new project at the given URL, then open it.
    public func createAndOpenProject(at url: URL) async throws {
        // Example: create the directory and a manifest file
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
        }
        // Optionally, write a manifest or initial project file
        let manifestURL = url.appendingPathComponent("structra.project")
        if !fileManager.fileExists(atPath: manifestURL.path) {
            let manifestData = Data()  // Replace with actual manifest data
            fileManager.createFile(
                atPath: manifestURL.path,
                contents: manifestData
            )
        }
        // Now open the project
        openProject(at: url)
    }

    /// Close the current project and reset to welcome state.
    public func closeProject() {
        currentSession?.close()
        currentSession = nil
    }
}
