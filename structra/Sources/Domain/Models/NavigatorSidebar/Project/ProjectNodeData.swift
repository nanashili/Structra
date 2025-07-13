//
//  ProjectNodeData.swift
//  structra
//
//  Created by Nanashi Li on 6/22/25.
//

import Foundation

/// A fully‐self‐contained, immutable representation of one node (and its
/// descendants) in the project navigator tree.
///
/// - Conforms to `Identifiable` for list/diffing APIs.
/// - Conforms to `Codable` (annotated `@preconcurrency`) for off‐actor
///   JSON/PLIST/XML encoding & decoding.
/// - Mirrors the properties of `ProjectNode`, but without any actor or
///   UI bindings.
public struct ProjectNodeData: Identifiable, @preconcurrency Codable {
    // MARK: Identification

    /// Unique identifier matching `ProjectNode.id`. Used by diffable data sources.
    public let id: UUID

    // MARK: Filesystem Reference

    /// Absolute filesystem URL for this node (folder or file).
    public let url: URL

    // MARK: Display Properties

    /// Display name (typically the last path component of `url`).
    public let name: String

    /// Folder vs. file, with optional custom SF Symbol or asset icon.
    public let type: ProjectItemType

    // MARK: Metadata

    /// Attached metadata such as file size, creation/modification dates,
    /// user‐defined tags, and read‐only flag.
    public let metadata: NodeMetadata

    // MARK: Hierarchy

    /// Snapshots of all child nodes. Empty for files.
    public let children: [ProjectNodeData]

    // MARK: UI State

    /// Expansion state in the UI (mirrors `ProjectNode.isExpanded`).
    public let isExpanded: Bool
}
