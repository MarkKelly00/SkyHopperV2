//
//  AppDelegate.swift
//  HopVerse
//
//  Created by Mark Kelly on 7/31/25.
//  Copyright © 2025 MKP LLC. All rights reserved.
//

import UIKit
import GameKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("Application launched")
        
        // Initialize managers
        _ = AudioManager.shared
        _ = PlayerData.shared
        _ = AchievementManager.shared
        _ = CurrencyManager.shared
        _ = MapManager.shared
        _ = CharacterManager.shared
        
        // Handle daily login
        PlayerData.shared.trackDailyLogin()
        
        // Configure game appearance
        configureAppAppearance()
        
        return true
    }
    
    private func configureAppAppearance() {
        // Configure app-wide UI appearance
        UINavigationBar.appearance().tintColor = UIColor(red: 0.0, green: 0.5, blue: 0.8, alpha: 1.0)
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.0, green: 0.5, blue: 0.8, alpha: 1.0)
        ]
        
        // Configure button appearance
        let buttonAppearance = UIButton.appearance()
        buttonAppearance.tintColor = UIColor(red: 0.0, green: 0.5, blue: 0.8, alpha: 1.0)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Pause the game when interrupted
        NotificationCenter.default.post(name: NSNotification.Name("AppWillResignActive"), object: nil)
        
        // Pause any ongoing audio
        AudioManager.shared.stopBackgroundMusic()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Save any game data
        PlayerData.shared.saveData()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Check for seasonal content updates
        MapManager.shared.checkForSeasonalMaps()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Resume game if needed
        NotificationCenter.default.post(name: NSNotification.Name("AppDidBecomeActive"), object: nil)
        
        // Resume audio if it was playing
        AudioManager.shared.playBackgroundMusic()
        
        // Check for daily challenges and login rewards
        if let lastDate = PlayerData.shared.lastDailyChallengeDate, !Calendar.current.isDateInToday(lastDate) {
            PlayerData.shared.generateDailyChallenges()
            
            // Set flag to show notification when menu loads
            UserDefaults.standard.set(true, forKey: "showDailyChallengeNotification")
        }
        
        // Track daily login
        PlayerData.shared.trackDailyLogin()
    }
}