# Dementia Mapper (`dmap`)

A **standalone Mudlet package** that maps and auto-explores the Achaea **Mnemosyne**
("tides of memory"). The Mnemosyne's incurable dementia (Creville's Legacy) **fakes the
GMCP room data** — exits and area name can point at real places while you're still inside —
so a normal mapper gets lost. `dmap` is dementia-tolerant: it routes over the graph it can
trust and self-corrects when a faked exit fails.

It's extracted from the LEVI combat system into a self-contained `dmap` namespace with **no
other dependencies** — it runs happily alongside LEVI or completely on its own.

## Install

Load `dmap_project/build/Dementia_Mapper.mpackage` in Mudlet (Package Manager → Install).
Nothing else to configure for mapping.

## What it does

- **Maps each ripple's 4×4 grid** as you walk, on its own coordinate grid (GMCP coords are
  faked, so it derives layout from the exit graph via BFS relayout).
- **Draggable mini-map window** — current room green, rooms with unexplored exits gold `?`,
  others grey. **Click a room to auto-walk there.** Shows only while you're in a ripple.
- **Dementia tolerance:** routing falls back from walked edges to the *reported-exit* graph,
  so a room stays reachable even when a faked exit drops its walked connection. A wrong
  (faked) exit just fails the move — and `Room.WrongDir` condemns it instantly.
- **Auto-explore** (Tier 2): sweeps the grid room-by-room, backtracks to unexplored exits,
  patrols for the boss on boss ripples, and pauses at the boon screen so you can pick + wade.
  `GO` (after wading) resumes automatically.

## Commands (`dmap ...`)

| Command | Effect |
|---|---|
| `dmap map [on\|off]` | Toggle / set the mini-map window |
| `dmap show` / `dmap hide` | Force the window on/off |
| `dmap status` | Dump map state (rooms, bounds, current) |
| `dmap explore [on\|off\|status]` | Start / stop / inspect the auto-sweep |
| `dmap attack <command>` | Set the auto-explore combat command (or `off`) |

## Combat: map-only vs auto-combat

The explorer **navigates**; combat is a pluggable hook, so `dmap` never needs class knowledge.

- **Map-only (default):** no attack set → the sweep **waits for you to clear each room**, then
  moves on. Great as a pure guide.
- **Auto-combat:** set an attack command with `@id` / `@name` placeholders, e.g.
  `dmap attack curse @id` or `dmap attack kill @name`. While a room has denizens the explorer
  re-sends it every ~1.5s (off-balance sends are simply rejected by the game). Use a
  balance-safe command (your own kill alias / a queued attack) for best results.
  `dmap attack off` returns to map-only.

Own pets/summons never count as targets — add their names to `dmap.config.ownDenizens`
(`dmap.config.ownDenizens["a war hound"] = true`).

## How the "room clear" signal works

`dmap` tracks room denizens itself from `gmcp.Char.Items`, using the `attrib` **flag-set**
correctly: a target is a live monster (`m`) that is not dead (`d`) and not loyal/protected
(`x`). It negotiates `Char.Items` on connect. "Room clear" = no live, targetable denizens.

## Build (for developers)

```
./dmap_build.sh            # dmap_src/ -> dmap_project/ -> Dementia_Mapper.mpackage
./dmap_build.sh --convert-only
lua dmap_src/tests/test_dmap.lua   # ported-logic unit tests
```

Source lives under `dmap_src/` (`scripts/`, `triggers/`, `aliases/`) — same YAML-header +
Muddler pipeline as LEVI, built with `--package-name Dementia_Mapper`. The dementia-tolerant
map + explorer are ports of LEVI's `mnemosyne/005_Ripple_Map` + `008_Explorer`, decoupled from
the basher (navigation only; combat via the hook above).

### Releasing

CI (`.github/workflows/dmap.yml`) builds the `.mpackage` and publishes a GitHub Release on any
`dmap-v*` tag — a separate namespace from LEVI's `v*`, so the two never cross-trigger. To cut a
release users can download directly:

```
# 1. bump the version
echo 0.1.1 > dmap_version.txt          # must match the tag
git commit -am "dmap 0.1.1"
# 2. tag + push (CI validates version==tag, builds, and attaches Dementia_Mapper.mpackage)
git tag dmap-v0.1.1
git push origin main dmap-v0.1.1
```
