import SwiftUI

// MARK: - Sudoku View
struct SudokuView: View {
    @ObservedObject var viewModel: RSSFeedViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var game = SudokuGame()
    @State private var hasTrackedPlay = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if game.isCompleted {
                        CompletionView {
                            viewModel.puzzleProgress.sudokuCompleted = true
                            viewModel.savePuzzleProgress()
                            viewModel.activityTracker.trackPuzzlePlay(gameType: "Sudoku", completed: true)
                            dismiss()
                        }
                    } else {
                        // Timer and difficulty
                        HStack {
                            Label("\(game.formattedTime)", systemImage: "clock.fill")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("Easy")
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.2))
                                .foregroundStyle(.green)
                                .cornerRadius(20)
                        }
                        .padding(.horizontal)
                        
                        // Game Grid
                        SudokuGrid(game: game)
                            .padding()
                        
                        // Number Pad
                        NumberPad(game: game)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .onAppear {
                    if !hasTrackedPlay {
                        viewModel.activityTracker.trackPuzzlePlay(gameType: "Sudoku", completed: false)
                        hasTrackedPlay = true
                    }
                }
            }
            .navigationTitle("Daily Sudoku")
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

// MARK: - Sudoku Game
class SudokuGame: ObservableObject {
    @Published var grid: [[SudokuCell]]
    @Published var selectedCell: (row: Int, col: Int)?
    @Published var isCompleted = false
    @Published var elapsedTime = 0
    
    private var timer: Timer?
    private let solution: [[Int]]
    
    init() {
        // Simple 9x9 Sudoku (Easy difficulty)
        // This is a pre-made puzzle - in production, you'd generate these
        let puzzle: [[Int?]] = [
            [5, 3, nil, nil, 7, nil, nil, nil, nil],
            [6, nil, nil, 1, 9, 5, nil, nil, nil],
            [nil, 9, 8, nil, nil, nil, nil, 6, nil],
            [8, nil, nil, nil, 6, nil, nil, nil, 3],
            [4, nil, nil, 8, nil, 3, nil, nil, 1],
            [7, nil, nil, nil, 2, nil, nil, nil, 6],
            [nil, 6, nil, nil, nil, nil, 2, 8, nil],
            [nil, nil, nil, 4, 1, 9, nil, nil, 5],
            [nil, nil, nil, nil, 8, nil, nil, 7, 9]
        ]
        
        solution = [
            [5, 3, 4, 6, 7, 8, 9, 1, 2],
            [6, 7, 2, 1, 9, 5, 3, 4, 8],
            [1, 9, 8, 3, 4, 2, 5, 6, 7],
            [8, 5, 9, 7, 6, 1, 4, 2, 3],
            [4, 2, 6, 8, 5, 3, 7, 9, 1],
            [7, 1, 3, 9, 2, 4, 8, 5, 6],
            [9, 6, 1, 5, 3, 7, 2, 8, 4],
            [2, 8, 7, 4, 1, 9, 6, 3, 5],
            [3, 4, 5, 2, 8, 6, 1, 7, 9]
        ]
        
        grid = puzzle.enumerated().map { row, rowValues in
            rowValues.enumerated().map { col, value in
                SudokuCell(
                    value: value,
                    isFixed: value != nil,
                    isValid: true
                )
            }
        }
        
        startTimer()
    }
    
    func selectCell(row: Int, col: Int) {
        guard !grid[row][col].isFixed else { return }
        selectedCell = (row, col)
    }
    
    func setNumber(_ number: Int) {
        guard let selected = selectedCell else { return }
        grid[selected.row][selected.col].value = number
        
        // Validate
        validateCell(row: selected.row, col: selected.col)
        checkCompletion()
    }
    
    func clearCell() {
        guard let selected = selectedCell else { return }
        if !grid[selected.row][selected.col].isFixed {
            grid[selected.row][selected.col].value = nil
            grid[selected.row][selected.col].isValid = true
        }
    }
    
    private func validateCell(row: Int, col: Int) {
        guard let value = grid[row][col].value else { return }
        
        // Check if value matches solution
        grid[row][col].isValid = (value == solution[row][col])
    }
    
    private func checkCompletion() {
        // Check if all cells are filled and valid
        let allFilled = grid.allSatisfy { row in
            row.allSatisfy { $0.value != nil }
        }
        
        let allValid = grid.allSatisfy { row in
            row.allSatisfy { $0.isValid }
        }
        
        if allFilled && allValid {
            isCompleted = true
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedTime += 1
        }
    }
    
