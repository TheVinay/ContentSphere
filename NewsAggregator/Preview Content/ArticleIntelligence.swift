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

// MARK: - What This Means (Implications)
struct ArticleImplications: Codable, Hashable {
    let bullets: [String]
    
    /// Returns true if there are meaningful implications to show
    var hasImplications: Bool {
        !bullets.isEmpty
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
    
    // MARK: - Article Implications ("What This Means")
    
    /// Generate "What This Means" bullet points for an article
    /// Returns up to 3 implication bullets based on category, keywords, and context
    func generateImplications(
        for article: NewsFeed,
        category: FeedCategory?,
        subcategory: InvestingSubcategory? = nil,
        sportsSubcategory: SportsSubcategory? = nil
    ) -> ArticleImplications? {
        
        let title = article.title.lowercased()
        let content = article.displayContent.lowercased()
        let combinedText = title + " " + content
        
        var bullets: [String] = []
        
        // Category-specific implications
        if let cat = category {
            bullets = generateCategoryImplications(cat, title: title, content: combinedText, subcategory: subcategory, sportsSubcategory: sportsSubcategory)
        }
        
        // Cross-cutting implications (political, regulatory, etc.)
        bullets.append(contentsOf: generateCrossCuttingImplications(title: title, content: combinedText))
        
        // Limit to 3 bullets
        let finalBullets = Array(bullets.prefix(3))
        
        guard !finalBullets.isEmpty else { return nil }
        
        return ArticleImplications(bullets: finalBullets)
    }
    
    // MARK: - Category-Specific Implications
    
    private func generateCategoryImplications(
        _ category: FeedCategory,
        title: String,
        content: String,
        subcategory: InvestingSubcategory?,
        sportsSubcategory: SportsSubcategory?
    ) -> [String] {
        
        var bullets: [String] = []
        
        switch category {
        case .technology:
            if containsAny(in: content, keywords: ["ai", "artificial intelligence", "machine learning", "chatgpt"]) {
                bullets.append("Could reshape labor markets and productivity expectations")
                bullets.append("May influence tech stock valuations and investor sentiment")
            }
            if containsAny(in: content, keywords: ["privacy", "data", "regulation", "antitrust"]) {
                bullets.append("Signals potential regulatory changes for tech companies")
                bullets.append("May affect how platforms collect and monetize user data")
            }
            if containsAny(in: content, keywords: ["iphone", "apple", "ios", "vision pro"]) {
                bullets.append("Could impact Apple's product roadmap and pricing strategy")
            }
            if containsAny(in: content, keywords: ["layoff", "hiring", "job cuts"]) {
                bullets.append("Indicates shifting priorities in the tech sector")
            }
            
        case .investing:
            if let sub = subcategory {
                bullets.append(contentsOf: generateInvestingImplications(sub, title: title, content: content))
            } else {
                // General investing
                if containsAny(in: content, keywords: ["bull market", "rally", "surge"]) {
                    bullets.append("Suggests positive momentum for equity allocations")
                }
                if containsAny(in: content, keywords: ["correction", "sell-off", "decline"]) {
                    bullets.append("May create buying opportunities for long-term investors")
                }
            }
            
        case .finance:
            if containsAny(in: content, keywords: ["fed", "federal reserve", "interest rate", "rate hike", "rate cut"]) {
                bullets.append("Affects mortgage rates, savings yields, and borrowing costs")
                bullets.append("Could shift allocation between bonds and equities")
            }
            if containsAny(in: content, keywords: ["inflation", "cpi", "consumer prices"]) {
                bullets.append("Influences purchasing power and cost of living")
                bullets.append("May affect Fed policy and market expectations")
            }
            if containsAny(in: content, keywords: ["recession", "economic downturn", "gdp"]) {
                bullets.append("Signals potential headwinds for corporate earnings")
                bullets.append("Could favor defensive sectors and quality stocks")
            }
            if containsAny(in: content, keywords: ["unemployment", "jobs", "labor market"]) {
                bullets.append("Indicates economic health and consumer spending power")
            }
            
        case .health:
            if containsAny(in: content, keywords: ["fda", "approval", "drug", "treatment"]) {
                bullets.append("May impact healthcare and biotech stock prices")
                bullets.append("Could change treatment options for patients")
            }
            if containsAny(in: content, keywords: ["vaccine", "pandemic", "outbreak"]) {
                bullets.append("Could influence public health policy debates")
                bullets.append("May affect travel, hospitality, and pharmaceutical sectors")
            }
            if containsAny(in: content, keywords: ["medicare", "insurance", "healthcare cost"]) {
                bullets.append("Signals potential changes in healthcare affordability")
            }
            
        case .news:
            if containsAny(in: content, keywords: ["election", "vote", "campaign"]) {
                bullets.append("Could affect policy direction and market regulations")
                bullets.append("May influence sector-specific legislation")
            }
            if containsAny(in: content, keywords: ["climate", "environment", "emissions"]) {
                bullets.append("Signals policy shifts affecting energy and transportation")
                bullets.append("May accelerate clean energy investment themes")
            }
            if containsAny(in: content, keywords: ["trade", "tariff", "sanctions"]) {
                bullets.append("Could disrupt global supply chains and pricing")
                bullets.append("May affect multinational corporations and importers")
            }
            
        case .sports:
            if containsAny(in: content, keywords: ["injury", "out for season"]) {
                bullets.append("Could shift playoff odds and team performance expectations")
            }
            if containsAny(in: content, keywords: ["trade", "signing", "contract"]) {
                bullets.append("May reshape competitive balance and team dynamics")
            }
            if containsAny(in: content, keywords: ["controversy", "suspension", "investigation"]) {
                bullets.append("Could affect team reputation and sponsor relationships")
            }
            
        case .entertainment:
            if containsAny(in: content, keywords: ["strike", "union", "writers", "actors"]) {
                bullets.append("May delay productions and affect streaming content pipelines")
                bullets.append("Signals broader labor issues in entertainment industry")
            }
            if containsAny(in: content, keywords: ["box office", "streaming", "ratings"]) {
                bullets.append("Indicates shifting consumer preferences in media")
            }
            
        case .gaming:
            if containsAny(in: content, keywords: ["console", "playstation", "xbox", "nintendo"]) {
                bullets.append("Could influence gaming hardware sales and ecosystem growth")
            }
            if containsAny(in: content, keywords: ["microtransaction", "regulation", "loot box"]) {
                bullets.append("May affect game monetization and industry practices")
            }
            
        case .food:
            if containsAny(in: content, keywords: ["recall", "contamination", "safety"]) {
                bullets.append("Signals potential health risks and supply disruptions")
            }
            if containsAny(in: content, keywords: ["shortage", "supply chain", "price"]) {
                bullets.append("Could affect grocery costs and restaurant pricing")
            }
            
        case .travel:
            if containsAny(in: content, keywords: ["airline", "flight", "cancellation"]) {
                bullets.append("May impact travel plans and booking strategies")
            }
            if containsAny(in: content, keywords: ["restriction", "border", "visa"]) {
                bullets.append("Could affect international travel accessibility")
            }
        }
        
        return bullets
    }
    
    // MARK: - Investing Subcategory Implications
    
    private func generateInvestingImplications(
        _ subcategory: InvestingSubcategory,
        title: String,
        content: String
    ) -> [String] {
        
        var bullets: [String] = []
        
        switch subcategory {
        case .stocks:
            if containsAny(in: content, keywords: ["earnings beat", "exceeds expectations", "revenue growth"]) {
                bullets.append("May drive upward price momentum and analyst upgrades")
                bullets.append("Signals strong fundamentals for the company")
            }
            if containsAny(in: content, keywords: ["earnings miss", "disappoints", "guidance lower"]) {
                bullets.append("Could trigger sell-off and downward revisions")
                bullets.append("May present buying opportunity if reaction is overblown")
            }
            if containsAny(in: content, keywords: ["upgrade", "downgrade", "price target"]) {
                bullets.append("Analyst changes often move stock prices in the short term")
            }
            
        case .etfs:
            if containsAny(in: content, keywords: ["inflow", "assets", "popularity"]) {
                bullets.append("Indicates growing investor interest in this theme")
                bullets.append("May amplify price movements in underlying holdings")
            }
            if containsAny(in: content, keywords: ["fee", "expense ratio", "cost"]) {
                bullets.append("Lower costs improve long-term returns for index investors")
            }
            
        case .longTermThemes:
            if containsAny(in: content, keywords: ["ai", "artificial intelligence"]) {
                bullets.append("Accelerates secular growth in AI infrastructure and applications")
                bullets.append("May benefit semiconductor, cloud, and software companies")
            }
            if containsAny(in: content, keywords: ["clean energy", "renewable", "solar", "wind"]) {
                bullets.append("Supports long-term transition to sustainable energy")
                bullets.append("Could attract ESG-focused capital flows")
            }
            if containsAny(in: content, keywords: ["healthcare", "biotech", "genomics"]) {
                bullets.append("Signals innovation in life sciences and longevity")
            }
            
        case .earningsAndFundamentals:
            if containsAny(in: content, keywords: ["free cash flow", "margin", "profitability"]) {
                bullets.append("Strong fundamentals support higher valuations")
            }
            if containsAny(in: content, keywords: ["debt", "leverage", "balance sheet"]) {
                bullets.append("Financial health affects risk profile and credit ratings")
            }
            
        case .dividendsAndIncome:
            if containsAny(in: content, keywords: ["dividend increase", "raise", "hike"]) {
                bullets.append("Signals management confidence and shareholder returns")
                bullets.append("May attract income-focused investors")
            }
            if containsAny(in: content, keywords: ["dividend cut", "suspend", "reduce"]) {
                bullets.append("Indicates financial stress or capital reallocation")
            }
            if containsAny(in: content, keywords: ["yield", "payout ratio"]) {
                bullets.append("Affects income stream for dividend portfolios")
            }
            
        case .portfolioStrategy:
            if containsAny(in: content, keywords: ["diversification", "allocation", "rebalance"]) {
                bullets.append("Highlights importance of portfolio construction")
            }
            if containsAny(in: content, keywords: ["60/40", "stocks", "bonds"]) {
                bullets.append("May affect traditional stock-bond allocation models")
            }
            
        case .riskAndVolatility:
            if containsAny(in: content, keywords: ["vix", "volatility spike", "fear index"]) {
                bullets.append("Elevated volatility suggests caution and hedging strategies")
                bullets.append("May create opportunities for contrarian investors")
            }
            if containsAny(in: content, keywords: ["crash", "correction", "bear market"]) {
                bullets.append("Signals increased risk and potential for defensive positioning")
            }
            
        case .macroAndRates:
            if containsAny(in: content, keywords: ["fed", "federal reserve", "powell"]) {
                bullets.append("Fed policy affects all asset classes and risk appetite")
            }
            if containsAny(in: content, keywords: ["yield curve", "inversion", "bonds"]) {
                bullets.append("Yield curve shape signals recession risk and growth outlook")
            }
            if containsAny(in: content, keywords: ["inflation", "deflation", "cpi"]) {
                bullets.append("Price trends affect real returns and central bank policy")
            }
        }
        
        return bullets
    }
    
    // MARK: - Cross-Cutting Implications
    
    private func generateCrossCuttingImplications(title: String, content: String) -> [String] {
        var bullets: [String] = []
        
        // Political and policy
        if containsAny(in: content, keywords: ["congress", "senate", "legislation", "bill", "law"]) {
            bullets.append("Legislative changes could ripple across multiple industries")
        }
        
        // Regulatory
        if containsAny(in: content, keywords: ["sec", "ftc", "regulator", "compliance"]) {
            bullets.append("Signals growing regulatory scrutiny in this space")
        }
        
        // Global events
        if containsAny(in: content, keywords: ["china", "europe", "global", "international"]) {
            bullets.append("International developments may affect U.S. markets and trade")
        }
        
        // Consumer behavior
        if containsAny(in: content, keywords: ["consumer", "spending", "retail", "shopping"]) {
            bullets.append("Reflects changing consumer behavior and spending patterns")
        }
        
        return bullets
    }
}
