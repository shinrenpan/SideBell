import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Run from the repository root:
//   swift docs/shipaton/make-thumbnail.swift
// Regenerate this whenever docs/images/ is refreshed — the thumbnail is built
// from those two screenshots plus the app icon, so it drifts otherwise.
let repoRoot = FileManager.default.currentDirectoryPath
let outPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "\(repoRoot)/docs/shipaton/devpost-thumbnail.png"

func loadImage(_ path: String) -> CGImage {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let src = CGImageSourceCreateWithURL(url, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
        fatalError("cannot load \(path)")
    }
    return img
}

let icon = loadImage("\(repoRoot)/Sources/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
let ipad = loadImage("\(repoRoot)/docs/images/patient-ipad.png")
let iphone = loadImage("\(repoRoot)/docs/images/caregiver-iphone.png")

// --- sample the icon's background navy from a corner pixel ---
func samplePixel(_ image: CGImage, x: Int, y: Int) -> (CGFloat, CGFloat, CGFloat) {
    var data = [UInt8](repeating: 0, count: 4)
    let cs = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(data: &data, width: 1, height: 1, bitsPerComponent: 8,
                              bytesPerRow: 4, space: cs,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        return (0, 0, 0)
    }
    ctx.draw(image, in: CGRect(x: -x, y: -(image.height - y - 1),
                               width: image.width, height: image.height))
    return (CGFloat(data[0]) / 255, CGFloat(data[1]) / 255, CGFloat(data[2]) / 255)
}

let (nr, ng, nb) = samplePixel(icon, x: 24, y: 24)
FileHandle.standardError.write("sampled navy: \(Int(nr*255)) \(Int(ng*255)) \(Int(nb*255))\n".data(using: .utf8)!)

// --- canvas: 3:2 as Devpost recommends ---
let W = 1500, H = 1000
let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8,
                          bytesPerRow: 0, space: cs,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fatalError("cannot create context")
}

// background: subtle vertical gradient off the icon's navy
let top = CGColor(colorSpace: cs, components: [nr * 1.18, ng * 1.18, nb * 1.22, 1])!
let bottom = CGColor(colorSpace: cs, components: [nr * 0.72, ng * 0.72, nb * 0.78, 1])!
if let grad = CGGradient(colorsSpace: cs, colors: [top, bottom] as CFArray, locations: [0, 1]) {
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])
}

// --- text helpers (CoreText) ---
func draw(_ text: String, font: CTFont, color: CGColor, at origin: CGPoint,
          maxWidth: CGFloat, lineSpacing: CGFloat = 0) {
    var spacing = lineSpacing
    let para = withUnsafeBytes(of: &spacing) { buf -> CTParagraphStyle in
        var setting = CTParagraphStyleSetting(
            spec: .lineSpacingAdjustment,
            valueSize: MemoryLayout<CGFloat>.size,
            value: buf.baseAddress!)
        return CTParagraphStyleCreate(&setting, 1)
    }
    let attrs: [CFString: Any] = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: color,
        kCTParagraphStyleAttributeName: para,
    ]
    let attributed = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
    let framesetter = CTFramesetterCreateWithAttributedString(attributed)
    let path = CGPath(rect: CGRect(x: origin.x, y: origin.y - 400,
                                   width: maxWidth, height: 400), transform: nil)
    let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
    ctx.saveGState()
    ctx.textMatrix = .identity
    CTFrameDraw(frame, ctx)
    ctx.restoreGState()
}

func font(_ name: String, _ size: CGFloat) -> CTFont {
    CTFontCreateWithName(name as CFString, size, nil)
}

let white = CGColor(colorSpace: cs, components: [1, 1, 1, 1])!
let softWhite = CGColor(colorSpace: cs, components: [1, 1, 1, 0.82])!

// --- left column: icon + wordmark + tagline ---
let leftX: CGFloat = 92
let iconSize: CGFloat = 150

func roundedImage(_ image: CGImage, in rect: CGRect, radius: CGFloat, shadow: Bool) {
    ctx.saveGState()
    if shadow {
        ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 34,
                      color: CGColor(colorSpace: cs, components: [0, 0, 0, 0.42])!)
        ctx.beginPath()
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
        ctx.setFillColor(CGColor(colorSpace: cs, components: [0, 0, 0, 1])!)
        ctx.fillPath()
        ctx.restoreGState()
        ctx.saveGState()
    }
    ctx.beginPath()
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.clip()
    ctx.draw(image, in: rect)
    ctx.restoreGState()
}

let iconRect = CGRect(x: leftX, y: CGFloat(H) - 250 - 96, width: iconSize, height: iconSize)
roundedImage(icon, in: iconRect, radius: iconSize * 0.225, shadow: true)

draw("SideBell", font: font("SFProDisplay-Bold", 82) , color: white,
     at: CGPoint(x: leftX, y: iconRect.minY - 34), maxWidth: 540)

draw("An accessible call bell\nthat works without\nthe internet.",
     font: font("SFProDisplay-Medium", 38), color: softWhite,
     at: CGPoint(x: leftX + 3, y: iconRect.minY - 150), maxWidth: 540, lineSpacing: 8)

// thin rule + qualifier
ctx.setFillColor(CGColor(colorSpace: cs, components: [1, 1, 1, 0.28])!)
ctx.fill(CGRect(x: leftX + 3, y: iconRect.minY - 330, width: 108, height: 3))

draw("Bluetooth only · No server · Free",
     font: font("SFProText-Semibold", 27), color: softWhite,
     at: CGPoint(x: leftX + 3, y: iconRect.minY - 356), maxWidth: 560)

// --- right column: the two devices ---
let scale: CGFloat = 1.06
let ipadW = CGFloat(ipad.width) * scale, ipadH = CGFloat(ipad.height) * scale
let phoneW = CGFloat(iphone.width) * scale, phoneH = CGFloat(iphone.height) * scale
let gap: CGFloat = 46
let groupW = ipadW + gap + phoneW
let rightRegionStart: CGFloat = 566
let startX = rightRegionStart + (CGFloat(W) - rightRegionStart - groupW) / 2
let baseY = (CGFloat(H) - ipadH) / 2

roundedImage(ipad, in: CGRect(x: startX, y: baseY, width: ipadW, height: ipadH),
             radius: 26, shadow: true)
roundedImage(iphone, in: CGRect(x: startX + ipadW + gap, y: baseY, width: phoneW, height: phoneH),
             radius: 22, shadow: true)

// --- write ---
guard let image = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: outPath) as CFURL,
                                                 UTType.png.identifier as CFString, 1, nil) else {
    fatalError("cannot write")
}
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote \(outPath) — \(W)x\(H)")
