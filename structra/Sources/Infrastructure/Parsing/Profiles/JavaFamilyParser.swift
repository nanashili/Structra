//
//  JavaFamilyParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct JavaFamilyParser: LanguageProfile {
    private static let importKeywords = [
        [UInt8]("import ".utf8), [UInt8]("using ".utf8),
    ]
    private static let symbolKeywords: [[UInt8]] = [
        // Java/C# Types
        [UInt8]("class ".utf8), [UInt8]("interface ".utf8),
        [UInt8]("enum ".utf8),
        // Java Specific
        [UInt8]("record ".utf8),
        // C# Specific
        [UInt8]("struct ".utf8), [UInt8]("delegate ".utf8),
        [UInt8]("event ".utf8),
        [UInt8]("namespace ".utf8),
        // Modifiers that often start a declaration
        [UInt8]("public ".utf8), [UInt8]("private ".utf8),
        [UInt8]("protected ".utf8),
        [UInt8]("static ".utf8), [UInt8]("final ".utf8),
        [UInt8]("abstract ".utf8),
        [UInt8]("sealed ".utf8), [UInt8]("virtual ".utf8),
        [UInt8]("override ".utf8),
        [UInt8]("const ".utf8), [UInt8]("readonly ".utf8),
    ].map { $0 }
    var pattern: LanguagePattern {
        LanguagePattern(
            language: "Java/C#",
            functionPattern:
                #"(?:public|protected|private|internal)?\s*(?:static|final)?\s*([\w<>\[\]]+)\s+(\w+)\s*(?:<[^>]+>)?\s*\(([^)]*)\)"#,
            parameterPattern: #"([\w<>\[\]]+)\s+(\w+)"#,
            returnTypePattern: #"\s*([\w<>\[\]]+)\s+\w+\s*\("#
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
