import AppKit

final class CharacterWindow: NSPanel {
    let imageView: NSImageView

    init(frameSize: NSSize) {
        let rect = NSRect(origin: .zero, size: frameSize)
        self.imageView = NSImageView(frame: rect)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.wantsLayer = true

        super.init(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        ignoresMouseEvents = true
        isMovable = false
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]

        contentView = imageView
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
