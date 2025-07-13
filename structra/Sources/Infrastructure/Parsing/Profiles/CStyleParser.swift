//
//  CStyleParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct CStyleParser: LanguageProfile {
    private static let importKeywords = [
        [UInt8]("#import ".utf8), [UInt8]("#include ".utf8),
        [UInt8]("#define ".utf8),
    ]
    private static let symbolKeywords: [[UInt8]] = [
        // C/C++ Types
        [UInt8]("class ".utf8), [UInt8]("struct ".utf8), [UInt8]("enum ".utf8),
        [UInt8]("union ".utf8), [UInt8]("typedef ".utf8),
        [UInt8]("namespace ".utf8),
        // C++ Templates
        [UInt8]("template<".utf8),
        // Objective-C Types
        [UInt8]("@interface ".utf8), [UInt8]("@implementation ".utf8),
        [UInt8]("@protocol ".utf8), [UInt8]("@property ".utf8),
        // Variables & Functions
        [UInt8]("extern ".utf8),
    ].map { $0 }
    var pattern: LanguagePattern {
        LanguagePattern(
            language: "C-Style",
            functionPattern:
                #"([a-zA-Z_][a-zA-Z0-9_*\s]+?)\s+([a-zA-Z_][a-zA-Z0-9_]+)\s*\(([^)]*)\)\s*\{"#,
            parameterPattern:
                #"([a-zA-Z_][a-zA-Z0-9_*\s]+)\s+([a-zA-Z_][a-zA-Z0-9_]+)"#,
            returnTypePattern: #"^([a-zA-Z_][a-zA-Z0-9_*\s]+?)\s+"#
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
