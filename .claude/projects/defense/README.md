# Defense systems and the Self Limb Counter (SLC): the reference that was in CLAUDE.md

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

## Defense Systems

### Core Defense Files
```
src_new/scripts/levi_ataxia/levi/ataxia/deffing/001_Defence_API.lua        # Main defense tracking API
src_new/scripts/levi_ataxia/levi/ataxia/deffing/003_Defence_Reporting.lua  # Defense status display
src_new/scripts/levi_ataxia/levi/ataxia/deffing/004_Defence_Sorting_-_Cleaner.lua  # Defense priority management
src_new/scripts/levi_ataxia/levi/ataxia/deffing/007_Sense_Keepers.lua      # Monk/BM DEAF + BLIND keepers; MINDSEYE (any class)
```

**MINDSEYE KEEPER (v4.7.378, user: "touch mindseye, thralls tend to strip defences").** Blind, the room hides its occupants ("A mysterious entity abides") and the explorer's look-ahead sees nothing. A third `ataxia_SENSE_KEEPERS` entry: any class (`anyClass`), only while `ataxia.defences.blindness` is up (`when`), not under Rimewrought, `touch mindseye` with a 4s `hold` (not the trance hold). Off with `ataxia.settings.senseKeep.mindseye = false`.

**MONK/BLADEMASTER SENSE KEEPERS -- THE POINT IS HERB BALANCE (v4.7.315/316).** DEAF and BLIND are
defences we WANT UP, and they are TIMED -- they lapse on their own, and a mob or a venom can strip
them. Two different wastes of the EATING balance are possible and they need different answers.
**(1) SSC eating a herb to CURE them off** (to *undeafen* us) is prevented by the AFFLICTION
priority **26**, which means ignored -- `curing priority deafness 26` / `curing priority blindness
26`. Already set for EVERY class at `ataxia/001_Default_Curing_Prios.lua:502-504`, and correct
there: the whole tree treats these two as kept defences (`004_Aff_gains_losses.lua` ignore lists,
`mnemosyne/009` `AFF_IGNORE`), so **do not make that per-class**. **(2) SSC eating a herb to put the
defence back UP** after it is stripped is what the SKILL keeper prevents -- the trance costs no herb
balance, so raising it ourselves is free where the curative is not. **The keeper IS the herb
saving**; it only had to be made to behave. (An earlier draft of this note claimed the herb saving
had not been delivered and recommended excluding the two names from `systemDefup` -- that was wrong,
and is retracted. The `curing priority defence` axis is a separate lever that is not what these two
run on.) Note for anyone auditing the priority write path: a `curing priority defence ...` command
is NOT filtered by `ataxia_sendCuringPriority`'s classifier (the pattern needs a trailing number, so
both the `25` and `reset` forms slip through) and lands in whichever curingset is ACTIVE, and
`isDefenceForCurrentClass` is a NO-OP for these two because it returns true for anything in
`curatives`.

