import SwiftUI

// MARK: - News Quiz View
struct NewsQuizView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var questions: [QuizQuestion] = []
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: Int?
    @State private var score = 0
    @State private var showingResults = false
    @State private var answeredQuestions: Set<Int> = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if questions.isEmpty {
                        ProgressView("Generating quiz from today's news...")
                    } else if showingResults {
                        ResultsView(score: score, total: questions.count) {
                            viewModel.puzzleProgress.newsQuizCompleted = true
                            viewModel.puzzleProgress.newsQuizScore = score
                            viewModel.savePuzzleProgress()
                            dismiss()
                        }
                    } else {
                        // Progress bar
                        ProgressBar(current: currentQuestionIndex + 1, total: questions.count)
                            .padding(.horizontal)
                        
                        // Question
                        QuestionCard(
                            question: questions[currentQuestionIndex],
                            selectedAnswer: $selectedAnswer,
                            hasAnswered: answeredQuestions.contains(currentQuestionIndex)
                        )
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // Next button
                        Button {
                            handleNext()
                        } label: {
                            Text(currentQuestionIndex == questions.count - 1 ? "Finish" : "Next")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedAnswer != nil ? Color.blue : Color.gray)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                        .disabled(selectedAnswer == nil)
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("News Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                generateQuestions()
                viewModel.activityTracker.trackPuzzlePlay(gameType: "Quiz", completed: false)
            }
        }
    }
    
    private func generateQuestions() {
        // Generate 5 questions from recent feeds
        let recentFeeds = viewModel.newsFeeds.prefix(20)
        questions = Array(recentFeeds.prefix(5)).map { feed in
            QuizQuestion(from: feed)
        }
    }
    
    private func handleNext() {
        guard let answer = selectedAnswer else { return }
        
        // Check if correct
        if answer == questions[currentQuestionIndex].correctAnswer {
            score += 1
        }
        
        answeredQuestions.insert(currentQuestionIndex)
        
        // Move to next or show results
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            selectedAnswer = nil
        } else {
            showingResults = true
            viewModel.activityTracker.trackPuzzlePlay(gameType: "Quiz", completed: true)
        }
    }
}

// MARK: - Quiz Question Model
struct QuizQuestion {
    let question: String
    let options: [String]
    let correctAnswer: Int
    let source: String
    
    init(from feed: NewsFeed) {
        // Generate question from feed title
        let words = feed.title.components(separatedBy: " ")
        
        // Simple question generation
        if words.count > 5 {
            // Create a fill-in-the-blank question
            let randomIndex = Int.random(in: 2..<min(words.count - 2, 8))
            let correctWord = words[randomIndex]
            
            var questionWords = words
            questionWords[randomIndex] = "_____"
            question = "Fill in the blank: \(questionWords.joined(separator: " "))"
            
            // Generate options
            let otherWords = ["reported", "announced", "revealed", "confirmed", "stated", "explained"]
            var opts = [correctWord]
            opts.append(contentsOf: otherWords.filter { $0 != correctWord.lowercased() }.prefix(3))
            opts.shuffle()
            
            options = opts
            correctAnswer = opts.firstIndex(of: correctWord) ?? 0
        } else {
            // Simple true/false about source
            question = "This article is from \(feed.sourceName ?? "Unknown Source"). True or False?"
            options = ["True", "False"]
            correctAnswer = 0
        }
        
        source = feed.sourceName ?? "Unknown"
    }
}

// MARK: - Question Card
struct QuestionCard: View {
    let question: QuizQuestion
    @Binding var selectedAnswer: Int?
    let hasAnswered: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Question
            Text(question.question)
                .font(.title3)
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)
            
            // Options
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                OptionButton(
                    text: option,
                    isSelected: selectedAnswer == index,
                    isCorrect: hasAnswered ? index == question.correctAnswer : nil
                ) {
                    if !hasAnswered {
                        selectedAnswer = index
                    }
                }
            }
            
            // Source
            Text("Source: \(question.source)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

// MARK: - Option Button
struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool?
    let action: () -> Void
    
    var backgroundColor: Color {
        if let isCorrect = isCorrect {
            if isCorrect {
                return .green.opacity(0.2)
            } else if isSelected {
                return .red.opacity(0.2)
            }
        } else if isSelected {
            return .blue.opacity(0.2)
        }
        return Color(.systemGray6)
    }
    
    var borderColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .green : (isSelected ? .red : .clear)
        } else if isSelected {
            return .blue
        }
        return .clear
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if let isCorrect = isCorrect {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCorrect ? .green : .red)
                }
            }
            .padding()
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let current: Int
    let total: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Question \(current) of \(total)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(current) / CGFloat(total), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Results View
struct ResultsView: View {
    let score: Int
    let total: Int
    let onDismiss: () -> Void
    
    var percentage: Int {
        Int((Double(score) / Double(total)) * 100)
    }
    
    var emoji: String {
        switch percentage {
        case 90...100: return "🏆"
        case 70..<90: return "🎉"
        case 50..<70: return "👍"
        default: return "💪"
        }
    }
    
    var message: String {
        switch percentage {
        case 90...100: return "Perfect! You're a news expert!"
        case 70..<90: return "Great job! You know your news!"
        case 50..<70: return "Good effort! Keep reading!"
        default: return "Keep learning! Read more news!"
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text(emoji)
                .font(.system(size: 80))
            
            Text("Quiz Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                Text("\(score) / \(total)")
                    .font(.system(size: 60, weight: .bold))
                
                Text("\(percentage)% Correct")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Preview
#Preview {
    NewsQuizView(viewModel: RSSFeedViewModel())
}
