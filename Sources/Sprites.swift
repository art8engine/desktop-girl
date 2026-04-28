import AppKit

struct Sprites {
    let idle: [NSImage]
    let walkRight: [NSImage]
    let walkLeft: [NSImage]

    var frameSize: NSSize {
        idle.first?.size ?? NSSize(width: 128, height: 128)
    }

    static func load() -> Sprites {
        let idle = loadRow(prefix: "idle")
        let right = loadRow(prefix: "right")
        // The source asset's "Walk Left" row is poorly drawn (the character
        // does not consistently face left), which makes the animation look
        // like it wobbles. We synthesize walkLeft by horizontally flipping
        // walkRight — the standard sprite-mirror trick used in 2D games.
        let left = right.map(flipHorizontally)
        return Sprites(idle: idle, walkRight: right, walkLeft: left)
    }

    private static func loadRow(prefix: String) -> [NSImage] {
        (0..<3).compactMap { idx -> NSImage? in
            let name = "\(prefix)_\(idx)"
            guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
                  let img = NSImage(contentsOf: url) else {
                FileHandle.standardError.write(Data("missing sprite: \(name).png\n".utf8))
                return nil
            }
            return img
        }
    }

    private static func flipHorizontally(_ src: NSImage) -> NSImage {
        let size = src.size
        let flipped = NSImage(size: size)
        flipped.lockFocus()
        let ctx = NSGraphicsContext.current
        ctx?.imageInterpolation = .none  // preserve crisp pixel-art edges
        let xform = NSAffineTransform()
        xform.translateX(by: size.width, yBy: 0)
        xform.scaleX(by: -1, yBy: 1)
        xform.concat()
        src.draw(at: .zero,
                 from: NSRect(origin: .zero, size: size),
                 operation: .sourceOver,
                 fraction: 1.0)
        flipped.unlockFocus()
        return flipped
    }
}
