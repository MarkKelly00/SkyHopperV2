# Audio Implementation Guide

This guide explains how to add actual audio files to replace the fallback system sounds in SkyHopper.

## Sound Effects Structure

The game requires the following sound files to be placed in the `Sounds` directory:

### Character-Specific Crash Sounds
- `duck_crash.wav` - Quacking sound for duck crash
- `bird_crash.wav` - Squawking sound for bird/eagle crash
- `dragon_crash.wav` - Roaring sound for dragon crash
- `biplane_crash.wav` - Engine sputtering sound for biplane crash
- `jet_crash.wav` - Engine failure sound for jet crash
- `helicopter_crash.wav` - Blade failure sound for helicopter crash
- `ufo_crash.wav` - Electronic failure sound for UFO crash
- `rocket_crash.wav` - Explosion sound for rocket pack crash

### General Sound Effects
- `jump.wav` - Player jump/tap sound
- `crash.wav` - Generic crash sound
- `collect.wav` - Item collection sound
- `menu_tap.wav` - UI interaction sound
- `achievement.wav` - Achievement unlocked sound
- `game_over.wav` - Game over sound
- `power_up.wav` - Power-up activation sound
- `coin_collect.wav` - Coin collection sound
- `gem_collect.wav` - Gem collection sound
- `unlock.wav` - Unlocking new content sound

### Theme-Specific Sounds
- `explosion.wav` - Space theme obstacle hit
- `splash.wav` - Underwater theme obstacle hit
- `wind.wav` - Mountain theme wind sound
- `stargate.wav` - Stargate portal effect
- `yeti.wav` - Yeti sound effect

## Music Tracks

The game uses the following music tracks (MP3 format):

### General Music
- `main_theme.mp3` - Main game theme
- `speed_boost_theme.mp3` - Faster version for speed boost
- `retro_theme.mp3` - General retro theme

### Map-Specific Music
- `city_theme.mp3` - City theme background music
- `forest_theme.mp3` - Forest theme background music
- `mountain_theme.mp3` - Mountain theme background music
- `space_theme.mp3` - Space theme background music
- `underwater_theme.mp3` - Underwater theme background music
- `desert_theme.mp3` - Desert theme background music

### Special Themed Music
- `stargate_theme.mp3` - Dune/Stargate inspired theme for desert maps
- `arcade_theme.mp3` - Classic arcade style for city maps

### Seasonal Themes
- `halloween_theme.mp3` - Halloween seasonal theme
- `christmas_theme.mp3` - Christmas seasonal theme

## Audio File Requirements

### Sound Effects (WAV)
- Format: 16-bit PCM WAV
- Sample Rate: 44.1kHz
- Channels: Mono or Stereo
- Duration: 0.1-2 seconds (keep short for responsiveness)

### Music Tracks (MP3)
- Format: MP3
- Bitrate: 192-320kbps
- Sample Rate: 44.1kHz
- Channels: Stereo
- Duration: 30-120 seconds (with seamless looping)

## Recommended 8-bit Style Sound Resources

Here are some resources for finding 8-bit style sounds and music:

1. **Free Resources**:
   - [Freesound.org](https://freesound.org/search/?q=8-bit)
   - [OpenGameArt.org](https://opengameart.org/art-search-advanced?keys=8-bit&field_art_type_tid%5B%5D=12)
   - [itch.io Free Game Assets](https://itch.io/game-assets/free/tag-8bit)

2. **Paid Resources**:
   - [GameDev Market](https://www.gamedevmarket.net/category/audio/8-bit-chiptune/)
   - [Unity Asset Store](https://assetstore.unity.com/categories/audio/sound-fx/8-bit)
   - [Envato Elements](https://elements.envato.com/sound-effects/8-bit)

3. **Music Generation Tools**:
   - [BeepBox](https://www.beepbox.co/) - Browser-based chiptune creation
   - [FamiTracker](http://famitracker.com/) - NES/Famicom music creation
   - [Bosca Ceoil](https://boscaceoil.net/) - Simple music creation tool

## Adding Audio Files to the Project

1. Create a `Sounds` directory in the project if it doesn't exist
2. Add the audio files to this directory
3. In Xcode, right-click on the project navigator and select "Add Files to SkyHopper"
4. Navigate to the Sounds directory and select all audio files
5. Make sure "Copy items if needed" is checked
6. Select the appropriate target(s)
7. Click "Add"

The `AudioManager` class will automatically detect and use these files instead of the fallback system sounds.
