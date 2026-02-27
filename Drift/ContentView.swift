import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var selectedTab: Tab = .discover
    @State private var showOnboarding = false

    enum Tab: String {
        case discover, map, search, activity, profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "house.fill")
                }
                .tag(Tab.discover)

            NavigationStack {
                DriftMapView()
                    .navigationTitle("Map")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .navigationDestination(for: AppDestination.self) { destination in
                        switch destination {
                        case .event(let id): EventDetailView(eventId: id)
                        case .organizer(let id): OrganizerDetailView(organizerId: id)
                        }
                    }
            }
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }
            .tag(Tab.map)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)

            ActivityFeedView()
                .tabItem {
                    Label("Activity", systemImage: "bell.fill")
                }
                .tag(Tab.activity)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .tint(Color(hex: "FF6B35"))
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(onDismiss: {
                showOnboarding = false
            })
        }
        .onAppear {
            let hasOnboarded = UserDefaults.standard.bool(forKey: "drift_has_onboarded")
            if !authViewModel.isAuthenticated && !hasOnboarded {
                showOnboarding = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel(authService: AuthService(
            client: .init(supabaseURL: SupabaseConfig.url, supabaseKey: SupabaseConfig.anonKey)
        )))
}
