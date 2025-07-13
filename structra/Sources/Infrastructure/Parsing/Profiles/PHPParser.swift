//
//  PHPParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct PHPParser: LanguageProfile {
    private static let importKeywords = [
        [UInt8]("use ".utf8), [UInt8]("require ".utf8),
        [UInt8]("include ".utf8), [UInt8]("require_once ".utf8),
        [UInt8]("include_once ".utf8),
    ]
    private static let symbolKeywords: [[UInt8]] = [
        [UInt8]("function ".utf8), [UInt8]("class ".utf8),
        [UInt8]("interface ".utf8),
        [UInt8]("trait ".utf8), [UInt8]("enum ".utf8),
        [UInt8]("namespace ".utf8),
        [UInt8]("const ".utf8), [UInt8]("abstract class ".utf8),
        [UInt8]("final class ".utf8),
    ].map { $0 }
    var pattern: LanguagePattern {
        LanguagePattern(
            language: "PHP",
            functionPattern:
                #"(?:public|protected|private|static)?\s*function\s+&?(\w+)\s*\(([^)]*)\)(?:\s*:\s*([\w\|\\?]+))?"#,
            parameterPattern: #"(?:([\w\\]+)\s+)?(&?\$(\w+))"#,
            returnTypePattern: #":\s*([\w\|\\?]+)"#
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
