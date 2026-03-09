import SwiftUI

struct SearchView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppConstants.Colors.textTertiary)
                        TextField("Search events, places, vibes...", text: Bindable(viewModel).query)
                            .foregroundStyle(.white)
                            .focused($isSearchFocused)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        if !viewModel.query.isEmpty {
                            Button {
                                viewModel.query = ""
                                viewModel.results = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(AppConstants.Colors.textTertiary)
                            }
                            .accessibilityLabel("Clear search")
                        }
                    }
                    .padding(13)
                    .background(AppConstants.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Filter button
                    Button {
                        viewModel.showFilters = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(hasActiveFilters ? AppConstants.Colors.accent : AppConstants.Colors.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(AppConstants.Colors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(hasActiveFilters ? AppConstants.Colors.accent.opacity(0.3) : .clear, lineWidth: 1.5)
                            )
                    }
                    .accessibilityLabel("Filters")
                    .accessibilityHint(hasActiveFilters ? "Filters active" : "No filters applied")
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if viewModel.query.isEmpty && viewModel.results.isEmpty {
                    // Recent searches
                    if !viewModel.recentSearches.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("RECENT")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .tracking(1)
                                    .foregroundStyle(AppConstants.Colors.textTertiary)
                                Spacer()
                                Button("Clear") {
                                    viewModel.clearRecentSearches()
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppConstants.Colors.textSecondary)
                            }
                            .padding(.horizontal)
                            .padding(.top, 24)

                            ForEach(viewModel.recentSearches, id: \.self) { search in
                                Button {
                                    viewModel.query = search
                                    Task { await viewModel.search() }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 14))
                                            .foregroundStyle(AppConstants.Colors.textTertiary)
                                        Text(search)
                                            .font(.subheadline)
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "arrow.up.left")
                                            .font(.system(size: 11))
                                            .foregroundStyle(AppConstants.Colors.textTertiary)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
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
                        LazyVStack(spacing: 18) {
                            ForEach(viewModel.results) { event in
                                NavigationLink(value: AppDestination.event(event.id)) {
                                    EventCardView(event: event)
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    if event.id == viewModel.results.suffix(5).first?.id {
                                        Task { await viewModel.loadMoreResults() }
                                    }
                                }
                            }

                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .tint(AppConstants.Colors.accent)
                                    .padding(.vertical, 16)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }
                }

                Spacer()
            }
            .background(AppConstants.Colors.background)
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
