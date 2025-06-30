//
//  InspectorViewController.swift
//  structra
//
//  Created by Tihan-Nico Paxton on 6/18/25.
//

import Cocoa

class InspectorViewController: NSViewController {
    override func loadView() {
        // a simple vertical stack of labels
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.distribution = .fillProportionally
        stack.spacing = 8
        self.view = stack
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let stack = view as? NSStackView else { return }

        let title = NSTextField(labelWithString: "Inspector")
        title.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        stack.addArrangedSubview(title)

        let info = NSTextField(labelWithString: "Select a file to see details")
        info.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        info.textColor = .secondaryLabelColor
        stack.addArrangedSubview(info)

        stack.setHuggingPriority(.defaultHigh, for: .horizontal)
        stack.setHuggingPriority(.defaultHigh, for: .vertical)
    }
}
