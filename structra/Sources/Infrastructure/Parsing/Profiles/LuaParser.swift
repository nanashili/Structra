//
//  LuaParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct LuaParser: LanguageProfile {
    private static let importKeywords = [[UInt8]("require ".utf8)]
    private static let symbolKeywords: [[UInt8]] = [
        [UInt8]("function ".utf8), [UInt8]("local function ".utf8),
        [UInt8]("local ".utf8),
    ].map { $0 }
    var pattern: LanguagePattern {
        LanguagePattern(
            language: "Lua",
            functionPattern: #"function\s+([\w\.:]+)\s*\(([^)]*)\)"#,
            parameterPattern: #"(\w+)"#,
            returnTypePattern: ""
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
