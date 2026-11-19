import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments[1]).appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func drawIcon(size: Int) throws -> Data {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    let scale = CGFloat(size) / 1024
    NSGraphicsContext.current!.cgContext.scaleBy(x: scale, y: scale)

    let tile = NSBezierPath(roundedRect: NSRect(x: 88, y: 88, width: 848, height: 848), xRadius: 192, yRadius: 192)
    NSColor(calibratedRed: 0.08, green: 0.29, blue: 0.24, alpha: 1).setFill()
    tile.fill()
    NSGradient(colors: [NSColor(calibratedRed: 0.20, green: 0.70, blue: 0.52, alpha: 1),
                        NSColor(calibratedRed: 0.07, green: 0.35, blue: 0.30, alpha: 1)])!
        .draw(in: tile, angle: -65)

    let back = NSBezierPath(roundedRect: NSRect(x: 274, y: 332, width: 330, height: 408), xRadius: 48, yRadius: 48)
    NSColor.white.withAlphaComponent(0.30).setFill()
    back.fill()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.17)
    shadow.shadowBlurRadius = 24
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    let front = NSBezierPath(roundedRect: NSRect(x: 386, y: 240, width: 330, height: 420), xRadius: 48, yRadius: 48)
    NSColor.white.setFill()
    front.fill()
    NSGraphicsContext.restoreGraphicsState()

    let clip = NSBezierPath(roundedRect: NSRect(x: 470, y: 630, width: 160, height: 64), xRadius: 26, yRadius: 26)
    NSColor(calibratedRed: 0.81, green: 0.94, blue: 0.87, alpha: 1).setFill()
    clip.fill()
    let ink = NSColor(calibratedRed: 0.13, green: 0.53, blue: 0.40, alpha: 1)
    ink.withAlphaComponent(0.20).setFill()
    NSBezierPath(roundedRect: NSRect(x: 445, y: 521, width: 210, height: 20), xRadius: 10, yRadius: 10).fill()
    NSBezierPath(roundedRect: NSRect(x: 445, y: 465, width: 142, height: 20), xRadius: 10, yRadius: 10).fill()
    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: 450, y: 359))
    arrow.line(to: NSPoint(x: 646, y: 359))
    arrow.move(to: NSPoint(x: 590, y: 415))
    arrow.line(to: NSPoint(x: 646, y: 359))
    arrow.line(to: NSPoint(x: 590, y: 303))
    arrow.lineWidth = 28
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    ink.setStroke()
    arrow.stroke()
    image.unlockFocus()
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "CopyPath.Icon", code: 1)
    }
    return png
}

for size in [16, 32, 128, 256, 512] {
    try drawIcon(size: size).write(to: output.appendingPathComponent("icon_\(size)x\(size).png"))
    try drawIcon(size: size * 2).write(to: output.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
