---
topic: classleads-2026-10-23
confidence: mixed (tagged per claim)
sources:
  - kb/raw/announcements/classleads_2026-10-23.txt
  - kb/raw/ab/crystalism_overload_2026-10-23.txt
  - kb/raw/ab/elementalism_pebble_2026-10-23.txt
  - kb/raw/ab/psionics_pulse_2026-10-23.txt
  - kb/raw/ab/woodlore_grapple_2026-10-23.txt
  - kb/raw/live/captures/kb_capture_2026-10-23_122952.txt
  - kb/raw/announcements/classleads_2026-10-23_part2.txt
  - kb/raw/players/cures-user-2026-10-23.txt
code:
  - src_new/scripts/levi_ataxia/levi/levi_scripts/serpent/002_Serpent_Offense.lua
  - src_new/scripts/levi_ataxia/levi/levi_scripts/mage/004_Magi_Offense.lua
  - src_new/triggers/levi_ataxia/for_levi/leviticus/striking/
  - src_new/triggers/levi_ataxia/for_levi/leviticus/expend_afflictions/
  - src_new/triggers/levi_ataxia/for_levi/leviticus/third-person_removes/
  - src_new/scripts/levi_ataxia/levi/ataxia/017_Affliction_Management.lua
last_verified: 2026-10-23
---

# Class-lead changes, 2026-10-23

The game's class-lead change post of 2026-10-23, one block per change, with what it means in a
fight and whether our code depends on the old behaviour. The announcement text is
**CONFIRMED (announcement)**: it states intent, and the live game wins where they differ. The
four new abilities that were pasted as `AB` output are **CONFIRMED (live)**.

The wiki-generated class pages (`kb/classes/`) predate this post. Each changed skill carries a
note there that points to this page. The open questions are rows #39-#49 in
[../CONFLICTS.md](../CONFLICTS.md).

Paths below are under `src_new/`. `...\leviticus` means `triggers\levi_ataxia\for_levi\leviticus`.

## Offense we run

### Crystalism (Magi): DESTABILISE needs balance and equilibrium (207)
- **Effect:** DESTABILISE (`VIBE DESTABILISE <vibe>`) now takes balance AND equilibrium. Before, it took equilibrium only.
- **Confidence:** CONFIRMED (announcement); the OVERLOAD AB text says the same.
- **Code:** unaffected. No alias or script sends `vibe destabilise`. Only our tracker for our own destabilise line exists (`...\leviticus\502_Destabilise.lua`:36-48).
- **Notes:** an automatic destabilise, if one is ever added, must use a balance+equilibrium queue (`free`/`freestand`), not an equilibrium-only one.

