//
//  StatusBarFloatingView.swift
//  structra
//
//  Created by Nanashi Li on 7/4/25.
//

import Combine
import SwiftUI

struct StatusBarFloatingView: View {
    @EnvironmentObject private var workspace: WorkspaceManager

    public enum DisplayState {
        case hidden
        case parsing
        case success
        case error(String)
    }

    @State private var displayState: DisplayState = .hidden
    @State private var autoHideTask: DispatchWorkItem?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if displayState != .hidden {
                contentView
                    .transition(
                        .opacity.combined(
                            with: .scale(scale: 0.9, anchor: .bottomTrailing)
                        )
                    )
            }

            if displayState == .hidden {
                showButton
                    .transition(.opacity)
            }
        }
        .padding([.bottom, .trailing], 15)
        .onChange(of: workspace.currentSession?.isParsing) { _, isParsing in
            handleParsingStateChange(isParsing: isParsing ?? false)
        }
        .onChange(of: workspace.currentSession?.parsingError) { _, error in
            if let error = error {
                updateState(to: .error(error))
            }
        }
    }

    // A computed property for the main content, keeping the body clean.
    @ViewBuilder
    private var contentView: some View {
        HStack(spacing: 10) {
            switch displayState {
            case .parsing:
                ProgressRingView(color: .secondary)
                    .frame(width: 15, height: 15)
                Text("Parsing Project...")
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Analysis Complete")
            case .error(let message):
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text(message)
                    .lineLimit(1)
            case .hidden:
                EmptyView()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            .bar,
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
    }

    private var showButton: some View {
        Button(action: {
            showCurrentStatus()
        }) {
            Image(systemName: "info.circle.fill")
                .font(.title2)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .buttonStyle(.plain)
    }

    private func showCurrentStatus() {
        // Check the real source of truth: the workspace session
        if let session = workspace.currentSession {
            if let error = session.parsingError {
                updateState(to: .error(error))
            } else if session.isParsing {
                updateState(to: .parsing)
            } else {
                // If no error and not parsing, it's a success
                updateState(to: .success)
            }
        } else {
            // If no project is open, "success" is a reasonable default state.
            updateState(to: .success)
        }
    }

    // MARK: - State Management Logic

    private func handleParsingStateChange(isParsing: Bool) {
        if isParsing {
            updateState(to: .parsing)
        } else {
            // If parsing just finished, show success (unless an error occurred)
            if case .error = displayState { return }
            updateState(to: .success)
        }
    }

    private func updateState(to newState: DisplayState) {
        // Always cancel any pending auto-hide task before changing state
        autoHideTask?.cancel()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            self.displayState = newState
        }

        // Schedule a new auto-hide task unless we are parsing
        if case .parsing = newState {
            // Don't auto-hide while parsing
        } else {
            scheduleAutoHide()
        }
    }

    private func scheduleAutoHide() {
        let task = DispatchWorkItem {
            hideWithAnimation()
        }
        self.autoHideTask = task
        // Hide after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: task)
    }

    private func hideWithAnimation() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            displayState = .hidden
        }
    }
}

extension StatusBarFloatingView.DisplayState: Equatable {
    static func == (
        lhs: StatusBarFloatingView.DisplayState,
        rhs: StatusBarFloatingView.DisplayState
    ) -> Bool {
        switch (lhs, rhs) {
        case (.hidden, .hidden): return true
        case (.parsing, .parsing): return true
        case (.success, .success): return true
        case (.error(let l), .error(let r)): return l == r
        default: return false
        }
    }
}
