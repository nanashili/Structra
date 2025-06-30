//
//  NodeMetadata.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/22/25.
//

import Foundation

/// Arbitrary metadata you can attach to any node (file or folder).
///
/// - Conforms to `Codable` for disk persistence (JSON, PLIST, etc.).
/// - Conforms to `Equatable` for easy diffing and change detection.
///
/// Extend with additional fields (permissions, owner, checksums) as needed.
public struct NodeMetadata: @preconcurrency Codable, Equatable {
    /// File size in bytes. `nil` for folders or if not yet loaded.
    public var fileSize: Int64?
    /// Creation timestamp. `nil` if unavailable.
    public var creationDate: Date?
    /// Last‐modified timestamp. Useful for UI badges or auto‐reload.
    public var modifiedDate: Date?
    /// File‐type or extension (e.g. "swift", "md"). `nil` if unknown.
    public var fileType: String?
    /// Is the file/folder read‐only? Defaults to `false`.
    public var isReadOnly: Bool
    /// User‐defined tags, for filtering or search. Defaults to empty.
    public var tags: [String]

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - fileSize: Size in bytes.
    ///   - creationDate: Date of creation.
    ///   - modifiedDate: Date of last modification.
    ///   - fileType: Extension or type identifier.
    ///   - isReadOnly: Read‐only flag.
    ///   - tags: Custom search tags.
    public init(
        fileSize: Int64?      = nil,
        creationDate: Date?   = nil,
        modifiedDate: Date?   = nil,
        fileType: String?     = nil,
        isReadOnly: Bool      = false,
        tags: [String]        = []
    ) {
        self.fileSize     = fileSize
        self.creationDate = creationDate
        self.modifiedDate = modifiedDate
        self.fileType     = fileType
        self.isReadOnly   = isReadOnly
        self.tags         = tags
    }
}
