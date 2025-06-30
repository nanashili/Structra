//
//  ProjectService.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/18/25.
//

import Foundation

/// A trivial implementation that just wraps the URL in a Project.
/// In a real app you might scan for files, parse code, etc.
struct ProjectService: ProjectServiceProtocol {
    func openProject(at url: URL) async throws -> Project {
        return Project(
            id: UUID(),
            name: url.lastPathComponent,
            url: url
        )
    }
}
