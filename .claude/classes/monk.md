# Monk

## Metadata
- **Type**: Base Class
- **Combat Style**: Limb | Affliction (Hybrid)
- **Difficulty**: Hard
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Tekura: Unarmed martial arts combat (default)
  -OR-
Shikudo: Staff-based martial arts (requires Trans Tekura to unlock)
Kaido: Internal energy manipulation and healing
Telepathy: Mental powers and afflictions
```

## Specializations
```yaml
Tekura:
  description: "Default unarmed martial arts"
  style: "Punches, kicks, and combinations"
  strength: "Versatile combos, good affliction application"
  unlock: "Default for all monks"

Shikudo:
  description: "Staff-based martial arts"
  style: "Staff strikes and sweeps"
  strength: "Better limb damage, different combo routes"
  unlock: "Requires Trans Tekura first"
```

## Kill Routes

### Primary Kill: Backbreaker (Tekura, Limb-Based)
```yaml
type: limb
summary: Prep all 6 limbs, break arms+torso then legs, finish with Backbreaker
implementation:
  primary: "tekura6 (002_Tekura_6Limb_Offense.lua) - 6-limb, tekura6.dispatch.run()"
  legacy: "tekura (001_Tekura_Offense.lua) - 3-limb, tekura.dispatch.run()"

phases (TK6):
  1_prep: "PREP - all 6 limbs to 86%+ (one punch, HFP ~14%, from break)"
  2_break_upper: "BREAK_UPPER - combo <tar> mnk <arm> spp <arm> hkp; HRS (Horse stance, breaks arms+torso)"
  3_break_lower: "BREAK_LOWER - combo <tar> wrt torso hfp left hfp right; BRS (Bear stance, wrenches torso + breaks legs, prones)"
  4_kill: "KILL - BBT <tar> (Backbreaker, in Bear stance)"

parry_avoidance: "During PREP skip parried limb; if last limb parried -> kai surge (dismount) -> sweep (prones) -> punch last limb"

kai_gate: |  # v4.7.419: tekura6.kaiDismount, tekura6.mountConfirmed, tekura6.surgeHoldsTarget (tekura/002)
  The dismount goes out only when ataxia_kaiAfford (ataxia/monk/004) says this round can pay: surge 45,
  cripple 41, and an unknown kai counts as not enough. It was the package's only automatic send that
  SPENDS kai (the basher's KAI CHOKE and Spirit Rend KAI ENFEEBLE are free against denizens), and it
  checked nothing, so a refused dismount left the round's sweep aimed at a rider.
  The mount flag is one global, tmounted: trigger 265 sets it, 264 clears it, and 016 switchTarget never
  resets it. So TK6 trusts it for a target only after seeing it down while that target was ours
  (mountConfirmed, checked every round). Mount confirmed and kai short: no sweep; the round falls through
  to ordinary prep (on the parried limb itself when that is the only unprepped one), echoed once per
  shortfall: "[TK6] SURGE needs 45 kai, have 40 -- no sweep, prepping instead". A flag left up by an
  earlier target sweeps anyway, as before the gate, and sends the dismount only when it is paid for
  ("-- sweeping without it (not seen mounted since targeting X)"); tk6status shows it as YES?.
  No second dismount while our own surge holds THIS target (ataxiaTemp.kaiSurgeWho, from trigger
  monk/002): the window opens just after the surge spent its kai, and nothing clears tmounted but 264.
  Open: whose attack prints 265's line, and whether KAI CRIPPLE dismounts at all.

kai_modes:  # costs from ataxia_KAI_COST (monk/004, Kaido.wiki); the code said 31 for surge until v4.7.419
  surge: "45 kai, 3.2s eq, dismount (tekura6.config.kaiMode = 'surge'). 45 is the wiki's (KW:319); no log has a surge, so it is unmeasured (kb/CONFLICTS.md #9)"
  cripple: "41 kai, 4s eq, dismount + L1 break all limbs ('cripple'). The L1 breaks are what Mystor's client showed; the dismount is the code's assumption"
```

### Alternative Kill: Scythe (Tekura TKD, Telepathy)
```yaml
type: damage
summary: Legacy 3-limb (tekura) system's alternative finisher via Telepathy
implementation: "001_Tekura_Offense.lua - tekura.PHASES.SCYTHE (phase 6)"
notes: "Set via tekura.state.preferScythe; a Telepathy-based kill, not a kick finisher"
```

### Attack Aliases (driver)
```yaml
# aliases/.../levi_062424/ -- each Monk branch tests ataxia.vitals.stance: a Stance charstat means
# Tekura, none means Shikudo (sr tests the Form charstat instead)
first_attack:  "152 zz - Tekura: tekura6.dispatch.run(), kaiMode surge (TK6 Backbreaker). Shikudo: shikudo.dispatch() (006)"
fourth_attack: "153 vv - Tekura: tekura6.dispatch.run(), kaiMode cripple. Shikudo: shikudo.dispatchMind() (011, v4.7.420: the dispatch offense with Telepathy rounds between its combos), else shikudo.dispatch() (006) if 011 is not loaded. Until v4.7.419 it called shikudo.setMode('godmode'), defined only in switched-off 008, and threw"
second_attack: "155 xx - Tekura: tekura.dispatch.run() (legacy TKD 3-limb). Shikudo: shikudo.dispatch() (006)"
group:         "154 sr - Shikudo only: shikudoLock.dispatch() (007) when a Form charstat is read; with none (Tekura) it echoes and does nothing"
shikudo:       "sk (aliases/.../shikudo/004_Dispatch.lua) -> shikudo.dispatch(); skata (shikudo/006_Kata.lua, v4.7.419) shows or overrides the kata caps; skstaff (shikudo/007_Staff.lua, v4.7.420) shows or sets the staff 006 and trigger 168 wield (007 still sends the bare 'wield staff')"
kai: |  # aliases/.../kaido/ (alias group Kaido, active)
  ks 'kai surge <t>', kcr 'kai cripple <t>', ke 'kai enfeeble <t>', kh 'kai heal', kc 'kai choke <t>', nu 'numb'.
  Since v4.7.419 ks, kcr, ke and kh always send what was typed, and when kai is KNOWN to be short
  (ataxia_kaiAfford, monk/004) they first warn: "[Kai] SURGE needs 45, have 40 -- sent anyway". Before,
  they dropped the command silently below their cost (ks at the wrong 31) and threw on a nil kai.
  kc sends MIND CRUSH instead when kai is known short ("-- mind crush instead"); an unknown kai sends the
  choke as typed, and against a denizen (a number) the choke is free. sur (kaido/001_SURGE) behaves like
  ks but sits in the switched-off KAIDO alias group.
```

**Shikudo, confirmed from two real fights (2026-10-11):** every strike, damage and effect line from
both sides, `light` strikes (no limb damage at all), form changes (a kata of 5+; inline
`... transition <form>` works), ASSESS for the target's health, SHATTER for the shield tattoo, and
the Dispatch as it was done are in `kb/combat/shikudo.md`. What the offense code gets wrong, and
the plan: `docs/plans/shikudo-offense-review-2026-10-11.md`.

### Alternative Kill: Shikudo Group Damage Route (v4.7.456)
```yaml
type: damage
summary: "For group fights (the user, 2026-10-27: 'a pure damage route for group combat'). 013,
  alias `srd` ('sr should be lock, srd should be damage'). One `queue addclear free` round: combatQueue() + wield <staff id> +
  [transition to <form> form;] + the attack + [;<EQ rider>] + [;assess, Health Inspector only]"
order:
  - "DISPATCH when 006's checkDispatchReady (INCAPACITATE on a Mhaldorian), no assess"
  - "SHATTER with this form's kick when shielded"
  - "Oak: risingkick torso livestrike ruku torso (31.8% torso a round in the 2026-10-27 log)"
  - "Maelstrom: the same, or `combo <t> crescent` ALONE when prone and known at half health or less
    (a fresh ASSESS, or IRE.Target hpperc naming the target); a ready Crescent is never traded for a
    transition"
  - "Gaital: sweep spinkick standing; needle spinkick ruku torso prone (spinkick on a prone target
    hits the head)"
  - "Rain: frontkick <side> kuro <side> ruku torso + the EQ rider; sides alternate each combo"
  - "Willow: flashheel <side> hiru hiraku; Tykonos: risingkick torso thrust torso thrust torso (both
    only on the way back to Rain)"
eq_rider: "RAIN ONLY (the user): KAI CHOKE when ataxia_kaiAfford('choke') and no held breath, else
  MIND CRUSH. Other forms: combos first, no rider"
held_breath: "No captured line. A choke cast (leviatax/004) with no landing (highlighting/063) in 1.2 s
  = MIND CRUSH for 10 s, echoed"
form_loop: "Oak -> Gaital -> Maelstrom (target at 60% or less, config.maelstromAt) or Rain; Maelstrom
  -> Oak; Rain -> Oak; Willow -> Rain; Tykonos -> Willow. ataxia_kataShouldLeave(form, kata, 0) (12,
  Rain 15); Willow and Tykonos leave at 5"
unconfirmed: "a one-attack `combo <t> crescent`; a combo and KAI CHOKE both running from one free
  entry; the held-breath line"
```

### Alternative Kill: Shikudo Lock Route (Affliction-Based)
```yaml
type: affliction
summary: Affliction lock with Shikudo + Telepathy, killed by KAI CHOKE once truelocked (007, `sr`;
  rebuilt on Mystor's counted route in v4.7.420: kb/combat/shikudo.md, "Mystor's lock route, counted")

lock_progression:  # 007's phase (shikudoLock.updatePhase): SOFTLOCK -> VENOMLOCK -> HARDLOCK -> TRUELOCK -> KILL
  softlock: "asthma + anorexia + slickness"
  venomlock: "softlock + paralysis"
  hardlock: "venomlock + impatience (Telepathy)"
  truelock: "hardlock + weariness (blocks Fitness)"

shikudo_afflictions:
  hiraku: "anorexia + stuttering (Willow form)"
  livestrike: "asthma (Oak/Maelstrom)"
  ruku_torso: "slickness (Rain/Oak/Gaital/Maelstrom)"  # AB 2499
  ruku_arms: "clumsiness, or healthleech if already clumsy"  # AB 2499; triggers 578/584
  nervestrike: "paralysis (Oak)"
  kuro: "weariness, or lethargy if already weary (Rain/Oak/Gaital)"  # AB 2501 confirmed 2026-10-04; trigger 573 records exactly this

telepathy_afflictions:
  mindlock: "Needed ONLY to reach a target outside your room, and for certain skills such as Radiance and
    Sapience (the user and Mystor, 2026-10-11). In-room affliction attacks (impatience, paralyse, batter, confuse,
    stupidity, epilepsy, ...) need no lock. The wiki also puts BLACKOUT and SCYTHE behind the lock; the players'
    rule says otherwise, so confirm each on its first live use (kb/CONFLICTS.md #7). Since 2026-10-23 (Telepathy
    115) locks and lock-based abilities treat an ADJACENT room as the same area: one room across an area border no
    longer breaks the lock or cancels Radiance. Our lock-loss handling reads the game's lines (`allies_enemies/011`),
    so it needs no change"
  impatience: "Required for hardlock. 007 sends it as soon as asthma, slickness or anorexia is on, so FOCUS
    cannot cure the anorexia hiraku is about to give (Mystor: FceAmb0o:5937, vNTjvghY:8444)"
  paralyse: "The venomlock piece when nervestrike's has been cured: 007 sends it to close softlock + impatience"
  confuse_disrupt: "007's kill prelude: a disrupted target has no equilibrium, and only CONCENTRATE brings it
    back, which confusion makes fail"
  batter: "stupidity + epilepsy + dizziness. 007 no longer sends it (v4.7.420: Mystor sent it once, just
    before his MIND SCYTHE, never in a lock); vv (011) keeps it behind shikudo.tele.scythe, off"

# Mystor's counted route (56 transitions over his six logs, never Tykonos), as 007 plays it since v4.7.420
# (shikudoLock.shouldTransition, 007:262-297). The transition goes FIRST in the round, so it is judged on the
# chain before the combo (ataxia_kataShouldLeave(form, kata, 0)): nothing below a chain of 5.
form_route:
  Rain: "-> Oak once weariness and clumsiness are on at a chain of 10 (config.rainKata; 'me shooting for 10 kata
    in rain with 2x arm prep'), at the cap (15), or at once with anorexia already on (mid-lock, what is missing
    is Oak's asthma and slickness)"
  Oak: "-> Willow only with asthma AND slickness on and anorexia still OFF (his model, all six Willow entries);
    -> Gaital at the cap (12). With anorexia already on, Oak holds for its kuro (weariness) and nervestrike
    (paralysis): Willow has neither (DART, SWEEP, HIRU, FLASHHEEL, HIRAKU, Shikudo.wiki:89)"
  Willow: "-> Rain once asthma or slickness has dropped, or at the cap (12)"
  Gaital: "-> Rain as soon as a transition is legal (Mystor stayed to 12 in 9 of 11)"
  Maelstrom: "-> Oak (007 never goes there on its own)"
  Tykonos: "-> Willow, its only exit (007 never goes there on its own)"
  why: "v4.7.417 went for anorexia first. When the target cured it before Rain reached kata 5, it went Rain ->
    Tykonos -> Willow and never saw Oak again, so asthma and nervestrike paralysis stopped going out (plan #8)"

kicks:  # shikudoLock.selectKick(form, arm, leg), 007:306-331
  Willow: "flashheel to the leg trigger 577 has NOT recorded as broken (shikudoLock.flashLeg). Flashheel BREAKS
    the leg; a second break is a second mending, on the salve balance epidermal needs to cure anorexia"
  Gaital: "spinkick on a prone target, else flashheel as in Willow"
  Rain: "frontkick to the less damaged arm; the ruku in the same combo hits the same arm (Mystor's 'frontkick
    right ruku right ruku right', vNTjvghY:928-938)"
  Maelstrom: "crescent only when shikudoLock.crescentReady(): prone AND a fresh ASSESS of this target at half
    health or less, from the raw numbers (ataxia_assessAtMostHalf(5)). Never in a shatter round"
  otherwise: "risingkick torso (Oak, Tykonos, Maelstrom without Crescent), Mystor's lock-window kick. KAI CHOKE
    deals increased damage to a target with a damaged or mangled torso (or head, or a mind clamp; any one of
    them, Kaido.wiki:289), so the torso kicks raise the choke only once the torso is damaged (the game's mild
    internal trauma). That this is why Mystor kicks the torso is our reading, not his words"
  sides: "pickSide(kind): the side with less damage in lb[target].hits; with no reading or a tie it alternates,
    and the alternation moves only when the round RUNS (state.roundAlt, committed with the round)"

staff:  # shikudoLock.STAFF + pickStaff(form, arm, leg), 007:347-390: the strike for each missing lock affliction
        # in order, then the form's fill, never the same strike twice
  Rain: "kuro <leg> (weariness), ruku <arm> (clumsiness). Rain gives no slickness of its own"
  Oak: "livestrike (asthma), ruku torso (slickness), nervestrike (paralysis), kuro <leg>, ruku <arm>; fill
    livestrike + ruku torso, so 'risingkick torso livestrike ruku torso' puts asthma and slickness on together"
  Willow: "hiraku + hiru (hiraku gives the anorexia)"
  Maelstrom: "livestrike, ruku torso, jinzuku (addiction)"
  Gaital: "ruku torso, kuro <leg>, jinzuku, ruku <arm>"
  Tykonos: "thrust left leg + thrust right leg"
  fixed: "v4.7.417's 'hiraku hiraku' in Willow, 'ruku torso ruku torso' / 'jinzuku jinzuku' in Maelstrom, and
    Rain's lone ruku torso"

round_planner:  # shikudoLock.dispatch(), 007:575-675. Every round is ONE 'queue addclear free' entry (free waits
                # for equilibrium AND balance) and ends ';assess <t>' (config.assessEachRound)
  1_shield: "a shield on the target: 'wield staff;combo <t> shatter <kick>' (a crescent pick becomes risingkick
    torso)"
  2_kill: "truelocked and KAI CHOKE affordable (10 kai through ataxia_kaiAfford('choke'); unknown kai is not):
    up to config.maxPrelude (3) MIND rounds, MIND CONFUSE if she is not confused, then MIND DISRUPT if she is
    not disrupted, then 'kai choke <t>' alone every round, no combo and no transition, until the lock breaks
    (which resets the prelude and the choke latch). Mystor's finisher in both lock wins (FceAmb0o:6309-6443,
    vNTjvghY:8840-9020)"
  3_transition: "'transition to <form> form' FIRST, the wording Mystor sends (56 times); the rest of the round
    is built for the form it leads into. v4.7.417 appended 'transition to the <form> form' AFTER the combo, a
    wording in no log"
  4_mind: "a MIND round INSTEAD of the combo when the pick is critical, or the last round run was a combo (or a
    shatter); at most config.maxMindRounds (2) in a row; and none once the chain's last strike is over
    config.lapseGuard (12) s old (ataxia_kataAtRisk), unless the round transitions: 'Transitioning will reset
    your kata chain' (Shikudo.wiki:116), so a combo would save nothing, and if the chain lapsed first the
    combo's transition would be refused and its strikes, built for the new form, go out in the old one. It
    may carry the transition (vNTjvghY:8444)"
  5_combo: "otherwise 'wield staff;[transition ...;]combo <t> <kick> <staff1> <staff2>'; a MIND command rides
    after it only with config.chainTelepathy (default off: 0 of Mystor's 274 combos carried one)"

telepathy:  # shikudoLock.selectTelepathy(form) -> cmd, critical (007:421-443);
            # shikudoLock.selectPrelude() (007:450-458)
  critical: "MIND IMPATIENCE when impatience is missing and asthma, slickness or anorexia is on; MIND PARALYSE
    when the softlock and impatience are on and paralysis is missing"
  rain_filler: "config.rainTelepathy, in a Rain round: impatience, then paralyse (none against an Apostate,
    config.classSkip, read through ataxiaNDB_getClass: an Apostate ate magnesium right after it,
    LcJC-rJ5:3124-3141), then disrupt. A filler goes out only right after a combo, so in Rain it alternates
    1:1 with combos, where Mystor's bursts ran to eight MIND rounds at kata 9-12 (FceAmb0o:2600-2944,
    vNTjvghY:3495); rainTelepathy and maxMindRounds are the knobs"
  no_eq_gate: "no equilibrium gate (v4.7.420 review): the free queue waits for equilibrium whatever the round
    is, so equilibrium at the press says nothing about what will run; the old gate swapped a critical
    impatience for a combo that ran at the same moment and landed hiraku first"
  no_lock: "no MIND LOCK first, and never bare words (v4.7.417)"

