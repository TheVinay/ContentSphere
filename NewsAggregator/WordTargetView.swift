import SwiftUI

// MARK: - Word Target View
struct WordTargetView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var game = WordTargetGame()
    @State private var hasTrackedPlay = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if game.gameState == .won || game.gameState == .lost {
                        ResultView(game: game) {
                            viewModel.puzzleProgress.wordTargetCompleted = true
                            viewModel.savePuzzleProgress()
                            viewModel.activityTracker.trackPuzzlePlay(gameType: "Word Target", completed: true)
                            dismiss()
                        }
                    } else {
                        // Game Board
                        GameBoard(game: game)
                        
                        Spacer()
                        
                        // Keyboard
                        GameKeyboard(game: game)
                    }
                }
                .padding()
                .onAppear {
                    if !hasTrackedPlay {
                        viewModel.activityTracker.trackPuzzlePlay(gameType: "Word Target", completed: false)
                        hasTrackedPlay = true
                    }
                }
            }
            .navigationTitle("Word Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        game.reset()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

// MARK: - Word Target Game
class WordTargetGame: ObservableObject {
    @Published var guesses: [[Letter]] = Array(repeating: Array(repeating: Letter(), count: 5), count: 6)
    @Published var currentRow = 0
    @Published var currentCol = 0
    @Published var gameState: GameState = .playing
    @Published var usedLetters: [Character: LetterState] = [:]
    
    private let targetWord: String
    private let wordList = ["APPLE", "BREAD", "CRANE", "DREAM", "EARTH", "FLAME", "GLOBE", "HOUSE", "IMAGE", "JOLLY"]
    
    enum GameState {
        case playing
        case won
        case lost
    }
    
    init() {
        targetWord = wordList.randomElement() ?? "APPLE"
    }
    
    func addLetter(_ letter: Character) {
        guard gameState == .playing, currentCol < 5 else { return }
        guesses[currentRow][currentCol] = Letter(char: letter)
        currentCol += 1
    }
    
    func deleteLetter() {
        guard currentCol > 0 else { return }
        currentCol -= 1
        guesses[currentRow][currentCol] = Letter()
    }
    
    func submitGuess() {
        guard currentCol == 5 else { return }
        
        let guess = guesses[currentRow].map { String($0.char) }.joined()
        
        // Check guess against target
        for (index, char) in guess.enumerated() {
            let targetChar = Array(targetWord)[index]
            
            if char == targetChar {
                guesses[currentRow][index].state = .correct
                usedLetters[char] = .correct
            } else if targetWord.contains(char) {
                guesses[currentRow][index].state = .wrongPosition
                if usedLetters[char] != .correct {
                    usedLetters[char] = .wrongPosition
                }
            } else {
                guesses[currentRow][index].state = .wrong
                usedLetters[char] = .wrong
            }
        }
        
        // Check win condition
        if guess == targetWord {
            gameState = .won
            return
        }
        
        // Move to next row
        currentRow += 1
        currentCol = 0
        
        // Check loss condition
        if currentRow >= 6 {
            gameState = .lost
        }
    }
    
    func reset() {
        guesses = Array(repeating: Array(repeating: Letter(), count: 5), count: 6)
        currentRow = 0
        currentCol = 0
        gameState = .playing
        usedLetters = [:]
    }
}

// MARK: - Letter Model
struct Letter {
    var char: Character = " "
    var state: LetterState = .unknown
}

enum LetterState {
    case unknown
    case wrong
    case wrongPosition
    case correct
    
    var color: Color {
        switch self {
        case .unknown: return Color(.systemGray5)
        case .wrong: return Color(.systemGray3)
        case .wrongPosition: return .yellow
        case .correct: return .green
        }
    }
}

// MARK: - Game Board
struct GameBoard: View {
    @ObservedObject var game: WordTargetGame
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<6) { row in
                HStack(spacing: 8) {
                    ForEach(0..<5) { col in
                        LetterBox(letter: game.guesses[row][col])
                    }
                }
            }
        }
    }
}

// MARK: - Letter Box
struct LetterBox: View {
    let letter: Letter
    
    var body: some View {
        Text(letter.char == " " ? "" : String(letter.char))
            .font(.title)
            .fontWeight(.bold)
            .frame(width: 60, height: 60)
            .background(letter.state.color)
            .foregroundStyle(letter.state == .unknown ? Color.primary : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 2)
            )
            .cornerRadius(8)
    }
}

// MARK: - Game Keyboard
struct GameKeyboard: View {
    @ObservedObject var game: WordTargetGame
    
    let rows = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["ENTER", "Z", "X", "C", "V", "B", "N", "M", "DELETE"]
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { key in
                        KeyButton(key: key, game: game)
                    }
                }
            }
        }
    }
}

// MARK: - Key Button
struct KeyButton: View {
    let key: String
    @ObservedObject var game: WordTargetGame
    
    var backgroundColor: Color {
        if key == "ENTER" || key == "DELETE" {
            return Color(.systemGray4)
        }
        
        guard let char = key.first, let state = game.usedLetters[char] else {
            return Color(.systemGray5)
        }
        
        return state.color
    }
    
    var body: some View {
        Button {
            handleKeyPress()
        } label: {
            Text(key)
                .font(key.count == 1 ? .title3 : .caption)
                .fontWeight(.semibold)
                .frame(width: key.count == 1 ? 30 : 60, height: 50)
                .background(backgroundColor)
                .foregroundStyle(game.usedLetters[key.first ?? " "] != nil && game.usedLetters[key.first ?? " "] != .unknown ? Color.white : Color.primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private func handleKeyPress() {
        if key == "ENTER" {
            game.submitGuess()
        } else if key == "DELETE" {
            game.deleteLetter()
        } else if let char = key.first {
            game.addLetter(char)
        }
    }
}

// MARK: - Result View
struct ResultView: View {
    @ObservedObject var game: WordTargetGame
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text(game.gameState == .won ? "🎉" : "😔")
                .font(.system(size: 80))
            
            Text(game.gameState == .won ? "You Won!" : "Game Over")
                .font(.title)
                .fontWeight(.bold)
            
            if game.gameState == .won {
                Text("You guessed the word in \(game.currentRow + 1) tries!")
                    .font(.headline)
            }
            
            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Button {
                game.reset()
            } label: {
                Text("Play Again")
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
    WordTargetView(viewModel: RSSFeedViewModel())
}
