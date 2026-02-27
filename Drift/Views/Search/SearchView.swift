import SwiftUI

struct SearchView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color(hex: "9CA3AF"))
                        TextField("Search events, places, vibes...", text: Bindable(viewModel).query)
                            .foregroundStyle(.white)
                            .focused($isSearchFocused)
                            .onSubmit {
                                Task { await viewModel.search() }
                            }

                        if !viewModel.query.isEmpty {
                            Button {
                                viewModel.query = ""
                                viewModel.results = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color(hex: "9CA3AF"))
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(hex: "1A1A1A"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Filter button
                    Button {
                        viewModel.showFilters = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.body)
                            .foregroundStyle(hasActiveFilters ? Color(hex: "FF6B35") : Color(hex: "9CA3AF"))
                            .padding(12)
                            .background(Color(hex: "1A1A1A"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if viewModel.query.isEmpty && viewModel.results.isEmpty {
                    // Recent searches
                    if !viewModel.recentSearches.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recent")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                                Button("Clear") {
                                    viewModel.clearRecentSearches()
                                }
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: "9CA3AF"))
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)

                            ForEach(viewModel.recentSearches, id: \.self) { search in
                                Button {
                                    viewModel.query = search
                                    Task { await viewModel.search() }
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .foregroundStyle(Color(hex: "9CA3AF"))
                                        Text(search)
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "arrow.up.left")
                                            .font(.caption)
                                            .foregroundStyle(Color(hex: "9CA3AF"))
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    } else {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "Search Drift",
                            message: "Find events, run clubs, sound baths, and more across DFW"
                        )
                    }
                } else if viewModel.isSearching {
                    LoadingView(message: "Searching...")
                } else if viewModel.results.isEmpty && !viewModel.query.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No results",
                        message: "Try different keywords or adjust your filters"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.results) { event in
                                NavigationLink(value: AppDestination.event(event.id)) {
                                    EventCardView(event: event)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }
                }

                Spacer()
            }
            .background(Color(hex: "0A0A0A"))
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .event(let id): EventDetailView(eventId: id)
                case .organizer(let id): OrganizerDetailView(organizerId: id)
                }
            }
            .sheet(isPresented: Bindable(viewModel).showFilters) {
                FilterSheetView()
            }
        }
    }

    private var hasActiveFilters: Bool {
        !viewModel.selectedCategories.isEmpty || viewModel.selectedCity != nil ||
        viewModel.alcoholFreeOnly || viewModel.freeOnly ||
        viewModel.dateRange != .anytime || viewModel.timeOfDay != .anytime
    }
}
