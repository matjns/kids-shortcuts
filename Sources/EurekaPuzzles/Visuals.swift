#if os(macOS)
import SwiftUI
import EurekaCore

struct PuzzleVisualView: View {
    @Bindable var model: GameModel
    var puzzle: Puzzle

    var body: some View {
        switch puzzle.visual {
        case .none:
            EmptyView()
        case .pairing:
            PairingView(model: model, socks: puzzle.kind == .countByPairs, showAutoPair: model.hintsShown >= 2)
        case .staircase(let rows):
            StaircaseView(rows: rows)
        case .oddLayers(let count):
            OddLayersView(count: count)
        case .doubling(let steps):
            DoublingView(steps: steps)
        case .handshake(let people):
            HandshakeView(people: people)
        case .checkerboard(let size):
            SquareHuntView(size: size)
        case let .grid(rows, columns):
            GridLinesView(rows: rows, columns: columns)
        case .digits(let text):
            DigitTilesView(text: text)
        case .socks(let colors):
            SockDrawerView(colors: colors)
        case let .dominoBoard(size, removed):
            DominoBoardView(size: size, removed: removed)
        case .hanoi:
            HanoiView(model: model)
        case .kenKen(let board):
            KenKenView(model: model, board: board)
        case .magic(let square):
            MagicSquareView(model: model, square: square)
        case .logicGrid(let grid):
            LogicGridView(model: model, grid: grid)
        }
    }
}

// MARK: Pairing

struct PairingView: View {
    @Bindable var model: GameModel
    var socks: Bool
    var showAutoPair: Bool

    static func summary(_ board: PairingBoard, socks: Bool) -> String {
        if socks { return "Pairs: \(board.pairs.count)" }
        let totals: [String] = board.pairSums.map { String($0) }
        return "Pair totals: " + totals.joined(separator: ", ")
    }

    static func fill(pair: Int?, selected: Bool) -> Color {
        if let pair { return Theme.pairColors[pair % Theme.pairColors.count] }
        return selected ? Theme.sun : Theme.paper
    }

    var body: some View {
        let board = model.pairing
        let perRow = board.numbers.count <= 12 ? board.numbers.count : (board.numbers.count + 1) / 2
        VStack(alignment: .leading, spacing: 14) {
            Text(socks ? "Tap two socks to make a pair." : "Tap a number, then its partner, to pair them. Tap a pair to undo it.")
                .font(Theme.rounded(16, .medium))
                .foregroundStyle(Theme.ink.opacity(0.65))
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(58), spacing: 8), count: max(1, perRow)), spacing: 10) {
                ForEach(board.numbers.indices, id: \.self) { index in
                    let pair: Int? = board.pairIndex(containing: index)
                    let selected: Bool = board.selected == index
                    let fill: Color = PairingView.fill(pair: pair, selected: selected)
                    Button {
                        model.pairing.tap(index)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(fill)
                            Circle()
                                .strokeBorder(selected ? Theme.ink : Theme.ink.opacity(0.15), lineWidth: selected ? 3 : 1)
                            if socks {
                                Image(systemName: "shoeprints.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(pair == nil ? Theme.ink : .white)
                            } else {
                                Text("\(board.numbers[index])")
                                    .font(Theme.rounded(22, .heavy))
                                    .foregroundStyle(pair == nil ? Theme.ink : .white)
                            }
                        }
                        .frame(width: 54, height: 54)
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack(spacing: 10) {
                if !board.pairs.isEmpty {
                    Text(PairingView.summary(board, socks: socks))
                        .font(Theme.rounded(18, .bold))
                        .foregroundStyle(Theme.ink)
                }
                if board.everyPairMatches && !socks {
                    Label("Every pair makes \(board.pairSums[0])!", systemImage: "sparkles")
                        .font(Theme.rounded(18, .heavy))
                        .foregroundStyle(Theme.violet)
                }
                Spacer()
                if showAutoPair && !socks {
                    QuietButton(title: "Pair the ends", symbol: "arrow.left.and.right") { model.pairing.autoPairEnds() }
                }
                if !board.pairs.isEmpty {
                    QuietButton(title: "Clear", symbol: "arrow.uturn.backward") { model.pairing.reset() }
                }
            }
        }
    }
}

// MARK: Dots

