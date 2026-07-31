# Runewarden

## Metadata
- **Type**: Knight
- **Combat Style**: Limb | Affliction (depends on spec)
- **Difficulty**: Medium
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Runelore: Mystical runes for combat and utility
Discipline: Passive abilities and combat enhancements
Weaponmastery: Combat with various weapon specializations (DWC, DWB, SnB, 2H)
```

## Specializations (Weaponmastery)
```yaml
DWC (Dual Wield Cutting):
  weapons: [scimitar, scimitar] or [longsword, longsword]
  style: Fast attacks, double venom application
  strength: Speed, venom stacking

DWB (Dual Wield Blunt):
  weapons: [mace, mace] or [flail, flail]
  style: Limb breaking, double breaks per attack
  strength: Best limb prep, breaks through parry

SnB (Sword and Board):
  weapons: [longsword, shield] or [broadsword, shield]
  style: Impale/stun combos, defensive
  strength: Damage mitigation, reliable disembowel

2H (Two-Handed):
  weapons: [bastard sword] or [warhammer]
  style: High damage, strip defenses
  strength: Best damage, passive para cure, strips rebounding/shield
```

> **Implementation note**: Only **Dual Blunt (DWB)** has an implemented dispatch offense
> (`dwbRunie`, `dwb_runie/001_DWB_Runie_Logic.lua`). The `zz`/attack aliases gate it on
> `ataxia.vitals.knight == "Dual Blunt"`
> (`aliases/.../152_First_Attack_(All_Classes).lua:23-26`). **`ataxia.vitals.knight` is the
> canonical weapon-spec read** (parsed unprefixed by `ataxia_Vitals_Update` from `charstats`);
> the old positional `gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt"` was replaced in v4.7.102
> because charstats order isn't guaranteed (RW Spec at `[3]`, Infernal at `[4]`). DWC / SnB / 2H
> specs have no RW-specific offense — they only run through the shared basher (see Bashing below).

## Kill Routes (DWB — `dwbRunie`)

The implemented offense (`dwb_runie/001_DWB_Runie_Logic.lua`) has **three modes**, selected via
`dwbRunie.setMode(...)` (aliases `rwtorso` / `rwpulp` / `rwgroup`). All kills are momentum-fuelled
damage, not disembowel/behead. Shared finishers (checked in `dispatch()` before mode routing):
**BISECT** at low health and **PULP** on a mangled head or 5+ skull fractures while prone.

### Mode: Torso Damage (`rwtorso`, default)
```yaml
type: limb + damage
summary: Break both legs (expend → prone) + torso, then assault the torso with flails
steps:
  1: "Prep left leg, right leg, torso (doublewhirl, lower-damage limb first)"
  2: "whirl right leg expend  → prone"
  3: "doublewhirl left leg torso  → break both"
  4: "assault <target> torso (flails) when momentum ≥3, doubled at ≥6"
  5: "morningstar doublewhirl torso pressure to rebuild momentum between assaults"
fork: "If target RESTOREs torso while legs still broken → pivot to skull fractures → PULP"
evidence: "dwb_runie:475-533"
```

### Mode: Head Pulp (`rwpulp`)
```yaml
type: limb + execute
summary: Break legs (prone) + head, assault head to mangle, build skull fractures, PULP
steps:
  1: "Prep left leg, right leg, head, torso (torso prepped for fork options)"
  2: "whirl right leg expend → prone; doublewhirl left leg head → break both"
  3: "assault <target> head at momentum ≥7 (mangles head)"
  4: "skull-fracture loop (doublewhirl head head [expend]) toward 5 fractures"
  5: "dismount;pulp <target> once head mangled OR 5+ skull fractures + prone"
fork: "Tumble fork — if target escapes prone → pivot to torso (already prepped)"
evidence: "dwb_runie:539-612"
```

