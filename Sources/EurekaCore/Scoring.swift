/// What happened while a puzzle was on screen.
public struct SolveStats: Equatable, Sendable {
    public var seconds: Double
    /// Scratch-pad calculations, plus extra moves beyond the best on a board.
    public var steps: Int
    public var wrongTries: Int
    public var hintsUsed: Int
    /// The player pressed "Show me the trick" instead of solving.
    public var gaveUp: Bool

    public init(seconds: Double, steps: Int = 0, wrongTries: Int = 0, hintsUsed: Int = 0, gaveUp: Bool = false) {
        self.seconds = seconds
        self.steps = steps
        self.wrongTries = wrongTries
        self.hintsUsed = hintsUsed
        self.gaveUp = gaveUp
    }

    /// Solved with at most one slip and at most one hint.
    public var isClean: Bool { !gaveUp && wrongTries <= 1 && hintsUsed <= 1 }

    /// Clearly hard going. Used to step the level down gently.
    public var isStruggle: Bool { gaveUp || wrongTries >= 3 || hintsUsed >= 3 }
}

/// Up to three stars: one for solving, one for speed, one for elegance.
public struct StarAward: Equatable, Sendable {
    public var solved: Bool
    public var speedy: Bool
    public var elegant: Bool

    public var stars: Int { solved ? 1 + (speedy ? 1 : 0) + (elegant ? 1 : 0) : 0 }

    public static func award(for puzzle: Puzzle, stats: SolveStats) -> StarAward {
        guard !stats.gaveUp else { return StarAward(solved: false, speedy: false, elegant: false) }
        let speedy = stats.seconds <= Double(puzzle.parSeconds)
        let elegant = stats.steps <= puzzle.parSteps && stats.hintsUsed <= 1 && stats.wrongTries <= 1
        return StarAward(solved: true, speedy: speedy, elegant: elegant)
    }

    /// A short line for the Eureka screen.
    public func message(for puzzle: Puzzle, stats: SolveStats) -> String {
        if !solved { return "Now you know the trick. Try a new one!" }
        switch (speedy, elegant) {
        case (true, true): return "Fast AND clever. A true shortcut finder!"
        case (false, true): return "Elegant! You found the shortcut."
        case (true, false): return stats.steps > puzzle.parSteps ? "Speedy! Next time, can you do it in \(puzzle.parSteps) steps or fewer?" : "Speedy! Try it with fewer hints next time."
        case (false, false): return "Solved! The long way is \(puzzle.longWay). The trick is much shorter."
        }
    }
}
