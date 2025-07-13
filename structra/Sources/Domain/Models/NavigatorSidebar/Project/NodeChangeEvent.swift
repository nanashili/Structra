//
//  NodeChangeEvent.swift
//  structra
//
//  Created by Nanashi Li on 6/22/25.
//

import Foundation

/// Describes incremental changes in the tree.
/// UI layers (SwiftUI/AppKit) can subscribe to this and apply animations.
public enum NodeChangeEvent {
    case added(node: ProjectNode, parentID: UUID?)
    case removed(nodeID: UUID, parentID: UUID?, fromIndex: Int)
    case moved(
        nodeID: UUID,
        fromParentID: UUID?,
        toParentID: UUID?,
        fromIndex: Int,
        toIndex: Int
    )
    case renamed(nodeID: UUID, oldName: String, newName: String)
    case metadataUpdated(nodeID: UUID, metadata: NodeMetadata)
    case reloaded(parentID: UUID?)
}
