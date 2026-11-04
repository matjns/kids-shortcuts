#if os(macOS)
import AppKit
import SwiftUI
import EurekaCore

struct RootView: View {
    @Bindable var model: GameModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
            switch model.screen {
            case .map:
                MapView(model: model)
            case .chapter(let id):
                ChapterView(model: model, chapter: Chapter.chapter(id))
            case .puzzle:
                if let puzzle = model.puzzle {
                    PuzzleScreen(model: model, puzzle: puzzle)
                } else {
                    MapView(model: model)
                }
            case .challengeOver:
                ChallengeOverView(model: model)
            }
            if model.showEureka, let puzzle = model.puzzle, let result = model.result {
                EurekaOverlay(model: model, puzzle: puzzle, result: result)
            }
            if let change = model.levelChange, !model.showEureka {
                LevelChangeOverlay(change: change) {
                    model.levelChange = nil
                }
            }
        }
        .preferredColorScheme(.light)
        .frame(minWidth: 1020, minHeight: 720)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                model.persist()
            }
        }
        .sheet(isPresented: $model.showGrownUps) {
            GrownUpsView(model: model)
        }
    }
}

struct MapView: View {
    @Bindable var model: GameModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 18), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Eureka!")
                        .font(Theme.rounded(60, .heavy))
                        .foregroundStyle(Theme.violet)
                        // Grown-ups: hold Option and triple-click the title.
                        .onTapGesture(count: 3) {
                            if NSEvent.modifierFlags.contains(.option) {
                                model.showGrownUps = true
                            }
                        }
                    Text("Every puzzle has a long way and a clever shortcut. Find the shortcut!")
                        .font(Theme.rounded(20, .medium))
                        .foregroundStyle(Theme.ink.opacity(0.75))
                }
                Spacer()
                LevelBadge(level: model.level, progress: model.progress.coach.progressToNextLevel)
            }

            HStack(spacing: 14) {
                Pill(symbol: "star.fill", tint: Theme.sun, text: "\(model.progress.totalStars) stars")
                Pill(symbol: "flame.fill", tint: Theme.coral, text: "Streak \(model.progress.currentStreak)  ·  best \(model.progress.bestStreak)")
                Pill(symbol: "trophy.fill", tint: Theme.violet, text: "Challenge best \(model.progress.challengeBest)")
                Spacer()
                if let warning = model.saveWarning {
                    Text(warning).font(Theme.rounded(14, .medium)).foregroundStyle(Theme.coral)
                }
            }

            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(Chapter.all, id: \.id) { chapter in
                    ChapterCard(chapter: chapter, level: model.level, progress: model.progress) {
                        model.open(chapter.id)
                    }
                }
            }

            HStack {
                Spacer()
                Button(action: model.startChallenge) {
                    HStack(spacing: 12) {
                        Image(systemName: "bolt.fill")
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Challenge").font(Theme.rounded(26, .heavy))
                            Text("8 mixed puzzles · 3 lives").font(Theme.rounded(15, .medium))
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(LinearGradient(colors: [Theme.coral, Theme.violet], startPoint: .leading, endPoint: .trailing), in: Capsule())
                }
                .buttonStyle(.plain)
                .keyboardShortcut("c", modifiers: [])
                Spacer()
            }
        }
        .padding(36)
        .frame(maxWidth: 1180)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LevelBadge: View {
    var level: Level
    var progress: Double

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "mountain.2.fill")
                Text(level.title)
            }
            .font(Theme.rounded(22, .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(Theme.levelColor(level), in: Capsule())
            if let next = level.next {
                ProgressView(value: progress)
                    .tint(Theme.levelColor(next))
                    .frame(width: 200)
                Text("Next: \(next.title)")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.ink.opacity(0.6))
            } else {
                Text("Top level!")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.ink.opacity(0.6))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct ChapterCard: View {
    var chapter: Chapter
    var level: Level
    var progress: PlayerProgress
    var action: () -> Void

    var body: some View {
        let unlocked = progress.isUnlocked(chapter.id)
        let kinds = chapter.kinds(for: level)
        let earned = kinds.reduce(0) { $0 + progress.stars(for: $1) }
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: unlocked ? chapter.symbol : "lock.fill")
                        .font(.system(size: 30, weight: .bold))
                    Spacer()
                    Text("\(chapter.id.rawValue)")
                        .font(Theme.rounded(18, .heavy))
                        .opacity(0.7)
                }
                Text(chapter.title)
                    .font(Theme.rounded(23, .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(unlocked ? chapter.bigIdea : "Solve \(PlayerProgress.solvesToUnlock) puzzles in the chapter before to open this one.")
                    .font(Theme.rounded(14, .medium))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0.9)
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                    Text("\(earned) / \(kinds.count * 3)")
                }
                .font(Theme.rounded(15, .bold))
            }
            .foregroundStyle(.white)
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
            .background(Theme.chapterColor(chapter.id).opacity(unlocked ? 1 : 0.35), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .accessibilityLabel(unlocked ? "\(chapter.title). \(earned) stars." : "\(chapter.title). Locked.")
    }
}

