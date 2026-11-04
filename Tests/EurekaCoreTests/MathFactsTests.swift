import XCTest
@testable import EurekaCore

final class MathFactsTests: XCTestCase {
    func testFormulasMatchBruteForce() {
        for n in 0...200 {
            XCTAssertEqual(MathFacts.triangular(n), (0...n).reduce(0, +))
            XCTAssertEqual(MathFacts.oddSum(count: n), (0..<n).reduce(0) { $0 + 2 * $1 + 1 })
            XCTAssertEqual(MathFacts.squaresOnBoard(n), (0...n).reduce(0) { $0 + $1 * $1 })
            XCTAssertEqual(MathFacts.openLockers(n), lockerSimulation(n))
            XCTAssertEqual(MathFacts.digitalRoot(n * 7919), repeatedDigitSum(n * 7919))
        }
        XCTAssertEqual(MathFacts.triangular(100), 5050)
        XCTAssertEqual(MathFacts.rangeSum(21, 60), (21...60).reduce(0, +))
        XCTAssertEqual(MathFacts.arithmeticSum(first: 3, step: 4, terms: 20), stride(from: 3, through: 79, by: 4).reduce(0, +))
        XCTAssertEqual(MathFacts.squaresOnBoard(8), 204)
        XCTAssertEqual(MathFacts.rectangles(rows: 8, columns: 8), 1296)
        XCTAssertEqual(MathFacts.choose(10, 3), 120)
        XCTAssertEqual(MathFacts.pizzaPieces(cuts: 3), 7)
        XCTAssertEqual(MathFacts.diagonals(sides: 6), 9)
        XCTAssertEqual(MathFacts.weighings(coins: 12), 3)
        XCTAssertEqual(MathFacts.weighings(coins: 27), 3)
        XCTAssertEqual(MathFacts.weighings(coins: 28), 4)
        XCTAssertEqual(MathFacts.weighings(coins: 3), 1)
        XCTAssertEqual(MathFacts.digitSum(987_654_321), 45)
    }

    func testRectanglesMatchCounting() {
        for rows in 1...5 {
            for columns in 1...5 {
                var count = 0
                for top in 0..<rows { for bottom in top..<rows { for left in 0..<columns { for right in left..<columns { _ = (bottom, right); count += 1 } } } }
                XCTAssertEqual(MathFacts.rectangles(rows: rows, columns: columns), count)
            }
        }
    }

    func testFormat() {
        XCTAssertEqual(Format.number(5050), "5,050")
        XCTAssertEqual(Format.number(999), "999")
        XCTAssertEqual(Format.number(1_000_000), "1,000,000")
        XCTAssertEqual(Format.number(-1234), "-1,234")
        XCTAssertEqual(Format.series(first: 3, step: 4, last: 79), "3 + 7 + 11 + … + 79")
        XCTAssertEqual(Format.stableHash("abc"), Format.stableHash("abc"))
    }

    func testAnswerParser() {
        XCTAssertEqual(AnswerParser.integer(from: "5,050"), 5050)
        XCTAssertEqual(AnswerParser.integer(from: " 5 050 "), 5050)
        XCTAssertEqual(AnswerParser.integer(from: "-3"), -3)
        XCTAssertNil(AnswerParser.integer(from: "five"))
        XCTAssertNil(AnswerParser.integer(from: ""))
        XCTAssertNil(AnswerParser.integer(from: "12.5"))
    }

    private func lockerSimulation(_ n: Int) -> Int {
        guard n > 0 else { return 0 }
        var open = [Bool](repeating: false, count: n + 1)
        for kid in 1...n { for locker in stride(from: kid, through: n, by: kid) { open[locker].toggle() } }
        return open.filter { $0 }.count
    }

    private func repeatedDigitSum(_ n: Int) -> Int {
        var value = n
        while value > 9 { value = String(value).compactMap { $0.wholeNumberValue }.reduce(0, +) }
        return value
    }
}
