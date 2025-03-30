import Foundation

struct NewsFeed: Identifiable {
    let id = UUID()
    let title: String
    let link: String
    let thumbnail: String?
    let postDate: String?
    let content: String?
    let sourceName: String?
    var isBookmarked: Bool = false // Tracks whether the feed is bookmarked
}

struct FeedSource: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    var isSelected: Bool
    let category: FeedCategory
}

enum FeedCategory: String, CaseIterable {
    case News, Technology, Sports, Entertainment, HealthAndWellness, Finance, Food, Travel, Gaming
}

class RSSFeedViewModel: ObservableObject {
    // MARK: Published Properties
    @Published var feedSources: [FeedSource] = [
        FeedSource(name: "BBC", url: "https://feeds.bbci.co.uk/news/world/rss.xml", isSelected: true, category: .News),
        FeedSource(name: "CNN", url: "https://rss.cnn.com/rss/edition.rss", isSelected: true, category: .News),
        FeedSource(name: "Reuters", url: "https://feeds.reuters.com/reuters/topNews", isSelected: true, category: .News),
        FeedSource(name: "ESPN", url: "https://www.espn.com/espn/rss/news", isSelected: true, category: .Sports),
        FeedSource(name: "TechCrunch", url: "https://feeds.feedburner.com/TechCrunch", isSelected: true, category: .Technology),
        FeedSource(name: "Variety", url: "https://variety.com/feed/", isSelected: true, category: .Entertainment),
        FeedSource(name: "Art of Healthy Living", url: "https://artofhealthyliving.com/category/feed", isSelected: true, category: .HealthAndWellness),
        FeedSource(name: "Investopedia", url: "https://www.investopedia.com/rss/", isSelected: true, category: .Finance),
        FeedSource(name: "Skinnytaste", url: "https://www.skinnytaste.com/feed", isSelected: true, category: .Food),
        FeedSource(name: "Nomadic Matt", url: "https://www.nomadicmatt.com/feed/", isSelected: true, category: .Travel),
        FeedSource(name: "IGN", url: "https://feeds.ign.com/rss.xml", isSelected: true, category: .Gaming)
    ]
    @Published var newsFeeds: [NewsFeed] = [] // Stores fetched articles
    @Published var isDarkModeEnabled: Bool = false // Tracks dark mode toggle
    @Published var searchQuery: String = "" // Stores the search query for filtering feeds

    // MARK: Feed Fetching
    /// Fetch articles from feeds for a specific category
    func fetchRSSFeeds(for category: FeedCategory) {
        newsFeeds = [] // Clear existing feeds
        for source in feedSources where source.category == category && source.isSelected {
            guard let url = URL(string: source.url) else { continue }
            let task = URLSession.shared.dataTask(with: url) { data, _, error in
                if let data = data, error == nil {
                    let parser = RSSParser()
                    if let feeds = parser.parse(data: data) {
                        DispatchQueue.main.async {
                            self.newsFeeds.append(contentsOf: feeds)
                        }
                    }
                }
            }
            task.resume()
        }
    }

    // MARK: Bookmark Management
    /// Toggle the bookmark state of a feed
    func toggleBookmark(for feed: NewsFeed) {
        if let index = newsFeeds.firstIndex(where: { $0.id == feed.id }) {
            newsFeeds[index].isBookmarked.toggle()
        }
    }

    // MARK: Feed Source Management
    /// Toggle whether a feed source is enabled or disabled
    func toggleFeedSelection(for feed: FeedSource) {
        if let index = feedSources.firstIndex(where: { $0.id == feed.id }) {
            feedSources[index].isSelected.toggle()
        }
    }

    // MARK: Dark Mode Management
    /// Toggle the dark mode setting
    func toggleDarkMode() {
        isDarkModeEnabled.toggle()
    }

    // MARK: Search Filtering
    /// Filter feeds based on the search query
    func searchFeeds() -> [NewsFeed] {
        if searchQuery.isEmpty {
            return newsFeeds
        } else {
            return newsFeeds.filter { $0.title.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
}
