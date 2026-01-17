import Foundation

// MARK: - Search Engine
@MainActor
class SearchEngine {
    
    /// Parse natural language query and search feeds
    func search(query: String, in feeds: [NewsFeed]) -> [NewsFeed] {
        guard !query.isEmpty else { return feeds }
        
        let parsedQuery = parseQuery(query)
        
        return feeds.filter { feed in
            matchesCriteria(feed: feed, criteria: parsedQuery)
        }
    }
    
    /// Parse natural language query into search criteria
    private func parseQuery(_ query: String) -> SearchCriteria {
        let lowercased = query.lowercased()
        var criteria = SearchCriteria()
        
        // Extract date range
        criteria.dateRange = extractDateRange(from: lowercased)
        
        // Extract source
        criteria.source = extractSource(from: lowercased)
        
        // Extract category
        criteria.category = extractCategory(from: lowercased)
        
        // Extract keywords (remove date/source/category words)
        criteria.keywords = extractKeywords(from: lowercased)
        
        return criteria
    }
    
    // MARK: - Query Parsing
    
    private func extractDateRange(from query: String) -> DateRange? {
        let now = Date()
        let calendar = Calendar.current
        
        // Today
        if query.contains("today") {
            let startOfDay = calendar.startOfDay(for: now)
            return DateRange(start: startOfDay, end: now)
        }
        
        // Yesterday
        if query.contains("yesterday") {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: now) {
                let startOfYesterday = calendar.startOfDay(for: yesterday)
                let endOfYesterday = calendar.date(byAdding: .day, value: 1, to: startOfYesterday)!
                return DateRange(start: startOfYesterday, end: endOfYesterday)
            }
        }
        
        // Last week
        if query.contains("last week") || query.contains("past week") {
            if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) {
                return DateRange(start: weekAgo, end: now)
            }
        }
        
        // Last month
        if query.contains("last month") || query.contains("past month") {
            if let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) {
                return DateRange(start: monthAgo, end: now)
            }
        }
        
        // This week
        if query.contains("this week") {
            if let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) {
                return DateRange(start: startOfWeek, end: now)
            }
        }
        
        // Last 24 hours
        if query.contains("24 hours") || query.contains("last day") {
            if let dayAgo = calendar.date(byAdding: .hour, value: -24, to: now) {
                return DateRange(start: dayAgo, end: now)
            }
        }
        
        return nil
    }
    
    private func extractSource(from query: String) -> String? {
        let sources = ["bbc", "cnn", "reuters", "espn", "techcrunch", "guardian", 
                       "verge", "wired", "variety", "bloomberg", "marketwatch"]
        
        for source in sources {
            if query.contains(source) {
                return source
            }
        }
        
        // Check for "from [source]"
        if let fromRange = query.range(of: "from ") {
            let afterFrom = String(query[fromRange.upperBound...])
            let words = afterFrom.components(separatedBy: " ")
            if let firstWord = words.first, !firstWord.isEmpty {
                return firstWord
            }
        }
        
        return nil
    }
    
    private func extractCategory(from query: String) -> FeedCategory? {
        if query.contains("tech") || query.contains("technology") {
            return .technology
        }
        if query.contains("sport") {
            return .sports
        }
        if query.contains("news") {
            return .news
        }
        if query.contains("entertainment") || query.contains("movies") || query.contains("film") {
            return .entertainment
        }
        if query.contains("health") || query.contains("medical") {
            return .health
        }
        if query.contains("finance") || query.contains("business") || query.contains("market") {
            return .finance
        }
        if query.contains("food") || query.contains("recipe") {
            return .food
        }
        if query.contains("travel") {
            return .travel
        }
        if query.contains("gaming") || query.contains("games") {
            return .gaming
        }
        
        return nil
    }
    
    private func extractKeywords(from query: String) -> [String] {
        // Remove common words and date/source indicators
        let stopWords = ["the", "a", "an", "from", "about", "show", "me", "find", 
                        "get", "news", "articles", "article", "on", "in", "at",
                        "today", "yesterday", "last", "week", "month", "this"]
        
        var words = query.components(separatedBy: .whitespaces)
        words = words.filter { word in
            !stopWords.contains(word) && word.count > 2
        }
        
        return words
    }
    
    // MARK: - Matching
    
    private func matchesCriteria(feed: NewsFeed, criteria: SearchCriteria) -> Bool {
        // Check date range
        if let dateRange = criteria.dateRange {
            guard let feedDate = feed.postDate else { return false }
            if feedDate < dateRange.start || feedDate > dateRange.end {
                return false
            }
        }
        
        // Check source
        if let source = criteria.source {
            guard let feedSource = feed.sourceName?.lowercased() else { return false }
            if !feedSource.contains(source) {
                return false
            }
        }
        
        // Check keywords (any keyword matches)
        if !criteria.keywords.isEmpty {
            let title = feed.title.lowercased()
            let content = feed.displayContent.lowercased()
            
            let hasMatch = criteria.keywords.contains { keyword in
                title.contains(keyword) || content.contains(keyword)
            }
            
            if !hasMatch {
                return false
            }
        }
        
        return true
    }
}

// MARK: - Search Criteria

struct SearchCriteria {
    var keywords: [String] = []
    var dateRange: DateRange?
    var source: String?
    var category: FeedCategory?
}

struct DateRange {
    let start: Date
    let end: Date
}

// MARK: - Search Suggestions

extension SearchEngine {
    
    /// Generate search suggestions
    func generateSuggestions(for feeds: [NewsFeed]) -> [String] {
        var suggestions: [String] = []
        
        // Common queries
        suggestions.append("Tech news from today")
        suggestions.append("Sports news from yesterday")
        suggestions.append("Show me articles from BBC")
        suggestions.append("Finance news from last week")
        
        // Based on available sources
        let sources = Set(feeds.compactMap { $0.sourceName?.lowercased() })
        for source in sources.prefix(3) {
            suggestions.append("Latest from \(source)")
        }
        
        return suggestions
    }
    
    /// Get example queries
    static var exampleQueries: [String] {
        [
            "Tech news from yesterday",
            "Show me sports articles from ESPN",
            "Finance news from last week",
            "Articles about AI from today",
            "Entertainment news from this week",
            "Health articles from last month",
            "Gaming news from The Verge",
            "Food articles from today"
        ]
    }
}
