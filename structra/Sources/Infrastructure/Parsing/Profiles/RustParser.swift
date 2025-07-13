//
//  RustParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct RustParser: LanguageProfile {
    private static let importKeywords = [
        [UInt8]("use ".utf8), [UInt8]("extern crate ".utf8),
    ]
    private static let symbolKeywords: [[UInt8]] = [
        // Definitions
        [UInt8]("fn ".utf8), [UInt8]("struct ".utf8), [UInt8]("enum ".utf8),
        [UInt8]("union ".utf8), [UInt8]("trait ".utf8), [UInt8]("impl".utf8),
        [UInt8]("mod ".utf8), [UInt8]("type ".utf8),
        // Variables & Constants
        [UInt8]("const ".utf8), [UInt8]("static ".utf8),
        // Macros
        [UInt8]("macro_rules!".utf8),
        // Visibility
        [UInt8]("pub fn ".utf8), [UInt8]("pub struct ".utf8),
        [UInt8]("pub enum ".utf8),
        [UInt8]("pub const ".utf8), [UInt8]("pub static ".utf8),
        [UInt8]("pub mod ".utf8),
    ].map { $0 }
    var pattern: LanguagePattern {
        LanguagePattern(
            language: "Rust",
            functionPattern:
                #"fn\s+(\w+)(?:<[^>]*>)?\s*\(([^)]*)\)(?:\s*->\s*([^{]+))?"#,
            parameterPattern: #"(\w+)\s*:\s*([^,)]+)"#,
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
