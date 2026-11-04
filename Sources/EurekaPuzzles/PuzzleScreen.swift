#if os(macOS)
import SwiftUI
import EurekaCore

struct PuzzleScreen: View {
    @Bindable var model: GameModel
    var puzzle: Puzzle

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            topBar
            HStack(alignment: .top, spacing: 22) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(puzzle.story)
                        .font(Theme.rounded(model.level == .explorer ? 24 : 21, .medium))
                        .foregroundStyle(Theme.ink.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(puzzle.question)
                        .font(Theme.rounded(model.level == .explorer ? 32 : 28, .heavy))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                    if puzzle.visual != .none {
                        PuzzleVisualView(model: model, puzzle: puzzle)
                            .frame(maxWidth: .infinity, minHeight: 260)
                            .card()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                AnswerPanel(model: model, puzzle: puzzle)
                    .frame(width: 360)
            }
            Spacer(minLength: 0)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            QuietButton(title: model.mode == .challenge ? "End" : "Back", symbol: "chevron.left") {
                model.leavePuzzle()
            }
            .keyboardShortcut(.escape, modifiers: [])
            Text(puzzle.title)
                .font(Theme.rounded(30, .heavy))
                .foregroundStyle(Theme.chapterColor(puzzle.chapter))
            Spacer()
            if let run = model.challenge {
                Pill(symbol: "bolt.fill", tint: Theme.violet, text: "\(min(run.index + 1, ChallengeRun.length)) of \(ChallengeRun.length)")
                Pill(symbol: "heart.fill", tint: Theme.coral, text: "\(run.lives)")
                Pill(symbol: "star.fill", tint: Theme.sun, text: "\(run.score)")
            }
            QuietButton(title: "Read to me", symbol: "speaker.wave.2.fill", action: model.readAloud)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let seconds = Int(context.date.timeIntervalSince(model.startedAt))
                Pill(symbol: "timer", tint: seconds <= puzzle.parSeconds ? Theme.leaf : Theme.ink.opacity(0.4), text: "\(seconds / 60):" + String(format: "%02d", seconds % 60))
            }
        }
    }
}

struct AnswerPanel: View {
    @Bindable var model: GameModel
    var puzzle: Puzzle
    @FocusState var fieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            answerArea
                .card()

            if let nudge = model.nudge {
                Text(nudge)
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.coral)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Hints").font(Theme.rounded(19, .heavy)).foregroundStyle(Theme.ink)
                    Spacer()
                    if model.hintsShown < puzzle.hints.count {
                        QuietButton(title: model.hintsShown == 0 ? "Nudge me" : "Another nudge", symbol: "lightbulb.fill", action: model.showHint)
                            .keyboardShortcut("h", modifiers: [.command])
                    }
                }
                ForEach(0..<model.hintsShown, id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb").foregroundStyle(Theme.sun)
                        Text(puzzle.hints[index])
                            .font(Theme.rounded(16, .medium))
                            .foregroundStyle(Theme.ink.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if model.hintsShown == 0 {
                    Text("Hints nudge you toward the trick. They never tell you the answer.")
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.ink.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .card()

            if case .number = puzzle.answer {
                ScratchpadToggle(model: model, puzzle: puzzle)
            }

            if model.wrongTries >= 2 || model.hintsShown == puzzle.hints.count {
                QuietButton(title: "Show me the trick", symbol: "sparkles", action: model.giveUp)
            }
        }
    }

    @ViewBuilder
    private var answerArea: some View {
        switch puzzle.answer {
        case .number:
            VStack(alignment: .leading, spacing: 12) {
                Text("Your answer").font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink.opacity(0.6))
                TextField("Type a number", text: $model.typed)
                    .textFieldStyle(.plain)
                    .font(Theme.rounded(38, .heavy))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.paper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .focused($fieldFocused)
                    .onSubmit(model.submitTyped)
                // Return in the field submits, so the button has no shortcut of its own.
                BigButton(title: "Check", fill: Theme.leaf, action: model.submitTyped)
            }
            .onAppear { fieldFocused = true }
        case let .choice(options, _):
            VStack(alignment: .leading, spacing: 10) {
                Text("Pick one").font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink.opacity(0.6))
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Button {
                        model.choose(index)
                    } label: {
                        HStack {
                            Text("\(index + 1)")
                                .font(Theme.rounded(16, .heavy))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(Theme.violet.opacity(0.8), in: Circle())
                            Text(option)
                                .font(Theme.rounded(28, .heavy))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Theme.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: [])
                }
            }
        case .board:
            VStack(alignment: .leading, spacing: 8) {
                Text("Solve the board").font(Theme.rounded(22, .heavy)).foregroundStyle(Theme.ink)
                Text("It checks itself the moment it's right.")
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.ink.opacity(0.65))
            }
        }
    }
}

