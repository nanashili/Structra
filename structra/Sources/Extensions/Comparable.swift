//
//  Comparable.swift
//  structra
//
//  Created by Nanashi Li on 7/6/25.
//

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
