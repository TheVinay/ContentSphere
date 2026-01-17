import Foundation

// MARK: - Signal Model
struct Signal: Identifiable, Codable {
    let id: UUID
    let message: String
    let date: Date
    let type: SignalType
    
    init(id: UUID = UUID(), message: String, date: Date = Date(), type: SignalType) {
        self.id = id
        self.message = message
        self.date = date
        self.type = type
    }
    
    enum SignalType: String, Codable {
        case topicMomentum
        case crossSourceConvergence
    }
}

// MARK: - Signal Engine
@MainActor
class SignalEngine: ObservableObject {
    @Published var todaysSignals: [Signal] = []
    
    private let defaults = UserDefaults.standard
    private let signalsKey = "signals_data"
    private let topicHistoryKey = "topic_history"
    
    init() {
        loadSignals()
    }
    
    // MARK: - Signal Generation
    
    func generateSignals(from feeds: [NewsFeed]) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Clear old signals if they're from previous day
        if let lastSignalDate = todaysSignals.first?.date,
           Calendar.current.startOfDay(for: lastSignalDate) < today {
            todaysSignals = []
        }
        
        // Generate new signals
        var newSignals: [Signal] = []
        
        // 1. Topic Momentum signals
        newSignals.append(contentsOf: generateTopicMomentumSignals(from: feeds))
        
        // 2. Cross-Source Convergence signals
        newSignals.append(contentsOf: generateCrossSourceSignals(from: feeds))
        
        // Limit to 5 signals max
        todaysSignals = Array(newSignals.prefix(5))
        
