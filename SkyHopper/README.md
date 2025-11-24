# SkyHopper 🐦

A modern, addictive endless runner game for iOS featuring stunning visuals, immersive audio, and comprehensive social features. Built with Swift and SpriteKit.

![SkyHopper Banner](https://via.placeholder.com/800x200/1a1a1a/ffffff?text=SkyHopper+-+Endless+Runner)

## ✨ Features

### 🎮 Core Gameplay
- **Endless Runner Mechanics**: Classic tap-to-jump gameplay with increasing difficulty
- **Multiple Characters**: Unlock and play as different characters (Duck, Bird, Dragon, Biplane, Jet, Helicopter, UFO, Rocket)
- **Diverse Environments**: City, Forest, Mountain, Space, Underwater, Desert themes
- **Power-ups & Hazards**: Collect coins, gems, and power-ups while avoiding obstacles

### 👥 Social Features
- **User Authentication**: Sign up/login with email or Apple Sign-In
- **Friend System**: Add friends, view leaderboards, send friend requests
- **Referral Program**: Earn rewards by inviting friends with unique referral codes
- **Global Leaderboards**: Compete with players worldwide via Game Center

### 🏆 Achievements & Progress
- **Achievement System**: Track progress across multiple categories (Maps Played, High Scores, Coins Earned, Friends Referred)
- **Character Unlocks**: Unlock new characters as you progress
- **Currency System**: Earn and spend in-game currency in the shop

### 🎨 Modern UI/UX
- **Glass Morphism Design**: Modern iOS design with glass effects and smooth animations
- **Profile Management**: Comprehensive profile settings with avatar upload
- **Tabbed Interface**: Clean navigation between Profile, Achievements, and Referrals
- **Responsive Layout**: Optimized for all iOS device sizes

### 🎵 Audio Experience
- **Dynamic Soundtrack**: Theme-specific music that adapts to your environment
- **Character-Specific SFX**: Unique crash sounds for each character
- **8-bit Style Audio**: Retro game audio with modern production quality

## 🚀 Installation

### Prerequisites
- **Xcode 15.0+**
- **iOS 15.0+** deployment target
- **macOS Ventura 13.0+**
- **Apple Developer Account** (for Game Center and App Store deployment)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/MarkKelly00/SkyHopperV2.git
   cd SkyHopper
   ```

2. **Open in Xcode**
   ```bash
   open SkyHopper.xcodeproj
   ```

3. **Configure Game Center**
   - Enable Game Center capability in Xcode
   - Update `GameKit-Info.plist` with your app's bundle identifier
   - Configure leaderboards and achievements in App Store Connect

4. **Add Audio Assets** (Optional)
   - Place sound effects in the `Sounds/` directory
   - Place music tracks in `Audio/Music/` and `Audio/SFX/` directories
   - See [Audio Implementation Guide](Docs/Audio-Implementation.md) for details

5. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd + R` to build and run

## 📱 Game Structure

```
SkyHopper/
├── Controllers/
│   ├── AppDelegate.swift          # App lifecycle management
│   └── GameViewController.swift   # Main game view controller
├── Scenes/
│   ├── GameScene.swift            # Core gameplay scene
│   ├── MainMenuScene.swift        # Main menu interface
│   ├── LeaderboardScene.swift     # Leaderboards display
│   ├── AuthenticationScene.swift  # User authentication
│   ├── ProfileSettingsScene.swift # Profile management
│   └── ShopScene.swift            # In-game shop
├── Managers/
│   ├── AudioManager.swift         # Audio system management
│   ├── GameCenterManager.swift    # Game Center integration
│   ├── AchievementManager.swift   # Achievement tracking
│   ├── AuthenticationManager.swift # User authentication
│   └── CurrencyManager.swift      # Currency system
├── Models/
│   ├── PlayerData.swift           # Player statistics
│   ├── LevelData.swift            # Level configuration
│   └── UserProfile.swift          # User profile data
├── Utilities/
│   ├── Extensions.swift           # Swift extensions
│   ├── LightingSystem.swift       # Visual effects
│   └── SafeAreaLayout.swift       # UI layout helpers
├── Audio/
│   ├── Music/                     # Background music tracks
│   └── SFX/                       # Sound effects
└── Docs/                          # Documentation and guides
```

## 🎯 Game Mechanics

### Controls
- **Tap**: Make character jump
- **Hold**: Extended jump for certain characters
- **Swipe**: Navigate menus and UI

### Characters
- **Duck**: Basic character, easy to control
- **Bird/Dragon**: Flying characters with unique mechanics
- **Biplane/Jet**: Aircraft with momentum-based physics
- **Helicopter/UFO**: Advanced vehicles with special abilities
- **Rocket**: High-speed character with boost mechanics

### Scoring System
- **Distance**: Points based on distance traveled
- **Coins**: Collectible currency scattered throughout levels
- **Gems**: Rare collectibles worth bonus points
- **Multipliers**: Chain collections for score bonuses

## 🔧 Development

### Key Technologies
- **Swift 5.9+**: Modern Swift with latest language features
- **SpriteKit**: 2D game framework for smooth gameplay
- **GameKit**: Apple Game Center integration
- **UIKit**: Native iOS UI components
- **Core Animation**: Smooth visual effects and transitions

### Architecture Patterns
- **MVC**: Model-View-Controller for scene management
- **Manager Pattern**: Centralized systems (Audio, Game Center, etc.)
- **Singleton Pattern**: Shared instances for global systems
- **Protocol Extensions**: Clean, modular code organization

### Performance Optimizations
- **Object Pooling**: Reuse game objects to reduce memory allocation
- **Texture Atlases**: Optimized sprite rendering
- **Background Processing**: Async operations for heavy tasks
- **Memory Management**: Proper cleanup and weak references

## 📚 Documentation

- [Audio Implementation Guide](Docs/Audio-Implementation.md) - Adding custom audio assets
- [GameKit Setup Guide](Docs/GameKit-Setup.md) - Game Center configuration
- [UI Regression Fixes](Docs/README-UI-Regression.md) - UI debugging and fixes
- [Changes Summary](CHANGES-SUMMARY.md) - Recent updates and improvements
- [Fixes Summary](FIXES-SUMMARY.md) - Bug fixes and patches
- [Redesign Summary](REDESIGN-SUMMARY.md) - Major UI/UX improvements

## 🐛 Troubleshooting

### Common Issues

**App crashes on leaderboard access**
- Ensure Game Center is properly configured
- Check `scrollContainer` initialization in `ModernLeaderboardScene`

**Authentication flow not working**
- Verify `hasCompletedOnboarding` flag is set after signup
- Check `AuthenticationManager` configuration

**Audio not playing**
- Confirm audio files are in correct directories
- Check `AudioManager` initialization

### Debug Features
- Enable debug menu in `DebugMenu.swift` for development tools
- Use `UILinter.swift` for UI validation
- Check console logs for detailed error information

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Swift naming conventions
- Add documentation for new features
- Test on multiple device sizes
- Ensure Game Center compatibility
- Update README for significant changes

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with SpriteKit and Apple's Game frameworks
- Audio assets created with retro gaming inspiration
- UI design inspired by modern iOS aesthetics
- Special thanks to the iOS development community

## 📞 Support

For support, bug reports, or feature requests:
- Create an issue on GitHub
- Check the documentation in the `Docs/` folder
- Review recent changes in the summary files

---

**Happy Hopping!** 🐦✨
