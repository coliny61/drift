import SwiftUI

struct DiscoverView: View {
    @Environment(DiscoverViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var selectedEventId: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Feed mode picker
                    feedModePicker
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Category chips
                    categoryChips
                        .padding(.top, 12)

                    // Featured carousel
                    if !viewModel.featuredEvents.isEmpty {
                        featuredCarousel
                    }

                    if viewModel.isLoading && viewModel.events.isEmpty {
                        ProgressView()
                            .tint(AppConstants.Colors.accent)
                            .padding(.top, 60)
                    } else if viewModel.error != nil && viewModel.events.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(AppConstants.Colors.textTertiary)
                            Text("Couldn't load events")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Check your connection and pull to refresh")
                                .font(.subheadline)
                                .foregroundStyle(AppConstants.Colors.textSecondary)
                        }
                        .padding(.top, 60)
                    } else if viewModel.filteredEvents.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "calendar")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(AppConstants.Colors.textTertiary)
                            Text("No events found")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Try a different category or feed")
                                .font(.subheadline)
                                .foregroundStyle(AppConstants.Colors.textSecondary)
                        }
                        .padding(.top, 60)
                    } else {
                        // Event cards
                        LazyVStack(spacing: 20) {
                            ForEach(viewModel.filteredEvents) { event in
                                NavigationLink(value: AppDestination.event(event.id)) {
                                    EventCardView(event: event)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .background(AppConstants.Colors.background)
            .navigationTitle("Drift")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .event(let id): EventDetailView(eventId: id)
                case .organizer(let id): OrganizerDetailView(organizerId: id)
                }
            }
            .refreshable {
                await viewModel.loadEvents()
            }
            .task {
                if viewModel.events.isEmpty {
                    await viewModel.loadEvents()
                }
                let userId = authViewModel.currentProfile?.id ?? authViewModel.localUserId
                await viewModel.loadUserContext(userId: userId)
            }
        }
    }

    // MARK: - Feed Mode Picker

    private var feedModePicker: some View {
        HStack(spacing: 0) {
            ForEach(DiscoverViewModel.FeedMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.setFeedMode(mode)
                    }
                    HapticManager.selection()
                } label: {
                    Text(mode.rawValue)
                        .font(.subheadline)
                        .fontWeight(viewModel.feedMode == mode ? .bold : .medium)
                        .foregroundStyle(viewModel.feedMode == mode ? .white : AppConstants.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.feedMode == mode
                                ? AppConstants.Colors.secondaryBackground
                                : .clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .background(AppConstants.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Featured Carousel

    private var featuredCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppConstants.Colors.accent)
                Text("FEATURED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(1.2)
                    .foregroundStyle(AppConstants.Colors.accent)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.featuredEvents) { event in
                        NavigationLink(value: AppDestination.event(event.id)) {
                            featuredCard(event)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 20)
    }

    private func featuredCard(_ event: Event) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let urlString = event.coverImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        featuredGradient(event)
                    }
                }
            } else {
                featuredGradient(event)
            }
        }
        .frame(width: 300, height: 180)
        .clipped()
        .overlay(
            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(event.startTime.relativeDescription)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    if event.rsvpCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 9))
                            Text("\(event.rsvpCount)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .foregroundStyle(.white.opacity(0.85))
            }
            .padding(14)
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                Text("FEATURED")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AppConstants.Colors.accent)
            .clipShape(Capsule())
            .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    private func featuredGradient(_ event: Event) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: event.categoryEnum?.color ?? "FF6B35").opacity(0.6),
                        Color(hex: event.categoryEnum?.color ?? "FF6B35").opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: event.categoryEnum?.icon ?? "star")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.15))
            }
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                CategoryChipView(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: viewModel.selectedCategory == nil,
                    color: AppConstants.Colors.accent
                ) {
                    viewModel.selectCategory(nil)
                }

                ForEach(Category.allCases, id: \.self) { category in
                    CategoryChipView(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: viewModel.selectedCategory == category,
                        color: Color(hex: category.color)
                    ) {
                        viewModel.selectCategory(
                            viewModel.selectedCategory == category ? nil : category
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
