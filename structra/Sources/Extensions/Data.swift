//
//  Data.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

extension Data {
    /// An iterator that reads lines from Data without converting the entire buffer to a String.
    struct LineIterator: Sequence, IteratorProtocol {
        private let data: Data
        private var currentOffset: Int = 0

        init(data: Data) { self.data = data }

        mutating func next() -> Data.SubSequence? {
            guard currentOffset < data.count else { return nil }

            let newlineByte: UInt8 = 10  // \n
            var lineEndOffset = currentOffset

            while lineEndOffset < data.count
                && data[lineEndOffset] != newlineByte
            {
                lineEndOffset += 1
            }

            let line = data[currentOffset..<lineEndOffset]
            currentOffset = lineEndOffset + 1
            return line
        }
    }

    var lines: LineIterator {
        LineIterator(data: self)
    }

    var optimizedLines: OptimizedLineSequence {
        OptimizedLineSequence(data: self)
    }
}

extension Data.SubSequence {
    func trimmingWhitespaceOptimized() -> Data.SubSequence {
        var start = startIndex
        var end = endIndex

        // Trim leading whitespace
        while start < end && isWhitespace(self[start]) {
            start = index(after: start)
        }

        // Trim trailing whitespace
        while end > start && isWhitespace(self[index(before: end)]) {
            end = index(before: end)
        }

        return self[start..<end]
    }

    func startsWithOptimized(_ prefix: [UInt8]) -> Bool {
        guard count >= prefix.count else { return false }

        for i in 0..<prefix.count {
            if self[index(startIndex, offsetBy: i)] != prefix[i] {
                return false
            }
        }
        return true
    }

    func containsOptimized(_ sequence: [UInt8]) -> Bool {
        guard count >= sequence.count else { return false }

        let searchLimit = count - sequence.count + 1
        for i in 0..<searchLimit {
            var match = true
            for j in 0..<sequence.count {
                if self[index(startIndex, offsetBy: i + j)] != sequence[j] {
                    match = false
                    break
                }
            }
            if match {
                return true
            }
        }
        return false
    }

    func firstRangeOptimized(of sequence: [UInt8]) -> Range<Index>? {
        guard count >= sequence.count else { return nil }

        let searchLimit = count - sequence.count + 1
        for i in 0..<searchLimit {
            var match = true
            for j in 0..<sequence.count {
                if self[index(startIndex, offsetBy: i + j)] != sequence[j] {
                    match = false
                    break
                }
            }
            if match {
                let start = index(startIndex, offsetBy: i)
                let end = index(start, offsetBy: sequence.count)
                return start..<end
            }
        }
        return nil
    }

    func firstWordOptimized() -> String? {
        let trimmed = trimmingWhitespaceOptimized()
        guard !trimmed.isEmpty else { return nil }

        var wordEnd = trimmed.startIndex
        while wordEnd < trimmed.endIndex && !isWhitespace(trimmed[wordEnd]) {
            wordEnd = trimmed.index(after: wordEnd)
        }

        let wordData = trimmed[trimmed.startIndex..<wordEnd]
        return String(decoding: wordData, as: UTF8.self)
    }

    func modulePathOptimized() -> String? {
        // Optimized module path extraction
        let trimmed = trimmingWhitespaceOptimized()
        guard !trimmed.isEmpty else { return nil }

        // Look for quoted strings or module identifiers
        if let first = trimmed.first {
            if first == 34 || first == 39 {  // " or '
                return extractQuotedString(from: trimmed)
            } else {
                return firstWordOptimized()
            }
        }

        return nil
    }

    private func extractQuotedString(from data: Data.SubSequence) -> String? {
        guard data.count >= 2 else { return nil }

        let quote = data[data.startIndex]
        var current = data.index(after: data.startIndex)

        while current < data.endIndex && data[current] != quote {
            current = data.index(after: current)
        }

        guard current < data.endIndex else { return nil }

        let contentStart = data.index(after: data.startIndex)
        let content = data[contentStart..<current]
        return String(decoding: content, as: UTF8.self)
    }

    private func isWhitespace(_ byte: UInt8) -> Bool {
        return byte == 32 || byte == 9 || byte == 10 || byte == 13  // space, tab, LF, CR
    }
}
