import Foundation
import AuthenticationServices
import CryptoKit
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

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

    /// Notification name for profile updates (e.g., avatar change)
    static let profileDidUpdateNotification = Notification.Name("AuthenticationManagerProfileDidUpdate")
    
    /// Persist a custom avatar image for the signed-in user.
    func updateCustomAvatar(_ data: Data?) {
        guard var user = currentUser else { return }
        user.customAvatar = data
        saveCurrentUser(user)
        
        // Post notification so other scenes (like Leaderboard) can refresh
        NotificationCenter.default.post(name: AuthenticationManager.profileDidUpdateNotification, object: nil)
    }
    
    func logout() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: currentUserKey)
        UserDefaults.standard.set(false, forKey: isAuthenticatedKey)
    }
    
    var isAuthenticated: Bool {
        return currentUser != nil && UserDefaults.standard.bool(forKey: isAuthenticatedKey)
    }
    
    var isGuest: Bool {
        return currentUser?.isGuestUser ?? false
    }
    
    var hasCompletedOnboarding: Bool {
        return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func setOnboardingCompleted() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    /// Create a local-only guest profile so users can reach gameplay without registration.
    func continueAsGuest(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        let guest = UserProfile.guestProfile()
        saveCurrentUser(guest)
        UserDefaults.standard.set(true, forKey: isAuthenticatedKey)
        setOnboardingCompleted()
        completion(.success(guest))
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
        #if canImport(GoogleSignIn) && canImport(FirebaseCore)
        // Get client ID from Firebase configuration (set up in AppDelegate)
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(NSError(domain: "GoogleSignIn", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "Google Sign-In is not configured. Please ensure GoogleService-Info.plist is added to your project and Firebase is initialized."])))
            return
        }
        
        // Ensure Google Sign-In is configured (should already be done in AppDelegate)
        if GIDSignIn.sharedInstance.configuration == nil {
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(self?.mapGoogleError(error) ?? error))
                }
                return
            }
            
            guard let user = result?.user,
                  let userID = user.userID else {
                DispatchQueue.main.async {
                    completion(.failure(AuthError.unknownError))
                }
                return
            }
            
            // Extract user information
            let email = user.profile?.email ?? "google_user@gmail.com"
            let fullName = user.profile?.name ?? "Player\(Int.random(in: 1000...9999))"
            let avatarURL = user.profile?.imageURL(withDimension: 200)?.absoluteString
            
            // Check if user already exists with this Google ID
            if let existingUser = self?.loadUserByGoogleID(userID) {
                self?.saveCurrentUser(existingUser)
                self?.setOnboardingCompleted()
                DispatchQueue.main.async {
                    completion(.success(existingUser))
                }
                return
            }
            
            // Create new user profile
            var newUser = UserProfile(username: fullName, email: email, authProvider: .google, authID: userID)
            
            // Download and save avatar if available
            if let avatarURLString = avatarURL, let url = URL(string: avatarURLString) {
                self?.downloadAvatar(from: url) { avatarData in
                    if let data = avatarData {
                        newUser.customAvatar = data
                    }
                    self?.saveUserProfile(newUser)
                    self?.saveCurrentUser(newUser)
                    self?.setOnboardingCompleted()
                    DispatchQueue.main.async {
                        completion(.success(newUser))
                    }
                }
            } else {
                self?.saveUserProfile(newUser)
                self?.saveCurrentUser(newUser)
                self?.setOnboardingCompleted()
                DispatchQueue.main.async {
                    completion(.success(newUser))
                }
            }
        }
        #else
        // Google Sign-In SDK or Firebase not available - show user-friendly error
        completion(.failure(NSError(domain: "GoogleSignIn", code: -1, 
            userInfo: [NSLocalizedDescriptionKey: "Google Sign-In is not available. Please ensure Firebase and GoogleSignIn SDKs are installed."])))
        #endif
    }
    
    /// Maps Google Sign-In errors to user-friendly messages
    private func mapGoogleError(_ error: Error) -> Error {
        let nsError = error as NSError
        let message: String
        
        switch nsError.code {
        case -5: // GIDSignInError.canceled
            message = "Sign in was canceled. Please try again."
        case -4: // GIDSignInError.hasNoAuthInKeychain
            message = "No previous sign-in found. Please sign in again."
        case -7: // GIDSignInError.unknown
            message = "An unknown error occurred with Google Sign-In."
        default:
            message = "Google Sign-In failed. Please check your internet connection and try again."
        }
        
        return NSError(domain: "GoogleSignIn", code: nsError.code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
    /// Downloads avatar image from URL
    private func downloadAvatar(from url: URL, completion: @escaping (Data?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, error == nil {
                completion(data)
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    /// Loads existing user by Google ID
    private func loadUserByGoogleID(_ googleID: String) -> UserProfile? {
        let profileKey = "google_profile_\(googleID)"
        if let profileData = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            return profile
        }
        return nil
    }
    
    /// Saves user profile to persistent storage (linked by auth ID)
    private func saveUserProfile(_ user: UserProfile) {
        // Save by email for email auth
        let emailKey = "profile_\(user.email)"
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: emailKey)
        }
        
        // Also save by Apple ID if present
        if let appleID = user.appleID {
            let appleKey = "apple_profile_\(appleID)"
            if let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: appleKey)
            }
        }
        
        // Also save by Google ID if present
        if let googleID = user.googleID {
            let googleKey = "google_profile_\(googleID)"
            if let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: googleKey)
            }
        }
        
        // Add username to taken usernames list
        var takenUsernames = UserDefaults.standard.stringArray(forKey: "takenUsernames") ?? []
        if !takenUsernames.contains(user.username.lowercased()) {
            takenUsernames.append(user.username.lowercased())
            UserDefaults.standard.set(takenUsernames, forKey: "takenUsernames")
        }
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
    
    /// Purges local data for account deletion (used for guests and fallback paths).
    private func purgeLocalAccountData(email: String?) {
        // Remove stored password for the email if present
        if let email = email {
            let key = "password_\(email)"
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.removeObject(forKey: "friendRequests")
        UserDefaults.standard.removeObject(forKey: "takenUsernames")
        logout()
    }
    
    /// Delete the signed-in account. Uses Firebase Auth if present, otherwise falls back to local deletion.
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        let email = currentUser?.email
        
        // Guest accounts only need local cleanup
        if isGuest {
            purgeLocalAccountData(email: email)
            completion(.success(()))
            return
        }
        
        #if canImport(FirebaseAuth)
        if let firebaseUser = Auth.auth().currentUser {
            firebaseUser.delete { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    self?.purgeLocalAccountData(email: email)
                    completion(.success(()))
                }
            }
            return
        }
        #endif
        
        // Fallback: remove local data
        purgeLocalAccountData(email: email)
        completion(.success(()))
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
    
    /// Get pending friend requests for the current user
    func getPendingFriendRequests() -> [FriendRequest] {
        guard let currentUser = currentUser else { return [] }
        
        let requestsData = UserDefaults.standard.array(forKey: "friendRequests") as? [[String: Any]] ?? []
        var pendingRequests: [FriendRequest] = []
        
        for dict in requestsData {
            if let data = try? JSONSerialization.data(withJSONObject: dict),
               let request = try? JSONDecoder().decode(FriendRequest.self, from: data) {
                // Return requests sent TO the current user that are still pending
                if (request.toUserId == currentUser.id || request.toUserId == currentUser.username) &&
                   request.status == .pending {
                    pendingRequests.append(request)
                }
            }
        }
        
        return pendingRequests
    }
    
    /// Respond to a friend request (accept or decline)
    func respondToFriendRequest(requestId: String, accept: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        var requestsData = UserDefaults.standard.array(forKey: "friendRequests") as? [[String: Any]] ?? []
        
        for (index, dict) in requestsData.enumerated() {
            if let data = try? JSONSerialization.data(withJSONObject: dict),
               let request = try? JSONDecoder().decode(FriendRequest.self, from: data),
               request.id == requestId {
                // Note: 'request' is intentionally a 'let' constant (not mutated)
                
                // Create updated request with new status
                let updatedRequest = FriendRequest(
                    id: request.id,
                    fromUserId: request.fromUserId,
                    fromUsername: request.fromUsername,
                    fromAvatar: request.fromAvatar,
                    toUserId: request.toUserId,
                    status: accept ? .accepted : .declined,
                    sentDate: request.sentDate
                )
                
                // Update in storage
                if let encoded = try? JSONEncoder().encode(updatedRequest),
                   let updatedDict = try? JSONSerialization.jsonObject(with: encoded) as? [String: Any] {
                    requestsData[index] = updatedDict
                    UserDefaults.standard.set(requestsData, forKey: "friendRequests")
                    
                    // If accepted, add to friends list
                    if accept {
                        addFriend(userId: request.fromUserId, username: request.fromUsername)
                    }
                    
                    completion(.success(()))
                    return
                }
            }
        }
        
        completion(.failure(AuthError.unknownError))
    }
    
    /// Add a friend to the current user's friends list
    private func addFriend(userId: String, username: String) {
        var friends = UserDefaults.standard.array(forKey: "userFriends") as? [[String: String]] ?? []
        friends.append(["userId": userId, "username": username])
        UserDefaults.standard.set(friends, forKey: "userFriends")
    }
    
    /// Get the current user's friends list
    func getFriendsList() -> [(userId: String, username: String)] {
        let friends = UserDefaults.standard.array(forKey: "userFriends") as? [[String: String]] ?? []
        return friends.compactMap { dict in
            guard let userId = dict["userId"], let username = dict["username"] else { return nil }
            return (userId: userId, username: username)
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
            DispatchQueue.main.async { [weak self] in
                self?.authCompletion?(.failure(AuthError.unknownError))
            }
            return
        }
        
        let userID = appleIDCredential.user
        
        // Check if user already exists with this Apple ID
        if let existingUser = loadUserByAppleID(userID) {
            saveCurrentUser(existingUser)
            setOnboardingCompleted()
            DispatchQueue.main.async { [weak self] in
                self?.authCompletion?(.success(existingUser))
            }
            return
        }
        
        // For new users, Apple only provides name/email on first sign-in
        // On subsequent sign-ins, these will be nil, so we generate defaults
        let email = appleIDCredential.email ?? "apple_\(userID.prefix(8))@icloud.com"
        let fullName = appleIDCredential.fullName
        let firstName = fullName?.givenName
        let lastName = fullName?.familyName
        
        // Create username from name or generate random
        let username: String
        if let first = firstName {
            if let last = lastName {
                username = "\(first) \(last.prefix(1))."
            } else {
                username = first
            }
        } else {
            username = "Player\(Int.random(in: 1000...9999))"
        }
        
        // Create new user profile and save to database
        let newUser = UserProfile(username: username, email: email, authProvider: .apple, authID: userID)
        saveUserProfile(newUser)  // Save to database
        saveCurrentUser(newUser)  // Set as current user
        setOnboardingCompleted()
        
        DispatchQueue.main.async { [weak self] in
            self?.authCompletion?(.success(newUser))
        }
    }
    
    /// Loads existing user by Apple ID
    private func loadUserByAppleID(_ appleID: String) -> UserProfile? {
        let profileKey = "apple_profile_\(appleID)"
        if let profileData = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            return profile
        }
        return nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let mapped = mapAppleError(error)
        DispatchQueue.main.async { [weak self] in
            self?.authCompletion?(.failure(mapped))
        }
    }
    
    /// Converts common Apple sign-in errors into user-friendly messages.
    private func mapAppleError(_ error: Error) -> Error {
        if let authError = error as? ASAuthorizationError {
            let message: String
            let errorCode = authError.code
            
            if errorCode == .canceled {
                message = "Sign in was canceled. Please try again."
            } else if errorCode == .failed {
                message = "Sign in with Apple failed. Please check your iCloud account and try again."
            } else if errorCode == .invalidResponse {
                message = "Invalid response from Apple ID. Please retry."
            } else if errorCode == .notHandled {
                message = "Sign in with Apple could not be completed. Please try again."
            } else if errorCode == .unknown {
                message = "An unknown Apple sign-in error occurred."
            } else if errorCode == .notInteractive {
                message = "Apple sign-in requires user interaction. Please try again."
            } else {
                message = "Sign in with Apple encountered an unexpected error."
            }
            
            return NSError(domain: "SignInWithApple", code: authError.code.rawValue, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return error
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
