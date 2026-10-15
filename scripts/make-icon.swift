import AppKit

@main struct IconMaker {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else { fatalError("Output path required") }
        let size = 1024
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                          bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                          isPlanar: false, colorSpaceName: .deviceRGB,
                                          bytesPerRow: 0, bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: bitmap) else { fatalError("Bitmap creation failed") }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        defer { NSGraphicsContext.restoreGraphicsState() }

        let background = NSBezierPath(roundedRect: NSRect(x: 32, y: 32, width: 960, height: 960), xRadius: 225, yRadius: 225)
        NSGradient(starting: NSColor(red: 0.29, green: 0.32, blue: 0.77, alpha: 1),
                   ending: NSColor(red: 0.13, green: 0.52, blue: 0.67, alpha: 1))!
            .draw(in: background, angle: -27)

        let halo = NSBezierPath(ovalIn: NSRect(x: 210, y: 210, width: 604, height: 604))
        NSColor.white.withAlphaComponent(0.075).setFill()
        halo.fill()

        for (degrees, alpha, width) in [(38.0, 0.93, 31.0), (-38.0, 0.56, 23.0)] {
            let orbit = NSBezierPath(ovalIn: NSRect(x: 194, y: 407, width: 636, height: 210))
            var rotation = AffineTransform()
            rotation.translate(x: 512, y: 512)
            rotation.rotate(byDegrees: degrees)
            rotation.translate(x: -512, y: -512)
            orbit.transform(using: rotation)
            orbit.lineWidth = width
            NSColor.white.withAlphaComponent(alpha).setStroke()
            orbit.stroke()
        }

        let center = NSBezierPath(ovalIn: NSRect(x: 426, y: 426, width: 172, height: 172))
        NSColor(red: 0.94, green: 0.69, blue: 0.40, alpha: 1).setFill()
        center.fill()
        NSColor.white.setFill()
        NSBezierPath(ovalIn: NSRect(x: 741, y: 635, width: 29, height: 29)).fill()

        guard let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("PNG encoding failed") }
        try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]), options: .atomic)
    }
}
