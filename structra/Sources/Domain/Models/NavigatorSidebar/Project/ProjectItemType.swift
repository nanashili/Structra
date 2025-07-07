//
//  ProjectItemType.swift
//  structra
//
//  Created by Nanashi Li on 6/22/25.
//

import Foundation

/// Distinguishes between a folder or file node, with optional custom icon names.
///
/// - `folder(customIconName:)`
/// - `file(customIconName:)`
///
/// Conforms to `Codable` so that the tree can be serialized/deserialized.
public enum ProjectItemType: Codable, Equatable {
    /// A directory node.
    case folder(customIconName: String?)
    /// A file node.
    case file(customIconName: String?)

    private enum CodingKeys: String, CodingKey {
        case kind, icon
    }
    private enum Kind: String, Codable { case folder, file }

    /// Decode from JSON/PLIST.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(Kind.self, forKey: .kind)
        let icon = try c.decodeIfPresent(String.self, forKey: .icon)
        switch kind {
        case .folder: self = .folder(customIconName: icon)
        case .file: self = .file(customIconName: icon)
        }
    }

    /// Encode to JSON/PLIST.
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .folder(let icon):
            try c.encode(Kind.folder, forKey: .kind)
            try c.encode(icon, forKey: .icon)
        case .file(let icon):
            try c.encode(Kind.file, forKey: .kind)
            try c.encode(icon, forKey: .icon)
        }
    }

    /// The SF Symbol or asset name to display in the UI.
    public var iconName: String {
        if let custom = customIconName, !custom.isEmpty {
            return custom
        }
        switch self {
        case .folder: return "folder"
        case .file: return "doc.text"
        }
    }

    /// Underlying custom icon name, if provided.
    public var customIconName: String? {
        switch self {
        case .folder(let x), .file(let x):
            return x
        }
    }

    /// Returns `true` for `.folder`, `false` for `.file`.
    nonisolated public var isFolder: Bool {
        switch self {
        case .folder: return true
        case .file: return false
        }
    }
}