history:  # v4.7.420 review; .claude/AGENTS.md, "Round history moves when the GAME RUNS the round"
  what: "lastRound, mindRun, the prelude count, the choke latch and the alternated sides (shikudoLock.state,
    never saved)"
  when: "they move when the GAME RUNS a round, never on the press: each press sends 'queue addclear free',
    which replaces a round still waiting, so per-press history made the round that ran depend on how often
    sr was pressed (the third press of a critical impatience became a combo; the fourth press in a truelock
    skipped the whole prelude). sendRound keeps the round PENDING; shikudoLock.onQueueRan commits it when the
    pending round starts with the run line's first row, both lower-cased with whitespace dropped (007:536)"
  run_line: "'[System]: Running queued <q> command: <cmd>' (shikudoLock.RAN_PATTERN, the pattern
    clean-up/001_Queue_Scanning.lua:34 uses; no capture in kb/raw), read by a session tempRegexTrigger whose
    id lives on ataxiaTemp.shikLockRunTrigger (a reload kills the old one first). A combo's run line is about
    134 columns and wraps at this user's 119-124, so its FIRST row is matched as a prefix of the pending
    round, both lower-cased with whitespace dropped. Another command's run line moves nothing"
  fallback: "until a run line has matched one of our rounds (state.runLine), a round counts when it is sent,
    so the caps hold with queue alerts off"
  limits: "unconfirmed whether the run line prints for a round that runs at once (if it does not, that round
    is never counted: the next press replaces its pending record); a press that crosses a run line in flight
    can lose one round's count, which the caps bound; queue alerts turned off mid-session freeze the history
    until a reload (007 rebuilds shikudoLock.state when it loads, 007:50-61). A frozen history stops the MIND
    cap and the prelude limit from moving, so they bound nothing: frozen below a cap, MIND rounds (or prelude
    rounds) can go out on every press until the lapse guard (the prelude has none) or the afflictions landing
    stop them; frozen at a cap, none goes out (vv's freeze differs: vv_telepathy, below)"

kill_method: "Once truelocked: MIND CONFUSE and MIND DISRUPT, then KAI CHOKE every round (round_planner above).
  MIND SCYTHE (Mystor's third win) is wired only in vv (011), and off. Telepathy helps BUILD the lock (MIND
  IMPATIENCE is its impatience); it is not saved for after it (corrected 2026-10-11)"

implementation:
  file: "007_CC_Shikudo_Lock.lua"
  activate: "alias sr (154) -> shikudoLock.dispatch() by name, only when a Shikudo Form charstat is read;
    shikudolock() (007:754) is only its fallback"
  status: "sklstatus() / sklockstatus() (shikudoLock.status(), 007:681): phase, form with its policy cap
    (ataxia_kataLeaveAfter), kai ('KAI CHOKE READY' once affordable, '?' while unknown), mind lock, lock pieces"
  config: "shikudoLock.config (runtime only): rainKata 10, assessMaxAge 5, assessEachRound true, maxMindRounds 2,
    maxPrelude 3, chokePrelude true, chainTelepathy false, rainTelepathy true, lapseGuard 12,
    classSkip {apostate = {paralyse = true}}"
  reads: "monk/004: ataxia_kai, ataxia_kaiAfford('choke'), ataxia_kataShouldLeave(form, kata, 0),
    ataxia_kataAtRisk(12), ataxia_assessAtMostHalf(5), ataxia_kataLeaveAfter. Target afflictions through
    haveAff, else tAffs. Until v4.7.420 it read kai from ataxia.vitals.class and only echoed 'KAI SURGE READY'
    at a wrong 31; its own 12/24 kata caps (maxKata), selectDamageStaff and the six per-form staff pickers
    are gone"
  wield: "the bare 'wield staff' on combo and shatter rounds; it does not read the skstaff setting 006 uses"
  tests: "test_shikudo_offense.lua (46 tests: 44 on the real 007, one on 006's Crescent and one on the
    shikudo/002 trigger; monk/004 loaded first; the run line goes through 007's real pattern and callback,
    wrapped at 100/119/124/200 columns)"
  open: "live: whether a MIND command chained after a combo executes (chainTelepathy stays off), Crescent's
    real round shape and lines, whether an appended ASSESS costs anything, whether a flashheel on an
    already-broken leg does anything. The KILL prelude and the chokes ignore the lapse guard by design, so a
    long choke run may leave the chain lapsed for the next transition. A target that keeps curing anorexia
    could loop Oak -> Gaital -> Rain -> Oak"
```

### Shikudo Kill: Dispatch (Limb-Based) - PRIMARY
```yaml
type: limb
summary: SWEEP to prone, FLASHHEEL a leg every round to keep the target down, NEEDLE (and SPINKICK) the head and throat, DISPATCH

prerequisites:  # the game's (WIKI): prone + damaged head + crushed throat
  - Target must be prone (SWEEP or FRONTKICK)
  - Head damaged (100%+ or damagedhead)
  - Throat crushed (NEEDLE gives crushedthroat)
  # Not a game requirement, but how it was done (log 2026-10-11, kb/combat/shikudo.md): after
  # one SWEEP the monk FLASHHEELed a leg every round -- flashheel BREAKS a leg in one blow -- so
  # the target spent her turns mending and never stood up again. Dispatch landed with her left
  # leg at 8% damage.

# Leg breaks are not a Dispatch requirement, and FLASHHEEL breaks a leg in one blow whatever its
# damage, so no limb-% threshold keeps a flashheeled leg whole. In the recorded kill the broken leg
# was the TOOL: one SWEEP, then a flashheel every round so the target spent her turns mending and
# never stood, while NEEDLE finished the head and throat (kb/combat/shikudo.md, "Dispatch, as it was
# done"). (Corrected 2026-10-12: this said "NEVER break legs until head is also prepped".)

kill_flow:  # how 006 plays it since v4.7.420 (shikudo.buildRound, 006:1329; shouldTransition, 006:434-567).
            # The form exits are 006's own rules on top of the kata policy (ataxia_kataShouldLeave), not the
            # game's; the policy cap is 12 after the combo (Rain 15)
  phase_1_prep_legs:
    form: "Rain (twice the normal chain length, wiki; the policy leaves at 15 after the combo)"
    attacks: "FRONTKICK to an arm, KURO on the legs (the less damaged first); with both legs prepped, HIRU
      for the head, then ruku torso or LIGHT strikes"
    goal: "Both legs one kuro from 100% (91.6% with the 8.4 default)"
    transition: "Rain -> Oak as soon as a transition is legal once both legs AND the head are prepped (in Rain
      the head counts as prepped one hiru short, 95.7%; 006:475-481); with the legs alone prepped at kata 9+
      (006:504-506); or at the cap (006:500-502)"

  phase_2_prep_head:
    form: "Oak"
    attacks: "NERVESTRIKE first (staff before the kick: paralysis stops the parry), then RISINGKICK TORSO;
      RISINGKICK HEAD only on a prone target (stun, Shikudo.wiki:138; 006:661-663). The branch that would kick a
      standing target's head is dead: hitsToPrep returns at most 2, so `headHitsNerve <= 2` (006:674) always
      sends the torso before it is reached (006:679-683)"
    goal: "Head one nervestrike from 100% (86.6% with the 13.4 default)"
    transition: "Oak -> Gaital as soon as a transition is legal with both legs AND the head prepped; at the
      cap with both legs prepped (Gaital's NEEDLE finishes the head) or legs and head at 85%+; else back
      to Willow at the cap"

  phase_3_kill:
    form: "Gaital"
    prep: "standing and not ready: kuro the unprepped legs, then needle the head (selectGaitalStaff PHASE 0)"
    combo_1: "SWEEP + FLASHHEEL pushed to 100% (prone + a broken leg): 'combo <t> sweep flashheel <leg>', once
      she stands, is not mounted, and both legs and the head are prepped (shikudo.gaitalSweeps). SWEEP uses
      both arms, so only a kick joins it, and the round is two kata actions"
    combo_2: "she is down: NEEDLE in slot 1 (one crushes the throat); slot 2 needles again only while the head
      would still be short of 100, else ruku torso (slickness: no salve, so no mending to stand or for the
      throat), then jinzuku, then kuro on an unbroken leg (shikudo.needleSecond). The kick: SPINKICK on a
      prone head that is not yet damaged, when she stays down and one needle would not finish the head
      (Mystor's finish: 'combo Agathon needle spinkick kuro right', LcJC-rJ5:5797-5803); else a flashheel
      pushed to 100%"
    combo_3: "DISPATCH once prone + damaged head + crushed throat, sent alone, no ASSESS (INCAPACITATE on a
      Mhaldorian)"
    holds: "Gaital never leaves while she is prone, nor on the round that sweeps her, even past the cap"

dynamic_thresholds:
  description: "Prepped = ONE HIT away from breaking (100%)"
  calculation: "threshold = 100 - shikudo.getAttackDamage(attack, limb), halved on the hyperfocused limb"
  examples:  # 006's defaults since v4.7.420, from raw damage lines (attacker :71, :76, :361, :2659)
    kuro_8.4_percent: "Leg prepped at 91.6%"
    thrust_14.5_percent: "Leg prepped at 85.5% (Tykonos)"
    nervestrike_13.4_percent: "Head prepped at 86.6% in Oak (needle 13.4 in Gaital likewise; hiru 4.3 elsewhere:
      95.7%). Hyperfocused on the head, 93.3%"
  note: "006 reads shikudo_limbDamage[attack] before its defaults, but nothing writes that table, so the
    defaults apply. The strike triggers store samples in ataxiaTables.limbData.shik*, which 006 does not
    read: a sample taken on a hyperfocused limb is already halved"

edge_cases:
  partial_prep: "If legs not fully prepped in Rain, Oak can finish with KURO"
  kata_constraint: "006 leaves Rain for Oak at the cap: the chain after the combo reaches 15, kata 12+ before a
    three-strike combo (006:499-502). A completed transition starts the new form at kata 0; a refused one
    keeps the chain"
  waiting_for_kata: "Use LIGHT attacks or hit torso/arms if can't transition yet"
  parried_limbs: "Switch to alternate limb or use LIGHT on parried limb"

key_mechanics:
  spinkick:
    standing: "Hits TORSO"
    prone: "Hits HEAD with massive damage"
    prone_damaged_head: "Instantly MANGLES head (level 2 → level 3)!"
  sweep:
    effect: "Knocks target prone"
    cost: "Uses BOTH arm balances - only one kick allowed with sweep"
  light_modifier:
    effect: "NO limb damage: a light strike prints no damage line but still lands its affliction
      and its effect line (CONFIRMED, log 2026-10-11: kuro light, nervestrike light). Builds kata safely"
    usage: "Use on prepped limbs to avoid premature breaks"
  forms:
    transition: "Need 5+ kata to transition between forms. An INLINE transition is judged after the
      combo's strikes (log 2026-10-11, attacker:960-961: the chain line '3', then the refusal)"
    kata_reset: "A completed transition (or a stumble) resets the kata to 0 (wiki). A REFUSED transition
      (kata below 5) keeps the chain (log 2026-10-11: kata 3 stayed 3, and the next combo made 6)"
    kata_limit: "No game number (wiki: Rain allows twice the normal length; Tykonos never stumbles); Oak
      reached 13 with no stumble (log 2026-10-11), which rules out only a certain stumble at 12. Both
      offenses read the written policy since v4.7.420 (ataxia_KATA, ataxia/monk/004; see 'Kai, kata and
      ASSESS' below): leave at 12 after the combo, Rain 15, Tykonos as soon as legal. 006 passes its
      combo's strikes (3, or 2 for a sweep round), 007 passes 0 because its transition goes first"
    sweep_kata: "A SWEEP round is two kata actions, the sweep and its kick ('a kata chain of 2 actions',
      c.iJVmpL:3868-3872), so 006 judges a sweep round's inline transition on 2: judged on 3, a Tykonos or
      Maelstrom sweep round at a chain of 2 would carry a transition the game refuses (it reaches 4). Gaital
      holds on the sweep round and while she is prone; v4.7.419's 006 left for Maelstrom at kata 9+ whenever
      she was not dispatch-ready, the round that puts her down and a kill in progress included"
    kata_lapse: "A chain with no strike lapses about 20 s after the last one: 'You can no longer maintain
      your deadly kata.' (vNTjvghY:5967); the form is kept. KAI and MIND commands add no kata, so a run of
      them ages the chain (kb/combat/shikudo.md)"