**AND THE MECHANICAL BUG BEHIND IT -- A GUARD FED BY THE GAME'S REPLY CANNOT HOLD OFF THE SENDS THAT
PRECEDE IT (v4.7.315).** AB Deaf (Kaido 875) is `DEAF`, self, "enter a short TRANCE" -- it resolves
over TIME and spends no balance or equilibrium we track, so nothing about sending it makes the next
send wait. The keeper lived in `318_Prompt_Trigger.lua` guarded only by `incomingdeafness`, a global
set when the game's ATTEMPT ECHO printed -- which cannot close until our command has made the round
trip, so every prompt inside that window re-sent: **six DEAF for one trance in 0.15s**. The hold is
now stamped at SEND time, the only moment we know something is in flight (the `shin augment` lesson,
v4.7.270). `deffing/007` owns the class gate, the GMCP check and the hold; the trigger just calls
`ataxia_senseKeepTick()`, because **a guard inside a trigger is a guard the test suite cannot see**.
Three further rules came out of the same three lines. **A missing stamp reads READY** (v4.7.192):
`incomingdeafness` was never initialised and `nil == false` is FALSE, so a fresh session raised
nothing until the first *manual* DEAF. **GMCP owns whether a defence is up; we only own whether one
is in flight** -- the old triggers wrote `ataxia.defences.<sense> = true` from the ATTEMPT line, and
an interrupted trance would leave us believing in a defence GMCP never confirmed and so will never
Remove, i.e. a keeper silently off for the session (v4.7.280); that write is gone, and the hold is a
timestamp against a window rather than a flag awaiting a confirmation, so it cannot livelock
(v4.7.167). **The attempt echo still stamps** (762/763), because it proves an attempt is in flight
whoever started it -- without it a manually typed DEAF draws a duplicate from the keeper. And the
blind half of that block had **never executed**: it read `incommingblindness` (two m's, assigned
nowhere) against 762's `incomingblindness`, and read `ataxia.afflictions.blindness` where 762 writes
`ataxia.defences.blindness` -- two names wrong and one table wrong. Fixed and enabled at the user's
direction, treating the repaired branch as new code (the v4.7.314 Kai Choke rule). **That repair
carries an UNVERIFIED PvE risk worth naming:** `ataxia.denizensHere` is fed from GMCP `Char.Items`
for the room -- what the character PERCEIVES -- and v4.7.125 already records that "airborne gmcp
`Char.Items` reflects the SKY so `denizensHere` is empty". If blindness does the same on the
ground, `_roomHasDenizens` reads clear, the explorer walks out of occupied rooms and targeting
finds nothing, silently. Hence the per-sense opt-out (`ataxia.settings.senseKeep.blindness =
false`, default ON) added in v4.7.316. **Both landed lines are now captured (v4.7.317)** -- `772_Blind_Landed`
("You open your eyes once more, and the world about you is darkness.") and `773_Deaf_Landed`
("The world about you falls silent as the deafness trance sinks upon you."), which also CONFIRMS
`blind` as a real command. A live blind capture brackets the trance at **3.2-5.9s** (the landed
line sits between two prompts), condemning the inherited 6s hold that sat right on that boundary;
it is **10s** now. Raising it used to trade against masking an opponent STRIPPING deafness
(stridulation, prefarar) -- **that trade is gone**: `ataxia_senseLanded` collapses the hold to a
1.5s grace the moment the game says the trance resolved, so a strip is answered in ~1.5s rather
than ~10s. A grace, not a clear, because GMCP's Add can lag the landed line. The landed line never
writes `ataxia.defences`: it proves the ACTION finished, GMCP still owns the STATE. **Both REFUSAL lines are captured too** (v4.7.317, `774`/`775`: "You are already deaf." /
"You are already blind."), so all six lines -- attempt, landed and refusal per sense -- are live and
none is inferred. A refusal is a free state probe (the Fury / shin-augment rule): it proves no
trance started AND that the defence is up. It takes the FULL hold rather than the landed grace,
since a refusal means our picture is already wrong. **It still does not write `ataxia.defences`** --
the one place that rule is genuinely tempting, and the reason is that a GMCP which disagrees here is
a GMCP not tracking the defence, which will therefore never Remove it: the write would be a belief
nothing can clear, i.e. the v4.7.280 livelock from the opposite direction. It warns once per session
and lets the hold re-probe.

### Defence API (`ataxia.defense`)
The defense system tracks active defenses and manages automatic rekeeping.

**Key Functions:**
| Function | Purpose |
|----------|---------|
| `ataxia.defense.add(def)` | Mark defense as active |
| `ataxia.defense.remove(def)` | Mark defense as lost |
| `ataxia.defense.has(def)` | Check if defense is active |
| `ataxia.defense.list()` | Return all active defenses |

### Anti-Serpent Defenses
Located in `algedonic_defense_1.0/001_Anti_Priorities.lua`

**Serpent Defense Priority Adjustments:**
When fighting a serpent, automatically adjusts curing priorities:
- Metawake high priority (vs hypnosis)
- Insomnia high priority (vs sleep lock)
- Kola/Gypsum for deafness cycling

**Usage:**
```lua
ataxia.defense.antiSerpent(true)   -- Enable anti-serpent priorities
ataxia.defense.antiSerpent(false)  -- Restore normal priorities
```

### Self Limb Counter (SLC) — Defensive Limb Tracking

Tracks exact limb damage percentages from combat text with automated defensive responses (auto-parry, auto-shield, party callouts, SSC priority).

