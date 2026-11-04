/// Tower of Hanoi: move the whole tower from the left peg to the right peg.
/// Only the top disc moves, and a disc never sits on a smaller one.
public struct HanoiGame: Equatable, Sendable {
    public private(set) var pegs: [[Int]]
    public private(set) var moves: Int = 0
    public let discs: Int

    public init(discs: Int) {
        self.discs = discs
        // Bottom of the peg first. Bigger number, bigger disc.
        pegs = [Array((1...discs).reversed()), [], []]
    }

    public var minimumMoves: Int { MathFacts.power(2, discs) - 1 }

    public var isSolved: Bool { pegs[2].count == discs }

    public func canMove(from: Int, to: Int) -> Bool {
        guard from != to, (0..<3).contains(from), (0..<3).contains(to) else { return false }
        guard let disc = pegs[from].last else { return false }
        if let top = pegs[to].last { return disc < top }
        return true
    }

    @discardableResult
    public mutating func move(from: Int, to: Int) -> Bool {
        guard canMove(from: from, to: to) else { return false }
        let disc = pegs[from].removeLast()
        pegs[to].append(disc)
        moves += 1
        return true
    }

    /// The shortest solution, as (from, to) pairs. Used by tests and the "show me" replay.
    public static func solution(discs: Int, from: Int = 0, to: Int = 2, via: Int = 1) -> [(Int, Int)] {
        guard discs > 0 else { return [] }
        return solution(discs: discs - 1, from: from, to: via, via: to)
            + [(from, to)]
            + solution(discs: discs - 1, from: via, to: to, via: from)
    }
}
