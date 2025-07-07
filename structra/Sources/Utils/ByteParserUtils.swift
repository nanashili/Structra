//
//  ByteParserUtils.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

enum ByteParserUtils {
    // Pre-allocated buffer for line processing to reduce allocations
    private static let lineBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(
        capacity: 8192
    )

    static func extractImports(from data: Data, keywords: [[UInt8]]) -> [String]
    {
        var results: [String] = []
        results.reserveCapacity(32)  // Pre-allocate for typical import count

        // Use optimized line iteration with early termination
        for line in data.optimizedLines {
            let trimmedLine = line.trimmingWhitespaceOptimized()

            // Early continue for empty lines
            guard !trimmedLine.isEmpty else { continue }

            for keyword in keywords {
                if trimmedLine.startsWithOptimized(keyword) {
                    let remainder = trimmedLine.dropFirst(keyword.count)
                    if let path = remainder.firstWordOptimized() {
                        let cleanPath = path.trimmingCharacters(
                            in: .punctuationCharacters
                        )
                        if !cleanPath.isEmpty {
                            results.append(cleanPath)
                        }
                    } else if let path = remainder.modulePathOptimized() {
                        if !path.isEmpty {
                            results.append(path)
                        }
                    }
                    break  // Found match, no need to check other keywords
                }
            }
        }
        return results
    }

    static func extractSymbols(from data: Data, keywords: [[UInt8]]) -> [String]
    {
        var results: [String] = []
        results.reserveCapacity(64)  // Pre-allocate for typical symbol count

        for line in data.optimizedLines {
            let trimmedLine = line.trimmingWhitespaceOptimized()

            // Early continue for empty lines
            guard !trimmedLine.isEmpty else { continue }

            for keyword in keywords {
                // Use optimized contains check
                if trimmedLine.containsOptimized(keyword) {
                    if let keywordRange = trimmedLine.firstRangeOptimized(
                        of: keyword
                    ) {
                        let remainder = trimmedLine[keywordRange.upperBound...]
                            .trimmingWhitespaceOptimized()
                        if let name = remainder.firstWordOptimized() {
                            let keywordString = String(
                                decoding: keyword,
                                as: UTF8.self
                            ).trimmingCharacters(in: .whitespaces)
                            results.append("\(keywordString) \(name)")
                            break
                        }
                    }
                }
            }
        }
        return results
    }
}
