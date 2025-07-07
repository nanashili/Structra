//
//  LanguageRegistry.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

/// A central registry that provides `LanguageProfile`.
public enum LanguageRegistry {
    private static let profiles: [Language: LanguageProfile] = [
        .swift: SwiftParser(),
        .objectiveC: CStyleParser(),
        .c: CStyleParser(),
        .cpp: CStyleParser(),
        .java: JavaFamilyParser(),
        .kotlin: KotlinParser(),
        .csharp: JavaFamilyParser(),
        .javascript: JavaScriptParser(),
        .typescript: JavaScriptParser(),
        .python: PythonParser(),
        .ruby: RubyParser(),
        .go: GoParser(),
        .rust: RustParser(),
        .php: PHPParser(),
        .dart: DartParser(),
        .lua: LuaParser(),
        .perl: PerlParser(),
        .elixir: ElixirParser(),
    ]

    public static func profile(for language: Language) -> LanguageProfile {
        return profiles[language, default: NoOpParser()]
    }
}
