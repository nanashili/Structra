//
//  ProjectTreeModel.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/26/25.
//

import Combine
import Foundation

@MainActor
public final class ProjectTreeModel: ObservableObject {
    // MARK: – Published State

    /// Top‐level nodes for your outline view.
    @Published public private(set) var rootNodes: [ProjectNode] = []

    // MARK: – Lookups

    /// Fast ID → node
    private var nodesByID: [UUID: ProjectNode] = [:]
    /// Fast path → node
    private var nodesByPath: [String: ProjectNode] = [:]

    // MARK: – Incremental Events

    /// Emits add/remove/metadata events for diffable data sources.
    public let changePublisher = PassthroughSubject<NodeChangeEvent, Never>()

    // MARK: – Internal Queue

    /// Serial queue for tree mutations to avoid races.
    private let modelQueue = DispatchQueue(
        label: "com.stuctra.ProjectTreeModel",
        qos: .utility
    )

    // MARK: – Initialization

    /// Initialize with zero or more top‐level folder URLs.
    public init(rootURLs: [URL] = []) {
        // Create nodes for each URL
        self.rootNodes = rootURLs.map { url in
            let type: ProjectItemType =
                url.hasDirectoryPath
                ? .folder(customIconName: "") : .file(customIconName: "")
            return ProjectNode(
                url: url,
                name: url.lastPathComponent,
                type: type
            )
        }
        // Map them into lookups
        rootNodes.forEach(mapRecursively(_:))
    }

    // MARK: – Public Lookup

    /// O(1) lookup by UUID.
    public func node(withID id: UUID) -> ProjectNode? {
        nodesByID[id]
    }

    /// O(1) lookup by full filesystem path.
    public func node(forPath path: String) -> ProjectNode? {
        nodesByPath[path]
    }

    // MARK: – FileSystem Integration

    /// Apply batched FSEvents from `FileSystemWatcher`.
    /// Call this on the MainActor.
    public func handleFileEvents(_ events: [FileEvent]) {
        for ev in events {
            let path = ev.path
            if ev.isRemoved {
                removeNode(atPath: path)
            }
            if ev.isCreated {
                addNode(atPath: path)
            }
            if ev.isModified {
                updateMetadata(atPath: path)
            }
            // Note: renames will show up as remove + create
        }
    }

    // MARK: – Mutation Helpers

    /// Insert a newly created file/folder into the tree.
    private func addNode(atPath path: String) {
        // Avoid duplicates
        guard nodesByPath[path] == nil else { return }

        let url = URL(fileURLWithPath: path)
        let parentPath = url.deletingLastPathComponent().path
        let type: ProjectItemType =
            url.hasDirectoryPath
            ? .folder(customIconName: "") : .file(customIconName: "")
        let newNode = ProjectNode(
            url: url,
            name: url.lastPathComponent,
            type: type
        )

        if let parent = nodesByPath[parentPath] {
            parent.addChild(newNode)
            changePublisher.send(.added(node: newNode, parentID: parent.id))
        } else {
            // New root
            rootNodes.append(newNode)
            changePublisher.send(.added(node: newNode, parentID: nil))
        }

        // Map into lookups
        mapRecursively(newNode)
    }

    /// Remove a file/folder (and its subtree) from the tree.
    private func removeNode(atPath path: String) {
        guard let node = nodesByPath[path] else { return }

        node.removeFromParent()
        if node.parent == nil {
            // It was a root
            rootNodes.removeAll { $0 === node }
        }

        // Clean up all descendants from lookups
        node.flattened().forEach {
            nodesByID[$0.id] = nil
            nodesByPath[$0.url.path] = nil
        }

        changePublisher.send(.removed(nodeID: node.id))
    }

    /// Refresh file metadata (size, modification date).
    private func updateMetadata(atPath path: String) {
        guard let node = nodesByPath[path] else { return }
        let attrs =
            (try? FileManager.default.attributesOfItem(atPath: path)) ?? [:]
        var md = node.metadata
        md.modifiedDate = attrs[.modificationDate] as? Date
        md.fileSize = (attrs[.size] as? NSNumber)?.int64Value
        node.metadata = md
        changePublisher.send(.metadataUpdated(nodeID: node.id, metadata: md))
    }

    // MARK: – Lookup Mapping

    /// Recursively register a node and its children.
    private func mapRecursively(_ node: ProjectNode) {
        nodesByID[node.id] = node
        nodesByPath[node.url.path] = node
        node.children.forEach(mapRecursively(_:))
    }
}
