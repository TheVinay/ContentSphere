import Foundation

// MARK: - Reading Activity Tracker
struct ReadingActivity: Codable {
    var articlesReadToday: [ArticleReadRecord] = []
    var articlesReadAllTime: [ArticleReadRecord] = []
    var categoryReadCounts: [String: Int] = [:]
    var lastReadDate: Date?
    var currentStreak: Int = 0
    var tabVisitCounts: [String: Int] = [:]
}

struct ArticleReadRecord: Codable {
    let articleId: UUID
    let date: Date
    let category: String
}

// MARK: - Puzzle Activity Tracker
struct PuzzleActivity: Codable {
    var gamesPlayedToday: [PuzzlePlayRecord] = []
    var gamesPlayedAllTime: [PuzzlePlayRecord] = []
    var currentPuzzleStreak: Int = 0
    var lastPuzzleDate: Date?
    var gameTypeCounts: [String: Int] = [:]
}

struct PuzzlePlayRecord: Codable {
    let gameType: String // "Quiz", "Word Target", "Sudoku"
    let date: Date
    let completed: Bool
}

// MARK: - Activity Tracker
@MainActor
class ActivityTracker: ObservableObject {
    @Published var readingActivity = ReadingActivity()
    @Published var puzzleActivity = PuzzleActivity()
    
    private let defaults = UserDefaults.standard
    private let readingKey = "reading_activity"
    private let puzzleKey = "puzzle_activity"
    
    init() {
        loadData()
    }
    
    // MARK: - Reading Tracking
    
    func trackArticleRead(articleId: UUID, category: String) {
        let record = ArticleReadRecord(articleId: articleId, date: Date(), category: category)
        
        // Add to all-time
        if !readingActivity.articlesReadAllTime.contains(where: { $0.articleId == articleId }) {
            readingActivity.articlesReadAllTime.append(record)
        }
        
        // Add to today if not already tracked
        if !readingActivity.articlesReadToday.contains(where: { $0.articleId == articleId }) {
            readingActivity.articlesReadToday.append(record)
        }
        
        // Update category count
        readingActivity.categoryReadCounts[category, default: 0] += 1
        
        // Update streak
        updateReadingStreak()
        
        // Clean old data
        cleanTodayRecords()
        
        saveData()
    }
    
    func trackTabVisit(_ tabName: String) {
        readingActivity.tabVisitCounts[tabName, default: 0] += 1
        saveData()
    }
    
    private func updateReadingStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastRead = readingActivity.lastReadDate {
            let lastReadDay = calendar.startOfDay(for: lastRead)
            let daysDiff = calendar.dateComponents([.day], from: lastReadDay, to: today).day ?? 0
            
            if daysDiff == 0 {
                // Same day, don't change streak
                return
            } else if daysDiff == 1 {
                // Consecutive day
                readingActivity.currentStreak += 1
            } else {
                // Streak broken
                readingActivity.currentStreak = 1
            }
        } else {
            // First article
            readingActivity.currentStreak = 1
        }
        
        readingActivity.lastReadDate = Date()
    }
    
    private func cleanTodayRecords() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        readingActivity.articlesReadToday.removeAll { record in
            let recordDay = calendar.startOfDay(for: record.date)
            return recordDay < today
        }
        
        puzzleActivity.gamesPlayedToday.removeAll { record in
            let recordDay = calendar.startOfDay(for: record.date)
            return recordDay < today
        }
    }
    
    // MARK: - Puzzle Tracking
    
    func trackPuzzlePlay(gameType: String, completed: Bool) {
        let record = PuzzlePlayRecord(gameType: gameType, date: Date(), completed: completed)
        
        puzzleActivity.gamesPlayedToday.append(record)
        puzzleActivity.gamesPlayedAllTime.append(record)
        puzzleActivity.gameTypeCounts[gameType, default: 0] += 1
        
        if completed {
            updatePuzzleStreak()
        }
        
        cleanTodayRecords()
        saveData()
    }
    
    private func updatePuzzleStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastPuzzle = puzzleActivity.lastPuzzleDate {
            let lastPuzzleDay = calendar.startOfDay(for: lastPuzzle)
            let daysDiff = calendar.dateComponents([.day], from: lastPuzzleDay, to: today).day ?? 0
            
            if daysDiff == 0 {
                return
            } else if daysDiff == 1 {
                puzzleActivity.currentPuzzleStreak += 1
            } else {
                puzzleActivity.currentPuzzleStreak = 1
            }
        } else {
            puzzleActivity.currentPuzzleStreak = 1
        }
        
        puzzleActivity.lastPuzzleDate = Date()
    }
    
    // MARK: - Computed Properties
    
    var articlesReadToday: Int {
        readingActivity.articlesReadToday.count
    }
    
    var articlesReadThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return readingActivity.articlesReadAllTime.filter { $0.date > weekAgo }.count
    }
    
    var articlesReadAllTime: Int {
        readingActivity.articlesReadAllTime.count
    }
    
    var mostReadCategory: String? {
        readingActivity.categoryReadCounts.max(by: { $0.value < $1.value })?.key
    }
    
    var mostVisitedTab: String? {
        readingActivity.tabVisitCounts.max(by: { $0.value < $1.value })?.key
    }
    
    var readingStreak: Int {
        readingActivity.currentStreak
    }
    
    var puzzlesPlayedToday: Int {
        puzzleActivity.gamesPlayedToday.count
    }
    
    var puzzlesPlayedAllTime: Int {
        puzzleActivity.gamesPlayedAllTime.count
    }
    
    var puzzleStreak: Int {
        puzzleActivity.currentPuzzleStreak
    }
    
    var mostPlayedGame: String? {
        puzzleActivity.gameTypeCounts.max(by: { $0.value < $1.value })?.key
    }
    
    // MARK: - Persistence
    
    private func saveData() {
        if let readingData = try? JSONEncoder().encode(readingActivity) {
            defaults.set(readingData, forKey: readingKey)
        }
        if let puzzleData = try? JSONEncoder().encode(puzzleActivity) {
            defaults.set(puzzleData, forKey: puzzleKey)
        }
    }
    
    private func loadData() {
        if let readingData = defaults.data(forKey: readingKey),
           let decoded = try? JSONDecoder().decode(ReadingActivity.self, from: readingData) {
            readingActivity = decoded
        }
        if let puzzleData = defaults.data(forKey: puzzleKey),
           let decoded = try? JSONDecoder().decode(PuzzleActivity.self, from: puzzleData) {
            puzzleActivity = decoded
        }
        
        cleanTodayRecords()
    }
}
