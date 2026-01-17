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
            
            // Map Tab (NEW)
            NavigationView {
                NewsMapView(viewModel: viewModel)
            }
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }
            .tag(3)
            
            // Puzzles Tab
            PuzzlesView(viewModel: viewModel)
                .tabItem {
                    Label("Puzzles", systemImage: "puzzlepiece.fill")
                }
                .tag(4)
            
            // Saved Tab
            SavedView(viewModel: viewModel)
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }
                .tag(5)
        }
        .accentColor(.blue)
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.92)
            
            // Apply blur effect
            let blurEffect = UIBlurEffect(style: .systemMaterial)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100)
            
            // Increase icon size
            _ = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            appearance.stackedLayoutAppearance.normal.iconColor = .secondaryLabel
            appearance.stackedLayoutAppearance.selected.iconColor = .systemBlue
            
            // Ensure labels always visible
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium)
            ]
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .onChange(of: selectedTab) { _, newValue in
            let tabNames = ["Home", "Discover", "Headlines", "Map", "Puzzles", "Saved"]
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
                // Subtle subheader
                HStack {
                    Text("What's moving the world right now")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 6)
                .padding(.bottom, 4)
                
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
                .padding(.vertical, 6)
                
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
            .navigationTitle("WorldPulse")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            Task {
                                await viewModel.refreshFeeds()
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Button {
                            isGridView.toggle()
                        } label: {
                            Label(
                                isGridView ? "List View" : "Grid View",
                                systemImage: isGridView ? "list.bullet" : "square.grid.2x2"
                            )
                        }
                        
                        Divider()
                        
                        Button {
                            showSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.blue)
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
    
    var groupedFeeds: [(header: String, feeds: [NewsFeed], isTopStories: Bool)] {
        let now = Date()
        let calendar = Calendar.current
        
        var sections: [(String, [NewsFeed], Bool)] = []
        
        // Top Stories - expand time range if needed to always have content
        var topStories: [NewsFeed] = []
        var hoursBack = 6
        
        while topStories.isEmpty && hoursBack <= 24 {
            let timeAgo = calendar.date(byAdding: .hour, value: -hoursBack, to: now)!
            topStories = feeds.filter { feed in
                guard let date = feed.postDate else { return false }
                return date > timeAgo
            }
            if topStories.isEmpty {
                hoursBack += 6
            }
        }
        
        if !topStories.isEmpty {
            sections.append(("Top Stories", Array(topStories.prefix(10)), true))
        }
        
        // Earlier Today
        let startOfDay = calendar.startOfDay(for: now)
        let sixHoursAgo = calendar.date(byAdding: .hour, value: -6, to: now)!
        let earlierToday = feeds.filter { feed in
            guard let date = feed.postDate else { return false }
            return date >= startOfDay && date <= sixHoursAgo
        }
        if !earlierToday.isEmpty {
            sections.append(("Earlier Today", earlierToday, false))
        }
        
        // This Week
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let thisWeek = feeds.filter { feed in
            guard let date = feed.postDate else { return false }
            return date >= sevenDaysAgo && date < startOfDay
        }
        if !thisWeek.isEmpty {
            sections.append(("This Week", thisWeek, false))
        }
        
        // Fallback
        if sections.isEmpty && !feeds.isEmpty {
            sections.append(("All Articles", feeds, true))
        }
        
        return sections
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12, pinnedViews: [.sectionHeaders]) {
                ForEach(Array(groupedFeeds.enumerated()), id: \.element.header) { index, section in
                    Section {
                        if isGridView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(Array(section.feeds.enumerated()), id: \.element.id) { feedIndex, feed in
                                    FeedGridCard(feed: feed, isBookmarked: isBookmarked(feed)) {
                                        onFeedTapped(feed)
                                    }
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                    .animation(.easeOut(duration: 0.3).delay(Double(feedIndex) * 0.03), value: feed.id)
                                }
                            }
                        } else {
                            // Hero card for first article in Top Stories
                            if section.isTopStories, let heroFeed = section.feeds.first {
                                HeroFeedCard(feed: heroFeed, isBookmarked: isBookmarked(heroFeed)) {
                                    onFeedTapped(heroFeed)
                                }
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                .animation(.easeOut(duration: 0.4), value: heroFeed.id)
                            }
                            
                            // Regular cards
                            LazyVStack(spacing: 10) {
                                ForEach(Array(section.feeds.enumerated()), id: \.element.id) { feedIndex, feed in
                                    // Skip first if it's the hero
                                    if !(section.isTopStories && feedIndex == 0) {
                                        FeedListCard(feed: feed, isBookmarked: isBookmarked(feed)) {
                                            onFeedTapped(feed)
                                        }
                                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                        .animation(.easeOut(duration: 0.3).delay(Double(feedIndex) * 0.03), value: feed.id)
                                    }
                                }
                            }
                        }
                    } header: {
                        ImprovedSectionHeader(title: section.header, count: section.feeds.count)
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

// MARK: - Hero Feed Card
struct HeroFeedCard: View {
    let feed: NewsFeed
    let isBookmarked: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Background Image
                if let thumbnailURL = feed.thumbnail, let url = URL(string: thumbnailURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            placeholderImage
                        case .empty:
                            ProgressView()
                        @unknown default:
                            placeholderImage
                        }
                    }
                    .frame(height: 280)
                    .clipped()
                } else {
                    placeholderImage
                        .frame(height: 280)
                }
                
                // Gradient Overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.3), .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Source badge
                    if let sourceName = feed.sourceName {
                        Text(sourceName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .cornerRadius(6)
                    }
                    
                    // Title
                    Text(feed.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                    
                    // Context
                    if let context = feed.context {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption2)
                            Text(context.reason)
                                .font(.caption)
                                .italic()
                                .lineLimit(2)
                        }
                        .foregroundStyle(.white.opacity(0.9))
                    }
                    
                    // Meta row
                    HStack {
                        Text(feed.formattedDate)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        
                        if isBookmarked {
                            Image(systemName: "bookmark.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        
                        Spacer()
                        
                        if feed.location != nil {
                            HStack(spacing: 3) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .padding(16)
            }
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Image(systemName: "newspaper")
                    .font(.system(size: 50))
                    .foregroundStyle(.white.opacity(0.5))
            }
    }
}

// MARK: - Improved Section Header
struct ImprovedSectionHeader: View {
    let title: String
    let count: Int
    
    private var icon: String {
        switch title {
        case "Top Stories": return "flame.fill"
        case "Earlier Today": return "clock.fill"
        case "This Week": return "calendar"
        default: return "newspaper"
        }
    }
    
    private var iconColor: Color {
        switch title {
        case "Top Stories": return .orange
        case "Earlier Today": return .blue
        case "This Week": return .purple
        default: return .blue
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text("\(count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 8)
        )
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
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
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
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
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        Color(.systemGray5)
                    }
                }
            )
            .foregroundStyle(isSelected ? .white : .secondary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.0 : 0.98)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Investing Category Chip
struct InvestingCategoryChip: View {
    let isSelected: Bool
    let hasSubcategorySelected: Bool
    let subcategoryName: String?
    let action: () -> Void
    let onSubcategoryTap: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                action()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14))
                    Text("Investing")
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                }
            }
            
            if isSelected && hasSubcategorySelected {
                Button(action: onSubcategoryTap) {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.25))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Group {
                if isSelected {
                    LinearGradient(
                        colors: [.teal, .teal.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .shadow(color: .teal.opacity(0.3), radius: 4, x: 0, y: 2)
                } else {
                    Color(.systemGray5)
                }
            }
        )
        .foregroundStyle(isSelected ? .white : .secondary)
        .cornerRadius(20)
        .scaleEffect(isSelected ? 1.0 : 0.98)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Sports Category Chip
struct SportsCategoryChip: View {
    let isSelected: Bool
    let action: () -> Void
    let onPreferencesTap: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                action()
            }) {
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
                        .background(Color.white.opacity(0.25))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Group {
                if isSelected {
                    LinearGradient(
                        colors: [.green, .green.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                } else {
                    Color(.systemGray5)
                }
            }
        )
        .foregroundStyle(isSelected ? .white : .secondary)
        .cornerRadius(20)
        .scaleEffect(isSelected ? 1.0 : 0.98)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
