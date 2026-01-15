import Foundation

// MARK: - News Feed Model
struct NewsFeed: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let link: String
    let thumbnail: String?
    let postDate: Date?
    let content: String?
    let sourceName: String?
    let description: String?
    var context: ArticleContext? // "Why This Matters" intelligence
    
    init(
        id: UUID = UUID(),
        title: String,
        link: String,
        thumbnail: String? = nil,
        postDate: Date? = nil,
        content: String? = nil,
        sourceName: String? = nil,
        description: String? = nil,
        context: ArticleContext? = nil
    ) {
        self.id = id
        self.title = title
        self.link = link
        self.thumbnail = thumbnail
        self.postDate = postDate
        self.content = content
        self.sourceName = sourceName
        self.description = description
        self.context = context
    }
    
    var formattedDate: String {
        guard let date = postDate else { return "Unknown Date" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var displayContent: String {
        // Strip HTML tags from content or description
        let text = content ?? description ?? "No content available"
        return text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
// MARK: - Feed Source Model
struct FeedSource: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let url: String
    var isSelected: Bool
    let category: FeedCategory
    let subcategory: InvestingSubcategory?
    let sportsSubcategory: SportsSubcategory?
    
    init(
        id: UUID = UUID(),
        name: String,
        url: String,
        isSelected: Bool = true,
        category: FeedCategory,
        subcategory: InvestingSubcategory? = nil,
        sportsSubcategory: SportsSubcategory? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.isSelected = isSelected
        self.category = category
        self.subcategory = subcategory
        self.sportsSubcategory = sportsSubcategory
    }
}

// MARK: - Feed Category
enum FeedCategory: String, CaseIterable, Codable {
    case news = "News"
    case technology = "Technology"
    case sports = "Sports"
    case entertainment = "Entertainment"
    case health = "Health"
    case finance = "Finance"
    case investing = "Investing"
    case food = "Food"
    case travel = "Travel"
    case gaming = "Gaming"
    
    var iconName: String {
        switch self {
        case .news: return "newspaper"
        case .technology: return "cpu"
        case .sports: return "sportscourt"
        case .entertainment: return "film"
        case .health: return "heart"
        case .finance: return "chart.line.uptrend.xyaxis"
        case .investing: return "chart.bar.fill"
        case .food: return "fork.knife"
        case .travel: return "airplane"
        case .gaming: return "gamecontroller"
        }
    }
    
    var color: String {
        switch self {
        case .news: return "blue"
        case .technology: return "purple"
        case .sports: return "green"
        case .entertainment: return "pink"
        case .health: return "red"
        case .finance: return "orange"
        case .investing: return "teal"
        case .food: return "yellow"
        case .travel: return "cyan"
        case .gaming: return "indigo"
        }
    }
    
    var hasSubcategories: Bool {
        self == .investing || self == .sports
    }
    
    var investingSubcategories: [InvestingSubcategory]? {
        guard self == .investing else { return nil }
        return InvestingSubcategory.allCases
    }
    
    var sportsSubcategories: [SportsSubcategory]? {
        guard self == .sports else { return nil }
        return SportsSubcategory.allCases
    }
}

// MARK: - Investing Subcategories
enum InvestingSubcategory: String, CaseIterable, Codable {
    case stocks = "Stocks"
    case etfs = "ETFs"
    case longTermThemes = "Long-Term Themes"
    case earningsAndFundamentals = "Earnings & Fundamentals"
    case dividendsAndIncome = "Dividends & Income"
    case portfolioStrategy = "Portfolio Strategy"
    case riskAndVolatility = "Risk & Volatility"
    case macroAndRates = "Macro & Rates"
    
    var iconName: String {
        switch self {
        case .stocks: return "chart.line.uptrend.xyaxis"
        case .etfs: return "square.grid.3x3.fill"
        case .longTermThemes: return "lightbulb.fill"
        case .earningsAndFundamentals: return "doc.text.magnifyingglass"
        case .dividendsAndIncome: return "dollarsign.circle.fill"
        case .portfolioStrategy: return "briefcase.fill"
        case .riskAndVolatility: return "waveform.path.ecg"
        case .macroAndRates: return "globe.americas.fill"
        }
    }
    
    var description: String {
        switch self {
        case .stocks: return "Individual stock analysis and news"
        case .etfs: return "Exchange-traded funds and index investing"
        case .longTermThemes: return "AI, Energy, Healthcare, Tech trends"
        case .earningsAndFundamentals: return "Company earnings, financials, analysis"
        case .dividendsAndIncome: return "Dividend stocks and income strategies"
        case .portfolioStrategy: return "Asset allocation and portfolio building"
        case .riskAndVolatility: return "Risk management and market volatility"
        case .macroAndRates: return "Economic trends, Fed policy, interest rates"
        }
    }
    
    var keywords: [String] {
        switch self {
        case .stocks:
            return ["stock", "shares", "equity", "nasdaq", "dow", "s&p"]
        case .etfs:
            return ["etf", "index", "fund", "vanguard", "ishares", "spdr"]
        case .longTermThemes:
            return ["ai", "artificial intelligence", "energy", "healthcare", "innovation", "technology", "renewable", "biotech"]
        case .earningsAndFundamentals:
            return ["earnings", "revenue", "profit", "eps", "balance sheet", "cash flow", "fundamentals"]
        case .dividendsAndIncome:
            return ["dividend", "yield", "income", "payout", "aristocrat"]
        case .portfolioStrategy:
            return ["portfolio", "allocation", "diversification", "rebalance", "strategy"]
        case .riskAndVolatility:
            return ["risk", "volatility", "vix", "hedge", "protection", "downside"]
        case .macroAndRates:
            return ["fed", "federal reserve", "interest rate", "inflation", "gdp", "macro", "economy", "bonds"]
        }
    }
}

// MARK: - Sports Subcategories
enum SportsSubcategory: String, CaseIterable, Codable {
    case football = "Football"
    case basketball = "Basketball"
    case baseball = "Baseball"
    case soccer = "Soccer"
    case hockey = "Hockey"
    case tennis = "Tennis"
    case golf = "Golf"
    case racing = "Racing"
    case combat = "Combat Sports"
    
    var iconName: String {
        switch self {
        case .football: return "football.fill"
        case .basketball: return "basketball.fill"
        case .baseball: return "baseball.fill"
        case .soccer: return "soccerball"
        case .hockey: return "hockey.puck.fill"
        case .tennis: return "tennis.racket"
        case .golf: return "figure.golf"
        case .racing: return "car.fill"
        case .combat: return "figure.boxing"
        }
    }
    
    var description: String {
        switch self {
        case .football: return "NFL, College Football"
        case .basketball: return "NBA, NCAA Basketball"
        case .baseball: return "MLB, Minor League"
        case .soccer: return "Premier League, MLS, International"
        case .hockey: return "NHL, Hockey News"
        case .tennis: return "ATP, WTA, Grand Slams"
        case .golf: return "PGA, Golf Tournaments"
        case .racing: return "F1, NASCAR, IndyCar"
        case .combat: return "Boxing, MMA, UFC"
        }
    }
}

// MARK: - Sports Preference (for ordering)
struct SportsPreference: Identifiable, Codable {
    let id: UUID
    let subcategory: SportsSubcategory
    var isEnabled: Bool
    var priority: Int
    
    init(id: UUID = UUID(), subcategory: SportsSubcategory, isEnabled: Bool = true, priority: Int) {
        self.id = id
        self.subcategory = subcategory
        self.isEnabled = isEnabled
        self.priority = priority
    }
}

// MARK: - Loading State
enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

