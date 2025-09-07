import SpriteKit
import CoreImage

/// Full-scene grading node with optional CI filters.
/// Use low default intensity; gate usage by device tier if needed.
final class VisualGradeNode: SKEffectNode {
    enum Grade { case none, subtleBloom, vignette, curve }

    var grade: Grade = .subtleBloom { didSet { updateChain() } }
    var intensity: CGFloat = 0.35 { didSet { updateChain() } }

    override init() {
        super.init()
        shouldRasterize = true
        blendMode = .alpha
        updateChain()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        updateChain()
    }

    private func updateChain() {
        switch grade {
        case .none:
            filter = nil
        case .subtleBloom:
            // CIBloom: inputImage -> outputImage
            let bloom = CIFilter(name: "CIBloom")
            bloom?.setValue(intensity * 2.0, forKey: kCIInputIntensityKey)
            bloom?.setValue(max(intensity * 20.0, 3.0), forKey: kCIInputRadiusKey)
            filter = bloom
        case .vignette:
            let vg = CIFilter(name: "CIVignette")
            vg?.setValue(intensity * 2.0, forKey: kCIInputIntensityKey)
            vg?.setValue(max(intensity * 18.0, 2.0), forKey: kCIInputRadiusKey)
            filter = vg
        case .curve:
            // Use a gentle tone curve
            let curve = CIFilter(name: "CIToneCurve")
            curve?.setValue(CIVector(x: 0, y: 0), forKey: "inputPoint0")
            curve?.setValue(CIVector(x: 0.25, y: 0.2 + intensity * 0.05), forKey: "inputPoint1")
            curve?.setValue(CIVector(x: 0.5, y: 0.5), forKey: "inputPoint2")
            curve?.setValue(CIVector(x: 0.75, y: 0.8 - intensity * 0.05), forKey: "inputPoint3")
            curve?.setValue(CIVector(x: 1, y: 1), forKey: "inputPoint4")
            filter = curve
        }
    }
}


