# Launched into the sky

An enemy effect throws us into the air, out of reach of the fight on the ground. We answer with
LAND (since v4.7.491).

## The lines (LOG: `raw/logs/ours/2026-11-03_102828_Harkon.log`, rows 500/503, 1575/1578, 7299/7302)

    A single, piercing note emanates from Dunn, a sound to set teeth on edge and glass to shattering.
    A violent force suddenly takes hold of you and launches you high into the sky.

- The note line names the caster. The second line names "you", so it is the proof that we went up.
- The note alone does not launch us: at row 7127 Tabethys played the same note and no launch line
  followed. So the trigger keys on the second line.
- Dunn's class and the skill are not in `kb/` yet. The note came after "Dunn steadies himself in
  preparation to avoid arcane based attacks." (row 498), which is not a class line.
- About 0.16 s later, gmcp `Room.Info.name` reads `Flying above <room>` (row 1586: the launch at
  10:30:46.169, the room at 10:30:46.331).

## What it cost us (same log)

- Rows 1578-1586: gmcp read `Flying above A rotting treetrunk.` while the fight went on below. (The
  `lsr` sends after the launch drew "I cannot fathom the meaning of "lsr"": that is an unknown
  command, not a refusal in the air.)
- Row 7302: we were under aeon ("You move sluggishly into action.") and were still `Flying above`
  3 s later (row 7367).
- Other players come down with LAND. From the ground it looks like "<name> descends from above."
  (row 615). From the air it looks like "You see <name> wheel and dive earthwards, alighting easily
  on the ground far below." (row 1673).

## What our code does (v4.7.491)

- Trigger `801_Launched_Into_Sky` (`src_new/triggers/levi_ataxia/for_levi/leviticus/`) matches the
  second line as a substring. It is not `^`-anchored, because our own echoes print near it.
- `ataxia_launchedLand()` (`src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/032_Launch_Land.lua`)
  sends `land` at once, directly. It does not use the server queue, because the next round's
  `queue addclearfull` deletes a queued command.
- Every 0.5 s for 6 s, while gmcp still says `Flying above`, it sends `land` again. This covers a
  LAND that the game refuses (balance, paralysis, aeon).
- It stays up during the SLC both-arms flee (`selfLimbDamage.bothArmsFlee`), which flies on purpose,
  and during a Mnemosyne flight (`ataxia.mnemosyne.swarm.flying`).

## Open

- The game's refusal lines for LAND (balance, paralysis) and whether LAND needs balance. None is in a log.
- Whether other launch effects (the Alchemist gravity overdraw, "throw a random person in the room
  into the sky") print the same line. If not, add their line to trigger 801.