kill_condition_check: |   # 006's shikudo.checkDispatchReady (006:99-105): the game's three conditions
  shikudo.has("prone")
  AND (lb[target].hits["head"] >= 100 OR shikudo.has("damagedhead"))   -- shikudo.headDamaged()
  AND (shikudo.has("crushedthroat") OR shikudo.has("damagedwindpipe"))
  -> DISPATCH (INCAPACITATE on a Mhaldorian)
  -- v4.7.420: no leg term. It demanded a leg at 100%, which blocks a legal Dispatch once she
  -- restores her legs; the logged kill went out with the kicked leg at 8.4% (attacker :2654, :2664).
  -- shikudo.has reads haveAff (V3), else tAffs.

notes: |
  Leg breaks are not required. As done live: SWEEP once, FLASHHEEL a leg every round to keep the
  target prone, NEEDLE until the head is past 100% and the throat is crushed, then DISPATCH.
  SPINKICK on a prone head takes it much further than a needle (Shikudo.wiki:298; +15% in Mystor's
  log where the needle did +6.7%, LcJC-rJ5:5801-5803); Mystor says a spinkick on a damaged prone head
  mangles it (level 3). 006 uses it to FINISH an undamaged head that one needle would leave short.
  Its strike line has never been captured (Mystor's client gags it); after it, "You feel something
  give way under your blow." printed twice (LcJC-rJ5:5804, c.iJVmpL:3973).
```

## Offensive Abilities
```yaml
# Tekura (Unarmed)
punch:
  skill: Tekura
  balance: bal
  effect: "Basic punch attack"
  syntax: "PUNCH <target>"

kick:
  skill: Tekura
  balance: bal
  effect: "Basic kick attack"
  syntax: "KICK <target>"

combination:
  skill: Tekura
  balance: bal
  effect: "Execute a combo (kick + 2 punches): COMBO <target> <kick> <punch1> <punch2>"
  syntax: "COMBO <target> <kick> <punch> <punch>"
  # Implemented TK6 limb->attack map (tekura6.LIMB_ATTACKS):
  limb_attacks:
    head: "wwk (kick) / ucp (punch)"
    torso: "sdk (kick) / hkp (punch)"
    arms: "mnk left|right (kick) / spp left|right (punch)"
    legs: "snk left|right (kick) / hfp left|right (punch)"

break_and_kill:
  skill: Tekura
  balance: bal
  effect: "Backbreaker kill sequence stance/break moves"
  moves:
    - hrs: "Horse stance - break arms + torso"
    - brs: "Bear stance - wrench torso + break legs (prones)"
    - wrt: "Wrench torso (used with leg break)"
    - bbt: "Backbreaker - the kill (Bear stance)"

# Shikudo (Staff) - Alternative spec
# Shikudo uses COMBO syntax: COMBO <target> <kick> <staff1> <staff2>

combo:
  skill: Shikudo
  balance: bal
  effect: "Execute a combo of kick + staff strikes"
  syntax: "COMBO <target> <kick> <staff1> [staff2]"
  notes: "Primary attack method - up to 3 attacks per combo"

sweep:
  skill: Shikudo
  balance: bal
  effect: "Knocks target prone"
  syntax: "COMBO <target> sweep <kick>"
  notes: "Uses BOTH arm balances - only ONE kick allowed with sweep"
  forms: [Tykonos, Willow, Gaital, Maelstrom]  # wiki attack lists (Shikudo.wiki:42, 89, 261, 321)

needle:
  skill: Shikudo
  balance: bal
  effect: "High head damage + windpipe damage (required for Dispatch)"
  syntax: "COMBO <target> <kick> needle [needle]"
  forms: [Gaital]
  critical: "Windpipe damage is REQUIRED for Dispatch kill. ONE needle crushes it ('with a single thrust',
    Shikudo.wiki:287; the logged Dispatch: 'flashheel left needle jinzuku', attacker :2566, :2662), so 006
    sends a second only while the head is still short of 100 (shikudo.needleSecond, v4.7.420)"

kuro:
  skill: Shikudo
  balance: bal
  effect: "Weariness; lethargy if the target is already weary"  # AB 2501 (KURO <LEFT|RIGHT>, adventurers and denizens)
  syntax: "COMBO <target> <kick> kuro left/right"
  forms: [Rain, Oak, Gaital]
  notes: "Primary leg prep attack"

nervestrike:
  skill: Shikudo
  balance: bal
  effect: "Head damage + paralysis affliction"
  syntax: "COMBO <target> <kick> nervestrike"
  forms: [Oak]

ruku:
  skill: Shikudo
  balance: bal
  effect: "Arms: clumsiness, or healthleech if already clumsy. Torso: slickness"  # AB 2499
  syntax: "COMBO <target> <kick> ruku left/right/torso"
  forms: [Rain, Oak, Gaital, Maelstrom]
  notes: "Clumsiness is highly valuable - makes enemy miss attacks"

hiru:
  skill: Shikudo
  balance: bal
  effect: "Dizziness; if prone it MAY also give confusion (not tracked -- a maybe)"  # AB 2498
  syntax: "COMBO <target> <kick> hiru"
  forms: [Willow, Rain]

livestrike:
  skill: Shikudo
  balance: bal
  effect: "Torso damage + asthma affliction"
  syntax: "COMBO <target> <kick> livestrike"
  forms: [Oak, Maelstrom]

# Shikudo Kicks
spinkick:
  skill: Shikudo
  balance: bal
  effect: "Torso damage (standing) or HEAD damage (prone)"
  syntax: "COMBO <target> spinkick <staff1> <staff2>"
  forms: [Gaital]
  critical: "If prone + damaged head → INSTANTLY MANGLES head! (Mystor; unconfirmed in game text)"
  offense: "006 (v4.7.420) spinkicks a prone head that is not damaged yet when she stays down and one needle
    would not finish it; 007 spinkicks any prone target in Gaital"

flashheel:
  skill: Shikudo
  balance: bal
  effect: "BREAKS the leg in one blow (CONFIRMED, log 2026-10-11: the target mended her legs after
    every flashheel), plus 8.4% limb damage. Not prep."
  syntax: "COMBO <target> flashheel left/right <staff1> <staff2>"
  forms: [Willow, Gaital]
  offense: "Every Willow combo in the logs carries a flashheel (Mystor 19 of 19, log 1 3 of 3), and most Gaital
    combos do (Mystor 43 of 47: the other four were two needle + spinkick finishes on a prone head,
    LcJC-rJ5:5797 and c.iJVmpL:3966, and two dawnkick rounds, c.iJVmpL:2588 and :2676; log 1 8 of 11: a
    dawnkick opener, attacker:12-34, and two staff-only 'kuro left kuro right' combos, :1906 and :1977):
    the break keeps her down and mending. Since
    v4.7.420 both offenses choose the leg (006 shikudo.flashheelKick, 007 shikudoLock.flashLeg) and read the
    break from trigger 577 (broken<side>leg). Before, 007 always kicked 'flashheel left' and 006 planned
    the kick as leg prep"

risingkick:
  skill: Shikudo
  balance: bal
  effect: "Head/torso damage, stuns if prone"
  syntax: "COMBO <target> risingkick head/torso <staff1> <staff2>"
  forms: [Tykonos, Oak, Maelstrom]

frontkick:
  skill: Shikudo
  balance: bal
  effect: "Arm damage and PRONE (CONFIRMED: '...throwing her from her feet and sending her spinning
    to the ground.')"
  syntax: "COMBO <target> frontkick left/right <staff1> <staff2>"
  forms: [Rain]

dawnkick:
  skill: Shikudo
  balance: bal
  effect: "Head damage + epilepsy (repeats if prone)"
  syntax: "COMBO <target> dawnkick <staff1> <staff2>"
  forms: [Gaital]

dispatch:
  skill: Shikudo
  balance: bal
  effect: "INSTANT KILL when conditions met"
  syntax: "DISPATCH <target>"
  requirements:  # WIKI; CONFIRMED in practice (log 2026-10-11)
    - "Target must be prone"
    - "Head damaged (100%+)"
    - "Throat crushed (from NEEDLE)"
    # (not a broken leg: it only keeps a prone target from standing)

# Kaido
# Kai is a percentage, 0-100 (the prompt shows "K:59%"; the charstats key is "Kai", and its "N%" form is
# assumed: see 'Kai, kata and ASSESS' below). Since v4.7.419 it is read into ataxia.vitals.kai
# (update_stuff/004, which keeps only the digits; before, it shared ataxia.vitals.class with Shin and
# vitals.kai was written nowhere). The costs below are ataxia_KAI_COST (ataxia/monk/004), all from the wiki
# (Kaido.wiki); boost 11, cripple 41 and choke 10 were also measured in Mystor's logs and equal it. Every
# KAI ability but BOOST and DELIVERANCE (neither lists a cooldown, KW:343, :365) spends equilibrium, so a
# queued round carries at most one, competing with MIND abilities. KAI and MIND commands add no kata.
kai:
  skill: Kaido
  balance: "kai energy; equilibrium for all but BOOST and DELIVERANCE (no cooldown listed)"
  effect: "Various kai abilities"
  syntax: "KAI <ability>"
  abilities:
    - boost: "11 kai; no cooldown listed (KW:341-343); went out in the same command as a combo (LcJC-rJ5:561)"
    - choke: "KAI CHOKE <target>: 10 kai and 50 mana, 4.00s eq; free against a denizen (KW:286-289)"
    - heal: "Heal HP: 21 kai, 3.00s eq (KW:308-310)"
    - cripple: "KAI CRIPPLE <target>: 41 kai, 4.00s eq. OFFENSIVE: 'you can crush the limbs of your target'
        (KW:297-300). Mystor's client showed all four of the target's limbs at level 1 right after one
        (LcJC-rJ5:2726; its own model, not game text). It was listed here as a self-cure until 2026-10-12"
    - surge: "KAI SURGE <target>: 45 kai, 3.20s eq; prones, and the target cannot remount for a while
        ('The effect will fade over time.', KW:315-322). Unmeasured (kb/CONFLICTS.md #9)"
    - enfeeble: "KAI ENFEEBLE <target>: 61 kai, 3.00s eq; free against a denizen with the Spirit Rend boon"
    - deliverance: "81 kai, no cooldown listed (KW:363, :365)"
    - transmute: "TRANSMUTE <0-1000>, not a KAI command: no kai and no cooldown listed (KW:252-255). Convert MANA into HEALTH (AB 893; requires balance, does not consume it) -- this line said health-to-mana until v4.7.320, which is backwards"

# Telepathy (every ability: kb/classes/monk.md; lines and costs seen in fights: kb/combat/shikudo.md)
# There is no MINDBLAST: MIND BLAST and MIND SCRAMBLE are Monk BATTLERAGE (scripts/_groups.yaml), and
# Telepathy's damage ability is MIND CRUSH (corrected 2026-10-11).
mindcrush:
  skill: Telepathy
  balance: "eq, 3.40s (wiki)"
  effect: "Physical and mental damage; works on adventurers and denizens"
  syntax: "MIND CRUSH [target]"

mindlock:
  skill: Telepathy
  balance: "none listed; 80 mana (wiki)"
  effect: "Locks your mind to the target's. Needed only to reach a target outside your room and for certain
    skills such as Radiance and Sapience (the user and Mystor, 2026-10-11)"
  syntax: "MIND LOCK <target>"  # live: 'mind lock Claes' (log 2026-10-11); MINDLOCK was wrong
```

## Defensive Abilities
```yaml
fitness:
  skill: Tekura
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]

kai_heal:
  skill: Kaido
  balance: "eq, 3.00s; 21 kai"
  effect: "Heal HP using kai"
  syntax: "KAI HEAL"
  notes: "21 kai and 3.00s of equilibrium (Kaido.wiki:308-310)"

# KAI CRIPPLE is not defensive: it crushes the TARGET's limbs (Offensive Abilities, Kaido, above).
```

## Passive Cures
```yaml
fitness:
  cures: [asthma]
  blocked_by: [weariness]
  trigger: "Passive, automatic on asthma gain"
```

## Limb Strategy
```yaml
enabled: true
# Tekura (TK6): prep ALL 6 limbs, then break upper (arms+torso) and lower (legs), then Backbreaker
tekura_target_order: [head, torso, left_arm, right_arm, left_leg, right_leg]
tekura_break_requirements: {all_six_limbs: "86%+ prep -> break"}
# Shikudo (dispatch): prone + damaged head + crushed throat (NEEDLE), then DISPATCH; a flashheeled leg
# keeps a swept target down but is not required (006's check demanded one until v4.7.420)
shikudo_target_order: [left_leg, right_leg, head, windpipe]  # 006's prep order
finisher_options:
  - "BBT <target>"       # Tekura Backbreaker (all limbs broken, prone)
  - "DISPATCH <target>"  # Shikudo (prone + damaged head + crushed throat; any form, outside a combo)
```

## Bashing (PvE)
```yaml
# Entry point: ataxiaBasher_monkBashing2 (basher/002_Class_Bashing.lua). Spec resolved from
# charstats: Tekura if vitals.stance present, else Shikudo if vitals.form present.
tekura_attack: "unwield all; combo <tar> sdk ucp ucp"   # rhk instead of sdk when shieldbreak needed
shikudo_attack: "per-form COMBOs via shikudoBashCombo, riding Willow(leaveAt 9) -> Rain(5) -> Oak(5)"
shikudo_notes: "inline TRANSITION suffix on the combo; shatter variant for shieldbreak. leaveAt is read BEFORE the combo, so Willow leaves at a chain of 12 after it (policy, kb/CONFLICTS.md #8). When it queues a transition it zeroes ataxia.vitals.kata at once: charstats still shows the old kata for a tick, and without the zero the next prompt would append a second transition that the new chain of 3 refuses. A refused transition costs only the form change; the game keeps the chain (v4.7.68's 'fail loop' story was retracted in v4.7.69). These PvE literals (SHIKUDO_BASH_ROTATION) are separate from the PvP skata caps on purpose"
transmute_gapfiller: "transmute to top up HP ONLY when sip balance is down and HP <= transmuteat (default 70)"
transmute_sharp_mind: "with the Sharp Mind boon, in the tower: a plain top-up at HP <= sharpmindat (default 90), sip balance ignored; floor + transmuteto unchanged (v4.7.320)"
crushbash: "if ataxia.settings.crushbash set, sends 'mind crush <target>' instead"
mind_crush_rider: "v4.7.457, int monk: 'mind crush <tar>; ' rides the idle EQ before the combo every round, Shikudo (any form) and Tekura (ataxiaBasher_monkMindCrush). Last in the eq chain: Spirit Rend > Kai Unleashed choke > Senseless Flurry numb > mind crush. KAI CHOKE is never sent without the Kai Unleashed boon. Int spec = `bash mindcrush auto|on|off` (ataxiaBasher.monkMindCrush; auto = intelligence > strength from STAT AND the QUICK-WITTED trait since v4.7.458 -- user: quick-witted is the eq trait (mind crush, kai choke), NIMBLE the balance one; either unread = off). Skipped when GMCP eq is down (3.40s eq vs a ~2s combo), when mana - 150 would pass the manause floor (default 30%), and on shielded rounds"
int_monk_form: "v4.7.458: an int monk always bashes in RAIN (Shikudo) or DRAGON stance (Tekura). Bash start sends 'adopt rain form' / 'drs' as crushbash does (genrunning/003). In Rain the combo never transitions out; outside Rain SHIKUDO_INT_ROTATION moves toward it at kata 5 (Oak/Tykonos -> Willow -> Rain, Gaital -> Rain, Maelstrom -> Oak)"
shield: "Monk never spends rage on Splinterkick (spk) to raze - both specs break denizen shields free (shatter / rhk)"