### Mode: Group (`rwgroup`)
```yaml
type: limb + damage (team)
summary: Prone + torso damage with party callouts for pile-on coordination
notes: "Same break/execute shape as torso; sends 'pt <target> PRONE + TORSO BROKEN - PILE ON' via partyrelay"
evidence: "dwb_runie:618-654"
```

### Shared finishers (dispatch, all modes)
```yaml
bisect:  "assess <= 34 (config.bisectThreshold) and no shield → wield bastard;bisect <target>"
pulp:    "prone + (head mangled: 200% or concussion) OR skull fractures >= 5 → dismount;pulp <target>"
evidence: "dwb_runie:230-232,205-212,716-728"
```

## Momentum (core resource)
```yaml
# dwbRunie.getMomentum() = tonumber(ataxia.vitals.class)  (dwb_runie:189-204)
source: ataxia.vitals.class
thresholds:
  assault_torso:        ">= 3   (canAssaultTorso)"
  double_assault_torso: ">= 6   (canDoubleAssaultTorso — two torso assaults in one action)"
  assault_head:         ">= 7   (canAssaultHead — mangles head instantly)"
notes: |
  Momentum drives every mode. Morningstar doublewhirl builds it; flail assault spends it.
  Parry response and skull-fracture loops branch on 2+ / 1 / 0 momentum.
```

## Mode Aliases
```yaml
# aliases/.../dual_blunt/009_DWB_Runie_Mode.lua (regex ^rw(torso|pulp|group|status)$)
rwtorso:  "dwbRunie.setMode('torso')"
rwpulp:   "dwbRunie.setMode('pulp')"
rwgroup:  "dwbRunie.setMode('group')"
rwstatus: "dwbRunie.status()  — echoes mode, momentum, per-limb damage, skull fractures/cracked ribs"
# attack keys (152_First_Attack): zz → setMode('torso') + dispatch(); gated on ataxia.vitals.knight == "Dual Blunt"
```

## Offensive Abilities (DWB — actual fire commands)
```yaml
# These are the commands dwbRunie actually issues (dwb_runie:442-448,485-488,566,718,725,732)
whirl:
  effect: "Single-weapon limb hit (e.g. break a leg with 'expend')"
  syntax: "whirl <target> <limb> [expend]"

doublewhirl:
  effect: "Both weapons; prep or break one/two limbs. 'expend' consumes momentum"
  syntax: "doublewhirl <target> <limb> [expend] [<limb2> [expend]]"

assault:
  effect: "Flail/morningstar momentum-damage strike; torso ≥3 mom (≥6 doubled), head ≥7 mom (mangles)"
  syntax: "assault <target> torso | head"

pulp:
  effect: "Head execute — mangled head or 5+ skull fractures while prone"
  syntax: "dismount;pulp <target>"

bisect:
  effect: "Low-health finish (assess <= 34, no shield); wields a bastard sword first"
  syntax: "wield bastard;bisect <target>"
  # AB (2026-07-31): "BISECT <target> [venom]" | works on adventurers AND DENIZENS |
  # 4.00s of BALANCE. Requires an edged runeblade with HUGALAZ sketched on the blade.
  # Multi-typed: lightning first, then cutting. Bypasses rebounding/reflections but
  # LEAVES THEM INTACT. The "slain outright at <=20% health" clause is ADVENTURERS ONLY.
  # SnB does NOT need the bastard re-wield -- an edged longsword qualifies (live: Valafar).
  # PvE: see the Thunderclap boon below.

fracture:
  effect: "Used in the raze/strip path to remove rebounding/shield"
  syntax: "falcon track <target>;falcon slay <target>;fracture <target>"

falcon:
  effect: "Falcon companion - slay (prepended to assaults), track/rake, plus 'falcon rake' bash pet hit"
  syntax: "falcon slay | track | rake <target>"
  # Rake has TWO landing animations, both matched since v4.7.178 (trigger 370):
  #   "A razor-beaked falcon dives at <t>, raking his face with its talons."
  #   "A razor-beaked falcon rips out a chunk of <t>'s flesh with its beak."
  # They re-arm the 30s cooldown from the LANDED moment, not from the order. Negative
  # lookaheads (?!you,) / (?!your flesh) keep the turned-on-us forms out -- counting those
  # would put the rake on cooldown for a hit we never ordered. Trigger 376 owns the at-us
  # case and sends `order falcon passive` (free, no balance).
  # Highlighted like the Infernal hyena maul: order = dark_sea_green, landing = chartreuse
  # bold, refusal = dim_grey. Never the orange family (user-reserved).

# Runes are applied as WEAPON EMPOWERMENT, not standalone sketches (see below)
empower:
  effect: "Sets the rune empower priority on wielded weapons before attacking"
  syntax: "empower priority set isaz wunjo sowulu"
```

