//
//  AIGenerationViewModel.swift
//  structra
//
//  Created by Nanashi Li on 7/5/25.
//

import Combine
import Foundation

@MainActor
class AIGenerationViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The text content that is actively being streamed from the AI.
    /// The SwiftUI view will bind to this property.
    @Published var displayText: String = ""

    /// A flag to indicate when an AI job is in progress.
    /// Used to show/hide a progress indicator and disable buttons.
    @Published var isGenerating: Bool = false

    /// Holds any error message for display in the UI.
    @Published var errorMessage: String?

    // MARK: - Private Properties

    public let workspaceManager: WorkspaceManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer

    init(workspaceManager: WorkspaceManager) {
        self.workspaceManager = workspaceManager
        setupSubscriptions()
    }

    // MARK: - Public Methods

    /// Starts the documentation generation process for a given project node.
    func generateDocumentation(for node: ProjectNode) {
        // Reset state before starting a new job
        self.displayText = ""
        self.errorMessage = nil
        self.isGenerating = true

        // Call the existing method on your WorkspaceManager
        workspaceManager.initiateDocumentationGeneration(for: node, detailLevel: "detailLevel")
    }

    func reset() {
        self.displayText = ""
        self.errorMessage = nil
        self.isGenerating = false
    }

    // MARK: - Private Setup

    /// Subscribes to the publisher from the WorkspaceManager to receive AI results.
    private func setupSubscriptions() {
        workspaceManager.aiResultPublisher
            // We use .receive(on: RunLoop.main) to ensure all UI updates
            // happen on the main thread, which is a requirement for SwiftUI.
            // @MainActor on the class also helps enforce this.
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .chunk(let textChunk):
                    // This is the core of the streaming logic.
                    // We simply append the new text to our published property.
                    self.displayText += textChunk

                case .success:
                    // The stream finished successfully.
                    self.isGenerating = false

                case .failure(let error):
                    // An error occurred.
                    self.errorMessage =
                        "Generation Failed: \(error.localizedDescription)"
                    self.isGenerating = false
                }
            }
            // Store the subscription to keep it alive.
            .store(in: &cancellables)
    }
}
