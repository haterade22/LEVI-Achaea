# The Ataxia combat core: the reference that was in CLAUDE.md

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

### Ataxia Combat System
- **Affliction Tracking**: 100+ afflictions with color-coded display
- **Target Affliction Tracking**: V3 branching probability engine — single source of truth (see below)
- **Limb Tracking**: `selfLimbDamage` for own limb damage, `lb` for target limb tracking (per-target, event-driven, trigger-fed from actual game damage)
- **Fracture Management**: Two-handed combat tracking
- **Defense Management**: Automatic parrying, SSC integration
- **Basher**: `ataxiaBasher` for automated hunting (see details below)
- **Class Modules**: Serpent, Shaman, Blademaster, Infernal DWC, Apostate, Monk, and 12+ more
- **Shikudo (Monk)** (corrected 2026-10-11; the old list named files that never existed). Live:
  `shikudo/006_CC_Shikudo_Dispatch.lua` (`sk`; `zz`/`xx` when the monk has no stance),
  `011_Shikudo_Telepathy.lua` (`vv` with no stance: `shikudo.dispatchMind`, the dispatch with MIND rounds
  between its combos, v4.7.420), `007_CC_Shikudo_Lock.lua` (`sr` -> `shikudoLock.dispatch()`,
  `shikudolock()` only its fallback; status `sklstatus()`) and the strike ledger
  `010_Shikudo_Strike_Ledger.lua`. `009_CC_Shikudo_GodMode.lua` is switched off (v4.7.419; its header lists
  why and what to salvage): until then `vv` called `shikudo.setMode`, defined only in the switched-off
  008, and threw on every press. What is wrong and the three-phase rework:
  `docs/plans/shikudo-offense-review-2026-10-11.md`. Every real line from two fights, both sides, and
  Mystor's counted lock route: `kb/combat/shikudo.md`.
  - **Tracking** (v4.7.413-414, `test_shikudo_tracking.lua`): strike triggers 563-585 pair a strike
    line's START with the damage line up to two rows later (strike lines run to 147 columns);
    effect-line triggers (`3rd_person_shikudo/`, `calls/`) record what landed (nervestrike's own
    line, `3rd_person_shikudo/008`, since v4.7.415, so light nervestrikes count); 587 clears the
    `ignoreThirdPerson` dedupe flag at every strike. All but `calls/` only run while our own queued
    command's output is on screen (`queue_Scan` opens the groups, the prompt closes them).
  - **The strike ledger** (v4.7.419, `shikudo/010` + trigger 789, `test_shikudo_ledger.lua`) gives an
    effect line that names no target (ruku to the arm) to the strike in flight: 587 opens an entry per
    strike line, 789 hands it every line that can end a strike, 318 expires it before closing the gated
    groups. It records only on a line, never at the boundary; misses are counted (`.unresolved`,
    `.refused`/`.lastRefused`) and echoed under `shikudoLedger.debug`. The duplicate recorder 586 is
    gone, and livestrike (`3rd_person_shikudo/001`) skips once after 576, like its siblings.
  - **GMCP shows the new form before the lines of its block (v4.7.475, one sample,
    `kb/raw/live/shikudo-bash_2026-11-03.txt`).** After an inline transition, `ataxia.vitals.form` read the next form one row
    above the form line, so the `[SK]` line printed `Willow:12` for an Oak combo. A trigger that reads `ataxia.vitals` in the middle of a
    block can see the state at the END of that block. `shikudostance` is the form lines' own value, but a stumble changes the form with no
    line we know, so it can go stale. `shikudoEcho` (012) therefore uses a form line since the last prompt, else GMCP's form at the last
    prompt. **The `[SK]` line says `MISS` only with a miss line for every strike**; zero hits with a strike that has no outcome line is
    `UNSEEN`.
  - **A strike line is not a hit:** it prints even when parried. `light` strikes and blows a
    Shield of Absorption swallows print no damage line but still land.
  - **Facts the offense must respect** (logs, 2026-10-11): at most three attacks, one a kick; SWEEP
    pairs only with a kick, and that round counts two kata actions (c.iJVmpL:3868-3872); flashheel
    BREAKS the leg; a TRANSITION needs a kata of 5+ (inline `combo ... transition <form>` works and is
    judged after the combo's strikes; ADOPT needs none but costs 4.1 s of balance, log 1's monk, ours unmeasured); ASSESS gives the
    target's health (`698_Assess` stores `ataxiaTemp.lastAssess`); SHATTER breaks the shield tattoo
    (seen in Willow; the wiki says it works in any form); Dispatch = prone + damaged head + crushed
    throat. Willow combos with a kick cost 1.9 s of balance (ours too: "Balance used" 1.9s x13, 2.1s x115; 2.1 s in the other forms, 2.8 s with
    dawnkick; a combo without a kick prints no reading); a standalone TRANSITION costs none, and a
    refused one keeps the kata chain.
  - **Telepathy** (the user and Mystor, 2026-10-11): **a mind lock is needed only for a target outside
    the room and certain skills such as Radiance and Sapience**; most Telepathy needs only the target
    present (the wiki's (*) abilities certainly; BLACKOUT and SCYTHE carry no (*), which is open,
    `kb/CONFLICTS.md` #7). **Rain speeds equilibrium**, so monks do their Telepathy there (not only
    there). **Blackout is critical**: 4 s, they usually tree it off, we give it again, and it hides the
    combo behind it. Since v4.7.420 every MIND command goes out as a round of its own (Mystor: none of
    his 274 combos carried a MIND affliction), with no lock first and no equilibrium gate (the `free`
    queue waits for it): since 2026-11-02, 007 sends MIND IMPATIENCE only with 2 or more afflictions on the target, MIND BATTER
    in Rain while under that (`shikudo.stuckCount`, 006; `kb/raw/players/shikudo-2026-11-02.txt`), and
    MIND PARALYSE to close the lock or as a Rain filler, and kills with MIND CONFUSE, MIND DISRUPT, then
    KAI CHOKE every round; `vv` (011) puts MIND rounds between 006's combos. MIND BLACKOUT and MIND
    SCYTHE are wired in 011 and switched off (`shikudo.tele.blackout`, `shikudo.tele.scythe`) until the
    lock question (#7), our own blackout line and a recorder for a mangled head are settled. Nothing
    records MIND BLACKOUT on the target: only Psion LIGHTSTEAL and Knight CONCUSS record blackout, both
    on a prone target, and since v4.7.419 hold it for the game's 4 s through `ataxia_tarAffTimed`, a
    repeat restarting the clock (`kb/combat/shikudo.md`).
  - **Shared monk state** (v4.7.419, `ataxia/monk/004_Kai_And_Kata.lua`): kai (`ataxia_kai()`, from
    `ataxia.vitals.kai`, stamped `ataxiaTemp.kaiAt` so a kai restored from disk is unknown), its costs
    (`ataxia_kaiAfford(ability, spent, tgt)`: surge 45; unknown kai is never enough for a paid ability,
    and choke on a denizen is free), the kata POLICY (`ataxia_KATA`, `skata`: from Mystor's play, not
    game limits) and `ataxia_assessAtMostHalf`. TK6, the kaido aliases and `skata` read it, and since
    v4.7.420 006, 007 and 011 do too (their own 12/24 caps and 007's surge 31 are gone). **Pitfall:**
    `kataAt` outlives the chain, so `ataxia_kataAtRisk` tests the kata (0 = no chain; a form change
    zeroes it).
  - **The lock (007, `sr`, v4.7.420)** follows Mystor's counted route (56 transitions, none into
    Tykonos): Rain -> Oak at a chain of 10 with weariness and clumsiness on, at 15, or as soon as legal
    once anorexia is on; Oak -> Willow only with asthma + slickness on and anorexia still off; Oak ->
    Gaital at 12. The transition goes FIRST (`transition to <form> form`, judged on the chain before the
    combo) and every round ends `;assess <t>`; flashheel goes to the leg 577 has not recorded as broken,
    Oak kicks `risingkick torso`, and Crescent needs prone plus a fresh raw ASSESS at half health or less.
  - **The dispatch (006, `zz`/`xx`/`sk`, v4.7.420):** `shikudo.buildRound()` returns cmd, kind and
    transition and never sends (011 reuses it); it picks the strikes first and judges the inline
    transition on their count (a sweep round counts 2). No leg for Dispatch; `shikudo.flashheelKick`
    picks the flashheel leg; one needle, a second only while the head is short; spinkick on a prone head;
    Gaital holds while she is prone and on the sweep round (`shikudo.gaitalSweeps`); combo and shatter
    rounds ASSESS; `skstaff` sets the staff (`shikudo.staffRef()`, default the bare keyword `staff`).
  - **`srd` (013) has no combos since 2026-11-02:** MIND CRUSH in Rain, KAI CHOKE if it cannot go, `adopt rain form` alone outside
    Rain. A combo needs equilibrium, and crush and choke need balance, so they cannot share a flush (CONFLICTS #56).
  - **`vv` (011, v4.7.420):** MIND rounds between 006's combos (impatience to close a softlock, disrupt
    on a confused target, a Rain burst from kata 9, at most 4, batter under 2 afflictions), none in a kill window (prone in Gaital,
    or prone at half health in Maelstrom); kill and shield rounds go to 006.
  - **007 and 011 move their round history on the queue's run line, not on the press** (Lessons
    Learned, "Counter Incrementing"; `.claude/AGENTS.md`). Until a run line has matched, a round counts
    when sent; queue alerts turned off after that freeze 007's history until a reload and vv's (on
    `ataxiaTemp`) until a client restart. Whether the line prints for a round that runs at once is open
    (`kb/CONFLICTS.md` #35).
- **Infernal DWC Vivisect System**: Full auto-combat for Infernal DWC spec
  - `dwc/001_Infernal_DWC_Vivisect.lua` - Undercut + DSL vivisect strategy
  - Commands: `infernalDWCVivisect()`, `infernalDWCStatus()`, `infernalDWCReset()`
  - Phases: DAMAGE KILL (highest) → KILL → EXECUTE → PREP
  - Kill routes: Vivisect (all 4 limbs broken) or Damage Kill (health ≤40%)
  - RIFTLOCK mode: Counter to RESTORE ability (anorexia + slickness + addiction lock)
  - Reads afflictions through `infernalDWC.hasAff()` (`haveAff`, the V3 tracker)
