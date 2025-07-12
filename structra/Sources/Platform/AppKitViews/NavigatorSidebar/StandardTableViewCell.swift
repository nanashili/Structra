//
//  StandardTableViewCell.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/22/25.
//

import AppKit
import SwiftUI

/// Custom NSTableCellView with icon, two labels, and a status indicator.
class StandardTableViewCell: NSTableCellView {

    // MARK: - View Components

    let label: NSTextField  // Main label (editable optionally)
    let secondaryLabel: NSTextField  // Secondary text (right-aligned)
    let fileIcon: NSImageView  // File icon on the left
    let staleDocumentationIndicator: NSImageView  // Stale data warning (right side)

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        self.fileIcon = Self.createIcon()
        self.label = Self.createLabel(isEditable: false)
        self.secondaryLabel = Self.createSecondaryLabel()
        self.staleDocumentationIndicator = Self.createStaleIndicator()

        super.init(frame: frameRect)

        self.textField = label
        self.imageView = fileIcon

        // Add all views to the cell
        addSubview(fileIcon)
        addSubview(label)
        addSubview(secondaryLabel)
        addSubview(staleDocumentationIndicator)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Cell Configuration

    /// Populates the cell with content and styles.
    func configure(
        labelText: String,
        labelIsEditable: Bool,
        icon: NSImage?,
        iconColor: NSColor,
        secondaryText: String,
        isDocumentationStale: Bool
    ) {
        label.stringValue = labelText
        label.isEditable = labelIsEditable
        label.isSelectable = labelIsEditable

        fileIcon.image = icon
        fileIcon.contentTintColor = iconColor

        secondaryLabel.stringValue = secondaryText
        staleDocumentationIndicator.isHidden = !isDocumentationStale

        needsLayout = true
    }

    /// Prepares cell for reuse by clearing dynamic content.
    override func prepareForReuse() {
        super.prepareForReuse()
        staleDocumentationIndicator.isHidden = true
        secondaryLabel.stringValue = ""
        label.backgroundColor = .clear
    }

    // MARK: - Manual Layout

    /// Optimized manual layout of all subviews.
    override func layout() {
        super.layout()

        let bounds = self.bounds
        let iconSize = NSSize(width: 16, height: 16)
        let padding: CGFloat = 4.0
        let totalHeight = bounds.height

        // File icon on the far left
        let iconY = (totalHeight - iconSize.height) / 2
        fileIcon.frame = NSRect(
            x: padding,
            y: iconY,
            width: iconSize.width,
            height: iconSize.height
        )

        // Warning icon on the far right
        let staleIndicatorSize =
            staleDocumentationIndicator.isHidden
            ? .zero : NSSize(width: 14, height: 14)
        let staleIndicatorY = (totalHeight - staleIndicatorSize.height) / 2
        staleDocumentationIndicator.frame = NSRect(
            x: bounds.width - staleIndicatorSize.width - padding,
            y: staleIndicatorY,
            width: staleIndicatorSize.width,
            height: staleIndicatorSize.height
        )

        // Secondary label before warning icon
        let secondaryLabelSize = secondaryLabel.sizeThatFits(
            NSSize(width: .greatestFiniteMagnitude, height: totalHeight)
        )
        let secondaryLabelY = (totalHeight - secondaryLabelSize.height) / 2
        let secondaryLabelX =
            staleDocumentationIndicator.frame.minX - secondaryLabelSize.width
            - (staleIndicatorSize.width > 0 ? padding : 0)
        secondaryLabel.frame = NSRect(
            x: secondaryLabelX,
            y: secondaryLabelY,
            width: secondaryLabelSize.width,
            height: secondaryLabelSize.height
        )

        // Main label fills space between icon and secondary label
        let labelX = fileIcon.frame.maxX + padding * 2
        let availableWidthForLabel = secondaryLabelX - labelX - padding
        let labelY = (totalHeight - label.intrinsicContentSize.height) / 2
        label.frame = NSRect(
            x: labelX,
            y: labelY,
            width: availableWidthForLabel,
            height: label.intrinsicContentSize.height
        )
    }

    // MARK: - View Factory Methods

    /// Creates the icon view (left).
    private static func createIcon() -> NSImageView {
        let icon = NSImageView()
        icon.symbolConfiguration = .init(
            pointSize: 13,
            weight: .regular,
            scale: .medium
        )
        return icon
    }

    /// Creates the primary label.
    private static func createLabel(isEditable: Bool) -> NSTextField {
        let label = NSTextField()
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = isEditable
        label.isSelectable = isEditable
        label.cell?.usesSingleLineMode = true
        label.cell?.lineBreakMode = .byTruncatingMiddle
        label.font = .systemFont(ofSize: 13)
        label.backgroundColor = .clear
        label.layer?.cornerRadius = 4.0
        return label
    }

    /// Creates the secondary label (right-aligned).
    private static func createSecondaryLabel() -> NSTextField {
        let label = NSTextField()
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabelColor
        return label
    }

    /// Creates the warning indicator for stale documentation.
    private static func createStaleIndicator() -> NSImageView {
        let indicator = NSImageView()
        indicator.symbolConfiguration = .init(
            pointSize: 12,
            weight: .semibold,
            scale: .small
        )
        indicator.image = NSImage(
            systemSymbolName: "exclamationmark.triangle.fill",
            accessibilityDescription: "Stale documentation"
        )
        indicator.contentTintColor = .systemYellow
        indicator.isHidden = true
        return indicator
    }
}