### Crystalism (Magi): OVERLOAD (207, AB 3289)
- **Syntax:** `VIBE DESTABILISE <vibe> <target> <affliction>`
- **Cost:** balance AND equilibrium. The equilibrium cost is the greater of two values: the destabilised vibration's cost and OVERLOAD's own cost. AB does not give OVERLOAD's own cost.
- **Lessons:** 3301 in Crystalism.
- **Works on:** "a foe standing alongside you" (the same room).
- **Effect:** the vibration is destroyed, and its unstable room effect still fires. The target then gets ONE affliction of your choice: paralysis, asthma, slickness, anorexia or stupidity.
- **Confidence:** CONFIRMED (live) AB.
- **Code:** no code. Our Magi offense (`mage/004_Magi_Offense.lua`) never sends it.
- **Notes (offense):** each vibration in the room is now a one-shot chosen lock affliction. Paralysis, asthma, slickness and anorexia are the parts of the lock our Magi offense builds with spells. The price is the vibration and a balance+equilibrium action.
- **Notes (defence):** against a Magi with vibrations up, a lock affliction can arrive with no spell cast first.
- **Open (CONFLICTS #39):** OVERLOAD's own equilibrium figure, its lines (ours and the victim's), and whether the victim's line names the affliction. A trigger needs that line before V3 can record the affliction.

### Elementalism (Magi): PEBBLE (208, AB 3290)
- **Syntax:** `CAST PEBBLE AT <target>`
- **Cost:** 2.30 s of equilibrium, 90 mana, earth channel.
- **Lessons:** 1336 in Elementalism.
- **Works on:** adventurers.
- **Effect:** "Should the pebble strike true, it will shatter one of your target's healthy limbs, as well as causing damage." If every limb is already broken, it still wounds, and "your resonance will not grow".
- **Confidence:** CONFIRMED (live) AB.
- **Code:** no code. Not the travel artefact "enchanted pebble" (`scripts\mudlet-mapper\mudlet_mapper\001_Load_settings.lua`:86).
- **Notes (offense):** Magi gets a direct limb break at 2.30 s of equilibrium. "Strike true" means it can miss, and the text names no defence that stops it.
- **Notes (defence):** a pebble break has no damaged stage before it. A limb counter that waits for damage sees the break with no warning.
- **Notes (resonance):** the last clause implies a normal pebble hit raises resonance (earth, from the channel). AB does not say this directly.
- **Open (CONFLICTS #40):** which limb it picks (random or chosen), and its lines.

### Psionics (Psion): PULSE (236, AB 3292)
- **Syntax:** `PSI PULSE <target>`
- **Cost:** 1.00 s of equilibrium.
- **Lessons:** 2974 in Psionics.
- **Works on:** adventurers.
- **Effect:** "sense exactly how heavily they are bleeding". It reads the target's bleeding and gives no affliction.
- **Confidence:** CONFIRMED (live) AB.
- **Code:** no code. The "pulse" in `...\leviticus\telepathy_tekura\002_Confusion.lua`:38 is a Monk line and is unrelated.
- **Notes:** a Psion damage-over-time route that depends on bleeding can measure it exactly instead of guessing. The output line is uncaptured.

### Hypnosis (Serpent): SUGGEST and SEAL off balance (admin)
- **Effect:** SUGGEST used while off balance takes a fixed equilibrium that nothing can modify. SEAL used while off balance takes an unmodified equilibrium. On balance, nothing changes.
- **Why (admin note, verbatim intent):** "the attempt to slow down serpent early game while preserving the post snap explosiveness of the class continues ... This one might very well get reverted".
- **Confidence:** CONFIRMED (announcement). The fixed figure is not given.
- **Code:** unaffected. The offense returns unless balance is up (`serpent/002_Serpent_Offense.lua`:2226). Suggest and seal go BEFORE dstab/bite in the command (:2026, :2043), so they are always sent on balance. Only snap and shrugging go after (:2024, :2041). The manual 7-suggest alias (`aliases\...\serpent\003_Suggest_1.lua`:16-22) behaves as before.
- **Notes:** a Serpent who chains `dstab ...::suggest ...` now pays the fixed equilibrium for the suggest. Expect slower hypnosis set-up from Serpents who used that order.

### Weaponmastery, Dual Blunt: EXPEND relapse message (93)
- **Effect:** when an expended affliction relapses, the attacker now gets one uniform relapse message. The stray PARALYSIS message on an asthma relapse is fixed.
- **Confidence:** CONFIRMED (announcement). The new line is uncaptured.
- **Code:** affected (CONFLICTS #42). Nothing reads a relapse message. The relapse is simulated by blind 2.5 s timers in `...\leviticus\expend_afflictions\006-012`, which re-add the affliction even when it was cured. Nothing ever took paralysis from the old stray line.
- **Notes:** the new line lets one trigger replace the timers.

## Opponents we face

### Striking (Blademaster): EYES and TEMPLE on a broken head (270)
- **Effect:** on a target with a broken head, STRIKE EYES also gives hallucinations and STRIKE TEMPLE also gives dizziness.
- **Confidence:** CONFIRMED (announcement).
- **Code:** affected (CONFLICTS #41). `...\leviticus\striking\008_Stupidity_(temple).lua` added stupidity only; since v4.7.451 it also adds dizziness when `tAffs.damagedhead` or `mangledhead` is set. `009_Hallucinations_(eyes).lua`:37/42 adds hallucinations on EVERY eyes strike, with no head check. The patch implies hallucinations come from eyes only on a broken head.
- **Notes:** dizziness is a focus cure, so a temple strike on a broken head now adds to the focus pressure.

### Spirituality (Priest): ANGEL PANIC vs hellsight (53)
- **Effect:** ANGEL PANIC gives slickness instead of fear if the target has hellsight.
- **Confidence:** CONFIRMED (announcement).
- **Code:** no code. No trigger records fear from angel panic.
- **Notes:** slickness blocks salves (it is a lock part). Against a Priest with an Apostate ally (hellsight source, `.claude/classes/apostate.md`), panic is now a lock tool, not a fear.
- **Doc note:** the patch files ANGEL PANIC under Spirituality. Our Priest dossier files the ANGEL abilities under Zeal.

### Spirituality (Priest): HERESY ablaze tick (253)
- **Effect:** while HERESY is active, finishing a prayer of two or more verses forces one extra ablaze tick on every ablaze enemy in the room. It does not reset the next tick's timer.
- **Confidence:** CONFIRMED (announcement).
- **Code:** no code. We count no ablaze ticks on targets.

### Physiology (Alchemist): tempered MELANCHOLIC caps mana regen (229)
- **Effect:** passive mana regeneration is capped: level 2 at 2 stacks, level 1 at 4 stacks, none at 6 stacks. The old moss penalty stays.
- **Confidence:** CONFIRMED (live). AFFLICTION SHOW, re-captured 2026-10-23: "A tempered melancholic humour reduces the efficacy of irid moss and potash, and increasingly suppresses natural mana regeneration." Cures: eat ginger / eat antimony; NoRandomCure. The stack thresholds (2/4/6) are from the announcement only. Source: `kb/raw/live/affliction_show/temperedmelancholic.txt`, evidence copy in `kb/raw/live/captures/kb_capture_2026-10-23_122952.txt`.
- **Code:** unaffected. Tracked on us as an affliction only (`ataxia\005_Prompt_Affs.lua`:24, `ataxia\001_Default_Curing_Prios.lua`:336, `ataxia\008_Bash_Curing_Profile.lua`:178). Nothing models mana regeneration.
- **Notes:** against an Alchemist, melancholic stacks now drain a mana-hungry class (Magi, Psion) over a long fight. Raising its priority is a choice, not a fix.

### Sublimation (Alchemist): HALOPHILIC (37)
- **Effect:** reagent cost x3. It now clears vines: one toss with no Druid in the area, two with a Druid in the area.
- **Confidence:** CONFIRMED (announcement).
- **Code:** no halophilic code. Our vines handling is a fire clear (`aliases\...\083_Firelash.lua`:23, `...\leviticus\279_Vines_1.lua`, `028_Vines.lua`) and is unaffected.

### Subterfuge (Serpent): HYPERSIGHT (31)
- **Effect:** HYPERSIGHT, when active, works like a star sigil against an evading Serpent, if that Serpent has any affliction you gave or took damage from you recently.
- **Confidence:** CONFIRMED (announcement).
- **Code:** no code. `hypersight` is only a defence name (`ataxia\deffing\004_Defence_Sorting_-_Cleaner.lua`:252).
- **Notes:** a Serpent can now hold another Serpent in the room once the first hit lands.

### Telepathy (Monk): locks reach an adjacent room (115)
- **Effect:** locks and lock-based abilities treat an adjacent room as the same area. One room across an area border no longer breaks a lock or cancels Radiance.
- **Confidence:** CONFIRMED (announcement).
- **Code:** unaffected. Lock loss is driven by the game's lines (`...\leviticus\allies_enemies\011_Mind_Lock_Gone.lua`, `telepathy\001_NO_MORE_RADIANCE.lua`), not by our room changes.
- **Notes:** fleeing one room over an area border no longer breaks a Monk's mind lock on us.

### Woodlore (Sentinel): GRAPPLE (301, AB 3291)
- **Syntax:** `GRAPPLE <direction>`
- **Cost:** 2.50 s of balance.
- **Lessons:** 3006 in Woodlore.
- **Effect:** springs a trap the Sentinel laid in that direction and pulls them into the adjacent room. The trap is destroyed when the move succeeds.
- **Confidence:** CONFIRMED (live) AB.
- **Code:** no code.
- **Notes:** a movement skill, not an attack. A Sentinel with a trap laid toward an exit can leave, or follow us, on balance, and walls or blocks at the exit are not mentioned.

### Weaponmastery, Two Handed: RETALIATE (157)
- **Effect:** `DEFEND <target>` (AB id 3288, captured 2026-10-28). You take much of the damage from blows aimed at the adventurer you defend, and you strike back at anyone who threatens them, "so long as you are able".
- **Confidence:** CONFIRMED (AB text). Its start, stop and retaliation lines are not captured.
- **Code:** no code. If RETALIATE is a defence, check it against our existing `retaliation` defence key (`ataxia\deffing\004_Defence_Sorting_-_Cleaner.lua`:103).

## Tracking: third-party cure lines (Misc 232)
- **Effect:** "Third party affliction cures now only show to those who have relevant skill access where appropriate." The list: bloodfire, coldfate, conflagration, constricted, degenerate, earworm, enmeshed, guilt, hatred, horror, inquisition, kkractlebrand, latched, lovers, mindravaged, mycalium, petrified, rebbies, reeling, retribution, shadowmadness, snared, tension, all unweavings, whisperingmadness.
- **Confidence:** CONFIRMED (announcement). "Relevant skill access" is not defined. ASSUMED: it means the skill that gives the affliction.
- **Code:** affected (CONFLICTS #43). These target-removal triggers now fire only for someone with the giver's skill:
  - mycalium, rebbies, shadowmadness, unweavingbody/spirit/mind, guilt: `...\leviticus\third-person_removes\001-007`
  - lovers, mindravaged, horror (stack down): `...\leviticus\other_things_fading\002`, `004`, `008`
  - earworm and retribution: `...\leviticus\herbs\016_Cured_Earworm.lua`
  - petrified: `...\leviticus\606_Petrify_Cured.lua`
  - Removals inferred from the target's own herb and salve lines still work (goldenseal, lobelia, bellwort, the applies). Inquisition has its own 20 s timer.
  - None of the 25 has an `ataxia_TARGET_AFF_SECONDS` backstop (`ataxia\017_Affliction_Management.lua`:197-209).
- **Notes:** an affliction that enters our tracker without our class (party relay) can now stay on the target forever.

## Misc
- **Shackle artefact (bug):** switching outfits no longer bypasses the shackle's delayed mass. CONFIRMED (announcement). No code.
- **Arena ASSESS (141):** ASSESS from an arena's spectator stands now also shows the target's mana. CONFIRMED (announcement). `...\leviticus\698_Assess.lua` deletes the line and re-echoes HP only, so the mana is hidden (cosmetic, CONFLICTS #44).
- **Grimoire and gem (307):** the level-one grimoire (Grimoire of Adaptation, level 1) and the gem of reincarnation now have a 12-hour cooldown, not 24. CONFIRMED (announcement). See `docs/artefacts-reference.md`.
- **Pranks (9, 264):** used SUICIDEMICE return to the owner when the owner's part in an arena match ends; killed ones do not. MICE now shows each mouse's strapped bomb type. No code.
- **Domination (216):** summoning entities on the Chaos Plane has a different message. No trigger matches an entity summon line.
- **Chivalry (19):** the admins can now edit knight lineages. No combat effect.

## Part 2 ("More changes!")

The second part of the post, `kb/raw/announcements/classleads_2026-10-23_part2.txt`. Its last two
sections (Weaponmastery, Survival) came outside the pasted block, in the user's message; they are
part of the same post. All **CONFIRMED (announcement)** unless tagged.

### Survival (everyone): CLOTTING takes an amount (164)
- **Effect:** "CLOTTING now takes an amount of bleeding to clot." The user: bleeding "is cured by CLOT (amount)" (`kb/raw/players/cures-user-2026-10-23.txt`). ASSUMED: the syntax is `CLOT <amount>`, and the amount sets how much bleeding one clot removes.
- **Code:** probably unaffected; open as CONFLICTS #47. We never send CLOT ourselves. SSC clots for us: `curing clotat 30` at install (`ataxia/003_Install_System.lua`:32). The Mnemosyne Haemophiliac hold waits while bleed is 50 or more for SSC to clot it down (`mnemosyne/008_Explorer.lua`:56, :1633-1638). If SSC's clot now removes only a fixed amount each time, the hold lasts longer.
- **Found during the check (older), fixed in v4.7.451:** losing corruption set `curing clotat 180` (`ataxia/004_Aff_gains_losses.lua`), not the installed 30, so after a Pariah/corruption fight SSC clotted only above 180. It now restores 30.

### Subterfuge (Serpent): the snake's sileris strip is progressive (admin)
- **Effect:** the snake pet no longer strips sileris in one hit. The sileris "degrades each tick", and after a certain number of hits it is stripped. Darkshade on the target speeds this up, and scytherus speeds it up a lot. With both, it strips at once, as before.
- **Why (admin):** sileris was "turned off almost 100% of the time", so fratricide was "basically an always on thing". This keeps the snake strong in the mid and late game and slows the early game.
- **Code:** unaffected in logic; open as CONFLICTS #49. Our offense does not count on the adder (`order adder kill`, `serpent/002`:2196) to strip sileris. It strips with gecko, and impulses wait for sileris and fangbarrier to be down (`checkImpulseEligible`). No trigger reads the snake's strip or degrade lines, so V3 notices the strip only when a later bite is refused (`707_Sileris_True`) or lands.
- **Notes:** against a fresh target, sileris now stays up longer, so impulses and the frat route start later unless darkshade and scytherus are on.

### Weaponmastery, Dual Blunt: inline Oppression invests (101)
- **Effect:** an Infernal can append an Oppression invest to the end of a relevant blunt attack, to invest inline.
- **Code:** affected (an opportunity); open as CONFLICTS #48. Our Infernal DWB sends `hellforge invest <x>` as a separate command before every attack (`dwb/001_Infernal_DWB_Logic_-_Levi.lua`:424, :428, :432). The post gives no inline syntax.

### Reclamation (Druid): EMBRACE no longer needs vines (324)
- **Effect:** EMBRACE (`RECLAMATION EMBRACE <target>`, 3.00 s balance) no longer needs vines. The wiki's condition is still a target with all four limbs at least damaged (`kb/classes/druid.md`).
- **Code:** affected; open as CONFLICTS #46. Our only Embrace response runs: `cq all;goto 11090` and "EMBRACE DANGER" (`ataxia/004_Aff_gains_losses.lua`:252-255). Running away from the reclaimed room no longer avoids an Embrace.
- **Found during the check (older, and serious), fixed in v4.7.451:** that branch's condition was `aff == "damagedrightarm" or aff == "damagedleftarm" and not prone and class == "Druid"`. Lua binds `and` tighter than `or`, so a damaged RIGHT arm from ANY source (any class, or a denizen) cleared our queue and walked us to room 11090. The leg branch below it had the same bug (a random `tumble`), and so did four branches of the Infernal DWB offense. All are bracketed now.

### Metamorphosis (Druid, Sentinel): wreathe, incinerate, flame (337)
- **WREATHE** now adds burning stacks, and WYVERN FRENZY can be wreathed.
- **INCINERATE** kills below 40% health (was higher), plus more for each burning stack, up to three stacks and a 60% cap. The first stack counts for more than the other two. The wiki capture already has the steps: 40%, then 50% at one burning stack, 55% at two and 60% at three (`kb/classes/druid.md`, WIKI).
- **Summoned FLAME:** after a morph to another form, the Druid has 30 s to SUMMON FLAME again and gets the old flame level back after a short delay. Without that, they take backlash damage and the flame is cleared.
- **Code:** no code reads incinerate or wreathe. **Notes (defence):** against a wyvern, every burning stack raises the incinerate kill line, so burning becomes a kill-route resource. Cure burning early and keep health above 60% when the Druid has white fire up.

### Groves (Druid, Sylvan) (234, 64)
- LASTHARVEST is removed from the skill.
- VIGOUR and similar abilities drain sunlight only when there is enough to cast them.
- **Code:** none.

### Oppression (Infernal): ACCUSATION (152)
- A new ability. The post gives no detail. **Code:** none.

## Conflicts
Rows #39-#49 in [../CONFLICTS.md](../CONFLICTS.md).
