//
//  OptimizedLineIterator.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct OptimizedLineIterator: IteratorProtocol {
    private let data: Data
    private var position: Int = 0
    private let newline: UInt8 = 10  // ASCII newline

    init(data: Data) {
        self.data = data
    }

    mutating func next() -> Data.SubSequence? {
        guard position < data.count else { return nil }

        let startPosition = position

        // Find next newline using optimized search
        while position < data.count && data[position] != newline {
            position += 1
        }

        let line = data[startPosition..<position]

        // Skip the newline character
        if position < data.count {
            position += 1
        }

        return line
    }
}