### Rune / weapon setup
```yaml
# dwb_runie:36-44,56-69,254-281 — runes here are weapon empowerment, NOT ground sketches / touch effects
loadout: "Dual morningstar + dual flail (per-weapon wield IDs in dwbRunie.config.weapons)"
per_weapon: "sketch nairat on each weapon; sketch configuration wielded isaz wunjo sowulu"
empower:    "'empower priority set isaz wunjo sowulu' sent once on weapon-type switch (anti-spam)"
switching:  "morningstar for prep/breaks/head; flail for torso assault"
```

## Defensive Abilities
```yaml
fitness:
  skill: Weaponmastery
  effect: "Passively cures asthma"
  cures: [asthma]
  blocked_by: [weariness]
  trigger: "Automatic when asthma is gained"

sowulu:
  skill: Runelore
  effect: "Weapon-empower rune in this system (part of the isaz/wunjo/sowulu empower set), not a self-heal"
  syntax: "empower priority set isaz wunjo sowulu"
  note: "isaz, wunjo and nairat are likewise applied here as offensive weapon runes, not touch/ground effects"

thurisaz:
  skill: Runelore
  effect: "OFFENSIVE line-of-sight damage, not a barrier (740_Rune_Found.lua:64 = 'LoS damage').
           The alias sends it targeted -- you do not sketch a defensive barrier FOR someone."
  syntax: "sketch thurisaz on ground for <target>   (aliases/.../137_thurisaz.lua:17)"
  note: "Corrected v4.7.171; this file previously called it a defensive barrier rune."

dagaz:
  skill: Runelore
  effect: "THE passive heal -- cures one affliction on its own timer. See the Dagaz section below."
  line:   "A rune like a rising sun upon the ground flares, bathing you with healing magic."
```

### Dagaz - the passive heal (v4.7.171)
```yaml
# Ground rune (Runelore). Fires on its own timer and cures ONE affliction for free.
line:      "A rune like a rising sun upon the ground flares, bathing you with healing magic."
effect:    "cures affs" (740_Rune_Found.lua:62)
interval:  "12s (user-confirmed 2026-07-30). passiveCooldownTimingsV3.passive_dagaz,
            affliction_tracking_core/007:1136. This is a GAME CONSTANT shared by 23 of the 27
            tracked passives -- the table groups them under a literal '-- 12s cooldowns'
            comment, dagaz and fitness among them. Only hallelujah (14s) and the tarot
            passives suntarot/panacea/fool (20s) differ. An earlier note here called the
            number an enemy-side model of unknown applicability to us; that was wrong."
trigger:   "passive_active/027_Dagaz_(Runewarden).lua -- ONE trigger, BOTH sides. The capture
            is (\w+): an enemy's rune yields their name and feeds the V3 target tracker; ours
            yields the literal 'you'."
gotcha:    "Until v4.7.171 only the enemy branch existed. isTargeted('you') is false, so on our
            own proc the trigger fired and did NOTHING -- not even its highlight. The self
            branch now highlights the line medium_sea_green (deliberately not spring_green,
            which already means parry-success)."
not_tracked: "We still have no idea whether OUR dagaz is ready -- passiveCooldownsV3 is
            entirely enemy-side, and no ground rune in the package is tracked as a state
            (sowulu/raido/thurisaz are all send-only with room/ripple latches)."
```

