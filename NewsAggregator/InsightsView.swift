import SwiftUI

struct InsightsView: View {
    @ObservedObject var activityTracker: ActivityTracker
    @ObservedObject var signalEngine: SignalEngine
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Signals Section (only show if signals exist)
                    if !signalEngine.todaysSignals.isEmpty {
                        SignalsSection(signals: signalEngine.todaysSignals)
                    }
                    
                    // Reading Activity Section
                    InsightSection(title: "Reading Activity") {
                        StatRow(label: "Articles read today", value: "\(activityTracker.articlesReadToday)")
                        StatRow(label: "Articles read this week", value: "\(activityTracker.articlesReadThisWeek)")
                        StatRow(label: "Total articles read", value: "\(activityTracker.articlesReadAllTime)")
                        
                        if let mostRead = activityTracker.mostReadCategory {
                            StatRow(label: "Most-read category", value: mostRead)
                        }
                    }
                    
                    // App Usage Section
                    InsightSection(title: "App Usage") {
                        if let mostVisited = activityTracker.mostVisitedTab {
                            StatRow(label: "Most visited tab", value: mostVisited)
                        } else {
                            StatRow(label: "Most visited tab", value: "No data yet")
                        }
                    }
                    
                    // Reading Streak Section (only show if streak exists)
                    if activityTracker.readingStreak > 0 {
                        InsightSection(title: "Reading Streak") {
                            StatRow(
                                label: "Consecutive days",
                                value: "\(activityTracker.readingStreak) day\(activityTracker.readingStreak == 1 ? "" : "s")"
                            )
                        }
                    }
                    
                    // Puzzles Section (only show if data exists)
                    if activityTracker.puzzlesPlayedAllTime > 0 {
                        InsightSection(title: "Puzzles") {
                            StatRow(label: "Games played today", value: "\(activityTracker.puzzlesPlayedToday)")
                            StatRow(label: "Total games played", value: "\(activityTracker.puzzlesPlayedAllTime)")
                            
                            if activityTracker.puzzleStreak > 0 {
                                StatRow(
                                    label: "Current streak",
                                    value: "\(activityTracker.puzzleStreak) day\(activityTracker.puzzleStreak == 1 ? "" : "s")"
                                )
                            }
                            
                            if let mostPlayed = activityTracker.mostPlayedGame {
                                StatRow(label: "Most played game", value: mostPlayed)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

// MARK: - Signals Section
struct SignalsSection: View {
    let signals: [Signal]
    
    var body: some View {
        InsightSection(title: "Signals") {
            ForEach(Array(signals.enumerated()), id: \.element.id) { index, signal in
                VStack(alignment: .leading, spacing: 0) {
                    Text(signal.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                    
                    if index < signals.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}

// MARK: - Insight Section
struct InsightSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview
#Preview {
    InsightsView(
        activityTracker: ActivityTracker(),
        signalEngine: SignalEngine()
    )
}
