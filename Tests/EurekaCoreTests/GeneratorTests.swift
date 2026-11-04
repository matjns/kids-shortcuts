import XCTest
@testable import EurekaCore

final class GeneratorTests: XCTestCase {
    let seeds: [UInt64] = Array(1...40)

    func allPuzzles(_ level: Level) -> [Puzzle] {
        Chapter.all.flatMap { chapter in
            chapter.kinds(for: level).flatMap { kind in seeds.map { PuzzleGenerator.make(kind, level: level, seed: $0) } }
        }
    }

    func testEightChaptersWithFiveToEightPuzzlesEach() {
        XCTAssertEqual(Chapter.all.count, 8)
        for chapter in Chapter.all {
            XCTAssertTrue((5...8).contains(chapter.kinds.count), chapter.title)
            XCTAssertTrue((4...8).contains(chapter.kinds(for: .explorer).count), chapter.title)
            for kind in chapter.kinds(for: .explorer) {
                XCTAssertEqual(kind.chapter, chapter.id, kind.rawValue)
            }
        }
        // Every kind is reachable from some chapter at some level.
        let reachable = Set(Chapter.all.flatMap { $0.kinds + $0.kinds(for: .explorer) })
        XCTAssertEqual(reachable, Set(PuzzleKind.allCases))
    }

    func testEveryPuzzleIsWellFormed() {
        for level in Level.allCases {
            for puzzle in allPuzzles(level) {
                let name = "\(level) \(puzzle.kind) \(puzzle.seed)"
                XCTAssertFalse(puzzle.title.isEmpty, name)
                XCTAssertFalse(puzzle.question.isEmpty, name)
                XCTAssertEqual(puzzle.hints.count, 3, name)
                XCTAssertFalse(puzzle.eureka.isEmpty, name)
                XCTAssertGreaterThan(puzzle.parSeconds, 0, name)
                XCTAssertEqual(puzzle.level, level, name)
                switch puzzle.answer {
                case .number(let value):
                    XCTAssertFalse(level.usesChoices, "Explorer answers are buttons: \(name)")
                    XCTAssertGreaterThanOrEqual(value, 0, name)
                    XCTAssertTrue(puzzle.check(typed: Format.number(value)), name)
                    XCTAssertTrue(puzzle.check(typed: String(value)), name)
                    XCTAssertFalse(puzzle.check(typed: String(value + 1)), name)
                    // The first nudge never hands over the answer.
                    XCTAssertFalse(value >= 13 && NumberTokens.contains(puzzle.hints[0], value), "first hint gives it away: \(name): \(puzzle.hints[0])")
                case let .choice(options, correct):
                    XCTAssertTrue(options.indices.contains(correct), name)
                    XCTAssertEqual(Set(options).count, options.count, "duplicate options: \(name) \(options)")
                    XCTAssertTrue(puzzle.check(choice: correct), name)
                    XCTAssertGreaterThanOrEqual(options.count, 2, name)
                case .board:
                    break
                }
            }
        }
    }

    func testSameSeedSamePuzzleNewSeedNewNumbers() {
        for kind in PuzzleKind.allCases {
            XCTAssertEqual(PuzzleGenerator.make(kind, level: .challenger, seed: 7), PuzzleGenerator.make(kind, level: .challenger, seed: 7))
        }
        let distinct = Set(seeds.map { PuzzleGenerator.make(.fromHereToThere, level: .challenger, seed: $0).question })
        XCTAssertGreaterThan(distinct.count, 20)
    }

    func testExplorerUsesSmallNumbers() {
        for seed in seeds {
            let pairs = PuzzleGenerator.make(.pairUpTen, level: .explorer, seed: seed)
            guard case .pairing(let numbers) = pairs.visual else { return XCTFail("pairing visual") }
            XCTAssertLessThanOrEqual(numbers.count, 10)
            let teacher = PuzzleGenerator.make(.teachersTrick, level: .explorer, seed: seed)
            XCTAssertTrue(teacher.question.contains("20"))
            guard case .hanoi(let discs) = PuzzleGenerator.make(.hanoiPlay, level: .explorer, seed: seed).visual else { return XCTFail("hanoi") }
            XCTAssertEqual(discs, 3)
        }
    }

    // MARK: Answers recomputed from the puzzle itself

    func number(_ puzzle: Puzzle) -> Int {
        guard case .number(let value) = puzzle.answer else { XCTFail("not a number answer"); return -1 }
        return value
    }

    func chosen(_ puzzle: Puzzle) -> String {
        guard case let .choice(options, correct) = puzzle.answer else { XCTFail("not a choice"); return "" }
        return options[correct]
    }