### Thunderclap (Mnemosyne boon) -- bisect becomes the crowd swing
```yaml
# ataxiaBasher_rwBisect, basher/002. Flag mnemThunderclap (trigger mnemosyne/052).
boon:      "Your bisect ability now strikes a third time, dealing bonus electric damage
            to all denizens in your location."
effect:    "BISECT stops being a single-target finisher and becomes a ROOM hit."
gate:      "ataxiaBasher.bisectAt denizens (default 2). Over a 4s window combination lands
            2 swings on ONE mob; bisect lands 1 empowered strike on the target PLUS electric
            on EVERY denizen -- twice the balance for room-wide coverage. At 1 denizen there
            is nothing to splash to, the only case the gate excludes; from 2 upward bisect
            covers ground combination cannot, widening with each extra mob. bisectAt tunes
            UPWARD only -- 2 is a CLAMPED FLOOR, not a default (user rule): at one denizen
            the third strike has nothing to splash to, so no setting makes it correct.
            Same trade as Infernal Arc (4.75s vs ~2s dsl, 2+)."
replaces:  "the swing (both spend balance) -- but the FREE falcon rake still rides"
skips:     "shielded rounds (bisect bypasses rebounding, NOT shields); non-numeric target"
no_execute: "the <=20% slain-outright clause is ADVENTURERS ONLY -- no low-hp branch exists"
prereq:    "an edged runeblade with HUGALAZ on the blade -- NOT managed by the system.
            Nothing here knows hugalaz and the blade-sketch syntax was never captured."
fire_line: "Lightning follows the path of <weapon> as you sweep it at <target>, a clap of
            thunder heralding your strike.  -> highlighting/035, chartreuse bold"
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
# DWB prep set depends on mode (dwb_runie:476,540,620)
prep_set:
  torso_mode: [left leg, right leg, torso]
  pulp_mode:  [left leg, right leg, head, torso]
break_sequence: "whirl right leg expend (→ prone), then doublewhirl left leg + <torso|head>"
finisher: "assault torso / PULP head / BISECT (see Kill Routes) — no DISEMBOWEL exists in code"

## Parry Handling (dwb_runie:218-228,367-383)
parried_limb_source: "ataxiaTemp.parriedLimb ('none' when clear)"
disable_parry: "doublewhirl ... left arm expend  → applies 'numbedleftarm' (isParryDisabled)"
parry_response_by_momentum:
  "2+": "doublewhirl <primary> expend left arm expend  (disable + progress)"
  "1":  "doublewhirl left arm expend <unprepped non-parried limb>"
  "0":  "untargeted doublewhirl to generate momentum"

## Restoration forks
torso_mode: "torso RESTOREd while legs broken → pivot to skull fractures → PULP (dwb_runie:502-504)"
pulp_mode:  "head RESTOREd or target stands (tumble) → pivot to torso assault (dwb_runie:546-560,574-584)"

## Misc gates (dwb_runie:441,708-714,730-735)
clumsiness: "auto-cured with 'discipline' before breaking legs"
anti_serpent: "shield on impatience vs Serpent until cured"
instant_cath: "myinstantcath → touch shield"
raze_path: "rebounding/shield → falcon track;falcon slay;fracture <target>"
```

