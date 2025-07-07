//
//  ProjectGraph.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

/// Represents the entire lightweight dependency graph for a project.
/// This is the top-level object that can be cached to disk.
public struct ProjectGraph: Codable {
    public let id: UUID
    public let createdAt: Date
    public var files: [FileNode]

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        files: [FileNode] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.files = files
    }
}
