public enum Format {
    /// 5050 -> "5,050". Works the same on every Mac, whatever the region setting.
    public static func number(_ value: Int) -> String {
        let digits = String(abs(value))
        var out = ""
        for (offset, character) in digits.enumerated() {
            if offset > 0 && (digits.count - offset) % 3 == 0 { out.append(",") }
            out.append(character)
        }
        return value < 0 ? "-" + out : out
    }

    public static func plural(_ count: Int, _ word: String, _ plural: String? = nil) -> String {
        "\(number(count)) \(count == 1 ? word : (plural ?? word + "s"))"
    }

    /// "3 + 7 + 11 + … + 79", showing the first three terms and the last.
    public static func series(first: Int, step: Int, last: Int) -> String {
        let terms = [first, first + step, first + 2 * step].map(number)
        return terms.joined(separator: " + ") + " + … + " + number(last)
    }

    /// Stable 64-bit hash of a string (FNV-1a), so seeds don't change between launches.
    public static func stableHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }
}
