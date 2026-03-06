import SwiftUI

struct SignInView: View {
    @Environment(AuthViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "wind")
                .font(.system(size: 50))
                .foregroundStyle(AppConstants.Colors.accent)

            Text("Drift")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)

            Text("Welcome back")
                .font(.title3)
                .foregroundStyle(AppConstants.Colors.textSecondary)

            Spacer()

            // Email form
            VStack(spacing: 14) {
                TextField("Email", text: Bindable(viewModel).email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(AppConstants.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)

                SecureField("Password", text: Bindable(viewModel).password)
                    .textContentType(.password)
                    .padding(14)
                    .background(AppConstants.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 24)

            if let error = viewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(AppConstants.Colors.error)
                    .padding(.horizontal)
            }

            Button {
                Task {
                    await viewModel.signInWithEmail()
                    if viewModel.isAuthenticated {
                        dismiss()
                    }
                }
            } label: {
                Text("Sign In")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppConstants.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .opacity(viewModel.isLoading ? 0.6 : 1)
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 40)
        }
        .background(AppConstants.Colors.background)
    }
}
