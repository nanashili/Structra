import AppKit

class FileSystemTableViewCell: StandardTableViewCell {

    /// The `ProjectNode` the cell represents.
    var node: ProjectNode!

    var changeLabelLargeWidth: NSLayoutConstraint!
    var changeLabelSmallWidth: NSLayoutConstraint!

    init(frame frameRect: NSRect, node: ProjectNode?, isEditable: Bool = true) {
        super.init(frame: frameRect, isEditable: isEditable)

        if let node = node {
            addIcon(for: node)
        }

        Task { @MainActor in
            addModel()
        }
    }

    override func configLabel(label: NSTextField, isEditable: Bool) {
        super.configLabel(label: label, isEditable: isEditable)
        label.delegate = self
    }

    func addIcon(for node: ProjectNode) {
        var imageName = iconName(for: node)

        guard
            let image = NSImage(
                systemSymbolName: imageName,
                accessibilityDescription: nil
            )
        else {
            return
        }

        self.node = node
        fileIcon.image = image
        fileIcon.contentTintColor = color(for: node)
        toolTip = node.name
        label.stringValue = displayName(for: node)
    }

    func addModel() {
        secondaryLabel.stringValue = node.metadata.tags.first ?? ""
        if secondaryLabel.stringValue == "?" {
            secondaryLabel.stringValue = "A"
        }
    }

    required init?(coder: NSCoder) {
        fatalError(
            """
                init?(coder: NSCoder) isn't implemented on FileSystemTableViewCell.
                Use init(frame:node:isEditable:) instead.
            """
        )
    }

    override init(frame frameRect: NSRect) {
        fatalError(
            """
                init(frame:) isn't implemented. Use init(frame:node:isEditable:) instead.
            """
        )
    }

    private var fontSize: Double {
        switch self.frame.height {
        case 20: return 11
        case 22: return 13
        case 24: return 14
        default: return 13
        }
    }

    func displayName(for node: ProjectNode) -> String {
        node.name.deletingPathExtension
    }

    func iconName(for node: ProjectNode) -> String {
        if node.type == .folder(customIconName: "") {
            return "folder"
        }
        if node.metadata.isReadOnly {
            return "lock"
        }
        if node.metadata.fileType == "swift" {
            return "swift"
        }
        return "doc"
    }

    func color(for node: ProjectNode) -> NSColor {
        if node.type == .file(customIconName: "") {
            return .systemBlue
        } else {
            return .controlAccentColor
        }
    }
}

let errorRed = NSColor(red: 1, green: 0, blue: 0, alpha: 0.2)

extension FileSystemTableViewCell: @MainActor NSTextFieldDelegate {

    func controlTextDidChange(_ obj: Notification) {
        label.backgroundColor =
            validateFileName(for: label?.stringValue ?? "") ? .none : errorRed
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        label.backgroundColor =
            validateFileName(for: label?.stringValue ?? "") ? .none : errorRed
        if validateFileName(for: label?.stringValue ?? "") {
            let newURL = node.url.deletingLastPathComponent()
                .appendingPathComponent(label?.stringValue ?? "")
            // FileManager.default.moveItem(at: node.url, to: newURL)
            node.rename(to: label?.stringValue ?? "")
        } else {
            label?.stringValue = node.name
        }
    }

    func validateFileName(for newName: String) -> Bool {
        guard newName != node.name else { return true }

        let newPath = node.url.deletingLastPathComponent()
            .appendingPathComponent(newName).path

        return !newName.isEmpty
            && newName.isValidFilename
            && !FileManager.default.fileExists(atPath: newPath)
    }
}

extension String {
    var isValidFilename: Bool {
        // Exclude invalid characters (like ":")
        let regex = "^[^:]+$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(
            with: self
        )
    }

    var deletingPathExtension: String {
        (self as NSString).deletingPathExtension
    }

    func typeHidden(hidden: Bool) -> String {
        return hidden ? self.deletingPathExtension : self
    }
}
