public struct RecordResult: Equatable, Sendable {
    public var award: StarAward
    public var newBest: Bool
    public var levelChange: LevelChange?
    public var streak: Int
    public var unlocked: ChapterID?
}

/// Everything saved on this Mac. No names, no accounts.
public struct PlayerProgress: Codable, Equatable, Sendable {
    public var coach = LevelCoach()
    /// Best stars per puzzle kind (raw value), across levels.
    public var bestStars: [String: Int] = [:]
    /// How many times each kind was solved.
    public var solves: [String: Int] = [:]
    public var currentStreak = 0
    public var bestStreak = 0
    public var challengeBest = 0
    /// A grown-up opened every chapter.
    public var allChaptersOpen = false

    public init() {}

    public static let fresh = PlayerProgress()

    /// Puzzles solved in a chapter before the next one opens.
    public static let solvesToUnlock = 3

    public var level: Level { coach.level }

    public var totalStars: Int { bestStars.values.reduce(0, +) }

    public func stars(for kind: PuzzleKind) -> Int { bestStars[kind.rawValue] ?? 0 }

    public func solvedKinds(in chapter: ChapterID) -> Int {
        Chapter.chapter(chapter).kinds.filter { (solves[$0.rawValue] ?? 0) > 0 }.count
            + Chapter.explorerKinds[chapter, default: []].filter { !Chapter.chapter(chapter).kinds.contains($0) && (solves[$0.rawValue] ?? 0) > 0 }.count
    }

    public func isUnlocked(_ chapter: ChapterID) -> Bool {
        if allChaptersOpen || chapter == .pairs { return true }
        guard let previous = ChapterID(rawValue: chapter.rawValue - 1) else { return true }
        return isUnlocked(previous) && solvedKinds(in: previous) >= PlayerProgress.solvesToUnlock
    }

    public var unlockedChapters: [ChapterID] { ChapterID.allCases.filter(isUnlocked) }

    public mutating func record(_ puzzle: Puzzle, stats: SolveStats) -> RecordResult {
        let award = StarAward.award(for: puzzle, stats: stats)
        let before = Set(unlockedChapters)
        var newBest = false
        if award.solved {
            let key = puzzle.kind.rawValue
            solves[key, default: 0] += 1
            if award.stars > (bestStars[key] ?? 0) {
                bestStars[key] = award.stars
                newBest = true
            }
        }
        if award.solved && stats.wrongTries == 0 && !stats.gaveUp {
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
        } else {
            currentStreak = 0
        }
        let change = coach.record(Outcome(award: award, stats: stats))
        let unlocked = unlockedChapters.first { !before.contains($0) }
        return RecordResult(award: award, newBest: newBest, levelChange: change, streak: currentStreak, unlocked: unlocked)
    }

    /// A grown-up's "start over". Clears stars and sends the level back to Explorer.
    public mutating func resetAll() {
        self = PlayerProgress()
    }
}
