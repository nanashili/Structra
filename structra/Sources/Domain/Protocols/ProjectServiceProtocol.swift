//
//  ProjectServiceProtocol.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/18/25.
//

import Foundation

protocol ProjectServiceProtocol {
    /// Open a project at the given folder URL and return its metadata.
    func openProject(at url: URL) async throws -> Project
}
