import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @StateObject private var viewModel = RSSFeedViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Discover Tab
            DiscoverView(viewModel: viewModel)
                .tabItem {
                    Label("Discover", systemImage: "sparkles")
                }
                .tag(1)
            
            // Headlines Tab
            HeadlinesView(viewModel: viewModel)
                .tabItem {
                    Label("Headlines", systemImage: "newspaper.fill")
                }
                .tag(2)
            
            // Puzzles Tab
            PuzzlesView(viewModel: viewModel)
                .tabItem {
                    Label("Puzzles", systemImage: "puzzlepiece.fill")
                }
                .tag(3)
            
            // Saved Tab
            SavedView(viewModel: viewModel)
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .onChange(of: selectedTab) { _, newValue in
            let tabNames = ["Home", "Discover", "Headlines", "Puzzles", "Saved"]
            if newValue < tabNames.count {
                viewModel.activityTracker.trackTabVisit(tabNames[newValue])
            }
        }
    }
}

// MARK: - Home View (Main Feed)
struct HomeView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @State private var showSettings = false
    @State private var selectedFeed: NewsFeed?
    @State private var isGridView = false
    @State private var showInvestingSubcategories = false
    @State private var showSportsPreferences = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBarView(searchText: $viewModel.searchQuery)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Category Tabs
                CategoryTabsView(
                    selectedCategory: $viewModel.selectedCategory,
                    selectedSubcategory: $viewModel.selectedSubcategory,
                    onCategorySelected: { category in
                        if category != .investing {
                            viewModel.selectedSubcategory = nil
                        }
                        Task {
                            await viewModel.fetchFeeds(for: category)
                        }
                    },
                    onInvestingTapped: {
                        if viewModel.selectedCategory == .investing {
                            showInvestingSubcategories = true
                        }
                    },
                    onSportsTapped: {
                        if viewModel.selectedCategory == .sports {
                            showSportsPreferences = true
                        }
                    },
                    enabledCategories: viewModel.enabledCategories()
                )
                .padding(.vertical, 8)
                
                // Subcategory badge for Investing
                if viewModel.selectedCategory == .investing, let subcategory = viewModel.selectedSubcategory {
                    HStack {
                        InvestingBadge(subcategory: subcategory)
                        
                        Spacer()
                        
                        Button {
                            showInvestingSubcategories = true
                        } label: {
                            Text("Change Topic")
                                .font(.caption)
                                .foregroundStyle(.teal)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Content Area with Sections
                ZStack {
                    switch viewModel.loadingState {
                    case .idle:
                        EmptyStateView(
                            icon: "newspaper",
                            title: "Select a Category",
                            message: "Choose a category above to start reading news"
                        )
                        
                    case .loading:
                        LoadingView()
                        
                    case .loaded:
                        if viewModel.filteredFeeds().isEmpty {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: "No Results",
                                message: "No articles match your search"
                            )
                        } else {
                            SectionedFeedListView(
                                feeds: viewModel.filteredFeeds(),
                                isGridView: isGridView,
                                isBookmarked: { viewModel.isBookmarked($0) },
                                onFeedTapped: { selectedFeed = $0 }
                            )
                        }
                        
                    case .error(let message):
                        EmptyStateView(
                            icon: "exclamationmark.triangle",
                            title: "Error",
                            message: message
                        )
                    }
                }
            }
            .navigationTitle("News")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Refresh button
                        Button {
                            Task {
                                await viewModel.refreshFeeds()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.blue)
                        }
                        
                        // View mode toggle
                        Button {
                            isGridView.toggle()
                        } label: {
                            Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                                .foregroundStyle(.blue)
                        }
                        
                        // Settings button (de-emphasized)
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
            .sheet(item: $selectedFeed) { feed in
                FeedDetailView(feed: feed, viewModel: viewModel)
            }
            .sheet(isPresented: $showInvestingSubcategories) {
                InvestingSubcategoryView(
                    viewModel: viewModel,
                    selectedSubcategory: $viewModel.selectedSubcategory,
                    onSubcategorySelected: { subcategory in
                        Task {
                            await viewModel.fetchFeeds(for: .investing, subcategory: subcategory)
                        }
                    }
                )
            }
            .sheet(isPresented: $showSportsPreferences) {
                SportsPreferencesView(viewModel: viewModel)
            }
            .preferredColorScheme(viewModel.isDarkModeEnabled ? .dark : .light)
            .task {
                await viewModel.fetchFeeds()
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Sectioned Feed List View
struct SectionedFeedListView: View {
    let feeds: [NewsFeed]
    let isGridView: Bool
    let isBookmarked: (NewsFeed) -> Bool
    let onFeedTapped: (NewsFeed) -> Void
    
    var groupedFeeds: [(header: String, feeds: [NewsFeed])] {
        let now = Date()
        let calendar = Calendar.current
        
        var sections: [(String, [NewsFeed])] = []
        
        // Top Stories (last 6 hours)
        let sixHoursAgo = calendar.date(byAdding: .hour, value: -6, to: now)!
        let topStories = feeds.filter { feed in
            guard let date = feed.postDate else { return false }
            return date > sixHoursAgo
        }
        if !topStories.isEmpty {
            sections.append(("Top Stories", Array(topStories.prefix(10))))
        }
        
        // Earlier Today (today but older than 6 hours)
        let startOfDay = calendar.startOfDay(for: now)
        let earlierToday = feeds.filter { feed in
            guard let date = feed.postDate else { return false }
            return date >= startOfDay && date <= sixHoursAgo
        }
        if !earlierToday.isEmpty {
            sections.append(("Earlier Today", earlierToday))
        }
        
        // This Week (last 7 days, excluding today)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let thisWeek = feeds.filter { feed in
            guard let date = feed.postDate else { return false }
            return date >= sevenDaysAgo && date < startOfDay
        }
        if !thisWeek.isEmpty {
            sections.append(("This Week", thisWeek))
        }
        
        // If no sections created, show all
        if sections.isEmpty && !feeds.isEmpty {
            sections.append(("All Articles", feeds))
        }
        
        return sections
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedFeeds, id: \.header) { section in
                    Section {
                        if isGridView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(section.feeds) { feed in
                                    FeedGridCard(feed: feed, isBookmarked: isBookmarked(feed)) {
                                        onFeedTapped(feed)
                                    }
                                }
                            }
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(section.feeds) { feed in
                                    FeedListCard(feed: feed, isBookmarked: isBookmarked(feed)) {
                                        onFeedTapped(feed)
                                    }
                                }
                            }
                        }
                    } header: {
                        SectionHeader(title: section.header, count: section.feeds.count)
                    }
                }
            }
            .padding()

        }
        .refreshable {
            // Trigger refresh
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
            
            Text("\(count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground).opacity(0.95))
    }
}

