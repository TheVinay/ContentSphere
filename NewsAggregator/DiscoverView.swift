import SwiftUI

// MARK: - Discover View
struct DiscoverView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @State private var selectedTopics: Set<String> = []
    @State private var customFeeds: [NewsFeed] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Discover")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Personalize your news feed by selecting topics you're interested in")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Categories
                    ForEach(FeedCategory.allCases, id: \.self) { category in
                        CategoryDiscoverSection(
                            category: category,
                            selectedTopics: $selectedTopics,
                            viewModel: viewModel
                        )
                    }
                    
                    // Apply Button
                    Button {
                        applyCustomFeed()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Apply Personalized Feed")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTopics.isEmpty ? Color.gray : Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(selectedTopics.isEmpty)
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                .padding(.vertical)
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func applyCustomFeed() {
        // Save preferences
        viewModel.customTopics = selectedTopics
        isLoading = true
        
        Task {
            await viewModel.fetchCustomFeed()
            isLoading = false
        }
    }
}

// MARK: - Category Discover Section
struct CategoryDiscoverSection: View {
    let category: FeedCategory
    @Binding var selectedTopics: Set<String>
    @ObservedObject var viewModel: RSSFeedViewModel
    
    var availableSources: [FeedSource] {
        viewModel.feedSources.filter { $0.category == category }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category Header
            HStack {
                Image(systemName: category.iconName)
                    .foregroundStyle(categoryColor)
                Text(category.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
            
            // Source Pills
            FlowLayout(spacing: 8) {
                ForEach(availableSources) { source in
                    TopicPill(
                        title: source.name,
                        isSelected: selectedTopics.contains(source.id.uuidString)
                    ) {
                        toggleTopic(source.id.uuidString)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var categoryColor: Color {
        switch category.color {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "pink": return .pink
        case "red": return .red
        case "orange": return .orange
        case "teal": return .teal
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "indigo": return .indigo
        default: return .blue
        }
    }
    
    private func toggleTopic(_ topic: String) {
        if selectedTopics.contains(topic) {
            selectedTopics.remove(topic)
        } else {
            selectedTopics.insert(topic)
        }
    }
}

// MARK: - Topic Pill
struct TopicPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout (for wrapping pills)
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: width, height: y + lineHeight)
        }
    }
}

// MARK: - Preview
#Preview {
    DiscoverView(viewModel: RSSFeedViewModel())
}
