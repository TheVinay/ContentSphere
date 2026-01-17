import Foundation
import NaturalLanguage
import CoreLocation

// MARK: - Location Detection Engine
/// Detects geographic locations in news articles using NaturalLanguage + CoreLocation
@MainActor
final class LocationEngine {
    
    // MARK: - Properties
    
    /// Simple in-memory cache: place name -> coordinate
    private var geocodeCache: [String: CLLocationCoordinate2D] = [:]
    
    /// Geocoder instance (reused)
    private let geocoder = CLGeocoder()
    
    /// UserDefaults for persistent cache
    private let defaults = UserDefaults.standard
    private let cacheKey = "geocode_cache"
    
    // MARK: - Initialization
    
    init() {
        loadPersistentCache()
    }
    
    // MARK: - Public API
    
    /// Detect location from article text (title + description)
    /// - Parameters:
    ///   - article: The article to analyze
    /// - Returns: ArticleLocation if a valid location is detected, nil otherwise
    func detectLocation(from article: NewsFeed) async -> ArticleLocation? {
        // Step 1: Extract text to analyze
        let textToAnalyze = buildAnalysisText(from: article)
        
        guard !textToAnalyze.isEmpty else {
            return nil
        }
        
        // Step 2: Extract place name candidates
        let candidates = extractPlaceNames(from: textToAnalyze)
        
        guard !candidates.isEmpty else {
            return nil
        }
        
        // Step 3: Score and select best candidate
        guard let bestCandidate = selectBestCandidate(candidates) else {
            return nil
        }
        
        // Step 4: Geocode the place name to coordinates
        guard let coordinate = await geocode(placeName: bestCandidate.name) else {
            return nil
        }
        
        // Step 5: Create ArticleLocation
        let location = ArticleLocation(
            detectedLocation: bestCandidate.name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            confidenceScore: bestCandidate.confidence
        )
        
        print("📍 [LocationEngine] Geo-tagged: \(bestCandidate.name) → \(coordinate.latitude), \(coordinate.longitude)")
        
        return location
    }
    
    // MARK: - Geocoding
    
    /// Convert place name to coordinates using CLGeocoder
    private func geocode(placeName: String) async -> CLLocationCoordinate2D? {
        // Check in-memory cache first
        if let cached = geocodeCache[placeName] {
            return cached
        }
        
        // Check hardcoded city coordinates (instant, no API)
        if let hardcoded = cityCoordinates[placeName] {
            geocodeCache[placeName] = hardcoded
            savePersistentCache()
            return hardcoded
        }
        
        // Try with common country suffixes for better geocoding
        let placesToTry = [
            placeName,
            "\(placeName), USA",
            "\(placeName), United Kingdom",
            "\(placeName), France",
            "\(placeName), Germany",
            "\(placeName), China",
            "\(placeName), Japan"
        ]
        
        // Geocode using CLGeocoder
        for placeVariant in placesToTry {
            do {
                let placemarks = try await geocoder.geocodeAddressString(placeVariant)
                
                if let location = placemarks.first?.location {
                    let coordinate = location.coordinate
                    
                    // Cache the result (using original name as key)
                    geocodeCache[placeName] = coordinate
                    savePersistentCache()
                    
                    return coordinate
                }
            } catch {
                // Try next variant
                continue
            }
        }
        
        // All attempts failed
        return nil
    }
    
    // MARK: - Persistent Cache
    
