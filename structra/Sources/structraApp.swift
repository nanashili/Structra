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

    // MARK: - State Management
    @StateObject private var workspaceManager = WorkspaceManager.shared
    @StateObject private var projectViewModel: ProjectListViewModel

    @AppStorage("hasCompletedWalkthrough") private var hasCompletedWalkthrough:
        Bool = false

    init() {
        let manager = WorkspaceManager.shared
        _projectViewModel = StateObject(
            wrappedValue: ProjectListViewModel(
                projectService: ProjectService(),
                workspaceManager: manager
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedWalkthrough {
                RootView()
                    .environmentObject(projectViewModel)
                    .environmentObject(workspaceManager)
            } else {
                WalkthroughView(
                    hasCompletedWalkthrough: $hasCompletedWalkthrough
                )
            }
        }
        .commands {
            #if DEBUG
                CommandMenu("Debug") {
                    Button("Reset Walkthrough") {
                        hasCompletedWalkthrough = false
                    }
                    .keyboardShortcut("R", modifiers: [.command, .shift])
                }
            #endif
        }
    }
}
