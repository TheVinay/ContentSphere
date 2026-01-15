import Foundation

// MARK: - Article Context
struct ArticleContext: Codable, Hashable {
    let reason: String
    let confidence: Double
    let type: ContextType
    
    enum ContextType: String, Codable {
        case categoryRelevance   // Based on category/subcategory
        case personalInterest    // Based on reading history
        case marketImpact        // Financial/economic significance
        case crossCategory       // Affects multiple areas
        case trending            // Multiple sources covering
        case timeSensitive       // Breaking/urgent
    }
    
    var displayColor: String {
        switch type {
        case .categoryRelevance: return "blue"
        case .personalInterest: return "purple"
        case .marketImpact: return "orange"
        case .crossCategory: return "teal"
        case .trending: return "red"
        case .timeSensitive: return "pink"
        }
    }
}

// MARK: - Intelligence Engine
@MainActor
class ArticleIntelligenceEngine {
    
    // MARK: - Context Generation
    
    /// Generate contextual explanation for why an article matters
    func generateContext(
        for article: NewsFeed,
        category: FeedCategory,
        subcategory: InvestingSubcategory? = nil,
        sportsSubcategory: SportsSubcategory? = nil,
        userReadHistory: Set<UUID>,
        userBookmarks: Set<UUID>
    ) -> ArticleContext? {
        
        var contexts: [(context: ArticleContext, score: Double)] = []
        
        // 1. Category-specific context
        if let categoryContext = generateCategoryContext(article, category, subcategory, sportsSubcategory) {
            contexts.append((categoryContext, categoryContext.confidence))
        }
        
        // 2. Personal interest context
        if let personalContext = generatePersonalContext(article, userReadHistory, userBookmarks) {
            contexts.append((personalContext, personalContext.confidence))
        }
        
        // 3. Market impact context (for finance/investing)
        if category == .finance || category == .investing {
            if let marketContext = generateMarketImpactContext(article, subcategory) {
                contexts.append((marketContext, marketContext.confidence))
            }
        }
        
        // 4. Time-sensitive context
        if let timeContext = generateTimeSensitiveContext(article) {
            contexts.append((timeContext, timeContext.confidence))
        }
        
        // Pick best context with confidence > 0.6
        let bestContext = contexts
            .filter { $0.score > 0.6 }
            .max(by: { $0.score < $1.score })
        
        return bestContext?.context
    }
    
    // MARK: - Category Context
    
    private func generateCategoryContext(
        _ article: NewsFeed,
        _ category: FeedCategory,
        _ subcategory: InvestingSubcategory?,
        _ sportsSubcategory: SportsSubcategory?
    ) -> ArticleContext? {
        
        let title = article.title.lowercased()
        let content = article.displayContent.lowercased()
        
        switch category {
        case .technology:
            if containsAny(in: title + content, keywords: ["ai", "artificial intelligence", "machine learning", "chatgpt", "openai"]) {
                return ArticleContext(
                    reason: "Impacts AI development and tech industry trends",
                    confidence: 0.85,
                    type: .categoryRelevance
                )
            }
            if containsAny(in: title + content, keywords: ["iphone", "apple", "ios", "macos", "vision pro"]) {
                return ArticleContext(
                    reason: "Affects Apple ecosystem and consumer tech",
                    confidence: 0.8,
                    type: .categoryRelevance
                )
            }
            if containsAny(in: title + content, keywords: ["regulation", "privacy", "antitrust", "policy"]) {
                return ArticleContext(
                    reason: "Shapes tech industry regulations and policy",
                    confidence: 0.75,
                    type: .categoryRelevance
                )
            }
            
        case .investing:
            if let sub = subcategory {
                return generateInvestingSubcategoryContext(article, sub)
            }
            
        case .sports:
            if let sportsSub = sportsSubcategory {
                return ArticleContext(
                    reason: "Latest updates in \(sportsSub.rawValue)",
                    confidence: 0.75,
                    type: .categoryRelevance
                )
            }
            
        case .finance:
            if containsAny(in: title + content, keywords: ["fed", "federal reserve", "interest rate", "inflation"]) {
                return ArticleContext(
                    reason: "Affects interest rates, mortgages, and market sentiment",
                    confidence: 0.9,
                    type: .marketImpact
                )
            }
            if containsAny(in: title + content, keywords: ["recession", "gdp", "unemployment", "jobs"]) {
                return ArticleContext(
                    reason: "Indicates economic health and market conditions",
                    confidence: 0.85,
                    type: .marketImpact
                )
            }
            
        case .health:
            if containsAny(in: title + content, keywords: ["fda", "approval", "drug", "vaccine"]) {
                return ArticleContext(
                    reason: "May impact healthcare stocks and public health policy",
                    confidence: 0.75,
                    type: .crossCategory
                )
            }
            
        case .news:
            if containsAny(in: title + content, keywords: ["election", "vote", "congress", "senate"]) {
                return ArticleContext(
                    reason: "Could affect policy, markets, and regulations",
                    confidence: 0.8,
                    type: .crossCategory
                )
            }
            
        default:
            break
        }
        
        return nil
    }
    
    // MARK: - Investing Subcategory Context
    
