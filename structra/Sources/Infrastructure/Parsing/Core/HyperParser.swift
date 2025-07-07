//
//  HyperParser.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation
import OSLog

public actor HyperParser {
    private let fileManager: FileManager
    private let logger = Logger(
        subsystem: "com.structra.workspace.parser",
        category: "HyperParser"
    )

    // Cache for language detection to avoid repeated string operations
    private let languageCache = NSCache<NSString, NSString>()

    // Batch size for controlled parallelism
    private let batchSize: Int

    public init(fileManager: FileManager = .default, batchSize: Int = 50) {
        self.fileManager = fileManager
        self.batchSize = batchSize
    }

    // MARK: - Updated `parse` method signature
    public func parse(
        projectURL: URL,
        excluding rules: [ExclusionRule] = []
    ) async throws -> ProjectGraph {
        logger.info("HYPER-PARSE starting at: \(projectURL.path)")
        let startTime = CFAbsoluteTimeGetCurrent()

        // Collect files with the new rule-based filtering
        let fileURLs = await self.collectFileURLsOptimized(
            at: projectURL,
            excluding: rules
        )

        let graphBuilder = GraphBuilderActor()
        let projectRootPath = projectURL.path

        // Process files in controlled batches to prevent CPU thrashing
        await withTaskGroup(of: Void.self) { group in
            for batch in fileURLs.chunked(into: batchSize) {
                group.addTask {
                    await self.processBatch(
                        batch,
                        projectRootPath: projectRootPath,
                        graphBuilder: graphBuilder
                    )
                }
            }
        }

        let finalGraph = await graphBuilder.getGraph()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logger.info(
            "HYPER-PARSE finished in \(String(format: "%.4f", duration)) seconds. Found \(finalGraph.files.count) files."
        )

        return finalGraph
    }

    private func processBatch(
        _ batch: [URL],
        projectRootPath: String,
        graphBuilder: GraphBuilderActor
    ) async {
        for fileURL in batch {
            if let node = await self.parseFileOptimized(
                at: fileURL,
                projectRootPath: projectRootPath
            ) {
                await graphBuilder.add(node: node)
            }
        }
    }

    private func parseFileOptimized(
        at fileURL: URL,
        projectRootPath: String
    ) async -> FileNode? {
        do {
            let resourceValues = try fileURL.resourceValues(forKeys: [
                .isRegularFileKey, .fileSizeKey,
            ])
            guard resourceValues.isRegularFile == true else { return nil }

            let language = await self.languageOptimized(for: fileURL)
            guard language != .unknown else { return nil }

            if let fileSize = resourceValues.fileSize, fileSize > 10_000_000 {
                logger.warning(
                    "Skipping large file: \(fileURL.path) (\(fileSize) bytes)"
                )
                return nil
            }

            let data: Data
            if let fileSize = resourceValues.fileSize, fileSize > 1_000_000 {
                data = try await self.readFileStreaming(fileURL)
            } else {
                data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            }

            let contentHash = String(data.hashValue)

            let relativePath = self.relativePath(
                from: fileURL.path,
                projectRoot: projectRootPath
            )

            async let imports = self.extractImportsAsync(
                from: data,
                language: language
            )
            async let symbols = self.extractSymbolsAsync(
                from: data,
                language: language
            )

            let (extractedImports, extractedSymbols) = await (imports, symbols)

            return FileNode(
                path: relativePath,
                language: language,
                contentHash: contentHash,
                declaredSymbols: extractedSymbols,
                imports: extractedImports,
                roleHints: self.roleHintsOptimized(for: relativePath)
            )
        } catch {
            logger.error(
                "Failed to parse file \(fileURL.path): \(error.localizedDescription)"
            )
            return nil
        }
    }

    private func readFileStreaming(_ fileURL: URL) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                do {
                    let data = try Data(contentsOf: fileURL)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func extractImportsAsync(from data: Data, language: Language) async
        -> [String]
    {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let profile = LanguageRegistry.profile(for: language)
                let imports = profile.extractImports(from: data)
                continuation.resume(returning: imports)
            }
        }
    }

    private func extractSymbolsAsync(from data: Data, language: Language) async
        -> [String]
    {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let profile = LanguageRegistry.profile(for: language)
                let symbols = profile.extractSymbols(from: data)
                continuation.resume(returning: symbols)
            }
        }
    }

    // MARK: - Heavily updated `collectFileURLsOptimized`
    private func collectFileURLsOptimized(
        at projectURL: URL,
        excluding rules: [ExclusionRule]
    ) async -> [URL] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                var urls: [URL] = []
                let resourceKeys: [URLResourceKey] = [
                    .isRegularFileKey, .isDirectoryKey, .fileSizeKey,
                ]

                // Separate rules into sets for efficient O(1) lookups
                var excludedNames = Set<String>()
                var excludedPaths = Set<String>()
                for rule in rules {
                    switch rule {
                    case .name(let name):
                        excludedNames.insert(name.lowercased())
                    case .path(let path):
                        // Normalize path format for comparison
                        let normalizedPath =
                            path.hasSuffix("/") ? String(path.dropLast()) : path
                        excludedPaths.insert(normalizedPath.lowercased())
                    }
                }

                let enumerator = self.fileManager.enumerator(
                    at: projectURL,
                    includingPropertiesForKeys: resourceKeys,
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                )

                guard let enumerator = enumerator else {
                    continuation.resume(returning: [])
                    return
                }

                let projectRootPath = projectURL.path

                for case let url as URL in enumerator {
                    do {
                        let resourceValues = try url.resourceValues(
                            forKeys: Set(resourceKeys)
                        )

                        if resourceValues.isDirectory == true {
                            var shouldSkip = false
                            let dirNameLowercased = url.lastPathComponent
                                .lowercased()

                            // Check for name-based exclusion
                            if excludedNames.contains(dirNameLowercased) {
                                shouldSkip = true
                            }

                            // Check for path-based exclusion
                            if !shouldSkip {
                                let relativeDirPath = self.relativePath(
                                    from: url.path,
                                    projectRoot: projectRootPath
                                )
                                if excludedPaths.contains(
                                    relativeDirPath.lowercased()
                                ) {
                                    shouldSkip = true
                                }
                            }

                            if shouldSkip {
                                enumerator.skipDescendants()
                                continue
                            }
                        }

                        if resourceValues.isRegularFile == true {
                            let ext = url.pathExtension.lowercased()
                            if self.isKnownExtension(ext) {
                                urls.append(url)
                            }
                        }
                    } catch {
                        continue
                    }
                }

                continuation.resume(returning: urls)
            }
        }
    }

    private func isKnownExtension(_ ext: String) -> Bool {
        // Pre-computed set of known extensions for O(1) lookup
        let knownExtensions: Set<String> = [
            "swift", "m", "h", "c", "cpp", "hpp", "cc", "hh", "cxx",
            "js", "mjs", "cjs", "ts", "tsx", "html", "htm", "css",
            "scss", "sass", "less", "py", "pyw", "rb", "go", "java",
            "kt", "kts", "cs", "fs", "fsi", "php", "phtml", "rs",
            "pl", "pm", "lua", "dart", "ex", "exs", "erl", "hrl",
            "json", "yml", "yaml", "xml", "plist", "storyboard", "xib",
            "csproj", "toml", "md", "markdown", "sql", "sh", "bash",
            "zsh", "ps1", "dockerfile",
        ]
        return knownExtensions.contains(ext)
    }

    private func languageOptimized(for fileURL: URL) async -> Language {
        let ext = fileURL.pathExtension.lowercased()
        let cacheKey = NSString(string: ext)

        if let cachedLanguageString = languageCache.object(forKey: cacheKey) {
            return Language(rawValue: cachedLanguageString as String)
                ?? .unknown
        }

        let language = self.languageFromExtension(ext)
        let languageString = NSString(string: language.rawValue)
        languageCache.setObject(languageString, forKey: cacheKey)
        return language
    }

    private func languageFromExtension(_ ext: String) -> Language {
        switch ext {
        case "swift": return .swift
        case "m", "h": return .objectiveC
        case "c": return .c
        case "cpp", "hpp", "cc", "hh", "cxx": return .cpp
        case "js", "mjs", "cjs": return .javascript
        case "ts", "tsx": return .typescript
        case "html", "htm": return .html
        case "css": return .css
        case "scss", "sass": return .scss
        case "less": return .less
        case "py", "pyw": return .python
        case "rb": return .ruby
        case "go": return .go
        case "java": return .java
        case "kt", "kts": return .kotlin
        case "cs": return .csharp
        case "fs", "fsi": return .fsharp
        case "php", "phtml": return .php
        case "rs": return .rust
        case "pl", "pm": return .perl
        case "lua": return .lua
        case "dart": return .dart
        case "ex", "exs": return .elixir
        case "erl", "hrl": return .erlang
        case "json": return .json
        case "yml", "yaml": return .yaml
        case "xml", "plist", "storyboard", "xib", "csproj": return .xml
        case "toml": return .toml
        case "md", "markdown": return .markdown
        case "sql": return .sql
        case "sh", "bash", "zsh": return .shell
        case "ps1": return .powershell
        case "dockerfile", "": return .dockerfile
        default: return .unknown
        }
    }

    private func relativePath(from fullPath: String, projectRoot: String)
        -> String
    {
        if fullPath.hasPrefix(projectRoot) {
            let startIndex = fullPath.index(
                fullPath.startIndex,
                offsetBy: projectRoot.count
            )
            // Also remove leading slash for clean relative paths
            var path = String(fullPath[startIndex...])
            if path.hasPrefix("/") {
                path = String(path.dropFirst())
            }
            return path
        }
        return fullPath
    }

    private func roleHintsOptimized(for path: String) -> [String] {
        var hintScores: [String: Int] = [:]

        let url = URL(fileURLWithPath: path)
        let fileName = url.lastPathComponent
        let fileNameStem = url.deletingPathExtension().lastPathComponent
        let directoryPath = "/" + url.deletingLastPathComponent().path + "/"

        // Assuming `roleHintRules` is defined elsewhere
        // for rule in roleHintRules { ... }

        let sortedHints = hintScores.sorted { $0.value > $1.value }
        return sortedHints.map { $0.key }
    }
}