    func testPairingAnswersAreTheSumOfTheNumbersShown() {
        for seed in seeds {
            for kind in [PuzzleKind.pairUpTen, .oddOneInMiddle, .makeTens] {
                let puzzle = PuzzleGenerator.make(kind, level: .adventurer, seed: seed)
                guard case .pairing(let numbers) = puzzle.visual else { return XCTFail("\(kind)") }
                XCTAssertEqual(number(puzzle), numbers.reduce(0, +), "\(kind)")
            }
            let socks = PuzzleGenerator.make(.countByPairs, level: .adventurer, seed: seed)
            guard case .pairing(let row) = socks.visual else { return XCTFail("socks") }
            XCTAssertEqual(number(socks), row.count)
            let explorer = PuzzleGenerator.make(.makeTens, level: .explorer, seed: seed)
            guard case .pairing(let shown) = explorer.visual else { return XCTFail("tens") }
            XCTAssertEqual(chosen(explorer), Format.number(shown.reduce(0, +)))
        }
    }

    func testSeriesAnswersMatchBruteForce() {
        for seed in seeds {
            let steps = PuzzleGenerator.make(.stepSequence, level: .challenger, seed: seed)
            let terms = NumberTokens.all(steps.question)
            let first = terms[0], step = terms[1] - terms[0], last = terms.last!
            XCTAssertEqual(number(steps), stride(from: first, through: last, by: step).reduce(0, +))

            let range = PuzzleGenerator.make(.fromHereToThere, level: .challenger, seed: seed)
            let ends = NumberTokens.all(range.question)
            XCTAssertEqual(number(range), (ends[0]...ends.last!).reduce(0, +))

            let odds = PuzzleGenerator.make(.oddsInRange, level: .challenger, seed: seed)
            let o = NumberTokens.all(odds.question)
            XCTAssertEqual(number(odds), stride(from: o[0], through: o.last!, by: 2).reduce(0, +))

            let big = PuzzleGenerator.make(.bigOdds, level: .challenger, seed: seed)
            XCTAssertEqual(number(big), stride(from: 1, through: NumberTokens.all(big.question).last!, by: 2).reduce(0, +))

            let evens = PuzzleGenerator.make(.evensToo, level: .challenger, seed: seed)
            XCTAssertEqual(number(evens), stride(from: 2, through: NumberTokens.all(evens.question).last!, by: 2).reduce(0, +))

            let doubling = PuzzleGenerator.make(.doublingSum, level: .challenger, seed: seed)
            var total = 0, value = 1
            let top = NumberTokens.all(doubling.question).last!
            while value <= top { total += value; value *= 2 }
            XCTAssertEqual(number(doubling), total)

            let missing = PuzzleGenerator.make(.missingCard, level: .challenger, seed: seed)
            let facts = NumberTokens.all(missing.story)
            XCTAssertEqual(number(missing), (1...facts[1]).reduce(0, +) - facts[2])
        }
    }

    func testCountingAnswersMatchBruteForce() {
        for seed in seeds {
            let hands = PuzzleGenerator.make(.handshakes, level: .challenger, seed: seed)
            let people = NumberTokens.all(hands.story)[0]
            var shakes = 0
            for a in 0..<people { for b in 0..<people where a < b { _ = b; shakes += 1 } }
            XCTAssertEqual(number(hands), shakes)

            let lockers = PuzzleGenerator.make(.lockers, level: .challenger, seed: seed)
            let n = NumberTokens.all(lockers.story)[0]
            XCTAssertEqual(number(lockers), (1...n).filter { MathFacts.isPerfectSquare($0) }.count)

            let paths = PuzzleGenerator.make(.gridPaths, level: .challenger, seed: seed)
            guard case let .grid(rows, columns) = paths.visual else { return XCTFail("grid") }
            XCTAssertEqual(number(paths), latticePaths(right: columns, up: rows))

            let board = PuzzleGenerator.make(.squaresOnBoard, level: .challenger, seed: seed)
            guard case .checkerboard(let size) = board.visual else { return XCTFail("board") }
            var squares = 0
            for k in 1...size { squares += (size - k + 1) * (size - k + 1) }
            XCTAssertEqual(number(board), squares)

            let cube = PuzzleGenerator.make(.paintedCube, level: .challenger, seed: seed)
            let side = NumberTokens.all(cube.story)[0]
            let faces = cube.question.contains("no paint") ? 0 : (cube.question.contains("one face") ? 1 : 2)
            XCTAssertEqual(number(cube), paintedCubes(side: side, faces: faces))

            let tower = PuzzleGenerator.make(.howManyRows, level: .challenger, seed: seed)
            let total = NumberTokens.all(tower.story).last!
            XCTAssertEqual(MathFacts.triangular(number(tower)), total)

            let coins = PuzzleGenerator.make(.balanceCoins, level: .challenger, seed: seed)
            let count = NumberTokens.all(coins.story)[0]
            let w = number(coins)
            XCTAssertGreaterThanOrEqual(MathFacts.power(3, w), count)
            XCTAssertLessThan(MathFacts.power(3, w - 1), count)
        }
    }

