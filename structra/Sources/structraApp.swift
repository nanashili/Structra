//
//  structraApp.swift
//  structra
//
//  Created by Nanashi Li on 6/14/25.
//

import SwiftUI

@main
struct structraApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var workspaceManager = WorkspaceManager.shared
    @StateObject private var projectViewModel: ProjectListViewModel

    init() {
        let manager = WorkspaceManager.shared
        _projectViewModel = StateObject(wrappedValue: ProjectListViewModel(
            projectService: ProjectService(),
            workspaceManager: manager
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(projectViewModel)
                .environmentObject(workspaceManager)
        }
    }
}
