import CoreGraphics

/// Canonical level profiles used to keep physics/feel consistent.
/// 1★ uses City Beginnings; 2★ uses Stargate Escape numbers.
struct LevelProfile: Codable {
    let scrollSpeed: CGFloat
    let gravityY: CGFloat
    let jumpImpulseY: CGFloat
    let spawnInterval: CGFloat
    // New hazards & fairness tuning for mountain maps
    let yetiSpawnChance: Int?
    let yetiMinGap: Int?
    let yetiMaxConcurrent: Int?
    let snowballSpeed: CGFloat?
    let snowballArc: CGFloat?
    let snowballMaxConcurrent: Int?
    let telegraphMs: Int?
    let throwCooldownMs: Int?
    let allowBounce: Bool?
    let bounceLoss: CGFloat?
}

enum LevelProfiles {
    static let star1 = LevelProfile(scrollSpeed: 120, gravityY: -5.0, jumpImpulseY: 12, spawnInterval: 3.0,
                                    yetiSpawnChance: nil, yetiMinGap: nil, yetiMaxConcurrent: nil, snowballSpeed: nil, snowballArc: nil, snowballMaxConcurrent: nil, telegraphMs: nil, throwCooldownMs: nil, allowBounce: nil, bounceLoss: nil)
    static let star2 = LevelProfile(scrollSpeed: 125, gravityY: -5.0, jumpImpulseY: 12, spawnInterval: 2.9,
                                    yetiSpawnChance: 25, yetiMinGap: 3, yetiMaxConcurrent: 1, snowballSpeed: 240, snowballArc: 0.55, snowballMaxConcurrent: 1, telegraphMs: 300, throwCooldownMs: 1200, allowBounce: false, bounceLoss: 0.4)
    static let star3 = LevelProfile(scrollSpeed: 140, gravityY: -5.2, jumpImpulseY: 12, spawnInterval: 2.5,
                                    yetiSpawnChance: 35, yetiMinGap: 3, yetiMaxConcurrent: 2, snowballSpeed: 275, snowballArc: 0.58, snowballMaxConcurrent: 1, telegraphMs: 280, throwCooldownMs: 1000, allowBounce: true, bounceLoss: 0.45)
    static let star4 = LevelProfile(scrollSpeed: 150, gravityY: -5.4, jumpImpulseY: 12, spawnInterval: 2.2,
                                    yetiSpawnChance: 40, yetiMinGap: 3, yetiMaxConcurrent: 2, snowballSpeed: 300, snowballArc: 0.6, snowballMaxConcurrent: 2, telegraphMs: 260, throwCooldownMs: 900, allowBounce: true, bounceLoss: 0.5)
}


