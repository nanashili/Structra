//
//  PythonParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct PythonParser: LanguageProfile {
    private static let importKeywords = [
        [UInt8]("import ".utf8), [UInt8]("from ".utf8),
    ]
    private static let symbolKeywords: [[UInt8]] = [
        [UInt8]("class ".utf8), [UInt8]("def ".utf8),
        [UInt8]("async def ".utf8),
    ].map { $0 }
    var pattern: LanguagePattern {
        LanguagePattern(
            language: "Python",
            functionPattern: #"def\s+(\w+)\s*\(([^)]*)\)(?:\s*->\s*([^:]+))?:"#,
            parameterPattern: #"(\w+)(?:\s*:\s*([\w\[\], \.]+))?"#,
            returnTypePattern: #"->\s*([^:]+)"#
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
