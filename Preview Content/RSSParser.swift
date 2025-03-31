import Foundation

class RSSParser: NSObject, XMLParserDelegate {
    private var feeds: [NewsFeed] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentThumbnail: String?
    private var currentPostDate: String?
    private var currentContent: String?

    func parse(data: Data) -> [NewsFeed]? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        feeds = []

        if parser.parse() {
            return feeds
        } else {
            print("Failed to parse RSS data.")
            return nil
        }
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes attributeDict: [String: String]) {
        currentElement = elementName

        if currentElement == "media:thumbnail" || currentElement == "image" {
            if let url = attributeDict["url"] {
                currentThumbnail = url
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)

        switch currentElement {
        case "title":
            currentTitle += trimmedString
        case "link":
            currentLink += trimmedString
        case "pubDate":
            currentPostDate = trimmedString
        case "description", "content:encoded":
            currentContent = (currentContent ?? "") + trimmedString
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "item" {
            let feed = NewsFeed(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                thumbnail: currentThumbnail,
                postDate: currentPostDate,
                content: currentContent,
                sourceName: nil
            )
            feeds.append(feed)

            currentTitle = ""
            currentLink = ""
            currentThumbnail = nil
            currentPostDate = nil
            currentContent = nil
        }
    }
}
