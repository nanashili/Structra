//
//  WorkspaceView.swift
//  structra
//
//  Created by Nanashi Li on 6/26/25.
//

import AppKit
import Combine
import OSLog
import SwiftUI

/// Workspace view.
struct WorkspaceView: View {

    @ObservedObject var session: WorkspaceSession

    @EnvironmentObject private var workspace: WorkspaceManager

    var body: some View {
        ZStack {
            VStack {
                // The logic now directly checks the session's property.
                // When session.selectedNodeID changes, this view will now be notified.
                if session.selectedNodeID == nil {
                    // You can make this view more informative.
                    VStack(spacing: 10) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No File Selected")
                            .font(.title)
                        Text(
                            "Select a file from the navigator to view its content or generate documentation."
                        )
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                    }
                } else {
                    StreamingTextView(
                        workspaceManager: workspace
                    )
                }
            }

            // Your status bar can remain as is.
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    StatusBarFloatingView()
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
