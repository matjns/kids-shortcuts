/// Numbers in a row that the player pairs up by tapping two of them.
public struct PairingBoard: Equatable, Sendable {
    public let numbers: [Int]
    public private(set) var pairs: [[Int]] = []
    public private(set) var selected: Int?

    public init(numbers: [Int]) {
        self.numbers = numbers
    }

    public func pairIndex(containing index: Int) -> Int? {
        pairs.firstIndex { $0.contains(index) }
    }

    /// Tap a number: select it, pair it with the selected one, or undo its pair.
    public mutating func tap(_ index: Int) {
        guard numbers.indices.contains(index) else { return }
        if let existing = pairIndex(containing: index) {
            pairs.remove(at: existing)
            selected = nil
            return
        }
        guard let first = selected else {
            selected = index
            return
        }
        if first == index {
            selected = nil
            return
        }
        pairs.append([min(first, index), max(first, index)])
        selected = nil
    }

    public mutating func reset() {
        pairs = []
        selected = nil
    }

    public var pairSums: [Int] {
        pairs.map { numbers[$0[0]] + numbers[$0[1]] }
    }

    /// At least two pairs, all with the same total. This is the "aha" moment.
    public var everyPairMatches: Bool {
        let sums = pairSums
        guard sums.count >= 2, let first = sums.first else { return false }
        return sums.allSatisfy { $0 == first }
    }

    /// Every number is paired, except at most one middle number when the count is odd.
    public var isComplete: Bool {
        pairs.count == numbers.count / 2
    }

    public var unpaired: [Int] {
        numbers.indices.filter { pairIndex(containing: $0) == nil }
    }

    /// The pairing the trick uses: first with last, second with second-last, ...
    public mutating func autoPairEnds() {
        pairs = (0..<(numbers.count / 2)).map { [$0, numbers.count - 1 - $0] }
        selected = nil
    }
}