// MARK: - Action Bar View
struct ActionBarView: View {
    @Binding var isGridView: Bool
    let onRefreshTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 32) {
            Button {
                onRefreshTapped()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20))
                        .foregroundStyle(.blue)
                    Text("Refresh")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
            
            Spacer()
            
            Button {
                isGridView.toggle()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: isGridView ? "square.grid.2x2.fill" : "list.bullet")
                        .font(.system(size: 20))
                        .foregroundStyle(.purple)
                    Text(isGridView ? "Grid" : "List")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                }
            }
        }
        .padding()
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
}

// MARK: - Updated Category Tabs with Sports
struct CategoryTabsView: View {
    @Binding var selectedCategory: FeedCategory
    @Binding var selectedSubcategory: InvestingSubcategory?
    let onCategorySelected: (FeedCategory) -> Void
    let onInvestingTapped: () -> Void
    let onSportsTapped: () -> Void
    let enabledCategories: [FeedCategory]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(enabledCategories, id: \.self) { category in
                    if category == .investing {
                        InvestingCategoryChip(
                            isSelected: selectedCategory == category,
                            hasSubcategorySelected: selectedSubcategory != nil,
                            subcategoryName: selectedSubcategory?.rawValue,
                            action: {
                                selectedCategory = category
                                onCategorySelected(category)
                            },
                            onSubcategoryTap: onInvestingTapped
                        )
                    } else if category == .sports {
                        SportsCategoryChip(
                            isSelected: selectedCategory == category,
                            action: {
                                selectedCategory = category
                                onCategorySelected(category)
                            },
                            onPreferencesTap: onSportsTapped
                        )
                    } else {
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                            onCategorySelected(category)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category: FeedCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.system(size: 14))
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                Color.blue :
                Color(.systemGray6)
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sports Category Chip
struct SportsCategoryChip: View {
    let isSelected: Bool
    let action: () -> Void
    let onPreferencesTap: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "sportscourt")
                        .font(.system(size: 14))
                    Text("Sports")
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                }
            }
            
            if isSelected {
                Button(action: onPreferencesTap) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.green : Color(.systemGray6))
        .foregroundStyle(isSelected ? .white : .primary)
        .cornerRadius(20)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
