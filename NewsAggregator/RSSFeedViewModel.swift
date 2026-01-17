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
    @Published var categoryPreferences: [CategoryPreference] = []
    
    private let parser = RSSParser()
    private let defaults = UserDefaults.standard
    private let searchEngine = SearchEngine()
    private let intelligenceEngine = ArticleIntelligenceEngine()
    private let locationEngine = LocationEngine()
    let activityTracker = ActivityTracker()
    let signalEngine = SignalEngine()
    
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
        static let categoryPreferences = "category_preferences"
    }
    
    // MARK: - Initialization
    init() {
        // Initialize feed sources
        self.feedSources = Self.defaultFeedSources()
        
        // Initialize sports preferences
        self.sportsPreferences = Self.defaultSportsPreferences()
        
        // Initialize category preferences
        self.categoryPreferences = Self.defaultCategoryPreferences()
        
        // Load persisted data
        loadBookmarks()
        loadReadArticles()
        loadDarkMode()
        loadFeedSources()
        loadFilters()
        loadSportsPreferences()
        loadCustomTopics()
        loadPuzzleProgress()
        loadCategoryPreferences()
    }
    
    // MARK: - Default Category Preferences
    static func defaultCategoryPreferences() -> [CategoryPreference] {
        FeedCategory.allCases.enumerated().map { index, category in
            CategoryPreference(category: category, isEnabled: true, priority: index)
        }
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
            // MARK: News Category
            FeedSource(name: "BBC News", url: "https://feeds.bbci.co.uk/news/world/rss.xml", category: .news),
            FeedSource(name: "CNN", url: "https://rss.cnn.com/rss/edition.rss", category: .news),
            FeedSource(name: "Reuters", url: "https://feeds.reuters.com/reuters/topNews", category: .news),
            FeedSource(name: "The Guardian", url: "https://www.theguardian.com/world/rss", category: .news),
            FeedSource(name: "Al Jazeera", url: "https://www.aljazeera.com/xml/rss/all.xml", category: .news),
            FeedSource(name: "NPR News", url: "https://feeds.npr.org/1001/rss.xml", category: .news),
            FeedSource(name: "Associated Press", url: "https://feeds.apnews.com/rss/apf-topnews", category: .news),
            
            // MARK: Regional News - USA
            FeedSource(name: "New York Times", url: "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml", category: .news),
            FeedSource(name: "LA Times", url: "https://www.latimes.com/rss2.0.xml", category: .news),
            FeedSource(name: "Chicago Tribune", url: "https://www.chicagotribune.com/arcio/rss/", category: .news),
            FeedSource(name: "Washington Post", url: "https://feeds.washingtonpost.com/rss/national", category: .news),
            FeedSource(name: "Miami Herald", url: "https://www.miamiherald.com/news/?widgetName=rssfeed&widgetContentId=712015&getXmlFeed=true", category: .news),
            FeedSource(name: "San Francisco Chronicle", url: "https://www.sfchronicle.com/rss/feed/San-Francisco-News-163.php", category: .news),
            
            // MARK: Regional News - UK
            FeedSource(name: "BBC UK", url: "https://feeds.bbci.co.uk/news/uk/rss.xml", category: .news),
            FeedSource(name: "BBC Scotland", url: "https://feeds.bbci.co.uk/news/scotland/rss.xml", category: .news),
            FeedSource(name: "The Guardian UK", url: "https://www.theguardian.com/uk-news/rss", category: .news),
            
            // MARK: Regional News - Europe
            FeedSource(name: "Deutsche Welle", url: "https://rss.dw.com/rdf/rss-en-all", category: .news),
            FeedSource(name: "France 24", url: "https://www.france24.com/en/rss", category: .news),
            FeedSource(name: "The Local (Europe)", url: "https://feeds.thelocal.com/rss/news", category: .news),
            
            // MARK: Regional News - Asia
            FeedSource(name: "South China Morning Post", url: "https://www.scmp.com/rss/91/feed", category: .news),
            FeedSource(name: "The Japan Times", url: "https://www.japantimes.co.jp/feed/", category: .news),
            FeedSource(name: "The Straits Times", url: "https://www.straitstimes.com/news/singapore/rss.xml", category: .news),
            FeedSource(name: "The Times of India", url: "https://timesofindia.indiatimes.com/rssfeedstopstories.cms", category: .news),
            
            // MARK: Regional News - Middle East
            FeedSource(name: "Jerusalem Post", url: "https://www.jpost.com/rss/rssfeedsheadlines.aspx", category: .news),
            FeedSource(name: "Haaretz", url: "https://www.haaretz.com/cmlink/1.628295", category: .news),
            
            // MARK: Regional News - Australia
            FeedSource(name: "ABC News (Australia)", url: "https://www.abc.net.au/news/feed/51120/rss.xml", category: .news),
            FeedSource(name: "Sydney Morning Herald", url: "https://www.smh.com.au/rss/feed.xml", category: .news),
            
            // MARK: Regional News - Africa
            FeedSource(name: "News24 (South Africa)", url: "https://feeds.24.com/articles/news24/TopStories/rss", category: .news),
            
            // MARK: Technology
            FeedSource(name: "The Verge", url: "https://www.theverge.com/rss/index.xml", category: .technology),
            FeedSource(name: "Wired", url: "https://www.wired.com/feed/rss", category: .technology),
            FeedSource(name: "TechCrunch", url: "https://techcrunch.com/feed/", category: .technology),
            FeedSource(name: "Ars Technica", url: "https://feeds.arstechnica.com/arstechnica/index", category: .technology),
            FeedSource(name: "MIT Technology Review", url: "https://www.technologyreview.com/feed/", category: .technology),
            
            // MARK: Sports
            FeedSource(name: "ESPN", url: "https://www.espn.com/espn/rss/news", category: .sports, sportsSubcategory: .football),
            FeedSource(name: "BBC Sport", url: "https://feeds.bbci.co.uk/sport/rss.xml", category: .sports),
            FeedSource(name: "CBS Sports", url: "https://www.cbssports.com/rss/headlines/", category: .sports),
            FeedSource(name: "Yahoo Sports", url: "https://sports.yahoo.com/rss/", category: .sports),
            FeedSource(name: "Sky Sports", url: "https://www.skysports.com/rss/12040", category: .sports),
            FeedSource(name: "The Athletic", url: "https://theathletic.com/rss/", category: .sports),
            
            // MARK: Entertainment
            FeedSource(name: "Variety", url: "https://variety.com/feed/", category: .entertainment),
            FeedSource(name: "The Hollywood Reporter", url: "https://www.hollywoodreporter.com/feed/", category: .entertainment),
            FeedSource(name: "Deadline", url: "https://deadline.com/feed/", category: .entertainment),
            FeedSource(name: "Entertainment Weekly", url: "https://ew.com/feed/", category: .entertainment),
            
            // MARK: Health
            FeedSource(name: "Medical News Today", url: "https://www.medicalnewstoday.com/rss", category: .health),
            FeedSource(name: "STAT News", url: "https://www.statnews.com/feed/", category: .health),
            FeedSource(name: "NIH Health News", url: "https://www.nlm.nih.gov/news/rss.xml", category: .health),
            FeedSource(name: "CDC Newsroom", url: "https://tools.cdc.gov/api/v2/resources/media/403372.rss", category: .health),
            FeedSource(name: "WHO News", url: "https://www.who.int/rss-feeds/news-english.xml", category: .health),
            FeedSource(name: "ScienceDaily Health", url: "https://www.sciencedaily.com/rss/health.xml", category: .health),
            FeedSource(name: "Nature Medical Research", url: "https://www.nature.com/subjects/medical-research.rss", category: .health),
            
            // MARK: Finance
            FeedSource(name: "MarketWatch", url: "https://www.marketwatch.com/rss/", category: .finance),
            FeedSource(name: "Bloomberg", url: "https://feeds.bloomberg.com/markets/news.rss", category: .finance),
            FeedSource(name: "Financial Times", url: "https://www.ft.com/rss/home", category: .finance),
            FeedSource(name: "The Economist", url: "https://www.economist.com/finance-and-economics/rss.xml", category: .finance),
            
            // MARK: Investing Category with Subcategories
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
            
            FeedSource(name: "Bon Appétit", url: "https://www.bonappetit.com/feed/rss", category: .food),
            FeedSource(name: "Serious Eats", url: "https://www.seriouseats.com/rss", category: .food),
            FeedSource(name: "Food & Wine", url: "https://www.foodandwine.com/rss", category: .food),
            FeedSource(name: "Eater", url: "https://www.eater.com/rss/index.xml", category: .food),
            FeedSource(name: "NYT Cooking", url: "https://rss.nytimes.com/services/xml/rss/nyt/DiningandWine.xml", category: .food),
            
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
        
        // Generate signals
        signalEngine.generateSignals(from: newsFeeds)
        
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
        
        // Track reading activity
        if let sourceName = feed.sourceName,
           let source = feedSources.first(where: { $0.name == sourceName }) {
            activityTracker.trackArticleRead(articleId: feed.id, category: source.category.rawValue)
        }
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
        // Force reset to new defaults (one-time migration for updated feeds)
        feedSources = Self.defaultFeedSources()
        saveFeedSources()
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
    
    /// Enrich articles with "Why This Matters" context AND spatial intelligence
    private func enrichArticlesWithContext(category: FeedCategory?, subcategory: InvestingSubcategory?) {
        // Step 1: Enrich with location data (async batch)
        Task {
            await enrichArticlesWithLocation()
        }
        
        // Step 2: Enrich with context (sync)
        newsFeeds = newsFeeds.map { article in
            var enrichedArticle = article
            
            // Determine category for context generation
            let contextCategory = category ?? selectedCategory
            
            // Determine sports subcategory if applicable
            var sportsSubcategory: SportsSubcategory? = nil
            if contextCategory == .sports {
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
    
    /// Enrich articles with location data (runs async, updates in place)
    private func enrichArticlesWithLocation() async {
        // Capture the current feeds to avoid mutation during iteration
        let currentFeeds = newsFeeds
        var enrichedFeeds = currentFeeds
        
        // Process articles in batches to avoid rate limiting
        for (index, article) in currentFeeds.enumerated() {
            if let location = await locationEngine.detectLocation(from: article) {
                enrichedFeeds[index].location = location
            }
            
            // Small delay to avoid geocoder rate limits (max 50 req/min)
            if index % 10 == 0 && index > 0 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
        
        // Update newsFeeds once at the end, on the main actor
        newsFeeds = enrichedFeeds
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
    
    // MARK: - Category Preferences
    func saveCategoryPreferences() {
        if let encoded = try? JSONEncoder().encode(categoryPreferences) {
            defaults.set(encoded, forKey: Keys.categoryPreferences)
        }
    }
    
    private func loadCategoryPreferences() {
        if let data = defaults.data(forKey: Keys.categoryPreferences),
           let decoded = try? JSONDecoder().decode([CategoryPreference].self, from: data) {
            categoryPreferences = decoded
        }
    }
    
    func enabledCategories() -> [FeedCategory] {
        categoryPreferences
            .filter { $0.isEnabled }
            .sorted { $0.priority < $1.priority }
            .map { $0.category }
    }
}
