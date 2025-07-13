//
//  Language.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

/// An exhaustive enumeration of supported programming languages.
public enum Language: String, Codable, Hashable, CaseIterable {
    // Apple Ecosystem
    case swift, objectiveC

    // Web Frontend
    case javascript, typescript, html, css, scss, less

    // Web Backend & General Purpose
    case python, ruby, go, java, kotlin, csharp, fsharp, php, rust, perl, lua,
        dart, elixir, erlang

    // C-Family
    case c, cpp

    // Data & Markup
    case json, yaml, xml, toml, markdown, sql

    // Shell & DevOps
    case shell, powershell, dockerfile

    // Unknown
    case unknown

    init?(url: URL) {
        self.init(rawValue: url.pathExtension.lowercased())
    }
}
