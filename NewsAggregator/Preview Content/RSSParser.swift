import Foundation

// MARK: - RSS Parser Error
enum RSSParserError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case parsingError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid feed URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError:
            return "Failed to parse RSS feed"
        case .noData:
            return "No data received from feed"
        }
    }
}

// MARK: - RSS Parser
class RSSParser {
    
    // Date formatters for various RSS date formats
    private static let dateFormatters: [DateFormatter] = {
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss z",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd"
        ]
        
        return formats.map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }
    }()
    
    /// Fetch and parse RSS feed from a URL
    func fetchAndParse(from urlString: String, sourceName: String) async throws -> [NewsFeed] {
        guard let url = URL(string: urlString) else {
            throw RSSParserError.invalidURL
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try await parse(data: data, sourceName: sourceName)
        } catch {
            throw RSSParserError.networkError(error)
        }
    }
    
    /// Parse RSS data
    private func parse(data: Data, sourceName: String) async throws -> [NewsFeed] {
        guard !data.isEmpty else {
            throw RSSParserError.noData
        }
        
        return await withCheckedContinuation { continuation in
            Task.detached {
                // Create parser and delegate on the detached task
                let parser = XMLParser(data: data)
                let delegate = ParserDelegate(sourceName: sourceName)
                parser.delegate = delegate
                
                // Parse synchronously on this background thread
                _ = parser.parse()
                
                // Return the results
                continuation.resume(returning: delegate.feeds)
            }
        }
    }
}

// MARK: - Parser Delegate
private final class ParserDelegate: NSObject, XMLParserDelegate, @unchecked Sendable {
    var feeds: [NewsFeed] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentThumbnail: String?
    private var currentPostDate: String?
    private var currentContent: String?
    private var currentDescription: String?
    private let sourceName: String
    
    init(sourceName: String) {
        self.sourceName = sourceName
        super.init()
    }
    
    // Date formatters for various RSS date formats
    private static let dateFormatters: [DateFormatter] = {
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss z",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd"
        ]
        
        return formats.map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }
    }()
    
    // MARK: - XMLParserDelegate Methods
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes attributeDict: [String: String]) {
        currentElement = elementName
        
        // Handle media thumbnails
        if elementName == "media:thumbnail" || elementName == "media:content" {
            if let url = attributeDict["url"] {
                currentThumbnail = url
            }
        }
        
        // Handle enclosure tags (common for images)
        if elementName == "enclosure" {
            if let type = attributeDict["type"], type.hasPrefix("image"),
               let url = attributeDict["url"] {
                currentThumbnail = url
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedString.isEmpty else { return }
        
        switch currentElement {
        case "title":
            currentTitle += trimmedString
        case "link":
            currentLink += trimmedString
        case "pubDate", "published", "dc:date":
            currentPostDate = (currentPostDate ?? "") + trimmedString
        case "description":
            currentDescription = (currentDescription ?? "") + trimmedString
        case "content:encoded", "content":
            currentContent = (currentContent ?? "") + trimmedString
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "item" || elementName == "entry" {
            let title = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let link = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Only add if we have at least a title and link
            guard !title.isEmpty, !link.isEmpty else {
                resetCurrentItem()
                return
            }
            
            let feed = NewsFeed(
                title: title,
                link: link,
                thumbnail: currentThumbnail,
                postDate: parseDate(from: currentPostDate),
                content: currentContent?.trimmingCharacters(in: .whitespacesAndNewlines),
                sourceName: sourceName,
                description: currentDescription?.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            feeds.append(feed)
            
            resetCurrentItem()
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetCurrentItem() {
        currentTitle = ""
        currentLink = ""
        currentThumbnail = nil
        currentPostDate = nil
        currentContent = nil
        currentDescription = nil
    }
    
    private func parseDate(from dateString: String?) -> Date? {
        guard let dateString = dateString?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }
        
        for formatter in Self.dateFormatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
}
