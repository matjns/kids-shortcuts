# Eureka Puzzles

Eureka Puzzles is a Mac app of logic and number puzzles for kids who like math. Every puzzle can be solved the long way, by counting or adding everything up. Each one also has a shortcut, an "aha" idea, and the game rewards finding it.

- **8 chapters**, 6 or 7 puzzles each (51 in all), plus extra starter puzzles for younger players.
- **New numbers every time.** Each puzzle is made fresh, so "New numbers" gives the same idea with a different setup.
- **Pictures you can poke.** Pair up numbers, fold a staircase of dots, peel odd layers off a square, slide a square around a checkerboard, move Tower of Hanoi discs, fill in KenKen and magic squares, and mark a logic grid.
- **Hints nudge, they don't tell.** Three hints per puzzle. None of them gives the answer. After a few misses or all the hints, "Show me the trick" opens the Eureka card.
- **Stars:** one for solving, one for being quick, and one for being elegant. Elegant means using few steps on the built-in adding machine, or few extra moves in Tower of Hanoi, with at most one hint and one miss.
- **Streaks** and a **Challenge** mode: 8 mixed puzzles, 3 lives.
- **Read to me** speaks the story and question out loud, using the Mac's built-in voice.
- No ads, no network, no account.

## Levels: automatic, no picker

Everyone starts at **Explorer**: small numbers, more pictures, short sentences, and pick-one-of-four answers. Explorer adds making tens, doubles, counting by pairs, odd and even patterns, a 1–9 magic square, 3×3 KenKen, a 3×3 logic grid, and Tower of Hanoi with 3 discs.

The game moves up on its own:

| Level | Numbers | Answers |
| --- | --- | --- |
| Explorer | small (about ages 8–9) | pick one of four |
| Adventurer | medium, every puzzle | type the number |
| Challenger | big enough that only the trick works | type the number |

- **Level up:** after at least 10 puzzles at a level, if 8 of the last 10 were clean (no "show me", at most one miss and one hint) and they averaged 2 stars or more. A "Level up!" screen celebrates it.
- **Gentle step down:** only if 4 of the last 6 puzzles were a real struggle (gave up, 3 or more misses, or all 3 hints). It never goes below Explorer, and stars are never taken away.
- Progress, stars, streaks and level are remembered on this Mac.

### Grown-ups panel (hidden)

On the map screen, **hold Option and triple-click the "Eureka!" title**. The panel can:

- set the level by hand, and pin it so it doesn't change on its own,
- open every chapter at once,
- start over, after a confirmation, which clears all progress.

There is no password. The gesture just keeps it out of the way.

Chapters open in order: solving 3 different puzzles in a chapter opens the next one.

## Chapters

1. **Gauss's Pairs:** adding a long list by pairing the ends.
2. **Triangle Town:** 1 + 2 + … + n as half a rectangle; handshakes; stacks.
3. **Odd Squares:** adding odd numbers makes square numbers.
4. **Doubling Peaks:** 1 + 2 + 4 + … is one less than the next double; Tower of Hanoi; folding paper.
5. **Digit Detectives:** divisibility by 3 and 9, digital roots, missing digits.
6. **Pigeons & Parity:** the sock drawer, shared birthdays, odd and even, the checkerboard domino puzzle, the locker puzzle.
7. **Grid Galaxy:** squares on a board, rectangles in a grid, paths, pizza cuts, the painted cube.
8. **Logic Lab:** magic squares, KenKen, logic grids, finding the fake coin.

## Kids Computer

The Kids Computer launcher opens this app by bundle id `com.kidscomputer.shortcuts`. That works once `Eureka Puzzles.app` is in `/Applications`, or after it has been opened once. Command-Q quits. Closing the window quits too.

## Where progress is saved

Progress is one file on this Mac, `progress.json`, in an Application Support folder named `Eureka Puzzles`. The app is sandboxed, so macOS keeps it inside the app's container:

`~/Library/Containers/com.kidscomputer.shortcuts/Data/Library/Application Support/Eureka Puzzles/progress.json`

## Download

There is no download yet. The repo is private and no release has been published.

## Build it yourself

You need a Mac with macOS 14 or later, and Xcode 15 or later.

```bash
./build.sh test
./build.sh
```

`./build.sh test` runs the puzzle tests. They also run on Linux, anywhere Swift is installed. Every answer is checked against a brute-force count. `./build.sh` writes `build/Eureka Puzzles.app` and `dist/EurekaPuzzles-mac-universal.zip`.

The puzzles, scoring and levels live in `EurekaCore`. The window is the `EurekaPuzzles` target. App Store steps are in `docs/APP_STORE.md`.
