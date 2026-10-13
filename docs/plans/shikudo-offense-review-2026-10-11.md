# Shikudo offense review (2026-10-11)

Checked against the game data in the knowledge base (`kb/classes/monk.md`, raw `kb/raw/wiki/Shikudo.wiki`,
`Kaido.wiki`, `Telepathy.wiki`; `kb/afflictions/afflictions.json`). Two independent reviews (tracking and
offense logic); every critical finding below was re-checked by hand against the code.

## The game's rules that matter

**Combo:** at most three attacks, only one a kick. Sweep uses both arm balances, so it pairs only with a kick,
and a sweep round is two kata actions (c.iJVmpL:3868-3872; one combo of Mystor's put a `hiru light` beside a
sweep, vNTjvghY:8081, and the hiru printed nothing though the chain counted three).
Dispatch/Incapacitate are used outside a combo, in any form.

**Forms** (wiki):

| Form | Attacks | Moves to |
|---|---|---|
| Tykonos | thrust, sweep, risingkick | Willow |
| Willow | dart, sweep, hiru, flashheel, **hiraku** | Rain |
| Rain | ruku, kuro, hiru, frontkick | Tykonos, Oak |
| Oak | **livestrike, nervestrike**, ruku, risingkick, kuro | Willow, Gaital |
| Gaital | **needle**, spinkick, sweep, ruku, flashheel, kuro, jinzuku, dawnkick | Rain, Maelstrom |
| Maelstrom | ruku, risingkick, sweep, **crescent**, livestrike, jinzuku | Oak |

**Afflictions:** livestrike asthma; nervestrike paralysis; ruku torso slickness; ruku arm clumsiness, or
healthleech if already clumsy; kuro weariness, or lethargy if already weary; hiru dizziness, plus confusion if
prone; hiraku anorexia + stuttering, plus a stun if prone; jinzuku addiction; needle crushed throat; flashheel
BREAKS a leg in one blow; frontkick (arm) and sweep prone; risingkick stun (head if prone, torso with internal
trauma); dawnkick epilepsy shortly after, a second time if prone. Telepathy: MIND
IMPATIENCE / PARALYSE / CONFUSE / STUPIDITY / EPILEPSY / FEAR / AMNESIA / PACIFY / DEADENING / DAZE / DISRUPT /
ISOLATE / CLAMP / BLACKOUT, and MIND BATTER = stupidity + epilepsy + dizziness. The wiki's (*) abilities
among them (impatience, paralyse, confuse, stupidity, epilepsy, fear, amnesia, deadening, disrupt, batter) need
no lock. The players (the user and Mystor, 2026-10-11) say most Telepathy needs only the target in the room,
with a lock only for out-of-room targets and certain skills such as Radiance and Sapience. PACIFY, DAZE,
ISOLATE, CLAMP and BLACKOUT carry no (*), and the wiki's text for PACIFY, ISOLATE, CLAMP and BLACKOUT also names
a locked target. Whether they need the lock in the same room is unconfirmed (blackout: kb/CONFLICTS.md #7); see
"Telepathy and blackout" below.

**Kill routes:** Crescent (Maelstrom kick: prone and <= 50% health, otherwise a long recovery and you drop to
Tykonos); Dispatch (prone + damaged head + windpipe); Mind Scythe (mangled head + two of stupidity, impatience,
dizziness, epilepsy, confusion).

**Locks:** softlock = livestrike + ruku torso + hiraku, which spans Oak/Maelstrom, Rain/Oak/Gaital/Maelstrom and
Willow. Venomlock adds nervestrike (Oak only). Truelock needs impatience, which only comes through Telepathy.
**Riftlock** (user): break both arms (thrust, dart, ruku arms, frontkick), slickness (ruku torso), asthma
(livestrike), plus addiction (jinzuku) to make them eat what is in hand. Maelstrom has ruku, livestrike and
jinzuku in one form.

## What is live

| File | Status |
|---|---|
| 006_CC_Shikudo_Dispatch | **Live** dispatch path (`sk`, `zz`, `xx`; `vv`'s combo, kill and shield rounds through 011). `skstaff` (alias `shikudo/007_Staff`, v4.7.420) sets the staff it wields |
| 007_CC_Shikudo_Lock | **Live** lock path (`sr`), rebuilt in v4.7.420 |
| 011_Shikudo_Telepathy | **Live** (v4.7.420): `vv` = the dispatch offense with Telepathy rounds between its combos (`shikudo.dispatchMind`) |
| 009_CC_Shikudo_GodMode | **Switched off** (v4.7.419). Nothing could reach it, and its run() threw on the first tick. Why, and what a later riftlock or arm route should salvage, are in its RETIRED header; read them there (its line numbers are pinned by `test_monk_aliases.lua` and move with the file). To be deleted with 001/002/004/005/008 |
| 010_Shikudo_Strike_Ledger | **Live** (v4.7.419): the strike ledger, phase 3a (Status, below) |
| 001, 002, 004, 005 | Dead (no callers, or redefined by 006) |
| 003, 008 | Inactive |
| aliases `dis`, `lock` | Call undefined functions, but sit in the switched-off SHIKUDO alias group, so they never fire (corrected 2026-10-11) |

## Offense logic findings

**Critical**
1. **`vv` throws on Shikudo, and GodMode can never run** (153 -> `shikudo.setMode`, defined only in inactive 008).
   **Resolved in v4.7.419:** 009 is switched off, and `vv` on a Shikudo ran `shikudo.dispatch()`, as `zz`
   does. Since v4.7.420 it runs `shikudo.dispatchMind` (011): the dispatch with Telepathy rounds.
2. **The lock can never use Telepathy, so it never gets past venomlock.** 007 gates Telepathy on
   `ataxia.balances.eq`, which nothing writes. Even ungated, it sends `mindlock`, `impatience`, `paralyse`
   (the game needs `MIND LOCK`, `MIND IMPATIENCE`, `MIND PARALYSE`) and `batter`, which is not an ability
   (`MIND BATTER`). So impatience, and with it hardlock/truelock/kill, is unreachable. **Fixed in v4.7.417**
   (Phase 2 progress, below). v4.7.420 rebuilt it: a MIND round of its own instead of the combo, with no
   equilibrium gate at all, and no BATTER.
3. **Flashheel is treated as ~9% leg prep, but it breaks the leg outright.** 006 flashheels in every Willow combo
   and in Gaital, so legs break (and get mended) long before the head is ready. 009 does the same. 007 breaks the
   left leg every combo. **Narrowed and fixed in v4.7.420:** the break is the players' tool (every logged Willow
   combo carries a flashheel, and most Gaital combos: Mystor 43 of 47, log 1 8 of 11; it keeps her down and
   mending), so the fix is choosing the LEG, not dropping the kick.
   006's `shikudo.flashheelKick` ranks the legs (not into her parry, not to 100% unless the round sweeps or she is
   down, an unbroken leg first) and reads the break from trigger 577; 007's `shikudoLock.flashLeg` kicks the leg
   577 has not recorded as broken. `isLegSafe` and the "never break legs" doctrine are gone.

