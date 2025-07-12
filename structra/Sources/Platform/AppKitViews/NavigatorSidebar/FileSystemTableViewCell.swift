//
//  FileSystemTableViewCell.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/22/25.
//

import AppKit

/// A specialized cell for displaying `ProjectNode` data.
class FileSystemTableViewCell: StandardTableViewCell {

    private var node: ProjectNode?  // Bound node for this cell
    private let errorRed = NSColor(red: 1, green: 0.1, blue: 0.1, alpha: 0.2)  // Error highlight

    // MARK: - Configuration

    /// Sets up the cell UI based on the provided node data.
    func configure(with node: ProjectNode, isEditable: Bool) {
        self.node = node

        let iconName = self.iconName(for: node)
        let iconColor = self.color(for: node)
        let secondaryText = node.metadata.tags.first ?? ""

        super.configure(
            labelText: displayName(for: node),
            labelIsEditable: isEditable,
            icon: NSImage(
                systemSymbolName: iconName,
                accessibilityDescription: nil
            ),
            iconColor: iconColor,
            secondaryText: secondaryText,
            isDocumentationStale: node.isDocumentationStale
        )

        self.toolTip = node.name
        self.label.delegate = self
    }

    // MARK: - Cell Lifecycle

    /// Reset internal references before reuse.
    override func prepareForReuse() {
        super.prepareForReuse()
        self.node = nil
        self.label.delegate = nil
    }

    // MARK: - Editing

    /// Makes the label editable and focuses it.
    @MainActor
    func beginEditing() {
        self.window?.makeFirstResponder(self.label)
    }

    // MARK: - Data to View Translation

    /// Extracts display name from node path.
    private func displayName(for node: ProjectNode) -> String {
        return node.name.deletingPathExtension
    }

    /// Selects appropriate SF Symbol based on node type and metadata.
    private func iconName(for node: ProjectNode) -> String {
        switch node.type {
        case .folder:
            return "folder"
        case .file:
            if node.metadata.isReadOnly { return "lock" }
            if node.metadata.fileType == "swift" { return "swift" }
            return "doc"
        }
    }

    /// Returns color used to tint the icon based on node type.
    private func color(for node: ProjectNode) -> NSColor {
        switch node.type {
        case .folder:
            return .controlAccentColor
        case .file:
            return .systemBlue
        }
    }
}

// MARK: - NSTextFieldDelegate for Renaming

extension FileSystemTableViewCell: NSTextFieldDelegate {

    /// Updates background to red if file name is invalid while typing.
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        let isValid = validate(fileName: textField.stringValue)
        textField.layer?.backgroundColor =
            isValid ? NSColor.clear.cgColor : errorRed.cgColor
    }

    /// Applies or reverts the edited name after editing ends.
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let node = self.node, let textField = obj.object as? NSTextField
        else { return }

        textField.layer?.backgroundColor = NSColor.clear.cgColor

        if validate(fileName: textField.stringValue) {
            node.rename(to: textField.stringValue)
        } else {
            textField.stringValue = displayName(for: node)
        }
    }

    /// Validates the new file name: non-empty, safe characters, not existing.
    private func validate(fileName: String) -> Bool {
        guard let node = self.node else { return false }
        guard fileName != node.name else { return true }

        let newPath = node.url.deletingLastPathComponent()
            .appendingPathComponent(fileName).path

        return !fileName.isEmpty
            && fileName.range(of: "[/:]", options: .regularExpression) == nil
            && !FileManager.default.fileExists(atPath: newPath)
    }
}

// MARK: - String Extension Helper

extension String {
    /// Removes file extension from string.
    fileprivate var deletingPathExtension: String {
        return (self as NSString).deletingPathExtension
    }
}
