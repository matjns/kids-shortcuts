/// Free play: a run of mixed puzzles from the chapters that are open.
/// Three wrong answers end the run. Score is the stars earned.
public struct ChallengeRun: Equatable, Sendable {
    public static let length = 8
    public static let startingLives = 3

    public private(set) var puzzles: [Puzzle]
    public private(set) var index = 0
    public private(set) var lives = ChallengeRun.startingLives
    public private(set) var score = 0

    /// Long boards stay in the chapters; Challenge keeps things quick.
    public static let excluded: Set<PuzzleKind> = [.hanoiPlay, .kenKenFour, .logicGrid, .magicSquare]

    public init(level: Level, chapters: [ChapterID], seed: UInt64) {
        var rng = SplitMix64(seed: seed)
        let open = chapters.isEmpty ? [ChapterID.pairs] : chapters
        let kinds = open.flatMap { Chapter.chapter($0).kinds(for: level) }.filter { !ChallengeRun.excluded.contains($0) }
        var picked: [Puzzle] = []
        var bag = rng.shuffled(kinds)
        while picked.count < ChallengeRun.length {
            if bag.isEmpty { bag = rng.shuffled(kinds) }
            let kind = bag.removeLast()
            picked.append(PuzzleGenerator.make(kind, level: level, seed: rng.next()))
        }
        puzzles = picked
    }

    public var current: Puzzle? { isOver ? nil : puzzles[index] }

    public var isOver: Bool { lives == 0 || index >= puzzles.count }

    public mutating func wrongAnswer() {
        guard !isOver else { return }
        lives -= 1
    }

    public mutating func finishCurrent(stars: Int) {
        guard !isOver else { return }
        score += stars
        index += 1
    }
}
