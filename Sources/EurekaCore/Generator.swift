/// Builds a puzzle of a given kind, level and seed. The same three inputs
/// always give the same puzzle; a new seed gives new numbers.
public enum PuzzleGenerator {
    public static func make(_ kind: PuzzleKind, level: Level, seed: UInt64) -> Puzzle {
        var rng = SplitMix64(seed: seed ^ Format.stableHash(kind.rawValue + "/" + level.rawValue))
        var builder = Builder(kind: kind, level: level, seed: seed, rng: rng)
        var puzzle = builder.build()
        rng = builder.rng
        if level.usesChoices, case .number(let answer) = puzzle.answer {
            puzzle.answer = choices(for: answer, traps: builder.traps, using: &rng)
        }
        puzzle.level = level
        return puzzle
    }

    /// Four buttons: the answer and three believable wrong answers.
    /// Traps are the mistakes a real kid makes (forgetting to halve, off by one).
    static func choices(for answer: Int, traps: [Int], using rng: inout SplitMix64) -> AnswerSpec {
        var wrong: [Int] = []
        let spread = max(2, answer / 10)
        let fallbacks = [answer + 1, answer - 1, answer + spread, answer - spread, answer + 2 * spread, answer * 2, answer + 10, answer + 3]
        for candidate in traps + rng.shuffled(fallbacks) where candidate >= 0 && candidate != answer && !wrong.contains(candidate) {
            wrong.append(candidate)
            if wrong.count == 3 { break }
        }
        var step = 4
        while wrong.count < 3 {
            if !wrong.contains(answer + step) { wrong.append(answer + step) }
            step += 1
        }
        let options = rng.shuffled([answer] + wrong)
        return .choice(options: options.map(Format.number), correct: options.firstIndex(of: answer)!)
    }
}

private let yesNo = ["Yes", "No"]

struct Builder {
    let kind: PuzzleKind
    let level: Level
    let seed: UInt64
    var rng: SplitMix64
    var traps: [Int] = []

    init(kind: PuzzleKind, level: Level, seed: UInt64, rng: SplitMix64) {
        self.kind = kind
        self.level = level
        self.seed = seed
        self.rng = rng
    }

    /// Pick a number from the range for this level.
    mutating func n(_ explorer: ClosedRange<Int>, _ adventurer: ClosedRange<Int>, _ challenger: ClosedRange<Int>) -> Int {
        switch level {
        case .explorer: return rng.int(explorer)
        case .adventurer: return rng.int(adventurer)
        case .challenger: return rng.int(challenger)
        }
    }

    mutating func p<T>(_ explorer: [T], _ adventurer: [T], _ challenger: [T]) -> T {
        switch level {
        case .explorer: return rng.pick(explorer)
        case .adventurer: return rng.pick(adventurer)
        case .challenger: return rng.pick(challenger)
        }
    }

    var easy: Bool { level == .explorer }

    func puzzle(_ title: String, _ story: String, _ question: String, _ answer: AnswerSpec, visual: PuzzleVisual = .none, hints: [String], eureka: String, longWay: String, seconds: Int, steps: Int) -> Puzzle {
        Puzzle(kind: kind, seed: seed, title: title, story: story, question: question, answer: answer, visual: visual, hints: hints, eureka: eureka, longWay: longWay, parSeconds: easy ? seconds * 2 : seconds, parSteps: steps)
    }

