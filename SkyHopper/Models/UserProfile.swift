import Foundation
import UIKit

struct UserProfile: Codable {
    let id: String
    let username: String
    let email: String
    let avatarURL: String?
    let appleID: String?
    let googleID: String?
    let friends: [String] // Array of friend user IDs
    let referralCode: String
    let referralCount: Int
    let totalPoints: Int
    let dateJoined: Date
    let customAvatar: Data? // For uploaded avatars
    let privacySettings: PrivacySettings
    let region: RegionInfo?
    
    struct PrivacySettings: Codable {
        var emailVisibility: PrivacyLevel
        var mutualFriendsVisibility: PrivacyLevel
        var regionVisibility: PrivacyLevel
        
        init() {
            self.emailVisibility = .friendsOnly
            self.mutualFriendsVisibility = .everyone
            self.regionVisibility = .everyone
        }
    }
    
    enum PrivacyLevel: String, Codable {
        case everyone
        case friendsOnly
        case hidden
    }
    
    struct RegionInfo: Codable {
        let state: String?
        let country: String
    }
    
    init(username: String, email: String, authProvider: AuthProvider, authID: String) {
        self.id = UUID().uuidString
        self.username = username
        self.email = email
        self.friends = []
        self.referralCode = UserProfile.generateReferralCode()
        self.referralCount = 0
        self.totalPoints = 0
        self.dateJoined = Date()
        self.customAvatar = nil
        self.privacySettings = PrivacySettings()
        self.region = nil
        
        switch authProvider {
        case .apple:
            self.appleID = authID
            self.googleID = nil
            self.avatarURL = nil
        case .google:
            self.googleID = authID
            self.appleID = nil
            self.avatarURL = nil
        case .email:
            self.appleID = nil
            self.googleID = nil
            self.avatarURL = nil
        }
    }
    
    enum AuthProvider {
        case apple
        case google
        case email
    }
    
    static func generateReferralCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
}

// Friend request model
struct FriendRequest: Codable {
    let id: String
    let fromUserId: String
    let fromUsername: String
    let fromAvatar: String?
    let toUserId: String
    let status: RequestStatus
    let sentDate: Date
    
    enum RequestStatus: String, Codable {
        case pending
        case accepted
        case declined
    }
}

// Leaderboard entry with profile info
struct LeaderboardUser: Codable {
    let userId: String
    let username: String
    let score: Int
    let rank: Int
    let avatarURL: String?
    let customAvatar: Data?
    let isOnline: Bool
    let isFriend: Bool
    let recentActivity: Date?
    let privacySettings: UserProfile.PrivacySettings?
    let region: UserProfile.RegionInfo?
    let email: String? // Only included if privacy allows
}
