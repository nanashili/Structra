//
//  RootView.swift
//  structra
//
//  Created by Nanashi Li on 6/18/25.
//

import Catalyst
import SwiftUI

struct RootView: View {
    @EnvironmentObject var projectVM: ProjectListViewModel
    @State private var window: NSWindow?

    var body: some View {
        Group {
            if projectVM.currentProject == nil {
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
