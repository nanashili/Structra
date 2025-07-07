//
//  ProjectTreeModel.swift
//  structra
//
//  Created by Nanashi Li on 6/26/25.
//

import Combine
import Foundation

public final class ProjectTreeModel: ObservableObject {
    // MARK: – Published State

    /// Top‐level nodes for your outline view. Access is synchronized via the main thread.
    @Published public private(set) var rootNodes: [ProjectNode] = []

    // MARK: – Lookups (Protected by modelQueue)

    /// Fast ID → node lookup.
    private var nodesByID: [UUID: ProjectNode] = [:]
    /// Fast path → node lookup.
    private var nodesByPath: [String: ProjectNode] = [:]

    // MARK: – Incremental Events

    /// Emits add/remove/metadata events. Guaranteed to be sent on the main thread.
    public let changePublisher = PassthroughSubject<NodeChangeEvent, Never>()

    // MARK: – Internal Queue

    /// Writes are performed using a barrier to ensure exclusive access, implementing a
    /// reader-writer lock pattern. This is more performant than a serial queue
    /// if lookups are frequent.
    private let modelQueue = DispatchQueue(
        label: "com.stuctra.ProjectTreeModel.concurrent",
        qos: .utility,
        attributes: .concurrent
    )

    // MARK: – Initialization

    public init(rootURLs: [URL] = []) {
        self.rootNodes = rootURLs.map { url in
            let type: ProjectItemType =
                url.hasDirectoryPath
                ? .folder(customIconName: nil) : .file(customIconName: nil)
            return ProjectNode(
                url: url,
                name: url.lastPathComponent,
                type: type,
                children: []
            )
        }

        modelQueue.async(flags: .barrier) {
            self.rootNodes.forEach { self.mapRecursively($0) }
        }
    }

    private func normalized(_ path: String) -> String {
        if path.last == "/" && path.count > 1 {
            return String(path.dropLast())
        }
        return path
    }

    // MARK: – Public Lookup

    /// This read is dispatched synchronously to our queue, preventing data races
    /// with write operations happening in the background.
    public func node(withID id: UUID) -> ProjectNode? {
        modelQueue.sync {
            self.nodesByID[id]
        }
    }

    public func node(forPath path: String) -> ProjectNode? {
        let normPath = normalized(path)
        return modelQueue.sync {
            self.nodesByPath[normPath]
        }
    }

    // MARK: - Sorting

    func sortChildren(
        of node: ProjectNode?,
        by descriptor: SortDescriptor,
        direction: SortDirection
    ) {
        guard let node = node, node.type.isFolder else { return }

        node.sortDescriptor = descriptor
        node.sortDirection = direction

        node.children.sort { (lhs, rhs) -> Bool in
            let result: Bool
            switch descriptor {
            case .name:
                result =
                    lhs.name.localizedStandardCompare(rhs.name)
                    == .orderedAscending
            case .dateModified:
                result =
                    (lhs.metadata.modifiedDate ?? .distantPast)
                    < (rhs.metadata.modifiedDate ?? .distantPast)
            case .size:
                result =
                    (lhs.metadata.fileSize ?? 0) < (rhs.metadata.fileSize ?? 0)
            case .type:
                result =
                    (lhs.metadata.fileType ?? "").localizedStandardCompare(
                        rhs.metadata.fileType ?? ""
                    ) == .orderedAscending
            }

            return direction == .ascending ? result : !result
        }

        changePublisher.send(.reloaded(parentID: node.id))
    }

    // MARK: – FileSystem Integration

    public func handleFileEvents(_ events: [FileEvent]) {
        modelQueue.async(flags: .barrier) {
            let fileManager = FileManager.default

            var potentialRenames: [String: String] = [:]  // [oldPath: newPath]
            var creations = Set<String>()
            var deletions = Set<String>()
            var modifications = Set<String>()

            var appearedPaths: [String: FileEvent] = [:]
            var disappearedPaths: [String: FileEvent] = [:]

            for event in events {
                let path = self.normalized(event.path)
                if event.isRenamed {
                    if fileManager.fileExists(atPath: path) {
                        appearedPaths[path] = event
                    } else {
                        disappearedPaths[path] = event
                    }
                } else if event.isCreated {
                    creations.insert(path)
                } else if event.isRemoved {
                    deletions.insert(path)
                } else if event.isModified {
                    modifications.insert(path)
                }
            }

            for (oldPath, _) in disappearedPaths {
                let oldURL = URL(fileURLWithPath: oldPath)
                let parentDir = self.normalized(
                    oldURL.deletingLastPathComponent().path
                )

                if let newPath = appearedPaths.keys.first(where: {
                    self.normalized(
                        URL(fileURLWithPath: $0).deletingLastPathComponent()
                            .path
                    ) == parentDir
                }) {
                    potentialRenames[oldPath] = newPath

                    appearedPaths.removeValue(forKey: newPath)
                    disappearedPaths.removeValue(forKey: oldPath)
                }
            }

            creations.formUnion(appearedPaths.keys)
            deletions.formUnion(disappearedPaths.keys)

            for (oldPath, newPath) in potentialRenames {
                self.renameNode(fromPath: oldPath, toPath: newPath)
            }
            for path in deletions {
                self.removeNode(atPath: path)
            }
            for path in creations {
                self.addNode(atPath: path)
            }
            for path in modifications {
                self.updateMetadata(atPath: path)
            }
        }
    }

