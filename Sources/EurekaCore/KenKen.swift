public enum KenKenOperation: String, Equatable, Sendable, Codable {
    case add = "+"
    case subtract = "−"
    case multiply = "×"
    case divide = "÷"
    case given = ""
}

public struct KenKenCage: Equatable, Sendable, Codable {
    /// Cell indexes, row * size + column.
    public var cells: [Int]
    public var operation: KenKenOperation
    public var target: Int

    public init(cells: [Int], operation: KenKenOperation, target: Int) {
        self.cells = cells.sorted()
        self.operation = operation
        self.target = target
    }

    public var label: String { "\(target)\(operation.rawValue)" }

    /// The cell that shows the label: the first cell in reading order.
    public var labelCell: Int { cells.min() ?? 0 }

    public func isSatisfied(by values: [Int]) -> Bool {
        guard values.count == cells.count, !values.isEmpty else { return false }
        switch operation {
        case .given:
            return values[0] == target
        case .add:
            return values.reduce(0, +) == target
        case .multiply:
            return values.reduce(1, *) == target
        case .subtract:
            guard values.count == 2 else { return false }
            return abs(values[0] - values[1]) == target
        case .divide:
            guard values.count == 2 else { return false }
            let big = max(values[0], values[1])
            let small = min(values[0], values[1])
            return small > 0 && big % small == 0 && big / small == target
        }
    }
}

/// A KenKen board: every row and column uses 1...size once, and every cage
/// makes its target with its operation.
public struct KenKenPuzzle: Equatable, Sendable {
    public var size: Int
    public var cages: [KenKenCage]
    public var solution: [Int]

    public init(size: Int, cages: [KenKenCage], solution: [Int]) {
        self.size = size
        self.cages = cages
        self.solution = solution
    }

    public func cageIndex(of cell: Int) -> Int? {
        cages.firstIndex { $0.cells.contains(cell) }
    }

    /// True when the entries are a complete, valid solution.
    /// Any valid filling counts, not only the stored one.
    public func isSolved(_ entries: [Int?]) -> Bool {
        guard entries.count == size * size else { return false }
        var values: [Int] = []
        for entry in entries {
            guard let entry, entry >= 1, entry <= size else { return false }
            values.append(entry)
        }
        for line in 0..<size {
            let row = Set((0..<size).map { values[line * size + $0] })
            let column = Set((0..<size).map { values[$0 * size + line] })
            if row.count != size || column.count != size { return false }
        }
        for cage in cages where !cage.isSatisfied(by: cage.cells.map { values[$0] }) {
            return false
        }
        return true
    }

    /// Counts solutions, stopping at `limit`. Used to make sure a puzzle has exactly one.
    public func countSolutions(limit: Int = 2) -> Int {
        var grid = [Int](repeating: 0, count: size * size)
        var count = 0
        let cageOf = (0..<(size * size)).map { cageIndex(of: $0) ?? 0 }

        func fits(_ cell: Int, _ value: Int) -> Bool {
            let row = cell / size
            let column = cell % size
            for i in 0..<size {
                if grid[row * size + i] == value || grid[i * size + column] == value { return false }
            }
            let cage = cages[cageOf[cell]]
            // Check the cage once its last cell is being placed.
            if cage.cells.last == cell {
                let values = cage.cells.map { $0 == cell ? value : grid[$0] }
                return cage.isSatisfied(by: values)
            }
            if cage.operation == .add {
                let partial = cage.cells.reduce(0) { $0 + ($1 == cell ? value : grid[$1]) }
                if partial >= cage.target { return false }
            }
            if cage.operation == .multiply {
                let partial = cage.cells.reduce(1) { $0 * ($1 == cell ? value : max(1, grid[$1])) }
                if cage.target % partial != 0 { return false }
            }
            return true
        }

        func place(_ cell: Int) {
            if count >= limit { return }
            if cell == size * size {
                count += 1
                return
            }
            for value in 1...size where fits(cell, value) {
                grid[cell] = value
                place(cell + 1)
                grid[cell] = 0
                if count >= limit { return }
            }
        }

        place(0)
        return count
    }

