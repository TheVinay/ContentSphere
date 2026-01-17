import SwiftUI
import MapKit

// MARK: - News Map View
struct NewsMapView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @State private var selectedArticle: NewsFeed?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var selectedCategory: FeedCategory?
    
    private var geoTaggedArticles: [NewsFeed] {
        viewModel.newsFeeds.filter { $0.location != nil }
    }
    
    private var filteredArticles: [NewsFeed] {
        guard let category = selectedCategory else { return geoTaggedArticles }
        
        return geoTaggedArticles.filter { article in
            guard let sourceName = article.sourceName,
                  let source = viewModel.feedSources.first(where: { $0.name == sourceName }) else {
                return false
            }
            return source.category == category
        }
    }
    
    private var clusteredMarkers: [ClusterMarker] {
        clusterArticles(filteredArticles)
    }
    
    private var regionalHeadlines: [NewsFeed] {
        guard let region = visibleRegion else { return [] }
        
        return filteredArticles.filter { article in
            guard let location = article.location else { return false }
            return region.contains(coordinate: location.coordinate)
        }.prefix(10).map { $0 }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map
            Map(position: $cameraPosition, selection: $selectedArticle) {
                ForEach(clusteredMarkers) { cluster in
                    if cluster.articles.count == 1, let article = cluster.articles.first {
                        // Single article marker
                        Marker(coordinate: cluster.coordinate) {
                            VStack(spacing: 2) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(categoryColor(for: article))
                                Text(article.location?.detectedLocation ?? "")
                                    .font(.caption2)
                            }
                        }
                        .tag(article)
                    } else {
                        // Cluster marker
                        Annotation("", coordinate: cluster.coordinate) {
                            ClusterView(count: cluster.articles.count)
                                .onTapGesture {
                                    zoomToCluster(cluster)
                                }
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .onMapCameraChange { context in
                visibleRegion = context.region
            }
            
            // Overlay Controls
            VStack {
                HStack {
                    // Category Filter Menu
                    Menu {
                        Button("All Categories") {
                            selectedCategory = nil
                        }
                        
                        Divider()
                        
                        ForEach(FeedCategory.allCases) { category in
                            Button(category.rawValue) {
                                selectedCategory = category
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            Text(selectedCategory?.rawValue ?? "All")
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    // Recenter Button
                    Button {
                        withAnimation {
                            cameraPosition = .automatic
                        }
                    } label: {
                        Image(systemName: "location.circle.fill")
                            .font(.title2)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
            }
            
            // Global Pulse Sheet
            if selectedArticle == nil {
                GlobalPulseSheet(
                    headlines: regionalHeadlines,
                    onArticleTapped: { article in
                        selectedArticle = article
                    }
                )
                .transition(.move(edge: .bottom))
            } else if let article = selectedArticle {
                // Article Preview Card
                ArticlePreviewCard(
                    article: article,
                    viewModel: viewModel,
                    onClose: {
                        selectedArticle = nil
                    },
                    onReadMore: {
                        // Navigate to detail
                    }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .navigationTitle("Global News Map")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Clustering Logic
    
    private func clusterArticles(_ articles: [NewsFeed]) -> [ClusterMarker] {
        var clusters: [ClusterMarker] = []
        var processed: Set<UUID> = []
        
        for article in articles {
            guard let location = article.location, !processed.contains(article.id) else { continue }
            
            // Find nearby articles
            let nearby = articles.filter { other in
                guard let otherLocation = other.location, !processed.contains(other.id) else { return false }
                let distance = location.coordinate.distance(to: otherLocation.coordinate)
                return distance < 50_000 // 50km threshold
            }
            
            if nearby.isEmpty {
                clusters.append(ClusterMarker(articles: [article], coordinate: location.coordinate))
                processed.insert(article.id)
            } else {
                let clusterCoordinate = calculateCentroid(nearby.compactMap { $0.location?.coordinate })
                clusters.append(ClusterMarker(articles: nearby, coordinate: clusterCoordinate))
                nearby.forEach { processed.insert($0.id) }
            }
        }
        
        return clusters
    }
    
    private func calculateCentroid(_ coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
        guard !coordinates.isEmpty else { return CLLocationCoordinate2D() }
        
        let lat = coordinates.map { $0.latitude }.reduce(0, +) / Double(coordinates.count)
        let lon = coordinates.map { $0.longitude }.reduce(0, +) / Double(coordinates.count)
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    private func zoomToCluster(_ cluster: ClusterMarker) {
        let span = MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        let region = MKCoordinateRegion(center: cluster.coordinate, span: span)
        
        withAnimation {
            cameraPosition = .region(region)
        }
    }
    
    private func categoryColor(for article: NewsFeed) -> Color {
        guard let sourceName = article.sourceName,
              let source = viewModel.feedSources.first(where: { $0.name == sourceName }) else {
            return .blue
        }
        
        switch source.category.color {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "pink": return .pink
        case "red": return .red
        case "orange": return .orange
        case "teal": return .teal
        default: return .blue
        }
    }
}

// MARK: - Cluster Marker Model
struct ClusterMarker: Identifiable {
    let id = UUID()
    let articles: [NewsFeed]
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Cluster View
struct ClusterView: View {
    let count: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.blue.gradient)
                .frame(width: 40, height: 40)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Global Pulse Sheet
struct GlobalPulseSheet: View {
    let headlines: [NewsFeed]
    let onArticleTapped: (NewsFeed) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "globe.americas.fill")
                    .foregroundStyle(.blue)
                Text("Global Pulse")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !headlines.isEmpty {
                    Text("\(headlines.count) in view")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if headlines.isEmpty {
                Text("Pan the map to discover regional headlines")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(headlines) { article in
                            GlobalPulseRow(article: article)
                                .onTapGesture {
                                    onArticleTapped(article)
                                }
                        }
                    }
                }
                .frame(maxHeight: 250)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

// MARK: - Global Pulse Row
struct GlobalPulseRow: View {
    let article: NewsFeed
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let location = article.location {
                Image(systemName: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(location.detectedLocation)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                    
                    Text(article.title)
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Article Preview Card
struct ArticlePreviewCard: View {
    let article: NewsFeed
    @ObservedObject var viewModel: RSSFeedViewModel
    let onClose: () -> Void
    let onReadMore: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let location = article.location {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text(location.detectedLocation)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue)
                    .cornerRadius(6)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(article.title)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(3)
            
            if let description = article.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                if let sourceName = article.sourceName {
                    Label(sourceName, systemImage: "building.2")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                Text(article.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button {
                onReadMore()
            } label: {
                HStack {
                    Text("Read Article")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

// MARK: - CLLocationCoordinate2D Extensions
extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return location1.distance(from: location2)
    }
}

extension MKCoordinateRegion {
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let latDelta = abs(center.latitude - coordinate.latitude)
        let lonDelta = abs(center.longitude - coordinate.longitude)
        
        return latDelta <= span.latitudeDelta / 2 && lonDelta <= span.longitudeDelta / 2
    }
}
