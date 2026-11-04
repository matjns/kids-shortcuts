import XCTest
@testable import EurekaCore

final class BoardTests: XCTestCase {
    func testKenKenBoardsHaveExactlyOneSolution() {
        for size in [3, 4] {
            for seed in UInt64(1)...30 {
                var rng = SplitMix64(seed: seed)
                let board = KenKenPuzzle.generate(size: size, using: &rng)
                XCTAssertEqual(board.countSolutions(limit: 3), 1, "size \(size) seed \(seed)")
                XCTAssertTrue(board.isSolved(board.solution.map { Optional($0) }))
                // Every cell is in exactly one cage.
                let cells = board.cages.flatMap(\.cells).sorted()
                XCTAssertEqual(cells, Array(0..<(size * size)))
                for cage in board.cages where cage.operation == .subtract || cage.operation == .divide {
                    XCTAssertEqual(cage.cells.count, 2)
                }
            }
        }
    }

    func testKenKenRejectsWrongAndIncompleteGrids() {
        var rng = SplitMix64(seed: 99)
        let board = KenKenPuzzle.generate(size: 4, using: &rng)
        var entries = board.solution.map { Optional($0) }
        entries[0] = nil
        XCTAssertFalse(board.isSolved(entries))
        entries[0] = board.solution[0] % 4 + 1
        XCTAssertFalse(board.isSolved(entries))
    }

    func testCageMath() {
        XCTAssertTrue(KenKenCage(cells: [0, 1], operation: .divide, target: 2).isSatisfied(by: [2, 4]))
        XCTAssertFalse(KenKenCage(cells: [0, 1], operation: .divide, target: 2).isSatisfied(by: [3, 4]))
        XCTAssertTrue(KenKenCage(cells: [0, 1], operation: .subtract, target: 3).isSatisfied(by: [1, 4]))
        XCTAssertTrue(KenKenCage(cells: [0, 1, 2], operation: .multiply, target: 24).isSatisfied(by: [2, 3, 4]))
        XCTAssertEqual(KenKenCage(cells: [5, 1], operation: .add, target: 7).labelCell, 1)
    }

    func testMagicSquares() {
        let bases = MagicSquarePuzzle.allBaseSquares()
        XCTAssertEqual(Set(bases).count, 8)
        // Brute force: exactly 8 magic squares use 1...9.
        var found = 0
        permute(Array(1...9)) { if MagicSquarePuzzle.isMagic($0) { found += 1 } }
        XCTAssertEqual(found, 8)
        for seed in UInt64(1)...40 {
            var rng = SplitMix64(seed: seed)
            let puzzle = MagicSquarePuzzle.generate(using: &rng)
            XCTAssertTrue(puzzle.isSolved(puzzle.solution.map { Optional($0) }))
            XCTAssertEqual(puzzle.magicTotal, puzzle.solution[0] + puzzle.solution[1] + puzzle.solution[2])
            let matching = bases.map { $0.map { $0 + puzzle.lowest - 1 } }.filter { square in
                (0..<9).allSatisfy { !puzzle.givens[$0] || square[$0] == puzzle.solution[$0] }
            }
            XCTAssertEqual(matching.count, 1, "givens pin down one square")
        }
        let explorer = PuzzleGenerator.make(.magicSquare, level: .explorer, seed: 3)
        guard case .magic(let easy) = explorer.visual else { return XCTFail("magic") }
        XCTAssertEqual(easy.lowest, 1)
        XCTAssertEqual(easy.magicTotal, 15)
        XCTAssertTrue(easy.givens[4])
        XCTAssertTrue(easy.isSolved(easy.solution.map { Optional($0) }))
    }

    func testLogicGridsAreUniqueAndConsistent() {
        for seed in UInt64(1)...60 {
            var rng = SplitMix64(seed: seed)
            let grid = LogicGridPuzzle.generate(using: &rng)
            XCTAssertEqual(LogicGridPuzzle.countSolutions(clues: grid.clues), 1)
            XCTAssertTrue(grid.clues.allSatisfy { LogicGridPuzzle.holds($0, petOf: grid.petOf, colorOf: grid.colorOf) })
            XCTAssertLessThanOrEqual(grid.clues.count, 9)
            // Every clue matters.
            for index in grid.clues.indices {
                var fewer = grid.clues
                fewer.remove(at: index)
                XCTAssertGreaterThan(LogicGridPuzzle.countSolutions(clues: fewer), 1)
            }
            var pets = [GridMark](repeating: .no, count: 9)
            var colors = [GridMark](repeating: .blank, count: 9)
            for person in 0..<3 {
                pets[person * 3 + grid.petOf[person]] = .yes
                colors[person * 3 + grid.colorOf[person]] = .yes
            }
            XCTAssertTrue(grid.isSolved(petMarks: pets, colorMarks: colors))
            colors[grid.colorOf[0]] = .blank
            XCTAssertFalse(grid.isSolved(petMarks: pets, colorMarks: colors))
            XCTAssertEqual(grid.clueTexts.count, grid.clues.count)
        }
        XCTAssertEqual(GridMark.blank.next, .no)
        XCTAssertEqual(GridMark.no.next, .yes)
        XCTAssertEqual(GridMark.yes.next, .blank)
    }

