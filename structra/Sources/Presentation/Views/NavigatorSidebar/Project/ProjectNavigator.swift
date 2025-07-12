//
//  ProjectNavigator.swift
//  structra
//
//  Created by Nanashi Li on 6/26/25.
//

import SwiftUI

/// # Project Navigator - Sidebar
///
/// A list that functions as a project navigator, showing collapsable folders
/// and files.
///
/// When selecting a file it will open in the editor.
///
struct ProjectNavigator: View {
    /// The view body.
    var body: some View {
        ProjectNavigatorView()
            .environmentObject(WorkspaceManager.shared)
    }
}
