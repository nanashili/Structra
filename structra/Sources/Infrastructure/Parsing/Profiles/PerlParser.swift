//
//  PerlParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct PerlParser: LanguageProfile {
    private static let importKeywords = [
        [UInt8]("use ".utf8), [UInt8]("require ".utf8), [UInt8]("no ".utf8),
    ]
    private static let symbolKeywords: [[UInt8]] = [
        [UInt8]("sub ".utf8), [UInt8]("package ".utf8), [UInt8]("my ".utf8),
        [UInt8]("our ".utf8), [UInt8]("local ".utf8),
    ].map { $0 }
    var pattern: LanguagePattern {
        LanguagePattern(
            language: "Perl",
            functionPattern: #"sub\s+([\w:]+)"#,
            parameterPattern: "",
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
