//
//  ProjectNavigatorView.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/22/25.
//  Updated 2025/06/26 to drive selection with updateSelection(to:).
//

import Combine
import SwiftUI

struct ProjectNavigatorView: NSViewControllerRepresentable {
    @EnvironmentObject var workspaceManager: WorkspaceManager

    func makeNSViewController(
        context: Context
    ) -> ProjectNavigatorViewController {
        let controller = ProjectNavigatorViewController()
        controller.workspaceManager = workspaceManager

        // Subscribe to selectedNodeID and forward to the outline:
        if let session = workspaceManager.currentSession {
            session.$selectedNodeID
                .receive(on: DispatchQueue.main)
                .sink { [weak controller] nodeId in
                    controller?.updateSelection(to: nodeId)
                }
                .store(in: &context.coordinator.cancellables)
        }

        context.coordinator.controller = controller
        return controller
    }

    func updateNSViewController(
        _ controller: ProjectNavigatorViewController,
        context: Context
    ) {
        let nodeId = workspaceManager.currentSession?.selectedNodeID
        controller.updateSelection(to: nodeId)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var controller: ProjectNavigatorViewController?
        var cancellables = Set<AnyCancellable>()
    }
}
