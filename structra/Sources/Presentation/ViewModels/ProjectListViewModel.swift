//
//  ProjectListViewModel.swift
//  structra
//
//  Created by Nanashi Li on 6/18/25.
//

import AppKit
import Combine
import Foundation

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

        // Observe session changes from the WorkspaceManager
        workspaceManager.$currentSession
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                guard let self = self else { return }
                if let session = session {
                    let project = Project(
                        id: UUID(),
                        name: session.projectName,
                        url: session.projectURL
                    )
                    self.currentProject = project
                    // Add to recents if it's not already there
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
            workspaceManager.createAndOpenProject(at: url) { error in
                if let error = error {
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
            workspaceManager.openProject(at: url)
        }
    }
}
