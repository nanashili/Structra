//
//  SortCriterion.swift
//  structra
//
//  Created by Nanashi Li on 7/1/25.
//

/// The criteria by which children of a node can be sorted.
public enum SortCriterion {
    /// Sort by file/folder name, alphabetically.
    case name
    /// Sort by modification date, newest first.
    case dateModified
    /// Sort by file size, largest first.
    case size
    /// Sort by type, with folders appearing before files.
    case type
}

public enum SortDescriptor: Codable, Sendable {
    case name, dateModified, size, type
}

public enum SortDirection: Codable, Sendable {
    case ascending, descending
}