    private func addNode(atPath path: String) {
        let normPath = normalized(path)
        guard nodesByPath[normPath] == nil else { return }

        let url = URL(fileURLWithPath: normPath)
        let parentPath = normalized(url.deletingLastPathComponent().path)

        let parent = nodesByPath[parentPath]

        let type: ProjectItemType =
            url.hasDirectoryPath
            ? .folder(customIconName: nil) : .file(customIconName: nil)
        let newNode = ProjectNode(
            url: url,
            name: url.lastPathComponent,
            type: type,
            children: []
        )

        updateMetadata(for: newNode, shouldNotify: false)

        mapRecursively(newNode)

        DispatchQueue.main.async {
            if let parentNode = parent {
                parentNode.addChild(newNode)
                self.changePublisher.send(
                    .added(node: newNode, parentID: parentNode.id)
                )
            } else {
                self.rootNodes.append(newNode)
                self.changePublisher.send(.added(node: newNode, parentID: nil))
            }
        }
    }

    private func removeNode(atPath path: String) {
        let normPath = normalized(path)
        guard let node = nodesByPath[normPath] else { return }

        let nodeID = node.id
        let parent = node.parent
        let parentID = parent?.id

        unmapRecursively(node)

        let removalIndex =
            parent?.children.firstIndex(where: { $0.id == nodeID })
            ?? rootNodes.firstIndex(where: { $0.id == nodeID })

        DispatchQueue.main.async {
            if let parentNode = parent {
                parentNode.children.removeAll { $0.id == nodeID }
            } else {
                self.rootNodes.removeAll { $0.id == nodeID }
            }

            if let index = removalIndex {
                self.changePublisher.send(
                    .removed(
                        nodeID: nodeID,
                        parentID: parentID,
                        fromIndex: index
                    )
                )
            } else {
                self.changePublisher.send(.reloaded(parentID: parentID))
            }
        }
    }

    private func renameNode(fromPath: String, toPath: String) {
        let normFromPath = normalized(fromPath)
        let normToPath = normalized(toPath)

        guard let node = nodesByPath[normFromPath] else { return }

        nodesByPath.removeValue(forKey: normFromPath)
        nodesByPath[normToPath] = node

        let oldName = node.name
        let newURL = URL(fileURLWithPath: normToPath)
        let newName = newURL.lastPathComponent

        DispatchQueue.main.async {
            node.url = newURL
            node.name = newName
            self.changePublisher.send(
                .renamed(nodeID: node.id, oldName: oldName, newName: newName)
            )
        }
    }

    private func updateMetadata(atPath path: String) {
        let normPath = normalized(path)
        guard let node = nodesByPath[normPath] else { return }
        updateMetadata(for: node, shouldNotify: true)
    }

    private func updateMetadata(for node: ProjectNode, shouldNotify: Bool) {
        let attrs =
            (try? FileManager.default.attributesOfItem(atPath: node.url.path))
            ?? [:]
        var md = node.metadata
        md.modifiedDate = attrs[.modificationDate] as? Date
        md.creationDate = attrs[.creationDate] as? Date
        md.fileSize = (attrs[.size] as? NSNumber)?.int64Value

        if shouldNotify {
            DispatchQueue.main.async {
                node.metadata = md
                self.changePublisher.send(
                    .metadataUpdated(nodeID: node.id, metadata: md)
                )
            }
        } else {
            DispatchQueue.main.async {
                node.metadata = md
            }
        }
    }

    private func mapRecursively(_ node: ProjectNode) {
        nodesByID[node.id] = node
        nodesByPath[normalized(node.url.path)] = node
        for child in node.children {
            mapRecursively(child)
        }
    }

    private func unmapRecursively(_ node: ProjectNode) {
        nodesByID.removeValue(forKey: node.id)
        nodesByPath.removeValue(forKey: normalized(node.url.path))
        for child in node.children {
            unmapRecursively(child)
        }
    }
}
