import SwiftUI

// MARK: - Filter View
struct FilterView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var tempFilters: FeedFilters
    
    init(viewModel: RSSFeedViewModel) {
        self.viewModel = viewModel
        _tempFilters = State(initialValue: viewModel.filters)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Sort Section
                Section {
                    Picker("Sort By", selection: $tempFilters.sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Label(option.displayName, systemImage: option.iconName)
                                .tag(option)
                        }
                    }
                    
                    if tempFilters.sortOption != .none {
                        Toggle("Ascending", isOn: $tempFilters.sortAscending)
                    }
                } header: {
                    Text("Sort")
                } footer: {
                    Text("Choose how to sort your feed")
                }
                
                // Filter Section
                Section {
                    Toggle("Only with Images", isOn: $tempFilters.onlyWithImages)
                    Toggle("Hide Read Articles", isOn: $tempFilters.hideRead)
                } header: {
                    Text("Content Filters")
                }
                
                // Date Range Section
                Section {
                    Picker("Time Range", selection: $tempFilters.dateFilter) {
                        ForEach(DateFilter.allCases, id: \.self) { filter in
                            Text(filter.displayName).tag(filter)
                        }
                    }
                } header: {
                    Text("Date Range")
                } footer: {
                    Text("Filter articles by publication date")
                }
                
                // Source Filter Section
                Section {
                    if !availableSources.isEmpty {
                        ForEach(availableSources, id: \.self) { source in
                            Toggle(source, isOn: Binding(
                                get: { !tempFilters.excludedSources.contains(source) },
                                set: { isEnabled in
                                    if isEnabled {
                                        tempFilters.excludedSources.remove(source)
                                    } else {
                                        tempFilters.excludedSources.insert(source)
                                    }
                                }
                            ))
                        }
                    } else {
                        Text("No sources available")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    HStack {
                        Text("Sources")
                        Spacer()
                        if !tempFilters.excludedSources.isEmpty {
                            Button("Select All") {
                                tempFilters.excludedSources.removeAll()
                            }
                            .font(.caption)
                        }
                    }
                } footer: {
                    Text("Hide articles from specific sources")
                }
                
                // Reset Section
                Section {
                    Button(role: .destructive) {
                        tempFilters = FeedFilters()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Filters")
                        }
                    }
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        viewModel.filters = tempFilters
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var availableSources: [String] {
        let sources = Set(viewModel.newsFeeds.compactMap { $0.sourceName })
        return sources.sorted()
    }
}

// MARK: - Filter Models

struct FeedFilters: Codable {
    var sortOption: SortOption = .date
    var sortAscending: Bool = false
    var onlyWithImages: Bool = false
    var hideRead: Bool = false
    var dateFilter: DateFilter = .all
    var excludedSources: Set<String> = []
    
    /// Apply filters to feed array
    func apply(to feeds: [NewsFeed], readArticles: Set<UUID>) -> [NewsFeed] {
        var filtered = feeds
        
        // Filter by images
        if onlyWithImages {
            filtered = filtered.filter { $0.thumbnail != nil }
        }
        
        // Filter by read status
        if hideRead {
            filtered = filtered.filter { !readArticles.contains($0.id) }
        }
        
        // Filter by date
        filtered = dateFilter.apply(to: filtered)
        
        // Filter by source
        if !excludedSources.isEmpty {
            filtered = filtered.filter { feed in
                guard let source = feed.sourceName else { return true }
                return !excludedSources.contains(source)
            }
        }
        
        // Sort
        filtered = sortOption.apply(to: filtered, ascending: sortAscending)
        
        return filtered
    }
}

// MARK: - Sort Options

enum SortOption: String, CaseIterable, Codable {
    case none = "None"
    case date = "Date"
    case source = "Source"
    case title = "Title"
    
    var displayName: String {
        rawValue
    }
    
    var iconName: String {
        switch self {
        case .none: return "circle"
        case .date: return "calendar"
        case .source: return "building.2"
        case .title: return "textformat"
        }
    }
    
    func apply(to feeds: [NewsFeed], ascending: Bool) -> [NewsFeed] {
        switch self {
        case .none:
            return feeds
            
        case .date:
            return feeds.sorted { feed1, feed2 in
                guard let date1 = feed1.postDate, let date2 = feed2.postDate else {
                    return feed1.postDate != nil
                }
                return ascending ? date1 < date2 : date1 > date2
            }
            
        case .source:
            return feeds.sorted { feed1, feed2 in
                let source1 = feed1.sourceName ?? ""
                let source2 = feed2.sourceName ?? ""
                return ascending ? source1 < source2 : source1 > source2
            }
            
        case .title:
            return feeds.sorted { feed1, feed2 in
                return ascending ? feed1.title < feed2.title : feed1.title > feed2.title
            }
        }
    }
}

// MARK: - Date Filters

enum DateFilter: String, CaseIterable, Codable {
    case all = "All Time"
    case today = "Today"
    case yesterday = "Yesterday"
    case lastWeek = "Last 7 Days"
    case lastMonth = "Last 30 Days"
    
    var displayName: String {
        rawValue
    }
    
    func apply(to feeds: [NewsFeed]) -> [NewsFeed] {
        guard self != .all else { return feeds }
        
        let calendar = Calendar.current
        let now = Date()
        
        return feeds.filter { feed in
            guard let feedDate = feed.postDate else { return false }
            
            switch self {
            case .all:
                return true
                
            case .today:
                return calendar.isDateInToday(feedDate)
                
            case .yesterday:
                return calendar.isDateInYesterday(feedDate)
                
            case .lastWeek:
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
                    return false
                }
                return feedDate >= weekAgo
                
            case .lastMonth:
                guard let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) else {
                    return false
                }
                return feedDate >= monthAgo
            }
        }
    }
}

// MARK: - Filter Badge View

struct FilterBadgeView: View {
    let filters: FeedFilters
    let onTap: () -> Void
    
    var activeFilterCount: Int {
        var count = 0
        if filters.sortOption != .none { count += 1 }
        if filters.onlyWithImages { count += 1 }
        if filters.hideRead { count += 1 }
        if filters.dateFilter != .all { count += 1 }
        if !filters.excludedSources.isEmpty { count += 1 }
        return count
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: activeFilterCount > 0 ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .foregroundStyle(activeFilterCount > 0 ? .blue : .secondary)
                
                if activeFilterCount > 0 {
                    Text("\(activeFilterCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    FilterView(viewModel: RSSFeedViewModel())
}
