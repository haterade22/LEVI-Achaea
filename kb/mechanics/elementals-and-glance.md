---
topic: elementals-and-glance
confidence: mixed (tagged per claim)
sources:
  - kb/raw/logs/2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt
code:
  - src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/009_Swarm_Tactics.lua
  - src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/008_Explorer.lua
  - src_new/triggers/levi_ataxia/for_levi/leviticus/denizen_attacks_misc_lines/010_Denizen_Clean-up_2.lua
last_verified: 2026-10-21
---

# Elemental denizens, and what GLANCE shows of a room's denizens

Greater elementals hit hard, and in a Mnemosyne wade the user fights only ONE at a time
(user doctrine, 2026-10-21). The package isolates them with the swarm tactics and uses GLANCE to
see them before it walks in.

## Facts

### Elemental denizen names
- Seen: `a greater earth elemental`, `a lesser earth elemental`, `a greater fire elemental`,
  `a lesser fire elemental`, `a greater water elemental`, `a lesser water elemental`,
  `an unbound frost elemental`, `a colossal magma elemental` (a boss objective).
  No air elemental has been seen.
- **Confidence:** CONFIRMED (live: attack lines in `010_Denizen_Clean-up_2.lua`, World Tree log).
- **Code:** `S.GREATER_PATTERNS = { "greater %a+ elemental" }` (009) matches every greater kind
  and no lesser one.

### Greater earth elemental attacks
- "A greater earth elemental breaks a large chunk away from its rocky form and hurls it at you..."
- "As a greater earth elemental wraps a massive hand around your torso and squeezes you tightly,
  you feel it draining away your will to live."
- **Confidence:** CONFIRMED (live). **Source:** `010_Denizen_Clean-up_2.lua:72-80`.

### Room prose for several denizens of one kind
- Two or more of the same denizen print as ONE sentence in the room prose, mid-paragraph:
  "There are 2 greater fire elementals here." / "There are 3 lesser water elementals here."
  A single denizen prints its long description instead of its short name.
- **Confidence:** CONFIRMED (live, World Tree log lines 15, 653).
- **Code:** `M._greatersInText` (008) reads this sentence from a GLANCE block. Rows are joined
  first, because the server wrap can split the sentence.

### GLANCE
- `GLANCE <direction>` prints "Glancing to the <dir>, you see:", the neighbour's room name,
  its prose (denizens included), and its exits line. Free; no balance seen spent.
- **Confidence:** CONFIRMED (live sample in `008_Explorer.lua` header comment).

### A denizen's shield going up
- "A nearly invisible magical shield forms around Celepharn, High Priest of Life."
- **Confidence:** CONFIRMED (live, user, 2026-10-21).
- **Code:** trigger 336 sets `ataxiaBasher.shielded` and, since v4.7.431, calls
  `ataxiaBasher_shieldRaised()` so the swing already queued is replaced by the raze round.

### GLANCE while blind (live, user, 2026-10-21)
```
Glancing to the south, you see:
A corridor inside the Gnoll fortress. (indoors)
A mysterious entity abides.
You see exits leading north and east.
```
- Blind WITHOUT mindseye, the glanced room shows "A mysterious entity abides." in place of its
  denizens (the same line the MINDSEYE keeper notes for our own room).
- Blind WITH mindseye up, a glance reads the same as when not blind (user, 2026-10-21: "without
  blind and mindseye is the same thing" / "yes, so it would be the same").
- **Code:** since v4.7.432 `M._glanceWanted` (008) skips the glance only while blind AND mindseye
  is down. The keeper in `deffing/007` touches mindseye whenever we are blind.
- **Confidence:** CONFIRMED (live line; user statement for mindseye).

### SQUINT (live, user, 2026-10-21)
```
Narrowing your eyes, you squint off toward the southeast.
Upon broken cliffs.
The sky darkens with the onset of night. The ground is slick with ice. The area is ablaze! A half-formed elemental of
molten lava crawls slowly across the ground.
Atop a jagged ridge.
The sky darkens with the onset of night. The ground is slick with ice. The area is ablaze!
You can see no further.
```
- SQUINT walks a straight line: for EACH room in that direction it prints the room name and its
  prose, denizens included, until "You can see no further." Here: two rooms deep. No exits line, so
  trigger 063 is not fed. (An earlier sample, "A rock tunnel. (indoors)", was one empty room.)
- The first room's prose is the same as the GLANCE of that direction (sample below), minus the exits.
- **Confidence:** CONFIRMED (live). **Code:** not used.

### GLANCE prose also names room hazards (live, user, 2026-10-21)
```
Glancing to the southeast, you see:
Upon broken cliffs.
The sky darkens with the onset of night. The ground is slick with ice. The area is ablaze! A half-formed elemental of
molten lava crawls slowly across the ground.
You see exits leading northeast, southeast, and northwest.
```
- "The ground is slick with ice." and "The area is ablaze!" are in the glanced prose, before we enter.
  The code reads only the lava phrase today. The denizen sentence wraps mid-name (the reason
  `M._greatersInText` reads the joined rows).
- "A half-formed elemental of molten lava crawls slowly across the ground." is the long description
  of ONE denizen (short name not yet tied to it; it is not a "greater").
- **Confidence:** CONFIRMED (live).

## Open

- The long description of ONE greater elemental (needed to see two greaters of DIFFERENT kinds in
  a glance) has never been captured.
- The package does not use SQUINT. It could see greaters two rooms out; not wired.