struct StaircaseView: View {
    var rows: Int
    @State var folded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Canvas { context, size in
                let columns = rows + 1
                let cell = min(size.width / CGFloat(columns), size.height / CGFloat(rows))
                let radius = cell * 0.36
                for r in 0..<rows {
                    for c in 0..<columns {
                        let center = CGPoint(x: (CGFloat(c) + 0.5) * cell, y: (CGFloat(r) + 0.5) * cell)
                        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                        if c <= r {
                            context.fill(Path(ellipseIn: rect), with: .color(Theme.coral))
                        } else if folded {
                            context.fill(Path(ellipseIn: rect), with: .color(Theme.sky))
                        }
                    }
                }
            }
            .frame(height: 240)
            HStack {
                QuietButton(title: folded ? "Take the copy away" : "Copy & Flip", symbol: "rectangle.on.rectangle.angled") {
                    withAnimation(.easeInOut) { folded.toggle() }
                }
                if folded {
                    Text("Two staircases make a rectangle \(rows) tall and \(rows + 1) wide.")
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink.opacity(0.75))
                }
            }
        }
    }
}

struct OddLayersView: View {
    var count: Int
    @State var shown = 1

    private var layerLabel: String {
        let odds: [String] = (1...max(1, shown)).map { String(2 * $0 - 1) }
        let sum: String = odds.joined(separator: " + ")
        return "Layers: \(shown)   (\(sum))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Canvas { context, size in
                let cell = min(size.width, size.height) / CGFloat(max(count, 1))
                for r in 0..<count {
                    for c in 0..<count {
                        let layer = max(r, c)
                        guard layer < shown else { continue }
                        let rect = CGRect(x: CGFloat(c) * cell + 2, y: CGFloat(r) * cell + 2, width: cell - 4, height: cell - 4)
                        context.fill(Path(roundedRect: rect, cornerRadius: cell * 0.2), with: .color(Theme.pairColors[layer % Theme.pairColors.count]))
                    }
                }
            }
            .frame(width: 240, height: 240)
            Stepper(value: $shown, in: 1...max(1, count)) {
                Text(layerLabel)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
            }
        }
    }
}

struct DoublingView: View {
    var steps: Int

    var body: some View {
        let drawn = min(steps, 7)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .bottom, spacing: 14) {
                ForEach(0..<drawn, id: \.self) { index in
                    let blocks = 1 << index
                    let side = Int(Double(blocks).squareRoot().rounded(.up))
                    VStack(spacing: 6) {
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(9), spacing: 2), count: max(1, side)), spacing: 2) {
                            ForEach(0..<blocks, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 2).fill(Theme.pairColors[index % Theme.pairColors.count]).frame(width: 9, height: 9)
                            }
                        }
                        .frame(width: CGFloat(side) * 11)
                        Text("\(blocks)").font(Theme.rounded(16, .heavy)).foregroundStyle(Theme.ink)
                    }
                }
                if steps > drawn {
                    Text("… keeps doubling").font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink.opacity(0.6))
                }
            }
            Text("Each pile is double the one before it.")
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.ink.opacity(0.6))
        }
    }
}

struct HandshakeView: View {
    var people: Int
    @State var everyone = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 22
                let points = (0..<people).map { index -> CGPoint in
                    let angle = Double(index) / Double(people) * 2 * .pi - .pi / 2
                    return CGPoint(x: center.x + radius * CGFloat(cos(angle)), y: center.y + radius * CGFloat(sin(angle)))
                }
                for a in 0..<people {
                    for b in (a + 1)..<max(a + 1, people) where everyone || a == 0 {
                        var line = Path()
                        line.move(to: points[a])
                        line.addLine(to: points[b])
                        context.stroke(line, with: .color(a == 0 ? Theme.coral : Theme.sky.opacity(0.6)), lineWidth: a == 0 ? 3 : 1.5)
                    }
                }
                for (index, point) in points.enumerated() {
                    let rect = CGRect(x: point.x - 15, y: point.y - 15, width: 30, height: 30)
                    context.fill(Path(ellipseIn: rect), with: .color(index == 0 ? Theme.coral : Theme.violet))
                    context.draw(Text("\(index + 1)").font(Theme.rounded(14, .heavy)).foregroundColor(.white), at: point)
                }
            }
            .frame(height: 280)
            Toggle(everyone ? "Showing everyone's handshakes" : "Showing person 1's handshakes", isOn: $everyone)
                .font(Theme.rounded(16, .semibold))
        }
    }
}

struct SquareHuntView: View {
    var size: Int
    @State var squareSize = 1
    @State var spot = 0

