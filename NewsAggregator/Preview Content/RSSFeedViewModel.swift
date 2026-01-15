import Foundation
import SwiftUI

@MainActor
class RSSFeedViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var feedSources: [FeedSource]
    @Published var newsFeeds: [NewsFeed] = []
    @Published var bookmarkedFeeds: Set<UUID> = []
    @Published var readArticles: Set<UUID> = []
    @Published var isDarkModeEnabled: Bool = false
    @Published var searchQuery: String = ""
    @Published var loadingState: LoadingState = .idle
    @Published var selectedCategory: FeedCategory = .news
    @Published var selectedSubcategory: InvestingSubcategory? = nil
    @Published var filters: FeedFilters = FeedFilters()
    @Published var sportsPreferences: [SportsPreference] = []
    @Published var customTopics: Set<String> = []
    @Published var puzzleProgress: PuzzleProgress = PuzzleProgress()
    
    private let parser = RSSParser()
    private let defaults = UserDefaults.standard
    private let searchEngine = SearchEngine()
    private let intelligenceEngine = ArticleIntelligenceEngine()
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let bookmarks = "bookmarked_feeds"
        static let readArticles = "read_articles"
        static let darkMode = "dark_mode_enabled"
        static let feedSources = "feed_sources"
        static let filters = "feed_filters"
        static let sportsPreferences = "sports_preferences"
        static let customTopics = "custom_topics"
        static let puzzleProgress = "puzzle_progress"
    }
    
    // MARK: - Initialization
    init() {
        // Initialize feed sources
        self.feedSources = Self.defaultFeedSources()
        
        // Initialize sports preferences
        self.sportsPreferences = Self.defaultSportsPreferences()
        
        // Load persisted data
        loadBookmarks()
        loadReadArticles()
        loadDarkMode()
        loadFeedSources()
        loadFilters()
        loadSportsPreferences()
        loadCustomTopics()
        loadPuzzleProgress()
    }
    
    // MARK: - Default Sports Preferences
    static func defaultSportsPreferences() -> [SportsPreference] {
        SportsSubcategory.allCases.enumerated().map { index, subcategory in
            SportsPreference(subcategory: subcategory, isEnabled: true, priority: index)
        }
    }
    
    // MARK: - Default Feed Sources
    static func defaultFeedSources() -> [FeedSource] {
        [
            FeedSource(name: "BBC News", url: "https://feeds.bbci.co.uk/news/world/rss.xml", category: .news),
            FeedSource(name: "CNN", url: "https://rss.cnn.com/rss/edition.rss", category: .news),
            FeedSource(name: "Reuters", url: "https://feeds.reuters.com/reuters/topNews", category: .news),
            FeedSource(name: "The Guardian", url: "https://www.theguardian.com/world/rss", category: .news),
            
            FeedSource(name: "TechCrunch", url: "https://feeds.feedburner.com/TechCrunch/", category: .technology),
            FeedSource(name: "Ars Technica", url: "https://feeds.arstechnica.com/arstechnica/index", category: .technology),
            FeedSource(name: "The Verge", url: "https://www.theverge.com/rss/index.xml", category: .technology),
            FeedSource(name: "Wired", url: "https://www.wired.com/feed/rss", category: .technology),
            
            FeedSource(name: "ESPN", url: "https://www.espn.com/espn/rss/news", category: .sports, sportsSubcategory: .football),
            FeedSource(name: "Sports Illustrated", url: "https://www.si.com/rss/si_topstories.rss", category: .sports),
            FeedSource(name: "NBA.com", url: "https://www.nba.com/rss/nba_rss.xml", category: .sports, sportsSubcategory: .basketball),
            FeedSource(name: "MLB.com", url: "https://www.mlb.com/feeds/news/rss.xml", category: .sports, sportsSubcategory: .baseball),
            FeedSource(name: "NFL.com", url: "https://www.nfl.com/feeds/rss/news", category: .sports, sportsSubcategory: .football),
            FeedSource(name: "NHL.com", url: "https://www.nhl.com/feeds/news/rss.xml", category: .sports, sportsSubcategory: .hockey),
            
            FeedSource(name: "Variety", url: "https://variety.com/feed/", category: .entertainment),
            FeedSource(name: "Hollywood Reporter", url: "https://www.hollywoodreporter.com/feed/", category: .entertainment),
            
            FeedSource(name: "Health Line", url: "https://www.healthline.com/rss", category: .health),
            FeedSource(name: "WebMD", url: "https://rssfeeds.webmd.com/rss/rss.aspx?RSSSource=RSS_PUBLIC", category: .health),
            
            FeedSource(name: "MarketWatch", url: "https://www.marketwatch.com/rss/", category: .finance),
            FeedSource(name: "Bloomberg", url: "https://feeds.bloomberg.com/markets/news.rss", category: .finance),
            
            // Investing Category with Subcategories
            // Stocks
            FeedSource(name: "Yahoo Finance - Stocks", url: "https://finance.yahoo.com/news/rssindex", category: .investing, subcategory: .stocks),
            FeedSource(name: "Seeking Alpha - Stocks", url: "https://seekingalpha.com/feed.xml", category: .investing, subcategory: .stocks),
            FeedSource(name: "MarketWatch - Stocks", url: "https://www.marketwatch.com/rss/topstories", category: .investing, subcategory: .stocks),
            
            // ETFs
            FeedSource(name: "ETF Trends", url: "https://www.etftrends.com/feed/", category: .investing, subcategory: .etfs),
            FeedSource(name: "ETF Database", url: "https://etfdb.com/feed/", category: .investing, subcategory: .etfs),
            
            // Long-Term Themes
            FeedSource(name: "ARK Invest Blog", url: "https://ark-invest.com/feed/", category: .investing, subcategory: .longTermThemes),
            FeedSource(name: "Bloomberg - Technology", url: "https://feeds.bloomberg.com/technology/news.rss", category: .investing, subcategory: .longTermThemes),
            
            // Earnings & Fundamentals
            FeedSource(name: "Earnings Whispers", url: "https://www.earningswhispers.com/feed", category: .investing, subcategory: .earningsAndFundamentals),
            FeedSource(name: "Zacks Investment", url: "https://www.zacks.com/rss/stock_news.xml", category: .investing, subcategory: .earningsAndFundamentals),
            
            // Dividends & Income
            FeedSource(name: "Dividend.com", url: "https://www.dividend.com/feed/", category: .investing, subcategory: .dividendsAndIncome),
            FeedSource(name: "Sure Dividend", url: "https://www.suredividend.com/feed/", category: .investing, subcategory: .dividendsAndIncome),
            
            // Portfolio Strategy
            FeedSource(name: "Morningstar", url: "https://www.morningstar.com/rss/all-news.xml", category: .investing, subcategory: .portfolioStrategy),
            FeedSource(name: "Investopedia", url: "https://www.investopedia.com/feedbuilder/feed/getfeed?feedName=rss_headline", category: .investing, subcategory: .portfolioStrategy),
            
            // Risk & Volatility
            FeedSource(name: "CBOE VIX", url: "https://www.cboe.com/rss/vix_news.xml", category: .investing, subcategory: .riskAndVolatility),
            
            // Macro & Rates
            FeedSource(name: "Federal Reserve News", url: "https://www.federalreserve.gov/feeds/press_all.xml", category: .investing, subcategory: .macroAndRates),
            FeedSource(name: "Bloomberg Economics", url: "https://feeds.bloomberg.com/economics/news.rss", category: .investing, subcategory: .macroAndRates),
            
            FeedSource(name: "Serious Eats", url: "https://www.seriouseats.com/feed", category: .food),
            FeedSource(name: "Food Network", url: "https://www.foodnetwork.com/feeds/feed.rss", category: .food),
            
            FeedSource(name: "Lonely Planet", url: "https://www.lonelyplanet.com/feeds/latest", category: .travel),
            FeedSource(name: "Nomadic Matt", url: "https://www.nomadicmatt.com/feed/", category: .travel),
            
            FeedSource(name: "IGN", url: "https://feeds.ign.com/ign/all", category: .gaming),
            FeedSource(name: "GameSpot", url: "https://www.gamespot.com/feeds/mashup/", category: .gaming)
        ]
    }
    
    // MARK: - Feed Fetching
    func fetchFeeds(for category: FeedCategory? = nil, subcategory: InvestingSubcategory? = nil) async {
        let targetCategory = category ?? selectedCategory
        loadingState = .loading
        
        var selectedSources = feedSources.filter { source in
            source.category == targetCategory && source.isSelected
        }
        
        // If investing category and subcategory is selected, filter by subcategory
        if targetCategory == .investing, let subcategory = subcategory ?? selectedSubcategory {
            selectedSources = selectedSources.filter { $0.subcategory == subcategory }
        }
        
        guard !selectedSources.isEmpty else {
            loadingState = .error("No feed sources selected")
            return
        }
        
        var allFeeds: [NewsFeed] = []
        
        await withTaskGroup(of: [NewsFeed].self) { group in
            for source in selectedSources {
                group.addTask { [weak self] in
                    guard let self = self else { return [] }
                    do {
                        let feeds = try await self.parser.fetchAndParse(
                            from: source.url,
                            sourceName: source.name
                        )
                        return feeds
                    } catch {
                        print("Error fetching \(source.name): \(error.localizedDescription)")
                        return []
                    }
                }
            }
            
            for await feeds in group {
                allFeeds.append(contentsOf: feeds)
            }
        }
        
        // Sort by date (newest first)
        newsFeeds = allFeeds.sorted { feed1, feed2 in
            guard let date1 = feed1.postDate, let date2 = feed2.postDate else {
                return feed1.postDate != nil
            }
            return date1 > date2
        }
        
        // Generate "Why This Matters" context for each article
        enrichArticlesWithContext(category: targetCategory, subcategory: subcategory)
        
        loadingState = newsFeeds.isEmpty ? .error("No articles found") : .loaded
    }
    
    func refreshFeeds() async {
        await fetchFeeds(for: selectedCategory, subcategory: selectedSubcategory)
    }
    
    // MARK: - Search & Filtering
    func filteredFeeds() -> [NewsFeed] {
        var result = newsFeeds
        
        // Apply natural language search
        if !searchQuery.isEmpty {
            result = searchEngine.search(query: searchQuery, in: result)
        }
        
        // Apply filters and sorting
        result = filters.apply(to: result, readArticles: readArticles)
        
        return result
    }
    
    // MARK: - Bookmarks
    func isBookmarked(_ feed: NewsFeed) -> Bool {
        bookmarkedFeeds.contains(feed.id)
    }
    
    func toggleBookmark(for feed: NewsFeed) {
        if bookmarkedFeeds.contains(feed.id) {
            bookmarkedFeeds.remove(feed.id)
        } else {
            bookmarkedFeeds.insert(feed.id)
        }
        saveBookmarks()
    }
    
    func getBookmarkedFeeds() -> [NewsFeed] {
        newsFeeds.filter { bookmarkedFeeds.contains($0.id) }
    }
    
    private func saveBookmarks() {
        let ids = bookmarkedFeeds.map { $0.uuidString }
        defaults.set(ids, forKey: Keys.bookmarks)
    }
    
    private func loadBookmarks() {
        if let ids = defaults.array(forKey: Keys.bookmarks) as? [String] {
            bookmarkedFeeds = Set(ids.compactMap { UUID(uuidString: $0) })
        }
    }
    
    // MARK: - Read Articles
    func markAsRead(_ feed: NewsFeed) {
        readArticles.insert(feed.id)
        saveReadArticles()
    }
    
    func isRead(_ feed: NewsFeed) -> Bool {
        readArticles.contains(feed.id)
    }
    
    private func saveReadArticles() {
        let ids = readArticles.map { $0.uuidString }
        defaults.set(ids, forKey: Keys.readArticles)
    }
    
    private func loadReadArticles() {
        if let ids = defaults.array(forKey: Keys.readArticles) as? [String] {
            readArticles = Set(ids.compactMap { UUID(uuidString: $0) })
        }
    }
    
    // MARK: - Dark Mode
    func toggleDarkMode() {
        isDarkModeEnabled.toggle()
        defaults.set(isDarkModeEnabled, forKey: Keys.darkMode)
    }
    
    private func loadDarkMode() {
        isDarkModeEnabled = defaults.bool(forKey: Keys.darkMode)
    }
    
    // MARK: - Filters
    private func saveFilters() {
        if let encoded = try? JSONEncoder().encode(filters) {
            defaults.set(encoded, forKey: Keys.filters)
        }
    }
    
    private func loadFilters() {
        if let data = defaults.data(forKey: Keys.filters),
           let decoded = try? JSONDecoder().decode(FeedFilters.self, from: data) {
            filters = decoded
        }
    }
    
    // MARK: - Feed Source Management
    func toggleFeedSelection(for source: FeedSource) {
        if let index = feedSources.firstIndex(where: { $0.id == source.id }) {
            feedSources[index].isSelected.toggle()
            saveFeedSources()
        }
    }
    
    func addFeedSource(_ source: FeedSource) {
        feedSources.append(source)
        saveFeedSources()
    }
    
    func removeFeedSource(_ source: FeedSource) {
        feedSources.removeAll { $0.id == source.id }
        saveFeedSources()
    }
    
    private func saveFeedSources() {
        if let encoded = try? JSONEncoder().encode(feedSources) {
            defaults.set(encoded, forKey: Keys.feedSources)
        }
    }
    
    private func loadFeedSources() {
        if let data = defaults.data(forKey: Keys.feedSources),
           let decoded = try? JSONDecoder().decode([FeedSource].self, from: data) {
            feedSources = decoded
        }
    }
    
    // MARK: - Sports Preferences
    private func saveSportsPreferences() {
        if let encoded = try? JSONEncoder().encode(sportsPreferences) {
            defaults.set(encoded, forKey: Keys.sportsPreferences)
        }
    }
    
    private func loadSportsPreferences() {
        if let data = defaults.data(forKey: Keys.sportsPreferences),
           let decoded = try? JSONDecoder().decode([SportsPreference].self, from: data) {
            sportsPreferences = decoded
        }
    }
    
    // MARK: - Custom Topics (Discover)
    func fetchCustomFeed() async {
        guard !customTopics.isEmpty else { return }
        
        loadingState = .loading
        var allFeeds: [NewsFeed] = []
        
        let selectedSources = feedSources.filter { source in
            customTopics.contains(source.id.uuidString) && source.isSelected
        }
        
        await withTaskGroup(of: [NewsFeed].self) { group in
            for source in selectedSources {
                group.addTask { [weak self] in
                    guard let self = self else { return [] }
                    do {
                        let feeds = try await self.parser.fetchAndParse(
                            from: source.url,
                            sourceName: source.name
                        )
                        return feeds
                    } catch {
                        print("Error fetching \(source.name): \(error.localizedDescription)")
                        return []
                    }
                }
            }
            
            for await feeds in group {
                allFeeds.append(contentsOf: feeds)
            }
        }
        
        newsFeeds = allFeeds.sorted { feed1, feed2 in
            guard let date1 = feed1.postDate, let date2 = feed2.postDate else {
                return feed1.postDate != nil
            }
            return date1 > date2
        }
        
        // Generate context for custom feed
        enrichArticlesWithContext(category: nil, subcategory: nil)
        
        loadingState = newsFeeds.isEmpty ? .error("No articles found") : .loaded
        saveCustomTopics()
    }
    
    private func saveCustomTopics() {
        let topics = Array(customTopics)
        defaults.set(topics, forKey: Keys.customTopics)
    }
    
    private func loadCustomTopics() {
        if let topics = defaults.array(forKey: Keys.customTopics) as? [String] {
            customTopics = Set(topics)
        }
    }
    
    // MARK: - Headlines (All Categories)
    func fetchAllCategories() async {
        loadingState = .loading
        var allFeeds: [NewsFeed] = []
        
        await withTaskGroup(of: [NewsFeed].self) { group in
            for category in FeedCategory.allCases {
                let sources = feedSources.filter { $0.category == category && $0.isSelected }
                
                for source in sources.prefix(2) { // Limit to 2 sources per category
                    group.addTask { [weak self] in
                        guard let self = self else { return [] }
                        do {
                            let feeds = try await self.parser.fetchAndParse(
                                from: source.url,
                                sourceName: source.name
                            )
                            return feeds
                        } catch {
                            return []
                        }
                    }
                }
            }
            
            for await feeds in group {
                allFeeds.append(contentsOf: feeds)
            }
        }
        
        newsFeeds = allFeeds.sorted { feed1, feed2 in
            guard let date1 = feed1.postDate, let date2 = feed2.postDate else {
                return feed1.postDate != nil
            }
            return date1 > date2
        }
        
        // Generate context for headlines
        enrichArticlesWithContext(category: nil, subcategory: nil)
        
        loadingState = newsFeeds.isEmpty ? .error("No articles found") : .loaded
    }
    
    // MARK: - Article Intelligence
    
    /// Enrich articles with "Why This Matters" context
    private func enrichArticlesWithContext(category: FeedCategory?, subcategory: InvestingSubcategory?) {
        newsFeeds = newsFeeds.map { article in
            var enrichedArticle = article
            
            // Determine category for context generation
            let contextCategory = category ?? selectedCategory
            
            // Determine sports subcategory if applicable
            var sportsSubcategory: SportsSubcategory? = nil
            if contextCategory == .sports {
                // Find which sports subcategory this article belongs to
                if let source = feedSources.first(where: { $0.name == article.sourceName }) {
                    sportsSubcategory = source.sportsSubcategory
                }
            }
            
            // Generate context
            let context = intelligenceEngine.generateContext(
                for: article,
                category: contextCategory,
                subcategory: subcategory,
                sportsSubcategory: sportsSubcategory,
                userReadHistory: readArticles,
                userBookmarks: bookmarkedFeeds
            )
            
            enrichedArticle.context = context
            return enrichedArticle
        }
    }
    
    // MARK: - Puzzle Progress
    func savePuzzleProgress() {
        if let encoded = try? JSONEncoder().encode(puzzleProgress) {
            defaults.set(encoded, forKey: Keys.puzzleProgress)
        }
    }
    
    private func loadPuzzleProgress() {
        if let data = defaults.data(forKey: Keys.puzzleProgress),
           let decoded = try? JSONDecoder().decode(PuzzleProgress.self, from: data) {
            puzzleProgress = decoded
        }
    }
}