# Battlerage (ataxiaBasher_monkBattlerage). Kit: SBP 14 (small dmg), MIND SCRAMBLE 22 (Clumsy),
# SPK 17 (shieldbreak, never used), MIND BLAST 25 (conditional), RPST 25 (Inhibit), TNK 36 (large dmg).
battlerage_priority:
  1: "RPST (Ripplestrike) -> Inhibit, ONLY vs healer denizens or the 'Sanguine Restoration' Mnemosyne affix"
  2: "TNK (Tornadokick, large) then SBP (Spinningbackfist, small) for damage"
  3: "MIND SCRAMBLE -> Clumsy (mob misses ~33%) with surplus rage (>=22)"
  note: "MIND BLAST deliberately not prioritised (its bonus wants Weakness/Sensitivity, not in Monk kit)"
```

## Fighting Against This Class
```yaml
priority_cures:
  - weariness: "Restores your Fitness if you have it"
  - broken_limbs: "Prevent Backbreaker (Tekura) / Dispatch (Shikudo) setup"
  - prone: "Stand up immediately (Sweep prones for Dispatch/Backbreaker)"
  - windpipe: "Mend/restore head-throat - Dispatch needs damagedwindpipe (from NEEDLE)"
  - mental_affs: "Telepathy can stack mental afflictions"

dangerous_abilities:
  - backbreaker: "Tekura BBT - instant kill once all 6 limbs broken and prone"
  - dispatch: "Shikudo - instant kill when prone with a damaged head and a crushed throat (no broken leg needed)"
  - combinations: "Fast limb damage accumulation (COMBO kick + punches/staff)"
  - kai_abilities: "Self-healing, and Kai Surge to dismount you"

avoid:
  - "Letting all limbs (or legs+head) reach break threshold"
  - "Being proned by Sweep with legs broken"
  - "Letting them combo freely"
  - "Ignoring mental afflictions from Telepathy"

recommended_strategy: |
  Parry legs/head to slow the Backbreaker/Dispatch setup.
  Restore your windpipe to deny the Shikudo Dispatch condition.
  Keep restoration salve ready for limb damage; stand up out of prone fast.
  Track their kai balance (Kai Surge dismount / Cripple).
  Cure mental afflictions from Telepathy.
  Apply weariness to block their Fitness.
```

## Shikudo Forms
```yaml
# Shikudo uses 6 forms with different attacks available per form
# Must have 5+ kata to transition between forms
# The max_kata values below are OUR POLICY, NOT the game's: ataxia_KATA.leaveAfter (ataxia/monk/004,
# v4.7.419), the chain AFTER the combo at which a form is left, overridable with `skata`, and read by
# both offenses since v4.7.420 (their own 12/24 tables are gone). The wiki gives no number (Rain allows
# "twice the normal length"; Tykonos is exempt and can hold a chain indefinitely), and a log (2026-10-11)
# shows Oak at kata 13 with no stumble. The stumble line has never been captured. The numbers come from
# Mystor's play (kb/combat/shikudo.md, "Mystor's lock route, counted").

Tykonos:
  max_kata: none  # wiki: Tykonos holds a chain indefinitely. The policy leaves it as soon as a transition is legal (a chain of 5 after the combo); 007 never goes there
  staff_attacks: [thrust, sweep]
  kicks: [risingkick]
  transitions_to: [Willow]
  style: "Defensive, basic attacks"
  notes: "Starting form, limited offensive options"

Willow:
  max_kata: 12
  staff_attacks: [dart, sweep, hiru, hiraku]  # sweep added 2026-10-11 (wiki SW:89)
  kicks: [flashheel]
  transitions_to: [Rain]
  style: "Speed-focused"
  notes: "Good for head damage (hiru, hiraku)"

Rain:
  max_kata: 15  # the policy (the code said 24 until v4.7.420). The wiki doubles the chain length; Mystor took Rain to 15 in 10 of his 17 Rain exits, 16 at most
  staff_attacks: [kuro, hiru, ruku]
  kicks: [frontkick]
  transitions_to: [Tykonos, Oak]
  style: "Best for damage building"
  notes: "PRIMARY PREP FORM - 15 kata = 5 three-strike combos of sustained damage. Equilibrium recovers
    fastest here, so it is where the Telepathy goes (007's Rain filler, vv's Rain burst)"

Oak:
  max_kata: 12
  staff_attacks: [kuro, nervestrike, livestrike, ruku]
  kicks: [risingkick]
  transitions_to: [Willow, Gaital]
  style: "Power and afflictions"
  notes: "Good for paralysis (nervestrike) and asthma (livestrike)"

Gaital:
  max_kata: 12
  staff_attacks: [needle, sweep, kuro, ruku, jinzuku]
  kicks: [spinkick, flashheel, dawnkick]
  transitions_to: [Rain, Maelstrom]
  style: "KILL FORM"
  notes: "Has SWEEP, NEEDLE (crushed throat) and SPINKICK (the head, on a prone target): the Dispatch SETUP lives here"
  critical: "DISPATCH is not a Gaital attack: it is sent outside a combo, from ANY form, and may name a form to flow into on success (wiki: DISPATCH|INCAPACITATE <target> [form], Shikudo.wiki:365, 369). Seen live from Rain: Mystor, at Gaital 5, sent 'transition to rain form/dispatch Agathon oak' and killed (LcJC-rJ5:5847-5859, his client's summary lines)"

Maelstrom:
  max_kata: 12
  staff_attacks: [ruku, livestrike, jinzuku, sweep]
  kicks: [risingkick, crescent]
  transitions_to: [Oak]
  style: "Death form"
  notes: "Alternative kill with CRESCENT (prone, half health or less: slain; above half, dodged with greatly
    increased recovery, Shikudo.wiki:358). Both offenses gate it on prone + a fresh ASSESS at half or less"

# Form Transition Paths
transition_map:
  Tykonos: [Willow]
  Willow: [Rain]
  Rain: [Tykonos, Oak]
  Oak: [Willow, Gaital]
  Gaital: [Rain, Maelstrom]
  Maelstrom: [Oak]

# 006's form cycle (shikudo.shouldTransition, 006:434-567): Willow → Rain → Oak → Gaital (when ready).
# An inline transition is judged on the chain AFTER the combo's strikes (3, or 2 in a sweep round), so a
# "leave at 12" form leaves when the chain reads 9+ before a three-strike combo.
#
# Willow: HEAD prep with hiru/hiraku; 006 leaves for Rain at the cap (006:487-492)
# Rain: PRIMARY LEG prep with kuro (the cap is 15), can also prep the head with hiru; leaves for Oak as
#      soon as a transition is legal once both legs AND the head are prepped (006:475-481), with both legs
#      prepped at kata 9+ (006:504-506), or at the cap
# Oak: HEAD prep with nervestrike. 006 goes on to Gaital as soon as a transition is legal once both legs
#      AND the head are prepped (006:475-481); at the cap once both legs are prepped, head or not
#      (Gaital's NEEDLE finishes the head), or with both legs and the head at 85%+; otherwise, at the cap,
#      back to Willow (006:514-551)
# Gaital: the kill form - sweep, needle, spinkick on a prone head (v4.7.420). It never leaves while she is
#      prone or on the round that sweeps her (shikudo.gaitalSweeps), even past the cap; standing and not
#      ready at the cap, it goes to Maelstrom (006:457-469). DISPATCH works from any form
#
# If kill fails in Gaital: Maelstrom → Oak → (continue cycle)
#
# Key: Dispatch needs prone + damaged head + crushed throat. 006 enters Gaital from Oak once both legs
#      are prepped (or legs and head are at 85%+), and SWEEPs there only once the legs AND the head are
#      prepped (selectGaitalStaff PHASE 0-1, 006:1087-1134; a MOUNTED target whose prep is not done is
#      swept by the fallback at 006:1147-1157): its own rules, not the game's
# Key: Rain's 15 = 5 three-strike combos of sustained prep time
#
# 007's route (the lock) is Mystor's counted one: Rain → Oak → Willow, Oak → Gaital at its cap, never
# Tykonos (Kill Routes, "Alternative Kill: Shikudo Lock Route", form_route)
```

## Shikudo Implementation (LEVI System)
```yaml
# LIVE: 006_CC_Shikudo_Dispatch.lua (dispatch), 007_CC_Shikudo_Lock.lua (lock) and 011_Shikudo_Telepathy.lua
# (vv: the dispatch with Telepathy, v4.7.420), with the strike ledger (010) and the shared monk state in
# ataxia/monk/004. 008 (the old "unified" file with setMode, riftlock and godmode) is SWITCHED OFF, so none
# of its modes or commands exist at runtime. (Corrected 2026-10-12: this section presented 008 as the live
# system.) The lock (007) is in Kill Routes, "Alternative Kill: Shikudo Lock Route".

# On-disk files (levi_scripts/shikudo/ holds 001-011):
files:
  001_Shikudo.lua: "dead (no callers, or redefined by 006)"
  002_Shikudo_R2.lua: "dead"
  003_Dispatch_Dat_Hoe.lua: "switched off"
  004_Levi_Dispatch.lua: "dead"
  005_Shikudo_Needle_Logic.lua: "dead"
  006_CC_Shikudo_Dispatch.lua: "Dispatch -- LIVE (sk; zz/xx when the monk has no stance; vv's combo, kill and
    shield rounds through 011)"
  007_CC_Shikudo_Lock.lua: "Lock -- LIVE (sr -> shikudoLock.dispatch(); shikudolock() is only its fallback)"
  008_CC_Shikudo_Offense_ALL.lua: "old unified offense (all modes) -- switched off"
  009_CC_Shikudo_GodMode.lua: "God Mode -- RETIRED, switched off in v4.7.419. Nothing could reach it (only 008's
    setMode routed to it) and its run() threw on the first tick. Its header lists why, and what a later
    riftlock or arm route should salvage. skgodmode()/skgmstatus() went with it"
  010_Shikudo_Strike_Ledger.lua: "Strike ledger -- LIVE (v4.7.419): records a light or absorbed ruku to the arm from
    its untargeted effect line (kb/combat/shikudo.md, 'What our triggers record')"
  011_Shikudo_Telepathy.lua: "vv's Telepathy -- LIVE (v4.7.420): shikudo.dispatchMind, MIND rounds between 006's
    combos (vv_telepathy, below)"
  012_Shikudo_Combo_Echo.lua: "The [SK] combo line -- LIVE (v4.7.456): one line per combo from the strike ledger
    (hits, misses and why, limb damage, afflictions, form:kata); skecho on|off"
  013_Shikudo_Group_Damage.lua: "Group damage route -- LIVE (v4.7.456): srd
    (Alternative Kill: Shikudo Group Damage Route, above)"

# Mode selection: none live. shikudo.setMode / shikudo.mode / godmode exist only in switched-off 008
# (008:67). vv no longer calls setMode (v4.7.419); it runs shikudo.dispatchMind (011) since v4.7.420.

# Dispatch behaviour specifics (006, live)
dispatch_specifics:
  round: "shikudo.buildRound() (006:1329) returns cmd, kind, transition and NEVER sends: kind 'dispatch'
    ('wield <staff>;dispatch <t>', no ASSESS), 'incapacitate' (the same, on a Mhaldorian), 'shatter'
    ('wield <staff>;combo <t> shatter <kick>;assess <t>') or 'combo' ('wield <staff>;combo <t> <strikes>
    [transition <form>];assess <t>'); nil with no target. It chooses the strikes first and judges the
    inline transition on their count. It never calls combatQueue(): shikudo.dispatch() (006:1361) calls
    combatQueue() first (it can drop a Deliverance target for a new one), then sends 'queue addclear free '
    .. prefix .. round; 011 reuses buildRound for the combo hidden behind a blackout"
  staff: "Every round wields shikudo.staffRef(): the skstaff setting (ataxia.settings.shikudoStaff, saved),
    else (v4.7.456) the id of an inventory item named '... staff' from GMCP Char.Items (a willow or oak staff
    first, then the staff2 weapon slot, then a wielded staff; a name not ending in 'staff' never), else the
    bare keyword 'staff' with a one-time warning. The bare keyword took the user's illusion staff (a
    Shar'ilian lightspire) on about half the rounds of the 2026-10-27 group log, and the game refused the
    combo; 007 sent it in two places. Trigger 794 on the refusal drops the id. Until v4.7.420 it was
    one player's item, staff489282, in four places (and in trigger 168). combatQueue()'s prefix ('g body;
    g gold;stand;' plus a parry or a chase step when one is due; ataxia/ataxia/003_Queueing_Related.lua)
    goes in front"
  assess: "Combo and shatter rounds end ';assess <t>' (shikudo.config.assessEachRound, default true, runtime
    only, no alias) ONLY with the Health Inspector trait (v4.7.456, shikudo.assessSuffix; misc_scripts/031
    reads TRAIT LIST KNOWN and filters every class's sends). Without it ASSESS costs balance, so the user's rounds carry none, and Crescent
    needs a fresh manual ASSESS or the server's IRE.Target hpperc (013)"
  target_guard: "v4.7.456: shikudo.guardTarget (006) refuses a target that died in the last 6 s (401, 795)
    unless the room shows it again, and a combo at a target not in ataxia.playersHere; 006, 007, 011, 013"
  mhaldorian_safety: "On a Mhaldorian target (tCity), sends INCAPACITATE instead of DISPATCH (friendly-fire
    safety, 006:1338-1340)"
  shield: "If target shielded (tAffs.shield), SHATTER inside the combo (006:1345-1347)"
  kai_surge: "006 never sends KAI SURGE. The Rain dismount and the Gaital kai window were 008-only (switched
    off). Only TK6 sends a surge automatically; 007's kai ability is KAI CHOKE, its kill (v4.7.420)"

quick_commands:  # live functions only
  dispatch: ["sk alias", "shikudo.dispatch() (006:1361)", "levishikudodispatch() (006:1424)"]
  dispatch_round: ["shikudo.buildRound() (006:1329): the round, unsent"]
  dispatch_status: ["shikudo.status() / skstatus() (006:1432, 1490)"]
  vv: ["vv alias (153)", "shikudo.dispatchMind() (011:327)"]
  lock: ["sr alias", "shikudoLock.dispatch()", "shikudolock() (007:754)"]
  group_damage: ["srd alias", "shikudoDmg.group() -> shikudoDmg.dispatch() (013)"]
  combo_echo: ["skecho on|off -> shikudoEcho.command() (012)"]
  traits: ["traits / traits show -> ataxia_traitCommand() (misc_scripts/031)"]
  lock_status: ["sklstatus() / sklockstatus() (007:758, 762)"]
  kata_caps: ["skata alias -> ataxia_kataCommand() (monk/004, v4.7.419)"]
  staff: ["skstaff [ITEM|clear] alias -> shikudo.staffCommand() (006:226, v4.7.420)"]
  # skdispatch, sklock, skriftlock, shikudoriftlock, shikudo.reset, shikudo.setMode: 008 only (switched off)

