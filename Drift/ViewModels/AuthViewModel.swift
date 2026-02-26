import Foundation
import AuthenticationServices
import CryptoKit

@Observable
final class AuthViewModel {
    private let authService: AuthService

    var isAuthenticated: Bool { authService.isAuthenticated }
    var isLoading = false
    var error: String?

    // Onboarding state
    var onboardingStep: OnboardingStep = .welcome
    var selectedInterests: Set<Category> = []
    var selectedCity: String?
    var displayName = ""
    var username = ""

    // Email auth state
    var email = ""
    var password = ""
    var confirmPassword = ""
    var isSignUpMode = true

    // Backward compat
    var selectedNeighborhood: String?

    private var currentNonce: String?

    enum OnboardingStep: Int, CaseIterable {
        case welcome, interests, city, permissions, signIn
    }

    /// Returns the authenticated profile, or a local anonymous profile for browse-mode users
    var currentProfile: Profile? {
        if let profile = authService.currentProfile {
            return profile
        }
        return localProfile
    }

    /// Stable anonymous user ID persisted across launches
    var localUserId: UUID {
        let key = "drift_local_user_id"
        if let stored = UserDefaults.standard.string(forKey: key), let id = UUID(uuidString: stored) {
            return id
        }
        let newId = UUID()
        UserDefaults.standard.set(newId.uuidString, forKey: key)
        return newId
    }

    /// Local profile for non-authenticated users built from onboarding selections
    private var localProfile: Profile? {
        let hasOnboarded = UserDefaults.standard.bool(forKey: "drift_has_onboarded")
        guard hasOnboarded else { return nil }
        return Profile(
            id: localUserId,
            username: "drifter",
            displayName: "Drifter",
            bio: nil,
            avatarUrl: nil,
            interests: selectedInterests.map(\.slug),
            locationLat: nil,
            locationLng: nil,
            neighborhood: selectedNeighborhood,
            streakCount: 0,
            eventsAttended: 0,
            createdAt: .now,
            city: selectedCity
        )
    }

    init(authService: AuthService) {
        self.authService = authService
        // Restore interests from onboarding
        if let saved = UserDefaults.standard.array(forKey: "drift_selected_interests") as? [String] {
            selectedInterests = Set(saved.compactMap { slug in Category.allCases.first { $0.slug == slug } })
        }
        selectedNeighborhood = UserDefaults.standard.string(forKey: "drift_selected_neighborhood")
        selectedCity = UserDefaults.standard.string(forKey: "drift_selected_city")
    }

    func initialize() async {
        await authService.initialize()
    }

    // MARK: - Email Auth

    func signUpWithEmail() async {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Email and password are required"
            return
        }
        guard password == confirmPassword else {
            error = "Passwords don't match"
            return
        }
        guard password.count >= 6 else {
            error = "Password must be at least 6 characters"
            return
        }

        isLoading = true
        error = nil
        do {
            try await authService.signUpWithEmail(email: email, password: password)

            // Create profile for new user
            if let user = authService.currentUser {
                let profile = Profile(
                    id: user.id,
                    username: "user_\(UUID().uuidString.prefix(8))",
                    displayName: displayName.isEmpty ? "Drifter" : displayName,
                    bio: nil,
                    avatarUrl: nil,
                    interests: selectedInterests.map(\.slug),
                    locationLat: nil,
                    locationLng: nil,
                    neighborhood: selectedNeighborhood,
                    streakCount: 0,
                    eventsAttended: 0,
                    createdAt: .now,
                    city: selectedCity
                )
                try await authService.createProfile(profile)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func signInWithEmail() async {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Email and password are required"
            return
        }

        isLoading = true
        error = nil
        do {
            try await authService.signInWithEmail(email: email, password: password)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Apple Sign In

    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let idTokenData = credential.identityToken,
                  let idToken = String(data: idTokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                error = "Failed to get Apple ID credentials"
                return
            }

            isLoading = true
            do {
                try await authService.signInWithApple(idToken: idToken, nonce: nonce)

                // Create profile if new user
                if authService.currentProfile == nil, let user = authService.currentUser {
                    let profile = Profile(
                        id: user.id,
                        username: username.isEmpty ? "user_\(UUID().uuidString.prefix(8))" : username,
                        displayName: displayName.isEmpty ? (credential.fullName?.givenName ?? "Drifter") : displayName,
                        bio: nil,
                        avatarUrl: nil,
                        interests: selectedInterests.map(\.slug),
                        locationLat: nil,
                        locationLng: nil,
                        neighborhood: selectedNeighborhood,
                        streakCount: 0,
                        eventsAttended: 0,
                        createdAt: .now,
                        city: selectedCity
                    )
                    try await authService.createProfile(profile)
                }
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false

        case .failure(let error):
            self.error = error.localizedDescription
        }
    }

    func prepareSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        let hashedNonce = sha256(nonce)
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce
    }

    func updateProfile(_ profile: Profile) async throws {
        try await authService.updateProfile(profile)
    }

    func signOut() async {
        try? await authService.signOut()
        email = ""
        password = ""
        confirmPassword = ""
    }

    func nextOnboardingStep() {
        if let nextIndex = OnboardingStep(rawValue: onboardingStep.rawValue + 1) {
            onboardingStep = nextIndex
        }
    }

    // MARK: - Nonce helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess { fatalError("Unable to generate nonce") }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
