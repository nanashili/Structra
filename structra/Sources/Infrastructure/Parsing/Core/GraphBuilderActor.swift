//
//  to.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

/// A helper actor to build the graph concurrently and safely.
public actor GraphBuilderActor {
    private var graph = ProjectGraph()

    func add(node: FileNode) {
        graph.files.append(node)
    }

    func getGraph() -> ProjectGraph {
        return graph
    }
}
