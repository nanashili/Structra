//
//  OptimizedLineSequence.swift
//  structra
//
//  Created by Nanashi Li on 7/3/25.
//

import Foundation

struct OptimizedLineSequence: Sequence {
    let data: Data

    func makeIterator() -> OptimizedLineIterator {
        OptimizedLineIterator(data: data)
    }
}
