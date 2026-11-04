#if os(macOS)
import SwiftUI
import EurekaCore

struct HanoiView: View {
    @Bindable var model: GameModel

    var body: some View {
        let game = model.hanoi
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 18) {
                ForEach(0..<3, id: \.self) { peg in
                    Button {
                        model.tapPeg(peg)
                    } label: {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.ink.opacity(0.35))
                                .frame(width: 10, height: 200)
                            VStack(spacing: 3) {
                                ForEach(Array(game.pegs[peg].reversed().enumerated()), id: \.offset) { position, disc in
                                    let lifted = model.hanoiSelected == peg && position == 0
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.pairColors[disc % Theme.pairColors.count])
                                        .frame(width: 40 + CGFloat(disc) * 26, height: 24)
                                        .offset(y: lifted ? -18 : 0)
                                }
                            }
                            Rectangle().fill(Theme.ink.opacity(0.5)).frame(height: 6)
                        }
                        .frame(width: 200, height: 220)
                        .background(model.hanoiSelected == peg ? Theme.sun.opacity(0.18) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(KeyEquivalent(Character("\(peg + 1)")), modifiers: [])
                }
            }
            HStack {
                Text("Moves: \(game.moves)   ·   Best possible: \(game.minimumMoves)")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(game.moves <= game.minimumMoves ? Theme.ink : Theme.coral)
                Spacer()
                QuietButton(title: "Start over", symbol: "arrow.counterclockwise", action: model.restartHanoi)
            }
            Text("Tap a peg to lift its top disc, then tap where it goes. (Keys 1, 2, 3 work too.)")
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.ink.opacity(0.6))
        }
    }
}

/// A square board of cells with a number pad, shared by KenKen and the magic square.
struct NumberPad: View {
    var values: [Int]
    var pick: (Int?) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(values, id: \.self) { value in
                Button { pick(value) } label: {
                    Text("\(value)")
                        .font(Theme.rounded(22, .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(Theme.violet, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            Button { pick(nil) } label: {
                Image(systemName: "delete.left.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 46, height: 46)
                    .background(Theme.paper, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }
}

struct KenKenView: View {
    @Bindable var model: GameModel
    var board: KenKenPuzzle

    let cell: CGFloat = 78

    var body: some View {
        let n = board.size
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<n, id: \.self) { r in
                        HStack(spacing: 0) {
                            ForEach(0..<n, id: \.self) { c in
                                let index = r * n + c
                                Button {
                                    model.selectedCell = index
                                } label: {
                                    Text(model.cells.indices.contains(index) ? (model.cells[index].map(String.init) ?? "") : "")
                                        .font(Theme.rounded(34, .heavy))
                                        .foregroundStyle(Theme.ink)
                                        .frame(width: cell, height: cell)
                                        .background(model.selectedCell == index ? Theme.sun.opacity(0.35) : Color.white)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                Canvas { context, _ in
                    var thin = Path()
                    var thick = Path()
                    for r in 0..<n {
                        for c in 0..<n {
                            let index = r * n + c
                            let cage = board.cageIndex(of: index)
                            let x = CGFloat(c) * cell
                            let y = CGFloat(r) * cell
                            // Right edge
                            if c + 1 < n {
                                var edge = Path()
                                edge.move(to: CGPoint(x: x + cell, y: y))
                                edge.addLine(to: CGPoint(x: x + cell, y: y + cell))
                                if board.cageIndex(of: index + 1) == cage { thin.addPath(edge) } else { thick.addPath(edge) }
                            }
                            // Bottom edge
                            if r + 1 < n {
                                var edge = Path()
                                edge.move(to: CGPoint(x: x, y: y + cell))
                                edge.addLine(to: CGPoint(x: x + cell, y: y + cell))
                                if board.cageIndex(of: index + n) == cage { thin.addPath(edge) } else { thick.addPath(edge) }
                            }
                        }
                    }
                    context.stroke(thin, with: .color(Theme.ink.opacity(0.2)), lineWidth: 1)
                    context.stroke(thick, with: .color(Theme.ink), lineWidth: 4)
                    context.stroke(Path(CGRect(x: 0, y: 0, width: CGFloat(n) * cell, height: CGFloat(n) * cell)), with: .color(Theme.ink), lineWidth: 6)
                    for cage in board.cages {
                        let index = cage.labelCell
                        let point = CGPoint(x: CGFloat(index % n) * cell + 6, y: CGFloat(index / n) * cell + 4)
                        context.draw(Text(cage.label).font(Theme.rounded(15, .heavy)).foregroundColor(Theme.violet), at: point, anchor: .topLeading)
                    }
                }
                .frame(width: CGFloat(n) * cell, height: CGFloat(n) * cell)
                .allowsHitTesting(false)
            }
            .frame(width: CGFloat(n) * cell, height: CGFloat(n) * cell)
            NumberPad(values: Array(1...n)) { model.put($0) }
            Text("Tap a square, then a number.")
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.ink.opacity(0.6))
        }
    }
}

struct MagicSquareView: View {
    @Bindable var model: GameModel
    var square: MagicSquarePuzzle

    let cell: CGFloat = 84

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { r in
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { c in
                                cellButton(r * 3 + c)
                            }
                            lineTotal([r * 3, r * 3 + 1, r * 3 + 2])
                        }
                    }
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { c in
                            lineTotal([c, c + 3, c + 6]).frame(width: cell)
                        }
                        Spacer().frame(width: 44)
                    }
                }
            }
            NumberPad(values: Array(square.numbers)) { model.put($0) }
            Text("Totals show when a line is full. Green means it matches the others.")
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.ink.opacity(0.6))
        }
    }