    /// Load geocode cache from UserDefaults
    private func loadPersistentCache() {
        if let data = defaults.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([String: CoordinateData].self, from: data) {
            geocodeCache = decoded.mapValues { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            print("📍 [LocationEngine] Loaded \(geocodeCache.count) cached locations from disk")
        }
    }
    
    /// Save geocode cache to UserDefaults
    private func savePersistentCache() {
        let coordinateData = geocodeCache.mapValues { CoordinateData(latitude: $0.latitude, longitude: $0.longitude) }
        if let encoded = try? JSONEncoder().encode(coordinateData) {
            defaults.set(encoded, forKey: cacheKey)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Builds text string for analysis from article title + description + content preview
    private func buildAnalysisText(from article: NewsFeed) -> String {
        var parts: [String] = []
        
        if !article.title.isEmpty {
            parts.append(article.title)
        }
        
        if let description = article.description, !description.isEmpty {
            parts.append(description)
        }
        
        // Add content preview (first 500 characters) for better location detection
        if let content = article.content, !content.isEmpty {
            let preview = String(content.prefix(500))
            parts.append(preview)
        }
        
        return parts.joined(separator: " ")
    }
    
    /// Extract place name candidates using NaturalLanguage
    private func extractPlaceNames(from text: String) -> [PlaceCandidate] {
        var candidates: [PlaceCandidate] = []
        
        // Create NLTagger for named entity recognition
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            
            // Only process place names
            if tag == .placeName {
                let placeName = String(text[tokenRange])
                
                // Filter out obvious false positives
                if isValidPlaceName(placeName) {
                    let confidence = calculateConfidence(for: placeName, in: text)
                    candidates.append(PlaceCandidate(name: placeName, confidence: confidence))
                }
            }
            
            return true
        }
        
        return candidates
    }
    
    /// Validates whether a detected string is likely a real place
    private func isValidPlaceName(_ name: String) -> Bool {
        // Filter out common false positives
        let lowercased = name.lowercased()
        
        // Known non-places (company names, generic terms)
        let blacklist: Set<String> = [
            "apple", "google", "microsoft", "amazon", "meta", "tesla",
            "facebook", "twitter", "x", "netflix", "uber", "spotify",
            "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
            "january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"
        ]
        
        if blacklist.contains(lowercased) {
            return false
        }
        
        // Must be capitalized
        guard name.first?.isUppercase == true else {
            return false
        }
        
        // Must be at least 3 characters
        guard name.count >= 3 else {
            return false
        }
        
        return true
    }
    
    /// Calculate confidence score for a place candidate
    private func calculateConfidence(for placeName: String, in text: String) -> Double {
        var score = 0.5 // Base score
        
        // Boost if capitalized properly
        if placeName.first?.isUppercase == true {
            score += 0.1
        }
        
        // Boost if contains multiple words (e.g., "New York")
        if placeName.contains(" ") {
            score += 0.15
        }
        
        // Boost if it's a known major city
        if majorCities.contains(placeName) {
            score += 0.25
        }
        
        // Boost if it's a known country
        if countries.contains(placeName) {
            score += 0.2
        }
        
        // Reduce score if appears at start (might be source name)
        if text.hasPrefix(placeName) {
            score -= 0.15
        }
        
        // Boost if appears multiple times
        let occurrences = text.components(separatedBy: placeName).count - 1
        if occurrences > 1 {
            score += 0.1
        }
        
        // Clamp to [0, 1]
        return min(max(score, 0.0), 1.0)
    }
    
    /// Select the best candidate from a list
    private func selectBestCandidate(_ candidates: [PlaceCandidate]) -> PlaceCandidate? {
        // Return candidate with highest confidence
        return candidates.max(by: { $0.confidence < $1.confidence })
    }
    
    // MARK: - Known Places Database
    
    /// Pre-geocoded city coordinates (instant lookup, no API needed)
    private let cityCoordinates: [String: CLLocationCoordinate2D] = [
        // North America - USA
        "New York": CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        "Los Angeles": CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        "Chicago": CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298),
        "Houston": CLLocationCoordinate2D(latitude: 29.7604, longitude: -95.3698),
        "Phoenix": CLLocationCoordinate2D(latitude: 33.4484, longitude: -112.0740),
        "Philadelphia": CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652),
        "San Antonio": CLLocationCoordinate2D(latitude: 29.4241, longitude: -98.4936),
        "San Diego": CLLocationCoordinate2D(latitude: 32.7157, longitude: -117.1611),
        "Dallas": CLLocationCoordinate2D(latitude: 32.7767, longitude: -96.7970),
        "San Jose": CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863),
        "Austin": CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431),
        "Jacksonville": CLLocationCoordinate2D(latitude: 30.3322, longitude: -81.6557),
        "San Francisco": CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        "Columbus": CLLocationCoordinate2D(latitude: 39.9612, longitude: -82.9988),
        "Indianapolis": CLLocationCoordinate2D(latitude: 39.7684, longitude: -86.1581),
        "Fort Worth": CLLocationCoordinate2D(latitude: 32.7555, longitude: -97.3308),
        "Charlotte": CLLocationCoordinate2D(latitude: 35.2271, longitude: -80.8431),
        "Seattle": CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
        "Denver": CLLocationCoordinate2D(latitude: 39.7392, longitude: -104.9903),
        "Washington": CLLocationCoordinate2D(latitude: 38.9072, longitude: -77.0369),
        "Boston": CLLocationCoordinate2D(latitude: 42.3601, longitude: -71.0589),
        "Nashville": CLLocationCoordinate2D(latitude: 36.1627, longitude: -86.7816),
        "Detroit": CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458),
        "Portland": CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784),
        "Las Vegas": CLLocationCoordinate2D(latitude: 36.1699, longitude: -115.1398),
        "Memphis": CLLocationCoordinate2D(latitude: 35.1495, longitude: -90.0490),
        "Baltimore": CLLocationCoordinate2D(latitude: 39.2904, longitude: -76.6122),
        "Milwaukee": CLLocationCoordinate2D(latitude: 43.0389, longitude: -87.9065),
        "Albuquerque": CLLocationCoordinate2D(latitude: 35.0844, longitude: -106.6504),
        "Tucson": CLLocationCoordinate2D(latitude: 32.2226, longitude: -110.9747),
        "Fresno": CLLocationCoordinate2D(latitude: 36.7378, longitude: -119.7871),
        "Sacramento": CLLocationCoordinate2D(latitude: 38.5816, longitude: -121.4944),
        "Kansas City": CLLocationCoordinate2D(latitude: 39.0997, longitude: -94.5786),
        "Mesa": CLLocationCoordinate2D(latitude: 33.4152, longitude: -111.8315),
        "Atlanta": CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3880),
        "Miami": CLLocationCoordinate2D(latitude: 25.7617, longitude: -80.1918),
        "New Orleans": CLLocationCoordinate2D(latitude: 29.9511, longitude: -90.0715),
        "Minneapolis": CLLocationCoordinate2D(latitude: 44.9778, longitude: -93.2650),
        "Tampa": CLLocationCoordinate2D(latitude: 27.9506, longitude: -82.4572),
        "Cleveland": CLLocationCoordinate2D(latitude: 41.4993, longitude: -81.6944),
        "Pittsburgh": CLLocationCoordinate2D(latitude: 40.4406, longitude: -79.9959),
        "St. Louis": CLLocationCoordinate2D(latitude: 38.6270, longitude: -90.1994),
        "Cincinnati": CLLocationCoordinate2D(latitude: 39.1031, longitude: -84.5120),
        
        // North America - Canada
        "Toronto": CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
        "Montreal": CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673),
        "Vancouver": CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
        "Calgary": CLLocationCoordinate2D(latitude: 51.0447, longitude: -114.0719),
        "Ottawa": CLLocationCoordinate2D(latitude: 45.4215, longitude: -75.6972),
        "Edmonton": CLLocationCoordinate2D(latitude: 53.5461, longitude: -113.4938),
        
        // North America - Mexico
        "Mexico City": CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
        "Guadalajara": CLLocationCoordinate2D(latitude: 20.6597, longitude: -103.3496),
        "Monterrey": CLLocationCoordinate2D(latitude: 25.6866, longitude: -100.3161),
        
        // Europe - UK
        "London": CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
        "Manchester": CLLocationCoordinate2D(latitude: 53.4808, longitude: -2.2426),
        "Birmingham": CLLocationCoordinate2D(latitude: 52.4862, longitude: -1.8904),
        "Edinburgh": CLLocationCoordinate2D(latitude: 55.9533, longitude: -3.1883),
        "Glasgow": CLLocationCoordinate2D(latitude: 55.8642, longitude: -4.2518),
        "Liverpool": CLLocationCoordinate2D(latitude: 53.4084, longitude: -2.9916),
        
        // Europe - France
        "Paris": CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        "Marseille": CLLocationCoordinate2D(latitude: 43.2965, longitude: 5.3698),
        "Lyon": CLLocationCoordinate2D(latitude: 45.7640, longitude: 4.8357),
        "Nice": CLLocationCoordinate2D(latitude: 43.7102, longitude: 7.2620),
        
        // Europe - Germany
        "Berlin": CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
        "Munich": CLLocationCoordinate2D(latitude: 48.1351, longitude: 11.5820),
        "Frankfurt": CLLocationCoordinate2D(latitude: 50.1109, longitude: 8.6821),
        "Hamburg": CLLocationCoordinate2D(latitude: 53.5511, longitude: 9.9937),
        "Cologne": CLLocationCoordinate2D(latitude: 50.9375, longitude: 6.9603),
        
        // Europe - Spain
        "Madrid": CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
        "Barcelona": CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734),
        "Valencia": CLLocationCoordinate2D(latitude: 39.4699, longitude: -0.3763),
        "Seville": CLLocationCoordinate2D(latitude: 37.3891, longitude: -5.9845),
        
        // Europe - Italy
        "Rome": CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964),
        "Milan": CLLocationCoordinate2D(latitude: 45.4642, longitude: 9.1900),
        "Naples": CLLocationCoordinate2D(latitude: 40.8518, longitude: 14.2681),
        "Turin": CLLocationCoordinate2D(latitude: 45.0703, longitude: 7.6869),
        "Florence": CLLocationCoordinate2D(latitude: 43.7696, longitude: 11.2558),
        "Venice": CLLocationCoordinate2D(latitude: 45.4408, longitude: 12.3155),
        
        // Europe - Other
        "Amsterdam": CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041),
        "Brussels": CLLocationCoordinate2D(latitude: 50.8503, longitude: 4.3517),
        "Vienna": CLLocationCoordinate2D(latitude: 48.2082, longitude: 16.3738),
        "Stockholm": CLLocationCoordinate2D(latitude: 59.3293, longitude: 18.0686),
        "Copenhagen": CLLocationCoordinate2D(latitude: 55.6761, longitude: 12.5683),
        "Oslo": CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7522),
        "Helsinki": CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384),
        "Lisbon": CLLocationCoordinate2D(latitude: 38.7223, longitude: -9.1393),
        "Athens": CLLocationCoordinate2D(latitude: 37.9838, longitude: 23.7275),
        "Dublin": CLLocationCoordinate2D(latitude: 53.3498, longitude: -6.2603),
        "Prague": CLLocationCoordinate2D(latitude: 50.0755, longitude: 14.4378),
        "Warsaw": CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122),
        "Budapest": CLLocationCoordinate2D(latitude: 47.4979, longitude: 19.0402),
        "Zurich": CLLocationCoordinate2D(latitude: 47.3769, longitude: 8.5417),
        "Geneva": CLLocationCoordinate2D(latitude: 46.2044, longitude: 6.1432),
        
        // Asia - China
        "Beijing": CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
        "Shanghai": CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
        "Guangzhou": CLLocationCoordinate2D(latitude: 23.1291, longitude: 113.2644),
        "Shenzhen": CLLocationCoordinate2D(latitude: 22.5431, longitude: 114.0579),
        "Chengdu": CLLocationCoordinate2D(latitude: 30.5728, longitude: 104.0668),
        "Hong Kong": CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694),
        
        // Asia - Japan
        "Tokyo": CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
        "Osaka": CLLocationCoordinate2D(latitude: 34.6937, longitude: 135.5023),
        "Kyoto": CLLocationCoordinate2D(latitude: 35.0116, longitude: 135.7681),
        "Yokohama": CLLocationCoordinate2D(latitude: 35.4437, longitude: 139.6380),
        
        // Asia - India
        "Mumbai": CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777),
        "Delhi": CLLocationCoordinate2D(latitude: 28.7041, longitude: 77.1025),
        "Bangalore": CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946),
        "Kolkata": CLLocationCoordinate2D(latitude: 22.5726, longitude: 88.3639),
        "Chennai": CLLocationCoordinate2D(latitude: 13.0827, longitude: 80.2707),
        "Hyderabad": CLLocationCoordinate2D(latitude: 17.3850, longitude: 78.4867),
        
        // Asia - Southeast Asia
        "Singapore": CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
        "Bangkok": CLLocationCoordinate2D(latitude: 13.7563, longitude: 100.5018),
        "Jakarta": CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456),
        "Manila": CLLocationCoordinate2D(latitude: 14.5995, longitude: 120.9842),
        "Hanoi": CLLocationCoordinate2D(latitude: 21.0285, longitude: 105.8542),
        "Kuala Lumpur": CLLocationCoordinate2D(latitude: 3.1390, longitude: 101.6869),
        
        // Asia - Middle East
        "Dubai": CLLocationCoordinate2D(latitude: 25.2048, longitude: 55.2708),
        "Abu Dhabi": CLLocationCoordinate2D(latitude: 24.4539, longitude: 54.3773),
        "Riyadh": CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
        "Tel Aviv": CLLocationCoordinate2D(latitude: 32.0853, longitude: 34.7818),
        "Jerusalem": CLLocationCoordinate2D(latitude: 31.7683, longitude: 35.2137),
        "Istanbul": CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
        "Ankara": CLLocationCoordinate2D(latitude: 39.9334, longitude: 32.8597),
        
        // Asia - Other
        "Seoul": CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        "Taipei": CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654),
        
        // Oceania
        "Sydney": CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093),
        "Melbourne": CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631),
        "Brisbane": CLLocationCoordinate2D(latitude: -27.4698, longitude: 153.0251),
        "Perth": CLLocationCoordinate2D(latitude: -31.9505, longitude: 115.8605),
        "Auckland": CLLocationCoordinate2D(latitude: -36.8485, longitude: 174.7633),
        "Wellington": CLLocationCoordinate2D(latitude: -41.2865, longitude: 174.7762),
        
        // Africa
        "Cairo": CLLocationCoordinate2D(latitude: 30.0444, longitude: 31.2357),
        "Lagos": CLLocationCoordinate2D(latitude: 6.5244, longitude: 3.3792),
        "Nairobi": CLLocationCoordinate2D(latitude: -1.2921, longitude: 36.8219),
        "Johannesburg": CLLocationCoordinate2D(latitude: -26.2041, longitude: 28.0473),
        "Cape Town": CLLocationCoordinate2D(latitude: -33.9249, longitude: 18.4241),
        "Casablanca": CLLocationCoordinate2D(latitude: 33.5731, longitude: -7.5898),
        
        // South America
        "São Paulo": CLLocationCoordinate2D(latitude: -23.5505, longitude: -46.6333),
        "Rio de Janeiro": CLLocationCoordinate2D(latitude: -22.9068, longitude: -43.1729),
        "Buenos Aires": CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816),
        "Lima": CLLocationCoordinate2D(latitude: -12.0464, longitude: -77.0428),
        "Bogotá": CLLocationCoordinate2D(latitude: 4.7110, longitude: -74.0721),
        "Santiago": CLLocationCoordinate2D(latitude: -33.4489, longitude: -70.6693),
        "Caracas": CLLocationCoordinate2D(latitude: 10.4806, longitude: -66.9036),
        
        // Russia
        "Moscow": CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
        "Saint Petersburg": CLLocationCoordinate2D(latitude: 59.9343, longitude: 30.3351),
        
        // US States (for better detection)
        "California": CLLocationCoordinate2D(latitude: 36.7783, longitude: -119.4179),
        "Texas": CLLocationCoordinate2D(latitude: 31.9686, longitude: -99.9018),
        "Florida": CLLocationCoordinate2D(latitude: 27.6648, longitude: -81.5158),
        "New York State": CLLocationCoordinate2D(latitude: 42.1657, longitude: -74.9481),
        "Illinois": CLLocationCoordinate2D(latitude: 40.6331, longitude: -89.3985),
        "Pennsylvania": CLLocationCoordinate2D(latitude: 41.2033, longitude: -77.1945),
        "Ohio": CLLocationCoordinate2D(latitude: 40.4173, longitude: -82.9071),
        "Georgia": CLLocationCoordinate2D(latitude: 32.1656, longitude: -82.9001),
        "North Carolina": CLLocationCoordinate2D(latitude: 35.7596, longitude: -79.0193),
        "Michigan": CLLocationCoordinate2D(latitude: 44.3148, longitude: -85.6024),
        
        // Regions
        "Gaza": CLLocationCoordinate2D(latitude: 31.5017, longitude: 34.4668),
        "West Bank": CLLocationCoordinate2D(latitude: 31.9522, longitude: 35.2332),
        "Ukraine": CLLocationCoordinate2D(latitude: 48.3794, longitude: 31.1656),
        "Kyiv": CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234),
        "Taiwan": CLLocationCoordinate2D(latitude: 23.6978, longitude: 120.9605)
    ]
    
    private let majorCities: Set<String> = [
        "Paris", "London", "New York", "Tokyo", "Beijing", "Moscow",
        "Berlin", "Madrid", "Rome", "Washington", "Los Angeles", "Chicago",
        "San Francisco", "Boston", "Seattle", "Miami", "Dubai", "Singapore",
        "Hong Kong", "Sydney", "Toronto", "Mexico City", "Mumbai", "Shanghai",
        "Amsterdam", "Brussels", "Vienna", "Stockholm", "Copenhagen", "Oslo",
        "Helsinki", "Lisbon", "Athens", "Istanbul", "Cairo", "Jerusalem",
        "Bangkok", "Seoul", "Jakarta", "Manila", "Hanoi", "Delhi", "Bangalore",
        "Karachi", "Lagos", "Nairobi", "Johannesburg", "Cape Town", "Rio de Janeiro",
        "São Paulo", "Buenos Aires", "Lima", "Bogotá", "Santiago", "Caracas",
        "Havana", "Atlanta", "Dallas", "Houston", "Phoenix", "Philadelphia",
        "Detroit", "Minneapolis", "Denver", "Portland", "Las Vegas", "Austin"
    ]
    
    private let countries: Set<String> = [
        "Afghanistan", "Albania", "Algeria", "Argentina", "Australia", "Austria",
        "Bangladesh", "Belgium", "Brazil", "Canada", "Chile", "China", "Colombia",
        "Denmark", "Egypt", "Finland", "France", "Germany", "Greece", "India",
        "Indonesia", "Iran", "Iraq", "Ireland", "Israel", "Italy", "Japan",
        "Kenya", "Malaysia", "Mexico", "Netherlands", "Nigeria", "Norway",
        "Pakistan", "Peru", "Philippines", "Poland", "Portugal", "Russia",
        "Saudi Arabia", "Singapore", "South Africa", "South Korea", "Spain",
        "Sweden", "Switzerland", "Thailand", "Turkey", "Ukraine", "United Kingdom",
        "United States", "Venezuela", "Vietnam"
    ]
}

// MARK: - Supporting Types

/// Internal representation of a detected place candidate
private struct PlaceCandidate {
    let name: String
    let confidence: Double
}

/// Codable wrapper for CLLocationCoordinate2D (for UserDefaults persistence)
private struct CoordinateData: Codable {
    let latitude: Double
    let longitude: Double
}

