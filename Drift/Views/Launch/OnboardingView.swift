import SwiftUI

struct OnboardingView: View {
    @Environment(AuthViewModel.self) private var viewModel
    @Environment(LocationManager.self) private var locationManager
    @Environment(NotificationService.self) private var notificationService
    var onDismiss: () -> Void

    private let totalSteps = AuthViewModel.OnboardingStep.allCases.count

    var body: some View {
        ZStack {
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
                    cityStep.tag(AuthViewModel.OnboardingStep.city)
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
                    .frame(width: step == viewModel.onboardingStep ? 28 : 8, height: 4)
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
                            colors: [AppConstants.Colors.accent.opacity(0.18), .clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)

                VStack(spacing: 20) {
                    Image(systemName: "wind")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(AppConstants.Colors.accent)
                        .symbolEffect(.pulse, options: .repeating)

                    Text("Drift")
                        .font(.system(size: 56, weight: .bold, design: .default))
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
                featureRow(icon: "person.2.fill", text: "Find your people, build your streak", color: AppConstants.Colors.success)
            }
            .padding(.horizontal, 32)

            Spacer()

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
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 11))

            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
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
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(isSelected ? catColor.opacity(0.15) : AppConstants.Colors.cardBackground)
                            .foregroundStyle(isSelected ? catColor : AppConstants.Colors.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(isSelected ? catColor.opacity(0.4) : .clear, lineWidth: 1.5)
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
                        .fontWeight(.bold)
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

    // MARK: - City

    private var cityStep: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("What's your city?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("We'll prioritize events near you")
                    .font(.subheadline)
                    .foregroundStyle(AppConstants.Colors.textSecondary)
            }
            .padding(.top, 32)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                    ForEach(AppConstants.dfwCities, id: \.self) { city in
                        let isSelected = viewModel.selectedCity == city

                        Button {
                            withAnimation(.spring(duration: 0.2)) {
                                viewModel.selectedCity = city
                            }
                            HapticManager.selection()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.subheadline)
                                    .symbolEffect(.bounce, value: isSelected)

                                Text(city)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(isSelected ? Color(hex: "60A5FA").opacity(0.12) : AppConstants.Colors.cardBackground)
                            .foregroundStyle(isSelected ? Color(hex: "60A5FA") : AppConstants.Colors.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(isSelected ? Color(hex: "60A5FA").opacity(0.4) : .clear, lineWidth: 1.5)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 16)
            }

            primaryButton("Continue") {
                if let city = viewModel.selectedCity {
                    UserDefaults.standard.set(city, forKey: "drift_selected_city")
                }
                viewModel.selectedNeighborhood = "Dallas Fort Worth"
                UserDefaults.standard.set("Dallas Fort Worth", forKey: "drift_selected_neighborhood")
                viewModel.nextOnboardingStep()
            }
            .opacity(viewModel.selectedCity != nil ? 1 : 0.4)
            .disabled(viewModel.selectedCity == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
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

            VStack(spacing: 14) {
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

            VStack(spacing: 14) {
                primaryButton("Enable & Continue") {
                    locationManager.requestPermission()
                    Task { await notificationService.requestPermission() }
                    viewModel.nextOnboardingStep()
                }

                Button {
                    viewModel.nextOnboardingStep()
                } label: {
                    Text("Maybe later")
                        .font(.subheadline)
                        .fontWeight(.medium)
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
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Sign In

    private var signInStep: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Hero
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [AppConstants.Colors.accent.opacity(0.12), .clear],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 240, height: 240)

                        VStack(spacing: 16) {
                            Image(systemName: "wind")
                                .font(.system(size: 40, weight: .light))
                                .foregroundStyle(AppConstants.Colors.accent)
                                .symbolEffect(.pulse, options: .repeating)

                            Text("Join Drift")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)

                            Text("Create an account to RSVP,\nfollow organizers, and more")
                                .font(.subheadline)
                                .foregroundStyle(AppConstants.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    .padding(.top, 16)

                    // Email form
                    VStack(spacing: 12) {
                        TextField("Email", text: Bindable(viewModel).email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(AppConstants.Colors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)

                        SecureField("Password", text: Bindable(viewModel).password)
                            .textContentType(viewModel.isSignUpMode ? .newPassword : .password)
                            .padding(14)
                            .background(AppConstants.Colors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)

                        if viewModel.isSignUpMode {
                            SecureField("Confirm Password", text: Bindable(viewModel).confirmPassword)
                                .textContentType(.newPassword)
                                .padding(14)
                                .background(AppConstants.Colors.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 24)
                    .disabled(viewModel.isLoading)

                    if viewModel.resetEmailSent {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppConstants.Colors.success)
                            Text("Reset link sent — check your email")
                                .foregroundStyle(AppConstants.Colors.success)
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 24)
                    }

                    if let error = viewModel.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color(hex: "EF5350"))
                            .padding(.horizontal, 24)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // Bottom actions
            VStack(spacing: 16) {
                primaryButton(viewModel.isSignUpMode ? "Create Account" : "Sign In") {
                    Task {
                        if viewModel.isSignUpMode {
                            await viewModel.signUpWithEmail()
                        } else {
                            await viewModel.signInWithEmail()
                        }
                        if viewModel.isAuthenticated {
                            UserDefaults.standard.set(true, forKey: "drift_has_onboarded")
                            onDismiss()
                        }
                    }
                }
                .opacity(viewModel.isLoading ? 0.6 : 1)
                .disabled(viewModel.isLoading)
                .overlay {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.isSignUpMode.toggle()
                        viewModel.error = nil
                        viewModel.resetEmailSent = false
                    }
                } label: {
                    Text(viewModel.isSignUpMode
                         ? "Already have an account? **Sign In**"
                         : "Don't have an account? **Sign Up**")
                        .font(.subheadline)
                        .foregroundStyle(AppConstants.Colors.textSecondary)
                }

                if !viewModel.isSignUpMode {
                    Button {
                        Task { await viewModel.sendPasswordReset() }
                    } label: {
                        Text("Forgot Password?")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(AppConstants.Colors.accent)
                    }
                    .disabled(viewModel.isLoading)
                }

                Button {
                    UserDefaults.standard.set(true, forKey: "drift_has_onboarded")
                    onDismiss()
                } label: {
                    Text("Browse without account")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppConstants.Colors.textTertiary)
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
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppConstants.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: AppConstants.Colors.accent.opacity(0.25), radius: 8, x: 0, y: 4)
        }
    }
}
