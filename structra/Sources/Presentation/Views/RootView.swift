//
//  RootView.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/18/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var projectVM: ProjectListViewModel
    @State private var window: NSWindow?
    @State private var didOpenEditor = false

    var body: some View {
        Group {
            if projectVM.currentProject != nil {
                WorkspaceView()
            } else {
                WelcomeView()
            }
        }
        .frame(minWidth: 800, minHeight: 460)
        .background(
            WindowAccessor { win in
                if self.window == nil {
                    self.window = win
                }
                applyWindowStyle(
                    to: win,
                    isWelcome: projectVM.currentProject == nil
                )
            }
        )
        .onChange(of: projectVM.currentProject) { oldProject, newProject in
            guard let win = window else { return }
            applyWindowStyle(to: win, isWelcome: newProject == nil)

            // Open the editor window if a project is set and we haven't already
            if newProject != nil && !didOpenEditor {
                WorkspaceSession(projectURL: projectVM.currentProject!.url).showWindow()
                didOpenEditor = true
            }
        }
    }

    private func applyWindowStyle(to window: NSWindow, isWelcome: Bool) {
        window.titlebarAppearsTransparent = isWelcome
        window.isMovableByWindowBackground = isWelcome

        if isWelcome {
            window.styleMask.remove(.titled)
            window.styleMask.remove(.fullSizeContentView)
        } else {
            window.styleMask.insert(.titled)
            window.styleMask.insert(.fullSizeContentView)
        }

        [.closeButton, .miniaturizeButton, .zoomButton].forEach { b in
            window.standardWindowButton(b)?.isHidden = isWelcome
        }

        window.backingType = .buffered
    }
}