    var formattedTime: String {
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func reset() {
        // Reset to initial state
        isCompleted = false
        elapsedTime = 0
        selectedCell = nil
        
        for row in 0..<9 {
            for col in 0..<9 {
                if !grid[row][col].isFixed {
                    grid[row][col].value = nil
                    grid[row][col].isValid = true
                }
            }
        }
        
        timer?.invalidate()
        startTimer()
    }
}

// MARK: - Sudoku Cell
struct SudokuCell {
    var value: Int?
    let isFixed: Bool
    var isValid: Bool
}

// MARK: - Sudoku Grid
struct SudokuGrid: View {
    @ObservedObject var game: SudokuGame
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<9) { row in
                HStack(spacing: 0) {
                    ForEach(0..<9) { col in
                        cellView(row: row, col: col)
                    }
                }
                .border(width: rowBorderWidth(row), edges: [.bottom], color: .primary)
            }
        }
        .border(width: 2, edges: Edge.allEdges, color: .primary)
        .background(Color(.systemBackground))
    }
    
    private func cellView(row: Int, col: Int) -> some View {
        let cell = game.grid[row][col]
        let isSelected = game.selectedCell?.row == row && game.selectedCell?.col == col
        let borderWidth = columnBorderWidth(col)
        
        return CellView(
            cell: cell,
            isSelected: isSelected
        ) {
            game.selectCell(row: row, col: col)
        }
        .border(width: borderWidth, edges: [.trailing], color: .primary)
    }
    
    private func columnBorderWidth(_ col: Int) -> CGFloat {
        return (col % 3 == 2 && col < 8) ? 2 : 1
    }
    
    private func rowBorderWidth(_ row: Int) -> CGFloat {
        return (row % 3 == 2 && row < 8) ? 2 : 1
    }
}

// MARK: - Cell View
struct CellView: View {
    let cell: SudokuCell
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(backgroundColor)
                    .frame(width: 40, height: 40)
                
                if let value = cell.value {
                    Text("\(value)")
                        .font(.title3)
                        .fontWeight(cell.isFixed ? .bold : .regular)
                        .foregroundStyle(textColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.blue.opacity(0.3)
        } else if !cell.isValid {
            return Color.red.opacity(0.2)
        }
        return Color(.systemBackground)
    }
    
    private var textColor: Color {
        if cell.isFixed {
            return .primary
        } else if !cell.isValid {
            return .red
        }
        return .blue
    }
}

// MARK: - Number Pad
struct NumberPad: View {
    @ObservedObject var game: SudokuGame
    
    var body: some View {
        VStack(spacing: 12) {
            // Numbers 1-9
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(1...9, id: \.self) { number in
                    Button {
                        game.setNumber(number)
                    } label: {
                        Text("\(number)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(width: 60, height: 60)
                            .background(Color(.systemGray6))
                            .foregroundStyle(.primary)
                            .cornerRadius(12)
                    }
                }
                
                // Clear button
                Button {
                    game.clearCell()
                } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.title2)
                        .frame(width: 60, height: 60)
                        .background(Color.red.opacity(0.2))
                        .foregroundStyle(.red)
                        .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Completion View
struct CompletionView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("🎉")
                .font(.system(size: 80))
            
            Text("Puzzle Solved!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Congratulations! You've completed the sudoku puzzle!")
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
                    .background(Color.purple)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Border Extension
extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(
            EdgeBorder(width: width, edges: edges)
                .foregroundColor(color)
        )
    }
}

struct EdgeBorder: Shape {
    let width: CGFloat
    let edges: [Edge]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            let edgeRect = calculateRect(for: edge, in: rect)
            path.addRect(edgeRect)
        }
        return path
    }
    
    private func calculateRect(for edge: Edge, in rect: CGRect) -> CGRect {
        switch edge {
        case .top:
            return CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width)
        case .bottom:
            return CGRect(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width)
        case .leading:
            return CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height)
        case .trailing:
            return CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height)
        }
    }
}

enum Edge {
    case top, bottom, leading, trailing
    
    static var allEdges: [Edge] {
        [.top, .bottom, .leading, .trailing]
    }
}

// MARK: - Preview
#Preview {
    SudokuView(viewModel: RSSFeedViewModel())
}
