import Foundation
import AuthenticationServices
import CryptoKit
// TODO: Add GoogleSignIn SDK
// import GoogleSignIn

class AuthenticationManager: NSObject {
    static let shared = AuthenticationManager()
    
    // Current user
    private(set) var currentUser: UserProfile?
    private var authCompletion: ((Result<UserProfile, Error>) -> Void)?
    
    // Keys for UserDefaults
    private let currentUserKey = "currentUserProfile"
    private let isAuthenticatedKey = "isAuthenticated"
    
    enum AuthError: LocalizedError {
        case invalidCredentials
        case usernameTaken
        case emailAlreadyInUse
        case weakPassword
        case networkError
        case unknownError
        
        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Invalid username or password"
            case .usernameTaken:
                return "This username is already taken"
            case .emailAlreadyInUse:
                return "An account with this email already exists"
            case .weakPassword:
                return "Password must be at least 8 characters"
            case .networkError:
                return "Network connection error"
            case .unknownError:
                return "An unknown error occurred"
            }
        }
    }
    
    override init() {
        super.init()
        loadCurrentUser()
    }
    
    // MARK: - User Management
    
    private func loadCurrentUser() {
        if let userData = UserDefaults.standard.data(forKey: currentUserKey),
           let user = try? JSONDecoder().decode(UserProfile.self, from: userData) {
            currentUser = user
        }
    }
    
    private func saveCurrentUser(_ user: UserProfile) {
        currentUser = user
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: currentUserKey)
            UserDefaults.standard.set(true, forKey: isAuthenticatedKey)
        }
    }
    
    func logout() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: currentUserKey)
        UserDefaults.standard.set(false, forKey: isAuthenticatedKey)
    }
    
    var isAuthenticated: Bool {
        return currentUser != nil && UserDefaults.standard.bool(forKey: isAuthenticatedKey)
    }
    
    var hasCompletedOnboarding: Bool {
        return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func setOnboardingCompleted() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    // MARK: - Email Authentication
    
    func signUpWithEmail(username: String, email: String, password: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        // Validate inputs
        guard !username.isEmpty, username.count >= 3 else {
            completion(.failure(AuthError.invalidCredentials))
            return
        }
        
        guard isValidEmail(email) else {
            completion(.failure(AuthError.invalidCredentials))
            return
        }
        
        guard password.count >= 8 else {
            completion(.failure(AuthError.weakPassword))
            return
        }
        
        // Check if username is taken (in real app, this would be a server call)
        if isUsernameTaken(username) {
            completion(.failure(AuthError.usernameTaken))
            return
        }
        
        // Create new user profile
        let newUser = UserProfile(username: username, email: email, authProvider: .email, authID: UUID().uuidString)
        
        // Save password hash (in real app, this would be handled by server)
        savePasswordHash(for: email, password: password)
        
        // Save user
        saveCurrentUser(newUser)
        UserDefaults.standard.set(true, forKey: isAuthenticatedKey)
        setOnboardingCompleted()
        completion(.success(newUser))
    }
    
    func loginWithEmail(email: String, password: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        // Verify credentials (in real app, this would be a server call)
        guard verifyPassword(for: email, password: password) else {
            completion(.failure(AuthError.invalidCredentials))
            return
        }
        
        // Load user profile (in real app, fetch from server)
        if let user = loadUserProfile(for: email) {
            saveCurrentUser(user)
            setOnboardingCompleted()
            completion(.success(user))
        } else {
            completion(.failure(AuthError.unknownError))
        }
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple(presentingViewController: UIViewController, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        authCompletion = completion
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle(presentingViewController: UIViewController, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        // Note: Requires Google Sign-In SDK setup
        // This is a placeholder implementation
        completion(.failure(AuthError.unknownError))
    }
    
    // MARK: - Helper Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isUsernameTaken(_ username: String) -> Bool {
        // In real app, check against server database
        let takenUsernames = UserDefaults.standard.stringArray(forKey: "takenUsernames") ?? []
        return takenUsernames.contains(username.lowercased())
    }
    
    private func savePasswordHash(for email: String, password: String) {
        // In real app, passwords would be hashed and stored on server
        // This is for demo purposes only
        let key = "password_\(email)"
        let passwordData = Data(password.utf8)
        let hashed = SHA256.hash(data: passwordData)
        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(hashString, forKey: key)
    }
    
    private func verifyPassword(for email: String, password: String) -> Bool {
        // In real app, verify against server
        let key = "password_\(email)"
        guard let storedHash = UserDefaults.standard.string(forKey: key) else { return false }
        
        let passwordData = Data(password.utf8)
        let hashed = SHA256.hash(data: passwordData)
        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
        
        return hashString == storedHash
    }
    
    private func loadUserProfile(for email: String) -> UserProfile? {
        // In real app, fetch from server
        // For demo, create a mock profile
        let profileKey = "profile_\(email)"
        if let profileData = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            return profile
        }
        return nil
    }
    
    // MARK: - Friend Management
    
    func sendFriendRequest(to username: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = currentUser else {
            completion(.failure(AuthError.unknownError))
            return
        }
        
        // In real app, send to server
        let request = FriendRequest(
            id: UUID().uuidString,
            fromUserId: currentUser.id,
            fromUsername: currentUser.username,
            fromAvatar: currentUser.avatarURL,
            toUserId: username, // Would be user ID in real app
            status: .pending,
            sentDate: Date()
        )
        
        // Save request locally for demo
        saveFriendRequest(request)
        completion(.success(()))
    }
    
    func searchUsers(query: String, completion: @escaping (Result<[UserProfile], Error>) -> Void) {
        // In real app, search server database
        // For demo, return mock results
        let mockUsers = [
            UserProfile(username: "Player123", email: "player123@example.com", authProvider: .email, authID: "123"),
            UserProfile(username: "GameMaster", email: "gm@example.com", authProvider: .email, authID: "456"),
            UserProfile(username: "SkyHero", email: "hero@example.com", authProvider: .email, authID: "789")
        ].filter { $0.username.lowercased().contains(query.lowercased()) }
        
        completion(.success(mockUsers))
    }
    
    private func saveFriendRequest(_ request: FriendRequest) {
        var requests = UserDefaults.standard.array(forKey: "friendRequests") as? [[String: Any]] ?? []
        if let encoded = try? JSONEncoder().encode(request),
           let dict = try? JSONSerialization.jsonObject(with: encoded) as? [String: Any] {
            requests.append(dict)
            UserDefaults.standard.set(requests, forKey: "friendRequests")
        }
    }
    
    // MARK: - Referral System
    
    func applyReferralCode(_ code: String, completion: @escaping (Result<Int, Error>) -> Void) {
        // In real app, validate with server
        // For demo, give 500 points
        if code.count == 6 {
            // Add points to user
            if let user = currentUser {
                // Would update user points here in a real app
                // For now, just save the existing user
                saveCurrentUser(user)
                completion(.success(500))
            }
        } else {
            completion(.failure(AuthError.invalidCredentials))
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            authCompletion?(.failure(AuthError.unknownError))
            return
        }
        
        let userID = appleIDCredential.user
        let email = appleIDCredential.email ?? "apple_user@icloud.com"
        let fullName = appleIDCredential.fullName
        let username = fullName?.givenName ?? "Player\(Int.random(in: 1000...9999))"
        
        // Create or update user profile
        let user = UserProfile(username: username, email: email, authProvider: .apple, authID: userID)
        saveCurrentUser(user)
        setOnboardingCompleted()
        
        authCompletion?(.success(user))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        authCompletion?(.failure(error))
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the key window using the current window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }
        
        // Fallback to first window
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }
        
        return UIWindow()
    }
}