    func f(_ value: Int) -> String { Format.number(value) }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    mutating func build() -> Puzzle {
        switch kind {
        // MARK: Gauss's Pairs
        case .makeTens:
            let total = rng.pick([10, 10, 20])
            let count = total == 10 ? 4 : 4
            var pool: [Int] = []
            for _ in 0..<count {
                let a = rng.int(1...(total - 1))
                pool.append(a)
                pool.append(total - a)
            }
            let numbers = rng.shuffled(pool)
            let sum = numbers.reduce(0, +)
            traps = [sum - 1, sum + total, sum - total]
            return puzzle("Make \(total)s", "Tap two numbers that make \(total). Pair them all up!", "What do all the numbers add up to?", .number(sum), visual: .pairing(numbers: numbers), hints: ["Find a buddy for each number so the two make \(total).", "How many buddy pairs are there?", "Each pair is \(total). Count the pairs, then count by \(total)s."], eureka: "You made \(count) pairs of \(total). Counting \(count) \(total)s is \(f(sum)). Grouping into easy totals beats adding one at a time!", longWay: "7 additions", seconds: 60, steps: 1)
        case .pairUpTen:
            let top = p([6, 8, 10], [10, 12, 14, 16, 20], [12, 14, 16, 18, 20])
            let answer = MathFacts.triangular(top)
            traps = [top * (top + 1), top * top / 2, answer + top]
            return puzzle("Pair Up", "Here are the numbers 1 to \(top).", "What is 1 + 2 + … + \(top)?", .number(answer), visual: .pairing(numbers: Array(1...top)), hints: ["Tap the first number and the last number to make a pair.", "What do 1 and \(top) make? What about 2 and \(top - 1)?", "Every pair makes the same total. How many pairs are there?"], eureka: "Pair the ends: 1 + \(top), 2 + \(top - 1), and so on. Every pair is \(top + 1), and there are \(top / 2) pairs. \(top / 2) × \(top + 1) = \(f(answer)).", longWay: "\(top - 1) additions", seconds: 60, steps: 2)
        case .countByPairs:
            let pairs = rng.int(4...9)
            let extra = rng.bool(0.5) ? 1 : 0
            let total = 2 * pairs + extra
            traps = [total + 1, total - 1, pairs]
            return puzzle("Count by Pairs", "Socks on a line! Tap two at a time to pair them.", "How many socks are there?", .number(total), visual: .pairing(numbers: Array(repeating: 1, count: total)), hints: ["Make pairs first. Don't count one by one.", "Count the pairs by 2s: 2, 4, 6…", "Is there one sock left over?"], eureka: "\(pairs) pairs is \(2 * pairs)\(extra == 1 ? ", plus 1 left over makes \(total)" : ""). Counting by 2s is twice as fast!", longWay: "\(total) counts", seconds: 45, steps: 1)
        case .teachersTrick:
            let top = p([20], [100], [100])
            let answer = MathFacts.triangular(top)
            traps = [top * (top + 1), answer - top / 2, answer + top]
            return puzzle("The Teacher's Trick", "Long ago, a teacher wanted a quiet class, so she said: add every number from 1 to \(top). One student, Carl Friedrich Gauss, had the answer almost at once.", "What is 1 + 2 + 3 + … + \(top)?", .number(answer), visual: easy ? .pairing(numbers: Array(1...top)) : .none, hints: ["Adding one by one would take \(top - 1) steps. Is there a shortcut?", "What is 1 + \(top)? What is 2 + \(top - 1)? And 3 + \(top - 2)?", "All the pairs are the same. How many pairs can you make from \(top) numbers?"], eureka: "Gauss paired the ends: 1 + \(top), 2 + \(top - 1), … Each pair is \(top + 1), and \(top) numbers make \(top / 2) pairs. \(top / 2) × \(top + 1) = \(f(answer)).", longWay: "\(top - 1) additions", seconds: 90, steps: 2)
        case .oddOneInMiddle:
            let top = p([5, 7, 9], [9, 11, 13, 15], [15, 17, 19, 21, 25])
            let answer = MathFacts.triangular(top)
            let middle = (top + 1) / 2
            traps = [answer - middle, (top / 2) * (top + 1) + top, answer + 1]
            return puzzle("Odd One in the Middle", "The numbers 1 to \(top). That's an odd amount, so pairing leaves one number alone.", "What is 1 + 2 + … + \(top)?", .number(answer), visual: .pairing(numbers: Array(1...top)), hints: ["Pair the ends again. Which number has no partner?", "The lonely middle number is \(middle). What's special about it compared with each pair?", "Each pair is \(top + 1). The middle is exactly half a pair."], eureka: "\(top / 2) pairs of \(top + 1), plus the middle \(middle). Or think of it as \(top) numbers that average \(middle): \(top) × \(middle) = \(f(answer)).", longWay: "\(top - 1) additions", seconds: 75, steps: 3)
        case .bigThousand:
            let top = p([30, 40, 50], [200, 400, 500], [1000, 2000, 500, 10000])
            let answer = MathFacts.triangular(top)
            traps = [top * (top + 1), answer + top]
            return puzzle("To the Thousands", "Same trick, bigger mountain.", "What is 1 + 2 + … + \(f(top))?", .number(answer), hints: ["How many pairs can \(f(top)) numbers make?", "What does each pair add up to?", "Pairs × pair total."], eureka: "\(f(top / 2)) pairs of \(f(top + 1)) is \(f(answer)). The trick works for any size: n × (n + 1) ÷ 2.", longWay: "\(f(top - 1)) additions", seconds: 60, steps: 2)
        case .fromHereToThere:
            let a = n(2...6, 5...20, 11...40)
            let count = 2 * n(3...5, 5...15, 10...30)
            let b = a + count - 1
            let answer = MathFacts.rangeSum(a, b)
            traps = [(a + b) * (b - a) / 2, answer + b]
            return puzzle("From Here to There", "Not from 1 this time!", "What is \(a) + \(a + 1) + … + \(b)?", .number(answer), visual: easy ? .pairing(numbers: Array(a...b)) : .none, hints: ["Pairing the ends still works. What is \(a) + \(b)?", "How many numbers are there from \(a) to \(b)? Careful: it isn't \(b) − \(a).", "There are \(count) numbers, so \(count / 2) pairs."], eureka: "From \(a) to \(b) is \(count) numbers (\(b) − \(a) + 1). They make \(count / 2) pairs of \(a + b). \(count / 2) × \(a + b) = \(f(answer)).", longWay: "\(count - 1) additions", seconds: 90, steps: 3)
        case .stepSequence:
            let first = n(1...3, 1...9, 1...9)
            let step = n(2...3, 2...5, 3...7)
            let terms = 2 * n(3...4, 5...8, 6...13)
            let last = first + step * (terms - 1)
            let answer = MathFacts.arithmeticSum(first: first, step: step, terms: terms)
            traps = [terms * (first + last), answer + last]
            return puzzle("Stepping Stones", "These numbers go up by \(step) each time.", "What is \(Format.series(first: first, step: step, last: last))?", .number(answer), hints: ["Do the ends still make pairs with the same total?", "How many numbers are in the list? Jumps of \(step) from \(first) to \(last)…", "(\(last) − \(first)) ÷ \(step) jumps means one more number than jumps."], eureka: "There are \(terms) numbers. They make \(terms / 2) pairs of \(first + last). \(terms / 2) × \(first + last) = \(f(answer)). Pairing works on any list that goes up by the same step!", longWay: "\(terms - 1) additions", seconds: 120, steps: 4)
        case .missingCard:
            let top = n(6...10, 12...20, 20...40)
            let missing = rng.int(1...top)
            let rest = MathFacts.triangular(top) - missing
            traps = [missing + 1, missing - 1]
            return puzzle("The Missing Card", "Cards numbered 1 to \(top). One fell behind the couch. The cards left add up to \(f(rest)).", "Which card is missing?", .number(missing), hints: ["What would ALL the cards add up to?", "Use the pairing trick for 1 to \(top).", "Full total − what's left = the missing card."], eureka: "All \(top) cards make \(f(MathFacts.triangular(top))). Take away \(f(rest)) and the missing card is \(missing).", longWay: "\(top - 2) additions plus guessing", seconds: 90, steps: 3)

        // MARK: Triangle Town
        case .staircaseFold:
            let rows = n(3...5, 5...8, 6...9)
            let answer = MathFacts.triangular(rows)
            traps = [rows * (rows + 1), rows * rows, answer + 1]
            return puzzle("Staircase Fold", "A staircase of dots: 1 on top, then 2, then 3… all the way to \(rows).", "How many dots in the staircase?", .number(answer), visual: .staircase(rows: rows), hints: ["Press Copy & Flip. What shape do two staircases make?", "The rectangle is \(rows) by \(rows + 1).", "The staircase is half the rectangle."], eureka: "Two staircases make a \(rows) × \(rows + 1) rectangle of \(rows * (rows + 1)) dots. One staircase is half: \(answer). These are triangle numbers.", longWay: "\(rows - 1) additions", seconds: 45, steps: 2)
        case .canStack:
            let rows = n(4...7, 8...15, 12...30)
            let answer = MathFacts.triangular(rows)
            traps = [rows * (rows + 1), rows * rows]
            return puzzle("Can Tower", "A shop stacks cans in a triangle: 1 can on top, 2 under it, 3 under that, and \(rows) on the bottom row.", "How many cans?", .number(answer), visual: easy ? .staircase(rows: rows) : .none, hints: ["This is a staircase! Imagine a second tower upside down beside it.", "Together they make a rectangle \(rows) tall and \(rows + 1) wide.", "Half of \(rows) × \(rows + 1)."], eureka: "\(rows) × \(rows + 1) ÷ 2 = \(f(answer)) cans.", longWay: "\(rows - 1) additions", seconds: 60, steps: 2)
        case .handshakes:
            let people = n(3...6, 6...12, 10...30)
            let answer = people * (people - 1) / 2
            traps = [people * (people - 1), people * people, answer + people]
            return puzzle("Handshake Party", "\(people) friends meet. Everybody shakes hands with everybody else once.", "How many handshakes?", .number(answer), visual: people <= 12 ? .handshake(people: people) : .none, hints: ["How many hands does ONE person shake?", "\(people) people × \(people - 1) shakes each… but each handshake has two people in it.", "Every handshake got counted twice. Halve it."], eureka: "Each of \(people) people shakes \(people - 1) hands: \(people * (people - 1)). Each handshake was counted twice, so \(f(answer)). It's the staircase 1 + 2 + … + \(people - 1) in disguise!", longWay: "drawing \(f(answer)) lines", seconds: 60, steps: 2)
        case .homeAndAway:
            let teams = n(3...5, 4...8, 6...20)
            let answer = teams * (teams - 1)
            traps = [answer / 2, teams * teams]
            return puzzle("Home and Away", "A soccer league has \(teams) teams. Every team plays every other team twice: once at home and once away.", "How many games in the season?", .number(answer), visual: teams <= 12 ? .handshake(people: teams) : .none, hints: ["Is this like the handshake party?", "Each pair of teams meets twice.", "Each team hosts every other team once."], eureka: "Each of \(teams) teams hosts \(teams - 1) games: \(teams) × \(teams - 1) = \(answer). No halving this time, because home and away are different games.", longWay: "listing every game", seconds: 60, steps: 1)
        case .diagonals:
            let sides = n(4...6, 5...8, 6...12)
            let names = [4: "square", 5: "pentagon", 6: "hexagon", 7: "heptagon", 8: "octagon", 9: "nonagon", 10: "decagon", 11: "hendecagon", 12: "dodecagon"]
            let answer = MathFacts.diagonals(sides: sides)
            traps = [sides * (sides - 1) / 2, sides * (sides - 3)]
            return puzzle("Diagonal Web", "A \(names[sides] ?? "shape") has \(sides) corners. A diagonal joins two corners that are not next to each other.", "How many diagonals?", .number(answer), visual: .handshake(people: sides), hints: ["The picture joins every corner to every other corner, like handshakes.", "Some of those lines are the sides, not diagonals.", "All lines − \(sides) sides."], eureka: "Corners 'shake hands': \(sides) × \(sides - 1) ÷ 2 = \(sides * (sides - 1) / 2) lines. Take away the \(sides) sides: \(answer) diagonals.", longWay: "drawing and counting", seconds: 60, steps: 3)
        case .howManyRows:
            let rows = n(3...6, 6...15, 10...40)
            let total = MathFacts.triangular(rows)
            traps = [rows + 1, rows - 1, total / 2]
            return puzzle("Backwards Tower", "A triangle tower (1 on top, then 2, then 3…) uses exactly \(f(total)) blocks.", "How many rows tall is it?", .number(rows), visual: easy ? .staircase(rows: rows) : .none, hints: ["Two towers make a rectangle. How many blocks would that be?", "Double \(f(total)) is \(f(2 * total)).", "Find two numbers right next to each other that multiply to \(f(2 * total))."], eureka: "Double it: \(f(2 * total)) = \(rows) × \(rows + 1). So the tower is \(rows) rows tall.", longWay: "adding row after row", seconds: 75, steps: 2)

        // MARK: Odd Squares
        case .oddEvenPattern:
            let start = rng.int(1...9)
            let count = rng.int(5...7)
            let list = (0..<count).map { start + $0 }
            let oddCount = list.filter { $0 % 2 != 0 }.count
            traps = [count - oddCount, count]
            let options: [String] = ["Odd", "Even"]
            let next = start + count
            if rng.bool(0.5) {
                return puzzle("Odd or Even?", "Odd and even take turns: odd, even, odd, even…", "Is the next number after \(list.map(String.init).joined(separator: ", ")) odd or even?", .choice(options: options, correct: next % 2 != 0 ? 0 : 1), visual: .pairing(numbers: list), hints: ["Even numbers can be split into pairs with none left over.", "Try pairing \(next) dots in your head.", "The pattern never breaks: odd, even, odd, even."], eureka: "\(next) is \(next % 2 != 0 ? "odd" : "even"). Odd and even always take turns, so you never have to count far.", longWay: "counting dots", seconds: 30, steps: 0)
            }
            return puzzle("Odd Spotter", "Odd numbers have a lonely one left after pairing.", "How many odd numbers in \(list.map(String.init).joined(separator: ", "))?", .number(oddCount), visual: .pairing(numbers: list), hints: ["Odd numbers end in 1, 3, 5, 7 or 9.", "Odd and even take turns in a row of numbers.", "Start with \(start): is it odd?"], eureka: "In a row of \(count) numbers, odds and evens take turns, so there are \(oddCount) odd ones.", longWay: "checking each one", seconds: 30, steps: 0)
        case .oddLayers:
            let count = n(3...5, 4...7, 5...8)
            let last = 2 * count - 1
            traps = [count * (count + 1), count * count + count, count * count - 1]
            return puzzle("Odd Layers", "Each odd number is an L-shaped layer wrapped around a square.", "What is \((1...count).map { String(2 * $0 - 1) }.joined(separator: " + "))?", .number(count * count), visual: .oddLayers(count: count), hints: ["Look at the shape the layers make.", "1 is a 1×1 square. Add 3 and you get 2×2. Add 5…", "How many layers? That's the side of the square."], eureka: "\(count) odd numbers wrap into a \(count) × \(count) square: \(count * count). (The last one, \(last), is the \(count)th odd number.)", longWay: "\(count - 1) additions", seconds: 45, steps: 1)
        case .bigOdds:
            let count = n(6...10, 10...30, 20...60)
            let last = 2 * count - 1
            traps = [last * last, count * (count + 1)]
            return puzzle("Odd Mountain", "The odd numbers, all in a row.", "What is 1 + 3 + 5 + … + \(last)?", .number(count * count), hints: ["Remember the L-shaped layers?", "How many odd numbers are there from 1 to \(last)?", "(\(last) + 1) ÷ 2 odd numbers make a square."], eureka: "1 to \(last) has \(count) odd numbers, so they make a \(count) × \(count) square: \(f(count * count)).", longWay: "\(count - 1) additions", seconds: 60, steps: 2)
        case .oddsInRange:
            let a = n(2...3, 3...8, 5...15)
            let b = a + n(2...4, 4...10, 5...20)
            let low = 2 * a + 1
            let high = 2 * b - 1
            let answer = b * b - a * a
            traps = [b * b, (b - a) * (b - a)]
            return puzzle("Odd Slice", "Only some of the odd numbers this time.", "What is \(low) + \(low + 2) + … + \(high)?", .number(answer), hints: ["Pretend you started at 1. What would 1 + 3 + … + \(high) be?", "Then take away the odds you didn't want: 1 + 3 + … + \(low - 2).", "Big square − small square."], eureka: "1 to \(high) is \(b) odds: \(b * b). 1 to \(low - 2) is \(a) odds: \(a * a). The slice is \(b * b) − \(a * a) = \(f(answer)). (Pairing works too!)", longWay: "\(b - a - 1) additions", seconds: 90, steps: 3)
        case .upAndDown:
            let top = n(3...6, 5...15, 10...30)
            let series = top <= 5 ? (Array(1...top) + Array((1..<top).reversed())).map(String.init).joined(separator: " + ") : "1 + 2 + … + \(top) + … + 2 + 1"
            traps = [top * (top + 1), MathFacts.triangular(top), top * top + 1]
            return puzzle("Up and Down", "Climb up to \(top), then climb back down.", "What is \(series)?", .number(top * top), visual: easy ? .oddLayers(count: top) : .none, hints: ["Try small ones: 1 + 2 + 1 = 4. 1 + 2 + 3 + 2 + 1 = 9.", "Those answers look familiar… 4, 9, …", "Pair each number on the way up with the one just after it on the way down."], eureka: "Up and down to \(top) is always \(top) × \(top) = \(f(top * top)). Pair 1 with \(top - 1), 2 with \(top - 2)… every pair is \(top), and there are \(top) of them.", longWay: "\(2 * top - 2) additions", seconds: 60, steps: 1)
        case .evensToo:
            let count = n(4...6, 8...20, 10...50)
            let answer = count * (count + 1)
            traps = [count * count, answer / 2]
            return puzzle("Even Steven", "Now the even numbers.", "What is 2 + 4 + 6 + … + \(2 * count)?", .number(answer), hints: ["Every even number is 2 × something.", "2 + 4 + … + \(2 * count) = 2 × (1 + 2 + … + \(count)).", "You know the trick for 1 + 2 + … + \(count)!"], eureka: "Take out the 2: 2 × (1 + … + \(count)) = 2 × \(MathFacts.triangular(count)) = \(f(answer)). That's \(count) × \(count + 1).", longWay: "\(count - 1) additions", seconds: 60, steps: 2)
        case .nextSquare:
            let k = n(3...9, 10...30, 15...60)
            traps = [2 * k, k + 1, (k + 1) * (k + 1)]
            return puzzle("Next Square", "\(k) × \(k) = \(f(k * k)).", "What do you add to \(f(k * k)) to get \(k + 1) × \(k + 1)?", .number(2 * k + 1), visual: easy ? .oddLayers(count: k + 1) : .none, hints: ["Picture a \(k) × \(k) square of dots. How many dots make it one bigger?", "You add a row and a column…", "…but they share a corner dot."], eureka: "Growing a square adds one L-shaped layer: \(k) + \(k) + 1 = \(2 * k + 1). That's the next odd number!", longWay: "two big multiplications", seconds: 45, steps: 1)

        // MARK: Doubling Peaks
        case .doublesFacts:
            let start = rng.int(1...5)
            let times = rng.int(3...5)
            let answer = start * MathFacts.power(2, times)
            traps = [start * 2 * times, answer / 2, answer + start]
            return puzzle("Double Trouble", "A magic bean has \(start) leaf\(start == 1 ? "" : "s"). Every day the leaves double.", "How many leaves after \(times) days?", .number(answer), visual: .doubling(steps: times + 1), hints: ["Doubling means adding the number to itself.", "Day 1: \(start * 2). Day 2: \(start * 4)…", "Keep doubling \(times) times."], eureka: "\(start) → \((1...times).map { String(start * MathFacts.power(2, $0)) }.joined(separator: " → ")). Doubling grows fast!", longWay: "counting leaves", seconds: 45, steps: 1)
        case .doublingSum:
            let k = n(3...4, 5...8, 7...12)
            let answer = MathFacts.power(2, k + 1) - 1
            traps = [answer + 1, MathFacts.power(2, k), answer - 2]
            return puzzle("Doubling Stairs", "Each number is double the one before.", "What is 1 + 2 + 4 + … + \(f(MathFacts.power(2, k)))?", .number(answer), visual: .doubling(steps: k + 1), hints: ["Try small ones: 1 + 2 = 3. 1 + 2 + 4 = 7. 1 + 2 + 4 + 8 = 15.", "3, 7, 15… what is each one close to?", "Each total is one less than the next double."], eureka: "The total is always one less than the next double: \(f(MathFacts.power(2, k + 1))) − 1 = \(f(answer)).", longWay: "\(k) additions", seconds: 60, steps: 2)
        case .riceBoard:
            let squares = n(4...6, 6...10, 8...16)
            let answer = MathFacts.power(2, squares) - 1
            traps = [MathFacts.power(2, squares), MathFacts.power(2, squares - 1)]
            return puzzle("Rice on the Board", "A king pays a clever inventor in rice: 1 grain on the first square, 2 on the next, 4 on the next, doubling each time.", "How many grains on the first \(squares) squares altogether?", .number(answer), visual: easy ? .doubling(steps: squares) : .none, hints: ["Square \(squares) gets \(f(MathFacts.power(2, squares - 1))) grains.", "Remember Doubling Stairs?", "All the squares together are one less than the next double."], eureka: "1 + 2 + … + \(f(MathFacts.power(2, squares - 1))) = \(f(MathFacts.power(2, squares))) − 1 = \(f(answer)). All 64 squares would need more rice than the whole world grows!", longWay: "\(squares - 1) additions", seconds: 75, steps: 2)
        case .hanoiPlay:
            let discs = p([3], [3, 4], [4, 5])
            let best = MathFacts.power(2, discs) - 1
            return puzzle("Tower of Hanoi", "Move the whole tower to the right peg. Move one disc at a time, and never put a big disc on a small one.", "Can you do it in \(best) moves?", .board, visual: .hanoi(discs: discs), hints: ["Start with just the top disc or two. Where must the smallest disc go first?", "To move the biggest disc, all the others must be stacked on the middle peg.", "Moving \(discs) discs = move \(discs - 1) out of the way, move the big one, move \(discs - 1) back on top."], eureka: "Each extra disc doubles the work, plus one: 1, 3, 7, 15, 31… For \(discs) discs the best is \(best) moves.", longWay: "lots of wandering moves", seconds: discs == 3 ? 60 : (discs == 4 ? 150 : 300), steps: 0)
        case .hanoiCount:
            let discs = n(4...5, 5...8, 6...12)
            let answer = MathFacts.power(2, discs) - 1
            traps = [MathFacts.power(2, discs), 2 * discs - 1, discs * discs]
            return puzzle("Hanoi Thinker", "In the Tower of Hanoi, 1 disc takes 1 move, 2 discs take 3, 3 discs take 7.", "What is the fewest moves for \(discs) discs?", .number(answer), hints: ["1, 3, 7… what comes next?", "Each step: move the small tower, move the big disc, move the small tower back.", "Each answer is one less than a doubling number."], eureka: "Moves double plus one each time, landing on 2 × 2 × … − 1. For \(discs) discs: \(f(MathFacts.power(2, discs))) − 1 = \(f(answer)).", longWay: "actually doing \(f(answer)) moves", seconds: 60, steps: 2)
        case .paperFold:
            let folds = n(2...4, 4...7, 6...10)
            let answer = MathFacts.power(2, folds)
            traps = [2 * folds, answer / 2, answer - 1]
            return puzzle("Paper Folding", "Fold a sheet of paper in half, then in half again, and again: \(folds) folds in all.", "How many layers thick is it now?", .number(answer), visual: .doubling(steps: folds + 1), hints: ["One fold: 2 layers. Two folds: ?", "Every fold doubles the layers.", "Double \(folds) times starting from 1."], eureka: "Each fold doubles: 2 × 2 × … (\(folds) times) = \(f(answer)) layers.", longWay: "real folding", seconds: 45, steps: 1)
        case .toppings:
            let count = n(2...3, 3...6, 4...10)
            let answer = MathFacts.power(2, count)
            traps = [answer - 1, 2 * count, count * count]
            return puzzle("Pizza Choices", "A pizza shop has \(count) toppings. Each one can be on or off (a plain pizza counts too).", "How many different pizzas can you order?", .number(answer), hints: ["With 1 topping: plain or with it. That's 2.", "Each new topping doubles the choices: every old pizza, with or without it.", "Double \(count) times."], eureka: "Every topping is yes or no, so the choices double each time: 2 multiplied \(count) times = \(f(answer)).", longWay: "listing every pizza", seconds: 45, steps: 1)
        case .lilyPond:
            let day = n(4...10, 10...30, 20...60)
            traps = [day / 2, day - 2, day + 1]
            return puzzle("Lily Pond", "A lily patch doubles in size every day. On day \(day) it covers the whole pond.", "On what day was the pond half covered?", .number(day - 1), hints: ["Don't halve the days!", "Think backwards: what was it the day before it was full?", "Doubling half gives the whole."], eureka: "If it doubles each day, it was half the size one day earlier: day \(day - 1).", longWay: "dividing the wrong thing", seconds: 30, steps: 0)

        // MARK: Digit Detectives
        case .divisibleByNine:
            let lowDigits = p([2, 3], [4, 5], [5, 7])
            let low = MathFacts.power(10, lowDigits - 1)
            var value = rng.int(low...(10 * low - 1))
            let yes = rng.bool(0.5)
            if yes {
                value -= value % 9
                if value < low { value += 9 }
            } else if value % 9 == 0 {
                value += value + 1 < 10 * low ? 1 : -1
            }
            let digits = f(MathFacts.digitSum(value))
            return puzzle("Nine Detector", "A number can be split into 9s evenly if its digits add up to a multiple of 9.", "Can \(f(value)) be split into groups of 9 with none left over?", .choice(options: yesNo, correct: value % 9 == 0 ? 0 : 1), visual: .digits(String(value)), hints: ["Add up the digits.", "Is the digit total a multiple of 9 (9, 18, 27…)?", "The digits add to \(digits)."], eureka: "The digits of \(f(value)) add to \(digits). \(value % 9 == 0 ? "That's a multiple of 9, so yes!" : "That's not a multiple of 9, so no.") It works because 10, 100, 1000 are each one more than a multiple of 9.", longWay: "long division", seconds: 30, steps: 0)
        case .remainderNine:
            let value = n(100...999, 10_000...99_999, 1_000_000...99_999_999)
            let answer = value % 9
            traps = [MathFacts.digitSum(value), (answer + 1) % 9, (answer + 8) % 9]
            return puzzle("Leftover Nines", "When you split a number into 9s, the leftover is hiding in its digits.", "What is left over when \(f(value)) is split into 9s?", .number(answer), visual: .digits(String(value)), hints: ["Add the digits.", "Still more than 8? Add the digits of that.", "Leftover of the digit total = leftover of the number."], eureka: "\(f(value)): digits add to \(MathFacts.digitSum(value)), and \(MathFacts.digitSum(value)) leaves \(answer) after taking out 9s. So \(f(value)) leaves \(answer) too.", longWay: "long division", seconds: 45, steps: 1)
        case .missingDigit:
            let length = p([3], [4], [5, 6])
            var digits = (0..<length).map { $0 == 0 ? rng.int(1...9) : rng.int(0...9) }
            let blank = rng.int(1...(length - 1))
            var needed = 0
            for _ in 0..<50 {
                let others = digits.enumerated().filter { $0.offset != blank }.map(\.element).reduce(0, +)
                needed = (9 - others % 9) % 9
                if needed != 0 { break }
                let bump = (blank + 1) % length == 0 ? 1 : (blank + 1) % length
                digits[bump] = (digits[bump] + 1) % 10
                if digits[0] == 0 { digits[0] = 1 }
            }
            if needed == 0 { needed = 9 }
            digits[blank] = needed
            let shown = digits.enumerated().map { $0.offset == blank ? "_" : String($0.element) }.joined()
            traps = [(needed + 1) % 10, (needed + 2) % 10, 9 - needed]
            return puzzle("Missing Digit", "This number splits into 9s with nothing left over. One digit is smudged.", "What digit goes in the blank: \(shown)?", .number(needed), visual: .digits(shown), hints: ["Add up the digits you can see.", "The full digit total must be a multiple of 9.", "How much more to reach the next multiple of 9?"], eureka: "The digits must add to a multiple of 9, so the blank is \(needed). The number is \(digits.map(String.init).joined()).", longWay: "trying every digit with long division", seconds: 45, steps: 1)
        case .whichByThree:
            let range = p([10...99], [100...999], [1000...9999])
            var correct = rng.int(range)
            correct -= correct % 3
            if correct < range.lowerBound { correct += 3 }
            var others: [Int] = []
            while others.count < 3 {
                let candidate = rng.int(range)
                if candidate % 3 != 0 && !others.contains(candidate) { others.append(candidate) }
            }
            let options = rng.shuffled([correct] + others)
            return puzzle("Three's Company", "A number splits into 3s evenly when its digits add to a multiple of 3.", "Which number splits into 3s with nothing left over?", .choice(options: options.map(f), correct: options.firstIndex(of: correct)!), hints: ["Add the digits of each number.", "Which digit total is 3, 6, 9, 12, 15…?", "Only one of them works."], eureka: "\(f(correct)): digits add to \(MathFacts.digitSum(correct)), a multiple of 3. The 3s test is the 9s test's little sibling.", longWay: "four divisions", seconds: 45, steps: 0)
        case .castingOutNines:
            let a = n(12...49, 100...999, 100...999)
            let b = n(11...29, 20...99, 100...999)
            let product = a * b
            var wrong: [Int] = []
            while wrong.count < 2 {
                let k = rng.int(1...30)
                guard k % 9 != 0 else { continue }
                let candidate = rng.bool(0.5) ? product + 10 * k : product - 10 * k
                if candidate > 0 && !wrong.contains(candidate) && candidate % 9 != product % 9 { wrong.append(candidate) }
            }
            let options = rng.shuffled([product] + wrong)
            return puzzle("Casting Out Nines", "Three robots worked out \(f(a)) × \(f(b)). Only one is right. They all end in the same digit, so that won't help!", "Which answer can be right?", .choice(options: options.map(f), correct: options.firstIndex(of: product)!), hints: ["Find the digit-sum leftover (after 9s) of \(f(a)) and of \(f(b)).", "Multiply those two leftovers, and find the leftover of that.", "The right answer's digits must leave the same leftover."], eureka: "\(f(a)) leaves \(a % 9) and \(f(b)) leaves \(b % 9). \(a % 9) × \(b % 9) leaves \((a % 9) * (b % 9) % 9). Only \(f(product)) leaves \(product % 9). That's casting out nines, a checker used for hundreds of years.", longWay: "doing the whole multiplication", seconds: 90, steps: 1)
        case .digitalRoot:
            let value = n(100...999, 10_000...999_999, 10_000_000...999_999_999)
            let answer = MathFacts.digitalRoot(value)
            traps = [MathFacts.digitSum(value), (answer % 9) + 1]
            return puzzle("Digit Shrinker", "Add the digits. If the answer has more than one digit, add those digits. Keep going until one digit is left.", "What single digit does \(f(value)) shrink to?", .number(answer), visual: .digits(String(value)), hints: ["Any 9 can be crossed out. It doesn't change the answer!", "Cross out digits that make 9 together too, like 4 and 5.", "The answer is the leftover after 9s (but 9 instead of 0)."], eureka: "\(f(value)) shrinks to \(answer). Crossing out 9s (and pairs that make 9) is the shortcut.", longWay: "adding every digit, again and again", seconds: 45, steps: 1)

        // MARK: Pigeons & Parity
        case .sockDrawer:
            let colors = n(2...3, 2...5, 3...7)
            traps = [2, 2 * colors, colors]
            return puzzle("Sock Drawer", "A dark drawer has lots of socks in \(colors) colors. You grab without looking.", "How many socks must you grab to be SURE you have a matching pair?", .number(colors + 1), visual: .socks(colors: colors), hints: ["What's the unluckiest thing that could happen?", "You might get one of every color first.", "The very next sock has to match one of them."], eureka: "Unluckiest case: \(colors) different colors. Sock \(colors + 1) must match. More pigeons than holes means two share a hole!", longWay: "guessing", seconds: 30, steps: 0)
        case .sockTriples:
            let colors = n(2...3, 2...4, 3...6)
            let wanted = n(3...3, 3...4, 3...5)
            let answer = colors * (wanted - 1) + 1
            traps = [colors * wanted, answer - 1, colors + wanted]
            return puzzle("Sock Triples", "The drawer has lots of socks in \(colors) colors. You need \(wanted) of the same color.", "How many must you grab to be sure?", .number(answer), visual: .socks(colors: colors), hints: ["Unluckiest case again.", "How many of each color could you grab and still NOT have \(wanted)?", "\(wanted - 1) of every color, then one more."], eureka: "You could hold \(wanted - 1) of each of \(colors) colors (\(colors * (wanted - 1)) socks) and still not win. One more makes \(answer).", longWay: "guessing", seconds: 45, steps: 2)
        case .sharedMonth:
            let options: [(String, Int, String)] = easy ? [("roll the same number on a dice", 6, "6 numbers"), ("be born on the same day of the week", 7, "7 days")] : [("share a birth month", 12, "12 months"), ("be born on the same day of the week", 7, "7 days"), ("have names starting with the same letter", 26, "26 letters"), ("roll the same number on a dice", 6, "6 numbers")]
            let pick = rng.pick(options)
            traps = [pick.1, 2 * pick.1, pick.1 + 2]
            return puzzle("Pigeonholes", "How big must a group be?", "How many people (or dice) do you need to be sure two \(pick.0)?", .number(pick.1 + 1), hints: ["How many 'holes' are there?", "Unluckiest case: everyone different.", "There are \(pick.2). One more than that."], eureka: "\(pick.2), so \(pick.1) could all be different. Number \(pick.1 + 1) must match someone.", longWay: "asking around", seconds: 30, steps: 0)
        case .oddNumbersSum:
            let k = n(2...4, 3...7, 3...9)
            var total = 2 * n(4...8, 5...15, 6...20)
            if rng.bool(0.5) { total += 1 }
            let possible = total >= k && (total - k) % 2 == 0
            return puzzle("Odd Ones", "Odd + odd = even. Even + odd = odd.", "Can \(k) odd numbers (repeats allowed) add up to \(total)?", .choice(options: yesNo, correct: possible ? 0 : 1), hints: ["What do 2 odd numbers make: odd or even?", "Three odds? Four odds?", "\(k) is \(k % 2 == 0 ? "even" : "odd") and \(total) is \(total % 2 == 0 ? "even" : "odd")."], eureka: possible ? "Yes! An \(k % 2 == 0 ? "even" : "odd") count of odd numbers makes an \(total % 2 == 0 ? "even" : "odd") total, for example \((Array(repeating: "1", count: k - 1) + [String(total - k + 1)]).joined(separator: " + "))." : "No. \(k) odd numbers always make an \(k % 2 == 0 ? "even" : "odd") total, and \(total) is \(total % 2 == 0 ? "even" : "odd"). Parity settles it without trying anything.", longWay: "trying lots of numbers", seconds: 45, steps: 0)
        case .dominoBoard:
            let size = p([4], [6, 8], [8])
            let opposite = rng.bool(0.6)
            let removed = opposite ? [0, size * size - 1] : [0, size - 1]
            return puzzle("Domino Mystery", "A \(size) × \(size) board is missing two corner squares (\(opposite ? "opposite corners" : "both top corners")). Each domino covers two squares side by side.", "Can dominoes cover the rest exactly?", .choice(options: yesNo, correct: opposite ? 1 : 0), visual: .dominoBoard(size: size, removed: removed), hints: ["Every domino covers one dark and one light square.", "What colors are the two missing squares?", "Count dark and light squares that are left."], eureka: opposite ? "No! Opposite corners are the same color, so 2 more light squares than dark are left (or the other way). Each domino needs one of each, so it can never work." : "Yes! The two top corners are different colors, so the dark and light counts stay equal, and you can snake the dominoes around the board.", longWay: "trying every layout", seconds: 60, steps: 0)
        case .lockers:
            let count = n(10...20, 20...60, 50...200)
            let answer = MathFacts.openLockers(count)
            traps = [count / 2, answer + 1, answer - 1]
            return puzzle("Locker Flip", "\(count) lockers, all shut. Kid 1 flips every locker. Kid 2 flips every 2nd locker. Kid 3 flips every 3rd… up to kid \(count).", "How many lockers are open at the end?", .number(answer), hints: ["Locker 12 gets flipped by kids 1, 2, 3, 4, 6 and 12. Open or shut?", "A locker ends open if it's flipped an odd number of times.", "Which numbers have an odd number of factors? Factors come in pairs… unless one is paired with itself."], eureka: "Only square numbers (1, 4, 9, 16…) have an odd number of factors. There are \(answer) squares up to \(count).", longWay: "\(count) rounds of flipping", seconds: 90, steps: 0)
        case .oddOrEvenTotal:
            let top = n(4...12, 10...50, 20...200)
            let total = MathFacts.triangular(top)
            return puzzle("Odd or Even Total", "No need to add it all up!", "Is 1 + 2 + … + \(top) odd or even?", .choice(options: ["Odd", "Even"], correct: total % 2 == 1 ? 0 : 1), visual: easy ? .pairing(numbers: Array(1...top)) : .none, hints: ["Only the odd numbers matter. Evens never change odd/even.", "How many odd numbers are there from 1 to \(top)?", "An even count of odd numbers makes even."], eureka: "There are \((top + 1) / 2) odd numbers from 1 to \(top). That's \(((top + 1) / 2) % 2 == 0 ? "even" : "odd"), so the total (\(f(total))) is \(total % 2 == 0 ? "even" : "odd").", longWay: "\(top - 1) additions", seconds: 45, steps: 0)

        // MARK: Grid Galaxy
        case .squaresOnBoard:
            let size = n(2...3, 3...5, 4...8)
            let answer = MathFacts.squaresOnBoard(size)
            traps = [size * size, answer - 1, MathFacts.squaresOnBoard(size - 1)]
            return puzzle("Square Hunt", "Squares come in many sizes on a \(size) × \(size) board: 1×1, 2×2, and bigger.", "How many squares of ALL sizes?", .number(answer), visual: .checkerboard(size: size), hints: ["Count one size at a time. Use the size slider.", "How many 1×1? How many \(size)×\(size)?", "The counts are square numbers!"], eureka: "Sizes give \((1...size).reversed().map { "\($0 * $0)" }.joined(separator: " + ")) = \(answer). Count by size, then add the layers.", longWay: "counting squares one by one", seconds: 90, steps: 3)
        case .squaresOfOneSize:
            let size = n(3...4, 4...7, 5...10)
            let k = rng.int(2...(size - 1))
            let answer = (size - k + 1) * (size - k + 1)
            traps = [(size - k) * (size - k), size - k + 1, answer + 1]
            return puzzle("One Size Only", "On a \(size) × \(size) board…", "How many \(k) × \(k) squares can you find?", .number(answer), visual: .checkerboard(size: size), hints: ["Where can the top-left corner of a \(k) × \(k) square sit?", "It can slide across \(size - k + 1) spots…", "…and down \(size - k + 1) spots."], eureka: "The corner has \(size - k + 1) spots across and \(size - k + 1) down: \(answer) squares.", longWay: "drawing each one", seconds: 60, steps: 1)
        case .rectanglesInGrid:
            let rows = n(1...2, 2...3, 2...4)
            let columns = n(2...3, 2...4, 3...6)
            let answer = MathFacts.rectangles(rows: rows, columns: columns)
            traps = [rows * columns, answer / 2, answer - 1]
            return puzzle("Rectangle Rally", "A grid \(rows) cells tall and \(columns) cells wide. Squares count as rectangles too.", "How many rectangles of any size?", .number(answer), visual: .grid(rows: rows, columns: columns), hints: ["A rectangle is made by choosing 2 up-and-down lines and 2 side-to-side lines.", "There are \(columns + 1) up-and-down lines. How many ways to choose 2? (Handshakes!)", "Ways for across × ways for down."], eureka: "Choose 2 of \(columns + 1) vertical lines (\(MathFacts.triangular(columns)) ways) and 2 of \(rows + 1) horizontal lines (\(MathFacts.triangular(rows)) ways): \(MathFacts.triangular(columns)) × \(MathFacts.triangular(rows)) = \(answer).", longWay: "counting and losing track", seconds: 90, steps: 2)
        case .gridPaths:
            let right = n(1...2, 2...4, 2...5)
            let up = n(1...2, 2...3, 2...5)
            let answer = MathFacts.choose(right + up, right)
            traps = [right * up, right + up, answer + 1]
            return puzzle("Shortest Paths", "A bug walks along the lines from the bottom-left corner to the top-right corner of a grid \(right) wide and \(up) tall. It only steps right or up.", "How many different paths?", .number(answer), visual: .grid(rows: up, columns: right), hints: ["How many ways to reach each corner along the bottom edge? Just 1.", "Ways to reach a corner = ways from below + ways from the left.", "Fill in the corners one by one."], eureka: "Adding left + below at every corner builds Pascal's triangle. For \(right) right and \(up) up there are \(answer) paths.", longWay: "drawing every path", seconds: 90, steps: 3)
        case .pizzaCuts:
            let cuts = n(1...3, 3...6, 4...10)
            let answer = MathFacts.pizzaPieces(cuts: cuts)
            traps = [2 * cuts, MathFacts.power(2, cuts), answer - 1]
            return puzzle("Pizza Cuts", "Straight cuts across a big pizza. Pieces don't have to be the same size.", "What is the MOST pieces you can make with \(cuts) cut\(cuts == 1 ? "" : "s")?", .number(answer), hints: [cuts <= 1 ? "Try it in your head: what does one cut across a circle do?" : "0 cuts: 1 piece. " + (1..<min(cuts, 4)).map { "\($0) cut\($0 == 1 ? "" : "s"): \(MathFacts.pizzaPieces(cuts: $0))." }.joined(separator: " "), "Each new cut can cross every old cut once.", "The new cut adds one more piece than the number of cuts it crosses."], eureka: "Cut number k adds k new pieces, so the total is 1 + (1 + 2 + … + \(cuts)) = 1 + \(MathFacts.triangular(cuts)) = \(answer). Triangle numbers again!", longWay: "drawing pizzas", seconds: 60, steps: 2)
        case .paintedCube:
            let side = n(3...3, 3...5, 3...8)
            let variant = rng.int(0...2)
            let answers = [(side - 2) * (side - 2) * (side - 2), 6 * (side - 2) * (side - 2), 12 * (side - 2)]
            let phrases = ["no paint at all", "paint on exactly one face", "paint on exactly two faces"]
            let answer = answers[variant]
            traps = answers.filter { $0 != answer } + [8]
            return puzzle("Painted Cube", "A big \(side) × \(side) × \(side) cube is painted on the outside, then cut into small cubes.", "How many small cubes have \(phrases[variant])?", .number(answer), hints: ["Corners have 3 painted faces. Edges (not corners) have 2. Face middles have 1. The inside has none.", "Peel off the outside layer. What's left inside?", "Each edge has \(side - 2) cubes that aren't corners."], eureka: ["The unpainted inside is a \(side - 2) × \(side - 2) × \(side - 2) cube: \(answers[0]).", "Each of 6 faces has a \(side - 2) × \(side - 2) middle: 6 × \((side - 2) * (side - 2)) = \(answers[1]).", "Each of 12 edges has \(side - 2) middle cubes: 12 × \(side - 2) = \(answers[2])."][variant], longWay: "counting cubes", seconds: 75, steps: 2)

        // MARK: Logic Lab
        case .magicSquare:
            var square = MagicSquarePuzzle.generate(using: &rng)
            if easy {
                // Explorers get 1 to 9 and an extra clue.
                let shift = square.lowest - 1
                square.solution = square.solution.map { $0 - shift }
                square.lowest = 1
                if let extra = (0..<9).first(where: { !square.givens[$0] && $0 != 4 }) { square.givens[extra] = true }
                square.givens[4] = true
            }
            return puzzle("Magic Square", "Put \(square.lowest) to \(square.lowest + 8) in the grid, once each, so every row, column and diagonal adds to the same number.", "Fill the magic square.", .board, visual: .magic(square), hints: ["All nine numbers add to \(9 * (square.lowest + 4)). Three rows share that.", "So each line adds to \(square.magicTotal).", "The middle number always goes in the center: \(square.lowest + 4)."], eureka: "The magic total is the grand total ÷ 3 = \(square.magicTotal), and the middle number sits in the center because it's in 4 lines.", longWay: "trial and error", seconds: 180, steps: 0)
        case .magicTotal:
            if rng.bool(0.5) {
                let size = n(3...3, 3...4, 3...6)
                let top = size * size
                let answer = size * (top + 1) / 2
                traps = [MathFacts.triangular(top), answer + size]
                return puzzle("Magic Total", "A \(size) × \(size) magic square uses 1 to \(top) once each. Every row adds to the same number.", "What does each row add to?", .number(answer), hints: ["What do 1 to \(top) add up to? (Gauss!)", "That total is shared equally by \(size) rows.", "Total ÷ \(size)."], eureka: "1 to \(top) adds to \(MathFacts.triangular(top)). Split over \(size) rows: \(answer).", longWay: "building the whole square", seconds: 60, steps: 2)
            }
            let low = n(1...5, 2...20, 5...50)
            traps = [9 * (low + 4), low + 4, 3 * low + 12 + 3]
            return puzzle("Magic Total", "A 3 × 3 magic square uses \(low) to \(low + 8) once each.", "What does each row add to?", .number(3 * (low + 4)), hints: ["Gauss pairing: what's the total of all nine?", "Three rows share it.", "Or: the middle number × 3."], eureka: "Nine numbers averaging \(low + 4) make \(9 * (low + 4)); each of 3 rows gets \(3 * (low + 4)).", longWay: "building the square", seconds: 60, steps: 2)
        case .kenKenThree, .kenKenFour:
            let size = kind == .kenKenThree ? 3 : 4
            let board = KenKenPuzzle.generate(size: size, using: &rng)
            return puzzle("KenKen \(size)×\(size)", "Use 1 to \(size) once in every row and every column. Each outlined cage must make its number with its sign.", "Fill the grid.", .board, visual: .kenKen(board), hints: ["Start with cages of one square: they're given.", "A 2-square cage with ÷ or − has only a few possible pairs.", "Each row adds to \(MathFacts.triangular(size)). Use that to find a missing number."], eureka: "Logic beats guessing: one sure square leads to the next.", longWay: "guessing", seconds: size == 3 ? 120 : 300, steps: 0)
        case .logicGrid:
            let board = LogicGridPuzzle.generate(using: &rng)
            return puzzle("Logic Grid", "Three friends, three pets, three favorite colors. Read the clues. Tap a box once for ✗ (no), twice for ✓ (yes).", "Who has which pet and color?", .board, visual: .logicGrid(board), hints: ["Put ✗ for every 'not' clue first.", "If a row has two ✗, the last box must be ✓.", "A ✓ means everything else in its row and column is ✗."], eureka: "Ruling out what can't be true leaves only what must be true. That's how detectives think!", longWay: "guessing", seconds: 240, steps: 0)
        case .balanceCoins:
            let coins = p([3, 9], [4, 9, 10, 12, 27], [12, 27, 30, 81, 100, 243])
            let answer = MathFacts.weighings(coins: coins)
            traps = [coins / 2, answer + 1, coins - 1]
            return puzzle("Heavy Coin", "\(coins) coins look the same, but one is a little heavier. You have a balance scale.", "What is the fewest weighings that ALWAYS finds the heavy coin?", .number(answer), hints: ["One weighing has 3 outcomes: left heavy, right heavy, or balanced.", "Split into three piles, not two!", "One weighing handles 3 coins. Two handle 9. Three handle…"], eureka: "Each weighing cuts the suspects to a third. 3 weighings handle 27 coins; \(answer) weighing\(answer == 1 ? "" : "s") handle up to \(MathFacts.power(3, answer)) ≥ \(coins).", longWay: "weighing coins two at a time", seconds: 60, steps: 1)
        }
    }
}