## Bashing (PvE)
```yaml
# ataxiaBasher_runewardenBashing() is spec-branched on ataxia.vitals.knight
# (basher/002_Class_Bashing.lua:1521-1559)
attack_skill: Weaponmastery
spec_branches:
  Dual Cutting: { raze: "razeslash <target>",                    bash: "dsl <target>" }
  Two Handed:   { raze: "battlefury focus speed;carve <target>", bash: "battlefury focus speed;slaughter <target>" }
  Dual Blunt:   { raze: "fracture <target>",                     bash: "doublewhirl <target>" }
  else (SnB):   { raze: "combination <target> raze smash",       bash: "combination <target> slice smash" }
  # `razeslash` is spelled out (v4.7.151, 002:1535) -- `rsl` is a personal server-side
  # alias, not a game command. Corrected across every knight DWC branch in the basher.
battlerage:
  raze: "ataxiaBasher.battlerage.Runewarden.raze (used when shielded + rageraze + rage >= 17)"
  # There is no 'slash'/'rend' battlerage — that was fictional.
  # PvE rotation is OWNED (RW_BR, basher/002) — timer-free, real AB cooldowns:
  owned_rotation:
    bulwark:   { rage: 28, cd: 45, target: self, note: "25% damage negation, 15s -- NOT mob-count gated" }
    etch:      { rage: 25, cd: 23, needs: "aeon or stun on the denizen (it consumes one)" }
    onslaught: { rage: 36, cd: 23 }
    collide:   { rage: 14, cd: 16 }
  # Fire lines -- each calls ataxiaBasher_rwConfirm(key) (002:1467-1473), which restamps
  # ataxiaTemp.rwBrAt[key] from the LANDED moment and releases the in-flight replay:
  fire_lines:
    collide:   "330:47 -- You charge at <t>, slamming into him and throwing him back."
    onslaught: "331:47 -- You unleash a ferocious onslaught on <t>..."
    bulwark:   |
      332:37 -- "The runes on your armour flare brightly as you adopt a defensive stance."
      The Runewarden branch (332:99-113) calls rwConfirm("bulwark") and bolds the line in
      gold -- 25% negation for 15s is the thing most worth SEEING land mid-bash.
    etch:      |
      375_Runewarden_Etch_Landed.lua (captured live 2026-07-30) -- "You trace the outline
      of a rune in the air with <weapon>. The edges catch fire as it hurtles towards
      <target>, clipping him slightly as it dissipates." Matched as a SUBSTRING on the
      opening clause (375:34, type 3), because the weapon name and the target both vary.
      Etch was the ONE ability in RW_BR with no fire line, so
      its in-flight replay had nothing to release it: after the queued etch fired, the
      next two rebuilds re-queued the SAME etch and the server rejected both ("You must
      wait a short time before you can use a battlerage ability again"). Two wasted
      cycles back to back, live.
    bulwark_end: |
      "The runes on your armour cease to glare as your bulwark ends." -- captured from the
      log but NOT handled anywhere (no trigger matches it as of v4.7.169). It marks the end
      of the 15s DURATION, not the 45s cooldown, so nothing in the rotation needs it today;
      it is the line to wire if we ever want true bulwark uptime measurement.
  # Legend deck: XYLTHUS plants a battlerage-style STUN, which is what Etch cashes in --
  # Etch's needsAff is {aeon, stun} (002:1460) and stun carries dur = 4s in
  # ataxiaBasher_BR_AFFS (basher/008:60-62). The Mnemosyne card layer (basher/010) draws it
  # only when 25 rage is affordable AND Etch is off cooldown (010:97-99, CARD_EXPLOIT), and
  # records the stun only once the draw is CONFIRMED -- an optimistic stamp is what let Etch
  # spend 25 rage on a phantom stun, twice, in the v4.7.165 live log.

# Falcon rake (ataxiaBasher)
# Free pet attack prepended to the bash when off cooldown (mirrors Infernal hyena maul).
falcon_rake:
  command: "FALCON RAKE <target>"
  cooldown: "30s (ataxiaBasher.falconRakeCooldownSec)"
  behavior: "Prepended to the spec bash string when ataxiaBasher.falconRakeReady is true"
  tracking: "basher/005_Falcon_Cooldowns.lua (triggers 370/371, timer fallback)"
```