    var body: some View {
        let fits = size - squareSize + 1
        VStack(alignment: .leading, spacing: 10) {
            Canvas { context, canvas in
                let cell = min(canvas.width, canvas.height) / CGFloat(size)
                for r in 0..<size {
                    for c in 0..<size {
                        let rect = CGRect(x: CGFloat(c) * cell, y: CGFloat(r) * cell, width: cell, height: cell)
                        context.fill(Path(rect), with: .color((r + c) % 2 == 0 ? Theme.ink.opacity(0.75) : Theme.paper))
                    }
                }
                let row = spot / max(fits, 1)
                let column = spot % max(fits, 1)
                let frame = CGRect(x: CGFloat(column) * cell, y: CGFloat(row) * cell, width: CGFloat(squareSize) * cell, height: CGFloat(squareSize) * cell)
                context.stroke(Path(roundedRect: frame.insetBy(dx: 3, dy: 3), cornerRadius: 6), with: .color(Theme.sun), lineWidth: 6)
            }
            .frame(width: 260, height: 260)
            HStack {
                Stepper(value: $squareSize, in: 1...size) {
                    Text("Square size: \(squareSize) × \(squareSize)").font(Theme.rounded(16, .semibold))
                }
                .onChange(of: squareSize) { _, _ in spot = 0 }
                QuietButton(title: "Slide it", symbol: "arrow.right") {
                    spot = (spot + 1) % max(1, fits * fits)
                }
            }
        }
    }
}

struct GridLinesView: View {
    var rows: Int
    var columns: Int

    var body: some View {
        Canvas { context, size in
            let cell = min((size.width - 40) / CGFloat(columns), (size.height - 40) / CGFloat(rows))
            let origin = CGPoint(x: 20, y: 20)
            var lines = Path()
            for c in 0...columns {
                lines.move(to: CGPoint(x: origin.x + CGFloat(c) * cell, y: origin.y))
                lines.addLine(to: CGPoint(x: origin.x + CGFloat(c) * cell, y: origin.y + CGFloat(rows) * cell))
            }
            for r in 0...rows {
                lines.move(to: CGPoint(x: origin.x, y: origin.y + CGFloat(r) * cell))
                lines.addLine(to: CGPoint(x: origin.x + CGFloat(columns) * cell, y: origin.y + CGFloat(r) * cell))
            }
            context.stroke(lines, with: .color(Theme.ink.opacity(0.7)), lineWidth: 3)
            let start = CGPoint(x: origin.x, y: origin.y + CGFloat(rows) * cell)
            let end = CGPoint(x: origin.x + CGFloat(columns) * cell, y: origin.y)
            context.fill(Path(ellipseIn: CGRect(x: start.x - 10, y: start.y - 10, width: 20, height: 20)), with: .color(Theme.leaf))
            context.fill(Path(ellipseIn: CGRect(x: end.x - 10, y: end.y - 10, width: 20, height: 20)), with: .color(Theme.coral))
        }
        .frame(height: 260)
    }
}

struct DigitTilesView: View {
    var text: String
    @State var crossed: Set<Int> = []

    var body: some View {
        let characters = Array(text)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(characters.indices, id: \.self) { index in
                    Button {
                        if crossed.contains(index) { crossed.remove(index) } else { crossed.insert(index) }
                    } label: {
                        Text(String(characters[index]))
                            .font(Theme.rounded(40, .heavy))
                            .foregroundStyle(crossed.contains(index) ? Theme.ink.opacity(0.25) : Theme.ink)
                            .strikethrough(crossed.contains(index), color: Theme.coral)
                            .frame(width: 54, height: 70)
                            .background(Theme.paper, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(characters[index] == "_")
                }
            }
            Text("Tap digits to cross them out while you work.")
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.ink.opacity(0.6))
        }
    }
}

struct SockDrawerView: View {
    var colors: Int

    var body: some View {
        HStack(spacing: 22) {
            ForEach(0..<colors, id: \.self) { index in
                VStack(spacing: -10) {
                    ForEach(0..<4, id: \.self) { _ in
                        Image(systemName: "shoeprints.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(Theme.pairColors[index % Theme.pairColors.count])
                    }
                }
            }
        }
        .padding()
    }
}

struct DominoBoardView: View {
    var size: Int
    var removed: [Int]

    var body: some View {
        Canvas { context, canvas in
            let cell = min(canvas.width, canvas.height) / CGFloat(size)
            for index in 0..<(size * size) where !removed.contains(index) {
                let r = index / size
                let c = index % size
                let rect = CGRect(x: CGFloat(c) * cell, y: CGFloat(r) * cell, width: cell, height: cell)
                context.fill(Path(rect), with: .color((r + c) % 2 == 0 ? Theme.ink.opacity(0.8) : Theme.sun.opacity(0.35)))
            }
        }
        .frame(width: 260, height: 260)
    }
}
#endif
