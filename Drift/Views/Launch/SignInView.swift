import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "wind")
                .font(.system(size: 50))
                .foregroundStyle(Color(hex: "FF6B35"))

            Text("Drift")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)

            Text("Discover your flow")
                .font(.title3)
                .foregroundStyle(Color(hex: "9CA3AF"))

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                viewModel.prepareSignInRequest(request)
            } onCompletion: { result in
                Task { await viewModel.handleSignInWithApple(result) }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)

            if let error = viewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "EF5350"))
                    .padding(.horizontal)
            }

            Spacer().frame(height: 40)
        }
        .background(Color(hex: "0A0A0A"))
    }
}