        // Save
        saveSignals()
        updateTopicHistory(from: feeds)
    }
    
    // MARK: - Topic Momentum
    
    private func generateTopicMomentumSignals(from feeds: [NewsFeed]) -> [Signal] {
        var signals: [Signal] = []
        
        // Get today's articles
        let today = Calendar.current.startOfDay(for: Date())
        let todayFeeds = feeds.filter { feed in
            guard let date = feed.postDate else { return false }
            return Calendar.current.startOfDay(for: date) == today
        }
        
        guard !todayFeeds.isEmpty else { return [] }
        
        // Extract topics from today
        let topics = extractTopics(from: todayFeeds)
        
        // Load historical baseline (7-day average)
        let baseline = loadTopicBaseline()
        
        // Find topics with momentum
        for (topic, todayCount) in topics {
            let historicalAverage = baseline[topic] ?? 0.0
            
            // Trigger if today's count is at least 3 and 2x historical average
            if todayCount >= 3 && Double(todayCount) >= (historicalAverage * 2.0) {
                let sourceCount = countDistinctSources(for: topic, in: todayFeeds)
                
                let message = "\(topic.capitalized) appeared in \(todayCount) articles today across \(sourceCount) sources"
                signals.append(Signal(message: message, type: .topicMomentum))
            }
        }
        
        return signals
    }
    
    // MARK: - Cross-Source Convergence
    
    private func generateCrossSourceSignals(from feeds: [NewsFeed]) -> [Signal] {
        var signals: [Signal] = []
        
        // Get today's articles
        let today = Calendar.current.startOfDay(for: Date())
        let todayFeeds = feeds.filter { feed in
            guard let date = feed.postDate else { return false }
            return Calendar.current.startOfDay(for: date) == today
        }
        
        guard !todayFeeds.isEmpty else { return [] }
        
        // Extract topics
        let topics = extractTopics(from: todayFeeds)
        
        // High credibility sources
        let highCredSources = Set([
            "BBC News", "Reuters", "The Guardian", "Bloomberg",
            "Financial Times", "Wall Street Journal", "Associated Press"
        ])
        
        // Find topics covered by multiple sources
        for (topic, count) in topics where count >= 4 {
            let sourceCount = countDistinctSources(for: topic, in: todayFeeds)
            
            if sourceCount >= 4 {
                // Check if high-cred sources are covering it
                let sourcesForTopic = todayFeeds
                    .filter { containsTopic(topic, in: $0) }
                    .compactMap { $0.sourceName }
                
                let highCredCount = Set(sourcesForTopic).intersection(highCredSources).count
                
                if highCredCount >= 2 {
                    let message = "This topic (\(topic)) is being covered by multiple high-credibility outlets"
                    signals.append(Signal(message: message, type: .crossSourceConvergence))
                } else if sourceCount >= 5 {
                    let message = "\(topic.capitalized) is being reported by \(sourceCount) different sources today"
                    signals.append(Signal(message: message, type: .crossSourceConvergence))
                }
            }
        }
        
        return signals
    }
    
    // MARK: - Topic Extraction
    
    private func extractTopics(from feeds: [NewsFeed]) -> [String: Int] {
        var topicCounts: [String: Int] = [:]
        
        let keywords = [
            "ai", "artificial intelligence", "chatgpt", "regulation",
            "inflation", "interest rate", "federal reserve", "recession",
            "climate", "vaccine", "covid", "election", "china",
            "ukraine", "russia", "market", "stock", "crypto",
            "tesla", "apple", "microsoft", "amazon", "meta",
            "earnings", "profit", "revenue", "dividend", "yield"
        ]
        
        for feed in feeds {
            let text = (feed.title + " " + feed.displayContent).lowercased()
            
            for keyword in keywords {
                if text.contains(keyword) {
                    topicCounts[keyword, default: 0] += 1
                }
            }
        }
        
        return topicCounts
    }
    
    private func containsTopic(_ topic: String, in feed: NewsFeed) -> Bool {
        let text = (feed.title + " " + feed.displayContent).lowercased()
        return text.contains(topic.lowercased())
    }
    
    private func countDistinctSources(for topic: String, in feeds: [NewsFeed]) -> Int {
        let sources = feeds
            .filter { containsTopic(topic, in: $0) }
            .compactMap { $0.sourceName }
        
        return Set(sources).count
    }
    
    // MARK: - Topic History & Baseline
    
    private func updateTopicHistory(from feeds: [NewsFeed]) {
        let today = Calendar.current.startOfDay(for: Date())
        let topics = extractTopics(from: feeds.filter { feed in
            guard let date = feed.postDate else { return false }
            return Calendar.current.startOfDay(for: date) == today
        })
        
        var history = loadTopicHistory()
        
        // Store today's counts
        for (topic, count) in topics {
            if history[topic] == nil {
                history[topic] = []
            }
            history[topic]?.append((date: today, count: count))
            
            // Keep only last 7 days
            history[topic] = history[topic]?.filter { entry in
                let daysDiff = Calendar.current.dateComponents([.day], from: entry.date, to: today).day ?? 0
                return daysDiff < 7
            }
        }
        
        saveTopicHistory(history)
    }
    
    private func loadTopicBaseline() -> [String: Double] {
        let history = loadTopicHistory()
        var baseline: [String: Double] = [:]
        
        for (topic, entries) in history {
            let average = Double(entries.map { $0.count }.reduce(0, +)) / Double(max(entries.count, 1))
            baseline[topic] = average
        }
        
        return baseline
    }
    
    // MARK: - Persistence
    
    private func saveSignals() {
        if let encoded = try? JSONEncoder().encode(todaysSignals) {
            defaults.set(encoded, forKey: signalsKey)
        }
    }
    
    private func loadSignals() {
        if let data = defaults.data(forKey: signalsKey),
           let decoded = try? JSONDecoder().decode([Signal].self, from: data) {
            todaysSignals = decoded
        }
    }
    
    private func saveTopicHistory(_ history: [String: [(date: Date, count: Int)]]) {
        // Convert to encodable format
        let encodableHistory = history.mapValues { entries in
            entries.map { ["date": $0.date.timeIntervalSince1970, "count": Double($0.count)] }
        }
        
        if let encoded = try? JSONSerialization.data(withJSONObject: encodableHistory) {
            defaults.set(encoded, forKey: topicHistoryKey)
        }
    }
    
    private func loadTopicHistory() -> [String: [(date: Date, count: Int)]] {
        guard let data = defaults.data(forKey: topicHistoryKey),
              let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: [[String: Double]]] else {
            return [:]
        }
        
        var history: [String: [(date: Date, count: Int)]] = [:]
        
        for (topic, entries) in decoded {
            history[topic] = entries.compactMap { entry in
                guard let timestamp = entry["date"],
                      let count = entry["count"] else { return nil }
                return (date: Date(timeIntervalSince1970: timestamp), count: Int(count))
            }
        }
        
        return history
    }
}