struct ChapterView: View {
    @Bindable var model: GameModel
    var chapter: Chapter

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                QuietButton(title: "Map", symbol: "map.fill", action: model.goToMap)
                    .keyboardShortcut(.escape, modifiers: [])
                Spacer()
                LevelBadge(level: model.level, progress: model.progress.coach.progressToNextLevel)
            }
            HStack(spacing: 14) {
                Image(systemName: chapter.symbol)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Theme.chapterColor(chapter.id))
                VStack(alignment: .leading, spacing: 4) {
                    Text(chapter.title).font(Theme.rounded(44, .heavy)).foregroundStyle(Theme.ink)
                    Text("Big idea: \(chapter.bigIdea)").font(Theme.rounded(19, .medium)).foregroundStyle(Theme.ink.opacity(0.75))
                }
            }
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    ForEach(Array(chapter.kinds(for: model.level).enumerated()), id: \.element) { index, kind in
                        let sample = PuzzleGenerator.make(kind, level: model.level, seed: 1)
                        Button {
                            model.start(kind)
                        } label: {
                            HStack(spacing: 16) {
                                Text("\(index + 1)")
                                    .font(Theme.rounded(26, .heavy))
                                    .foregroundStyle(.white)
                                    .frame(width: 52, height: 52)
                                    .background(Theme.chapterColor(chapter.id), in: Circle())
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(sample.title).font(Theme.rounded(22, .bold)).foregroundStyle(Theme.ink)
                                    StarRow(filled: model.progress.stars(for: kind))
                                }
                                Spacer()
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 34))
                                    .foregroundStyle(Theme.chapterColor(chapter.id))
                            }
                            .card()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .padding(36)
        .frame(maxWidth: 1100)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ChallengeOverView: View {
    @Bindable var model: GameModel

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 90))
                .foregroundStyle(Theme.violet)
            Text(model.newChallengeBest ? "New best!" : "Challenge done!")
                .font(Theme.rounded(52, .heavy))
                .foregroundStyle(Theme.ink)
            Text("You earned \(model.lastChallengeScore) stars. Best ever: \(model.progress.challengeBest).")
                .font(Theme.rounded(24, .medium))
                .foregroundStyle(Theme.ink.opacity(0.8))
            HStack(spacing: 16) {
                BigButton(title: "Play again", fill: Theme.violet, action: model.startChallenge)
                    .keyboardShortcut(.defaultAction)
                BigButton(title: "Map", fill: Theme.teal, action: model.goToMap)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct GrownUpsView: View {
    @Bindable var model: GameModel
    @Environment(\.dismiss) private var dismiss
    @State var pinned = false
    @State var chosen: Level = .explorer
    @State var confirmReset = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("For grown-ups").font(Theme.rounded(30, .heavy))
            Text("Everyone starts as an Explorer. The game moves up a level after 8 clean solves out of the last 10 (and about 2 stars each), and steps back down gently after 4 hard puzzles out of 6.")
                .font(Theme.rounded(15, .medium))
                .fixedSize(horizontal: false, vertical: true)
            Text("Right now: \(model.level.title)\(model.progress.coach.pinned ? " (pinned)" : "")")
                .font(Theme.rounded(17, .bold))
            Picker("Level", selection: $chosen) {
                ForEach(Level.allCases, id: \.self) { level in
                    Text(level.title).tag(level)
                }
            }
            .pickerStyle(.segmented)
            Toggle("Pin this level (no automatic moves)", isOn: $pinned)
            HStack {
                Button("Use this level") {
                    model.setLevel(chosen, pinned: pinned)
                }
                Spacer()
            }
            Divider()
            Toggle("Open every chapter", isOn: Binding(get: { model.progress.allChaptersOpen }, set: { model.setAllChaptersOpen($0) }))
            Divider()
            HStack {
                Button("Start over…", role: .destructive) { confirmReset = true }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 520)
        .onAppear {
            chosen = model.level
            pinned = model.progress.coach.pinned
        }
        .alert("Erase all stars and go back to Explorer?", isPresented: $confirmReset) {
            Button("Erase", role: .destructive) {
                model.resetEverything()
                dismiss()
            }
            Button("Keep", role: .cancel) {}
        }
    }
}
#endif
