/// One of the eight big ideas on the map.
public enum ChapterID: Int, CaseIterable, Codable, Hashable, Comparable, Sendable {
    case pairs = 1
    case triangles
    case odds
    case doubling
    case digits
    case pigeons
    case grids
    case logic

    public static func < (lhs: ChapterID, rhs: ChapterID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// How hard the puzzles are. Everyone starts as an Explorer. The game moves
/// a player up when they show mastery (see LevelCoach) and gently back down
/// if they are struggling a lot. There is no picker for kids.
public enum Level: String, CaseIterable, Codable, Hashable, Comparable, Sendable {
    /// Small numbers, pictures to play with, pick-an-answer buttons.
    case explorer
    /// Every puzzle, medium numbers, typed answers.
    case adventurer
    /// Every puzzle with the big numbers.
    case challenger

    public var rank: Int {
        switch self {
        case .explorer: return 0
        case .adventurer: return 1
        case .challenger: return 2
        }
    }

    public static func < (lhs: Level, rhs: Level) -> Bool { lhs.rank < rhs.rank }

    public var next: Level? {
        switch self {
        case .explorer: return .adventurer
        case .adventurer: return .challenger
        case .challenger: return nil
        }
    }

    public var previous: Level? {
        switch self {
        case .explorer: return nil
        case .adventurer: return .explorer
        case .challenger: return .adventurer
        }
    }

    public var title: String {
        switch self {
        case .explorer: return "Explorer"
        case .adventurer: return "Adventurer"
        case .challenger: return "Challenger"
        }
    }

    public var blurb: String {
        switch self {
        case .explorer: return "Small numbers, lots of pictures, pick the answer."
        case .adventurer: return "Every puzzle, bigger numbers, type the answer."
        case .challenger: return "The giant numbers. Only the trick will do."
        }
    }

    /// Answers are buttons at Explorer, typed above it.
    public var usesChoices: Bool { self == .explorer }
}

public struct Chapter: Equatable, Sendable {
    public var id: ChapterID
    public var title: String
    public var bigIdea: String
    public var symbol: String
    public var kinds: [PuzzleKind]

    public static let all: [Chapter] = [
        Chapter(id: .pairs, title: "Gauss's Pairs", bigIdea: "Pair the ends. Every pair makes the same total.", symbol: "link", kinds: [.pairUpTen, .teachersTrick, .oddOneInMiddle, .bigThousand, .fromHereToThere, .stepSequence, .missingCard]),
        Chapter(id: .triangles, title: "Triangle Town", bigIdea: "Two staircases fit together into a rectangle.", symbol: "triangle", kinds: [.staircaseFold, .canStack, .handshakes, .homeAndAway, .diagonals, .howManyRows]),
        Chapter(id: .odds, title: "Odd Squares", bigIdea: "Odd numbers wrap around a square, one L at a time.", symbol: "square.grid.3x3", kinds: [.oddLayers, .bigOdds, .oddsInRange, .upAndDown, .evensToo, .nextSquare]),
        Chapter(id: .doubling, title: "Doubling Peaks", bigIdea: "Add up the doubles and you land one short of the next double.", symbol: "arrow.up.right", kinds: [.doublingSum, .riceBoard, .hanoiPlay, .hanoiCount, .paperFold, .toppings, .lilyPond]),
        Chapter(id: .digits, title: "Digit Detectives", bigIdea: "The digit sum knows the remainder when you divide by 9 (and by 3).", symbol: "magnifyingglass", kinds: [.divisibleByNine, .remainderNine, .missingDigit, .whichByThree, .castingOutNines, .digitalRoot]),
        Chapter(id: .pigeons, title: "Pigeons & Parity", bigIdea: "More pigeons than holes means a crowd. Odd and even never lie.", symbol: "bird", kinds: [.sockDrawer, .sockTriples, .sharedMonth, .oddNumbersSum, .dominoBoard, .lockers, .oddOrEvenTotal]),
        Chapter(id: .grids, title: "Grid Galaxy", bigIdea: "Count by size, then add the layers.", symbol: "square.grid.4x3.fill", kinds: [.squaresOnBoard, .squaresOfOneSize, .rectanglesInGrid, .gridPaths, .pizzaCuts, .paintedCube]),
        Chapter(id: .logic, title: "Logic Lab", bigIdea: "Use what must be true to rule out what can't be.", symbol: "puzzlepiece.extension", kinds: [.magicSquare, .magicTotal, .kenKenThree, .kenKenFour, .logicGrid, .balanceCoins]),
    ]

    /// The Explorer path through each chapter: small numbers and hands-on puzzles.
    public static let explorerKinds: [ChapterID: [PuzzleKind]] = [
        .pairs: [.makeTens, .pairUpTen, .countByPairs, .oddOneInMiddle, .teachersTrick],
        .triangles: [.staircaseFold, .canStack, .handshakes, .howManyRows],
        .odds: [.oddEvenPattern, .oddLayers, .upAndDown, .nextSquare],
        .doubling: [.doublesFacts, .doublingSum, .hanoiPlay, .paperFold, .lilyPond],
        .digits: [.whichByThree, .divisibleByNine, .digitalRoot, .missingDigit],
        .pigeons: [.sockDrawer, .sharedMonth, .oddOrEvenTotal, .dominoBoard],
        .grids: [.squaresOnBoard, .squaresOfOneSize, .gridPaths, .pizzaCuts],
        .logic: [.magicSquare, .kenKenThree, .logicGrid, .balanceCoins],
    ]

    public func kinds(for level: Level) -> [PuzzleKind] {
        switch level {
        case .adventurer, .challenger: return kinds
        case .explorer: return Chapter.explorerKinds[id] ?? kinds
        }
    }

    public static func chapter(_ id: ChapterID) -> Chapter {
        all.first { $0.id == id }!
    }
}

/// Every puzzle type. The raw value is the stable key used in saved progress.
public enum PuzzleKind: String, CaseIterable, Codable, Hashable, Sendable {
    // Gauss's Pairs
    case pairUpTen, teachersTrick, oddOneInMiddle, bigThousand, fromHereToThere, stepSequence, missingCard
    // Triangle Town
    case staircaseFold, canStack, handshakes, homeAndAway, diagonals, howManyRows
    // Odd Squares
    case oddLayers, bigOdds, oddsInRange, upAndDown, evensToo, nextSquare
    // Doubling Peaks
    case doublingSum, riceBoard, hanoiPlay, hanoiCount, paperFold, toppings, lilyPond
    // Digit Detectives
    case divisibleByNine, remainderNine, missingDigit, whichByThree, castingOutNines, digitalRoot
    // Pigeons & Parity
    case sockDrawer, sockTriples, sharedMonth, oddNumbersSum, dominoBoard, lockers, oddOrEvenTotal
    // Grid Galaxy
    case squaresOnBoard, squaresOfOneSize, rectanglesInGrid, gridPaths, pizzaCuts, paintedCube
    // Logic Lab
    case magicSquare, magicTotal, kenKenThree, kenKenFour, logicGrid, balanceCoins
    // Explorer-only warm-ups
    case makeTens, countByPairs, oddEvenPattern, doublesFacts

    public var chapter: ChapterID {
        switch self {
        case .makeTens, .countByPairs: return .pairs
        case .oddEvenPattern: return .odds
        case .doublesFacts: return .doubling
        default: return Chapter.all.first { $0.kinds.contains(self) }!.id
        }
    }
}

/// What the player has to produce.
public enum AnswerSpec: Equatable, Sendable {
    /// Type a whole number.
    case number(Int)
    /// Pick one button. `correct` is an index into `options`.
    case choice(options: [String], correct: Int)
    /// Solve the board in the picture (Tower of Hanoi, KenKen, magic square, logic grid).
    case board
}

/// The picture or toy next to the question.
public enum PuzzleVisual: Equatable, Sendable {
    case none
    /// Numbers in a row the player can tap to pair up.
    case pairing(numbers: [Int])
    /// A staircase of dots, rows 1...n, that can fold into an n by (n+1) rectangle.
    case staircase(rows: Int)
    /// Odd numbers as L-shaped layers that build an n by n square.
    case oddLayers(count: Int)
    /// Blocks that double: 1, 2, 4, ...
    case doubling(steps: Int)
    /// People on a circle with a line for each handshake.
    case handshake(people: Int)
    /// A board with squares of one size highlighted.
    case checkerboard(size: Int)
    /// A grid of cells for rectangle and path counting.
    case grid(rows: Int, columns: Int)
    /// Big digits to look at.
    case digits(String)
    /// Socks in a drawer, one color per pile.
    case socks(colors: Int)
    /// An n by n board with some corner squares removed.
    case dominoBoard(size: Int, removed: [Int])
    case hanoi(discs: Int)
    case kenKen(KenKenPuzzle)
    case magic(MagicSquarePuzzle)
    case logicGrid(LogicGridPuzzle)
}

public struct Puzzle: Identifiable, Equatable, Sendable {
    public var id: String { "\(level.rawValue)-\(kind.rawValue)-\(seed)" }
    public var kind: PuzzleKind
    public var seed: UInt64
    public var level: Level = .challenger
    public var title: String
    public var story: String
    public var question: String
    public var answer: AnswerSpec
    public var visual: PuzzleVisual
    /// Three nudges, gentlest first. None of them gives the answer away.
    public var hints: [String]
    /// The trick, explained after the puzzle is solved.
    public var eureka: String
    /// What the long way would cost, for example "99 additions".
    public var longWay: String
    /// Seconds for the speed star.
    public var parSeconds: Int
    /// Scratch-pad steps for the elegance star.
    public var parSteps: Int

    public var chapter: ChapterID { kind.chapter }

    public init(kind: PuzzleKind, seed: UInt64, title: String, story: String, question: String, answer: AnswerSpec, visual: PuzzleVisual = .none, hints: [String], eureka: String, longWay: String, parSeconds: Int, parSteps: Int) {
        self.kind = kind
        self.seed = seed
        self.title = title
        self.story = story
        self.question = question
        self.answer = answer
        self.visual = visual
        self.hints = hints
        self.eureka = eureka
        self.longWay = longWay
        self.parSeconds = parSeconds
        self.parSteps = parSteps
    }

    /// Checks a typed or picked answer. Board puzzles are checked by their board.
    public func check(typed text: String) -> Bool {
        guard case .number(let value) = answer else { return false }
        guard let typed = AnswerParser.integer(from: text) else { return false }
        return typed == value
    }

    public func check(choice index: Int) -> Bool {
        guard case .choice(_, let correct) = answer else { return false }
        return index == correct
    }
}

public enum AnswerParser {
    /// Reads "5050", "5,050", " 5 050 " or "-3". Anything else is nil.
    public static func integer(from text: String) -> Int? {
        var cleaned = ""
        for character in text where !character.isWhitespace && character != "," && character != "_" {
            cleaned.append(character)
        }
        guard !cleaned.isEmpty, cleaned.count <= 18 else { return nil }
        return Int(cleaned)
    }
}
