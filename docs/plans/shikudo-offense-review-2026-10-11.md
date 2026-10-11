# Shikudo offense review (2026-10-11)

Checked against the game data in the knowledge base (`kb/classes/monk.md`, raw `kb/raw/wiki/Shikudo.wiki`,
`Kaido.wiki`, `Telepathy.wiki`; `kb/afflictions/afflictions.json`). Two independent reviews (tracking and
offense logic); every critical finding below was re-checked by hand against the code.

## The game's rules that matter

**Combo:** at most three attacks, only one a kick. Sweep uses both arm balances, so it pairs only with a kick.
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
trauma); dawnkick epilepsy shortly after, a second time if prone. Telepathy (mind-locked target): MIND
IMPATIENCE / PARALYSE / CONFUSE / STUPIDITY / EPILEPSY / FEAR / AMNESIA / PACIFY / DEADENING / DAZE / DISRUPT /
ISOLATE / CLAMP / BLACKOUT, and MIND BATTER = stupidity + epilepsy + dizziness.

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
| 006_CC_Shikudo_Dispatch | **Live** dispatch path (`sk`, `zz`, `xx`) |
| 007_CC_Shikudo_Lock | **Live** lock path (`sr`) |
| 009_CC_Shikudo_GodMode | Unreachable: `vv` calls `shikudo.setMode`, which exists only in inactive 008, so `vv` throws |
| 001, 002, 004, 005 | Dead (no callers, or redefined by 006) |
| 003, 008 | Inactive |
| aliases `dis`, `lock` | Throw on every press (call undefined functions) |

## Offense logic findings

**Critical**
1. **`vv` throws on Shikudo, and GodMode can never run** (153 -> `shikudo.setMode`, defined only in inactive 008).
2. **The lock can never use Telepathy, so it never gets past venomlock.** 007 gates Telepathy on
   `ataxia.balances.eq`, which nothing writes. Even ungated, it sends `mindlock`, `impatience`, `paralyse`
   (the game needs `MIND LOCK`, `MIND IMPATIENCE`, `MIND PARALYSE`) and `batter`, which is not an ability
   (`MIND BATTER`). So impatience, and with it hardlock/truelock/kill, is unreachable.
3. **Flashheel is treated as ~9% leg prep, but it breaks the leg outright.** 006 flashheels in every Willow combo
   and in Gaital, so legs break (and get mended) long before the head is ready. 009 does the same. 007 breaks the
   left leg every combo.

**High**
4. **Dispatch also requires a broken leg** (006:101-105). The game needs prone + damaged head + windpipe only.
5. **Crescent never fires.** 006 reads `ataxiaTemp.targetHP`, which nothing writes. 007 fires it with no prone or
   health check. 009 can never reach it (it dispatches on the same state first).
6. **Hyperfocus key mismatch.** 006 reads `shikudo.state.hyperfocus`; the trigger writes `ataxiaTemp.hyperLimb`.
   The halved damage on the hyperfocused limb is never modelled, so head prep is overestimated.

**Medium**
7. Parry switching is dead (the "was parried" flags are only ever cleared). Kicks ignore the parried limb.
8. 007's softlock loops (Oak -> Willow -> Rain -> Oak, 5+ kata per hop), so anorexia is cured before asthma lands.
9. 009 defects: spinkick from Willow (Gaital only), kai never read (`vitals.kai` is never written), "clumsiness"
   slot sends ruku torso (slickness), transition ticks send no combo.
10. Weapon handling: 006 hardcodes `staff489282`; the sweep trigger hardcodes one staff description.

## Tracking findings (what the triggers record on the target)

Strikes are recorded by multiline triggers 563-585 (the strike line plus "you have dealt N% damage"), so a miss
or parry records nothing, which is correct. Problems:

1. **Strike patterns are likely too long for the line wrap.** Full-line anchored patterns with the staff name in
   them: ruku ~132-147 characters, hiru ~145, livestrike ~127, needle ~129, kai surge ~190, against a wrap of
   119-124. If they wrap they never match. Slickness/asthma/dizziness then rely only on the short third-person
   effect lines, and **ruku to the arm (clumsiness/healthleech) has no fallback**. Needs a live log to confirm.
2. **Mind Confuse and Mind Stupidity record nothing.** They call `tarAffedConfirmed`, defined only in the
   inactive `001_Core.lua`. **Blackout, fear, amnesia, epilepsy, pacify, deadening, daze, isolate and clamp are
   not tracked at all.**
3. **Missing prone conditionals:** hiru's confusion, hiraku's stun, risingkick's stun. **Dawnkick is not tracked**
   (first epilepsy or the delayed second one).
4. **Spinkick to the head records `mangledhead`**, unconditionally and outside the target check. Dispatch reads
   `damagedhead`.
5. **`calls/*` effect-line triggers have no target check** (sweep, frontkick, hiru, hiraku, needle): another
   Monk's hit on a third party marks your target. `calls/009` calls `tarAff`, which does not exist, so it
   throws on every jinzuku line.
6. One global `ignoreThirdPerson` flag de-duplicates strike and effect lines; duplicates defeat it.
7. Kai Surge writes `tAffs.prone` directly (and its pattern is ~190 characters). Kai Cripple and Enfeeble are not
   tracked.
8. Several relay lines index `ataxiaTemp.shikCombo` with no guard, so they error until a combo has been queued.
9. All of this only records for **queued** commands (the gated groups open on "[System]: Running queued").

## Docs that are wrong
- CLAUDE.md's Shikudo section names files that do not exist (200/201/203, `shikudov2`, `skv2status`), says Kai
  Surge is used (it is not), and gives a Tykonos kata cap the wiki does not have.
- `.claude/classes/monk.md` points at inactive 008, lists an illegal SWEEP + KURO combo, requires a broken leg for
  Dispatch, and models Willow flashheel as prep.
- Inline `combo ... transition <form>` (006) vs a separate `TRANSITION TO <form> FORM` (007/009): only the second
  is on the wiki.

## Opportunities
- Spinkick on a prone head (the big head-damage kick) is never used.
- One needle crushes the windpipe; the double needle wastes a slot.
- Mind Scythe, Kai Choke/Enfeeble/Cripple in PvP, and riftlock are not implemented.
- Prone follow-ups (hiraku stun, hiru confusion, risingkick stun) are unused after a frontkick.
- No tests cover 006, 007 or 009.

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
- **Still open from phase 1, moved to phase 3:** light or absorbed nervestrike and ruku to the arm
  are not recorded (no target-named effect line). Hold each strike as pending until the next
  strike or the prompt and drop it on a parry, fumble or dodge line. Dawnkick's epilepsy line is
  still wanted.
- **Phase 2 (make the current modes correct): next.** Add to the list above: Crescent reads
  `ataxiaTemp.lastAssess`; flashheel is a break, not prep; never SWEEP with a staff attack; send
  SHATTER when the target has a shield; never send a transition below kata 5.