    /// A random puzzle with exactly one solution. Cells are filled in reading
    /// order, so each cage's last cell is its highest index.
    public static func generate(size: Int, using rng: inout SplitMix64) -> KenKenPuzzle {
        for _ in 0..<400 {
            let solution = randomLatinSquare(size: size, using: &rng)
            let groups = randomCages(size: size, using: &rng)
            let cages = groups.map { cageFor(cells: $0, solution: solution, using: &rng) }
            let puzzle = KenKenPuzzle(size: size, cages: cages, solution: solution)
            if puzzle.countSolutions(limit: 2) == 1 {
                return puzzle
            }
        }
        // Practically unreachable. Every cell given is still a valid, unique board.
        let solution = randomLatinSquare(size: size, using: &rng)
        let cages = (0..<(size * size)).map { KenKenCage(cells: [$0], operation: .given, target: solution[$0]) }
        return KenKenPuzzle(size: size, cages: cages, solution: solution)
    }

    static func randomLatinSquare(size: Int, using rng: inout SplitMix64) -> [Int] {
        let rows = rng.shuffled(Array(0..<size))
        let columns = rng.shuffled(Array(0..<size))
        let symbols = rng.shuffled(Array(1...size))
        var grid = [Int](repeating: 0, count: size * size)
        for r in 0..<size {
            for c in 0..<size {
                grid[r * size + c] = symbols[(rows[r] + columns[c]) % size]
            }
        }
        return grid
    }

    static func randomCages(size: Int, using rng: inout SplitMix64) -> [[Int]] {
        var owner = [Int](repeating: -1, count: size * size)
        var groups: [[Int]] = []
        var singles = 0
        for start in 0..<(size * size) where owner[start] == -1 {
            let roll = rng.int(0...99)
            var wanted = roll < 12 ? 1 : (roll < 70 ? 2 : 3)
            if wanted == 1 && singles >= (size == 3 ? 1 : 2) { wanted = 2 }
            var group = [start]
            owner[start] = groups.count
            while group.count < wanted {
                var options: [Int] = []
                for cell in group {
                    let r = cell / size
                    let c = cell % size
                    let neighbors = [(r, c + 1), (r + 1, c), (r, c - 1), (r - 1, c)]
                    for (nr, nc) in neighbors where nr >= 0 && nr < size && nc >= 0 && nc < size {
                        let index = nr * size + nc
                        if owner[index] == -1 && !options.contains(index) { options.append(index) }
                    }
                }
                if options.isEmpty { break }
                let next = rng.pick(options)
                owner[next] = groups.count
                group.append(next)
            }
            if group.count == 1 { singles += 1 }
            groups.append(group.sorted())
        }
        return groups
    }

    static func cageFor(cells: [Int], solution: [Int], using rng: inout SplitMix64) -> KenKenCage {
        let values = cells.map { solution[$0] }
        if values.count == 1 {
            return KenKenCage(cells: cells, operation: .given, target: values[0])
        }
        if values.count == 2 {
            let big = max(values[0], values[1])
            let small = min(values[0], values[1])
            if big % small == 0 && big != small && rng.bool(0.5) {
                return KenKenCage(cells: cells, operation: .divide, target: big / small)
            }
            switch rng.int(0...2) {
            case 0: return KenKenCage(cells: cells, operation: .subtract, target: big - small)
            case 1: return KenKenCage(cells: cells, operation: .add, target: big + small)
            default: return KenKenCage(cells: cells, operation: .multiply, target: big * small)
            }
        }
        if rng.bool(0.6) {
            return KenKenCage(cells: cells, operation: .add, target: values.reduce(0, +))
        }
        return KenKenCage(cells: cells, operation: .multiply, target: values.reduce(1, *))
    }
}