### Battlerage READY lines — the cooldown feed we were discarding (v4.7.167)

The game names the exact ability coming off cooldown, and it does so in two wordings:

> You can use Collide again.
> Your Collide ability could be used again but you lack the necessary Rage.

The second is the *same event* seen through an empty rage bar — the cooldown expired, we
simply cannot pay for it yet. Both mean READY NOW. Trigger `328_Battlerage_Ready.lua:34-37`
captures the verb from either form and hands it to `ataxiaBasher_brReady`
(`basher/011_Battlerage_Ready_Lines.lua:91-116`), which lower-cases it, looks it up in
`BR_READY_MAP` (`011:60-81`) and clears the owning rotation's send-side stamp — for
Runewarden that is `ataxiaTemp.rwBrAt`, keyed `bulwark` / `etch` / `onslaught` / `collide`
(`011:62-65`). It also drops the in-flight replay if the pending pick is that same verb
(`011:110-113`): an ability the game just declared ready is by definition not still in flight,
so replaying it would re-send a pick whose cooldown was already reset.

Why this matters more than it sounds: until v4.7.167 `RW_BR` *guessed*, stamping an epoch at
send time and comparing against a hardcoded `cd` (`002:1501`). That guess is wrong in both
directions — too slow when a boon or gear shortens the real cooldown (the ability idles after
it was actually available), and too fast when a stamped pick never executed (queue cleared,
round refused for broken arms, target died), leaving the rotation believing an ability is
spent that never fired. The server settles it for free. The handler is class-agnostic and an
unknown verb is simply ignored, so it costs nothing for classes without an owned rotation.

**Rage starvation is the live context.** The captured lines are Collide, Bulwark and Etch
(plus Cullingblade, which is not an RW_BR slot) — Onslaught is not among them (`011:42-45`) —
and the ones quoted in the v4.7.166 log are the second, rage-starved form. Which figures:
28 (bulwark) + 36 (onslaught) + 25 (etch) + 14 (collide) is 103 rage for one pass of the
rotation, so it spends long stretches with everything off cooldown and nothing affordable.
Roughly ten free cooldown facts in three minutes, every one of them previously discarded.
This is also why the legend-deck layer's `ataxiaBasher_rageAfford` floor matters: a card drawn
for a payoff we cannot pay for is a wasted hourly charge.

