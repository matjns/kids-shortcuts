/// A 3 by 3 magic square made from nine numbers in a row, lowest...lowest+8.
public struct MagicSquarePuzzle: Equatable, Sendable {
    public var lowest: Int
    public var solution: [Int]
    public var givens: [Bool]

    public init(lowest: Int, solution: [Int], givens: [Bool]) {
        self.lowest = lowest
        self.solution = solution
        self.givens = givens
    }

    /// Every row, column and diagonal adds to this: the total of all nine numbers, divided by 3.
    public var magicTotal: Int { 3 * (lowest + 4) }

    public var numbers: ClosedRange<Int> { lowest...(lowest + 8) }

    public static let lines: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6],
    ]

    public static func isMagic(_ values: [Int]) -> Bool {
        guard values.count == 9 else { return false }
        let total = lines[0].reduce(0) { $0 + values[$1] }
        return lines.allSatisfy { line in line.reduce(0) { $0 + values[$1] } == total }
    }

    public func isSolved(_ entries: [Int?]) -> Bool {
        guard entries.count == 9 else { return false }
        let values = entries.compactMap { $0 }
        guard values.count == 9, Set(values) == Set(numbers) else { return false }
        for index in 0..<9 where givens[index] && values[index] != solution[index] {
            return false
        }
        return MagicSquarePuzzle.isMagic(values) && values.reduce(0, +) == 3 * magicTotal
    }

    /// All eight magic squares of 1...9 (the Lo Shu square turned and flipped).
    public static func allBaseSquares() -> [[Int]] {
        let loShu = [2, 7, 6, 9, 5, 1, 4, 3, 8]
        func rotate(_ s: [Int]) -> [Int] {
            // Turn a quarter clockwise: new[r][c] = old[2-c][r]
            (0..<9).map { index in
                let r = index / 3
                let c = index % 3
                return s[(2 - c) * 3 + r]
            }
        }
        func flip(_ s: [Int]) -> [Int] {
            (0..<9).map { index in s[(index / 3) * 3 + (2 - index % 3)] }
        }
        var result: [[Int]] = []
        var current = loShu
        for _ in 0..<4 {
            result.append(current)
            result.append(flip(current))
            current = rotate(current)
        }
        return result
    }

    public static func generate(using rng: inout SplitMix64) -> MagicSquarePuzzle {
        let lowest = rng.int(1...12)
        let bases = allBaseSquares().map { square in square.map { $0 + lowest - 1 } }
        let solution = rng.pick(bases)
        for _ in 0..<200 {
            let picked = Array(rng.shuffled(Array(0..<9)).prefix(3))
            let matches = bases.filter { square in picked.allSatisfy { square[$0] == solution[$0] } }
            if matches.count == 1 {
                let givens = (0..<9).map { picked.contains($0) }
                return MagicSquarePuzzle(lowest: lowest, solution: solution, givens: givens)
            }
        }
        // A corner and the edge next to it always pin down one square.
        let givens = (0..<9).map { $0 == 0 || $0 == 1 || $0 == 4 }
        return MagicSquarePuzzle(lowest: lowest, solution: solution, givens: givens)
    }
}
