/// One finished puzzle, as the coach remembers it.
public struct Outcome: Codable, Equatable, Sendable {
    public var stars: Int
    public var clean: Bool
    public var struggled: Bool

    public init(stars: Int, clean: Bool, struggled: Bool) {
        self.stars = stars
        self.clean = clean
        self.struggled = struggled
    }

    public init(award: StarAward, stats: SolveStats) {
        self.init(stars: award.stars, clean: award.solved && stats.isClean, struggled: stats.isStruggle)
    }
}

public enum LevelChange: Equatable, Sendable {
    case up(Level)
    case down(Level)
}

/// Moves a player between levels by how they are doing. Everyone starts as
/// an Explorer. There is no picker for kids; a grown-up can override it.
public struct LevelCoach: Codable, Equatable, Sendable {
    public var level: Level = .explorer
    /// Recent results at the current level, oldest first.
    public var recent: [Outcome] = []
    /// A grown-up pinned the level. Automatic moves are off.
    public var pinned = false

    /// Level up after at least this many puzzles at the level…
    public static let window = 10
    /// …when this many of the last `window` were clean solves…
    public static let cleanNeeded = 8
    /// …and the stars average at least this.
    public static let starsNeeded = 2.0
    /// Step down when this many of the last `struggleWindow` were a struggle.
    public static let struggleWindow = 6
    public static let strugglesForDown = 4

    public init(level: Level = .explorer) {
        self.level = level
    }

    /// 0...1, for the "next level" meter on the map.
    public var progressToNextLevel: Double {
        guard level.next != nil else { return 1 }
        let last = recent.suffix(LevelCoach.window)
        let clean = last.filter(\.clean).count
        return min(1, Double(clean) / Double(LevelCoach.cleanNeeded))
    }

    public mutating func record(_ outcome: Outcome) -> LevelChange? {
        recent.append(outcome)
        if recent.count > 30 { recent.removeFirst(recent.count - 30) }
        guard !pinned else { return nil }

        let last = recent.suffix(LevelCoach.window)
        if let next = level.next, last.count >= LevelCoach.window {
            let clean = last.filter(\.clean).count
            let average = Double(last.reduce(0) { $0 + $1.stars }) / Double(last.count)
            if clean >= LevelCoach.cleanNeeded && average >= LevelCoach.starsNeeded {
                level = next
                recent = []
                return .up(next)
            }
        }

        let tail = recent.suffix(LevelCoach.struggleWindow)
        if let previous = level.previous, tail.count >= LevelCoach.struggleWindow {
            if tail.filter(\.struggled).count >= LevelCoach.strugglesForDown {
                level = previous
                recent = []
                return .down(previous)
            }
        }
        return nil
    }

    /// Grown-up override from the hidden settings.
    public mutating func set(_ newLevel: Level, pinned: Bool) {
        level = newLevel
        self.pinned = pinned
        recent = []
    }
}
