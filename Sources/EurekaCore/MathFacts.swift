/// The plain formulas every puzzle is checked against. Each one is also
/// tested against a brute-force loop in the unit tests.
public enum MathFacts {
    /// 1 + 2 + ... + n
    public static func triangular(_ n: Int) -> Int {
        n * (n + 1) / 2
    }

    /// a + (a+1) + ... + b
    public static func rangeSum(_ a: Int, _ b: Int) -> Int {
        guard b >= a else { return 0 }
        return (a + b) * (b - a + 1) / 2
    }

    /// first, first+step, ... (terms numbers)
    public static func arithmeticSum(first: Int, step: Int, terms: Int) -> Int {
        let last = first + step * (terms - 1)
        return terms * (first + last) / 2
    }

    /// 1 + 3 + 5 + ... (n odd numbers)
    public static func oddSum(count n: Int) -> Int {
        n * n
    }

    /// 1^2 + 2^2 + ... + n^2, the number of squares on an n by n board.
    public static func squaresOnBoard(_ n: Int) -> Int {
        n * (n + 1) * (2 * n + 1) / 6
    }

    /// Rectangles of any size in a grid with `rows` by `columns` cells.
    public static func rectangles(rows: Int, columns: Int) -> Int {
        triangular(rows) * triangular(columns)
    }

    public static func power(_ base: Int, _ exponent: Int) -> Int {
        var result = 1
        for _ in 0..<max(0, exponent) { result *= base }
        return result
    }

    /// n choose k, exact for the small numbers puzzles use.
    public static func choose(_ n: Int, _ k: Int) -> Int {
        guard k >= 0, k <= n else { return 0 }
        let k = min(k, n - k)
        var result = 1
        for i in 0..<k {
            result = result * (n - i) / (i + 1)
        }
        return result
    }

    public static func digits(_ n: Int) -> [Int] {
        String(abs(n)).compactMap { $0.wholeNumberValue }
    }

    public static func digitSum(_ n: Int) -> Int {
        digits(n).reduce(0, +)
    }

    /// Keep adding the digits until one digit is left (0 stays 0).
    public static func digitalRoot(_ n: Int) -> Int {
        let n = abs(n)
        if n == 0 { return 0 }
        return 1 + (n - 1) % 9
    }

    /// The greatest number of pieces from `cuts` straight cuts across a pizza.
    public static func pizzaPieces(cuts: Int) -> Int {
        triangular(cuts) + 1
    }

    /// Diagonals in a polygon with `sides` corners.
    public static func diagonals(sides: Int) -> Int {
        sides * (sides - 3) / 2
    }

    /// Fewest weighings on a balance to find the one heavier coin among `coins`.
    public static func weighings(coins: Int) -> Int {
        var count = 0
        var reach = 1
        while reach < coins {
            reach *= 3
            count += 1
        }
        return count
    }

    /// Lockers left open after the 1..n toggling game: the perfect squares.
    public static func openLockers(_ n: Int) -> Int {
        var k = 0
        while (k + 1) * (k + 1) <= n { k += 1 }
        return k
    }

    public static func isPerfectSquare(_ n: Int) -> Bool {
        guard n >= 0 else { return false }
        var k = 0
        while k * k < n { k += 1 }
        return k * k == n
    }
}
