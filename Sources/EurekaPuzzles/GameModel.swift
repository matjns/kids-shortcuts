#if os(macOS)
import AppKit
import AVFoundation
import Foundation
import Observation
import EurekaCore

enum Screen: Equatable {
    case map
    case chapter(ChapterID)
    case puzzle
    case challengeOver
}

/// Where a puzzle came from, so "Next" knows where to go.
enum PlayMode: Equatable {
    case chapter(ChapterID)
    case challenge
}

@Observable
final class GameModel {
    var progress: PlayerProgress
    var screen: Screen = .map
    var mode: PlayMode = .chapter(.pairs)

    // The puzzle on screen
    var puzzle: Puzzle?
    var typed = ""
    var wrongTries = 0
    var hintsShown = 0
    var nudge: String?
    var startedAt = Date()
    var scratch = Scratchpad()
    var showScratch = false
    var pairing = PairingBoard(numbers: [])
    var hanoi = HanoiGame(discs: 3)
    var hanoiSelected: Int?
    var cells: [Int?] = []
    var selectedCell: Int?
    var petMarks: [GridMark] = Array(repeating: .blank, count: 9)
    var colorMarks: [GridMark] = Array(repeating: .blank, count: 9)
    var finished = false

    // After a puzzle
    var result: RecordResult?
    var lastStats: SolveStats?
    var showEureka = false
    var levelChange: LevelChange?

    var challenge: ChallengeRun?
    var lastChallengeScore = 0
    var newChallengeBest = false

    var saveWarning: String?

    private let store: ProgressStore
    private let speaker = AVSpeechSynthesizer()

    init(store: ProgressStore? = nil) {
        if let store {
            self.store = store
        } else {
            self.store = ProgressStore(directory: GameModel.supportDirectory())
        }
        progress = self.store.load()
    }