**High**
4. **Dispatch also requires a broken leg** (006:101-105). The game needs prone + damaged head + windpipe only.
   **Fixed in v4.7.420** (006:99-105): the logged kill went out with the kicked leg at 8.4%.
5. **Crescent never fires.** 006 reads `ataxiaTemp.targetHP`, which nothing writes. 007 fires it with no prone or
   health check. 009 can never reach it (it dispatches on the same state first). **006 fixed in v4.7.417** (it
   reads ASSESS). **Both fixed in v4.7.420:** 006's Maelstrom kick and 007's `crescentReady` need a prone target
   and `ataxia_assessAtMostHalf(5)` (monk/004: a fresh ASSESS of this target, raw numbers, so 3540/7000 no
   longer passes as 50%), and 007 never pairs Crescent with a shatter.
6. **Hyperfocus key mismatch.** 006 reads `shikudo.state.hyperfocus`; the trigger writes `ataxiaTemp.hyperLimb`.
   The halved damage on the hyperfocused limb is never modelled, so head prep is overestimated. **Fixed in
   v4.7.420:** `shikudo.hyperLimb()` reads `ataxiaTemp.hyperLimb` (nil once GMCP's defence list lacks hyperfocus),
   and both prep thresholds take their damage from `getAttackDamage`, which halves it.

**Medium**
7. Parry switching is half-wired (corrected 2026-10-12; this said the "was parried" flags were only ever
   cleared). They ARE written: `flashheelWasParried` by 187 (:62 in Willow, :67 in Gaital) and
   `frontkickWasParried` by `parry/001` (:65, in Rain). 006 reads each one once and clears it while building
   the same combo (006:492, 556, 621), so the kick switches side only in the first combo 006 builds after
   the parry line. The frontkick and flashheel picks never read the persistent `ataxiaTemp.parriedLimb` (148's
   perceive line and others write it); 006's risingkick and staff picks do. **Fixed in v4.7.420:**
   `shikudo.parriedLimb()` reads 148's perceived parry, else the `tp*` flags 187 and `parry/001` set beside the
   was-parried flags, every round; Rain keeps its frontkick arm until that arm is parried. The was-parried flags
   are still written, and now only the switched-off 008 reads them.
8. 007's softlock loops (Oak -> Willow -> Rain -> Oak, 5+ kata per hop), so anorexia is cured before asthma lands.
   **Fixed in v4.7.420**, and it was worse than listed: when anorexia was cured before Rain reached kata 5, 007
   went Rain -> Tykonos -> Willow and never saw Oak again. 007 now follows Mystor's counted route (Rain -> Oak ->
   Willow, never Tykonos; Oak -> Willow only with asthma + slickness on and anorexia still off;
   `kb/combat/shikudo.md`, "Mystor's lock route, counted").
9. 009 defects: spinkick from Willow (Gaital only), kai never read (`vitals.kai` is never written), "clumsiness"
   slot sends ruku torso (slickness), transition ticks send no combo. **Resolved in v4.7.419 by retiring 009**
   (switched off; see its header). `ataxia.vitals.kai` is written since v4.7.419 (`update_stuff/004`).
