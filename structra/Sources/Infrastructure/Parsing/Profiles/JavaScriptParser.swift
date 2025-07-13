//
//  JavaScriptParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct JavaScriptParser: LanguageProfile {
    private static let importKeywords = [
        [UInt8]("import ".utf8), [UInt8]("require(".utf8),
        [UInt8]("export ".utf8),
    ]
    private static let symbolKeywords: [[UInt8]] = [
        // Declarations
        [UInt8]("function ".utf8), [UInt8]("class ".utf8),
        [UInt8]("const ".utf8),
        [UInt8]("let ".utf8), [UInt8]("var ".utf8),
        // Async
        [UInt8]("async function ".utf8),
        // TypeScript Specific
        [UInt8]("interface ".utf8), [UInt8]("type ".utf8),
        [UInt8]("enum ".utf8),
        [UInt8]("namespace ".utf8), [UInt8]("abstract class ".utf8),
        [UInt8]("module ".utf8),
    ].map { $0 }
    var pattern: LanguagePattern {
        LanguagePattern(
            language: "JavaScript/TypeScript",
            functionPattern:
                #"(?:function\s+)?(\w+)\s*(?:=\s*)?\(([^)]*)\)(?:\s*:\s*([\w<>\|\[\]]+))?"#,
            parameterPattern: #"(\w+)(?:\s*:\s*([\w<>\|\[\]]+))?"#,
            returnTypePattern: #":\s*([\w<>\|\[\]]+)"#
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
