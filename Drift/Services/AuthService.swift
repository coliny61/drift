import Foundation
import Supabase
import AuthenticationServices

@Observable
final class AuthService {
    private let client: SupabaseClient

    var currentUser: User?
    var currentProfile: Profile?
    var isAuthenticated: Bool { currentUser != nil }
    var isLoading = false

    init(client: SupabaseClient) {
        self.client = client
    }

    func initialize() async {
        do {
            let session = try await client.auth.session
            currentUser = session.user
            if let userId = currentUser?.id {
                await fetchProfile(userId: userId)
            }
        } catch {
            currentUser = nil
        }
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        currentUser = session.user
        await fetchProfile(userId: session.user.id)
    }

    func signUpWithEmail(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let response = try await client.auth.signUp(email: email, password: password)
        currentUser = response.user
    }

    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let session = try await client.auth.signIn(email: email, password: password)
        currentUser = session.user
        await fetchProfile(userId: session.user.id)
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
        currentProfile = nil
    }

    func fetchProfile(userId: UUID) async {
        do {
            let profile: Profile = try await client.from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            currentProfile = profile
        } catch {
            print("Error fetching profile: \(error)")
        }
    }

    func createProfile(_ profile: Profile) async throws {
        try await client.from("profiles")
            .insert(profile)
            .execute()
        currentProfile = profile
    }

    func updateProfile(_ profile: Profile) async throws {
        try await client.from("profiles")
            .update(profile)
            .eq("id", value: profile.id.uuidString)
            .execute()
        currentProfile = profile
    }

    func uploadAvatar(userId: UUID, imageData: Data) async throws -> String {
        try await StorageService.uploadAvatar(client: client, userId: userId, imageData: imageData)
    }
}
