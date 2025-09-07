# GameKit Setup Instructions

To properly enable Game Center functionality in SkyHopper, follow these steps in Xcode:

## 1. Enable Game Center Capability

1. Open the SkyHopper project in Xcode
2. Select the SkyHopper target
3. Go to the "Signing & Capabilities" tab
4. Click the "+" button to add a capability
5. Search for and add "Game Center"

## 2. Verify Entitlements File

The project should have a `SkyHopper.entitlements` file with the following content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.game-center</key>
    <true/>
</dict>
</plist>
```

## 3. Update Info.plist

Make sure your Info.plist includes GameKit in the required device capabilities:

```xml
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>armv7</string>
    <string>gamekit</string>
</array>
```

## 4. Link the Entitlements File in Build Settings

1. Select the SkyHopper target
2. Go to "Build Settings"
3. Search for "Code Signing Entitlements"
4. Set the value to `SkyHopper/SkyHopper.entitlements`

## 5. Ensure Proper Provisioning

1. Make sure your Apple Developer account has Game Center enabled
2. Use a provisioning profile that includes the Game Center entitlement

## 6. Testing Game Center

1. Enable Game Center in the iOS Simulator settings
2. Sign in with a test Apple ID
3. Run the app and verify that authentication succeeds

## Troubleshooting

If you see errors like:

```
ERROR: No Game Center entitlement provided by: com.makllipse.SkyHopper
Could not load services for GameKit. This likely means your game is missing the com.apple.developer.game-center entitlement.
```

Check the following:

1. Verify the entitlements file is properly linked in build settings
2. Check that the bundle identifier matches the one in your provisioning profile
3. Clean the build folder (Product > Clean Build Folder) and rebuild
4. Restart Xcode and the simulator

For more information, see the [Apple documentation](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_game-center).