**Full documentation**: See `memory/slc.md` (thresholds, events, parry modes, defensive reactions, config)

**ARMY OF THE DEAD IS AN APOSTATE RIDER TOO (v4.7.347, user: "For Apostate").** `ataxiaBasher_infGravehands` has carried the Apostate command since v4.7.149 (`(class == "Apostate") and "summon hands of the grave" or "tyranny"`) and **nothing ever called it from the Apostate round** -- only `ataxiaBasher_infernalBashing` did -- so the boon was inert on this class: no error, no echo, simply nothing. Two differences from the Infernal copy, both from ABADMIN 144 (`SUMMON HANDS OF THE GRAVE`, 3.00s of EQUILIBRIUM, 1.50% life essence + 350 mana): (1) **it REPLACES the swing on its round, like TYRANNY** (corrected v4.7.354, user: "Gravehands takes balance") -- v4.7.347 believed the AB block's "3.00 seconds of EQUILIBRIUM" and prepended the summon beside the belch and the soulstorm, so the `deadeyes` swing behind it (also balance) was refused on every gravehands round; the belch and soulstorm (equilibrium) still ride that round; (2) **it costs 350 mana**, gated on the Apostate branch only (TYRANNY is a different ability and its cost is not this one) with a 40% floor -- lower than the belch's 50 because this is once-per-room, not every five seconds. The flat 350 check is NOT redundant with the floor: the floor is configurable and is inert when maxmp is unknown. **The once-per-room stamp is written at SEND time**, so a refused cast burns the room; the Apostate cast has a visible line (trigger 782 -> `ataxiaBasher_gravehandsUp`; matched on its FIRST-PERSON OPENING "You mutter words of death and decay..." since v4.7.351 -- the original fragment began at column 88 of a 148-character line and the server wrap went straight through it, so the confirmation never arrived and every room was cast twice), so an unconfirmed summon retries ONCE after `GRAVEHANDS_CONFIRM` 6s, per room. The Infernal is excluded from that retry by name -- TYRANNY's confirmation line was never captured, so "unconfirmed" would be its permanent state and it would re-cast every few seconds (the v4.7.148 essence burn). **That line does NOT latch the boon**, unlike the belch's: the base ability prints it with or without Army of the Dead, and a wrong latch costs 1.5% essence + 350 mana in every room after it -- the BOONS row (`mnemosyne/039`) and the claim line own that fact. Both lines are highlighted `cadet_blue` (belch goldenrod, soulstorm medium_orchid); the summon line WITHOUT the boon's "chill of the grave" line is the tell that the hands went up and the boon did not.

**GRAVEBORN -- gravehands in EVERY room (v4.7.348, user: "We need to ensure we gravehands every room to maximize this").** The combo boon (`mnemGraveborn`; rare / Offence / no echo; unlocked by **Army of the Dead + Maliceborn + Necrotic Aura**): *"While standing in gravehands, your attacks will command them to ravage your enemies, damaging all denizens in your location. This can only trigger every 15 seconds."* The crowd gate existed because the summon was ONE AoE hit; Graveborn makes the hands an ENGINE that fires every 15s for as long as we stand in them and swing, so a room we skip is an engine we never built. Three gates move with the boon, and all three had to, because any one of them silently skips a room: **denizens 2 -> 1**; **essence floor 20% -> 10%** (Graveborn is unlocked BY Maliceborn -- "slaying a denizen will now restore 5% of your life essence" -- so holding the combo means holding the refund); **mana floor 40% -> 25%**. LOWERED, NEVER WAIVED -- mana is the curing pool, and an explicit `infTyrannyAt`/`infEssenceFloor`/`gravehandsManaFloor` still beats the boon both ways. Wired in all five places a boon flag must be (BOON_FLAGS, run start, confirmed run end, claim line, BOONS row `mnemosyne/098`) plus the combo recipe. **NECROTIC AURA WAS INERT ON THE APOSTATE TOO** -- the identical v4.7.347 defect, found by reading what Graveborn is unlocked by: `ataxiaBasher_infDeathaura` is class-agnostic (DEATHAURA is a Necromancy defence) and only the Infernal round ever called it, so an Apostate on the combo path held a required component that did nothing. It now rides BOTH Apostate branches -- raising a defence is not an attack. **Two for two: when a helper is named for one class but its body is not, the name is not the gate, the CALL SITE is.**

