//
//  SwiftParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct SwiftParser: LanguageProfile {
    private static let importKeywords = [[UInt8]("import ".utf8)]
    private static let symbolKeywords: [[UInt8]] = [
        // Types
        [UInt8]("class ".utf8), [UInt8]("struct ".utf8), [UInt8]("enum ".utf8),
        [UInt8]("protocol ".utf8), [UInt8]("actor ".utf8),
        [UInt8]("typealias ".utf8),
        [UInt8]("associatedtype ".utf8),
        // Functions & Initializers
        [UInt8]("func ".utf8), [UInt8]("init".utf8), [UInt8]("deinit".utf8),
        [UInt8]("subscript ".utf8), [UInt8]("operator ".utf8),
        // Properties
        [UInt8]("var ".utf8), [UInt8]("let ".utf8),
        // Scopes
        [UInt8]("extension ".utf8),
    ].map { $0 }
    var pattern: LanguagePattern {
        LanguagePattern(
            language: "Swift",
            functionPattern:
                #"(?:func)\s+([a-zA-Z0-9_]+)(?:<.*?>)?\s*\((.*?)\)(?:\s*async)?(?:\s*throws)?(?:\s*->\s*([^{]+))?"#,
            parameterPattern: #"(?:(\w+)\s+)?(\w+)\s*:\s*([^,)]+)"#,
            returnTypePattern: #"->\s*([^{]+)"#
        )
    }
    func extractImports(from data: Data) -> [String] {
        ByteParserUtils.extractImports(
            from: data,
            keywords: Self.importKeywords
        )
    }
    func extractSymbols(from data: Data) -> [String] {
        ByteParserUtils.extractSymbols(
            from: data,
            keywords: Self.symbolKeywords
        )
    }
}
