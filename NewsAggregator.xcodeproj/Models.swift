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
    
    init(
        id: UUID = UUID(),
        title: String,
        link: String,
        thumbnail: String? = nil,
        postDate: Date? = nil,
        content: String? = nil,
        sourceName: String? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.title = title
        self.link = link
        self.thumbnail = thumbnail
        self.postDate = postDate
        self.content = content
        self.sourceName = sourceName
        self.description = description
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
    
    init(
        id: UUID = UUID(),
        name: String,
        url: String,
        isSelected: Bool = true,
        category: FeedCategory
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.isSelected = isSelected
        self.category = category
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
        case .food: return "yellow"
        case .travel: return "cyan"
        case .gaming: return "indigo"
        }
    }
}

// MARK: - Loading State
enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}
