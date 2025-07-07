//
//  StreamingTextView.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import SwiftUI

struct StreamingTextView: View {

    /// The ViewModel that drives this specific view's state. It's now initialized
    /// with a dependency passed from the parent view.
    @StateObject private var viewModel: AIGenerationViewModel

    /// The initializer now explicitly requires a WorkspaceManager.
    init(workspaceManager: WorkspaceManager) {
        _viewModel = StateObject(
            wrappedValue: AIGenerationViewModel(
                workspaceManager: workspaceManager
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(headerTitle)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)
                .truncationMode(.middle)

            TextEditor(text: $viewModel.displayText)
                .font(.body)
                .fontDesign(.monospaced)
                .scrollContentBackground(.hidden)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )

            HStack {
                Button(action: {
                    // Access the workspace through the viewModel
                    if let selectedNode = viewModel.workspaceManager
                        .currentSession?.selectedNode
                    {
                        viewModel.generateDocumentation(for: selectedNode)
                    }
                }) {
                    Text(
                        viewModel.isGenerating
                            ? "Generating..." : "Generate Documentation"
                    )
                }
                .disabled(
                    // Access the workspace through the viewModel
                    viewModel.workspaceManager.currentSession?.selectedNode
                        == nil
                        || viewModel.isGenerating
                )

                if viewModel.isGenerating {
                    ProgressView().padding(.leading, 8)
                }

                Spacer()
            }

            if let error = viewModel.errorMessage {
                Text(error).font(.footnote).foregroundColor(.red)
            }
        }
        .padding()
        .onChange(of: viewModel.workspaceManager.currentSession?.selectedNodeID)
        { _ in
            viewModel.reset()
        }
    }

    /// The computed property now gets the workspace from the viewModel.
    private var headerTitle: String {
        if let node = viewModel.workspaceManager.currentSession?.selectedNode {
            return "AI Docs for: \(node.name)"
        } else {
            return "Select a file to generate documentation"
        }
    }
}
