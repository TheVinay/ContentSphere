import Foundation

// MARK: - Summary Service
@available(iOS 18.2, *)
@MainActor
class SummaryService {
    static let shared = SummaryService()
    
    private init() {}
    
    /// Generate a summary for article content
    func generateSummary(for content: String) async throws -> ArticleSummary {
        // Import Foundation Models for AI summarization
        guard !content.isEmpty else {
            throw SummaryError.emptyContent
        }
        
        // Clean content (remove HTML, extra whitespace)
        let cleanedContent = cleanContent(content)
        
        // For now, create a basic summary
        // TODO: Integrate with Foundation Models when available
        let summary = try await createBasicSummary(from: cleanedContent)
        
        return summary
    }
    
    /// Generate key points from article
    func extractKeyPoints(from content: String, count: Int = 3) async throws -> [String] {
        let cleanedContent = cleanContent(content)
        let sentences = cleanedContent.components(separatedBy: ". ").filter { !$0.isEmpty }
        
        // Take first few sentences as key points for now
        let keyPoints = Array(sentences.prefix(min(count, sentences.count)))
        return keyPoints.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    /// Analyze sentiment of article
    func analyzeSentiment(for content: String) async -> ArticleSentiment {
        let cleanedContent = cleanContent(content).lowercased()
        
        // Simple sentiment analysis based on keywords
        let positiveWords = ["good", "great", "excellent", "amazing", "positive", "success", "win", "best"]
        let negativeWords = ["bad", "terrible", "negative", "fail", "worst", "crisis", "problem", "concern"]
        
        var positiveCount = 0
        var negativeCount = 0
        
        for word in positiveWords {
            positiveCount += cleanedContent.components(separatedBy: word).count - 1
        }
        
        for word in negativeWords {
            negativeCount += cleanedContent.components(separatedBy: word).count - 1
        }
        
        if positiveCount > negativeCount {
            return .positive
        } else if negativeCount > positiveCount {
            return .negative
        } else {
            return .neutral
        }
    }
    
    // MARK: - Helper Methods
    
    private func cleanContent(_ content: String) -> String {
        // Remove HTML tags
        var cleaned = content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Remove extra whitespace
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Trim
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
    
    private func createBasicSummary(from content: String) async throws -> ArticleSummary {
        // Extract first paragraph as summary
        let paragraphs = content.components(separatedBy: "\n\n").filter { !$0.isEmpty }
        let summaryText = paragraphs.first ?? content
        
        // Limit to ~200 characters
        let truncated = summaryText.prefix(200)
        let summary = String(truncated) + (summaryText.count > 200 ? "..." : "")
        
        // Extract key points
        let keyPoints = try await extractKeyPoints(from: content)
        
        // Analyze sentiment
        let sentiment = await analyzeSentiment(for: content)
        
        // Estimate reading time (average 200 words per minute)
        let wordCount = content.components(separatedBy: .whitespaces).count
        let readingTime = max(1, wordCount / 200)
        
        return ArticleSummary(
            summary: summary,
            keyPoints: keyPoints,
            sentiment: sentiment,
            readingTimeMinutes: readingTime,
            wordCount: wordCount
        )
    }
}

// MARK: - Fallback for older iOS versions
@MainActor
class LegacySummaryService {
    static let shared = LegacySummaryService()
    
    private init() {}
    
    func generateSummary(for content: String) async throws -> ArticleSummary {
        let cleanedContent = cleanContent(content)
        
        // Simple summary - first 200 chars
        let summaryText = String(cleanedContent.prefix(200)) + "..."
        
        // Extract key points
        let sentences = cleanedContent.components(separatedBy: ". ").filter { !$0.isEmpty }
        let keyPoints = Array(sentences.prefix(3))
        
        // Basic word count
        let wordCount = cleanedContent.components(separatedBy: .whitespaces).count
        let readingTime = max(1, wordCount / 200)
        
        return ArticleSummary(
            summary: summaryText,
            keyPoints: keyPoints,
            sentiment: .neutral,
            readingTimeMinutes: readingTime,
            wordCount: wordCount
        )
    }
    
    private func cleanContent(_ content: String) -> String {
        var cleaned = content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Models

struct ArticleSummary: Codable {
    let summary: String
    let keyPoints: [String]
    let sentiment: ArticleSentiment
    let readingTimeMinutes: Int
    let wordCount: Int
    
    var readingTimeText: String {
        "\(readingTimeMinutes) min read"
    }
}

enum ArticleSentiment: String, Codable {
    case positive
    case negative
    case neutral
    
    var emoji: String {
        switch self {
        case .positive: return "😊"
        case .negative: return "😟"
        case .neutral: return "😐"
        }
    }
    
    var color: String {
        switch self {
        case .positive: return "green"
        case .negative: return "red"
        case .neutral: return "gray"
        }
    }
}

// MARK: - Errors

enum SummaryError: Error, LocalizedError {
    case emptyContent
    case generationFailed
    case notAvailable
    
    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "No content to summarize"
        case .generationFailed:
            return "Failed to generate summary"
        case .notAvailable:
            return "Summary service not available"
        }
    }
}