    private func generateInvestingSubcategoryContext(
        _ article: NewsFeed,
        _ subcategory: InvestingSubcategory
    ) -> ArticleContext? {
        
        let title = article.title.lowercased()
        let content = article.displayContent.lowercased()
        
        switch subcategory {
        case .stocks:
            if containsAny(in: title + content, keywords: ["earnings", "revenue", "profit"]) {
                return ArticleContext(
                    reason: "Earnings reports affect stock valuations and sector trends",
                    confidence: 0.85,
                    type: .marketImpact
                )
            }
            
        case .etfs:
            if containsAny(in: title + content, keywords: ["inflow", "outflow", "assets under management"]) {
                return ArticleContext(
                    reason: "Fund flows indicate investor sentiment and allocation trends",
                    confidence: 0.8,
                    type: .marketImpact
                )
            }
            
        case .longTermThemes:
            if containsAny(in: title + content, keywords: ["ai", "clean energy", "healthcare innovation"]) {
                return ArticleContext(
                    reason: "Long-term growth theme with multi-year investment potential",
                    confidence: 0.85,
                    type: .categoryRelevance
                )
            }
            
        case .earningsAndFundamentals:
            return ArticleContext(
                reason: "Fundamental analysis for stock valuation and company health",
                confidence: 0.8,
                type: .categoryRelevance
            )
            
        case .dividendsAndIncome:
            if containsAny(in: title + content, keywords: ["dividend", "yield", "payout"]) {
                return ArticleContext(
                    reason: "Affects income investors and portfolio yield strategies",
                    confidence: 0.85,
                    type: .marketImpact
                )
            }
            
        case .portfolioStrategy:
            return ArticleContext(
                reason: "Portfolio construction and risk management insights",
                confidence: 0.75,
                type: .categoryRelevance
            )
            
        case .riskAndVolatility:
            if containsAny(in: title + content, keywords: ["vix", "volatility", "crash", "correction"]) {
                return ArticleContext(
                    reason: "Market risk indicators for defensive positioning",
                    confidence: 0.9,
                    type: .marketImpact
                )
            }
            
        case .macroAndRates:
            return ArticleContext(
                reason: "Macro trends affecting all asset classes and allocation",
                confidence: 0.85,
                type: .marketImpact
            )
        }
        
        return ArticleContext(
            reason: "Relevant to your \(subcategory.rawValue.lowercased()) focus",
            confidence: 0.7,
            type: .categoryRelevance
        )
    }
    
    // MARK: - Personal Interest Context
    
    private func generatePersonalContext(
        _ article: NewsFeed,
        _ userReadHistory: Set<UUID>,
        _ userBookmarks: Set<UUID>
    ) -> ArticleContext? {
        
        // If user has read/bookmarked similar source recently
        if userBookmarks.contains(article.id) {
            return ArticleContext(
                reason: "You bookmarked this for later reading",
                confidence: 1.0,
                type: .personalInterest
            )
        }
        
        // Simple heuristic: if from same source as bookmarked articles
        // (More sophisticated in Personal Memory Layer feature)
        if !userBookmarks.isEmpty {
            return ArticleContext(
                reason: "From sources you frequently bookmark",
                confidence: 0.65,
                type: .personalInterest
            )
        }
        
        return nil
    }
    
    // MARK: - Market Impact Context
    
    private func generateMarketImpactContext(
        _ article: NewsFeed,
        _ subcategory: InvestingSubcategory?
    ) -> ArticleContext? {
        
        let title = article.title.lowercased()
        let content = article.displayContent.lowercased()
        
        // Breaking financial news
        if containsAny(in: title + content, keywords: ["breaking", "just in", "developing"]) {
            if containsAny(in: title + content, keywords: ["market", "stocks", "trading"]) {
                return ArticleContext(
                    reason: "Breaking market news may trigger immediate price action",
                    confidence: 0.95,
                    type: .timeSensitive
                )
            }
        }
        
        // Analyst upgrades/downgrades
        if containsAny(in: title + content, keywords: ["upgrade", "downgrade", "rating", "target"]) {
            return ArticleContext(
                reason: "Analyst changes often move stock prices",
                confidence: 0.8,
                type: .marketImpact
            )
        }
        
        // Merger/acquisition
        if containsAny(in: title + content, keywords: ["merger", "acquisition", "takeover", "buyout"]) {
            return ArticleContext(
                reason: "M&A activity affects stock values and sector dynamics",
                confidence: 0.9,
                type: .marketImpact
            )
        }
        
        return nil
    }
    
    // MARK: - Time-Sensitive Context
    
    private func generateTimeSensitiveContext(_ article: NewsFeed) -> ArticleContext? {
        
        guard let postDate = article.postDate else { return nil }
        
        let hoursAgo = Date().timeIntervalSince(postDate) / 3600
        
        // Very recent (< 2 hours)
        if hoursAgo < 2 {
            let title = article.title.lowercased()
            if containsAny(in: title, keywords: ["breaking", "just in", "alert", "urgent"]) {
                return ArticleContext(
                    reason: "Breaking news from the last 2 hours",
                    confidence: 0.9,
                    type: .timeSensitive
                )
            }
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func containsAny(in text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}
