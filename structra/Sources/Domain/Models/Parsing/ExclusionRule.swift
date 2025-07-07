//
//  ExclusionRule.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

public enum ExclusionRule {
    /// Excludes any directory with this name, anywhere in the project.
    /// Example: .name("node_modules")
    case name(String)

    /// Excludes a directory at a specific path relative to the project root.
    /// Example: .path("build/generated")
    case path(String)
}
