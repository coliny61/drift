import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @Environment(AuthViewModel.self) private var viewModel
    var onDismiss: () -> Void

    private let totalSteps = AuthViewModel.OnboardingStep.allCases.count

    var body: some View {
        ZStack {
            // Background with subtle gradient
            AppConstants.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Step indicator dots (hidden on welcome)
                if viewModel.onboardingStep != .welcome {
                    stepIndicator
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }

                TabView(selection: Bindable(viewModel).onboardingStep) {
                    welcomeStep.tag(AuthViewModel.OnboardingStep.welcome)
                    interestsStep.tag(AuthViewModel.OnboardingStep.interests)
                    neighborhoodStep.tag(AuthViewModel.OnboardingStep.neighborhood)
                    permissionsStep.tag(AuthViewModel.OnboardingStep.permissions)
                    signInStep.tag(AuthViewModel.OnboardingStep.signIn)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.onboardingStep)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(AuthViewModel.OnboardingStep.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step == viewModel.onboardingStep
                          ? AppConstants.Colors.accent
                          : AppConstants.Colors.secondaryBackground)
                    .frame(width: step == viewModel.onboardingStep ? 24 : 8, height: 4)
                    .animation(.spring(duration: 0.3), value: viewModel.onboardingStep)
            }
        }
    }

    // MARK: - Welcome

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero area with gradient backdrop
            ZStack {
                // Ambient glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppConstants.Colors.accent.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 180
                        )
                    )
                    .frame(width: 360, height: 360)

                VStack(spacing: 20) {
                    // App icon
                    Image(systemName: "wind")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(AppConstants.Colors.accent)
                        .symbolEffect(.pulse, options: .repeating)

                    Text("Drift")
                        .font(.system(size: 52, weight: .bold, design: .default))
                        .foregroundStyle(.white)

                    Text("Discover your flow")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(AppConstants.Colors.textSecondary)
                }
            }

            Spacer()

            // Feature highlights
            VStack(spacing: 16) {
                featureRow(icon: "figure.run", text: "Run clubs, yoga, sound baths & more", color: AppConstants.Colors.accent)
                featureRow(icon: "mappin.circle.fill", text: "Events across DFW, near you", color: Color(hex: "60A5FA"))
                featureRow(icon: "person.2.fill", text: "Find your people, build your streak", color: Color(hex: "81C784"))
            }
            .padding(.horizontal, 32)

            Spacer()

            // CTA
            primaryButton("Get Started") {
                viewModel.nextOnboardingStep()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private func featureRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppConstants.Colors.textSecondary)

            Spacer()
        }
    }

    // MARK: - Interests

    private var interestsStep: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("What are you into?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Pick 3 or more to personalize your feed")
                    .font(.subheadline)
                    .foregroundStyle(AppConstants.Colors.textSecondary)
            }
            .padding(.top, 32)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                    ForEach(Category.allCases, id: \.self) { category in
                        let isSelected = viewModel.selectedInterests.contains(category)
                        let catColor = Color(hex: category.color)

                        Button {
                            withAnimation(.spring(duration: 0.2)) {
                                if isSelected { viewModel.selectedInterests.remove(category) }
                                else { viewModel.selectedInterests.insert(category) }
                            }
                            HapticManager.selection()
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: category.icon)
                                    .font(.title3)
                                    .symbolEffect(.bounce, value: isSelected)

                                Text(category.displayName)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(isSelected ? catColor.opacity(0.15) : AppConstants.Colors.cardBackground)
                            .foregroundStyle(isSelected ? catColor : AppConstants.Colors.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                                    .strokeBorder(isSelected ? catColor.opacity(0.5) : .clear, lineWidth: 1.5)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }

            // Selection count + CTA
            VStack(spacing: 12) {
                if !viewModel.selectedInterests.isEmpty {
                    Text("\(viewModel.selectedInterests.count) selected")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(viewModel.selectedInterests.count >= 3
                                         ? AppConstants.Colors.accent
                                         : AppConstants.Colors.textTertiary)
                }

                primaryButton("Continue") {
                    UserDefaults.standard.set(viewModel.selectedInterests.map(\.slug), forKey: "drift_selected_interests")
                    viewModel.nextOnboardingStep()
                }
                .opacity(viewModel.selectedInterests.count >= 3 ? 1 : 0.4)
                .disabled(viewModel.selectedInterests.count < 3)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Neighborhood

    private var neighborhoodStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Location hero
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "60A5FA").opacity(0.12), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)

                VStack(spacing: 20) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(Color(hex: "60A5FA"))
                        .symbolEffect(.pulse, options: .repeating)

                    Text("Dallas Fort Worth")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Events from Deep Ellum to Fort Worth,\nUptown to Frisco — we've got DFW covered")
                        .font(.subheadline)
                        .foregroundStyle(AppConstants.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }

            Spacer()

            // DFW neighborhood chips preview
            VStack(spacing: 12) {
                Text("Neighborhoods we cover")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(AppConstants.Colors.textTertiary)

                flowLayout(items: ["Deep Ellum", "Uptown", "Bishop Arts", "Oak Lawn", "Knox", "Frisco", "Fort Worth", "Lakewood"])
            }
            .padding(.horizontal, 24)

            Spacer()

            primaryButton("Continue") {
                viewModel.selectedNeighborhood = "Dallas Fort Worth"
                UserDefaults.standard.set("Dallas Fort Worth", forKey: "drift_selected_neighborhood")
                viewModel.nextOnboardingStep()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private func flowLayout(items: [String]) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(items.prefix(4), id: \.self) { item in
                    Text(item)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppConstants.Colors.cardBackground)
                        .foregroundStyle(AppConstants.Colors.textSecondary)
                        .clipShape(Capsule())
                }
            }
            HStack(spacing: 8) {
                ForEach(items.suffix(4), id: \.self) { item in
                    Text(item)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppConstants.Colors.cardBackground)
                        .foregroundStyle(AppConstants.Colors.textSecondary)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Permissions

    private var permissionsStep: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Stay in the loop")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Enable to get the full Drift experience")
                    .font(.subheadline)
                    .foregroundStyle(AppConstants.Colors.textSecondary)
            }
            .padding(.top, 32)

            Spacer()

            VStack(spacing: 16) {
                permissionCard(
                    icon: "location.fill",
                    title: "Location",
                    description: "Find events near you and get directions",
                    color: Color(hex: "60A5FA")
                )
                permissionCard(
                    icon: "bell.badge.fill",
                    title: "Notifications",
                    description: "Reminders before events you RSVP to",
                    color: AppConstants.Colors.accent
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                primaryButton("Enable & Continue") {
                    viewModel.nextOnboardingStep()
                }

                Button {
                    viewModel.nextOnboardingStep()
                } label: {
                    Text("Maybe later")
                        .font(.subheadline)
                        .foregroundStyle(AppConstants.Colors.textTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private func permissionCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(AppConstants.Colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(AppConstants.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
    }

    // MARK: - Sign In

    private var signInStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppConstants.Colors.accent.opacity(0.12), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)

                VStack(spacing: 16) {
                    Image(systemName: "wind")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(AppConstants.Colors.accent)
                        .symbolEffect(.pulse, options: .repeating)

                    Text("Join Drift")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Sign in to RSVP, follow friends,\nand join event chats")
                        .font(.subheadline)
                        .foregroundStyle(AppConstants.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }

            Spacer()

            // Social proof
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                Text("Wellness community in DFW")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(AppConstants.Colors.textTertiary)
            .padding(.bottom, 24)

            // Sign in + browse
            VStack(spacing: 16) {
                SignInWithAppleButton(.signIn) { request in
                    viewModel.prepareSignInRequest(request)
                } onCompletion: { result in
                    Task {
                        await viewModel.handleSignInWithApple(result)
                        if viewModel.isAuthenticated {
                            UserDefaults.standard.set(true, forKey: "drift_has_onboarded")
                            onDismiss()
                        }
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    UserDefaults.standard.set(true, forKey: "drift_has_onboarded")
                    onDismiss()
                } label: {
                    Text("Browse without account")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppConstants.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Shared Components

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppConstants.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
