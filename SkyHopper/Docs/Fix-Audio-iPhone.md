# Fixing Audio Not Playing on iPhone Device

## Problem
Audio plays in the simulator but not on physical iPhone devices (tested on iPhone 16 Pro Max with iOS 26).

## Root Cause
The Audio directory is not being included in the app bundle. The terminal log shows:
```
DEBUG: Found audio files in bundle: [list of audio files]
DEBUG: Audio directory NOT found in bundle
```

This means the audio files are in the bundle but not in the expected directory structure.

## Solution

### 1. Add Audio Folder to Xcode Project
1. Open your project in Xcode
2. Right-click on the SkyHopper folder in the project navigator
3. Select "Add Files to 'SkyHopper'..."
4. Navigate to and select the `Audio` folder
5. **IMPORTANT**: Make sure these options are selected:
   - ✅ Copy items if needed
   - ✅ Create folder references (NOT "Create groups")
   - ✅ Add to targets: SkyHopper
6. Click "Add"

### 2. Verify Bundle Resources
1. Select your project in the navigator
2. Select the SkyHopper target
3. Go to "Build Phases" tab
4. Expand "Copy Bundle Resources"
5. Verify that the Audio folder appears as a blue folder icon (not yellow)
6. If not present, click the "+" button and add the Audio folder

### 3. Clean and Rebuild
1. Product → Clean Build Folder (⇧⌘K)
2. Product → Build (⌘B)

### 4. Alternative: Individual File References
If folder references don't work:
1. Remove the Audio folder reference
2. Add each audio file individually to the project
3. Make sure they're all added to "Copy Bundle Resources"
4. Update AudioManager.swift to look for files in the root bundle instead of subdirectories

## Testing
After making these changes:
1. Build and run on your physical device
2. Check the console output - you should see:
   - "DEBUG: Audio directory exists in bundle"
   - "DEBUG: Successfully loaded [audio file] from Audio/[subdirectory]"

## Additional Troubleshooting
If audio still doesn't play:
1. Check device volume and mute switch
2. Verify audio session category is set correctly (already done in AudioManager)
3. Test with a simple AVAudioPlayer directly to isolate the issue
