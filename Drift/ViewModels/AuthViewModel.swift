import Foundation
import AuthenticationServices
import CryptoKit

@Observable
final class AuthViewModel {
    private let authService: AuthService

    var isAuthenticated: Bool { authService.isAuthenticated }
    var currentProfile: Profile? { authService.currentProfile }
    var isLoading = false
    var error: String?

    // Onboarding state
    var onboardingStep: OnboardingStep = .welcome
    var selectedInterests: Set<Category> = []
    var selectedNeighborhood: String?
    var displayName = ""
    var username = ""

    private var currentNonce: String?

    enum OnboardingStep: Int, CaseIterable {
        case welcome, interests, neighborhood, permissions, signIn
    }

    init(authService: AuthService) {
        self.authService = authService
    }

    func initialize() async {
        await authService.initialize()
    }

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
                        createdAt: .now
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
        currentNonce = sha256(nonce)
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func signOut() async {
        try? await authService.signOut()
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
