import AppKit

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

guard let context = NSGraphicsContext.current?.cgContext else {
    fatalError("Unable to create drawing context")
}

context.setFillColor(NSColor(calibratedRed: 16/255, green: 17/255, blue: 20/255, alpha: 1).cgColor)
context.fill(CGRect(origin: .zero, size: size))

let blue = NSColor(calibratedRed: 143/255, green: 197/255, blue: 1, alpha: 1).cgColor
let cream = NSColor(calibratedRed: 245/255, green: 241/255, blue: 232/255, alpha: 1).cgColor
let center = CGPoint(x: 512, y: 512)

context.setStrokeColor(blue)
context.setLineWidth(44)
context.setLineCap(.round)
context.strokeEllipse(in: CGRect(x: 242, y: 242, width: 540, height: 540))

context.setLineWidth(36)
context.move(to: CGPoint(x: center.x, y: 140))
context.addLine(to: CGPoint(x: center.x, y: 318))
context.move(to: CGPoint(x: center.x, y: 706))
context.addLine(to: CGPoint(x: center.x, y: 884))
context.move(to: CGPoint(x: 140, y: center.y))
context.addLine(to: CGPoint(x: 318, y: center.y))
context.move(to: CGPoint(x: 706, y: center.y))
context.addLine(to: CGPoint(x: 884, y: center.y))
context.strokePath()

context.setFillColor(cream)
context.fillEllipse(in: CGRect(x: 440, y: 440, width: 144, height: 144))

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:])
else { fatalError("Unable to encode app icon") }

let destination = CommandLine.arguments.dropFirst().first ?? "AppIcon.png"
try png.write(to: URL(fileURLWithPath: destination), options: .atomic)
