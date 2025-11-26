# Christmas Level "Santa's Flight" Implementation

## Overview
The Christmas level (id: "christmas_special", name: "Santa's Flight") is a seasonal map featuring Santa flying through Christmas-themed obstacles.

## Key Components

### 1. Player Character - Santa's Sleigh
- Located in: `CharacterManager.swift`
- Aircraft type: `.santaSleigh`
- Features:
  - Detailed pixel-art Santa in red sleigh
  - Two reindeer with animated running legs
  - Rudolph with glowing red nose (animated pulse)
  - Antlers, gift sack, and sparkle trail effect
  - Size: 90x45 pixels

### 2. Background - Dark Blue Night Sky
- Located in: `MapManager.swift` → `buildChristmasBackground()`
- Features:
  - Gradient dark blue night sky
  - 80+ twinkling stars with fade animation
  - 15 special stars with glow and sparkle rays
  - Full moon with glow and craters
  - 40 falling animated snowflakes
  - Distant snowy hills
  - Distant Christmas trees with lights
  - Aurora borealis effect (Northern Lights)
  - Snow ground with drifts

### 3. Obstacles - Christmas Trees
- Located in: `GameScene.swift` → `createObstacle()` (isChristmasLevel check)
- Features:
  - 3-layer triangular tree shape (like pyramids)
  - Pyramid-style physics body for collision
  - Gold star on top with glow animation
  - Multi-colored ornaments (red, gold, blue, silver, purple) with twinkle
  - Snow on branches
  - Brown trunk
- Small obstacles: Gift boxes or snowmen

### 4. Enemies - Evil Elves
- Located in: `GameScene.swift` → `createEvilElf()`
- Features:
  - Green tunic with belt and gold buckle
  - Evil red glowing eyes
  - Evil grin
  - Red pointy hat with white pom-pom
  - Pointy ears
  - Curly elf shoes with bells
  - Floating/bobbing animation
  - Side-to-side menacing movement
  - 40% spawn chance near trees

### 5. Collectibles - Floating Presents
- Located in: `GameScene.swift` → `createFloatingPresent()`
- Features:
  - Various color schemes (red/gold, blue/silver, green/red, purple/gold, gold/red)
  - Ribbon and bow decorations
  - Sparkle effect around present
  - Gentle floating and rotation animation
  - 50% spawn chance near trees
  - Awards 50-150 bonus points on collection
  - Festive explosion effect on collection

### 6. Audio
- Located in: `AudioManager.swift`
- Uses `holiday_soundtrack.wav` from `Audio/SFX/` folder
- Collection sound plays when presents are collected

## Physics Categories
- Evil elves use `obstacleCategory` (collision = game over)
- Presents use `powerUpCategory` (collection = bonus points)

## Level Data
- Difficulty: 3
- Gap size: 120
- Speed: 135
- Power-up frequency: 5.0 seconds
- Special mechanics: movingObstacles, fogEffects
- Unlock requirement: Seasonal (December)