    func testDigitPuzzles() {
        for seed in seeds {
            for level in Level.allCases {
                let nine = PuzzleGenerator.make(.divisibleByNine, level: level, seed: seed)
                guard case .digits(let shown) = nine.visual, let value = Int(shown) else { return XCTFail("digits") }
                XCTAssertEqual(chosen(nine), value % 9 == 0 ? "Yes" : "No")

                let missing = PuzzleGenerator.make(.missingDigit, level: level, seed: seed)
                guard case .digits(let blanked) = missing.visual else { return XCTFail("blank") }
                let digit = level.usesChoices ? Int(chosen(missing))! : number(missing)
                let filled = Int(blanked.replacingOccurrences(of: "_", with: String(digit)))!
                XCTAssertEqual(filled % 9, 0, blanked)
                XCTAssertEqual((0...9).filter { Int(blanked.replacingOccurrences(of: "_", with: String($0)))! % 9 == 0 }.count, 1, "one digit fits: \(blanked)")

                let three = PuzzleGenerator.make(.whichByThree, level: level, seed: seed)
                guard case let .choice(options, correct) = three.answer else { return XCTFail("choice") }
                let values = options.map { Int($0.replacingOccurrences(of: ",", with: ""))! }
                XCTAssertEqual(values.filter { $0 % 3 == 0 }.count, 1)
                XCTAssertEqual(values[correct] % 3, 0)

                let casting = PuzzleGenerator.make(.castingOutNines, level: level, seed: seed)
                let factors = NumberTokens.all(casting.story)
                let product = factors[0] * factors[1]
                guard case let .choice(answers, right) = casting.answer else { return XCTFail("casting") }
                let numbers = answers.map { Int($0.replacingOccurrences(of: ",", with: ""))! }
                XCTAssertEqual(numbers[right], product)
                XCTAssertEqual(numbers.filter { $0 % 9 == product % 9 }.count, 1, "only the true product passes the nines check")
                XCTAssertEqual(Set(numbers.map { $0 % 10 }).count, 1, "same last digit")
            }
        }
    }

    func testParityPuzzles() {
        for seed in seeds {
            let odd = PuzzleGenerator.make(.oddNumbersSum, level: .challenger, seed: seed)
            let facts = NumberTokens.all(odd.question)
            let (k, total) = (facts[0], facts[1])
            XCTAssertEqual(chosen(odd), canMake(total, withOdd: k) ? "Yes" : "No", odd.question)

            let parity = PuzzleGenerator.make(.oddOrEvenTotal, level: .challenger, seed: seed)
            let top = NumberTokens.all(parity.question).last!
            XCTAssertEqual(chosen(parity), (1...top).reduce(0, +) % 2 == 0 ? "Even" : "Odd")

            let domino = PuzzleGenerator.make(.dominoBoard, level: .challenger, seed: seed)
            guard case let .dominoBoard(size, removed) = domino.visual else { return XCTFail("domino") }
            var dark = 0, light = 0
            for cell in 0..<(size * size) where !removed.contains(cell) {
                if (cell / size + cell % size) % 2 == 0 { dark += 1 } else { light += 1 }
            }
            // Gomory: equal colors on an even board means it can be tiled.
            XCTAssertEqual(chosen(domino), dark == light ? "Yes" : "No")
        }
    }

    // MARK: Helpers

    private func canMake(_ total: Int, withOdd count: Int) -> Bool {
        // Smallest is 1+1+…; every bump of 2 keeps parity.
        total >= count && (total - count) % 2 == 0
    }

    private func latticePaths(right: Int, up: Int) -> Int {
        var grid = [[Int]](repeating: [Int](repeating: 1, count: right + 1), count: up + 1)
        for r in 1...up { for c in 1...right { grid[r][c] = grid[r - 1][c] + grid[r][c - 1] } }
        return grid[up][right]
    }

    private func paintedCubes(side: Int, faces: Int) -> Int {
        var count = 0
        for x in 0..<side { for y in 0..<side { for z in 0..<side {
            let painted = [x, y, z].reduce(0) { $0 + ($1 == 0 || $1 == side - 1 ? 1 : 0) }
            if painted == faces { count += 1 }
        } } }
        return count
    }
}

/// Pulls whole numbers (with commas) out of text, for tests.
enum NumberTokens {
    static func all(_ text: String) -> [Int] {
        var result: [Int] = []
        var current = ""
        func flush() {
            if let value = Int(current) { result.append(value) }
            current = ""
        }
        for character in text {
            if character.isNumber && character.isASCII {
                current.append(character)
            } else if character == "," && !current.isEmpty {
                continue
            } else {
                flush()
            }
        }
        flush()
        return result
    }

    static func contains(_ text: String, _ value: Int) -> Bool {
        all(text).contains(value)
    }
}