struct ScratchpadToggle: View {
    @Bindable var model: GameModel
    var puzzle: Puzzle

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                model.showScratch.toggle()
            } label: {
                HStack {
                    Image(systemName: "plusminus.circle.fill")
                    Text(model.showScratch ? "Hide adding machine" : "Adding machine")
                    Spacer()
                    Text("\(model.scratch.steps) step\(model.scratch.steps == 1 ? "" : "s")")
                        .foregroundStyle(model.scratch.steps <= puzzle.parSteps ? Theme.leaf : Theme.coral)
                }
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.ink)
            }
            .buttonStyle(.plain)
            if model.showScratch {
                ScratchpadView(model: model)
                Text("Clever solvers use \(puzzle.parSteps) step\(puzzle.parSteps == 1 ? "" : "s") or fewer.")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.ink.opacity(0.55))
            }
        }
        .card()
    }
}

struct ScratchpadView: View {
    @Bindable var model: GameModel

    var body: some View {
        VStack(spacing: 8) {
            Text(model.scratch.error ?? Format.number(model.scratch.currentValue ?? 0))
                .font(Theme.rounded(28, .heavy))
                .foregroundStyle(model.scratch.error == nil ? Theme.ink : Theme.coral)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.paper, in: RoundedRectangle(cornerRadius: 10))
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                GridRow {
                    key("7") { model.scratch.digit(7) }
                    key("8") { model.scratch.digit(8) }
                    key("9") { model.scratch.digit(9) }
                    key("÷", Theme.violet) { model.scratch.operation(.divide) }
                }
                GridRow {
                    key("4") { model.scratch.digit(4) }
                    key("5") { model.scratch.digit(5) }
                    key("6") { model.scratch.digit(6) }
                    key("×", Theme.violet) { model.scratch.operation(.multiply) }
                }
                GridRow {
                    key("1") { model.scratch.digit(1) }
                    key("2") { model.scratch.digit(2) }
                    key("3") { model.scratch.digit(3) }
                    key("−", Theme.violet) { model.scratch.operation(.subtract) }
                }
                GridRow {
                    key("C", Theme.coral) { model.scratch.clear() }
                    key("0") { model.scratch.digit(0) }
                    key("=", Theme.leaf) { model.scratch.equals() }
                    key("+", Theme.violet) { model.scratch.operation(.add) }
                }
            }
            if let line = model.scratch.tape.last {
                Text(line)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Theme.ink.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            Button("Use this number") {
                if let value = model.scratch.currentValue { model.typed = String(value) }
            }
            .font(Theme.rounded(14, .semibold))
        }
    }

    private func key(_ label: String, _ tint: Color = Theme.ink, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Theme.rounded(20, .heavy))
                .foregroundStyle(tint == Theme.ink ? Theme.ink : .white)
                .frame(width: 64, height: 40)
                .background(tint == Theme.ink ? Theme.paper : tint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct EurekaOverlay: View {
    @Bindable var model: GameModel
    var puzzle: Puzzle
    var result: RecordResult

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(result.award.solved ? "Eureka!" : "Here's the trick")
                    .font(Theme.rounded(54, .heavy))
                    .foregroundStyle(result.award.solved ? Theme.violet : Theme.teal)
                if result.award.solved {
                    StarRow(filled: result.award.stars, size: 44)
                    HStack(spacing: 18) {
                        Label("Solved", systemImage: "checkmark.circle.fill").foregroundStyle(Theme.leaf)
                        Label("Speedy", systemImage: result.award.speedy ? "hare.fill" : "hare").foregroundStyle(result.award.speedy ? Theme.leaf : Theme.ink.opacity(0.35))
                        Label("Elegant", systemImage: result.award.elegant ? "sparkles" : "sparkle").foregroundStyle(result.award.elegant ? Theme.leaf : Theme.ink.opacity(0.35))
                    }
                    .font(Theme.rounded(17, .bold))
                }
                if let stats = model.lastStats {
                    Text(result.award.message(for: puzzle, stats: stats))
                        .font(Theme.rounded(19, .semibold))
                        .foregroundStyle(Theme.ink.opacity(0.8))
                }
                Text(puzzle.eureka)
                    .font(Theme.rounded(22, .medium))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .background(Theme.paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                Text("The long way: \(puzzle.longWay).")
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.ink.opacity(0.6))
                if result.streak >= 2 {
                    Label("\(result.streak) in a row!", systemImage: "flame.fill")
                        .font(Theme.rounded(18, .heavy))
                        .foregroundStyle(Theme.coral)
                }
                if let unlocked = result.unlocked {
                    Label("New chapter open: \(Chapter.chapter(unlocked).title)", systemImage: "lock.open.fill")
                        .font(Theme.rounded(18, .heavy))
                        .foregroundStyle(Theme.chapterColor(unlocked))
                }
                HStack(spacing: 14) {
                    BigButton(title: "Next", fill: Theme.violet, action: model.next)
                        .keyboardShortcut(.defaultAction)
                    if model.mode != .challenge {
                        BigButton(title: "New numbers", fill: Theme.teal, action: model.playAgain)
                    }
                }
            }
            .padding(34)
            .frame(maxWidth: 680)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(radius: 20)
        }
    }
}

