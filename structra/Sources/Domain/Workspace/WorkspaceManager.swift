//
//  WorkspaceManager.swift
//  structra
//
//  Created by Nanashi Li on 6/26/25.
//

import Combine
import Foundation

public final class WorkspaceManager: ObservableObject {
    public static let shared = WorkspaceManager()

    @Published public private(set) var currentSession: WorkspaceSession?

    private init() {}

    public func openProject(at url: URL) {
        precondition(Thread.isMainThread, "Must be called on the main thread.")
        currentSession?.close()
        let session = WorkspaceSession(projectURL: url)
        currentSession = session

        session.showWindow()
    }

    /// Create a new project at the given URL, then open it.
    /// Replaces the async/throws version with a completion handler.
    public func createAndOpenProject(
        at url: URL,
        completion: @escaping (Error?) -> Void
    ) {
        precondition(Thread.isMainThread, "Must be called on the main thread.")

        // Perform file IO on a background thread.
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: url.path) {
                    try fileManager.createDirectory(
                        at: url,
                        withIntermediateDirectories: true
                    )
                }
                let manifestURL = url.appendingPathComponent("structra.project")
                if !fileManager.fileExists(atPath: manifestURL.path) {
                    let manifestData = Data()
                    fileManager.createFile(
                        atPath: manifestURL.path,
                        contents: manifestData
                    )
                }

                DispatchQueue.main.async {
                    self.openProject(at: url)
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    /// Close the current project and reset to welcome state.
    public func closeProject() {
        precondition(Thread.isMainThread, "Must be called on the main thread.")
        currentSession?.close()
        currentSession = nil
    }
}