**OUR BAALZADEEN WAS READING AS A SWARM (v4.7.348, user: "the denizens in the room should not count our Baalzadeen as Apostate! It is thinking it is a swarm").** `baalzadeen` and `falcon` have always been in the DEFAULT `ownDenizens` list -- which only runs when `ownDenizens` is nil, i.e. a fresh install -- while the backfill loop beside it, whose entire reason for existing is that "existing saves keep the old default", carried only `ashbeast` and `hyena`. So no existing save ever got them. The cost is not that the pet gets hit: `isOwnDenizen` is what `M._denizenCount`/`M._roomHasDenizens` filter through, so a missing keyword INFLATES THE SWARM COUNT, and that threshold fires the pull, the funnel and the icewall -- one pet beside two denizens reads as three, the default threshold exactly. Both are in the backfill now with a one-time echo. **A seeded default and a backfill are two different lists and only one runs for an existing user; adding to the seed alone ships a fix nobody receives.**

**PSION BOON KEEPERS (v4.7.349, user: "Psion is another class we need to add").** Two of the three pasted boons pay out only while a DEFENCE stands, which makes them keepers rather than attacks -- and ENACT costs EQUILIBRIUM (2.30s), which every Psion weave leaves idle, the same channel `psi transcend`/`enact wrath` already ride (the round sent `enact roth` -- the BOON's name -- until v4.7.360, so the heal never fired). `ataxiaBasher_psionEmulationKeepers(sp, rothFired)`: **Razor Clarity** (`psionRazorClarity`, +50% damage / +2% crit) keeps `clarity` via `enact clarity`; **Bloodletter's Fury** (`psionBloodletter`, weaves become unblockable, +50% base damage, 20% faster balance) keeps `rupturesight` via `enact rupture`. Commands and defence names are all confirmed, never guessed -- the two ENACTs are the package's own `emulation/004`/`005` aliases, both defence keys are already in `ataxiaTables.defences`, and the boon text names `rupturesight` itself. **THE HOLDS DIFFER DELIBERATELY** (clarity 12s, rupturesight 4s, `ataxiaBasher.psionKeepHold` overrides both): rupture's ability text is "your next three blows shall all deal significantly increased bleeding", which may make `rupturesight` a CHARGE rather than a lasting defence -- the keeper does not need to know, since it reads gmcp every round, so the uncertain one just gets the shorter anti-spam guard. They ride the shielded round too (raising a defence is not an attack). **ONE EQUILIBRIUM ACTION PER ROUND (v4.7.351):** roth, then psi transcend, then ONE keeper, RUPTURE FIRST -- v4.7.349 chained `enact clarity;enact rupture;`, and the second ENACT was refused while its hold was stamped as sent (the test asserted the collision as correct). The keepers take `eqSpent`, not just `rothFired`. Both keeper holds and the transcend hold are TIMESTAMPS (`ataxiaTemp.psionKeepAt[def]`, `psionTranscendAt`), not flags cleared by a tempTimer -- a lost timer wedged a keeper off for the session. **[REVERSED v4.7.356 -- shatter goes out ONLY at full transcendence, free, first in the round; user: "you keep using Psi shatter when we should be using weavings. Therefore, we should only use PSI Shatter when at 100 transcendence! PSI Shatter target;Weave deathblow target". The paid shatter below held every weave back: the queued round needs eq AND balance, and weaves build transcendence. What follows is v4.7.352's reasoning, kept for the record.]** **PSI SHATTER IS THE MAIN EQUILIBRIUM TOOL (v4.7.352, user: "Psi Shatter is the main tool to use unless we have other boons with full transcendence").** AB 2750: `PSI SHATTER <target>`, works on denizens, **3.10s of equilibrium** -- it was only ever sent at FULL transcendence (where it is free), and the user's log had it at 12,992 (Mindbreak) against deathblows of ~900-1,900. Equilibrium order: roth > psi transcend > ONE boon keeper > **psi shatter**; never shielded; rides a secondskin round. **At full transcendence the free shatter goes FIRST in the chain (v4.7.353)** -- it costs no equilibrium but REQUIRES equilibrium and balance to execute (user: "it does need EQ and Balance to execute but costs no EQ. Just requires it"; the wiki's "while off equilibrium" is wrong), so anything ahead of it that spent equilibrium would leave it none. With nothing else wanting equilibrium, the paid shatter followed it (v4.7.353-355; gone in v4.7.356 -- the round today is just `psi shatter <t>;weave deathblow <t>` at full transcendence and the weave otherwise). **PSIWAVE (v4.7.355, `psionPsiwave`)** swaps it for `psi radiate` (AB 2714, no target; with the boon it deals magic damage to every denizen) in `psionTranscendSpend(sp)` (v4.7.355 had a separate `psionEqAttack`, folded in v4.7.356) -- user: "When we have this boon please use this instead of shatter"; unconditional, over Mindbreak too. A keeper that fires now MARKS the round (`eqSpent`) -- before, it did not, which would have chained keeper + shatter (caught by the tests on the first run). The full-transcendence spend is `psionTranscendSpend(sp)` in basher/002 -- the one place a future boon changes it. **WRATH, NOT ROTH (v4.7.360).** The emergency heal is `ENACT WRATH` (AB 2739, 1.30s eq, below 50% HP, every 3 minutes, grants clarity + rupture); the round sent `enact roth` -- the Mnemosyne boon's name -- from the start, so it never fired, and every test asserted the wrong command. The **Roth** combo boon (Razor Clarity + Bloodletter's Fury, `psionRoth`) makes it 75% HP on a 30s cooldown. Lockouts (user, v4.7.361): 120s normally, 30s with Roth. **Rupture (v4.7.361)** is tracked from the game's lines -- up/already (psion/007) stand the Bloodletter keeper down, the down line (psion/008, "Distractions reassert themselves...") clears the belief and the hold so the next round re-enacts; the belief expires after 20s. Wrath is still stamped at BUILD -- a replaced round loses it for the lockout -- until its game line is captured. **Mindbreak changes no rotation** -- it multiplies the one free shatter per full transcendence. **EARTHQUAKE (v4.7.357, `psionEarthquake`)**: `enact upheaval` (AB 2730, 2.30s eq; "deals significant blunt damage to all denizens in the location when it summons rubble") rides on the equilibrium nothing else took -- after roth/transcend/keepers, after the free shatter, beside the weave -- via `ataxiaBasher_psionUpheaval(sp, eqSpent)`; only with 2+ denizens (`ataxiaBasher.upheavalAt`), at 50%+ HP, unshielded, because its rubble blocks OUR exits too. Costs a deathblow round 0.10s. Leaving over rubble is a slow clamber, so `M.onClamber()` (008, trigger mnemosyne/104) re-arms the explorer's pending move timeout for `CLAMBER_GRACE` (10s) once per move -- the 5s timeout used to re-send the step and could condemn a real exit. **PROPHET OF CREATION (v4.7.358, `psionProphet`)** -- foresight works on denizens and makes the next attack against us miss -- was latched only in v4.7.358 and is USED since v4.7.359: `ataxiaBasher_psionForesight(sp)` opens the round with `psi foresight <target>` (user: "No tree or shield that is optional") whenever it is off cooldown and the target is at 50%+ HP -- a foresight that does not come true stuns us, and against a denizen that means a target that dies before it swings. The cooldown is stamped by the CAST LINE (psion/005) and the refusal retries in 5s (psion/006); the build only takes a 2s in-flight hold, because a rebuilt round replaces the queued one and a build-time 30s stamp would lose the dodge. Free per the user; a test pins that the round is unchanged by it. First in-game test: the prediction is simply the denizen's next attack ("Your prediction comes to pass, and you effortlessly avoid the attack from <denizen>."), true in under 0.3s, no stun; about a 30s cooldown (refusal: "Your mind has not yet recovered enough to pierce the fabric of time once again."); the open question is a denizen that dies or never swings. **The round is re-queued the moment transcendence fills** (`ataxiaBasher_requeueNow`, genrunning/004, called from `psion/002` only on the change to 100): the round is rebuilt on prompt/vitals events behind a 0.3s anti-spam flag, so the "achieved transcendence" line could land after the last rebuild and the stale entry fired without the free shatter -- the user's "behind one attack". It clears that flag for one call and goes through tryAttack's normal gates; with no target it does nothing.

**THE TRANSCENDENCE DECAY LINE COULD NEVER HAVE MATCHED (v4.7.349).** `psion/001_Transcendence_Set` watched both directions with `$`-anchored patterns. The decay line ("Your inaction causes the harmonisation of your body and mind to falter: you are now only N percent of the way to transcendence.") is **128 characters**; Achaea wraps server-side at ~114, so it arrives in halves and an anchored pattern cannot match it. The BUILD line is 94, fits, and matched fine -- which is what hid it: **transcendence counted up and never came back down**, so `ataxiaBasher_psionBashing` kept sending `psi shatter <target>` believing it was at 100 when the game had taken it away. Both patterns now stop at the captured number (keeping only `^`), and "Your body and mind are no longer in harmony." -- the bottom of the ladder, previously unwired -- zeroes the counter in trigger 003. **The fix created a display bug (v4.7.351):** `deleteFull()` gags the first row and only deletes the next if it is a prompt, so the tail "transcendence." was left alone on screen every tick; `psion/004` gags it, but only within a second of `psion/001` firing (`ataxiaTemp.transcendLineAt`). **An anchored pattern is a bet that the line is short enough, and the lines that break it are exactly the informative ones** (v4.7.286 reached the same lesson from the other side: there the answer was a fragment, here it is stopping before the wrap).

**A RELOAD NOW BRINGS EVERY BOON BACK (v4.7.350).** Boon flags are bare globals, so a reimport clears them; `M._relatchBoons` sends `boon claimed` once per run so the rows (`<name>  <echoes>  <rarity>`) can re-latch what we own. `M.BOON_FLAGS` documented itself as latched from "the BOON CLAIM ... and the BOONS list (on demand, and after a reload)" -- **only the claim half was ever wired**. The generic row trigger `mnemosyne/013_Boons_List_Row` learned, recorded, coloured and annotated every row and never called `latchBoonFlag`, so a boon returned after a reload only if it ALSO had a hand-written row trigger. 15 of the table's 20 did not -- including Dead Breath and Deathtempest, so a mid-run reimport silently stopped the Apostate's belch and soulstorm (and Dead Breath cannot self-rescue from its boon line, because the belch that prints it never fires without the flag). The row trigger now calls `latchBoonFlag(name)` -- **only while `ataxiaBasher.inMnemosyne`** (v4.7.351: only one of the twenty consumers, Sharp Mind, checks for itself, so a list printed outside a run would have armed the belch and soulstorm for ordinary bashing; the wade-status trigger sets the flag before the re-latch is sent, and the per-boon rows 098-101 carry the same gate). **Run start now calls `M.clearBoonFlags()` too** (v4.7.351) -- it had cleared only a hand-written list missing 13 of the 20. Safe because the pattern requires an echo count AND a rarity word -- the offer screen's `Name:   description` rows have neither. **When adding a boon to `BOON_FLAGS`, no row trigger is needed any more** -- a test feeds a row for every name in the table and requires every flag back. Panoply (the user's prompt for this) was never affected: it has its own row trigger, and `weave flurry` has replaced `weave deathblow` under it since it shipped.

**A TRIGGER PATTERN MUST FIT ON ONE WRAPPED ROW (v4.7.351).** This user's Achaea wraps server-side at **119-124 columns** (measured from the break points in their pastes), so a long line reaches Mudlet as separate rows and a pattern that runs past the break -- or a fragment that straddles it -- can never match, silently. Three triggers from one week did exactly that (782 gravehands confirmation, 779 belch fouled, 780 soulstorm landing for long mob names) plus the highlights for all three. **Match an EARLY phrase of any line near or over ~110 characters; for a highlight, add a short anchored tail `^.{0,60}<last words>\.$` so the wrapped row is coloured too.** Chat pastes arrive UNWRAPPED, so a paste is not evidence of the line's length. Two guards: `tools/check_wrap.py` (CI) fails any pattern whose shortest match is wider than 118 columns (6 pre-existing allowlisted since v4.7.419; a stale entry fails the check), and `tests/test_trigger_wrap.lua` + `tests/trigger_lib.lua` catch the straddling class the lint cannot see -- they wrap known lines at 100/119/124 and run the trigger's REAL patterns per row, through an evaluator that raises on any regex shape it cannot judge. **Assert on the PATTERN, never on the file text** -- after the first fix, 782's old test still passed on the comment explaining the fix.

**THE GAME NO LONGER SPLITS LINES: `CONFIG SCREENWIDTH 0` (v4.7.441).** The user set it on 2026-10-22
("You have set your screen width to 0, which should disable wrapping completely") and it is now a
saved setting, `ataxia.settings.screenwidth` (default 0), sent at EVERY login (`login/001`) and by
`aconfig screenwidth <width|off>` (`configs/029`; `off` = `false`, never sent). Mudlet wraps the
display only, so a trigger sees the whole line, and the 145 allowlisted long patterns match again. The
one-row rule above STAYS as defence in depth: a width other than 0 -- set by hand, or by another
client on the same character -- brings every one of those misses back, and new patterns must still pass
`check_wrap.py`. Evidence that settled it: a highlight coloured BOTH screen rows of the Rampage proc
line, which only a whole line can do.

**THE GAME PRINTS EACH COST: `CONFIG SEEBALANCES YES` (v4.7.470).** It is a saved setting,
`ataxia.settings.seebalances`, **default off** until the user reports that the extra line breaks nothing. When
on, it is sent at EVERY login (`login/001`) and by `aconfig seebalances <on|off>` (`configs/032`; `off` is never
sent, and the game keeps what it has, so the user's own character already has it on). The game then prints `Balance used: 2.8s.` and `Equilibrium used: 3.40s.`, so every fight log
holds the true costs (`kb/raw/live/seebalances_2026-11-01.txt`). It adds a line after each spend, so a
trigger that acts on "the next line" can see that line instead (`docs/plans/timing-probes-2026-11.md`).

**A SERPENT ROUND CAN SEND ITS ATTACK FIRST: `aconfig serpent attackfirst <on|off>` (v4.7.479).** A saved setting,
`ataxia.settings.serpentattackfirst`, **default off** (`002_Check_For_Any_Missing_Variables.lua`), set by the alias
`configs/034_Serpent_Attack_First.lua` (no argument shows it). On, `serpent/002`'s `buildRound` sends the attack as the
round's first command: a wield goes before it only when GMCP shows the weapon is not in hand, a raw `stand` only when
prone, and an equilibrium step the offense puts before the attack (suggest, seal, hypnotise) stays before it. Purge, the
adder order and combatQueue's commands go after it. Why: in the 2026-11-07 spar the game answered a send's second and
later commands about 0.09 s after the first, so an attack behind six commands landed about 0.12 s later on our clock.
Whether that is our side or the server pacing its output is open (`kb/CONFLICTS.md` #69); a spar with it on settles it,
which is why it is off by default. The setup wizard's combat page shows it (`020_Setup_Wizard.lua`:760), and
`ataxia setup guide ataxia` entry 16 explains it. A Serpent fight log's header has ` | serpent attackfirst on|off` just before its last field, ` | rounds raw|alias`.

**A STATE trigger whose target NAME falls after the wrap reads it from the following rows (v4.7.419-420).**
An early fragment drops the name, and recording on `target` instead would record a spell cast at anyone
else. `general/022`'s `withName` and the four emanation triggers (`enamation/001-004`) read up to two more
rows, one at a time, with `tempLineTrigger(1, 1, ...)`, and keep their name check (the highlighting/071
idiom, used to record). **When the name sits MID-sentence** (the fire, air and earth emanations), join the
rows until the sentence closes, read the name with the old pattern's tail, and stop at the first closed
sentence so no reader stays armed. `check_wrap.py` reads patterns FOLDED across YAML lines since
v4.7.436 (`kb/CONFLICTS.md` #2).

**A fragment that ends before the name matches DENIZENS too (v4.7.420).** A whole-line strike pattern ending
in a one-word `(\w+)` name never matched a multi-word denizen; cut to an early fragment, it can (`calls/008`
and two of `gags/001`'s fragments still read a one-word name). A body meant for PvP then needs the PvE test
the basher's own triggers 337/338 make: `if type(target) ~= "string" or (ataxiaBasher and
ataxiaBasher.enabled) then return end`. Without it `gags/001` would hide our own strike lines while bashing,
and 166 would clear the PvP target's shield on every basher shatter round.

**MOUNTJUMP RECOVERS BOTH WAYS (v4.7.351).** "You have no mount on which to jump." (705) now re-sends a recorded MOUNTJUMP as `leap` (`ataxiaBasher_jumpRefusedOnFoot`) -- a stale mounted belief (died in the saddle, mount killed, thrown by an uncaptured line) previously lost the escape. Both recoveries HOLD the send, still latching, while a tumble is in flight (`S.moveLocked`) or we stand in lava (`M.onLava` owns movement). `S.reset` clears the jump ledger; `ataxiaBasher_onDeath` sets the belief to UNKNOWN (nil) above its enabled-check. **The gravehands once-per-room record is cleared at each ripple** (`M.onRippleReset`) -- the tower reuses room numbers.

**Namespace:** `selfLimbDamage` (global). **Alias:** `slc`. **Files:** `self_limb_tracking/002-005`, `triggers/.../highlighting/027_Parry_Success.lua`, `aliases/.../slc/005_SLC_Toggle.lua`. PvE predictive layer (005, v4.7.109): `selfLimbDamage.denizenPatterns[name]` holds fixed swing cycles (e.g. the Mnemosyne axe-wielding revenant: right leg x2 → left leg x2 → torso x2) or, since v4.7.111, `{ fixed = "<limb>" }` for mobs with exactly one parryable attack (a steel-encased Death Knight = left leg, a ravager of the Infernal Legion = torso, an unbound frost elemental = torso, and v4.7.167 **an iron malagma = right arm** / **an invar malagma = right leg** — the iron malagma has two arm attacks to one head attack and broken arms REFUSE the SnB combination outright, so arms are the limbs gating the whole offence; `fixed` not `cycle` because neither arm line names a SIDE, so an unsynchronised cycle would guard the wrong arm half the time); `ataxia_denizenParryPredict()` parries the NEXT swing's limb, including the cycle opener before the first hit lands. Lives inside the **`bashing` parry mode** (v4.7.110), which auto-engages on `basher enabled` (saving the prior mode) and restores on `basher disabled` — ladder: pattern/fixed prediction → focus-follow (`lasthit`, 12s-fresh via `lasthitAt`, fed by perceive lines AND confirmed parries through `ataxia_parrySuccess`) → head default (head → right leg → left leg → torso); `manual` never hijacked, opt-out `slc bashparry off`. **The level-1 break line had NO handler until v4.7.167** (trigger `038_Limb_Broken_L1`, `^Your (left arm|right arm|left leg|right leg) breaks with a loud crack\.$`) — SLC captured both ends of the trio (`036_Limb_healed` → `ataxia_clearLimbDamage`, `037_mangled` → `SLC_broke`) but not the most common of the three. Because `ataxia_brokenLimbFound` only branches on the `damaged*`/`mangled*` families, a level-1 break never reset the accumulator: `selfLimbDamage[limb].damage` climbed past the real break, `ataxia_selfHitsToBreak` pinned at 0, the threshold latched `critical` forever, and every one-shot reaction latch (SSC priority, party callout, auto-shield cooldown) stayed set and never re-armed — and `computeThreshold` never returns `"broken"` for a limb at all (torso only), making `004_Defensive_Reactions`' `if threshold ~= "broken" then return end` unreachable for arms. The fix uses the GAME'S OWN FIRE TEXT, which names limb AND side, sidestepping the unresolved `crippled*` vs `broken*` vs `damaged*` naming split the codebase is genuinely inconsistent about. **Two refusal lines** are also wired (v4.7.167): `344_Broken_Arms` (which previously fired an unthrottled `diag` that nothing parses) and the new `345_Broken_Legs_Block` both roll back every owned rotation's in-flight replay, and the legs one also calls `M._disarmMove()` — its expensive victim is not a lost swing but the swarm escape ladder's `leap`, whose refusal was otherwise silent. The parry-success line ("You parry the assault to your <limb> with a deft maneouvre." — game spells it "eo"; trigger tolerates both spellings) is highlighted bold spring_green and feeds the tracker; parried swings emit no perceive line, so without that feed the system went blind exactly while the parry worked.

---