    static func supportDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("Eureka Puzzles", isDirectory: true)
    }

    var level: Level { progress.level }

    // MARK: Navigation

    func goToMap() {
        stopSpeaking()
        screen = .map
        puzzle = nil
        challenge = nil
        showEureka = false
    }

    func open(_ chapter: ChapterID) {
        guard progress.isUnlocked(chapter) else { return }
        screen = .chapter(chapter)
    }

    func start(_ kind: PuzzleKind) {
        mode = .chapter(kind.chapter)
        load(PuzzleGenerator.make(kind, level: level, seed: UInt64.random(in: 1...UInt64.max)))
    }

    func startChallenge() {
        let run = ChallengeRun(level: level, chapters: progress.unlockedChapters, seed: UInt64.random(in: 1...UInt64.max))
        challenge = run
        mode = .challenge
        if let first = run.current { load(first) }
    }

    private func load(_ next: Puzzle) {
        stopSpeaking()
        puzzle = next
        typed = ""
        wrongTries = 0
        hintsShown = 0
        nudge = nil
        startedAt = Date()
        scratch = Scratchpad()
        showScratch = false
        hanoiSelected = nil
        selectedCell = nil
        finished = false
        result = nil
        showEureka = false
        petMarks = Array(repeating: .blank, count: 9)
        colorMarks = Array(repeating: .blank, count: 9)
        switch next.visual {
        case .pairing(let numbers):
            pairing = PairingBoard(numbers: numbers)
        case .hanoi(let discs):
            hanoi = HanoiGame(discs: discs)
        case .kenKen(let board):
            cells = Array(repeating: nil, count: board.size * board.size)
        case .magic(let square):
            cells = (0..<9).map { square.givens[$0] ? square.solution[$0] : nil }
        default:
            cells = []
        }
        screen = .puzzle
    }

    /// "Next" on the Eureka card.
    func next() {
        showEureka = false
        switch mode {
        case .challenge:
            if let run = challenge, let upcoming = run.current {
                load(upcoming)
            } else {
                endChallenge()
            }
        case .chapter(let chapter):
            guard let current = puzzle else { return goToMap() }
            let kinds = Chapter.chapter(chapter).kinds(for: level)
            if let index = kinds.firstIndex(of: current.kind), index + 1 < kinds.count {
                start(kinds[index + 1])
            } else {
                screen = .chapter(chapter)
                puzzle = nil
            }
        }
    }

    func playAgain() {
        guard let current = puzzle else { return }
        showEureka = false
        start(current.kind)
    }

    func leavePuzzle() {
        stopSpeaking()
        if mode == .challenge {
            endChallenge()
            return
        }
        if case .chapter(let chapter) = mode {
            screen = .chapter(chapter)
        } else {
            screen = .map
        }
        puzzle = nil
    }

    private func endChallenge() {
        let score = challenge?.score ?? 0
        lastChallengeScore = score
        newChallengeBest = score > progress.challengeBest
        progress.challengeBest = max(progress.challengeBest, score)
        persist()
        challenge = nil
        puzzle = nil
        showEureka = false
        screen = .challengeOver
    }

    // MARK: Answers

    func submitTyped() {
        guard let puzzle, !finished else { return }
        guard AnswerParser.integer(from: typed) != nil else {
            nudge = "Type a whole number, like 5050."
            return
        }
        if puzzle.check(typed: typed) {
            solved()
        } else {
            missed()
        }
    }

    func choose(_ index: Int) {
        guard let puzzle, !finished else { return }
        if puzzle.check(choice: index) {
            solved()
        } else {
            missed()
        }
    }

    private func missed() {
        wrongTries += 1
        let gentle = ["Not quite. Look for a shortcut!", "Close? Try a hint.", "Hmm, check it another way."]
        nudge = gentle[(wrongTries - 1) % gentle.count]
        if mode == .challenge {
            challenge?.wrongAnswer()
            if challenge?.isOver == true {
                finish(gaveUp: true)
            }
        }
    }

    func showHint() {
        guard let puzzle else { return }
        hintsShown = min(puzzle.hints.count, hintsShown + 1)
    }

    func giveUp() {
        finish(gaveUp: true)
    }

    private func solved() {
        nudge = nil
        finish(gaveUp: false)
    }

    private func finish(gaveUp: Bool) {
        guard let puzzle, !finished else { return }
        finished = true
        stopSpeaking()
        var steps = scratch.steps
        if case .hanoi = puzzle.visual {
            steps += max(0, hanoi.moves - hanoi.minimumMoves)
        }
        let stats = SolveStats(seconds: Date().timeIntervalSince(startedAt), steps: steps, wrongTries: wrongTries, hintsUsed: hintsShown, gaveUp: gaveUp)
        let recorded = progress.record(puzzle, stats: stats)
        lastStats = stats
        result = recorded
        if let change = recorded.levelChange {
            levelChange = change
        }
        if mode == .challenge {
            challenge?.finishCurrent(stars: recorded.award.stars)
        }
        persist()
        showEureka = true
    }

    // MARK: Boards

    func tapPeg(_ peg: Int) {
        guard !finished else { return }
        if let from = hanoiSelected {
            hanoiSelected = nil
            if from != peg && !hanoi.move(from: from, to: peg) {
                nudge = "A bigger disc can't sit on a smaller one."
            } else {
                nudge = nil
            }
            if hanoi.isSolved { solved() }
        } else if !hanoi.pegs[peg].isEmpty {
            hanoiSelected = peg
        }
    }

    func restartHanoi() {
        hanoi = HanoiGame(discs: hanoi.discs)
        hanoiSelected = nil
    }

    func put(_ value: Int?) {
        guard let cell = selectedCell, cells.indices.contains(cell), !finished, let puzzle else { return }
        if case .magic(let square) = puzzle.visual, square.givens[cell] { return }
        cells[cell] = value
        checkBoard()
    }

    func checkBoard() {
        guard let puzzle else { return }
        switch puzzle.visual {
        case .kenKen(let board):
            if board.isSolved(cells) { solved() } else if !cells.contains(where: { $0 == nil }) {
                nudge = "Every square is full, but something doesn't fit. Check each row, column and cage."
            }
        case .magic(let square):
            if square.isSolved(cells) { solved() } else if !cells.contains(where: { $0 == nil }) {
                nudge = "Full! But not every line makes the same total yet."
            }
        case .logicGrid(let grid):
            if grid.isSolved(petMarks: petMarks, colorMarks: colorMarks) { solved() }
        default:
            break
        }
    }

    func cycleMark(pets: Bool, index: Int) {
        guard !finished else { return }
        if pets {
            petMarks[index] = petMarks[index].next
        } else {
            colorMarks[index] = colorMarks[index].next
        }
        checkBoard()
    }

    // MARK: Read aloud

    func readAloud() {
        guard let puzzle else { return }
        if speaker.isSpeaking {
            stopSpeaking()
            return
        }
        let text = Speech.clean(puzzle.story + " " + puzzle.question)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.45
        speaker.speak(utterance)
    }

    func stopSpeaking() {
        if speaker.isSpeaking {
            speaker.stopSpeaking(at: .immediate)
        }
    }

    func persist() {
        do {
            try store.save(progress)
            saveWarning = nil
        } catch {
            saveWarning = "Progress couldn't be saved on this Mac."
        }
    }
}

enum Speech {
    /// Make symbols sound right when read aloud.
    static func clean(_ text: String) -> String {
        text.replacingOccurrences(of: "…", with: " and so on up to ")
            .replacingOccurrences(of: "×", with: " times ")
            .replacingOccurrences(of: "÷", with: " divided by ")
            .replacingOccurrences(of: "−", with: " minus ")
            .replacingOccurrences(of: "_", with: " blank ")
    }
}
#endif
