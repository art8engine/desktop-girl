import AppKit

final class MenuBarController {

    private let statusItem: NSStatusItem
    private let toggleItem: NSMenuItem
    private let onToggle: (Bool) -> Void

    init(initialEnabled: Bool, iconImage: NSImage?, onToggle: @escaping (Bool) -> Void) {
        self.onToggle = onToggle
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            if let icon = iconImage {
                let resized = NSImage(size: NSSize(width: 18, height: 18))
                resized.lockFocus()
                icon.draw(in: NSRect(x: 0, y: 0, width: 18, height: 18))
                resized.unlockFocus()
                resized.isTemplate = false
                button.image = resized
            } else {
                button.title = "M"
            }
            button.toolTip = "Marin"
        }

        let menu = NSMenu()

        toggleItem = NSMenuItem(
            title: "마린",
            action: #selector(MenuBarController.toggle),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.state = initialEnabled ? .on : .off
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggle() {
        let next: NSControl.StateValue = (toggleItem.state == .on) ? .off : .on
        toggleItem.state = next
        onToggle(next == .on)
    }

    func setState(_ enabled: Bool) {
        toggleItem.state = enabled ? .on : .off
    }
}
