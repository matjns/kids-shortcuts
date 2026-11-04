/// A whole-number adding machine. Each calculation it does is one "step".
/// Adding 1 + 2 + ... + 100 by hand is 99 steps. The trick is 2.
public struct Scratchpad: Equatable, Sendable {
    public enum Operation: String, CaseIterable, Sendable {
        case add = "+"
        case subtract = "−"
        case multiply = "×"
        case divide = "÷"
    }

    public private(set) var display = "0"
    public private(set) var steps = 0
    public private(set) var tape: [String] = []
    public private(set) var error: String?
    private var accumulator: Int?
    private var pending: Operation?
    private var entering = false

    public init() {}

    public static let maxDigits = 15

    public mutating func digit(_ value: Int) {
        guard (0...9).contains(value) else { return }
        error = nil
        if !entering {
            display = ""
            entering = true
        }
        if display == "0" { display = "" }
        guard display.count < Scratchpad.maxDigits else { return }
        display += String(value)
    }

    public mutating func backspace() {
        guard entering else { return }
        display.removeLast()
        if display.isEmpty { display = "0" }
    }

    public mutating func operation(_ op: Operation) {
        commit()
        if error == nil {
            pending = op
        }
        entering = false
    }

    public mutating func equals() {
        commit()
        pending = nil
        entering = false
    }

    public mutating func clear() {
        display = "0"
        accumulator = nil
        pending = nil
        entering = false
        error = nil
    }

    public var currentValue: Int? { Int(display) }

    private mutating func commit() {
        guard let value = Int(display) else { return }
        guard entering, let left = accumulator, let op = pending else {
            if entering || accumulator == nil || pending == nil {
                accumulator = value
            }
            return
        }
        let result: Int?
        switch op {
        case .add:
            let (sum, overflow) = left.addingReportingOverflow(value)
            result = overflow ? nil : sum
        case .subtract:
            let (difference, overflow) = left.subtractingReportingOverflow(value)
            result = overflow ? nil : difference
        case .multiply:
            let (product, overflow) = left.multipliedReportingOverflow(by: value)
            result = overflow ? nil : product
        case .divide:
            if value == 0 {
                fail("Can't split into 0 groups")
                return
            }
            if left % value != 0 {
                fail("Not a whole number")
                return
            }
            result = left / value
        }
        guard let result, String(abs(result)).count <= Scratchpad.maxDigits else {
            fail("Too big!")
            return
        }
        steps += 1
        tape.append("\(left) \(op.rawValue) \(value) = \(result)")
        if tape.count > 200 { tape.removeFirst(tape.count - 200) }
        accumulator = result
        display = String(result)
    }

    private mutating func fail(_ message: String) {
        error = message
        display = "0"
        accumulator = nil
        pending = nil
        entering = false
    }
}
