import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var selectedTab: Tab = .discover

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
                    .navigationDestination(for: UUID.self) { eventId in
                        EventDetailView(eventId: eventId)
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
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel(authService: AuthService(
            client: .init(supabaseURL: SupabaseConfig.url, supabaseKey: SupabaseConfig.anonKey)
        )))
}
