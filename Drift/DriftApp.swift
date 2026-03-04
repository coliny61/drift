import SwiftUI
import Supabase

@main
struct DriftApp: App {
    // MARK: - Core Utilities
    @State private var locationManager = LocationManager()

    // MARK: - Services
    @State private var authService: AuthService
    @State private var eventService: EventService
    @State private var profileService: ProfileService
    @State private var rsvpService: RSVPService
    @State private var chatService: ChatService
    @State private var activityService: ActivityService
    @State private var photoService: PhotoService
    @State private var organizerService: OrganizerService
    @State private var notificationService: NotificationService

    // MARK: - ViewModels
    @State private var authViewModel: AuthViewModel
    @State private var discoverViewModel: DiscoverViewModel
    @State private var eventDetailViewModel: EventDetailViewModel
    @State private var mapViewModel: MapViewModel
    @State private var searchViewModel: SearchViewModel
    @State private var profileViewModel: ProfileViewModel
    @State private var chatViewModel: ChatViewModel
    @State private var activityFeedViewModel: ActivityFeedViewModel
    @State private var settingsViewModel = SettingsViewModel()

    init() {
        let client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )

        let location = LocationManager()

        // Services
        let auth = AuthService(client: client)
        let events = EventService(client: client)
        let profiles = ProfileService(client: client)
        let rsvps = RSVPService(client: client)
        let chat = ChatService(client: client)
        let activity = ActivityService(client: client)
        let photos = PhotoService(client: client)
        let organizers = OrganizerService(client: client)

        _authService = State(initialValue: auth)
        _eventService = State(initialValue: events)
        _profileService = State(initialValue: profiles)
        _rsvpService = State(initialValue: rsvps)
        _chatService = State(initialValue: chat)
        _activityService = State(initialValue: activity)
        _photoService = State(initialValue: photos)
        _organizerService = State(initialValue: organizers)
        _locationManager = State(initialValue: location)

        let notifications = NotificationService()
        notifications.supabaseClient = client
        _notificationService = State(initialValue: notifications)

        // ViewModels
        _authViewModel = State(initialValue: AuthViewModel(authService: auth))
        _discoverViewModel = State(initialValue: DiscoverViewModel(eventService: events, organizerService: organizers, rsvpService: rsvps, locationManager: location))
        _eventDetailViewModel = State(initialValue: EventDetailViewModel(eventService: events, rsvpService: rsvps))
        _mapViewModel = State(initialValue: MapViewModel(eventService: events))
        _searchViewModel = State(initialValue: SearchViewModel(eventService: events, locationManager: location))
        _profileViewModel = State(initialValue: ProfileViewModel(profileService: profiles, rsvpService: rsvps, eventService: events))
        _chatViewModel = State(initialValue: ChatViewModel(chatService: chat))
        _activityFeedViewModel = State(initialValue: ActivityFeedViewModel(activityService: activity))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationManager)
                .environment(authViewModel)
                .environment(discoverViewModel)
                .environment(eventDetailViewModel)
                .environment(mapViewModel)
                .environment(searchViewModel)
                .environment(profileViewModel)
                .environment(chatViewModel)
                .environment(activityFeedViewModel)
                .environment(settingsViewModel)
                .environment(photoService)
                .environment(organizerService)
                .environment(eventService)
                .environment(notificationService)
                .preferredColorScheme(settingsViewModel.colorScheme)
                .task {
                    await authViewModel.initialize()
                }
        }
    }
}
