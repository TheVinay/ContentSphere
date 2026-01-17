import SwiftUI

// MARK: - Investing Subcategory View
struct InvestingSubcategoryView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @Binding var selectedSubcategory: InvestingSubcategory?
    let onSubcategorySelected: (InvestingSubcategory?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // All Investing Button
                    SubcategoryCard(
                        title: "All Investing",
                        icon: "chart.bar.fill",
                        description: "View all investing news and analysis",
                        isSelected: selectedSubcategory == nil
                    ) {
                        selectedSubcategory = nil
                        onSubcategorySelected(nil)
                        dismiss()
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Subcategories
                    ForEach(InvestingSubcategory.allCases, id: \.self) { subcategory in
                        SubcategoryCard(
                            title: subcategory.rawValue,
                            icon: subcategory.iconName,
                            description: subcategory.description,
                            isSelected: selectedSubcategory == subcategory
                        ) {
                            selectedSubcategory = subcategory
                            onSubcategorySelected(subcategory)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Investing Topics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Subcategory Card
struct SubcategoryCard: View {
    let title: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.teal : Color(.systemGray6))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(isSelected ? .white : .teal)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.teal)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.teal.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.teal : Color(.systemGray5), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Investing Feed Badge
struct InvestingBadge: View {
    let subcategory: InvestingSubcategory?
    
    var body: some View {
        if let subcategory = subcategory {
            HStack(spacing: 4) {
                Image(systemName: subcategory.iconName)
                    .font(.caption2)
                Text(subcategory.rawValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.teal.opacity(0.2))
            .foregroundStyle(.teal)
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview
#Preview {
    InvestingSubcategoryView(
        viewModel: RSSFeedViewModel(),
        selectedSubcategory: .constant(.stocks),
        onSubcategorySelected: { _ in }
    )
}
