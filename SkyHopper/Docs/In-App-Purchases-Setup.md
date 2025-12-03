# SkyHopper In-App Purchases Setup Guide

This document provides complete instructions for setting up In-App Purchases (IAP) for the SkyHopper game using Apple's StoreKit 2.

## Overview

SkyHopper uses **Consumable** in-app purchases for coin packs and a **Non-Consumable** purchase for removing ads.

### Product IDs

| Product ID | Type | Price (USD) | Description |
|------------|------|-------------|-------------|
| `com.skyhopper.coins.small` | Consumable | $0.99 | 500 coins |
| `com.skyhopper.coins.medium` | Consumable | $2.99 | 1,500 coins |
| `com.skyhopper.coins.large` | Consumable | $9.99 | 5,000 coins |
| `com.skyhopper.coins.mega` | Consumable | $19.99 | 12,000 coins |
| `com.skyhopper.removeads` | Non-Consumable | $2.99 | Remove all ads |

---

## Part 1: Xcode Configuration

### Step 1: Enable StoreKit Capability

1. Open your project in Xcode
2. Select the **SkyHopper** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **In-App Purchase**

### Step 2: Configure StoreKit Testing

1. In Xcode, go to **Product → Scheme → Edit Scheme**
2. Select **Run** from the left sidebar
3. Go to the **Options** tab
4. Under **StoreKit Configuration**, select `Configuration.storekit`
5. Click **Close**

This allows you to test purchases without connecting to App Store Connect.

### Step 3: Update Bundle Identifier

Make sure the product IDs in `StoreKitManager.swift` match your bundle identifier pattern:

```swift
// If your bundle ID is: com.yourcompany.skyhopper
// Update the ProductID enum in StoreKitManager.swift:
enum ProductID: String, CaseIterable {
    case coinsSmall = "com.yourcompany.skyhopper.coins.small"
    case coinsMedium = "com.yourcompany.skyhopper.coins.medium"
    // ... etc
}
```

---

## Part 2: App Store Connect Setup

### Step 1: Create Your App (if not already done)

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in your app details

### Step 2: Create In-App Purchases

1. Select your app in App Store Connect
2. Go to **Monetization** → **In-App Purchases**
3. Click the **+** button to add a new product

#### For Each Coin Pack (Consumable):

1. **Type**: Select **Consumable**
2. **Reference Name**: `Coins - Small Pack` (internal use only)
3. **Product ID**: `com.skyhopper.coins.small`
4. Click **Create**

After creation, configure:

1. **Availability**: Set to your target countries
2. **Price Schedule**:
   - Click **Add Pricing**
   - Select **United States** as base country
   - Choose the appropriate price tier:
     - Small Pack: Tier 1 ($0.99)
     - Medium Pack: Tier 3 ($2.99)
     - Large Pack: Tier 10 ($9.99)
     - Mega Pack: Tier 20 ($19.99)

3. **Localizations**:
   - Add at least **English (U.S.)**
   - **Display Name**: `Small Pack`
   - **Description**: `500 coins to spend in the game`

4. **Review Information**:
   - Upload a screenshot showing the purchase UI
   - Add review notes if needed

5. Set status to **Ready to Submit**

Repeat for all coin packs with appropriate values.

#### For Remove Ads (Non-Consumable):

1. **Type**: Select **Non-Consumable**
2. **Reference Name**: `Remove Ads`
3. **Product ID**: `com.skyhopper.removeads`
4. **Family Sharing**: Enable (recommended)
5. Configure pricing, localizations, and review info as above

### Step 3: Submit IAPs with Your App

1. Go to your app's **App Store** tab
2. Create a new version or select an existing one
3. Scroll to **In-App Purchases and Subscriptions**
4. Click the **+** to add your IAPs
5. Select all products you want to include
6. Submit with your app for review

---

## Part 3: Testing

### Testing in Xcode (Sandbox)

1. Run the app on a simulator or device
2. Open the Shop scene
3. Tap any coin pack to test purchasing
4. Purchases are simulated—no real money is charged

### Testing with Sandbox Accounts

For device testing without the StoreKit configuration file:

1. In App Store Connect, go to **Users and Access** → **Sandbox** → **Testers**
2. Create a sandbox tester account
3. On your test device:
   - Sign out of your regular Apple ID in Settings → App Store
   - Run the app and attempt a purchase
   - Sign in with the sandbox account when prompted

### Transaction Debugging

In Xcode's **Debug Navigator**, you can:
- View transaction history
- Simulate purchase failures
- Test restore purchases
- Clear purchase history

---

## Part 4: Code Architecture

### StoreKitManager.swift

The `StoreKitManager` class handles all IAP operations:

```swift
// Singleton access
let store = StoreKitManager.shared

// Load products from App Store
await store.loadProducts()

// Purchase a product
let success = await store.purchase(productID: .coinsSmall)

// Restore purchases (for non-consumables)
await store.restorePurchases()

// Check if ads are removed
if store.hasRemovedAds {
    // Hide ads
}
```

### ShopScene Integration

The `ShopScene` automatically:
1. Loads products on scene entry
2. Displays real prices from the App Store
3. Handles purchase flow with loading indicators
4. Shows success/failure messages
5. Updates currency display after purchases

### Delegate Methods

Implement `StoreKitManagerDelegate` for custom handling:

```swift
func purchaseDidComplete(productID: String, success: Bool) {
    // Handle purchase completion
}

func purchaseDidDeliver(productID: String, coins: Int) {
    // Handle product delivery
}
```

---

## Part 5: Best Practices

### Security

1. **Never trust the client**: Validate purchases server-side for high-value items
2. **Use App Store Server Notifications**: For real-time transaction updates
3. **Implement receipt validation**: For additional security (optional for consumables)

### User Experience

1. Always show a loading indicator during purchases
2. Handle all error cases gracefully
3. Provide a "Restore Purchases" button (required by App Review)
4. Show clear pricing before purchase confirmation

### App Review Guidelines

1. ✅ All IAPs must be functional before submission
2. ✅ Prices must be displayed before purchase
3. ✅ Restore Purchases must be available
4. ✅ Virtual currency cannot be transferred outside the app
5. ✅ Screenshots must show actual purchase UI

---

## Troubleshooting

### Products Not Loading

1. Verify product IDs match exactly (case-sensitive)
2. Check that IAPs are in "Ready to Submit" status
3. Ensure "Paid Applications" agreement is accepted in App Store Connect
4. Wait 24-48 hours for new IAPs to propagate

### Purchases Failing

1. Check console for StoreKit errors
2. Verify device is signed into an Apple ID
3. Test with sandbox account on device
4. Ensure device has internet connectivity

### StoreKit Configuration Not Working

1. Verify scheme is configured to use the .storekit file
2. Clean build folder (Cmd+Shift+K)
3. Delete derived data and rebuild

---

## Quick Reference

### File Locations

| File | Purpose |
|------|---------|
| `Managers/StoreKitManager.swift` | IAP logic and StoreKit 2 integration |
| `Scenes/ShopScene.swift` | Shop UI with real purchases |
| `Configuration.storekit` | Local testing configuration |

### Product ID Pattern

```
com.skyhopper.{category}.{item}
```

Examples:
- `com.skyhopper.coins.small`
- `com.skyhopper.coins.mega`
- `com.skyhopper.removeads`

---

## Resources

- [Apple StoreKit Documentation](https://developer.apple.com/documentation/storekit)
- [App Store Connect Help: In-App Purchases](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases)
- [StoreKit 2 WWDC Session](https://developer.apple.com/videos/play/wwdc2021/10114/)
- [App Review Guidelines - In-App Purchase](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)

