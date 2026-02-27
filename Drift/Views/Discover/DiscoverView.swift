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

                    // Event cards
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.filteredEvents) { event in
                            NavigationLink(value: event.id) {
                                EventCardView(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
            }
            .background(Color(hex: "0A0A0A"))
            .navigationTitle("Drift")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: UUID.self) { eventId in
                EventDetailView(eventId: eventId)
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
                        .fontWeight(viewModel.feedMode == mode ? .semibold : .regular)
                        .foregroundStyle(viewModel.feedMode == mode ? .white : Color(hex: "9CA3AF"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.feedMode == mode ? Color(hex: "2A2A2A") : .clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .background(Color(hex: "1A1A1A"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var featuredCarousel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(AppConstants.Colors.accent)
                Text("Featured")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.featuredEvents) { event in
                        NavigationLink(value: event.id) {
                            featuredCard(event)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 16)
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
        .frame(width: 280, height: 160)
        .clipped()
        .overlay(
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(event.startTime.relativeDescription)
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.8))
            }
            .padding(12)
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 3) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                Text("Featured")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppConstants.Colors.accent)
            .clipShape(Capsule())
            .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                CategoryChipView(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: viewModel.selectedCategory == nil,
                    color: Color(hex: "FF6B35")
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
