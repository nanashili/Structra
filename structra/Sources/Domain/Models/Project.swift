//
//  Project.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/18/25.
//

import Foundation

struct Project: Identifiable, Hashable {
    let id: UUID
    let name: String
    let url: URL
}
