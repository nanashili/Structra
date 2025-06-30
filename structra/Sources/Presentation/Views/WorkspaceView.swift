//
//  WorkspaceView.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/26/25.
//

import AppKit
import Combine
import OSLog
import SwiftUI

/// Workspace view.
struct WorkspaceView: View {
    /// The height of the tab bar.
    let tabBarHeight = 28.0

    /// Path of the workspace.
    private var path: String = ""

    /// The cancelables.
    @State
    var cancelables: Set<AnyCancellable> = .init()

    /// The alert state.
    @State
    private var showingAlert = false

    /// The alert title.
    @State
    private var alertTitle = ""

    /// The alert message.
    @State
    private var alertMsg = ""

    /// The inspector state.
    @State
    var showInspector = true

    /// The fullscreen state of the NSWindow.
    /// This will be passed into all child views as an environment variable.
    @State
    var isFullscreen = false

    /// Enter fullscreen observer.
    @State
    private var enterFullscreenObserver: Any?

    /// Leave fullscreen observer.
    @State
    private var leaveFullscreenObserver: Any?

    /// The sheet state.
    @State
    var sheetIsOpened = false

    /// Logger
    let logger = Logger(
        subsystem: "com.auroraeditor",
        category: "Workspace View"
    )

    /// The view body.
    var body: some View {
        VStack {
            Text("Test")
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct WorkspaceView_Previews: PreviewProvider {
    static var previews: some View {
        WorkspaceView()
    }
}