# Current dispatch system (006_CC_Shikudo_Dispatch.lua; the helpers below are 006:133-366)
current_system:
  description: "Dynamic threshold-based dispatch; the flashheel leg is chosen, not protected (v4.7.420)"

  dynamic_thresholds:
    purpose: "Calculate 'prepped' based on actual damage per hit"
    functions:
      - "shikudo.getLimbDamage(limb) → safely gets lb[target].hits[limb] or 0"
      - "shikudo.getAttackDamage(attack, limb) → the default (flashheel, frontkick, kuro 8.4; needle and
        nervestrike 13.4; spinkick 27; thrust 14.5; hiru, hiraku 4.3), halved on the hyperfocused limb"
      - "shikudo.getLegPrepThreshold(leg) → 100 - kuro damage (91.6%)"
      - "shikudo.getHeadPrepThreshold() → 100 - the form's head attack (nervestrike in Oak, needle in Gaital,
        hiru otherwise), through getAttackDamage. Until v4.7.420 it used nervestrike 7.8 where hitsToPrep
        used 13.4"
      - "shikudo.isLegPrepped(leg) → true if leg >= threshold"
      - "shikudo.areBothLegsPrepped() → true if both legs prepped"
      - "shikudo.isDynamicHeadPrepped() → true if head >= threshold"
      - "shikudo.getFocusLeg() → returns leg with LESS damage (hit first to balance prep)"
      - "shikudo.getOffLeg() → returns leg with MORE damage (secondary target)"
      # shikudo.isLegSafe and the display-only shikudo.maxKata table are gone (v4.7.420)

  state_reads:  # v4.7.420, 006:147-244 and 363: one read per fact, so the kick, the staff and the kill agree
    - "shikudo.has(aff) → haveAff (V3), else tAffs"
    - "shikudo.legBroken(side) → broken<side>leg (trigger 577, from the flashheel's damage line, so a flashheel
      whose damage a Shield of Absorption swallows is not recorded), damaged<side>leg,
      or the limb at 100%+. 006 used to call a leg broken only at 100%, so it never saw a flashheel break"
    - "shikudo.headDamaged() → head 100%+ or damagedhead"
    - "shikudo.staysDown() → both legs broken, or a leg at 100%+ (that takes restoration, not one mend).
      Whether a target with ONE broken leg can stand is unconfirmed; our own STAND is refused with one"
    - "shikudo.hyperLimb() → the hyperfocused limb (ataxiaTemp.hyperLimb), nil once GMCP's defence list is
      known and holds no hyperfocus"
    - "shikudo.parriedLimb() → trigger 148's perceived parry (ataxiaTemp.parriedLimb), else the tp* flag
      triggers 187 and parry/001 set; the hyperfocused limb counts as open. Read fresh every round"
    - "shikudo.gaitalSweeps() → this Gaital round sweeps: she stands, is not mounted, both legs and the head
      are prepped. The Gaital kick, the staff's PHASE 1 and shouldTransition all ask it"
    - "shikudo.staffRef() / shikudo.staffCommand(arg) → the staff to wield, and the skstaff alias"

  limb_tracking:
    source: "lb[target].hits table from Romaen's limb counter"
    access_pattern: 'lb[target].hits["left leg"], lb[target].hits["right leg"], lb[target].hits["head"]'
    helper: "shikudo.getLimbDamage(limb) provides safe access with nil checks"
    note: "NOT tLimbs - that's for a different limb tracking system"

  hyperfocus:
    description: "Bypasses parry on a limb at cost of HALF damage"
    syntax: "HYPERFOCUS <limb|NONE>"
    balance_cost: "3.4 seconds"
    strategy: "ALWAYS hyperfocus HEAD at combat start, never switch"
    reason: "Head is key prep target; 3.4s cost makes switching impractical"
    damage_adjustment: "Damage on the hyperfocused limb is halved (Shikudo.wiki:336), so the head prep threshold
      moves from 86.6% to 93.3% with needle or nervestrike. Mystor's needle did +6.7% (13.4 / 2) and his client
      logs '-Def: hyperfocus.' in two other fights, so his spinkick's +15% was most likely halved too"
    functions:
      - "shikudo.hyperLimb() (006:182): reads ataxiaTemp.hyperLimb, which trigger shikudo/003_Hyperfocus_Detection
        writes (003:39). Since v4.7.420 getAttackDamage, the thresholds and parriedLimb read it; before, 006
        read shikudo.state.hyperfocus, which nothing wrote, so the halving never applied (plan finding 6).
        003's pattern and the remove line are uncaptured (only Mystor's '-Def: hyperfocus.' is in a log), so
        hyperLimb() fails safe: once GMCP's defence list is known and lacks hyperfocus it returns nil"
      - "shikudo.setHyperfocus(limb) / resetHyperfocus() (006:378, 415): write and clear ataxiaTemp.hyperLimb.
        Nothing calls them; kept for a manual reset"
      - "shikudo.getHyperfocusCommand() (006:404) → returns 'hyperfocus head' if not already set"
      - "shikudo.isHyperfocusSet() (006:397) → true if head is hyperfocused"
    auto_behavior: "None: 006 sends no HYPERFOCUS ('Removed automatic hyperfocus - user will do this manually',
      006:1398-1399)"

  transition_priority:  # shikudo.shouldTransition([strikes]), 006:434-567. Legal once the chain after the
                        # combo's strikes reaches 5 (kata + strikes); 'the cap' is ataxia_kataShouldLeave(form,
                        # kata, strikes): 12 after the combo, Rain 15, Tykonos at once
    flow: "Willow → Rain → Oak → Gaital (when ready)"
    strikes: "buildRound passes the combo's real count: 3, or 2 for a sweep round (a sweep takes both arms and
      pairs only with a kick). A direct call defaults to 3; pass 0 for a transition sent without a combo"
    0_all_ready: "BOTH legs AND head prepped, once legal → one step toward Gaital (006:475-481)"
    1_willow:
      at_cap: "Willow at the cap → Rain (006:487-492): a chain of 9+ before a three-strike combo"
    2_rain:
      legs_prepped: "Rain legs prepped + kata 9+ → Oak (for nervestrike head prep, 006:504-506)"
      at_cap: "Rain at the cap (15 after the combo) → Oak (006:500-502). Until v4.7.420 this was kata 21+,
        before a cap of 24"
    3_oak:  # all at the cap (006:514-551)
      legs_prepped: "both legs prepped, head or not → Gaital, whose NEEDLE finishes the head"
      close: "both legs and the head at 85%+ → Gaital"
      not_ready: "otherwise → Willow (cycle back for more prep)"
    4_gaital:
      hold: "she is prone, or this round sweeps her (shikudo.gaitalSweeps): stay, even past the cap
        (006:457-462). v4.7.419 left for Maelstrom at kata 9+ whenever she was not dispatch-ready, so a
        kill in progress, and the very round that puts her down, could leave the form the needle is in"
      stuck: "standing, not ready to sweep, at the cap → Maelstrom → Oak (cycle out, 006:465-467)"
    5_other: "Tykonos → Willow and Maelstrom → Oak at the cap (006:556-564)"

  transition_syntax:
    description: "Both forms work live: inline at the end of a combo (006:1270-1272, 1292-1294; log 1,
      attacker:443, 'combo Claes frontkick left kuro left ruku right transition oak'), or a separate
      TRANSITION TO <FORM> FORM (log 1, e.g. attacker:321 'transition to Rain form'; it costs no balance and
      twice went through while paralysed). 006 sends the inline form. 007 sends 'transition to <form> form'
      FIRST in its round since v4.7.420, the wording Mystor sends (56 times, e.g. 'transition to rain
      form/dispatch Agathon oak', LcJC-rJ5:5847); until then it appended 'transition to the <form> form'
      after its combo, a wording in no log"
    example: "combo target risingkick head nervestrike livestrike transition willow"
    note: "The caps are policy (kb/CONFLICTS.md #8: Oak 13 and Rain 18 seen with no stumble); 006's comment
      'Must transition before kata 12 stumble' went with its own table in v4.7.420"

  flashheel_leg:  # shikudo.flashheelKick(pushToDamaged), 006:599-632 (v4.7.420). It replaced isLegSafe and the
                  # 'safe to break' planning, which sent a flashheel in every branch anyway
    principle: "Every landed flashheel BREAKS the leg and adds about 8.4%, so the only choices are which leg
      and whether to take it to 100% (damaged: restoration, not one mend). Every logged Willow combo
      flashheels, and most Gaital combos (Mystor 43 of 47, log 1 8 of 11; flashheel, above), to keep her
      down and mending"
    ranking: "lower is better, item by item: (1) not the leg she parries; (2) not to 100% unless pushing;
      (3) a leg not broken now (a fresh break is one more mend before she stands); (4) when pushing, a leg
      this kick takes to 100%, then one it leaves short, and last one already at 100% (with the logger's
      model reading the left leg at 100.8, the logged push went right: attacker :2474, :2560-2561); (5) the
      more damaged leg; (6) left"
    push: "pushToDamaged in Gaital while she is down or this round sweeps; never in Willow, where 006 does not
      sweep, so a leg stays short of 100% while the other can take the kick"
    other_kicks: "Rain keeps its frontkick arm across presses and switches only when she parries that arm.
      Tykonos risingkicks a prone head (stun, Shikudo.wiki:138); Oak already did. Willow's slot 2 falls back
      to 'hiraku light' on a prone target (stun, Shikudo.wiki:160; Mystor's 'flashheel right hiraku light hiru
      light', vNTjvghY:7976). Neither kicks into a parried head"
    light_strikes: "the staff pickers still go LIGHT or to the torso on prepped legs, so a kuro does not break
      one early"
    known_limit: "legBroken() calls any leg at 100%+ broken even after her mend cures the break, so item 3
      cannot prefer re-breaking a mended leg at 100%. The attacker log re-broke the mended left leg (:2566,
      after the logger's own 'Processed Cures(leftleg)' at :2479; its limb numbers are the logger's
      tracker, not game text); 006 picks the same leg, but only through the left-on-a-tie rule"

  kill_sequence:
    phase_1: "Willow: head prep with hiru/hiraku, transition to Rain at the cap (006:487-492)"
    phase_2: "Rain: PRIMARY LEG prep with kuro (the cap is 15), can also prep the head with hiru"
    phase_3: "Oak: HEAD prep with NERVESTRIKE FIRST (paralysis prevents parry!)"
    phase_4: "Gaital: entered once both legs are prepped (006:532-534); kuro and needle until legs and head are
      prepped (006:1087-1122), then SWEEP + a flashheel pushed to 100% (006:1124-1134); she is down: NEEDLE,
      needleSecond and the spinkick (006:1136-1145, 689-703) → DISPATCH"
    fallback: "If kill fails in Gaital: Maelstrom → Oak → (continue cycle)"

  attack_ordering:
    description: "Combo syntax is flexible: COMBO target attack1 attack2 attack3"
    principle: "Order attacks to maximize affliction/prone benefits"

    oak:
      order: "staff1 + staff2 + kick (STAFF FIRST)"
      reason: "Nervestrike paralysis prevents parrying subsequent attacks"
      example: "combo target nervestrike kuro left risingkick torso"  # 006 kicks the head only when she is prone

    rain:
      order: "kick + staff1 + staff2 (KICK FIRST - default)"
      reason: "Frontkick can prone, which bypasses parry for staff attacks"
      example: "combo target frontkick left kuro left kuro right"

    gaital_sweep:
      order: "sweep + kick (SWEEP FIRST)"
      reason: "Sweep prones target, kick hits while prone"
      example: "combo target sweep flashheel left"
      note: "Sweep uses both arm balances - only one kick allowed, and the round is two kata actions"

    maelstrom_sweep:
      order: "sweep + kick (SWEEP FIRST)"
      reason: "Same as Gaital - sweep prones, kick follows"
      example: "combo target sweep risingkick head"

    maelstrom_normal:
      order: "kick + staff1 + staff2 (KICK FIRST - default)"
      reason: "Risingkick stuns if prone; crescent slays a prone target at half health or less"
      example: "combo target risingkick head livestrike ruku torso"

    other_forms:
      order: "kick + staff1 + staff2 (default)"
      reason: "No special affliction ordering needed"

# vv (011_Shikudo_Telepathy.lua, v4.7.420): the dispatch offense with Telepathy rounds between its combos,
# as Mystor plays it: 87 of his rounds were a MIND command alone, and no MIND affliction ever rode a combo
# (kb/combat/shikudo.md, "Mystor's lock route, counted")
vv_telepathy:
  entry: "shikudo.dispatchMind() (011:327), from alias 153 when the monk has no stance. zz, xx and sk stay
    combo-only until vv is proven live"
  routing: "no target: echo and stop. reboundHold may hold the press (the integration every dispatch uses).
    The kill (shikudo.checkDispatchReady) and a shield (tAffs.shield) go to shikudo.dispatch(): DISPATCH, or
    SHATTER first. No pick: shikudo.dispatch(), the combo"
  mind_round: "'queue addclear free <combatQueue()>[wield <shikudo.tele.shield>;]mind <ability> <t>;assess
    <t>' as its OWN round: never a combo, never a transition (the next combo carries it inline). The ASSESS
    follows shikudo.config.assessEachRound. If combatQueue() dropped a Deliverance target for a new one,
    the press goes to shikudo.dispatch() for the new target"
  gates: "a target; mana at least manaFloor (25%); the chain not at risk (ataxia_kataAtRisk(lapseGuard 12):
    MIND adds no kata); and not in a kill window, which is a combo: she lies down in Gaital (needle,
    spinkick, DISPATCH), or she lies down in Maelstrom with a fresh ASSESS at half health or less (006's
    CRESCENT). No equilibrium gate (the free queue waits for it, and a gate would end every burst after one
    round whenever vv is pressed early) and no lock first"
  picker: "shikudo.telepathyPick(s, cfg) (011:184), pure over the snapshot shikudo.teleState(), in order:
    (1-2) MIND SCYTHE with a mangled head and two of stupidity, impatience, dizziness, epilepsy, confusion,
    else MIND BATTER with a mangled head, only with shikudo.tele.scythe; (3) nothing inside our own blackout
    (blackoutSecs 4), so the combo it hides goes out; (4) MIND IMPATIENCE when asthma, slickness and
    anorexia are on without it; (5) MIND BLACKOUT, only with shikudo.tele.blackout, in Rain at 40%+ mana,
    to STICK (she is paralysed, or her tree is down for 4+ more s) or as BAIT (her tree is up and two lock
    pieces are on, so the tree takes the blackout); (6) MIND DISRUPT on a confused target not yet
    disrupted; (7) a Rain burst from kata burstKata (9) while fewer than burstMax (4) MIND rounds have run
    since the last combo: impatience, else paralyse (not once she is paralysed; never on an Apostate,
    classSkip)"
  blackout: "wired and OFF (shikudo.tele.blackout = false) until our success line, the lock question
    (kb/CONFLICTS.md #7) and 'mind blackout' vs 'mind blackout <t>' are settled live. Turned on, it queues
    006's next round behind the blackout with 'queue add free ' .. shikudo.buildRound()"
  scythe: "wired and OFF (shikudo.tele.scythe = false): the wiki gives SCYTHE no (*) and no target, the one
    logged scythe was cast with a lock held (c.iJVmpL:1715, :4227), and a refused scythe changes nothing vv
    reads, so vv would pick it again on every press. Dormant anyway: nothing records a target's mangledhead"
  history: "the burst and the blackout window move when the game's run line shows a round RAN
    (shikudo.onTeleQueueRan, 011:283; 007's pattern, matched from its first row). The pending record is
    { key, blackout, committed } (011:243). Unlike 007, another command's run line CAN move it: any run line
    whose first row carries a whole-word 'combo' (006's, 007's or one typed by hand) ends the burst
    (011:293-295); a combo press drops the pending MIND round. Until a run line has been read (our pending
    MIND round's, or any combo's), the press counts. State on ataxiaTemp.shikTele: never saved, and it
    SURVIVES a reload (011:249-253; nothing resets ataxiaTemp), so only a client restart clears it"
  limits: "as 007's (history.limits, the lock route above), except that queue alerts turned off mid-session
    freeze vv's burst until the client restarts, not until a reload. Frozen below burstMax, a Rain round at
    kata 9+ with an impatience or paralyse to give can be a MIND round on every press until the lapse guard
    or those afflictions landing stop it; frozen at burstMax, no burst round goes out (the other picks are
    not capped by the burst)"
  config: "shikudo.tele (runtime only, back to the defaults on a client restart): manaFloor 25, burstMax 4,
    burstKata 9, lapseGuard 12, blackout false, scythe false, blackoutManaFloor 40, blackoutSecs 4,
    classSkip {apostate = {paralyse = true}}, shield unset"
  tests: "test_shikudo_telepathy.lua (47 tests on the real monk/004, 006 and 011)"
  open: "burstMax 4 is conservative (Mystor ran eight MIND rounds in one Rain burst, FceAmb0o:2600-2944);
    whether the run line prints for our MIND rounds is unconfirmed (without it, until some run line has been
    read, each press counts)"
```

## Advanced Shikudo Combat Strategies (Mystor's Insights)

### Fighting Momentum Classes
```yaml
principle: "Hit and run, slow prep"
strategy:
  - "Don't sit in combat against momentum classes (Serpents, DW)"
  - "Run when they have ~3 afflictions on you"
  - "Stay within kata fall off timer"
  - "Super fast momentum classes are the biggest threat"
  - "Time is everything - manage your windows carefully"

mounted_counter:
  problem: "Mounted stops frontkick and many monk abilities"
  solution: "Use KAI SURGE to dismount"
  note: "Kai surge is faster in Rain stance"
```

### Kata Double-Up Strategy (9/10 Kata)
```yaml
goal: "Achieve 9/10 kata for double up on kuro and ruku"
execution:
  1: "Build to 9-10 kata"
  2: "Use double kuro + ruku combo for max affliction burst"
  3: "Swap immediately after burst"
  4: "Use the aff burst to pressure next stance"

benefit: "Massive affliction pressure in single combo window"
```

### Stance Strategy Flow
```yaml
oak_start:
  description: "Best early hinder"
  afflictions: [paralysis, clumsiness]
  reason: "Par and clumsy provide immediate combat pressure"

gaital_transition:
  description: "Transition into Gaital with strong aff state"
  entering_with: [clumsiness, healthleech, lethargy, weariness]
  benefit: "Good continuance because transitioning with strong affliction stack"

rain_strategy:
  description: "Lose some affliction pressure, gain mind attack options"
  loses: "Some direct affliction pressure"
  gains:
    - "Mind attacks: imp, batter, blackout, illusion"
    - "Telepathy is SPED UP in Rain"
    - "Hiru for dizziness (confusion if prone)"
    - "Easy prone with frontkick"
    - "Kai surge is faster in Rain"

  hiru_combo:
    description: "Devastating frontkick hiru combo"
    execution: "If you beat their herb bal, slip imp in, then frontkick hiru"
    result: "Prone + dizziness + confusion if prone"
```

### Blackout Tactics (Rain Stance)
```yaml
description: "Blackout is a no-brainer in Rain if not using elsewhere"

hidden_combo:
  mechanic: "Blackout, then combo 1 time - combo is hidden"
  effect: "Forces diag or enemy plays defensive"
  psychology: "Most people assume you're disrupting and concentrate"

things_to_slip_under_blackout:
  - "Any telepathy attack"
  - "Any combo available in Rain"
  - "Strip a defence (if feeling lucky)"
  - "Confusion via frontkick hiru"

confusion_pressure:
  combo: "Blackout into frontkick hiru"
  follow_up: "If they don't cure confusion, slip mind impatience before herb bal"
  finisher: "Then disrupt - devastating"
  note: "Confusion extends equilibrium recovery by 100%"
```

### Riftlock Attempt (Rain Stance)
```yaml
setup:
  requirements:
    - "9 kata in Rain"
    - "Both arms prepped"

execution:
  1: "Blackout"
  2: "Mind paralyse (stops parry)"
  3: "Frontkick break 1 arm"
  4: "Kuro + ruku the other arm and a leg"
  5: "All done within blackout"

result_state:
  limbs: "RA2, LA2, RL2"
  afflictions: [clumsiness, healthleech, weariness, lethargy]

oak_continuation:
  description: "Transition into Oak with that state"
  affliction_sequence:
    1: "Oak gives asthma + slickness"
    2: "Asthma is kelpstack buried - they can eat mag for slickness but you have perfect info"
    3: "Follow with paralysis + slickness"
    4: "Then mind impatience, watch their cures"
    5: "Transition to Willow or Gaital for finisher"

# CRITICAL (the user, 2026-10-11): "Blackout is a CRITICAL affliction to give (you give it once, they usually
# touch tree to cure and we give it again). Under blackout they cannot see what we do to them."
# The game (AFFLICTION SHOW blackout): lasts 4 seconds, cured by time; the TREE cured it in log 2 (it is not
# NoRandomCure); it "obscures your prompt and prevents you from seeing many things happening" -- MANY, not all. A live
# victim (log 2026-10-11) lost their prompt and their own action lines, still saw the monk eat, and touched
# the tree 1.85s in.
blackout_psychology:
  - "Opponent sees almost nothing of what we do during blackout (their prompt is hidden)"
  - "Most assume you're just disrupting and CONCENTRATE"
  - "Meanwhile you've paralyzed them, burst limbs, stacked affs"
  - "When blackout ends they have missed much of what we did (log 2: they still saw the monk eat, and their
    curing kept running)"
  - "They waste time with DIAGNOSE while you transition to Oak"
```

### Riftlock design (switched-off 008 only; NOT LIVE: neither 006 nor 007 has riftlock)
```yaml
file: "008_CC_Shikudo_Offense_ALL.lua"  # switched off; kept as the record of the design
mode: "riftlock"
commands:  # none of these exists at runtime: skriftlock, shikudoriftlock, shikudo.reset and the
           # mode-aware shikudo.status are 008-only (008:1033, 1057, 1073)
  activate: "skriftlock() or shikudoriftlock()"
  attack: "shikudo.dispatch() (after mode set)"
  status: "shikudo.status() or skstatus()"
  reset: "shikudo.reset()"

phases:
  OAK_SETUP:
    description: "Build hindrance (paralysis + clumsiness)"
    form: Oak
    attacks: "nervestrike (para), ruku (clumsy)"
    transition_to: "Willow -> Rain when para+clumsy established"

  RAIN_PREP:
    description: "Build kata for blackout burst"
    form: Rain
    attacks: "kuro (weariness/lethargy), ruku (clumsy), hiru (dizziness)"
    goal: "Reach 9+ kata with mindlock established"  # 008's rule. The players need no lock in the room except for
    # certain skills (Radiance, Sapience), but the next phase is BLACKOUT, which the wiki puts behind the lock;
    # unconfirmed in the room (kb/CONFLICTS.md #7)
    transition_to: "BLACKOUT_BURST when ready"

  BLACKOUT_BURST:
    description: "Execute the hidden burst combo"
    form: Rain
    execution:
      1: "BLACKOUT (opponent goes blind)"
      2: "Mind PARALYSE (stops parry - they can't see this!)"
      3: "Frontkick + Kuro + Ruku burst (all hidden)"
    transition_to: "Oak for continuation"

  OAK_CONTINUATION:
    description: "Apply lock afflictions after burst"
    form: Oak
    attacks: "livestrike (asthma), ruku torso (slickness), nervestrike (para)"
    telepathy: "Mind impatience for hardlock"
    transition_to: "LOCK_PRESSURE when truelocked"

  LOCK_PRESSURE:
    description: "Pure damage pressure on truelocked target"
    forms: [Oak, Gaital, Rain]
    goal: "Kill through sustained damage"

key_functions:  # NONE of these exists: 008 (switched off) has no isReadyForBurst or canBlackout, and updatePhase is
  # 007's shikudoLock.updatePhase. 008's burst rule is inline in shikudo.selectTelepathy (008:395-444): an eq test
  # on ataxia.balances.eq, which nothing writes; mindlock first; Rain only; in riftlock the bare word
  # `blackout <target>` at kata >= 9 with 008's own 10 s limit (the wiki lists 4.00 s of equilibrium and no
  # separate cooldown; not checked in game). The status line 'Burst Ready' (008:1023) is Rain + kata >= 9 +
  # mindlocked.
  isReadyForBurst: "Returns true when in Rain with 9+ kata and mindlock"
  canBlackout: "Returns true if EQ available and cooldown elapsed"
  updatePhase: "Automatically detects and updates current phase"

synergies:
  - "Telepathy is FASTER in Rain stance (EQ balance decrease bonus)"
  - "Kai Surge is faster in Rain (for mounted targets)"
  - "Blackout hides most of what we do (the game: 'many things') for 4 seconds, or until they tree it"
  - "Frontkick can prone (confusion via hiru if already prone)"

telepathy_rule:  # corrected 2026-10-11 (the user and Mystor; wiki; log 1)
  preferred: "Rain is where Telepathy is cheapest: 'your equilibrium recovery shall be significantly increased'
    (wiki SW:173). MIND TRAVEL took 0.85s in Gaital and 0.72s in Rain (log 1). The user: 'Shikudo Monks also use
    telepathy in RAIN form do to the bonus of EQ.'"
  not_only: "Not only Rain, though: log 1 cast MIND IMPATIENCE and MIND PARALYSE in Willow"
  one_or_the_other: "In log 1 a telepathy round took the place of that round's combo (the user, below: 'you can't
    attack and do telepathy'; log 1's alias swapped the combo out for the MIND command), and none of Mystor's
    274 combos carried a MIND affliction command. Open: in log 2 a blackout arrived inside a combo round
    (kb/combat/shikudo.md). Since v4.7.420 007 and vv (011) send every MIND command as a round of its own"
  mindlock: "Needed for a target outside the room and for certain skills such as Radiance and Sapience (the user
    and Mystor), so not a setup step for the (*) attacks in the room. Open for BLACKOUT and SCYTHE: the wiki
    puts both behind the lock and neither has been tried in the room without one (kb/CONFLICTS.md #7)"
```

### Scythe Fork Strategy (Gaital)
```yaml
description: "Fork the opponent into choosing between head or leg death"

setup_combo:
  - "SWEEP RL2 (prone + leg damage)"
  - "SPINKICK L3H, CRTHR, LL2 (Mystor: 'spinkick l3h crthr ll2': a level-3 HEAD from spinkick on a prone
    target, a crushed throat from NEEDLE, the left leg at level 2). This read 'leg level 3' until 2026-10-12"

