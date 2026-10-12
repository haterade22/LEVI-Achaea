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
fourth_attack: "153 vv - Tekura: tekura6.dispatch.run(), kaiMode cripple. Shikudo: shikudo.dispatchMind() if it exists (nothing defines it yet), else shikudo.dispatch() (006). Until v4.7.419 it called shikudo.setMode('godmode'), defined only in switched-off 008, and threw"
second_attack: "155 xx - Tekura: tekura.dispatch.run() (legacy TKD 3-limb). Shikudo: shikudo.dispatch() (006)"
group:         "154 sr - Shikudo only: shikudoLock.dispatch() (007) when a Form charstat is read; with none (Tekura) it echoes and does nothing"
shikudo:       "sk (aliases/.../shikudo/004_Dispatch.lua) -> shikudo.dispatch(); skata (shikudo/006_Kata.lua, v4.7.419) shows or overrides the kata caps"
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

### Alternative Kill: Shikudo Lock Route (Affliction-Based)
```yaml
type: affliction
summary: Pure affliction lock using Shikudo + Telepathy, damage through truelock

lock_progression:
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
    stupidity, epilepsy, ...) need no lock. The wiki also puts BLACKOUT behind the lock; the players' rule says
    otherwise, so confirm it on its first live use"
  impatience: "Required for hardlock"
  batter: "stupidity + epilepsy + dizziness"
  paralyse: "Backup for paralysis"

form_strategy:
  1: "Start in Willow - get anorexia via Hiraku"
  2: "Transition to Rain - build kata, apply slickness"
  3: "Transition to Oak - apply asthma, paralysis, weariness"
  4: "Stay in Oak - maintain afflictions, use Telepathy for impatience"

kill_method: "Once truelocked: damage (staff and kicks) or MIND SCYTHE. Telepathy helps BUILD the lock (MIND
  IMPATIENCE is its impatience); it is not saved for after it (corrected 2026-10-11)"

implementation:
  # Corrected 2026-10-11: 008 is switched off; the live lock is 007.
  file: "007_CC_Shikudo_Lock.lua"
  activate: "alias sr (154) -> shikudoLock.dispatch() by name, only when a Shikudo Form charstat is read;
    shikudolock() (007:628) is only its fallback"
  status: "sklstatus() / sklockstatus() (shikudoLock.status())"
  telepathy: "Since v4.7.417: on equilibrium (ataxia.vitals.eq, 007:428) it sends MIND IMPATIENCE / MIND
    BATTER / MIND PARALYSE <target> (007:434-445) with no mind lock first, chained after the round's combo
    (007:535-540; whether the game takes a MIND command and a combo in one queued round is untested).
    Until then it waited on ataxia.balances.eq, which nothing writes, and sent bare words. Still open:
    the blackout cycle, and Telepathy in the dispatch offense (006)"
  kata: "Its own caps (shikudoLock.maxKata: 12, Rain 24). Once its affliction rules have passed, it
    leaves a form 3 short of the cap (007:186-188). It does not read the shared policy in
    ataxia/monk/004 (v4.7.419); no offense does yet"
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

kill_flow:  # a design for the dispatch offense, not 006's code and not how the recorded kill went (see
            # above). 006 never sends SPINKICK (plan, Opportunities), leaves Rain with prepped legs at
            # kata 9 (006:396), and goes Oak -> Gaital once both legs are prepped, head or not (006:422-426)
  phase_1_prep_legs:
    form: "Rain (twice the normal chain length, wiki; the code caps it at 24)"
    attacks: "KURO left/right"
    goal: "Both legs to 90.8% (one hit from break)"
    protection: "Once prepped, use LIGHT attacks to avoid breaking"
    transition: "Rain → Oak when kata >= 5 and legs prepped"

  phase_2_prep_head:
    form: "Oak"
    attacks: "NERVESTRIKE, RISINGKICK head"
    goal: "Head to ~92% (one hit from break)"
    protection: "Use LIGHT on legs if hitting them, or hit torso/arms"
    transition: "Oak → Gaital when kata >= 5 and all limbs prepped"

  phase_3_kill:
    form: "Gaital"
    combo_1: "SWEEP + FLASHHEEL (prone + a broken leg). SWEEP uses both arms, so only a kick can
      join it: SWEEP + KURO is not a legal combo. Seen: combo <t> sweep flashheel left"
    combo_2: "SPINKICK + NEEDLE (breaks head + applies windpipe)"
    combo_3: "DISPATCH (instant kill)"

dynamic_thresholds:
  description: "Prepped = ONE HIT away from breaking (100%)"
  calculation: "threshold = 100 - attack_damage"
  examples:
    kuro_9.2_percent: "Leg prepped at 90.8%"
    thrust_14.5_percent: "Leg prepped at 85.5%"
    nervestrike_7.8_percent: "Head prepped at 92.2%"
  note: "Actual damage depends on target health - use shikudo_limbDamage table"

edge_cases:
  partial_prep: "If legs not fully prepped in Rain, Oak can finish with KURO"
  kata_constraint: "006 leaves Rain for Oak at kata 21+ (006:392-393). A completed transition starts the
    new form at kata 0; a refused one keeps the chain"
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
    kata_limit: "No game number (wiki: Rain allows twice the normal length; Tykonos never stumbles). 006 and
      007 cap at 12, 24 in Rain; Oak reached 13 with no stumble (log 2026-10-11), which rules out only a
      certain stumble at 12. The written policy (ataxia_KATA, ataxia/monk/004, v4.7.419; see 'Kai, kata and
      ASSESS' below) leaves at 12 after the combo, Rain 15, and is not read by any offense yet"
    kata_lapse: "A chain with no strike lapses about 20 s after the last one: 'You can no longer maintain
      your deadly kata.' (vNTjvghY:5967); the form is kept. KAI and MIND commands add no kata, so a run of
      them ages the chain (kb/combat/shikudo.md)"

kill_condition_check: |   # 006's check: stricter than the game (the leg term is not needed)
  tAffs.prone
  AND (lb[target].hits["left leg"] >= 100 OR lb[target].hits["right leg"] >= 100)
  AND (lb[target].hits["head"] >= 100 OR tAffs.damagedhead)
  AND (tAffs.damagedwindpipe OR tAffs.crushedthroat)
  → DISPATCH

notes: |
  Leg breaks are optional. As done live: SWEEP once, FLASHHEEL a leg every round to keep the target
  prone, NEEDLE until the head is past 100% and the throat is crushed, then DISPATCH.
  SPINKICK is the key - if head is already damaged (level 2), SPINKICK
  on a prone target instantly mangles it (level 3), setting up dispatch (Mystor; the spinkick
  strike line has never been captured).
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
  critical: "Windpipe damage is REQUIRED for Dispatch kill"

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
  critical: "If prone + damaged head → INSTANTLY MANGLES head!"

flashheel:
  skill: Shikudo
  balance: bal
  effect: "BREAKS the leg in one blow (CONFIRMED, log 2026-10-11: the target mended her legs after
    every flashheel), plus 8.4% limb damage. Not prep."
  syntax: "COMBO <target> flashheel left/right <staff1> <staff2>"
  forms: [Willow, Gaital]

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
# keeps a swept target down but is not required (006's own check still demands one: 006:95-106)
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
# The max_kata values below are the CODE's caps (006/007; 008 is switched off), NOT the game's: the wiki
# gives no number (Rain allows "twice the normal length"; Tykonos is exempt and can hold a chain
# indefinitely), and a log (2026-10-11) shows Oak at kata 13 with no stumble. The stumble line has never
# been captured. The written policy in ataxia/monk/004 (v4.7.419) differs: leave at 12 after the combo,
# Rain 15, Tykonos as soon as legal; no offense reads it yet.

Tykonos:
  max_kata: none  # wiki: Tykonos holds a chain indefinitely. 006/007 still cap it at 12 (006:83, 007:72), and 006 leaves at kata 9 (006:448-449)
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
  max_kata: 24  # DOUBLE chain length!
  staff_attacks: [kuro, hiru, ruku]
  kicks: [frontkick]
  transitions_to: [Tykonos, Oak]
  style: "Best for damage building"
  notes: "PRIMARY PREP FORM - 24 kata (the code's cap) = ~8 combos of sustained damage"

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
  notes: "Alternative kill with CRESCENT"

# Form Transition Paths
transition_map:
  Tykonos: [Willow]
  Willow: [Rain]
  Rain: [Tykonos, Oak]
  Oak: [Willow, Gaital]
  Gaital: [Rain, Maelstrom]
  Maelstrom: [Oak]

# 006's form cycle: Willow → Rain → Oak → Gaital (when ready)
#
# Willow: Start here, HEAD prep with hiru/hiraku; 006 leaves for Rain at kata 9 (006:376-381)
# Rain: PRIMARY LEG prep with kuro (24 kata, the code's cap), can also prep head with hiru
# Oak: HEAD prep with nervestrike. 006 goes on to Gaital at kata 5+ once both legs AND the head are
#      prepped (006:367-373), and at kata 9+ once both legs are prepped, head or not (Gaital's NEEDLE
#      finishes the head, 006:422-426), or with both legs and the head at 85%+ (006:428-437);
#      otherwise, at kata 9+, back to Willow (006:440)
# Gaital: setup form - sweep, needle (Gaital has spinkick too; 006 never sends it). DISPATCH works
#      from any form
#
# If kill fails in Gaital: Maelstrom → Oak → (continue cycle)
#
# Key: Dispatch needs prone + damaged head + crushed throat. 006 enters Gaital from Oak once both legs
#      are prepped (or legs and head are at 85%+), and SWEEPs there only once the legs AND the head are
#      prepped (006:417-440, 1032-1078; a MOUNTED target is swept sooner, by the fallback at
#      006:1128-1133): its own rules, not the game's
# Key: Rain has 24 kata (the code's cap) = ~8 combos of sustained prep time
```

