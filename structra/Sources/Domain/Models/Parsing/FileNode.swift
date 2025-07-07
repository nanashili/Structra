//
//  FileNode.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

/// Represents a single parsed file within the project graph.
public struct FileNode: Codable, Identifiable, Hashable {
    public let id: UUID
    public let path: String
    public let language: Language
    public let contentHash: String
    public var declaredSymbols: [String]
    public var imports: [String]
    public var roleHints: [String]

    public init(
        id: UUID = UUID(),
        path: String,
        language: Language,
        contentHash: String,
        declaredSymbols: [String] = [],
        imports: [String] = [],
        roleHints: [String] = []
    ) {
        self.id = id
        self.path = path
        self.language = language
        self.contentHash = contentHash
        self.declaredSymbols = declaredSymbols
        self.imports = imports
        self.roleHints = roleHints
    }
}