enemy_choices:
  mending_head:
    action: "They mending head for crushed throat"
    counter: "If they restoration leg → transition Rain and get scythe"

  restoration_head:
    action: "They restoration head level 3"
    counter: "Needle dispatch available"

  hold_salve:
    action: "They hold salve"
    counter: "Mind imp, mind batter on repeat to pressure scythe"

outcome: "They choose head or leg first, or die to scythe"
```

### Spinkick Head Prep Optimization
```yaml
mechanic: "Spinkick to break head instantly elevates to level 3"
damage_boost: "Does immense damage to head if you drop hyperfocus as you do it"
oak_synergy: "Head prep is ~60% when starting in Oak"
hyperfocus_tip: "Drop hyperfocus right before spinkick for max damage"
```

### Character Build Considerations
```yaml
quick_witted:
  benefit: "Scythe is smoother"
  drawback: "Makes dispatch harder"
  recommendation: "Good for scythe-focused play"

strength:
  mystor_build: "9 strength when Shikudo"
  note: "Low strength, optimized elsewhere"

artifact_staff:
  level_1: "Current - Oak start recommended for hindrance"
  level_3: "Can start Gaital directly"
  tradeoff: "Gaital start loses Oak hindrance but faster kill route"
```

### Illusion for Telepathy
```yaml
stance: Rain
description: "Illusion for telepathy is huge - cannot be seen through"
usage: "Use when losing pressure in Rain anyway"
timing: "Slip in moments before enemy gets balance to disrupt"
synergy: "Rain speeds up telepathy, making illusion more viable"
```

## Mystor Combat Discussion (Full Transcript)
```
Mystor: "You get alot of pressure toward prep that way."
Mystor: "But you lose out on alot of affliction pressure."
You: "I am going to be a bitch."
You: "Hit and run."
You: "Slow prep."
You: "I aint sitting in there with momentum classes."
You: "Doesnt make sense."
You: "To me at least."
Mystor: "As long as you stay within the kata fall off timer its fine."
Mystor: "You ccan sit with alot of the momentum classes."
You: "I usually try and run when they got maybe 3 afflictions on me."
You: "What would you do differently?"
Mystor: "Its just the super fast momentum that gets me."
You: "Serpents, DW."
Mystor: "I try to achieve 9/10 kata for the double up on kuro and ruku."
Mystor: "And then swap immediately."
Mystor: "So I can use the aff burst to pressure next stance."
Mystor: "Oak start gives me the best early hinder I can get."
Mystor: "With par and clumsy."
You: "That makes a lot of sense."
Mystor: "Gaital then gives me good continuance because im transitioning into it with clu hlee leth wea."
Mystor: "Rain I lose a little pressure in."
Mystor: "But I have good options with mind attacks."
Mystor: "Imp batter."
Mystor: "Blackout."
Mystor: "Also illusion."
Mystor: "Illusion for telepathy is huge."
Mystor: "You cannot see through it."
Mystor: "But since Im losing pressure in rain reguardless."
Mystor: "Ill fall back to disrupt the enemy if I can slip it in moments before enemy gets balance."
You: "But you can't attack and do telepathy right."
You: "One or the other."
Mystor: "But telepathy is sped up in rain."
Mystor: "Rain also has hiru."
You: "True."
Mystor: "And an easy prone."
Mystor: "So if you can beat their herb bal."
Mystor: "Slip an imp in."
Mystor: "And frontkick hiru."
Mystor: "Devistating."
You: "Mounted stops frontkick."
You: "Mounted stops a lot of monk."
Mystor: "Kaido."
You: "Pretty wild."
You: "Kai surge sure."
You: "A lot of time."
You: "Time is everything."
Mystor: "You are in rain."
Mystor: "Kai surge is faster in rain."
You: "That big of a difference?"
Mystor: "But Im already planning to lose some momentum in rain."
Mystor: "So kai surge doesnt really hinder me much."
Mystor: "Im also quick witted though."
Mystor: "But yes its a nice difference."
Mystor: "Also if you arent using blackout at all in the rest of your attacks."
Mystor: "Blackout in rain is basically a no brainer."
Mystor: "You can blackout, and then combo 1 time."
Mystor: "And the combo is hidden."
Mystor: "You will force a diag, or enemy to play defensive."
Mystor: "Most people will immediately assume you are disrupting."
Mystor: "And concentrate, so dont."
Mystor: "But you can slip some pretty nasty things in under that blackout."
You: "This is more complex than I was thinking."
Mystor: "Any telepathy attack."
Mystor: "Any combo available in rain."
Mystor: "One of the big things to slip that people dont check for."
Mystor: "Confusion."
Mystor: "Blackout into a frontkick hiru."
You: "Yeah."
You: "True."
Mystor: "If they do not cure confusion you can slip a mind impatience before herb bal."
Mystor: "Then disrupt."
Mystor: "And thats disgusting."
Mystor: "But ultimately, I go for a riftlock attempt in rain."
Mystor: "If I can get to 9 kata in rain with both of your arms prepped."
Mystor: "Ill blackout, mind paralyse."
Mystor: "To stop parry."
Mystor: "And frontkick break 1 arm, kuro ruku the other and a leg."
Mystor: "All in blackout."
Mystor: "You come out of blackout with ra2 la2 rl2 clu hlee wea leth."
Mystor: "And im transitioning into oak with that state."
Mystor: "Oak giving ast sli, now ast is kelpstack buried they can eat mag for sli but you have perfect info."
Mystor: "Followed by par sli."
Mystor: "Then mind imp, watch their cures."
Mystor: "And transition willow or gaital for finisher."
You: "That is a great rift lock."
Mystor: "Im not sure if nimble monk is fast enough to hide mind par and a combo within the blackout."
Mystor: "But honestly not hiding the combo isnt that big of a deal."
Mystor: "Its big for me because my balance is a little slower."
Mystor: "So I delay the salve apply until they regain balance and notice their arms are broken and leg is broken with prone."
Mystor: "If they apply leg to stand you have forever to finish a full lock."
Mystor: "If they apply an arm, you go into gaital with them prone and one leg already broken."
You: "You go quick witted?"
Mystor: "If they dont apply then you are already won."
Mystor: "Yeah im quick witted."
Mystor: "It makes dispatch way harder."
Mystor: "But scythe is a bit smoother."
Mystor: "I have 9 strength when im shikudo."
You: "Yeah."
You: "I didnt even think of scythe with shikudo."
Mystor: "I fork scythe in gaital."
You: "So many options with shikudo."
Mystor: "I sweep rl2, spinkick l3h crthr ll2."
You: "Just probably one of the most difficult to ... eh 'implement'."
Mystor: "And they can mending head for crthr, and if they restoration leg I transition rain and get scythe."
Mystor: "If they restoration h3 I can needle dispatch."
Mystor: "If they hold salve."
Mystor: "I can mind imp."
Mystor: "Mind batter."
Mystor: "On repeat to keep pressuring scythe."
Mystor: "They will have to choose either head or leg first eventually."
Mystor: "Or die to the scythe."
Mystor: "Spinkick to break head instantly elevates to 3."
Mystor: "And it does immense damage to head, if you drop the hyperfocus as you do it."
Mystor: "So basically head prep is like 60%."
Mystor: "Which I get easily because I start in oak."
Mystor: "I can probably start gaital if I want, when I get l3 staff, Im currently only working with l1."
You: "Man that is going to be wild to factor into my shit."
Mystor: "But then I lose out on all the hinderance from oak."
```

## Implementation Notes
```
Triggers to watch for:
- Combination attack patterns (COMBO kick + punches: sdk/ucp/hkp/mnk/spp/snk/hfp etc.)
- "Your * is damaged/broken/mangled" - track limb state
- Backbreaker (BBT) / break-stance moves (HRS/BRS/WRT) - Tekura kill sequence
- Dispatch messages - Shikudo instant kill
- Telepathy ability messages

