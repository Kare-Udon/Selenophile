import AppKit

struct MenuBarStatusIconRenderer {
    let iconSize = NSSize(width: 18, height: 18)

    func makeImage(configuration: MenuBarIconConfiguration) -> NSImage {
        let image = NSImage(size: iconSize)
        image.lockFocus()

        let bounds = NSRect(origin: .zero, size: iconSize)
        let ringRect = bounds.insetBy(dx: 1.8, dy: 1.8)

        NSColor.black.withAlphaComponent(0.24).setStroke()
        let track = NSBezierPath(ovalIn: ringRect)
        track.lineWidth = 2.6
        track.stroke()

        NSColor.black.setStroke()
        let progressPath = NSBezierPath()
        progressPath.lineWidth = 3.2
        progressPath.lineCapStyle = .round
        progressPath.appendArc(
            withCenter: NSPoint(x: bounds.midX, y: bounds.midY),
            radius: ringRect.width / 2,
            startAngle: 90,
            endAngle: 90 - (configuration.visibleProgress * 360),
            clockwise: true
        )
        progressPath.stroke()

        if configuration.showsCenterCore {
            NSColor.black.setFill()
            let coreRect = NSRect(x: bounds.midX - 3, y: bounds.midY - 3, width: 6, height: 6)
            NSBezierPath(ovalIn: coreRect).fill()
        }

        if let overlaySymbolName = configuration.overlaySymbolName,
           let symbolImage = overlaySymbolImage(named: overlaySymbolName) {
            let symbolRect = NSRect(x: bounds.midX - 5, y: bounds.midY - 5, width: 10, height: 10)
            symbolImage.draw(in: symbolRect)
        }

        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    private func overlaySymbolImage(named systemName: String) -> NSImage? {
        let configuration = NSImage.SymbolConfiguration(pointSize: 9, weight: .heavy)
        guard let symbolImage = NSImage(
            systemSymbolName: systemName,
            accessibilityDescription: nil
        )?.withSymbolConfiguration(configuration) else {
            return nil
        }

        let tinted = NSImage(size: symbolImage.size)
        tinted.lockFocus()
        NSColor.black.set()
        let rect = NSRect(origin: .zero, size: symbolImage.size)
        rect.fill()
        symbolImage.draw(
            in: rect,
            from: .zero,
            operation: .destinationIn,
            fraction: 1
        )
        tinted.unlockFocus()
        tinted.isTemplate = true
        return tinted
    }
}
