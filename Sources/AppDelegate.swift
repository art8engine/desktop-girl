import AppKit

private let kEnabledKey = "marin.enabled"

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var sprites: Sprites!
    private var controller: CharacterController!
    private var menuBar: MenuBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        sprites = Sprites.load()
        controller = CharacterController(sprites: sprites)

        let defaults = UserDefaults.standard
        if defaults.object(forKey: kEnabledKey) == nil {
            defaults.set(true, forKey: kEnabledKey)
        }
        let initialEnabled = defaults.bool(forKey: kEnabledKey)

        menuBar = MenuBarController(
            initialEnabled: initialEnabled,
            iconImage: sprites.idle.first,
            onToggle: { [weak self] on in
                self?.controller.setEnabled(on)
                UserDefaults.standard.set(on, forKey: kEnabledKey)
            }
        )

        controller.setEnabled(initialEnabled)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
