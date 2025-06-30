//
//  ProjectListViewModel.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/18/25.
//

import AppKit
import Combine
import Foundation

@MainActor
final class ProjectListViewModel: ObservableObject {
    @Published var recentProjects: [Project] = []
    @Published var currentProject: Project?

    let projectService: ProjectServiceProtocol
    let workspaceManager: WorkspaceManager

    private var cancellables = Set<AnyCancellable>()

    init(
        projectService: ProjectServiceProtocol,
        workspaceManager: WorkspaceManager = .shared
    ) {
        self.projectService = projectService
        self.workspaceManager = workspaceManager

        // Observe session changes
        workspaceManager.$currentSession
            .sink { [weak self] session in
                guard let self = self else { return }
                if let session = session {
                    let project = Project(
                        id: UUID(),
                        name: session.projectName,
                        url: session.projectURL
                    )
                    self.currentProject = project
                    if !self.recentProjects.contains(where: {
                        $0.url == project.url
                    }) {
                        self.recentProjects.insert(project, at: 0)
                    }
                } else {
                    self.currentProject = nil
                }
            }
            .store(in: &cancellables)
    }

    func createNewProject() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "MyProject"
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            Task { @MainActor in
                do {
                    try await workspaceManager.createAndOpenProject(at: url)
                    // No need to call showEditorWindow here; handled by session observer
                } catch {
                    print("Failed to create project:", error)
                }
            }
        }
    }

    func openExistingProject() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            Task { @MainActor in
                workspaceManager.openProject(at: url)
            }
        }
    }
}
