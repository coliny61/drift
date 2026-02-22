import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @Environment(AuthViewModel.self) private var viewModel

    var body: some View {
        ZStack {
            Color(hex: "0A0A0A").ignoresSafeArea()

            TabView(selection: Bindable(viewModel).onboardingStep) {
                welcomeStep.tag(AuthViewModel.OnboardingStep.welcome)
                interestsStep.tag(AuthViewModel.OnboardingStep.interests)
                neighborhoodStep.tag(AuthViewModel.OnboardingStep.neighborhood)
                permissionsStep.tag(AuthViewModel.OnboardingStep.permissions)
                signInStep.tag(AuthViewModel.OnboardingStep.signIn)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.onboardingStep)
        }
    }

    // MARK: - Welcome
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "wind")
                .font(.system(size: 60))
                .foregroundStyle(Color(hex: "FF6B35"))

            Text("Drift")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.white)

            Text("Discover your flow")
                .font(.title3)
                .foregroundStyle(Color(hex: "9CA3AF"))

            Text("Find wellness events, run clubs, sound baths, and your people across DFW")
                .font(.body)
                .foregroundStyle(Color(hex: "9CA3AF"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                viewModel.nextOnboardingStep()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "FF6B35"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Interests
    private var interestsStep: some View {
        VStack(spacing: 24) {
            Text("What are you into?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.top, 60)

            Text("Pick 3 or more")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "9CA3AF"))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(Category.allCases, id: \.self) { category in
                    let isSelected = viewModel.selectedInterests.contains(category)
                    Button {
                        if isSelected { viewModel.selectedInterests.remove(category) }
                        else { viewModel.selectedInterests.insert(category) }
                        HapticManager.selection()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.title2)
                            Text(category.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isSelected ? Color(hex: category.color).opacity(0.2) : Color(hex: "1A1A1A"))
                        .foregroundStyle(isSelected ? Color(hex: category.color) : Color(hex: "9CA3AF"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(isSelected ? Color(hex: category.color) : .clear, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            Button {
                viewModel.nextOnboardingStep()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.selectedInterests.count >= 3 ? Color(hex: "FF6B35") : Color(hex: "2A2A2A"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.selectedInterests.count < 3)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Neighborhood
    private var neighborhoodStep: some View {
        VStack(spacing: 24) {
            Text("Where in DFW?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.top, 60)

            Text("We'll show events near you")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "9CA3AF"))

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 8) {
                    ForEach(AppConstants.neighborhoods, id: \.self) { hood in
                        Button {
                            viewModel.selectedNeighborhood = hood
                            HapticManager.selection()
                        } label: {
                            Text(hood)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(viewModel.selectedNeighborhood == hood ? Color(hex: "FF6B35").opacity(0.2) : Color(hex: "1A1A1A"))
                                .foregroundStyle(viewModel.selectedNeighborhood == hood ? Color(hex: "FF6B35") : Color(hex: "9CA3AF"))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(viewModel.selectedNeighborhood == hood ? Color(hex: "FF6B35") : .clear, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }

            Button {
                viewModel.nextOnboardingStep()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "FF6B35"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Permissions
    private var permissionsStep: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                permissionItem(
                    icon: "location.fill",
                    title: "Location",
                    description: "Find events near you",
                    color: Color(hex: "60A5FA")
                )
                permissionItem(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Get reminders for events",
                    color: Color(hex: "FF6B35")
                )
            }
            .padding(.horizontal, 30)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    viewModel.nextOnboardingStep()
                } label: {
                    Text("Enable & Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "FF6B35"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    viewModel.nextOnboardingStep()
                } label: {
                    Text("Maybe Later")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "9CA3AF"))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func permissionItem(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "9CA3AF"))
            }

            Spacer()
        }
    }

    // MARK: - Sign In
    private var signInStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "wind")
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: "FF6B35"))

            Text("Join Drift")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Sign in to RSVP, follow friends, and join event chats")
                .font(.body)
                .foregroundStyle(Color(hex: "9CA3AF"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

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

            Button {
                // Skip sign in for browsing
            } label: {
                Text("Browse without account")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: "9CA3AF"))
            }
            .padding(.bottom, 40)
        }
    }
}
