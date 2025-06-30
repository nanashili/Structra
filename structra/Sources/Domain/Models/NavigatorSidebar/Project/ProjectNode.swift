//
//  ProjectNode.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/22/25.
//

import Foundation
import Observation

/// A single element in the project tree: either a folder or a file.
///
/// - `@MainActor` guarantees that all property accesses and mutations
///   occur on the main thread (no data races).
/// - `@Observable` (SwiftData/SwiftUI macro) auto-generates publishers for
///   all mutable properties, so UI can react to changes automatically.
///
/// Conforms to `Identifiable` for diffable data sources and SwiftUI collection APIs.
@Observable
@MainActor
public final class ProjectNode: Identifiable {
    // MARK: Properties

    /// Unique identifier used by `NSOutlineViewDiffableDataSource` or SwiftUI.
    public let id: UUID

    /// The file-system URL this node represents.
    public let url: URL

    /// Display name for UI; typically `url.lastPathComponent`.
    public var name: String

    /// Indicates whether this node is a `.folder` or `.file`, and supplies
    /// any custom icon name.
    public let type: ProjectItemType

    /// Attached metadata: file size, modification date, tags, etc.
    public var metadata: NodeMetadata

    /// Child nodes, empty if this node is a file.
    public var children: [ProjectNode]

    /// UI state: whether the node is expanded (folders only).
    public var isExpanded: Bool

    /// Weak back-pointer to the parent node (`nil` for root nodes).
    public weak var parent: ProjectNode?

    // MARK: Initialization

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - id: Unique UUID (default: new `UUID()`).
    ///   - url: File URL for this node.
    ///   - name: Display name in the UI.
    ///   - type: `.folder` or `.file`.
    ///   - metadata: Initial metadata (default: empty).
    ///   - children: Pre-populated children (default: `[]`).
    ///   - isExpanded: Initial expansion state (default: `true`).
    public init(
        id: UUID = UUID(),
        url: URL,
        name: String,
        type: ProjectItemType,
        metadata: NodeMetadata = .init(),
        children: [ProjectNode] = [],
        isExpanded: Bool = true
    ) {
        self.id = id
        self.url = url
        self.name = name
        self.type = type
        self.metadata = metadata
        self.children = children
        self.isExpanded = isExpanded

        // Wire each child’s `parent` pointer back to this node.
        self.children.forEach { $0.parent = self }
    }

    // MARK: Build & Snapshot

    /// Recursively constructs a `ProjectNode` tree from a serializable
    /// `ProjectNodeData` value (e.g. loaded from disk).
    ///
    /// - Parameter data: Serialized node data including children.
    /// - Returns: A live `ProjectNode` tree with proper parent links.
    public static func build(from data: ProjectNodeData) -> ProjectNode {
        let node = ProjectNode(
            id: data.id,
            url: data.url,
            name: data.name,
            type: data.type,
            metadata: data.metadata,
            isExpanded: data.isExpanded
        )
        node.children = data.children.map {
            let child = ProjectNode.build(from: $0)
            child.parent = node
            return child
        }
        return node
    }

    /// Converts this node (and its descendants) into a `ProjectNodeData`
    /// snapshot suitable for serialization.
    ///
    /// - Returns: Serialized representation including children.
    public func snapshot() -> ProjectNodeData {
        ProjectNodeData(
            id: id,
            url: url,
            name: name,
            type: type,
            metadata: metadata,
            children: children.map { $0.snapshot() },
            isExpanded: isExpanded
        )
    }

    // MARK: Tree Mutation Helpers

    /// Adds a new child under this node (no-op if this is a file).
    ///
    /// - Parameter node: The `ProjectNode` to append.
    public func addChild(_ node: ProjectNode) {
        guard type.isFolder else { return }
        node.parent = self
        children.append(node)
    }

    /// Inserts a new child at a specific index (no-op if not a folder).
    ///
    /// - Parameters:
    ///   - node: The node to insert.
    ///   - idx:  Zero-based position in the `children` array.
    public func insertChild(_ node: ProjectNode, at idx: Int) {
        guard
            type.isFolder,
            idx >= 0, idx <= children.count
        else { return }
        node.parent = self
        children.insert(node, at: idx)
    }

    /// Detaches this node (and its entire subtree) from its parent.
    public func removeFromParent() {
        parent?.children.removeAll { $0 === self }
        parent = nil
    }

    /// Updates this node’s display name.
    ///
    /// - Parameter newName: The new name to assign.
    public func rename(to newName: String) {
        name = newName
    }

    // MARK: Traversal

    /// Visits this node and all descendants in depth-first order.
    ///
    /// - Parameter visit: Closure invoked for each node.
    public func traverse(_ visit: (ProjectNode) -> Void) {
        visit(self)
        children.forEach { $0.traverse(visit) }
    }

    /// Returns a flat array of this node and all its descendants.
    ///
    /// - Returns: An array of `ProjectNode`.
    public func flattened() -> [ProjectNode] {
        var array: [ProjectNode] = []
        traverse { array.append($0) }
        return array
    }
}