10. Weapon handling: 006 hardcodes `staff489282`; the sweep trigger hardcodes one staff description. **Fixed in
   v4.7.420 for 006 and the triggers that act:** every 006 round and trigger 168 wield `shikudo.staffRef()`
   (the new `skstaff` alias, else the bare keyword `staff`), and triggers 166, `calls/008` and `gags/001` match
   any staff as early fragments (166 and `gags/001` act only in PvP, since a fragment ending before the name
   matches a denizen too). 007 still sends a bare `wield staff`. The "Start Shikudo" strike triggers 172-186 do
   nothing but a guarded call into the undefined `monk.shikudo` (179 also sets a `flash_leg` that nothing
   reads), so they are inert; the staff-strike ones, 173 the sweep among them, still name "a warped black iron
   staff coated with rust". Candidates to retire.

## Tracking findings (what the triggers record on the target)

Strikes are recorded by multiline triggers 563-585 (the strike line plus "you have dealt N% damage"), so a miss
or parry records nothing, which is correct. Problems:

1. **Strike patterns are likely too long for the line wrap.** Full-line anchored patterns with the staff name in
   them: ruku ~132-147 characters, hiru ~145, livestrike ~127, needle ~129, kai surge ~190, against a wrap of
   119-124. If they wrap they never match. Slickness/asthma/dizziness then rely only on the short third-person
   effect lines, and **ruku to the arm (clumsiness/healthleech) has no fallback**. Needs a live log to confirm.
   **Fixed:** the strike triggers match a start fragment (v4.7.413), and a light or absorbed ruku to the arm is
   recorded by the strike ledger (v4.7.419, Status below).
2. **Mind Confuse and Mind Stupidity recorded nothing** (fixed in v4.7.413). They called `tarAffedConfirmed`,
   defined only in the inactive `001_Core.lua`. **Blackout, fear, amnesia, epilepsy, pacify, deadening, daze, isolate and clamp are
   not tracked at all.**
3. **Missing prone conditionals:** hiru's confusion, hiraku's stun, risingkick's stun. **Dawnkick is not tracked**
   (first epilepsy or the delayed second one).
4. **Spinkick to the head records `mangledhead`**, unconditionally and outside the target check. Dispatch reads
   `damagedhead`. **Fixed in v4.7.413** (581 no longer records it). Since then nothing records a target's
   mangled head (632 records `damagedhead` at 100-199% head damage and `concussion` at 200%+, and only when no
   leg, arm or torso is in its own band at the same time: its checks are one elseif chain, legs first), which
   keeps vv's MIND SCYTHE dormant (v4.7.420): capture which head level the game calls mangled before writing a
   recorder.
5. **`calls/*` effect-line triggers have no target check** (sweep, frontkick, hiru, hiraku, needle): another
   Monk's hit on a third party marks your target. `calls/009` calls `tarAff`, which does not exist, so it
   throws on every jinzuku line.
6. One global `ignoreThirdPerson` flag de-duplicates strike and effect lines; duplicates defeat it. **The two
   duplicates seen are gone (v4.7.419):** 586 (a second ruku-to-the-torso recorder) is deleted, and
   `3rd_person_shikudo/001` (livestrike) now skips once like its siblings. Moving every recorder onto the
   ledger and retiring the flag is phase 3b.
7. Kai Surge writes `tAffs.prone` directly (and its pattern is ~190 characters). Kai Cripple and Enfeeble are not
   tracked. **The Kai Surge half is fixed** (v4.7.413: `tarAffed("prone")` and a short start pattern; since
   v4.7.419 a second surge restarts its 15 s window and it records whom it holds, `ataxiaTemp.kaiSurgeWho`).
   Kai Cripple and Enfeeble on a player are still not tracked.
8. Several relay lines index `ataxiaTemp.shikCombo` with no guard, so they error until a combo has been queued.
9. All of this only records for **queued** commands (the gated groups open on "[System]: Running queued").

## Docs that are wrong

Status 2026-10-12 (v4.7.419, then v4.7.420):
- CLAUDE.md's Shikudo section: the files that do not exist (200/201/203, `shikudov2`, `skv2status`), the Kai
  Surge claim and the Tykonos kata cap were removed on 2026-10-11. Its 009 and `vv` lines change with v4.7.419.
- `.claude/classes/monk.md`: the SWEEP + KURO combo, the Dispatch requirements and flashheel's own entry were
  fixed on 2026-10-11. Corrected in v4.7.419: 008 shown as the live unified system (modes, riftlock, quick
  commands, the Kai Surge dismount), 009 as reachable, the "never break legs" / `isLegSafe()` doctrine,
  Dispatch needing a leg or Gaital, Willow's exit at kata 6 (006 uses 9), the hyperfocus wiring, the alias
  map, the Telepathy `known_bug` (fixed in v4.7.417), Kai Cripple as a self-cure, the Kai Surge cost (45),
  and trigger lines that were never captured.
- `.claude/AGENTS.md` and `docs/ai-includes/agent-teams.md` named `shikudov2`, which exists nowhere in
  src_new: corrected in v4.7.419.
