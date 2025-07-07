//
//  Array.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

// Extension for batching arrays
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
