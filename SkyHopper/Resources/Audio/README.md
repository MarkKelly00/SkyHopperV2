# SkyHopper Audio Files

This directory contains all audio files used in the SkyHopper game.

## Directory Structure

- `Music/`: Contains background music tracks for different map themes
- `SFX/`: Contains sound effects for game events

## Music Files

The following music files are available:

- `menu_soundtrack.wav`: Main menu music
- `city_soundtrack.wav`: Background music for city-themed maps
- `forest_soundtrack.wav`: Background music for forest-themed maps
- `mountain_soundtrack.wav`: Background music for mountain-themed maps
- `space_soundtrack.wav`: Background music for space-themed maps
- `water_soundtrack.wav`: Background music for underwater-themed maps

## Sound Effect Files

The following sound effect files are available:

- `crash_FX.mp3`: General crash sound effect used for most aircraft types
- `quack_FX.mp3`: Special crash sound effect for the duck aircraft

## Adding New Audio Files

To add new audio files:

1. Place music files in the `Music/` directory
2. Place sound effect files in the `SFX/` directory
3. Use the following naming conventions:
   - For map-specific music: `[theme_name]_soundtrack.wav`
   - For sound effects: `[effect_name]_FX.mp3`

## Implementation Details

The `AudioManager` class automatically looks for audio files in this directory structure. If a specific file is not found, it will fall back to the legacy location (`Sounds/` directory) or use system sounds as a last resort.

### Supported Audio Formats

- Music files: `.wav`, `.mp3`
- Sound effects: `.mp3`, `.wav`
