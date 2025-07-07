//
//  allows.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

// This struct allows for more flexible and powerful role detection.
public struct RoleHintRule {
    enum Target {
        case fileName  // e.g., "MyView.swift"
        case fileNameStem  // e.g., "MyView"
        case directoryPath  // e.g., "/views/"
    }
    enum MatchType {
        case exact
        case contains
        case suffix
    }

    let target: Target
    let matchType: MatchType
    let pattern: String
    let hint: String
    let score: Int  // Higher score means a more confident match
}