Numbered 328 so it sits immediately before 329 (`Battlerage_Global_Cooldown`, the "You must
wait a short time..." rejection) — the same signal inverted. Together they bracket the true
cooldown window from the server instead of from our client-side arithmetic.

### The falcon turning on us (v4.7.167)

The Runewarden twin of the daemonic hyena flip (Infernal, trigger 372). Trigger
`376_Falcon_Turned_On_Us.lua` matches **both** of the falcon's attack lines in their
second-person form:

```
^A razor-beaked falcon dives at you, raking your face with its talons\.$
^A razor-beaked falcon rips out a chunk of your flesh with its beak\.$
```

Against a real foe those read "...dives at a revolting ghoul, raking **his** face..." and
"...rips out a chunk of **a wraith's** flesh...", so the anchored second-person patterns
cannot fire on a normal rake (`376:34-37`).

The response is `order falcon passive`, sent directly with a 10s debounce (`376:59-67`). It is
**free** — no balance, no equilibrium — so it can go out on any round, including a round we
are attack-gated on. The debounce is the hyena's: a flipped pet keeps clawing every few
seconds and one order is enough, but re-engagement re-issues rather than giving up.

Note the *cause* differs from the hyena's. `falcon` has been on the seeded
`ataxiaBasher.ownDenizens` defaults from the start (`002_Check_For_Any_Missing_Variables:146`
— `{"falcon", "baalzadeen", "ashbeast", "hyena"}`), so the basher never targeted it; something
else flipped it (an AoE clipping it, or a tower effect). The fix is the same either way, which
is why the handler does not try to diagnose. See `infernal.md` for the flip side of that
substring match — the `hyena` keyword shielding a real denizen, and the `notOwnDenizens`
exemption list added in v4.7.169.

### Sword and Board refusal lines (v4.7.167)

SnB is the spec all the live Mnemosyne work was done on, and its `combination` has two hard
prerequisites the game enforces with flat refusals. Both were previously unhandled or handled
destructively — and a refusal costs a whole round, because the basher just re-queues the same
command next prompt.

```yaml
disarmed:
  line:    "You must be wielding both a sword and a shield to execute such an assault."
  trigger: "377_Sword_And_Shield_Lost.lua"
  fix:     "wield <sword>;wield shield;grip   (377:60-68, 5s debounce)"
  why: |
    THE DANGEROUS ONE: nothing in the KNIGHT bashing path re-wields -- basher/002 re-wields
    only for Bard (:332,:349, the lyre swap) and Jester (:840), and the `wield ...;grip`
    recovery prefix lives in the PvP aliases (2h/001_Hew, 146_Devastate, dwc_runie/006:20),
    never in the RW bash. So once something knocks a weapon loose EVERY
    subsequent round is refused and the failure persists FOREVER -- unlike the broken-arms
    refusal, which at least heals itself as the limb does. GRIP is re-asserted in the
    same breath because it is the defence that resists the disarm in the first place;
    re-wielding without re-gripping just queues up the next disarm. WIELD costs no balance,
    so the recovery rides any round.
    Sent DIRECTLY, not queued -- the basher rebuilds with `queue addclearfull` every prompt,
    which would wipe a queued recovery before it ran (the same reasoning as the pet passive
    orders, triggers 372/376). The sword uses the configured `longsword` slot via
    ataxia.getWeapon, which falls back to the literal "longsword" (022_User_Config:75,81);
    plain "shield" is the idiom already used at login (login/001:138,180).

both_arms_broken:
  line:    "You cannot do that because both of your arms must be whole and unbound."
  trigger: "344_Broken_Arms.lua"
  fix:     "roll back the in-flight replay on every owned rotation (344:61-64)"
  why: |
    SnB combination needs both arms whole and unbound, which makes THE ARMS the limbs that
    gate the entire offence -- and the iron malagma in the tower has TWO arm attacks (the
    pick to the arm, the vice-like bone-snap) against ONE head attack, so a Mnemosyne sweep
    pressures exactly the limbs that switch us off. That is why its parry prediction is
    parked on an arm: self_limb_tracking/005_Denizen_Parry_Patterns.lua:53-66, `fixed` and
    not `cycle` because neither arm line names a SIDE, so an unsynchronised cycle would
    guard the wrong arm half the time. Covering one arm halves the rate at which BOTH break,
    which is the only state that matters here.
    The line is authoritative: "the round we just queued did NOT execute". The rotations stamp
    their cooldown at SEND time and hold the pick for replay, so a refused round would
    otherwise burn a client-side cooldown on an ability that never fired AND keep replaying
    a command the game will refuse again. Same treatment 329 gives the "must wait" rejection.
    The battlerage is a SEPARATE command in the same queued chain and is not necessarily
    lost -- collide/onslaught need no arms. Only the weapon swing dies.
    PRIOR BEHAVIOUR, now deleted: this trigger fired an unthrottled `diag`. Nothing in the
    package parses our own DIAGNOSE output, so the sole effect was six lines of console spam
    at the worst possible moment -- three times in 0.8s in the live log.

both_legs_hindered:
  line:    "Both of your legs must be free and unhindered to do that."
  trigger: "345_Broken_Legs_Block.lua"
  fix:     "same rotation rollback, plus M._disarmMove() (345:60-71)"
  why: |
    Also unhandled before v4.7.167. Its expensive victim is not a swing but LEAP: the
    Mnemosyne swarm module moves with `stand;leap <dir>` (mnemosyne/009_Swarm_Tactics.lua:236
    low-HP retreat, :258/:266 the wall-escape decorator, :385 the re-entry), and a refusal was
    SILENT to that machinery -- the move sat "in flight" until the tactical arm's timeout
    expired, stalling the low-HP escape ladder at the moment it was holding us alive.
    One broken leg does not trip this; Achaea lets you stand and walk on one. The refusal
    means BOTH -- which is also exactly when the swarm most needs to move.
```

## Fighting Against This Class
```yaml
priority_cures:
  - paralysis: "Prevents tree, allows them to continue attacking"
  - weariness: "Restores your Fitness if you have it"
  - broken_limbs: "Prevent disembowel setup"

dangerous_abilities:
  - disembowel: "Instant kill if limbs broken"
  - impale: "Locks you in place (SnB)"
  - runes: "Room control and utility"

avoid:
  - "Letting both legs get broken"
  - "Being prone with broken limbs"
  - "Ignoring limb damage"
  - "Standing on sketched runes (algiz, lagul, wunjo)"

recommended_strategy: |
  Focus on keeping limbs healthy with restoration/mending.
  Parry legs to slow their prep.
  If they're 2H spec, watch for high damage and passive para cure.
  If they're DWC spec, prioritize curing venoms quickly.
  Be aware of runes on the ground - they provide room control.
  Watch for dagaz (the passive heal - cures one aff on a ~12s timer), thurisaz
  (line-of-sight damage) and sowulu (damage/splash). NOTE: this file previously said
  "sowulu (healing) and thurisaz (defense)" - wrong on both counts; the authoritative
  rune->effect table is 740_Rune_Found.lua:45-65 (sowulu = "damage", thurisaz =
  "LoS damage", dagaz = "cures affs").
```

## Limb Tracking
```yaml
# Uses lb[target].hits["limb"] format for limb damage tracking
# NOT tLimbs - use Romaen's limb counter format

access_pattern:
  left_leg: 'lb[target].hits["left leg"]'
  right_leg: 'lb[target].hits["right leg"]'
  left_arm: 'lb[target].hits["left arm"]'
  right_arm: 'lb[target].hits["right arm"]'
  head: 'lb[target].hits["head"]'
  torso: 'lb[target].hits["torso"]'

# dwbRunie thresholds (config, dwb_runie:65-68,179-183)
break_levels:
  prep:    "prepThreshold 99.9 — isPrepped: one/two whirl hits would reach this (not yet broken)"
  break:   "breakThreshold 100 — isBroken: damage >= 100 OR the 'damaged<limb>' aff"
  mangled: "200 — isMangled: damage >= 200 (or 'concussion' aff for head)"

pulp_check: |
  hasAff("prone")
  AND ( isMangled("head")  -- head >= 200% or concussion aff
        OR ataxiaTemp.fractures.skullfractures >= 5 )  -- config.skullFracturesForPulp
  → dismount;pulp <target>

bisect_check: |
  ataxiaTemp.lastAssess <= 34  -- config.bisectThreshold
  AND not hasAff("shield")
  → wield bastard;bisect <target>
```

## Implementation Notes
```
Triggers to watch for:
- "You have been impaled" - need to writhe
- "Your * is damaged/broken/mangled" - track limb state
- Venom messages for DWC tracking
- "sketches a rune" - rune being placed
- Rune activation messages

GMCP considerations:
- Track gmcp.Char.Vitals for limb percentages if available
- lb[target].hits["limb"] - enemy limb damage tracking
- Room items may include runes

Edge cases:
- 2H spec cures paralysis passively when attacking
- SnB has shield bash that can give random afflictions
- Runes persist until triggered or erased
- Some runes affect movement/positioning
```
