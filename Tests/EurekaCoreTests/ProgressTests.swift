import XCTest
import Foundation
@testable import EurekaCore

final class ProgressTests: XCTestCase {
    let clean = Outcome(stars: 3, clean: true, struggled: false)
    let rough = Outcome(stars: 0, clean: false, struggled: true)
    let okay = Outcome(stars: 1, clean: false, struggled: false)

    func testEveryoneStartsAsAnExplorer() {
        XCTAssertEqual(PlayerProgress.fresh.level, .explorer)
        XCTAssertEqual(LevelCoach().level, .explorer)
    }

    func testLevelsUpAfterMastery() {
        var coach = LevelCoach()
        for _ in 0..<9 { XCTAssertNil(coach.record(clean)) }
        XCTAssertEqual(coach.progressToNextLevel, 1)
        XCTAssertEqual(coach.record(clean), .up(.adventurer))
        XCTAssertEqual(coach.level, .adventurer)
        XCTAssertTrue(coach.recent.isEmpty)
        XCTAssertEqual(coach.progressToNextLevel, 0)
        for _ in 0..<9 { _ = coach.record(clean) }
        XCTAssertEqual(coach.record(clean), .up(.challenger))
        for _ in 0..<20 { XCTAssertNil(coach.record(clean)) }
        XCTAssertEqual(coach.level, .challenger)
    }

    func testNeedsMostlyCleanSolves() {
        var coach = LevelCoach()
        for index in 0..<30 { _ = coach.record(index % 3 == 0 ? okay : clean) }
        XCTAssertEqual(coach.level, .explorer, "two-thirds clean isn't mastery yet")
    }

    func testStepsDownGentlyOnlyWhenStrugglingALot() {
        var coach = LevelCoach(level: .challenger)
        for _ in 0..<3 { XCTAssertNil(coach.record(rough)) }
        XCTAssertNil(coach.record(clean))
        XCTAssertNil(coach.record(okay))
        XCTAssertEqual(coach.record(rough), .down(.adventurer), "4 struggles in the last 6")
        var explorer = LevelCoach()
        for _ in 0..<20 { XCTAssertNil(explorer.record(rough)) }
        XCTAssertEqual(explorer.level, .explorer, "never below Explorer")
    }

    func testStars() {
        let puzzle = PuzzleGenerator.make(.teachersTrick, level: .challenger, seed: 1)
        XCTAssertEqual(StarAward.award(for: puzzle, stats: SolveStats(seconds: 10, steps: 1)).stars, 3)
        XCTAssertEqual(StarAward.award(for: puzzle, stats: SolveStats(seconds: 500, steps: 1)).stars, 2)
        XCTAssertEqual(StarAward.award(for: puzzle, stats: SolveStats(seconds: 10, steps: 99)).stars, 2, "brute force loses the elegance star")
        XCTAssertEqual(StarAward.award(for: puzzle, stats: SolveStats(seconds: 500, steps: 99, hintsUsed: 3)).stars, 1)
        XCTAssertEqual(StarAward.award(for: puzzle, stats: SolveStats(seconds: 5, gaveUp: true)).stars, 0)
        XCTAssertTrue(SolveStats(seconds: 1, wrongTries: 3).isStruggle)
        XCTAssertFalse(SolveStats(seconds: 1, wrongTries: 1, hintsUsed: 1).isStruggle)
    }

    func testRecordingStreaksAndUnlocks() {
        var progress = PlayerProgress()
        XCTAssertEqual(progress.unlockedChapters, [.pairs])
        let kinds = Chapter.chapter(.pairs).kinds(for: .explorer)
        var unlocked: ChapterID?
        for (index, kind) in kinds.prefix(3).enumerated() {
            let puzzle = PuzzleGenerator.make(kind, level: .explorer, seed: UInt64(index))
            let result = progress.record(puzzle, stats: SolveStats(seconds: 5))
            XCTAssertEqual(result.award.stars, 3)
            XCTAssertTrue(result.newBest)
            XCTAssertEqual(result.streak, index + 1)
            unlocked = result.unlocked ?? unlocked
        }
        XCTAssertEqual(unlocked, .triangles)
        XCTAssertTrue(progress.isUnlocked(.triangles))
        XCTAssertFalse(progress.isUnlocked(.odds))
        XCTAssertEqual(progress.totalStars, 9)
        let again = progress.record(PuzzleGenerator.make(kinds[0], level: .explorer, seed: 9), stats: SolveStats(seconds: 5, wrongTries: 1))
        XCTAssertFalse(again.newBest)
        XCTAssertEqual(again.streak, 0)
        XCTAssertEqual(progress.bestStreak, 3)
    }

    func testChallengeRun() {
        var run = ChallengeRun(level: .adventurer, chapters: [.pairs, .triangles], seed: 42)
        XCTAssertEqual(run.puzzles.count, ChallengeRun.length)
        XCTAssertTrue(run.puzzles.allSatisfy { [.pairs, .triangles].contains($0.chapter) && !ChallengeRun.excluded.contains($0.kind) })
        XCTAssertEqual(run, ChallengeRun(level: .adventurer, chapters: [.pairs, .triangles], seed: 42))
        run.finishCurrent(stars: 3)
        XCTAssertEqual(run.score, 3)
        run.wrongAnswer(); run.wrongAnswer(); run.wrongAnswer()
        XCTAssertTrue(run.isOver)
        XCTAssertNil(run.current)
        let explorer = ChallengeRun(level: .explorer, chapters: [], seed: 1)
        XCTAssertTrue(explorer.puzzles.allSatisfy { $0.level == .explorer && $0.chapter == .pairs })
    }

    func testStoreRoundTripAndCorruptFile() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("eureka-tests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = ProgressStore(directory: folder)
        XCTAssertEqual(store.load(), .fresh)
        var progress = PlayerProgress()
        _ = progress.record(PuzzleGenerator.make(.pairUpTen, level: .explorer, seed: 1), stats: SolveStats(seconds: 3))
        progress.coach.setLevelForTesting(.adventurer)
        try store.save(progress)
        XCTAssertEqual(store.load(), progress)
        try Data("not json".utf8).write(to: store.fileURL)
        XCTAssertEqual(store.load(), .fresh)
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.backupURL.path))
    }
}
