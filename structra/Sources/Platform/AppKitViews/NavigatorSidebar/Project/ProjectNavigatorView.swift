//
//  ProjectNavigatorView.swift
//  structra
//
//  Created by Nanashi Li on 6/22/25.
//

import Combine
import SwiftUI

/// A SwiftUI wrapper for `ProjectNavigatorViewController`.
struct ProjectNavigatorView: NSViewControllerRepresentable {
    @EnvironmentObject var workspaceManager: WorkspaceManager

    /// Creates and configures the AppKit view controller.
    func makeNSViewController(context: Context)
        -> ProjectNavigatorViewController
    {
        let controller = ProjectNavigatorViewController()
        controller.workspaceManager = workspaceManager

        // Sync selection changes reactively via Combine.
        if let session = workspaceManager.currentSession {
            session.$selectedNodeID
                .receive(on: DispatchQueue.main)
                .sink { [weak controller] nodeId in
                    controller?.updateSelection(to: nodeId)
                }
                .store(in: &context.coordinator.cancellables)
        }

        return controller
    }

    /// No imperative updates needed; Combine handles updates.
    func updateNSViewController(
        _ controller: ProjectNavigatorViewController,
        context: Context
    ) {
        // Intentionally left empty — reactive Combine binding used instead.
    }

    /// Coordinator to store Combine subscriptions.
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var cancellables = Set<AnyCancellable>()
    }
}
