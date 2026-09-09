# Black Hole Minesweeper

![Black Hole Minesweeper title screen](assets/title-screen.png)

**Play Minesweeper against an alien Monte Carlo agent—and try to reach Earth first.**

Built by Dan during the pandemic, 2020–2021, after reading about Monte Carlo tree search in Sutton and Barto. Inspired by Z's fondness for Minesweeper. Revived and packaged for release in 2026.

## The mission

Navigate a field of black holes and complete the map before an alien agent. After you finish—or disappear into a black hole—the alien plays the same map. Its estimated black-hole probabilities appear as a heatmap.

- Easy: 5 × 5, with 3–4 black holes
- Medium: 8 × 8, with 7–10 black holes
- Hard: 12 × 12, with 15–18 black holes

Fewer moves wins. Time is recorded, but patience is usually the better navigation system.

## Play on Windows

The easiest route is the installer on the repository's **Releases** page (click link on the right). It installs the free MATLAB Runtime automatically; MATLAB and a MATLAB license are not required.

The first installation may take a while because the MATLAB Runtime is much larger than the game itself.

## Run from MATLAB

MATLAB R2021a or newer is recommended. The game uses base MATLAB functions and does not intentionally require add-on toolboxes.

1. Download and extract the repository.
2. Open the extracted folder in MATLAB.
3. Run:

   ```matlab
   BlackHoleMinesweeper
   ```

Controls:

- Left-click: reveal a sector
- Right-click: flag or unflag a black hole

## How the alien thinks

The agent is best described as a **Monte Carlo constraint solver inspired by MCTS**:

1. Each revealed numbered sector constrains the surrounding unknown sectors.
2. Overlapping constraints are grouped into connected systems.
3. The agent repeatedly samples candidate black-hole layouts and retains layouts consistent with the clues.
4. The fraction of retained layouts containing a black hole in each sector becomes its estimated probability.

It flags high-probability sectors, reveals low-probability sectors, and guesses when the clues are insufficient. It is not a textbook MCTS implementation, but that was the idea that sent the yak out to graze. :D

## Build the Windows installer

MATLAB Compiler is required to build, but not to play the packaged game. With MATLAB R2026a or a compatible release, run:

```matlab
build_windows
```

The helper creates the application under `release/build/` and a web installer under `release/installer/`.

## Project structure

```text
BlackHoleMinesweeper.m   Game entry point and alien solver
assets/                  Original replacement artwork for the public edition
build_windows.m          MATLAB Compiler packaging helper
```

## Credits and licenses

Code and game design: **Dan Egert**.  
Original spark: **Z**, who said she liked Minesweeper.

The code is released under the [MIT License](LICENSE). The public-edition artwork was generated specifically for this project and is described in [ASSET_LICENSE.md](ASSET_LICENSE.md). No third-party music, voice recording, or legacy media is included.

There is something pleasingly appropriate about recovering a game about navigating isolated sectors from a very isolated time.
