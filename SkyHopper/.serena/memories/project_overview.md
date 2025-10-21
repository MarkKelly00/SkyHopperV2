# SkyHopper Project Overview

## Purpose
SkyHopper is an iOS game built with SpriteKit featuring aircraft navigation through various themed maps with obstacles, power-ups, and achievements.

## Tech Stack
- **Language**: Swift
- **Framework**: SpriteKit (iOS game development)
- **Platform**: iOS
- **Architecture**: MVC pattern with managers for different game systems

## Key Components
- **Scenes**: Game screens (MainMenu, GameScene, Achievement, etc.)
- **Managers**: Game systems (Audio, GameCenter, Currency, Achievement, etc.)
- **Models**: Data structures (PlayerData, LevelData, etc.)
- **Utilities**: Helper classes (SafeAreaLayout, UIConstants, etc.)

## Current Issues
- Leaderboard not saving high scores from game over
- Need Game Center integration for score submission with player names