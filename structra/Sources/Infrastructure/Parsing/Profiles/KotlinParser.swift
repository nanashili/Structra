//
//  KotlinParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct KotlinParser: LanguageProfile {
    private static let importKeywords = [[UInt8]("import ".utf8)]
    private static let symbolKeywords: [[UInt8]] = [
        // Types
        [UInt8]("class ".utf8), [UInt8]("interface ".utf8),
        [UInt8]("object ".utf8),
        [UInt8]("data class ".utf8), [UInt8]("typealias ".utf8),
        [UInt8]("enum class ".utf8),
        // Functions & Properties
        [UInt8]("fun ".utf8), [UInt8]("val ".utf8), [UInt8]("var ".utf8),
        // Scopes & Initializers
        [UInt8]("init".utf8), [UInt8]("companion object".utf8),
    ].map { $0 }
    var pattern: LanguagePattern {
        LanguagePattern(
            language: "Kotlin",
            functionPattern:
                #"fun\s+(?:<[^>]+>\s+)?(\w+)\s*\(([^)]*)\)\s*(?::\s*([\w\<\>\[\]\?]+))?"#,
            parameterPattern: #"(\w+)\s*:\s*([\w\<\>\[\]\?]+)"#,
            returnTypePattern: #":\s*([\w\<\>\[\]\?]+)"#
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
