import SwiftUI

struct DiscoverView: View {
    @Environment(DiscoverViewModel.self) private var viewModel
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
