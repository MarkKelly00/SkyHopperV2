import SpriteKit

final class DebugMenu {
    static let shared = DebugMenu()
    private init() {}

    var lightingEnabled: Bool = true
    var gradingEnabled: Bool = true
    var overdrawEnabled: Bool = false
}


