import SwiftUI

struct FilterSheetView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Categories
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categories")
                            .font(.headline)
                            .foregroundStyle(.white)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(Category.allCases, id: \.self) { category in
                                let isSelected = viewModel.selectedCategories.contains(category)
                                Button {
                                    if isSelected {
                                        viewModel.selectedCategories.remove(category)
                                    } else {
                                        viewModel.selectedCategories.insert(category)
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: category.icon)
                                            .font(.caption)
                                        Text(category.displayName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isSelected ? Color(hex: category.color).opacity(0.2) : AppConstants.Colors.secondaryBackground)
                                    .foregroundStyle(isSelected ? Color(hex: category.color) : AppConstants.Colors.textSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(isSelected ? Color(hex: category.color).opacity(0.5) : .clear, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }

                    Divider().background(AppConstants.Colors.secondaryBackground)

                    // City
                    VStack(alignment: .leading, spacing: 12) {
                        Text("City")
                            .font(.headline)
                            .foregroundStyle(.white)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // "All" chip
                                let allSelected = viewModel.selectedCity == nil
                                Button {
                                    viewModel.selectedCity = nil
                                } label: {
                                    Text("All DFW")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(allSelected ? AppConstants.Colors.info.opacity(0.2) : AppConstants.Colors.secondaryBackground)
                                        .foregroundStyle(allSelected ? AppConstants.Colors.info : AppConstants.Colors.textSecondary)
                                        .clipShape(Capsule())
                                }

                                ForEach(AppConstants.dfwCities, id: \.self) { city in
                                    let isSelected = viewModel.selectedCity == city
                                    Button {
                                        viewModel.selectedCity = isSelected ? nil : city
                                    } label: {
                                        Text(city)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(isSelected ? AppConstants.Colors.info.opacity(0.2) : AppConstants.Colors.secondaryBackground)
                                            .foregroundStyle(isSelected ? AppConstants.Colors.info : AppConstants.Colors.textSecondary)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    Divider().background(AppConstants.Colors.secondaryBackground)

                    // Date Range
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When")
                            .font(.headline)
                            .foregroundStyle(.white)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SearchViewModel.DateRange.allCases, id: \.self) { range in
                                    let isSelected = viewModel.dateRange == range
                                    Button {
                                        viewModel.dateRange = range
                                    } label: {
                                        Text(range.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(isSelected ? AppConstants.Colors.accent.opacity(0.2) : AppConstants.Colors.secondaryBackground)
                                            .foregroundStyle(isSelected ? AppConstants.Colors.accent : AppConstants.Colors.textSecondary)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    Divider().background(AppConstants.Colors.secondaryBackground)

                    // Time of Day
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Time of Day")
                            .font(.headline)
                            .foregroundStyle(.white)

                        HStack(spacing: 8) {
                            ForEach(SearchViewModel.TimeOfDay.allCases, id: \.self) { time in
                                let isSelected = viewModel.timeOfDay == time
                                Button {
                                    viewModel.timeOfDay = time
                                } label: {
                                    Text(time.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? AppConstants.Colors.purple.opacity(0.2) : AppConstants.Colors.secondaryBackground)
                                        .foregroundStyle(isSelected ? AppConstants.Colors.purple : AppConstants.Colors.textSecondary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Divider().background(AppConstants.Colors.secondaryBackground)

                    // Distance
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Distance")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(Int(viewModel.maxDistance)) mi")
                                .font(.subheadline)
                                .foregroundStyle(AppConstants.Colors.accent)
                        }

                        Slider(value: Bindable(viewModel).maxDistance, in: 1...25, step: 1)
                            .tint(AppConstants.Colors.accent)
                    }

                    Divider().background(AppConstants.Colors.secondaryBackground)

                    // Toggles
                    VStack(spacing: 16) {
                        Toggle(isOn: Bindable(viewModel).alcoholFreeOnly) {
                            HStack(spacing: 8) {
                                Image(systemName: "leaf.fill")
                                    .foregroundStyle(AppConstants.Colors.teal)
                                Text("Alcohol-Free Only")
                                    .foregroundStyle(.white)
                            }
                        }
                        .tint(AppConstants.Colors.teal)

                        Toggle(isOn: Bindable(viewModel).freeOnly) {
                            HStack(spacing: 8) {
                                Image(systemName: "dollarsign.circle")
                                    .foregroundStyle(AppConstants.Colors.info)
                                Text("Free Events Only")
                                    .foregroundStyle(.white)
                            }
                        }
                        .tint(AppConstants.Colors.info)
                    }
                }
                .padding()
            }
            .background(AppConstants.Colors.background)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        viewModel.clearFilters()
                    }
                    .foregroundStyle(AppConstants.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        viewModel.applyLocalFilters()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppConstants.Colors.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}