struct LevelChangeOverlay: View {
    var change: LevelChange
    var dismiss: () -> Void
    @State var pop = false

    static func burst(_ index: Int, out: Bool) -> CGSize {
        guard out else { return .zero }
        let angle: Double = Double(index) * Double.pi / 6
        return CGSize(width: cos(angle) * 150, height: sin(angle) * 110)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 18) {
                switch change {
                case .up(let level):
                    ZStack {
                        ForEach(0..<12, id: \.self) { index in
                            Image(systemName: "star.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(Theme.pairColors[index % Theme.pairColors.count])
                                .offset(LevelChangeOverlay.burst(index, out: pop))
                                .opacity(pop ? 1 : 0)
                        }
                        Image(systemName: "mountain.2.fill")
                            .font(.system(size: 90))
                            .foregroundStyle(Theme.levelColor(level))
                            .scaleEffect(pop ? 1 : 0.4)
                    }
                    .frame(height: 230)
                    Text("Level up!").font(Theme.rounded(64, .heavy)).foregroundStyle(Theme.violet)
                    Text("You're a \(level.title) now.").font(Theme.rounded(30, .bold)).foregroundStyle(Theme.ink)
                    Text(level.blurb).font(Theme.rounded(20, .medium)).foregroundStyle(Theme.ink.opacity(0.75))
                case .down(let level):
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Theme.leaf)
                    Text("Warm-up time").font(Theme.rounded(48, .heavy)).foregroundStyle(Theme.teal)
                    Text("Let's do some \(level.title) puzzles for a bit. Your stars are all still here.")
                        .font(Theme.rounded(22, .medium))
                        .foregroundStyle(Theme.ink.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                BigButton(title: "Let's go!", fill: Theme.violet, action: dismiss)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(40)
            .frame(maxWidth: 640)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.55)) { pop = true }
        }
    }
}
#endif
