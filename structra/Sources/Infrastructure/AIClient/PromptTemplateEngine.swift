//
//  PromptTemplateEngine.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import Foundation

/// Loads and renders prompt templates from the file system or app bundle.
public struct PromptTemplateEngine {

    private let templateDirectory: URL?

    /// Initializes with an optional directory. If nil, it searches the main bundle.
    public init(templateDirectory: URL? = nil) {
        self.templateDirectory = templateDirectory
    }

    /// Asynchronously loads a template file and substitutes placeholders.
    /// - Parameters:
    ///   - key: The name of the template file (e.g., "swift-file-doc.md").
    ///   - data: The dictionary used to replace placeholders like `{{key}}`.
    /// - Returns: The rendered string content.
    func render(key: String, with data: [String: Any]) async throws -> String {
        guard let templateUrl = findTemplateUrl(forKey: key) else {
            throw AIClientError.templateNotFound(key)
        }

        var templateContent = try String(
            contentsOf: templateUrl,
            encoding: .utf8
        )

        for (placeholder, value) in data {
            // Simple string replacement. For more complex logic, a dedicated
            // template engine library (like Stencil) could be used.
            let stringValue = String(describing: value)
            templateContent = templateContent.replacingOccurrences(
                of: "{{\(placeholder)}}",
                with: stringValue
            )
        }

        // Optional: Add a check for any remaining {{...}} placeholders
        if templateContent.contains("{{") {
            print(
                "Warning: Potential un-filled placeholders remain in template '\(key)'."
            )
        }

        return templateContent
    }

    private func findTemplateUrl(forKey key: String) -> URL? {
        if let directory = templateDirectory {
            // Search in the provided directory
            return directory.appendingPathComponent(key)
        } else {
            // Fallback to the main app bundle
            let fileName = (key as NSString).deletingPathExtension
            let fileExtension = (key as NSString).pathExtension
            return Bundle.main.url(
                forResource: fileName,
                withExtension: fileExtension
            )
        }
    }
}