Shikudo-specific lines (captured; every line in kb/combat/shikudo.md; corrected 2026-10-12, this list
quoted lines no log has):
- Form change (the monk's side), e.g. "You let your eyes fall closed and instinct guide you as you flow into
  the form of Gaital." The form itself is read from charstats: ataxia.vitals.form
- Kata: "You are now maintaining a kata chain of N actions." (one per attack; trigger 164 writes
  ataxia.vitals.kata). Lapse: "You can no longer maintain your deadly kata." (165 zeroes it). Refused
  transition: "A kata of at least 5 must be performed in order to flow from the <form> to another."
- Sweep: "The staff sweeps the legs out from under <T>, sending her sprawling." (prone). A sweep round is
  two kata actions, the sweep and its kick (c.iJVmpL:3868-3872)
- Needle: "The end of the staff smashes into the exposed throat of <T>, crushing cartilage." (crushed throat)
- Dispatch: "Placing one foot on the chest of <T> to hold her in place, you drive your staff down with all
  your strength into her weakened throat. ..." then "You have slain <T>."
- SPINKICK on a prone head: the strike line has never been captured (Mystor's client gags it); after it,
  "You feel something give way under your blow." printed twice (LcJC-rJ5:5804, c.iJVmpL:3973)
- KAI CHOKE (007's kill): "<T> gasps and stumbles as an unseen force crushes the life breath out of him."
  (vNTjvghY:8961, FceAmb0o:6399)
- Shield rebound: "A dizzying beam of energy strikes you as your attack rebounds off of <T>'s shield."
  (after a combo every time in the logs; a MIND command's rebound is unseen)
- Stumble: "You lose your rhythm" (UNVERIFIED: in no log and no trigger). Per the wiki a stumble resets the kata
  AND drops you into Tykonos; Tykonos itself never stumbles. Since v4.7.419 monk/003 records a move into
  Tykonos we did not ask for as a probable stumble, so the real line can be kept when it happens
- Hyperfocus: "You will now focus on bypassing attempts to deflect blows when striking the *" (trigger
  shikudo/003's pattern; no log has it, only Mystor's "-Def: hyperfocus.")
  → the trigger stores ataxiaTemp.hyperLimb (003:39); 006 reads it through shikudo.hyperLimb() since v4.7.420
- Hyperfocus clear: "You stop focussing upon bypassing your target's parry" (no log has it, no trigger)
- The queue's run line, which 007 and vv count rounds by: "[System]: Running queued <q> command: <cmd>"
  (the package's pattern, clean-up/001_Queue_Scanning.lua:34; no capture in kb/raw)

GMCP considerations:
- Track gmcp.Char.Vitals for limb percentages if available
- ataxia.vitals.form - current Shikudo form
- ataxia.vitals.kata - current kata count
- lb[target].hits["limb"] - enemy limb damage tracking (e.g., lb[target].hits["left leg"])
- tAffs.prone, tAffs.damagedwindpipe, tAffs.damagedhead - kill conditions
- Kai balance separate from regular bal/eq

Edge cases:
- Kai abilities use separate kai balance
- Shikudo requires Trans Tekura to unlock
- Combinations can hit multiple body parts
- Tekura Backbreaker (BBT) requires all 6 limbs broken + prone (TK6); TKD alt kill is Scythe via Telepathy
- Shikudo Dispatch requires prone + damaged head + damaged windpipe (crushed throat); no broken leg (wiki;
  done that way in log 2026-10-11). 006's checkDispatchReady() matches that since v4.7.420 (006:99-105;
  it demanded a leg at 100% until then, plan finding 4)
- Mental afflictions from Telepathy can add lock pressure
- SPINKICK behavior changes based on target state:
  - Standing: hits TORSO
  - Prone: hits HEAD with massive damage
  - Prone + damaged head: INSTANTLY MANGLES head (level 2 → 3) (Mystor; no game line shows the level)
- SWEEP uses BOTH arm balances - only one kick allowed; the round counts two kata actions
- Form transitions require 5+ kata (can transition anytime after 5 if conditions met)
- Rain allows "twice the normal length" of kata (wiki); the 12 and Rain 15 caps are OUR POLICY (ataxia_KATA,
  read by both offenses since v4.7.420; the code's 12/24 tables are gone). A stumble is a chance that grows
  the longer a chain runs (wiki), so log 2026-10-11's Oak 13 and Rain 18 without one rule out only a certain
  stumble at 12, not a 12/24 limit. Tykonos is exempt
- 006 leaves Willow at the cap: a chain of 12 after the combo, i.e. kata 9+ before a three-strike combo
  (006:487-492)
- Rain stays and preps the head with hiru while the legs are prepped, the head is not, and the chain is
  under 9; it goes to Oak as soon as a transition is legal once the head is prepped too (006:475-481), with
  prepped legs at kata 9+, and at the cap (15 after the combo) regardless (006:499-507)
- Oak at the cap goes to Gaital once both legs are prepped (head or not: Gaital's NEEDLE finishes it) or
  legs and head are at 85%+, otherwise cycles back to Willow for more prep (006:514-551)
- Gaital at the cap goes to Maelstrom if she stands and this round does not sweep her (Maelstrom → Oak →
  Gaital cycle); while she is prone, or on the sweep round, it stays (006:457-469)
- Other non-Rain forms transition at the cap (Tykonos as soon as legal)
- 006 transitions inline ("combo target kick staff1 staff2 transition form"); 007 sends "transition to
  <form> form" FIRST in its round (007:654, v4.7.420), the wording Mystor sends 56 times. Until v4.7.420 it
  sent "transition to the <form> form" after its combo, which no log shows; the PvE basher sent that until
  v4.7.68 and got the kata refusal (CHANGELOG v4.7.68), so the game reads it as a TRANSITION, but a success
  at kata 5+ is unseen
- LIGHT: seen only on STAFF strikes (kuro, ruku, hiru, hiraku, nervestrike, livestrike and jinzuku light in
  Mystor's logs); every "light risingkick" there is "nervestrike light risingkick". Whether a kick can be
  light is UNVERIFIED
- Willow's only kick is flashheel, and every flashheel BREAKS the leg (log 2026-10-11). Since v4.7.420 both
  offenses choose the leg (006 shikudo.flashheelKick, 007 shikudoLock.flashLeg) instead of trying to keep it
  whole (006's isLegSafe is gone; plan finding 3)
- Our strike lines no longer name one staff: 166 (SHATTER), calls/008 (off) and gags/001 match any staff
  as early fragments, and gags/001 and 166 act only in PvP, since a fragment that ends before the name
  matches a denizen too (v4.7.420; kb/combat/shikudo.md, "What our triggers record")
- trigger 187 and parry/001 still set ataxiaTemp.flashheelWasParried / frontkickWasParried, which only the
  switched-off 008 reads; 006 reads the tp* flags those triggers set beside them
```

## Kai, kata and ASSESS: shared monk state (v4.7.419)

`ataxia/monk/004_Kai_And_Kata.lua` writes down once the facts the code held as scattered literals,
one of them wrong (Kai Surge: 31 in 007's old READY echo, 45 on the wiki). Its readers in v4.7.419
were TK6's dismount (`tekura/002`), the kaido aliases and `skata`. **Since v4.7.420 the Shikudo
offenses read it too**, and their own copies are gone (kata caps 12, Rain 24; 007's surge 31 and its
kai read from `ataxia.vitals.class`):
- **006** (`zz`, `xx`, `sk`): `ataxia_kataShouldLeave(form, kata, strikes)` with its combo's strikes
  (3, or 2 for a sweep round), `ataxia_KATA.min` for the legality test, `ataxia_kataLeaveAfter` in
  `skstatus`, and `ataxia_assessAtMostHalf(5)` for Crescent.
- **007** (`sr`): `ataxia_kai()` and `ataxia_kaiAfford("choke")` for its KAI CHOKE kill,
  `ataxia_kataShouldLeave(form, kata, 0)` (its transition goes first), `ataxia_kataAtRisk(12)` for
  the MIND-round lapse guard, `ataxia_assessAtMostHalf(5)`, and `ataxia_kataLeaveAfter` in its status.
- **011** (`vv`): `ataxia_kataAtRisk(12)`, `ataxia_assessAtMostHalf(5)` and `ataxia_shikudoForm`.

The basher keeps its PvE literals (`SHIKUDO_BASH_ROTATION`), which `skata` deliberately never
changes. Tests: `test_monk_kai_kata.lua`; `test_shikudo_offense.lua`, `test_shikudo_dispatch.lua` and
`test_shikudo_telepathy.lua` load the real monk/004 before the offense they test.

| Helper | What it answers |
|---|---|
| `ataxia_kai()` | Our kai (0-100), or nil when unknown. It is unknown until `update_stuff/004` reads a charstats `Kai` this session, which it stamps in `ataxiaTemp.kaiAt`. `ataxia.vitals` is saved and `ataxiaTemp` is not, so a kai restored from disk reads as unknown (the v4.7.299 rule). |
| `ataxia_kaiCost(ability, tgt)` | `ataxia_KAI_COST[ability]` (the Kaido list above). KAI CHOKE costs 0 against a denizen (a number); KAI ENFEEBLE costs 0 against a denizen with the Spirit Rend boon. |
| `ataxia_kaiAfford(ability, spent, tgt)` | Returns `ok, have, need`. An unknown kai is never enough (a free ability always is): a refused surge wastes its round, a skipped one only waits. `spent` is kai already committed earlier in the same queued round, because a round fires at once: BOOST then SURGE needs 56. |
| `ataxia_KATA`, `ataxia_kataShouldLeave(form, kata, strikes)` | When to leave a form: once the chain AFTER this round's strikes reaches 12 (Rain 15; Tykonos as soon as a transition is legal, at 5). Pass the combo's strike count for an inline transition (it is judged after the strikes), 0 for one sent before the combo. These are POLICY from Mystor's play, not game limits (kb/CONFLICTS.md #8). |
| `skata [FORM [N\|default]]` | Shows the caps, or saves an override in `ataxia.settings.shikudoKata` and warns past the longest chain seen without a stumble (13, Rain 18). Only overrides are saved, so a release can change a default. Tykonos takes no override. |
| `ataxia_kataAtRisk(maxIdle)` | True when a live chain's last strike (`ataxiaTemp.kataAt`, trigger 164) is older than `maxIdle` (default 17 s; the chain lapses at about 20 s). KAI and MIND rounds add no kata, so a run of them must let a combo through. False when there is no chain: no chain line yet this session, or the kata reads 0. The kata is the test because `kataAt` survives the end of a chain (the lapse line, or a MIND round that carries a transition, as Mystor plays: vNTjvghY:715, :8444). |
| `ataxia_assessAtMostHalf(maxAge)` | True only for a fresh ASSESS (default 5 s) of our current target whose RAW health is half or less. Crescent kills only then (Shikudo.wiki:358), and the floored percentage read 3540/7000 (50.57%) as 50. |

**Where the kata comes from:** charstats `Kata: N`; the chain line (trigger 164 also stamps
`ataxiaTemp.kataLast` and `kataAt`); the lapse line (165 sets it to 0 and stamps
`ataxiaTemp.kataLapseAt`); and a real form change (`update_stuff/004` calls
`shikudo_checkForms(true)`, which zeroes it). Charstats may not report the new chain until the next
strike, which is why the triggers write it. **The basher zeroes it too** when it queues a transition
(`basher/002`, `shikudoBashCombo`), so it reads 0 on exactly the combo a stumble is likeliest on.

**The stumble recorder** (`monk/003`): a move into Tykonos we did not ask for, while a chain was
alive, is kept in `ataxiaTemp.shikudoStumbles` and echoed "[Shikudo] probable STUMBLE from FORM at
kata N -- keep the line above". It decides nothing; it exists to capture the first stumble line
(kb/combat/shikudo.md has the rules it uses).

**Unverified:** the exact charstats wording for kai (`Kai: N%` is assumed; `update_stuff/004` reads
only its digits, and the prompt shows `K:59%`), and what charstats reports for `Kata` after a form
change. `basher/002` (its comment on `shikudoBashCombo`'s zero) says charstats keeps reporting the
OLD kata for a tick. A `Kata` parsed after the `Form` in the same update overwrites monk/003's zero;
if charstats then omits `Kata` until the next strike, the old value stays until the chain line (164)
replaces it, and `ataxia_kataAtRisk` can call a chain the transition already ended at risk. If `Kata`
is omitted at once, or sent as 0, the zero stands.

## Mnemosyne Boons (Shikudo bashing, v4.7.121-124)

```yaml
kai_unleashed:  # legendary — kai choke bursts magic damage on ALL denizens in the room
  flag: mnemKaiUnleashed
  behavior: "KAI CHOKE <target> PREPENDS to the combo at 2+ denizens, in EITHER spec
    (v4.7.297 — Tekura and Rain-form Shikudo; see ataxiaBasher_monkKaidoReady below)"
  ability_facts: "AB Kaichoke 896: 4.00s of EQUILIBRIUM (idle during balance combos —
    both land the same round); vs DENIZENS consumes NO kai, only 50 mana (250-mana
    floor); bonus damage vs damaged/mangled head/torso or mind clamp"
  cooldown: "30s on the boon's burst, CONFIRMATION-based: the burst line ('Your
    surroundings ripple like a lake's surface struck...') starts it via trigger 031;
    an eaten choke retries after 6s instead of forfeiting the window"
  live_numbers: "choke 3338→6369 asphyx (coalescence-empowered); burst 8472→25560
    magical (scales; one burst one-shot the primary); eq spend observed ~2.97s"
  lines: |
    Both halves of the choke are captured and highlighted chartreuse bold (v4.7.314,
    live 2026-09-17) -- the attack-LANDED colour shared with Spirit Rend and Arc:
      CAST  : "Your face contorted in a twisted grimace, you clench your fists to
               crush the life out of your foe."        (leviatax/004_Kai_Choke.lua)
      LANDED: "<mob> gasps and stumbles as an unseen force crushes the life breath
               out of him."                    (highlighting/063_Kai_Choke_Landed.lua)
    THE CAST LINE SAYS "your foe" AGAINST A DENIZEN, not the target's name. The old
    pattern was `...crush the life out of (\w+)\.$` -- one word, i.e. a player name --
    so the trigger had NEVER fired in PvE, and its party relay never ran there. Same
    bug as the v4.7.313 tempo triggers: grep `\w+` before trusting any PvE line.
    The LANDED line was previously uncaptured entirely, which is why a choke without
    the Kai Unleashed boon had no visible confirmation at all -- the burst line is
    boon-only. It is a highlight only; it deliberately does NOT clear
    `ataxiaTemp.kaiChokePendingAt` (see the trigger's note on confirmation livelocks).

senseless_flurry:  # balance recovers 30% faster while the numbness defence is up
  flag: mnemSenselessFlurry
  behavior: "NUMB prepends to the combo (Tekura or Rain-form Shikudo, v4.7.297) when the
    numbness defence is down (GMCP-tracked, 5s attempt-hold); fires on shielded rounds
    (self-targeted); Kai Choke OUTRANKS it — one eq spender per round"
  ability_facts: "AB Numbness 894: self-only, 3.00s eq; DEFERS incoming damage,
    delivered later in one blow at -40%. Fire line: 'You grit your teeth and will
    your pain out of existence.'"
  crowd_gate: "NEVER numbs at >= the swarm threshold or mid-swarm-tactic: deferral
    pins HP, blinding the damage-rate watchdog, danger levels, and the escape
    ladder until the lump lands — in a crowd that lump can exceed max HP (death
    from 'full HP' with every alarm silent). Thin rooms only."
```

**TEKURA GETS THE SAME THREE RIDERS (v4.7.297, user-directed).** Kai Choke, Kai Enfeeble (Spirit
Rend) and Numbness are all **Kaido** abilities, and Kaido is the skill Tekura and Shikudo SHARE
(see the class table above) -- "Rain form" was always user doctrine for *which Shikudo form* to
use them in, never a restriction to Shikudo itself. Before this fix `ataxia.vitals.form` is `nil`
for a Tekura Monk, so a bare `form ~= "Rain"` gate silently blocked all three for Tekura the whole
time these boons existed, and the Tekura branch of `ataxiaBasher_monkBashing2` never called any of
the three rider helpers at all -- both halves needed the fix. `ataxiaBasher_monkKaidoReady()`
(`basher/002_Class_Bashing.lua`, shared by all three) is `stance-truthy OR form == "Rain"`, reusing
the exact discriminator the dispatcher's own `tekura`/`shikudo` locals already compute. **No
stance-NAME filtering**: per the user ("In tekura I am only in one stance"), a Tekura Monk sits in
exactly one stance during ordinary bashing, so truthy `stance` alone is the whole test.


## Spirit Rend (Mnemosyne boon) -- KAI ENFEEBLE on denizens (v4.7.292)

> "Your kaido enfeeble ability costs no kai and can target denizens, halving the target's current
> health. You can only use this ability against denizens every 60 seconds."

**AB Enfeeble (Kaido, ID 901)** -- `KAI ENFEEBLE <target>`, **3.00 seconds of EQUILIBRIUM**, 61 kai,
"Works on/against: Adventurers". Halves current health *and mana*; against an adventurer who is not
prone that is reduced to 25%.

**What the boon changes, and what the basher therefore does** (`ataxiaBasher_spiritRend`,
`basher/002_Class_Bashing.lua`):

| Fact | Source | Handling |
|---|---|---|
| Costs no kai | boon | no kai gate at all -- the AB's 61 is exactly what is removed |
| Targets denizens | boon | `type(target) == "number"`; inert in PvP, where it is a normal 61-kai ability |
| 60s cooldown | boon | timed from the CONFIRMED fire line, not from send |
| Halves current health | boon | fires only above `ataxiaBasher.spiritRendAt` (**50**) -- halving 90% removes nearly half the mob, halving 40% removes a fifth |
| "reduced to 25% if not prone" | AB | **NOT applied.** That clause is in the adventurer ability; the boon restates the denizen effect with no prone condition. Revisit only if a live capture shows a reduced effect on a standing denizen. |
| 3.00s equilibrium | AB | rides free beside the balance combo, like Kai Choke and NUMB |

**Tekura or Rain-form Shikudo** (`ataxiaBasher_monkKaidoReady()`, v4.7.297 -- Kaido is shared by
both specs; see the note above), and it **sorts ahead of Kai Choke**: Rend's window closes as the
target drops below 50%, where the choke is equally good next round. Skips a shielded round so the
shield breaks first.

**Fire line, captured 2026-09-02** (highlighted chartreuse bold, trigger `mnemosyne/080`):

```
You violently propel your kai energy at a haskrovska vine, enfeebling him.
```

The pattern deliberately stops before the pronoun -- the game picks him/her/it from the denizen's
gender, and "a haskrovska vine" is a plant that still took "him".

**Unrelated manual alias:** `ke` (`aliases/.../kaido/001_kai_enfeeble.lua`) sends
`kai enfeeble <target>` on the free queue, with no boon gate or cooldown. Since v4.7.419 it always
sends (it used to drop the command silently below 61 kai, read from `vitals.class`) and first warns
when kai is KNOWN to be short; with Spirit Rend held, a denizen target costs 0 (`ataxia_kaiCost`,
monk/004). It is a separate path and does not interact with the basher rider.


## NUMB fire line (v4.7.293)

```
You grit your teeth and will your pain out of existence.
```

Highlighted **turquoise bold** (`triggers/highlighting/060_Numb.lua`). AB Numbness (Kaido 894):
self, 3.00s equilibrium, defers 40% of incoming damage into one later blow.

**Read it as a warning, not a buff notice.** While numb is up the HP number stops tracking the
fight, which blinds the rate watchdog, the danger levels and the escape ladder until the deferred
lump lands -- the reason `ataxiaBasher_senselessFlurryNumb` refuses at or above the swarm threshold
and while any swarm tactic is running. Fires for Tekura as well as Rain-form Shikudo (v4.7.297).


## DEAF / BLIND self-senses -- the keeper is a TIMER, not a reply (v4.7.315)

Both classes self-apply **deafness** and **blindness** as DEFENCES, kept up automatically by
`deffing/007_Sense_Keepers.lua` (called once per prompt from `318_Prompt_Trigger.lua`).

**AB Deaf (Kaido 875)** -- `DEAF`, Works on/against: **Self**. *"This simply allows you to enter a
short trance and deafen yourself."* Note what the AB does **not** list: any balance or equilibrium
cost. It is a TRANCE that resolves over time, so nothing about sending it makes the next send wait.

Lines, live-captured 2026-09-17:

| Line | Meaning |
|---|---|
| `You stare straight ahead and concentrate on a distant focal point.` | deaf attempt in flight (trigger 763) |
| `The world about you falls silent as the deafness trance sinks upon you.` | deaf trance LANDED (trigger 773) |
| `Your hearing is suddenly restored.` | defence lost -- GMCP Removes it, and that is what re-arms the keeper |
| `You close your eyes for a moment.` | blind attempt in flight (trigger 762) |
| `You open your eyes once more, and the world about you is darkness.` | blind trance LANDED (trigger 772) |
| `You are already deaf.` | DEAF refused, already up (trigger 774) |
| `You are already blind.` | BLIND refused, already up (trigger 775) |

**All six lines are live-captured** (2026-09-17): attempt, landed and refusal for each sense. No
wording here is inferred.

**The refusal is a free state probe** -- the reasoning that wired the Fury refusal ("You're already
raged with fury!") and the shin-augment already-channelling line. It says two things: no trance
started, and the defence IS up. It takes the FULL hold (not the landed line's grace), because a
refusal means our picture is already wrong somewhere and backing off properly is the right response.
**It deliberately does NOT write `ataxia.defences`**, even though the game just stated the state --
this is the one place that rule is genuinely tempting. If GMCP disagrees with the game here then
GMCP is not tracking the defence, and something GMCP never Added it will never Remove, so the write
would be a belief nothing can ever clear: the v4.7.280 livelock reached from the opposite direction.
It warns once per session instead and lets the hold re-probe.

BLIND is no longer unconfirmed: the command `blind` works, trigger 762's line is right, and the
trance has a landing line of its own.

**The trance duration, measured once.** The blind capture brackets it: the attempt echoed before
the `13:59:29.740` prompt and the landed line fell between the `13:59:32.925` and `13:59:35.679`
prompts -- so **3.2s at minimum, 5.9s at most**. That sample spans a `GO!` into a ripple, so treat
the slow end as soft. It is still enough to condemn the old 6s hold, which was inherited from a
`tempTimer(6, ...)` and sat right on the boundary: a slow trance would have drawn a duplicate at
almost the moment it landed. The hold is 10s now, and the landed line collapses it to a 1.5s grace,
so a long hold no longer costs anything -- an opponent stripping the defence is answered in ~1.5s
rather than ~10s. The grace exists because GMCP's `Char.Defences` Add can lag the landed line, and
a fully cleared stamp would re-send into a defence that is already coming up.

**Why it needed fixing:** the old guard was `incomingdeafness`, set by the trigger matching the
ATTEMPT ECHO -- a guard fed by the game's reply, which cannot close until our command has made the
round trip. Six DEAF went out in 0.15s for one trance. The hold is now stamped at SEND time, and
again on the attempt echo so a **manually typed** DEAF is not answered with a duplicate. GMCP owns
whether the defence is up (`ataxia.defences.deafness` / `.blindness`); the client only owns whether
an attempt is in flight. See CLAUDE.md's Defense Systems section for the four rules this produced.


### Why the skill route matters: HERB BALANCE

DEAF and BLIND are **defences we want UP**, and they are TIMED -- they lapse on their own, and a
mob or a venom can strip them. There are two separate ways the eating balance can be wasted on
them, and they need different answers:

1. **SSC eating a herb to CURE them off** -- to *undeafen* us. Prevented by the AFFLICTION priority
   `26`, which means "ignored": `curing priority deafness 26` / `curing priority blindness 26`.
   Already set for every class in `ataxia/001_Default_Curing_Prios.lua:337-339`, and correct there
   -- the whole tree treats these two as kept defences (`004_Aff_gains_losses.lua` ignore lists,
   `mnemosyne/009` `AFF_IGNORE`). **Nothing to change; do not "fix" it per class.**
2. **SSC eating a herb to put the defence back UP** after a mob or venom strips it. This is what
   the SKILL keeper exists to prevent: the trance costs no herb balance, so raising it ourselves is
   free where the curative is not.

**So the keeper is the herb saving**, and it only had to be made to behave: the defence being TIMED
is exactly why it re-fires, and the pre-v4.7.315 guard was fed by the game's attempt echo, so it
could not close until the command had made the round trip -- six DEAF in 0.15s for one trance.

## Transmute, and Sharp Mind (v4.7.320)

**AB Transmute (Kaido 893)**, live-pasted 2026-09-18:

```
Syntax:            TRANSMUTE <amount>
Extra Information: Balance
Works on/against:  Self
Details: This will instantly turn the specified amount of mana into health, minus a bit that is
lost in the transfer.
```

Mana INTO health (this file said the reverse until v4.7.320). **It requires balance but does not
consume it** (user) -- which is the ideal shape for a rider on the bash round: it can only execute
when the round actually fires, so it runs once per swing and never on every 0.3s rebuild (the
v4.7.270 `shin augment` trap, where a balanceless command re-fired on every re-queue), and it
costs the combo nothing. "Minus a bit lost in the transfer": `transmute N` buys slightly under N
health, which is harmless for a top-up to `transmuteto`.

**Normally a gap-filler** (`ataxiaBasher_monkBashing2`, basher/002): only while sip balance is DOWN,
only at or below `transmuteat` (70%) HP, topping to `transmuteto` (99%), never spending past the
`manause` floor (30% mana). It is stingy on purpose -- every point transmuted is mana the rest of
the kit wanted, and server-side sipping is already healing us while sip balance is up.

**Sharp Mind changes the premise** (Mnemosyne boon, common: "Critical strikes restore 5% of your
mana", 15% echoed). The Monk bash round is a three-strike combo -- three chances to crit every
balance -- so the mana transmute spends comes back. With the boon held **and** in the tower,
transmute becomes a plain top-up (user-directed):

| | Gap-filler (default) | Sharp Mind, in the tower |
|---|---|---|
| Fires at HP | <= `transmuteat` (70) | <= `sharpmindat` (90) |
| Sip balance | must be DOWN | ignored |
| Tops up to | `transmuteto` (99) | `transmuteto` (99) |
| Mana floor | `manause` (30%) | `manause` (30%) -- kept as the safety net |

Flag `mnemSharpMind`, latched through the generic boon registry (`004 M.BOON_FLAGS`) from the
BOONS row or an `(ECHO)` row. **Tower-gated as well as boon-gated** because the registry clears its
flags on a confirmed run END but not at run START (a known registry gap), and outside the tower
there are no crits refilling anything. `ataxia.settings.sipping.sharpmindat` tunes the threshold.

## `sr` routing (v4.7.382, v4.7.456)
`sr` as a Monk calls `shikudoLock.dispatch()` (007_CC_Shikudo_Lock) by name. The group damage
route (013, v4.7.456) is the separate alias `srd` (user: "sr should be lock, srd should be
damage"). `shikudolock()` is also written in 008, but 008 is switched off, so at runtime only 007's
(007:754) exists; calling the method by name keeps `sr` right if 008 is ever switched back on.
It requires a Shikudo `Form` charstat. With none (Tekura) it echoes and does nothing.