    private func cellButton(_ index: Int) -> some View {
        let given = square.givens[index]
        let value = model.cells.indices.contains(index) ? model.cells[index] : nil
        return Button {
            if !given { model.selectedCell = index }
        } label: {
            Text(value.map(String.init) ?? "")
                .font(Theme.rounded(34, .heavy))
                .foregroundStyle(given ? Theme.violet : Theme.ink)
                .frame(width: cell, height: cell)
                .background(model.selectedCell == index ? Theme.sun.opacity(0.35) : (given ? Theme.paper : Color.white), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.ink.opacity(0.25), lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private func lineTotal(_ indexes: [Int]) -> some View {
        let values = indexes.compactMap { model.cells.indices.contains($0) ? model.cells[$0] : nil }
        let full = values.count == 3
        let total = values.reduce(0, +)
        return Text(full ? "\(total)" : "")
            .font(Theme.rounded(18, .heavy))
            .foregroundStyle(full && total == square.magicTotal ? Theme.leaf : Theme.coral)
            .frame(width: 44, height: 28)
    }
}

struct LogicGridView: View {
    @Bindable var model: GameModel
    var grid: LogicGridPuzzle

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Clues").font(Theme.rounded(19, .heavy)).foregroundStyle(Theme.ink)
                ForEach(Array(grid.clueTexts.enumerated()), id: \.offset) { index, clue in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).").font(Theme.rounded(16, .heavy)).foregroundStyle(Theme.violet)
                        Text(clue).font(Theme.rounded(16, .medium)).foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: 300, alignment: .leading)
            VStack(alignment: .leading, spacing: 16) {
                table(title: "Pets", items: grid.pets, pets: true)
                table(title: "Colors", items: grid.colors, pets: false)
            }
        }
    }

    private func table(title: String, items: [String], pets: Bool) -> some View {
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
            GridRow {
                Text(title).font(Theme.rounded(15, .heavy)).foregroundStyle(Theme.ink.opacity(0.6)).frame(width: 90, alignment: .leading)
                ForEach(items, id: \.self) { item in
                    Text(item).font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink).frame(width: 70)
                }
            }
            ForEach(0..<3, id: \.self) { person in
                GridRow {
                    Text(grid.people[person]).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink).frame(width: 90, alignment: .leading)
                    ForEach(0..<3, id: \.self) { item in
                        let index = person * 3 + item
                        let mark = pets ? model.petMarks[index] : model.colorMarks[index]
                        Button {
                            model.cycleMark(pets: pets, index: index)
                        } label: {
                            Text(mark == .yes ? "✓" : (mark == .no ? "✗" : ""))
                                .font(Theme.rounded(26, .heavy))
                                .foregroundStyle(mark == .yes ? Theme.leaf : Theme.coral)
                                .frame(width: 70, height: 46)
                                .background(Theme.paper, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
#endif