- Transitions: inline `combo ... transition <form>` (006) and a separate `TRANSITION TO <form> FORM` both work
  live. 007 sent `transition to the <form> form` after its combo (007:545 at v4.7.419), the wiki's detail
  wording, which no log here shows; the PvE basher sent it until v4.7.68 and the game answered with the kata
  refusal (CHANGELOG v4.7.68), so the game reads it as a TRANSITION, but a success at kata 5+ is unseen. **Since
  v4.7.420 007 sends `transition to <form> form` FIRST in its round**, the wording Mystor sends (56 times in his
  six logs), so no live code sends the THE wording any more.
- v4.7.420 brought `.claude/classes/monk.md` and `kb/combat/shikudo.md` to the rebuilt offenses: 006 and 007 on
  the shared kata policy (their own 12/24 tables and Rain's 24 gone), the staff from `skstaff` instead of
  `staff489282`, Dispatch with no leg, flashheel as the chosen break rather than prep, `vv` as dispatch +
  Telepathy (011), and the KAI CHOKE kill.

## Opportunities
- Spinkick on a prone head (the big head-damage kick) is never used. **006 sends it since v4.7.420** (prone, the
  head not yet damaged, she stays down, and one needle would not finish the head), as Mystor finished one
  (`combo Agathon needle spinkick kuro right`, LcJC-rJ5:5797); 007 spinkicks a prone target in Gaital.
- One needle crushes the windpipe; the double needle wastes a slot. **Fixed in v4.7.420** (`shikudo.needleSecond`:
  a second needle only while the head is still short of 100, else ruku torso, jinzuku, kuro).
- Mind Scythe, Kai Choke/Enfeeble/Cripple in PvP, and riftlock are not implemented. **Kai Choke is 007's kill
  since v4.7.420**; MIND SCYTHE is wired in vv (011) but off (`shikudo.tele.scythe`), pending the lock question
  (kb/CONFLICTS.md #7) and a mangled-head recorder. Enfeeble and Cripple in PvP, and riftlock, are not.
- Prone follow-ups (hiraku stun, hiru confusion, risingkick stun) are unused after a frontkick. **v4.7.420:**
  006's Tykonos risingkicks a prone head and Willow's slot 2 falls back to `hiraku light` on a prone target
  (Mystor sends it, vNTjvghY:7976); Oak already risingkicked a prone head. Hiru's confusion is still not aimed for.
- No tests cover 006, 007 or 009. (Since v4.7.417 `test_shikudo_offense.lua` loads the real 006 and 007;
  009 is switched off, which `test_monk_aliases.lua` pins.) **v4.7.420:** `test_shikudo_dispatch.lua` (59, the
  real 006 and its triggers and alias), `test_shikudo_offense.lua` (46: 44 on 007, one on 006's Crescent, one on
  the shikudo/002 trigger) and `test_shikudo_telepathy.lua` (47, 011), each loading the real monk/004 first.

## What two real combat logs settled (2026-10-11, later the same day)

The user shared two fights (`kb/raw/logs/`, written up in `kb/combat/shikudo.md`): a Shikudo killing
a sword-and-board Runewarden by Dispatch (the monk's log) and a Runewarden killing a Shikudo (hers).

- **The wrap risk was real.** Strike lines run to 147 columns ("Turning with the motion, you channel
  the momentum of your previous strike into a thrust at the solar plexus of <T> with <staff>.").
- **Most attacks print a different strike line first in a combo than later.** No strike trigger knew
  livestrike's or hiru's later line; their afflictions reached the tracker only through effect lines.
- **A strike line proves nothing on its own:** a parried strike prints it, then "<T> parries the
  attack with a deft manoeuvre." Two fallback triggers recorded from strike lines.
- **`light` strikes print no damage line** (no limb damage; the affliction still lands), and a Shield
  of Absorption can swallow the damage line too. The strike triggers need the damage line.
- **Flashheel breaks the leg** (the target mends her legs after every one). **Inline `combo ...
  transition <form>` works**; a form change needs a **kata of at least 5**. **ASSESS** gives the
  target's health ("You glance over <T> and see that her health is at 4463/5460 [81%]."); our
  `698_Assess` already stores it in `ataxiaTemp.lastAssess`. **SHATTER** breaks the shield tattoo
  inside a combo. **Sweep pairs with a kick** (`sweep flashheel left`).
- **The Dispatch as done:** one SWEEP, then FLASHHEEL on a leg every round so she never stood, then
  NEEDLE (head past 100%, throat crushed), then DISPATCH. The leg's limb damage was 8%.

## Status

- **Phase 1 (tracking): done.** v4.7.413 (shipped inside the Serpent release, commit dc30f2d5) and
  v4.7.414, with `src_new/tests/test_shikudo_tracking.lua` (30 tests against the real lines).
  Beyond the list above, v4.7.414 also fixed: 14 triggers calling the undefined `monk.shikudo`
  (and three calling `isTarget`) threw on every strike, and one would have recorded prone on US;
  the frontkick effect line's pattern never matched; the needle fallback recorded on parried
  strikes; the dedupe flag (`ignoreThirdPerson`) went stale after strikes with no effect-line
  partner, losing absorbed and light blows; losing the mind lock never cleared `mindlocked`.
- **Moved from phase 1 to phase 3, and now done:** a light or absorbed nervestrike is recorded from
  its own effect line (v4.7.415, `3rd_person_shikudo/008`). A light or absorbed ruku to the arm is
  recorded by the **strike ledger** (phase 3a, v4.7.419: `shikudo/010_Shikudo_Strike_Ledger.lua`,
  trigger 789, a flush in 318). **The boundary rule is the opposite of what this plan said:** a
  pending strike is EXPIRED at the next strike or the prompt and never committed. In Mystor's six logs
  all 202 strikes with no damage line got an outcome line at once, so committing at the boundary
  could only add phantoms; a strike that ends with no line is counted (`shikudoLedger.unresolved`)
  instead, and an arm line the ledger cannot place is counted in `shikudoLedger.refused`. A parry, a
  fumble or a shield's rebound drops the strike; no dodge line has been seen. Dawnkick's epilepsy
  line is still wanted. **Phase 3b** (move about 30 recorders onto the ledger for a per-hit dedupe,
  then remove `ignoreThirdPerson`) waits until the ledger's counters have run in live play.
- **Phase 2 (make the current modes correct): in progress** (v4.7.417, v4.7.419, v4.7.420; Phase 2
  progress, below). Add to the list above: Crescent reads `ataxiaTemp.lastAssess`; flashheel is a break, not
  prep; never SWEEP with a staff attack; send SHATTER when the target has a shield; never send a
  transition the game will judge below kata 5 (it judges the chain when the transition resolves: an
  inline one counts the combo's strikes, attacker:960-961, and one sent before the combo does not).
  v4.7.420 rebuilt both offenses and added `vv`'s Telepathy; what remains is live checks, blackout and
  scythe, and the items under "Still open".

## Telepathy and blackout (the user and Mystor, 2026-10-11)

Checked against the wiki, the two logs, the game's AFFLICTION SHOW and the code (written up in
`kb/combat/shikudo.md`, "Telepathy" and "Blackout").

- **A mind lock is needed only to reach a target outside the room**, and for certain skills such as
  Radiance and Sapience (Mystor: "lock is only needed for out of room things"). Most Telepathy needs only
  the target in the room (the user); the wiki's (*) abilities certainly, blackout unconfirmed (#7).
- **Rain is where Telepathy is cheapest:** "your equilibrium recovery shall be significantly increased"
  (wiki); MIND TRAVEL took 0.85 s in Gaital and 0.72 s in Rain. Monks also use it in other forms (log 1:
  Willow). In log 1 a Telepathy round took the place of the combo that round (the alias swapped one for
  the other); log 2's blackout arrived inside a combo round, so whether both fit in one round is open.
- **Blackout is critical** (the user): they usually TREE it off, and we give it again; under it they
  cannot see what we do to them. The game: it lasts 4 s and is cured by time. Mystor: "You can blackout,
  and then combo 1 time. And the combo is hidden." Each tree spent on blackout is a tree (about 14 s
  cooldown, log 2) not spent on the lock. The wiki says blackout needs a lock; the players' rule says not
  in the room: confirm live.

**What the code gets wrong today (add to phase 2):**
1. **No automated Telepathy can fire.** 007 checks `ataxia.balances.eq`, which nothing writes (the real
   field is `ataxia.vitals.eq`, `update_stuff/004_ataxia_Vitals_Update.lua`). 008 (switched off) and 009
   (unreachable) are the only other pickers in the offense files, and 006 has none. A fourth,
   `disruptmind()` (`levi_scripts/telepathy/001_DISRUPT.lua`), is loaded but nothing calls it. It queues
   `mind blackout`, then CONFUSE, DISRUPT and IMPATIENCE (`queue addclear free`, the right `mind <ability>`
   form, no lock gate). It sends no target: the wiki's BLACKOUT syntax takes none, and the others take an
   optional one. It keys off `tAffs.blackout`, which nothing sets for MIND BLACKOUT, so it would only ever
   send BLACKOUT. **007 fixed in v4.7.417; `disruptmind()` deleted in v4.7.419.** 006 still sends no
   Telepathy; **`vv` does since v4.7.420** (011, `shikudo.dispatchMind`), with `zz`, `xx` and `sk` left
   combo-only until it is proven live.
2. **Every ability waits on `mindlocked`** (007:426, 008:404): drop the gate for in-room abilities; keep a
   lock only for anything that truly needs one. **Fixed in 007 in v4.7.417** (008 is switched off).
3. **Bare words are sent** (`mindlock`, `impatience`, `paralyse`, `batter`, `blackout`): the game takes
   `MIND IMPATIENCE <target>` (log 1). The alias `mp` sends `mind paralyze`, and `mrap` reads an `affstrack`
   that is never assigned. **Fixed:** 007 in v4.7.417; in v4.7.419 `mp` sends `mind paralyse` (attacker
   log :1063-1064 sent, :1067 landed) and `mrap` is deleted.
4. **Prefer Rain for Telepathy rounds** and decide per round between a combo and a MIND command. **Done in
   v4.7.420:** both 007 and vv send a MIND round INSTEAD of the combo (Mystor paired a MIND affliction with a
   combo in 0 of 274 rounds), 007 with a Rain filler and vv with a Rain burst from kata 9, neither gated on
   equilibrium at the press (the `free` queue waits for it), and both count rounds when the game's run line
   shows they ran, not per press.
5. **Blackout cycle:** MIND BLACKOUT, then the hidden combo; again after their tree (or the 4 s expiry).
   **Wired in vv (011) in v4.7.420 and switched off** (`shikudo.tele.blackout = false`): it waits for our
   success line, the lock question (CONFLICTS #7) and the syntax (`mind blackout` vs `mind blackout <t>`).

**Tracking to add (phase 2):**
6. **Blackout on the target:** nothing records MIND BLACKOUT; the two blackout recorders (Psion LIGHTSTEAL
   525, Knight CONCUSS snb/008, both only on a prone target) clear it after 3.5 s where the game says 4;
   and the tracker's tree pool (`treeCurableAffsV3`) lacks blackout, so a tree under blackout never cures
   it in our model. The tree is charged to the target's OTHER afflictions instead, if it carries any:
   `onTargetTreeV3` removes the one tree-pool affliction present or branches over several, then trigger
   389's `tSingleRandom()` erases the first present one on its own list. One or two real afflictions are
   dropped while blackout stays until its timer. Use `ataxia_tarAffTimed("blackout", 4)` and put blackout
   in the tree pool. Capture our MIND BLACKOUT success line first. **Done except the capture:** blackout
   joined the tree pool in v4.7.416. In v4.7.419 both recorders use `ataxia_tarAffTimed("blackout")` (4 s,
   and a repeat restarts the clock), and the tree is one charge for every class: with V3 on, 389 calls
   `ataxia_targetTreeV3()` and `tSingleRandom({ noErase = true })` erases nothing (kb/combat/shikudo.md).
   MIND BLACKOUT itself is still not recorded.
7. **No triggers for MIND EPILEPSY, AMNESIA, STRIP, DEADENING, SCYTHE, FEAR, PACIFY, DAZE, ISOLATE or
   CLAMP**; and a MIND affliction sent outside the server queue is never seen by the gated
   `telepathy_tekura` triggers. No alias does this today: `mba`, `mp`, `mi` and `md` use
   `queue addclear free` (`mrap`, which used `queue add eqbal`, was deleted in v4.7.419). The unqueued
   `min`, `ml`, `mu`, `mhl`, `mha` and `mhd` send LOCK, UNLOCK and HALLUCINATE, which no `telepathy_tekura`
   trigger matches (the lock line, 701, is ungated). Only a MIND affliction typed by hand goes unseen.

**Form and kata facts the offense must use (log 1, wiki):**
- Willow combos with a kick cost 1.9 s against 2.1 s elsewhere (2.8 s with dawnkick); only the kick's
  reading prints, so staff-only combos are unmeasured.
- A standalone TRANSITION costs no balance and works while paralysed; a refused one keeps the kata chain.
  The comments in `basher/002_Class_Bashing.lua` at 2361 and 2620, and the live trigger
  `triggers/.../shikudo/002_Reset_Failsafe.lua`, which sets `ataxia.vitals.kata = 0` and echoes
  "-= reset kata =-" on every refusal until charstats re-reports, all assume it resets; all are wrong.
  Every strike sent counts toward the kata, fumbled and parried ones included. **All three fixed:** the
  trigger and the comment at 2620 in v4.7.417, the comment at 2361 in v4.7.419.
- ADOPT reaches a form off the transition list but costs 4.1 s of balance.
- The kata caps in 006/007/008 (12, 24 in Rain) have no source. Log 1: Oak reached 13 and Rain 18 with no
  stumble; a stumble is a chance that grows (wiki), so this rules out only a certain stumble at 12, which is
  how the code's comments put it (006 "Must transition before kata 12 stumble"), not a 12/24 limit. Kai
  Surge: the code assumes 31 kai but never checks it on a live path (TK6 sends KAI SURGE with no kai check,
  007 uses 31 only for a READY echo, and only switched-off 008 gates on it); the wiki says 45.
  **v4.7.419:** the caps are written down once, as policy taken from Mystor's play, in `ataxia/monk/004`
  (`ataxia_KATA`: leave at a chain of 12 after the combo, Rain 15, Tykonos as soon as legal; the `skata`
  alias overrides them). Every kai cost is there too (`ataxia_KAI_COST`, surge 45), and TK6 now checks it
  before its dismount. **v4.7.420:** 006 and 007 read the policy and their own tables are gone. 006 judges its
  inline transition on the chain after the combo's strikes, with a sweep round counted as TWO (Mystor's
  client marks "Kata is 1" after the sweep and "Kata is 2" after its flashheel, then the game's "You are now
  maintaining a kata chain of 2 actions.", c.iJVmpL:3868-3872); 007 sends its transition first and judges
  the chain before the combo. 007 no longer mentions the surge: its kai ability is KAI CHOKE, read through
  `ataxia_kai()`.
- KAI and MIND commands add nothing to the kata (Mystor's prompts), and a chain with no strike lapses about
  20 s after the last one ("You can no longer maintain your deadly kata.", vNTjvghY:5967; the form is kept).
  So a run of MIND rounds must let a combo through in time: `ataxia_kataAtRisk()` (monk/004, v4.7.419)
  answers that. **Since v4.7.420 007 (a MIND round only when the chain's last strike is 12 s old or less, or
  the round transitions) and vv (011) call it.**

## Phase 2 progress

**v4.7.417 (2026-10-12):**
- **The lock offense (007) sends Telepathy at all.**
  - It reads `ataxia.vitals.eq`; `ataxia.balances.eq` is written nowhere, so it had never sent one.
  - It sends `MIND IMPATIENCE / BATTER / PARALYSE <target>` instead of bare words.
  - It no longer locks first. All three are (*) abilities and need only the target in the room.
- **Crescent (006) reads the ASSESS health** (`ataxiaTemp.lastAssess`). `ataxiaTemp.targetHP` is written nowhere, so Crescent could never fire.
- **A refused transition keeps our kata.** `shikudo/002_Reset_Failsafe` no longer zeroes it, and the basher's comment at 2620 is corrected (the one at 2361 still repeated the reset story until v4.7.419).
- **Checked and already right:** both offenses refuse a transition below kata 5; 006 sends SWEEP as the only staff attack (with a kick); both send SHATTER first when the target is shielded.

**v4.7.419 (2026-10-12), the first wave of the rework** (the offenses 006 and 007 are not changed by it):
- **GodMode retired.** `vv` on a Shikudo threw on every press (it called `shikudo.setMode`, defined only in
  switched-off 008). It now runs `shikudo.dispatch()`, and `shikudo.dispatchMind` once that exists. 009 is
  switched off; its RETIRED header says why and what to salvage.
- **Shared monk state in `ataxia/monk/004_Kai_And_Kata.lua`:**
  - kai is read into its own field (`ataxia.vitals.kai`, stamped `ataxiaTemp.kaiAt`; `ataxia_kai()` is nil
    until a reading this session);
  - every kai cost is written down in `ataxia_KAI_COST`, checked by `ataxia_kaiAfford` (KAI SURGE 45, not
    31; 007 still echoes READY at 31);
  - a written kata policy, `ataxia_KATA` with `ataxia_kataShouldLeave`, overridable with the new `skata`
    alias (006 and 007 keep their own caps until they read it);
  - `ataxia_kataAtRisk`, so a run of MIND rounds can let a combo through before the chain lapses;
  - `ataxia_assessAtMostHalf`, which reads ASSESS's raw numbers for Crescent.
  Triggers 164 and 165 and a real form change keep `ataxia.vitals.kata` current, and a move into Tykonos we
  did not ask for is recorded as a probable stumble (`monk/003`).
- **Kai checks outside the Shikudo offenses:** TK6 sends its KAI SURGE / KAI CRIPPLE dismount only when it
  can pay, and trusts the mount flag only for the target it was seen on. The kaido aliases send what is
  typed and warn when kai is known short (`kc` falls back to MIND CRUSH). The Kai Surge trigger restarts its
  window on a second surge and records whom it holds.
- **Target Telepathy and blackout tracking:** blackout for the game's 4 s with a restart; MIND DISRUPT's
  10 s backstop, cancelled by the target's CONCENTRATE; `mp` sends `mind paralyse`; `mrap` and
  `disruptmind()` deleted; "You do not possess a mindlock." is no longer gagged.
- **The target's tree is one charge** (every class).
- **The strike ledger (phase 3a)** records a light or absorbed ruku to the arm; the duplicate recorders 586
  and `calls/004` are deleted, and a damaged livestrike records asthma once.
- **`queue_Scan` no longer throws on every queued monk combo** (its `shikudo_findCombo` call, defined only
  in switched-off 008, is removed), and `tools/check_orphans.py` checks scripts as callers (1b) and fields
  only switched-off files assign (2b), both failing CI.

**v4.7.420 (2026-10-12), the second wave: both offenses rebuilt, and `vv`'s Telepathy** (code detail in
`.claude/classes/monk.md`; Mystor's counts in `kb/combat/shikudo.md`, "Mystor's lock route, counted"):
- **The lock offense (007, `sr`) follows Mystor's counted route** (#8 fixed): Rain (weariness, clumsiness and
  the arm prep) -> Oak at a chain of 10 with both, or 15 -> Willow only once asthma AND slickness are on and
  anorexia is still off (all six of his Willow entries), Oak -> Gaital at 12, Willow -> Rain when the Oak half
  drops; never Tykonos. The caps come from monk/004 (`skata`).
- **007's kicks and staff** (#3 narrowed to choosing the leg): Willow and Gaital flashheel the leg trigger 577
  has not recorded as broken (`shikudoLock.flashLeg`); Oak and Maelstrom kick risingkick torso; Rain frontkicks
  the less damaged arm, and its ruku hits the same arm. One table (`shikudoLock.STAFF`) replaces six pickers:
  the strike for each missing lock affliction first, never the same strike twice.
- **007's Crescent** (#5 fixed): only on a prone target with a fresh ASSESS at half health or less
  (`crescentReady`), never in a shatter round.
- **007's round shape and kill:** the transition goes FIRST as `transition to <form> form`; a MIND round
  replaces the combo (critical impatience as the lock forms, paralyse to close it, a Rain filler; no BATTER;
  at most two in a row; none once the chain is 12 s past its last strike unless the round transitions; no
  equilibrium gate); every round ends `;assess <t>`. Truelocked, with KAI CHOKE affordable: MIND CONFUSE, MIND
  DISRUPT (at most three prelude rounds), then KAI CHOKE alone every round, Mystor's finisher in both lock wins.
- **007's round history follows the run line:** the last round, the MIND run, the prelude count, the choke
  latch and the alternated sides move when the game's run line shows the round RAN, not on the key press
  (`.claude/AGENTS.md`, "Round history moves when the GAME RUNS the round").
- **The dispatch offense (006, `zz`/`xx`/`sk`):** Dispatch needs no leg (#4 fixed); a flashheel break is read
  from 577 and `shikudo.flashheelKick` chooses the leg (#3 fixed); one needle, with a second only while the
  head is short (`needleSecond`); spinkick on a prone head; hyperfocus read from `ataxiaTemp.hyperLimb` (#6
  fixed); the parried limb read every round (#7 fixed); damage defaults from the raw lines (flashheel,
  frontkick, kuro 8.4; needle 13.4); Tykonos risingkick and Willow `hiraku light` on a prone target; the
  shared kata policy, with a sweep round judged on two strikes and Gaital held while she is prone or on the
  sweep round; Crescent on `ataxia_assessAtMostHalf(5)` (#5); `shikudo.buildRound()` (unsent rounds), and
  `;assess <t>` on combo and shatter rounds.
- **Staff and triggers** (#10 for what acts): `shikudo.staffRef()` and the `skstaff` alias replace
  `staff489282` in 006 and trigger 168; 166, `calls/008` and `gags/001` match any staff, `gags/001` gags a
  wrapped tail row too, and `gags/001` and 166 act in PvP only.
- **`vv` = dispatch + Telepathy** (new `shikudo/011`, `shikudo.dispatchMind`): a MIND round alone between
  006's combos (impatience to close a softlock, disrupt on a confused target, a Rain burst from kata 9, at
  most 4 MIND rounds per burst), never in a kill window, run-line accounting like 007's (except that any
  combo's run line ends the burst, and its state survives a reload). MIND BLACKOUT and MIND SCYTHE (with its
  MIND BATTER) are wired and switched off.

**Still open:**
- live checks for the v4.7.420 rounds: whether the run line ("[System]: Running queued <q> command: ...",
  the package's pattern; no capture in kb/raw) prints for a round that runs at once; whether a MIND command
  chained after a combo executes (`chainTelepathy` stays off); Crescent's round shape, kill line and dodge
  line; whether an appended ASSESS costs anything; whether a flashheel on an already-broken leg does
  anything; whether a target with ONE broken leg can stand (006's `staysDown` assumes not); hyperfocus's set
  and remove lines;
- the blackout cycle (its lock question, CONFLICTS #7; vv has it wired and off), after our MIND BLACKOUT line
  is captured; MIND SCYTHE likewise (#7), plus a recorder for a target's mangled head;
- whether a MIND command rebounds off a shield (every logged rebound followed a combo);
- 007's Rain filler alternates 1:1 with combos where Mystor ran bursts of up to eight; watch it in play
  (`rainTelepathy`, `maxMindRounds`), and watch a target that keeps curing anorexia (Oak -> Gaital -> Rain);
- 007 still wields the bare `staff` rather than `shikudo.staffRef()`;
- queue alerts turned off mid-session freeze the run-line history: 007's until a reload, vv's until a client
  restart (`ataxiaTemp.shikTele` survives a reload); a frozen history no longer moves the MIND cap, the
  prelude limit or vv's burst;
- code comments that still carry facts the docs corrected in v4.7.420 (next code pass): 006:588-589 (not
  every Gaital combo flashheels: Mystor 43 of 47), 006:679-683 (that Oak branch is dead: `hitsToPrep`
  returns at most 2, so a standing target's head is never kicked), 007:329 (torso damage raises KAI CHOKE
  only once the torso is damaged, Kaido.wiki:289), 011:167-168 (632 records `damagedhead` only when no leg,
  arm or torso is in its own band);
- the "Start Shikudo" triggers 172-186 (inert, guarded calls into the undefined `monk.shikudo`) to retire;
- kata caps measured rather than assumed (#8; the stumble recorder collects the evidence);
- the real Kai Surge cost (#9; `ks` now sends at kai 31-44 with a warning, so it can be captured);
- phase 3b, the per-hit dedupe through the ledger.
