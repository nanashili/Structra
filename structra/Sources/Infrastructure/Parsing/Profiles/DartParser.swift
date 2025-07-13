//
//  DartParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct DartParser: LanguageProfile {
    private static let importKeywords = [
        [UInt8]("import ".utf8), [UInt8]("export ".utf8), [UInt8]("part ".utf8),
    ]
    private static let symbolKeywords: [[UInt8]] = [
        [UInt8]("class ".utf8), [UInt8]("mixin ".utf8), [UInt8]("enum ".utf8),
        [UInt8]("extension ".utf8), [UInt8]("typedef ".utf8),
        [UInt8]("const ".utf8),
        [UInt8]("final ".utf8), [UInt8]("var ".utf8), [UInt8]("late ".utf8),
        [UInt8]("abstract ".utf8), [UInt8]("external ".utf8),
    ].map { $0 }
    var pattern: LanguagePattern {
        LanguagePattern(
            language: "Dart",
            functionPattern: #"([\w\<\>\[\]\?]+)?\s*(\w+)\s*\(([^)]*)\)"#,
            parameterPattern: #"([\w\<\>\[\]\?]+)\s+(\w+)"#,
            returnTypePattern: #"^([\w\<\>\[\]\?]+)\s+"#
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
