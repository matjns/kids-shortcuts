public enum LogicClue: Equatable, Sendable {
    case personPet(person: Int, pet: Int, yes: Bool)
    case personColor(person: Int, color: Int, yes: Bool)
    case petColor(pet: Int, color: Int, yes: Bool)
}

public enum GridMark: Int, Equatable, Sendable, Codable {
    case blank, no, yes

    public var next: GridMark {
        switch self {
        case .blank: return .no
        case .no: return .yes
        case .yes: return .blank
        }
    }
}

/// Three characters, three pets, three favorite colors. Clues pin down who has what.
public struct LogicGridPuzzle: Equatable, Sendable {
    public var people: [String]
    public var pets: [String]
    public var colors: [String]
    /// petOf[person] is an index into pets.
    public var petOf: [Int]
    /// colorOf[person] is an index into colors.
    public var colorOf: [Int]
    public var clues: [LogicClue]

    public init(people: [String], pets: [String], colors: [String], petOf: [Int], colorOf: [Int], clues: [LogicClue]) {
        self.people = people
        self.pets = pets
        self.colors = colors
        self.petOf = petOf
        self.colorOf = colorOf
        self.clues = clues
    }

    public static let characterPool = ["Robot", "Dragon", "Wizard", "Pirate", "Alien", "Knight"]
    public static let petPool = ["cat", "dog", "fish", "parrot", "turtle", "hamster"]
    public static let colorPool = ["red", "blue", "green", "yellow", "purple", "orange"]

    public func text(for clue: LogicClue) -> String {
        switch clue {
        case let .personPet(person, pet, yes):
            return yes ? "The \(people[person]) has the \(pets[pet])." : "The \(people[person]) does not have the \(pets[pet])."
        case let .personColor(person, color, yes):
            return yes ? "The \(people[person])'s favorite color is \(colors[color])." : "The \(people[person])'s favorite color is not \(colors[color])."
        case let .petColor(pet, color, yes):
            return yes ? "Whoever has the \(pets[pet]) loves \(colors[color])." : "Whoever has the \(pets[pet]) does not love \(colors[color])."
        }
    }

    public var clueTexts: [String] { clues.map(text(for:)) }

    static func holds(_ clue: LogicClue, petOf: [Int], colorOf: [Int]) -> Bool {
        switch clue {
        case let .personPet(person, pet, yes):
            return (petOf[person] == pet) == yes
        case let .personColor(person, color, yes):
            return (colorOf[person] == color) == yes
        case let .petColor(pet, color, yes):
            guard let owner = petOf.firstIndex(of: pet) else { return false }
            return (colorOf[owner] == color) == yes
        }
    }

    static let permutations: [[Int]] = [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]]

    /// How many of the 36 possible worlds fit every clue.
    public static func countSolutions(clues: [LogicClue]) -> Int {
        var count = 0
        for pets in permutations {
            for colors in permutations where clues.allSatisfy({ holds($0, petOf: pets, colorOf: colors) }) {
                count += 1
            }
        }
        return count
    }

    /// Solved when the check marks match the one answer in both grids.
    /// petMarks and colorMarks are 3 by 3, indexed person * 3 + item.
    public func isSolved(petMarks: [GridMark], colorMarks: [GridMark]) -> Bool {
        guard petMarks.count == 9, colorMarks.count == 9 else { return false }
        for person in 0..<3 {
            for item in 0..<3 {
                let petYes = petMarks[person * 3 + item] == .yes
                let colorYes = colorMarks[person * 3 + item] == .yes
                if petYes != (petOf[person] == item) { return false }
                if colorYes != (colorOf[person] == item) { return false }
            }
        }
        return true
    }

    public static func generate(using rng: inout SplitMix64) -> LogicGridPuzzle {
        let people = Array(rng.shuffled(characterPool).prefix(3))
        let pets = Array(rng.shuffled(petPool).prefix(3))
        let colors = Array(rng.shuffled(colorPool).prefix(3))
        let petOf = rng.pick(permutations)
        let colorOf = rng.pick(permutations)

        // Every true clue, with at most one that hands over a pet directly.
        var pool: [LogicClue] = []
        for person in 0..<3 {
            for item in 0..<3 {
                if petOf[person] != item { pool.append(.personPet(person: person, pet: item, yes: false)) }
                if colorOf[person] != item { pool.append(.personColor(person: person, color: item, yes: false)) }
            }
        }
        for pet in 0..<3 {
            let owner = petOf.firstIndex(of: pet)!
            for color in 0..<3 {
                pool.append(.petColor(pet: pet, color: color, yes: colorOf[owner] == color))
            }
        }
        let gift = rng.int(0...2)
        pool.append(.personPet(person: gift, pet: petOf[gift], yes: true))
        pool = rng.shuffled(pool)

        var clues: [LogicClue] = []
        for clue in pool {
            clues.append(clue)
            if countSolutions(clues: clues) == 1 { break }
        }
        // Drop any clue the others already cover, so every clue matters.
        var index = 0
        while index < clues.count {
            var trial = clues
            trial.remove(at: index)
            if countSolutions(clues: trial) == 1 {
                clues = trial
            } else {
                index += 1
            }
        }
        return LogicGridPuzzle(people: people, pets: pets, colors: colors, petOf: petOf, colorOf: colorOf, clues: clues)
    }
}
