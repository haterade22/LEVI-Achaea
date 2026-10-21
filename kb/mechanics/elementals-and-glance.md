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
Narrowing your eyes, you squint off toward the northeast.
A rock tunnel. (indoors)
You can see no further.
```
- Header, room name, then "You can see no further." No exits line, so trigger 063 is not fed.
  No denizens shown in this sample: unknown whether the room was empty or SQUINT never shows them.
- **Confidence:** CONFIRMED (live).

## Open

- The long description of ONE greater elemental (needed to see two greaters of DIFFERENT kinds in
  a glance) has never been captured.
- SQUINT into a room WITH denizens (does it list them?). The package does not use SQUINT.
