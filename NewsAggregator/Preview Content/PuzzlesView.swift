import SwiftUI

// MARK: - Puzzles View
struct PuzzlesView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @State private var selectedPuzzle: PuzzleType?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Puzzles")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Challenge yourself with daily games and news trivia")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Daily Challenge Badge
                    if viewModel.puzzleProgress.completedToday == 3 {
                        CompletionBadge()
                            .padding(.horizontal)
                    }
                    
                    // Main Puzzles
                    VStack(spacing: 16) {
                        PuzzleTile(
                            puzzle: .newsQuiz,
                            progress: viewModel.puzzleProgress.newsQuizCompleted ? "5/5" : "\(viewModel.puzzleProgress.newsQuizScore)/5",
                            isCompleted: viewModel.puzzleProgress.newsQuizCompleted
                        ) {
                            selectedPuzzle = .newsQuiz
                        }
                        
                        PuzzleTile(
                            puzzle: .wordTarget,
                            progress: viewModel.puzzleProgress.wordTargetCompleted ? "✓" : "—",
                            isCompleted: viewModel.puzzleProgress.wordTargetCompleted
                        ) {
                            selectedPuzzle = .wordTarget
                        }
                        
                        PuzzleTile(
                            puzzle: .sudoku,
                            progress: viewModel.puzzleProgress.sudokuCompleted ? "✓" : "—",
                            isCompleted: viewModel.puzzleProgress.sudokuCompleted
                        ) {
                            selectedPuzzle = .sudoku
                        }
                    }
                    .padding(.horizontal)
                    
                    // Stats
                    StatsSection(progress: viewModel.puzzleProgress)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Puzzles")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $selectedPuzzle) { puzzle in
                puzzleView(for: puzzle)
            }
        }
    }
    
    @ViewBuilder
    private func puzzleView(for puzzle: PuzzleType) -> some View {
        switch puzzle {
        case .newsQuiz:
            NewsQuizView(viewModel: viewModel)
        case .wordTarget:
            WordTargetView(viewModel: viewModel)
        case .sudoku:
            SudokuView(viewModel: viewModel)
        }
    }
}

// MARK: - Puzzle Type
enum PuzzleType: Identifiable {
    case newsQuiz
    case wordTarget
    case sudoku
    
    var id: String {
        switch self {
        case .newsQuiz: return "newsQuiz"
        case .wordTarget: return "wordTarget"
        case .sudoku: return "sudoku"
        }
    }
    
    var title: String {
        switch self {
        case .newsQuiz: return "News Quiz"
        case .wordTarget: return "Word Target"
        case .sudoku: return "Daily Sudoku"
        }
    }
    
    var icon: String {
        switch self {
        case .newsQuiz: return "newspaper.fill"
        case .wordTarget: return "textformat.abc"
        case .sudoku: return "number.square.fill"
        }
    }
    
    var description: String {
        switch self {
        case .newsQuiz: return "Test your knowledge of today's news"
        case .wordTarget: return "Guess the 5-letter word in 6 tries"
        case .sudoku: return "Fill the 9x9 grid with numbers 1-9"
        }
    }
    
    var color: Color {
        switch self {
        case .newsQuiz: return .blue
        case .wordTarget: return .green
        case .sudoku: return .purple
        }
    }
}

// MARK: - Puzzle Tile
struct PuzzleTile: View {
    let puzzle: PuzzleType
    let progress: String
    let isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(puzzle.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: puzzle.icon)
                        .font(.title2)
                        .foregroundStyle(puzzle.color)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(puzzle.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(puzzle.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Progress
                VStack(spacing: 4) {
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.green)
                    } else {
                        Text(progress)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Completion Badge
struct CompletionBadge: View {
    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            
            Text("All puzzles completed today!")
                .fontWeight(.semibold)
            
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.2), Color.yellow.opacity(0.2)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}

// MARK: - Stats Section
struct StatsSection: View {
    let progress: PuzzleProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Stats")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                StatBox(title: "Streak", value: "\(progress.streak)", icon: "flame.fill", color: .orange)
                StatBox(title: "Completed", value: "\(progress.totalCompleted)", icon: "checkmark.circle.fill", color: .green)
                StatBox(title: "Best Streak", value: "\(progress.bestStreak)", icon: "trophy.fill", color: .yellow)
            }
        }
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Puzzle Progress Model
struct PuzzleProgress: Codable {
    var newsQuizCompleted: Bool = false
    var newsQuizScore: Int = 0
    var wordTargetCompleted: Bool = false
    var sudokuCompleted: Bool = false
    var streak: Int = 0
    var bestStreak: Int = 0
    var totalCompleted: Int = 0
    var lastCompletedDate: Date?
    
    var completedToday: Int {
        var count = 0
        if newsQuizCompleted { count += 1 }
        if wordTargetCompleted { count += 1 }
        if sudokuCompleted { count += 1 }
        return count
    }
}

// MARK: - Preview
#Preview {
    PuzzlesView(viewModel: RSSFeedViewModel())
}