    func testHanoi() {
        for discs in 1...8 {
            var game = HanoiGame(discs: discs)
            let moves = HanoiGame.solution(discs: discs)
            XCTAssertEqual(moves.count, game.minimumMoves)
            for (from, to) in moves { XCTAssertTrue(game.move(from: from, to: to)) }
            XCTAssertTrue(game.isSolved)
            XCTAssertEqual(game.moves, MathFacts.power(2, discs) - 1)
        }
        var game = HanoiGame(discs: 3)
        XCTAssertTrue(game.move(from: 0, to: 1))
        XCTAssertFalse(game.move(from: 0, to: 1), "big disc can't go on small")
        XCTAssertFalse(game.move(from: 2, to: 0), "empty peg")
        XCTAssertFalse(game.move(from: 1, to: 1))
        XCTAssertEqual(game.moves, 1)
    }

    func testPairingBoard() {
        var board = PairingBoard(numbers: Array(1...10))
        board.tap(0)
        XCTAssertEqual(board.selected, 0)
        board.tap(9)
        XCTAssertEqual(board.pairSums, [11])
        XCTAssertFalse(board.everyPairMatches)
        board.tap(1); board.tap(8)
        XCTAssertTrue(board.everyPairMatches)
        board.tap(2); board.tap(3)
        XCTAssertFalse(board.everyPairMatches)
        board.tap(3) // undo that pair
        XCTAssertEqual(board.pairs.count, 2)
        board.tap(4); board.tap(4)
        XCTAssertNil(board.selected)
        board.autoPairEnds()
        XCTAssertTrue(board.isComplete)
        XCTAssertTrue(board.everyPairMatches)
        var odd = PairingBoard(numbers: Array(1...9))
        odd.autoPairEnds()
        XCTAssertEqual(odd.unpaired, [4])
        XCTAssertTrue(odd.isComplete)
    }

    func testScratchpadCountsSteps() {
        var pad = Scratchpad()
        // The trick: 50 × 101
        pad.digit(5); pad.digit(0); pad.operation(.multiply); pad.digit(1); pad.digit(0); pad.digit(1); pad.equals()
        XCTAssertEqual(pad.currentValue, 5050)
        XCTAssertEqual(pad.steps, 1)
        // The long way: 1 + 2 + ... + 100 is 99 calculations.
        var long = Scratchpad()
        long.digit(1)
        for n in 2...100 {
            long.operation(.add)
            for character in String(n) { long.digit(character.wholeNumberValue!) }
        }
        long.equals()
        XCTAssertEqual(long.currentValue, 5050)
        XCTAssertEqual(long.steps, 99)
        // Pressing = again, or two operations in a row, doesn't count.
        long.equals()
        long.operation(.add); long.operation(.subtract)
        XCTAssertEqual(long.steps, 99)

        var division = Scratchpad()
        division.digit(7); division.operation(.divide); division.digit(2); division.equals()
        XCTAssertEqual(division.error, "Not a whole number")
        division.digit(8); division.operation(.divide); division.digit(0); division.equals()
        XCTAssertNotNil(division.error)
        division.clear()
        division.digit(9); division.backspace()
        XCTAssertEqual(division.display, "0")
        division.digit(1); division.digit(0); division.operation(.subtract); division.digit(3); division.operation(.multiply); division.digit(2); division.equals()
        XCTAssertEqual(division.currentValue, 14)

        var huge = Scratchpad()
        for _ in 0..<15 { huge.digit(9) }
        huge.operation(.multiply)
        for _ in 0..<15 { huge.digit(9) }
        huge.equals()
        XCTAssertEqual(huge.error, "Too big!")
    }

    private func permute(_ values: [Int], _ visit: ([Int]) -> Void) {
        var items = values
        func go(_ k: Int) {
            if k == items.count { visit(items); return }
            for i in k..<items.count {
                items.swapAt(k, i)
                go(k + 1)
                items.swapAt(k, i)
            }
        }
        go(0)
    }
}