## Shikudo Implementation (LEVI System)
```yaml
# LIVE: 006_CC_Shikudo_Dispatch.lua (dispatch) + 007_CC_Shikudo_Lock.lua (lock), with the strike ledger
# (010) and the shared monk state in ataxia/monk/004. 008 (the old "unified" file with setMode, riftlock
# and godmode) is SWITCHED OFF, so none of its modes or commands exist at runtime. (Corrected 2026-10-12:
# this section presented 008 as the live system.)

# On-disk files (levi_scripts/shikudo/ holds 001-010):
files:
  001_Shikudo.lua: "dead (no callers, or redefined by 006)"
  002_Shikudo_R2.lua: "dead"
  003_Dispatch_Dat_Hoe.lua: "switched off"
  004_Levi_Dispatch.lua: "dead"
  005_Shikudo_Needle_Logic.lua: "dead"
  006_CC_Shikudo_Dispatch.lua: "Dispatch -- LIVE (sk; zz/xx/vv when the monk has no stance)"
  007_CC_Shikudo_Lock.lua: "Lock -- LIVE (sr -> shikudoLock.dispatch(); shikudolock() is only its fallback)"
  008_CC_Shikudo_Offense_ALL.lua: "old unified offense (all modes) -- switched off"
  009_CC_Shikudo_GodMode.lua: "God Mode -- RETIRED, switched off in v4.7.419. Nothing could reach it (only 008's
    setMode routed to it) and its run() threw on the first tick. Its header lists why, and what a later
    riftlock or arm route should salvage. skgodmode()/skgmstatus() went with it"
  010_Shikudo_Strike_Ledger.lua: "Strike ledger -- LIVE (v4.7.419): records a light or absorbed ruku to the arm from
    its untargeted effect line (kb/combat/shikudo.md, 'What our triggers record')"

# Mode selection: none live. shikudo.setMode / shikudo.mode / godmode exist only in switched-off 008
# (008:67). vv no longer calls setMode (v4.7.419).

# Dispatch behaviour specifics (006, live)
dispatch_specifics:
  staff: "Every command carries 'wield staff489282;' (hardcoded) after combatQueue()'s prefix ('g body;g gold;
    stand;' plus a parry or a chase step when one is due; ataxia/ataxia/003_Queueing_Related.lua:17-20):
    006:1320, 1325, 1335, 1350"
  mhaldorian_safety: "On a Mhaldorian target, sends INCAPACITATE instead of DISPATCH (friendly-fire safety, 006:1316-1322)"
  shield: "If target shielded, SHATTER inside the combo (006:1335)"
  kai_surge: "006 never sends KAI SURGE. The Rain dismount and the Gaital kai window were 008-only (switched
    off). 007 only echoes 'KAI SURGE READY' at 31 kai read from vitals.class (007:41, 497-498), a display;
    the real cost is 45 (ataxia/monk/004, kb/CONFLICTS.md #9). Only TK6 sends a surge automatically"

quick_commands:  # live functions only
  dispatch: ["sk alias", "shikudo.dispatch() (006:1270)", "levishikudodispatch() (006:1365)"]
  dispatch_status: ["shikudo.status() / skstatus() (006:1373, 1430)"]
  lock: ["sr alias", "shikudoLock.dispatch()", "shikudolock() (007:628)"]
  lock_status: ["sklstatus() / sklockstatus() (007:632, 636)"]
  kata_caps: ["skata alias -> ataxia_kataCommand() (monk/004, v4.7.419)"]
  # skdispatch, sklock, skriftlock, shikudoriftlock, shikudo.reset, shikudo.setMode: 008 only (switched off)

# Current dispatch system (006_CC_Shikudo_Dispatch.lua; the helpers below are 006:134-266)
current_system:
  description: "Dynamic threshold-based dispatch with leg protection"

  dynamic_thresholds:
    purpose: "Calculate 'prepped' based on actual damage per hit"
    functions:
      - "shikudo.getLimbDamage(limb) → safely gets lb[target].hits[limb] or 0"
      - "shikudo.getLegPrepThreshold() → 100 - kuro_damage (~90.8%)"
      - "shikudo.getHeadPrepThreshold() → 100 - form_attack_damage"
      - "shikudo.isLegPrepped(leg) → true if leg >= threshold"
      - "shikudo.areBothLegsPrepped() → true if both legs prepped"
      - "shikudo.isDynamicHeadPrepped() → true if head >= threshold"
      - "shikudo.isLegSafe(leg) → true if safe to hit (head prepped or leg not prepped)"
      - "shikudo.getFocusLeg() → returns leg with LESS damage (hit first to balance prep)"
      - "shikudo.getOffLeg() → returns leg with MORE damage (secondary target)"

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
    damage_adjustment: "Head prep threshold changes from ~92% to ~96% (half damage)"
    functions:
      - "shikudo.setHyperfocus(limb) (006:283): NOTHING calls it. The trigger shikudo/003_Hyperfocus_Detection
        writes ataxiaTemp.hyperLimb (003:39), while 006 reads shikudo.state.hyperfocus (006:158, 197, 216), so
        the halved damage is never applied (plan finding 6, open)"
      - "shikudo.getHyperfocusCommand() (006:308) → returns 'hyperfocus head' if not already set"
      - "shikudo.isHyperfocusSet() (006:301) → true if head is hyperfocused"
    auto_behavior: "None: 006 sends no HYPERFOCUS ('Removed automatic hyperfocus - user will do this manually',
      006:1312-1313)"

  transition_priority:
    flow: "Willow → Rain → Oak → Gaital (when ready)"
    0_all_ready: "BOTH legs AND head prepped at kata 5+ → one step toward Gaital (006:367-373)"
    1_willow:
      early_exit: "Willow at 9+ kata → Rain (006:376-381; there is no 6-kata exit)"
    2_rain:
      legs_prepped: "Rain legs prepped + kata 9+ → Oak (for nervestrike head prep)"
      overflow: "Rain kata 21+ → ALWAYS go to Oak (safety transition before 24 stumble)"
    3_oak:
      all_ready: "Oak at kata 5+ with both legs AND the head prepped → Gaital (006:367-373)"
      legs_prepped: "Oak at kata 9+ with both legs prepped, head or not → Gaital, whose NEEDLE finishes the
        head (006:422-426)"
      close: "Oak at kata 9+ with both legs and the head at 85%+ → Gaital (006:428-437)"
      not_ready: "Oak at kata 9+ otherwise → Willow (cycle back for more prep, 006:440)"
    4_gaital:
      kill_ready: "Stay for dispatch"
      stuck: "Kata 9+ and not ready → Maelstrom → Oak (cycle out)"

  transition_syntax:
    description: "Both forms work live: inline at the end of a combo (006:1238, 1260; log 1, attacker:443,
      'combo Claes frontkick left kuro left ruku right transition oak'), or a separate TRANSITION TO <FORM>
      FORM (log 1, e.g. attacker:321 'transition to Rain form'; it costs no balance and twice went through
      while paralysed; Mystor sends 'transition to rain form' ahead of a dispatch, LcJC-rJ5:5847). 007
      sends ';transition to the <form> form' after its combo (007:545). No log here shows that wording,
      but the PvE basher sent it, after its combo, until v4.7.68, and the game answered with the kata
      refusal (CHANGELOG v4.7.68, commit 9064ca04), so the game reads it as a TRANSITION; whether it
      succeeds at kata 5+ is unseen"
    example: "combo target risingkick head nervestrike livestrike transition willow"
    note: "006 leaves non-Rain forms at kata 9 because it assumes a stumble at 12; the game gives no number
      (kb/CONFLICTS.md #8: Oak 13 and Rain 18 seen with no stumble)"

  leg_protection:  # 006's intent; it cannot work for flashheel
    principle: "006 avoids breaking prepped legs with LIGHT staff strikes"
    flaw: "FLASHHEEL breaks a leg in one blow and is Willow's only kick, so isLegSafe() (006:266, used at
      006:649) cannot stop a Willow or Gaital flashheel breaking a leg (plan finding 3, open). And breaking
      the leg is how the recorded kill kept the target down"
    forms_protected: [Rain, Oak, Tykonos, Willow]
    willow_behavior: "If legs prepped but head not ready, hit already-broken leg if possible"

  kill_sequence:
    phase_1: "Willow: START HERE, head prep with hiru/hiraku, transition to Rain at kata 9 (006:376-381)"
    phase_2: "Rain: PRIMARY LEG prep with kuro (24 kata, the code's cap), can also prep head with hiru"
    phase_3: "Oak: HEAD prep with NERVESTRIKE FIRST (paralysis prevents parry!)"
    phase_4: "Gaital: entered once both legs are prepped (006:422-426); NEEDLE the head until it is prepped
      too (006:1032-1066), then sweep + break → dispatch (006:1069-1078)"
    fallback: "If kill fails in Gaital: Maelstrom → Oak → (continue cycle)"

  attack_ordering:
    description: "Combo syntax is flexible: COMBO target attack1 attack2 attack3"
    principle: "Order attacks to maximize affliction/prone benefits"

    oak:
      order: "staff1 + staff2 + kick (STAFF FIRST)"
      reason: "Nervestrike paralysis prevents parrying subsequent attacks"
      example: "combo target nervestrike kuro left risingkick head"

    rain:
      order: "kick + staff1 + staff2 (KICK FIRST - default)"
      reason: "Frontkick can prone, which bypasses parry for staff attacks"
      example: "combo target frontkick left kuro left kuro right"

    gaital_sweep:
      order: "sweep + kick (SWEEP FIRST)"
      reason: "Sweep prones target, kick hits while prone"
      example: "combo target sweep flashheel left"
      note: "Sweep uses both arm balances - only one kick allowed"

    maelstrom_sweep:
      order: "sweep + kick (SWEEP FIRST)"
      reason: "Same as Gaital - sweep prones, kick follows"
      example: "combo target sweep risingkick head"

    maelstrom_normal:
      order: "kick + staff1 + staff2 (KICK FIRST - default)"
      reason: "Risingkick stuns if prone, crescent for damage"
      example: "combo target risingkick head livestrike ruku torso"

    other_forms:
      order: "kick + staff1 + staff2 (default)"
      reason: "No special affliction ordering needed"
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
    attack and do telepathy'; log 1's alias swapped the combo out for the MIND command). Open: in log 2 a
    blackout arrived inside a combo round (kb/combat/shikudo.md)"
  mindlock: "Needed for a target outside the room and for certain skills such as Radiance and Sapience (the user
    and Mystor), so not a setup step for the (*) attacks in the room. Open for BLACKOUT: the wiki puts it behind
    the lock and it has not been tried in the room without one (kb/CONFLICTS.md #7)"
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
- Sweep: "The staff sweeps the legs out from under <T>, sending her sprawling." (prone)
- Needle: "The end of the staff smashes into the exposed throat of <T>, crushing cartilage." (crushed throat)
- Dispatch: "Placing one foot on the chest of <T> to hold her in place, you drive your staff down with all
  your strength into her weakened throat. ..." then "You have slain <T>."
- SPINKICK on a prone head: the strike line has never been captured
- Stumble: "You lose your rhythm" (UNVERIFIED: in no log and no trigger). Per the wiki a stumble resets the kata
  AND drops you into Tykonos; Tykonos itself never stumbles. Since v4.7.419 monk/003 records a move into
  Tykonos we did not ask for as a probable stumble, so the real line can be kept when it happens
- Hyperfocus: "You will now focus on bypassing attempts to deflect blows when striking the *" (trigger
  shikudo/003's pattern; no log has it, only Mystor's "-Def: hyperfocus.")
  → the trigger stores ataxiaTemp.hyperLimb (003:39); 006 does not read it
- Hyperfocus clear: "You stop focussing upon bypassing your target's parry" (no log has it, no trigger)

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
  done that way in log 2026-10-11). 006's checkDispatchReady() still also demands a broken leg (006:95-106;
  plan finding 4, open)
- Mental afflictions from Telepathy can add lock pressure
- SPINKICK behavior changes based on target state:
  - Standing: hits TORSO
  - Prone: hits HEAD with massive damage
  - Prone + damaged head: INSTANTLY MANGLES head (level 2 → 3)
- SWEEP uses BOTH arm balances - only one kick allowed
- Form transitions require 5+ kata (can transition anytime after 5 if conditions met)
- Rain allows "twice the normal length" of kata (wiki); the 24/12 caps are the CODE's. A stumble is a chance
  that grows the longer a chain runs (wiki), so log 2026-10-11's Oak 13 and Rain 18 without one rule out only a
  certain stumble at 12, not a 12/24 limit. Tykonos is exempt
- 006 leaves Willow at kata 9 (006:376-381), not 6
- Rain stays and preps head with hiru if legs already prepped (no rush, 24 kata: the code's cap)
- Oak at 9 kata goes to Gaital once both legs are prepped (head or not: Gaital's NEEDLE finishes it) or
  legs and head are at 85%+, otherwise cycles back to Willow for more prep (006:417-440)
- Gaital at 9 kata goes to Maelstrom if kill not ready (Maelstrom → Oak → Gaital cycle)
- Other non-Rain forms transition at 9 kata
- 006 transitions inline ("combo target kick staff1 staff2 transition form"); 007 sends a separate
  "transition to the <form> form" after its combo (007:545). No log here shows that wording; the PvE basher
  sent it until v4.7.68 and got the kata refusal (CHANGELOG v4.7.68), so the game reads it as a TRANSITION,
  but a success at kata 5+ is unseen
- LIGHT: seen only on STAFF strikes (kuro, ruku, hiru, hiraku, nervestrike, livestrike and jinzuku light in
  Mystor's logs); every "light risingkick" there is "nervestrike light risingkick". Whether a kick can be
  light is UNVERIFIED
- Willow's only kick is flashheel, and every flashheel BREAKS the leg (log 2026-10-11); 006's isLegSafe()
  (006:649) tests limb %, so it cannot prevent the break (plan finding 3)
```

## Kai, kata and ASSESS: shared monk state (v4.7.419)

`ataxia/monk/004_Kai_And_Kata.lua` writes down once the facts the code still holds as scattered
literals, one of them wrong (Kai Surge: 31 in 007's READY echo, 45 on the wiki). In v4.7.419 its
readers are TK6's dismount (`tekura/002`), the kaido aliases and `skata`. **The Shikudo offenses
(006, 007) do not read it yet** and keep their own copies (kata caps 12, Rain 24; 007's surge 31),
as the basher keeps its PvE literals (`SHIKUDO_BASH_ROTATION`); wiring the offenses to it is the
next part of the rework. Tests: `test_monk_kai_kata.lua`.

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

## `sr` routing (v4.7.382)
`sr` (alias `154_Group_(All_Classes)`) as a Monk calls `shikudoLock.dispatch()` (007_CC_Shikudo_Lock)
by name. `shikudolock()` is also written in 008, but 008 is switched off, so at runtime only 007's
(007:628) exists; calling the method by name keeps `sr` right if 008 is ever switched back on.
It requires a Shikudo `Form` charstat. With none (Tekura) it echoes and does nothing.
