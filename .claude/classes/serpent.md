# Serpent

## Metadata
- **Type**: Base Class
- **Combat Style**: Affliction
- **Difficulty**: Hard
- **Lock Affliction**: Weariness (blocks Fitness passive cure)

## Skills
```
Subterfuge: Stealth, assassination, and utility abilities
Venom: Knowledge and application of toxins, and Ekanelia (venom reactions)
Hypnosis: Mental manipulation through suggestions (including Impulse)
```

## Confidence on this page

- **WIKI**: the Achaea wiki as filed in `kb/raw/wiki/` and generated into `kb/classes/serpent.md`.
  An in-game `AB` wins where they differ. No Serpent AB is filed in `kb/raw/ab/` (it holds only
  DIAGNOSE); the ABs cited in the PvE sections were pasted in chat.
- **CONFIRMED**: game text in `kb/raw/`: AFFLICTION SHOW and WHATCURES records, HELP files, combat logs.
- **PLAYER**: the notes relayed on 2026-10-12 (`kb/raw/players/serpent-2026-10-12.txt`).
- **UNVERIFIED**: nothing in `kb/raw` supports it yet.

There is no Serpent fight log in `kb/raw/logs/` yet. So how a Serpent's own commands behave is
WIKI, PLAYER or UNVERIFIED, and the lines our offense triggers read (dstab, bite, reaction,
impulse, relapse, snap) are code only: none of them is captured in `kb/raw` (grepped 2026-10-12).
One fight recorded with `fightlog` (v4.7.418, millisecond stamps) would settle most of the open
items on this page.

Code anchors are `src_new/scripts/levi_ataxia/levi/levi_scripts/serpent/002_Serpent_Offense.lua`
(written `:<line>` below) unless another file is named, as of v4.7.419.

---

## Offense Modes & Aliases (002_Serpent_Offense.lua)

```yaml
# The everyday keys are class-shared aliases. On a Serpent each sets a mode, then attacks once.
shared_aliases:
  zz:  "serp_setmode_lock(); serp_ekanelia_offense()       # 152_First_Attack_(All_Classes).lua:45-47"
  vv:  "serp_setmode_darkshade(); serp_ekanelia_offense()  # 153_Fourth_Attack_(All_Classes).lua:19-21"
  sr:  "serp_setmode_group(); serp_ekanelia_offense()      # 154_Group_(All_Classes).lua:32-34"
  srr: "serp_setmode_scytherus(); serp_ekanelia_offense()  # 157_Scytherus_(All_Classes).lua:14-16"

# The offense's own aliases (tempAlias, :2684-2696)
aliases:
  ek:          "serp_ekanelia_offense()  # fire one attack round in the current mode"
  ekauto:      "auto mode (the default: serpOffenseMode = 'auto', :83)"
  eklock:      "lock mode"
  ekgroup:     "group mode"
  ekdark:      "darkshade mode"
  ekscyth:     "scytherus mode"
  ekbite:      "bitepayload mode"
  ekhyp:       "hypnosis mode"
  ekhl:        "hypnolock mode"
  ekstatus:    "serp_status()"
  ekhypstatus: "serpent.hypnosis.status()"

# Eight strategy modes drive selection
modes: [auto, lock, group, darkshade, scytherus, bitepayload, hypnosis, hypnolock]

# One round: serp_ekanelia_offense (:2204) maps the mode to a strategy (auto: determineStrategy,
# :1237; the other modes inline, :2264-2351), selectVenoms (:1367) picks the DSTAB venoms, and
# serp_ekanelia_attack (:1670) builds the command. It dispatches only with balance, and only once
# per balance (attackInFlight, cleared on the balance-regained edge, :2208-2215, :2661-2670).

# Every round goes out as ONE `queue addclear freestand` entry (serp_sendAttack, :2150-2198):
purge:      "purge  # residual venom cleared first (:2181-2182)"
adder_pet:  "order adder kill <target>  (:2178-2179). The wiki's Snake ability summons a different snake per city (Mhaldor: adders); the command always says adder"

# Round-1 opener (buildOpener, :2115-2142), once per target
opener:
  dispel:       "dispel <target>  (first attack on each target, :2190-2194)"
  useOpener:    "master toggle (default on, :141)"
  useBowOpener: "remove bow; wield bow; pinshot <target> foot; wield shield dirk (default on, :142). The code's comment says PINSHOT needs a body part (:2121); the wiki's syntax is `PINSHOT <target>` (UNVERIFIED either way)"
  useSigils:    "drop incandescent sigil; attach monolith sigil to incandescent sigil (default off, :146)"

# Per-round denial (config useExitBlock, default off, :145)
exit_block: "sends `block <dir>` on its own, unqueued, for an exit not blocked in the last 5 s (nextExitToBlock :2093-2106; :2164-2176)"
```

### Class-Aware Venom Routing (CLASS_LOCK_VENOM, :765-783)
pickVenom sends curare while paralysis is missing (:823). Once paralysis is up, the next venom is
the target class's lock venom, when its affliction is missing (:825-834):

| Target class | First lock venom | Blocks |
|--------------|------------------|--------|
| apostate, pariah | voyria | sip-based healing/plagues |
| monk, shikudo, tekura | vernalius | weariness → Fitness |
| magi, sylvan | notechis | haemophilia → blood/passive cures |
| infernal, paladin, runewarden, unnamable, blademaster | xentio | clumsiness → parry+stance |
| psion, alchemist | aconite | stupidity → weave queue / transmute |
| depthswalker | eurypteria | recklessness → shadow cures |
| druid, sentinel | kalmia | asthma → smoke + morph |

Class comes from `classDetect.state.attackerClass` (fallback `tarClass`; getClassLockAff,
:785-793); unknown class → standard priority.

**Notechis may not ride a DSTAB.** The wiki says notechis "can not be used to envenom a weapon"
(`kb/raw/wiki/Venom.wiki:302`), and DSTAB delivers the venoms on a dirk. Our routing sends it by
DSTAB against Magi and Sylvan (above), in `ginseng_pressure` (:1564) and as the haemophilia piece
of `lock_reinforce` (AFF_TO_VENOM, :198). UNVERIFIED in game; if the game refuses it, notechis has
to be bitten.

### Advanced Mid-Fight Behaviors
```yaml
lock_reinforce_burst: |
  Lock, darkshade and bitepayload modes at truelock until a voyria impulse has gone out, and
  lock/darkshade at hardlock once impatience was delivered (:2268-2276, :2302-2309, :2332-2337).
  selectVenoms (:1500-1550): curare while paralysis is missing (with the class lock venom, else
  voyria) -> voyria (+eurypteria for recklessness) -> vardrax + euphorbia (addiction + nausea).
  PRIORITY 7 (:1900-1914) impulses scytherus once addiction + nausea are up (camus, by our
  reaction table), or voyria (with a vertigo suggestion when vertigo is missing) once anorexia +
  impatience are up; that marks voyriaSent and hands over to the finish strategy.

relapse_lock: |
  Lock and darkshade modes only, from the moment serpent.state.impatienceDelivered is set
  (trigger 016, on our monkshood reaction) until hardlock (:2255-2281, :2308-2311).
  selectVenoms (:1485-1498) pre-loads gecko + slike once asthma + weariness are up and neither
  slickness nor anorexia is. PRIORITY 7 (:1916-1926) runs selectRelapseImpulse (:991-1023): the
  monkshood pair again when slickness + anorexia are up and impatience is not (the impatience
  check is v4.7.419), else ONE stupidity impulse per relapse phase. Nothing here is timed to
  fratricide: the only fratricide clock is the 2.25 s window inside selectImpulse (see
  Fratricide Mechanics), and the stupidity impulse does not go through selectImpulse. (This
  entry said "timed to the fratricide ~3s relapse window" until v4.7.419.)

bitepayload_ladder: |
  selectBiteVenom (:1051-1097) picks the bite in bitepayload mode (PRIORITY 6, :1881-1887) and,
  in every mode, the venom the rebounding pre-empt's impulse carries (:1806-1807, falling back
  to pickVenom). It returns nil while sileris/fangbarrier is up (:1052). Priority: scytherus
  (camus loop) -> the monkshood reaction (asthma + masochism + weariness, and since v4.7.419
  only while impatience is missing) -> the kalmia, curare, loki and aconite reactions ->
  curare / kalmia / vernalius for a missing lock piece. A BITE costs 4.00 s of balance (WIKI)
  against DSTAB's 2.80 s.

rebounding_reapply_preempt: |
  When the target's rebounding drops, the clock is stamped (:1683-1689); 8.15 s later one
  `impulse <target> <suggestion> <bite venom>` goes out if the bite can land (:1795-1812). The
  code assumes rebounding returns about 8.5 s after it is stripped (comment, :1796); no capture
  says so. Since v4.7.419 the clock is getEpoch (see "What the offense records").

gecko_strip: |
  When the target's sileris/fangbarrier blocks the bite and the monkshood pair is the impulse we
  want, the round DSTABs gecko + another venom once (geckoStripAttempted), and the round after
  it sends curare + slike if impatience landed (postGeckoLockdown) (:1965-1982, :1372-1383).
  It never runs in scytherus mode or relapse_lock (:1970-1971); scytherus mode's own block for
  a blocked bite only echoes (:1984-1989).
  Slickness does strip the coating: CONFIRMED twice ("The protective covering coating your skin
  sloughs off." right after slickness lands: kb/raw/logs/2026-10-11_mystor_shikudo-vs-depthswalker_loss_EveP2TVe.txt:771,
  2026-10-11_mystor_shikudo-vs-infernal-dwc_win_c.iJVmpL.txt:873). A bare FLAY <target> strips
  it too (HELP 13.7, WIKI), but the offense never sends a bare flay. (This entry said "NOT
  flay"; that is true of our code, not of the game.)

cure_tracking: |
  serpent.trackCure (:1208-1231) counts the target's ginseng, bloodroot and focus cures in a 6 s
  window (ginseng only while a kelp affliction is up). Nothing passes "kelp" (the callers are
  399_Focus_(known), herbs/005_Bloodroot_TEST and herbs/007_Ginseng), so kelpCures stays 0.
  More than 2 ginseng cures with a ginseng stack under 3 switches auto mode to ginseng_pressure
  (:1314-1322); darkshade mode switches on the first one (:2295-2299).

execute_safety: |
  serp_ekanelia_offense recomputes the locks at graded confidence (:2239-2250): softlock = 3 of
  anorexia/asthma/slickness/bloodfire at 0.70; hardlock = that + impatience or sandfever at
  0.70; truelock = that + paralysis at 0.90 (haveAff_locked / haveAff_tactical, :99-106).
  EXECUTE also needs getStateProbabilityV3 of the five lock afflictions >= 0.90 (:1782-1790).
  See the Finisher for what the wiki says EXECUTE itself needs.
```

### What the offense records on the target (v4.7.419)
```yaml
dstab:    "serpent/001_Doublestab: on our dstab line, tarAffed for the two venoms we SENT (envenomList[1], envenomListTwo[1])"
bite:     "serpent/009_Bite: tarAffed(venom_to_aff(venom)) for the venom named in our bite line (not loki or camus)"
reaction: |
  serpent/016_Ekanelia_Success, since v4.7.419: tarAffed(serpent.EKANELIA_RESULTS[venom])
  (:525-532): monkshood impatience, kalmia slickness, loki nausea + paralysis, curare
  hypochondria, aconite paranoia, voyria confusion + disrupted; nothing for scytherus (camus is
  damage). On monkshood it also stamps the 2.5 s impatience cooldown (stampImpatienceCooldown,
  :646-648, which nothing called before) and sets serpent.state.impatienceDelivered. Before
  v4.7.419 it recorded nothing, so our own impatience reached the tracker only if the target
  printed the boredom line (414_Impatience_1), and PRIORITY 4, PRIORITY 7 and selectBiteVenom
  kept re-sending monkshood after it had worked.
impulse:    "serpent/017_Impulse_Suggestion: tarAffed(suggestion)"
relapse:    "serpent/018_Impulse_Relapse: tarAffed(suggestion) again"
fratricide: "tarAffed('fratricide') at the snap, if the fratricide suggestion was given (onSnapped, :267-284); erAff in onFratricideCured (:304-310). See Fratricide Mechanics"
timers: |
  Since v4.7.419 the offense's own timers (the 2.5 s impatience cooldown, the 2.25 s fratricide
  window and the 8.15 s rebounding pre-empt) run on getEpoch (now(), :574-581). They ran on
  os.clock, which Lua 5.1 defines as CPU time: wall time only under Windows' C runtime, so on
  Linux and macOS they ran many times slower than real time.
lines: "Every pattern above is our code's. None of these lines is captured in kb/raw."
tests: "src_new/tests/test_serpent_notes.lua (36 tests, v4.7.419)"
```

---

## Notes relayed 2026-10-12

**Source:** `kb/raw/players/serpent-2026-10-12.txt`, relayed by the user; its author was not named.
Tag: PLAYER. Each claim was checked against the game data in `kb/raw` and against the code as of
v4.7.419.

| Relayed claim | Game data | Status | Our code now |
|---|---|---|---|
| "dstab is the fastest 2venoms in the game" | DSTAB 2.80 s of balance (WIKI). A Druid wyvern's FRENZY gives two venoms in 2.20 s (WIKI); a knight's DSL runs 2.0-2.4 s in our logs | Contradicted on the data we hold; true within the Serpent kit | DSTAB is already the default attack |
| "hypochondria afflicts impatience after 10 seconds" | One log shows hypochondria giving impatience on its own; the game's record gives no time | Effect CONFIRMED (one log); 10 s UNVERIFIED | Defence cures it early (prioaff, v4.7.419); the offense does not plan around it |
| `impulse masochism monkshood` "now exists" and gives impatience with asthma + weariness | The wiki's IMPULSE takes no venom; masochism is a trivial suggestion; the reaction list was never captured | UNVERIFIED (the venom form and the reaction) | Already sent, with the target, from several paths |
| fratricide makes impulses (mentals only) relapse "at 2.25s" | "causes hypnotic impulses to relapse a short time after being first introduced" | Effect CONFIRMED; 2.25 s UNVERIFIED | Window 3.0 s -> 2.25 s (v4.7.419) |
| "three sources of relapsing effects" | Two Serpent sources in the game data: scytherus and fratricide | Third not identified | -- |

### 1. DSTAB, "the fastest two venoms in the game"

- **Game data (WIKI).** `DOUBLESTAB/DSTAB <target> [venom1 venom2]`, 2.80 s of balance, adventurers
  only: "If you are wielding a dirk that has been envenomed with more than one venom, you may use
  this ability to quickly deliver two venoms simultaneously to your target." Transcretion lets a
  Serpent "secrete venoms directly onto edged weapons". No Ekanelia reaction fires from it: "only
  the fangs of the serpent are sufficient for this purpose" (Venom, Ekanelia).
- **Against the claim.** On the wiki figures we hold, a Druid wyvern's FRENZY gives a sting venom
  and a claw venom in 2.20 s of balance (`kb/classes/druid.md`, Frenzy; the sting is limited to
  darkshade, vardrax, euphorbia or sumac, and the claw needs a vial on hand). A knight's DSL is
  "Balance cost varies based on weapon speed" (`kb/classes/infernal.md`, Duality) and ran about
  2.0-2.4 s in Mystor's Infernal logs (`kb/combat/fights/2026-10-11_mystor_shikudo-vs-infernal-dwc_win_FceAmb0o.md`,
  `..._vNTjvghY.md`). Hydra FUROR (2.00 s) and Sentinel DOUBLESTRIKE carry one venom each. Within
  the Serpent kit the claim holds: BITE is 4.00 s for one venom.
- **Unverified.** The 2.80 s is wiki only (no `AB DOUBLESTAB`), and the wiki may predate a rebalance.
- **Our code.** DSTAB is the default attack (`attackMode = "dstab"`, :85; header :21-24). The normal
  round is `wield shield dirk;dstab <target> <v1> <v2>` (:2029-2035).
- **Settle.** `AB DOUBLESTAB` in game, and a Serpent's DSTAB cadence timed in a `fightlog` recording.

### 2. Hypochondria's delayed impatience

- **Game data.** The record says nothing about it: "Hypochondriacs often think they are suffering
  from afflictions they do not have." Cure: Eat Lobelia / Eat Argentum
  (`kb/raw/live/affliction_show/hypochondria.txt`).
- **It happens (CONFIRMED, one log).** In `kb/raw/logs/2026-10-11_mystor_shikudo-vs-depthswalker_loss_EveP2TVe.txt`,
  hypochondria lands at 20:17:44 (774-775, "A terrible sense of unease comes over you."), lethargy
  between 20:17:46 and 20:17:47 (879), and impatience at 20:17:49 (945-946, "You shuffle your feet
  noisily, suddenly bored."), with no attacker line before either. The order nausea -> lethargy ->
  impatience is credited to Classleads #154 (31 July 2025) in `.claude/classes/depthswalker.md`;
  that text is not in `kb/raw`, so it is second-hand.
- **The 10 s is UNVERIFIED.** The log's stamps are whole seconds. Counted from the latest
  hypochondria, the impatience came about 5 s later. An earlier hypochondria landed at 20:17:39
  (575) and was cured a second later (598-600, "You eat an argentum flake."); counted from that one,
  the gap is about 10 s, which would mean the clock survived the cure. One log cannot tell the two
  apart. The victim also already had nausea, the first symptom, which may have shortened the chain.
- **Also unverified:** whether curing hypochondria inside the window stops the impatience.
- **How a Serpent gives it.** Hypochondria is a COMPLEX suggestion (`kb/raw/wiki/Hypnosis.wiki:353`),
  so it comes through HYPNOTISE / SUGGEST / SEAL / SNAP, not IMPULSE. Our reaction table also gives
  it from curare (hypersomnia + masochism), which no game data confirms.
- **Our code, offense.** The offense gives hypochondria two ways: it is the first of hypnolock's
  three complex suggestions (selectHypnoLockSuggestions, :438-448), and it is our curare reaction's
  result (picked by selectBiteVenom :1076-1078 and selectOpportunisticEkanelia :972-976; trigger 016
  records it since v4.7.419). It reads it twice: as a PRIORITY 4 "third condition" for the
  monkshood impulse (impatienceConditionsMet, :672), and as one of the four mentals the focus-lock
  push counts (MENTAL_AFFS, :711-716, for focusLockReady, :726-733). It does not wait for the free
  impatience, as the Depthswalker offense does (`depthswalker.selectInstillLock`, `depthswalker/015_CC_Depthswalker.lua:519`).
  Nothing models the delay: `017_Affliction_Management.lua` has no hypochondria clock, and the
  boredom-line trigger (`414_Impatience_1`) records impatience alone, deliberately without
  back-filling hypochondria.
- **Our code, defence.** Hypochondria is priority 5 (`ataxia/001_Default_Curing_Prios.lua:223`;
  row 5 of the live normal set). hypoImp (on by default) raises it to 1 and impatience to 4 when
  lethargy, nausea or addiction is up too (`algedonic_defense_1.0/001_Anti_Priorities.lua:167-174`).
  Since v4.7.419 `Algedonic.AntiSerpent` sends `curing prioaff hypochondria` while it is up and
  paralysis is not (:741-744 of that file), the branch AntiDepthswalker already had (:427-428).
- **Settle.** A `fightlog` recording of hypochondria on someone without nausea, left uncured; then
  one cured within a couple of seconds, to see whether the impatience still comes.

### 3. IMPULSE MASOCHISM MONKSHOOD

- **Game data (WIKI).** `IMPULSE <target> <suggestion>`, 1.70 s of equilibrium: "you may inflict
  them with one of the trivial suggestions(*) that are known to you" (`kb/raw/wiki/Hypnosis.wiki:43-50`).
  No venom argument, no stated requirement. The wiki does list the trivial suggestions
  (Hypnosis.wiki:86-251): amnesia, paranoia, loneliness, claustrophobia, stuttering, hallucinations,
  dementia, deadening, epilepsy, agoraphobia, **masochism**, recklessness, vertigo, confusion and
  stupidity, exactly our TRIVIAL_SUGGESTIONS (:156-160). So IMPULSE can give masochism. The complex
  suggestions (Hypnosis.wiki:252 onward: clumsiness, addiction, pacifism, hypersomnia, lethargy,
  anorexia, disrupt, generosity, action, hypochondria) need the full hypnosis. **Impatience is no
  suggestion at all.**
- Monkshood gives disloyalty (WIKI; AFFLICTION SHOW disloyalty: Smoke Valerian / Smoke Realgar;
  "disfigurement" is its old name, `kb/CONFLICTS.md`).
- Ekanelia (WIKI, Venom.wiki:383-391): a reaction has a trigger venom ("this is what you bite
  with"), conditionals, a result, and sometimes a bonus conditional and bonus result; "** Reactions
  fire on the bite command." The game's list of reactions (`EKANELIA`, `EKANELIA STUDY <reaction>`)
  has never been captured.
- **What the notes add (PLAYER).** IMPULSE now takes a venom as well, and `impulse masochism
  monkshood` gives masochism (the impulse), disloyalty (the venom) and, if the target has asthma
  and weariness, impatience. That matches our own reaction table (monkshood: asthma + masochism +
  weariness -> impatience, :459-466): the impulse brings its own masochism, so only asthma +
  weariness must already be up.
- **Unverified.** The venom form itself; what it costs (the header says "BAL+EQ", :25: the wiki's
  equilibrium for the impulse, plus a bite's balance?); whether fangbarrier blocks it (our code
  assumes so); whether impatience is the reaction's result or its bonus result. The relayed form
  leaves out `<target>`, which the wiki requires; our sends include it.
- **Our code.** It already sends `impulse <target> masochism monkshood`:
  - PRIORITY 4 (:1829-1854): asthma + weariness plus one "third condition" (fratricide,
    hypochondria, scytherus, slickness, or anorexia with focus down; impatienceConditionsMet,
    :666-676), or asthma + weariness alone in relapse_lock (impatienceConditionsRelapse, :679-684),
    and not inside the 2.5 s impatience cooldown. The third condition is our choice, not the game's
    (comment, :663).
  - PRIORITY 7's normal branch (:1949-1962) sends the same pair on asthma + weariness alone, through
    selectImpulsePair (:902-933).
  - The shield-break flay chains it on equilibrium (:1745-1755), and relapse_lock re-sends it once
    slickness + anorexia are up (selectRelapseImpulse, :997-1002).
  - With masochism already up it impulses another suggestion on the same venom (:1845-1849).
  - v4.7.419: every monkshood send now calls checkImpulseEligible (sileris/fangbarrier). Three did
    not (shield-break :1745-1746, PRIORITY 4 :1842-1843, PRIORITY 5 :1860), so with fangbarrier up
    the round sent a blocked impulse every round and never reached the gecko strip. (Scytherus
    mode's impulse still does not check it: see Impulse Mechanics.)
  - v4.7.419: monkshood is no longer sent FOR impatience onto a target that already has it
    (selectBiteVenom step 3, :1066-1067; selectRelapseImpulse, :997). PRIORITY 5 still carries its
    mental impulse on monkshood and requires impatience (focusLockReady, :726-733), so the
    reaction's impatience is wasted there; that is left as it is.
  - v4.7.419: the keybind suggestion override no longer replaces the masochism the reaction needs
    (reactionNeeds, :537-547).
- **Defence.** Since the impulse brings the masochism, curing masochism beforehand does not stop
  this route; it still stops a plain BITE monkshood. The conditionals a victim can deny in advance
  are asthma and weariness: astWear (on by default) raises asthma to 3 against a Serpent target
  when both are up (`algedonic_defense_1.0/001_Anti_Priorities.lua:190-195`).
- **Settle.** `AB HYPNOSIS IMPULSE` (syntax and cost) and `EKANELIA STUDY MONKSHOOD` in game, and a
  `fightlog` recording of our own `impulse <target> masochism monkshood` to read the reaction line.

### 4. Fratricide's 2.25 s relapse

- **Game data (CONFIRMED, AFFLICTION SHOW).** "Grants major negative poison resist and causes
  hypnotic impulses to relapse a short time after being first introduced." Cure: Eat Lobelia / Eat
  Argentum. The full record is under Fratricide Mechanics.
- **"Mentals only".** The record says "hypnotic impulses", i.e. the suggestion half, which is all
  mental. So the masochism from `impulse ... masochism monkshood` should relapse; whether the
  reaction's impatience does is not stated, since it comes from the venom, not the suggestion.
- **2.25 s is UNVERIFIED.** The record says "a short time". It times the relapse from when the
  impulse is first introduced, not from a cure. It does not say how many times the impulse
  relapses. Our reading (UNVERIFIED): once, shortly after the impulse lands, not after every
  cure, which this page described until v4.7.419. Knight flail expends use the same "after they
  are first given" wording and add "striking for a second time"; the fratricide record has no
  such clause.
- **Our code.** `FRATRICIDE_RELAPSE = 2.25` (:583-589; it was 3.0, from no stated source).
  selectImpulse will not re-impulse an affliction it sent less than 2.25 s ago while fratricide is
  believed up (:598-614), since the relapse is about to bring it back; a second pass ignores the
  window rather than return nothing. The window runs from our SEND (recordImpulse, :628-632), while
  the game counts from landing, so 2.25 s plus our latency is the matching figure. The tracker
  follows the relapse itself, not a clock: trigger 018 re-records the affliction on its relapse line.
- **Settle.** A `fightlog` recording of us impulsing under fratricide: the gap between 017's line
  and 018's line for the same suggestion.

### 5. "Three sources of relapsing effects"

| Source | Game data | Serpent's? |
|---|---|---|
| Scytherus ("Thin blood") | "Scytherus causes any venoms you get affected by to relapse after a short delay." Cure: Eat Ginseng / Eat Ferrum (`kb/raw/live/affliction_show/scytherus.txt`) | Yes: SECRETE SCYTHERUS / BITE (WIKI) |
| Fratricide | "causes hypnotic impulses to relapse a short time after being first introduced" | Yes by its effect; how it is given is unknown (Fratricide Mechanics) |
| (third) | Not found in the game data. Candidates: hypochondria's delayed symptoms (one log; the game never calls them a relapse); our reaction table's scytherus -> camus (code only); the Toxicologist boon (PvE, Mnemosyne only) | -- |

Not Serpent, listed so they are not confused with these: Shaman SYVIS, "causing diseases that your
victim believes they have cured to relapse shortly there after" (`kb/raw/wiki/Spiritlore.wiki:148`);
knight flail expends, "relapse a short while after they are first given, striking for a second time"
(`kb/raw/wiki/Weaponmastery.wiki:288`); Pariah infest, "The plague your swarm is carrying will relapse
twice at a later time" (`kb/raw/wiki/Pestilence.wiki:130`).

**Our code:** trigger 018 records fratricide's impulse relapses on the target. Nothing in the
target tracker models scytherus's venom relapses.

---

## CRITICAL: Impulse Mechanics (checked 2026-10-12)

**Impulse is how a Serpent gives a trivial suggestion without hypnosis, and, with a venom (relayed
notes), how its main reaction, monkshood's impatience, is delivered.**

```yaml
impulse:
  game: "IMPULSE <target> <suggestion>, 1.70 s of equilibrium; one TRIVIAL suggestion; no venom argument and no stated requirement (WIKI, kb/raw/wiki/Hypnosis.wiki:43-50)"
  trivial_suggestions: [amnesia, paranoia, loneliness, claustrophobia, stuttering, hallucinations, dementia, deadening, epilepsy, agoraphobia, masochism, recklessness, vertigo, confusion, stupidity]  # WIKI, Hypnosis.wiki:86-251; = TRIVIAL_SUGGESTIONS (:156-160)
  complex_only: [clumsiness, addiction, pacifism, hypersomnia, lethargy, anorexia, disrupt, generosity, action, hypochondria]  # WIKI, Hypnosis.wiki:252 onward: full hypnosis only
  not_a_suggestion: "impatience (it comes from the monkshood REACTION), fratricide (see Fratricide Mechanics)"
  venom_form: "PLAYER, UNVERIFIED: `impulse masochism monkshood` (relayed notes). Our code sends `impulse <target> <suggestion> <venom>` on every impulse (:1755, :1810, :1825, :1852, :1864, :2017, :2044)"
  cost: "Wiki: 1.70 s of equilibrium. Code header: 'BAL+EQ' (:25). The venom half's cost is UNVERIFIED"

our_eligibility_rule: |
  checkImpulseEligible (:1108-1122) refuses an impulse while the target has sileris or
  fangbarrier. Since v4.7.419 every impulse path calls it except scytherus mode's (PRIORITY 7,
  :1935-1939). That branch runs when addiction + nausea are up and scytherus is not (the scytherus
  mode strategy, :2315-2325), and sends `impulse <target> <suggestion> scytherus` unchecked; the
  gecko strip skips scytherus mode too (:1970). So with fangbarrier up it sends, every round, an
  impulse the rest of the offense treats as blocked, and because the impulse replaces the DSTAB,
  scytherus_attack's gecko (its first venom when asthma is up and slickness is not, :1608-1617)
  never goes out to strip the barrier (open; not fixed in v4.7.419). Before v4.7.419 the three
  monkshood sends (shield-break :1745-1746, PRIORITY 4 :1842-1843, PRIORITY 5 :1860) did not
  check it either. The rule is ours: HELP 13.7 says the coating gives "protection
  against bites from adventurers of the Serpent class" (kb/raw/help/13.7_healing-and-curing.txt:78-81),
  and a reaction "fires on the bite command", so an impulse's venom is presumably bitten. No
  capture shows fangbarrier blocking IMPULSE.

asthma_weariness: |
  NOT an impulse gate. With masochism they are the monkshood reaction's conditionals, and that
  reaction is where the impatience comes from. `impulse <target> masochism monkshood` brings the
  masochism, so asthma + weariness are the only conditionals that must already be up (Notes
  relayed 2026-10-12, item 3).

impulse_afflictions:   # what IMPULSE gives directly: the trivial list above, notably (effects: AFFLICTION SHOW)
  - masochism: "the monkshood and curare reactions' conditional"
  - confusion: "'extends your equilibrium recovery rates by 100%'; with recklessness, the loki reaction's conditionals (and the voyria reaction's RESULT)"
  - stupidity: "'You may fumble some actions.'"
  - amnesia: "'makes you forget one action that you try to take'"
  - vertigo: "the voyria reaction's conditional (with anorexia + impatience)"
  - dementia, deadening: "the aconite reaction's conditionals; deadening also deepens a SEAL (WIKI)"
  - epilepsy, recklessness: "mental pressure; recklessness is the loki reaction's other conditional"
  # NOT impatience (no suggestion) and NOT anorexia (a complex suggestion; slike gives it)

note: "Impatience is no suggestion, so neither SNAP nor IMPULSE gives it directly; it comes from the monkshood reaction (the old impSnap swap was removed: swaps/002_Priority_Management.lua:22)"

counter_impulse:
  - "Keep fangbarrier up: it stops bites (HELP 13.7). Slickness strips it (two logs) and so does a bare FLAY (HELP 13.7, WIKI)"
  - "Deny asthma or weariness (both kelp: one cure per eat). astWear raises asthma to 3 against a Serpent target when both are up"
  - "Curing masochism in advance does NOT stop the impulse route: the impulse brings it"
```

---

## Fratricide Mechanics

```yaml
fratricide:
  record: |
    CONFIRMED, AFFLICTION SHOW (kb/raw/live/affliction_show/fratricide.txt), and on the game's
    AFFLICTION LIST (kb/raw/live/affliction_list.txt:77):
      Description:   "Grants major negative poison resist and causes hypnotic impulses to relapse a short time after being first introduced."
      Cure(s):       Eat Lobelia / Eat Argentum   (also WHATCURES, kb/raw/live/whatcures.txt:53); NoRandomCure: No
      Diagnose:      "plagued by an insidious venom."
      Afflicted msg: "Something subtle and yet insidious overcomes you."
      Cured msg:     "You rid yourself of the insidious venom plaguing you."
    This page said the cure was "Argentum (pill)" until v4.7.419: it is lobelia, or an argentum
    flake (the eat line in our logs is "You eat an argentum flake.").

  how_given: |
    UNKNOWN. Fratricide is in no Hypnosis, Venom or Subterfuge page we hold, and not in either
    suggestion list. The game's own record calls it a VENOM ("an insidious venom"). Our code gives
    it as a SUGGESTION: hypnotise -> `suggest <target> fratricide` -> snap (fratricide mode,
    getCommand :361-369), which nothing in the game data supports, and which snaps without the
    SEAL the wiki puts before SNAP. Treat that route as UNVERIFIED. Settle with AB VENOM, AB
    HYPNOSIS and EKANELIA in game, or a log of a Serpent landing it.

  the_relapse: |
    Timed from when each impulse is FIRST INTRODUCED (game), not from a cure. The record gives no
    count. Our reading (UNVERIFIED): each impulse relapses once, shortly after it lands, and an
    affliction cured after that stays cured. It is not a loop that brings an affliction back
    after every cure, which is what this page described until v4.7.419 ("Fratricide causes
    impatience to RELAPSE immediately ... cannot escape"). Knight flail expends use the same
    timing words and state the count the fratricide record leaves out: "relapse a short while
    after they are first given, striking for a second time" (Weaponmastery.wiki:288).
    Timing: "a short time" (game); 2.25 s (relayed notes, PLAYER); our code used 3.0 s from no
    source and now uses 2.25 s.
    Scope: "hypnotic impulses" (game), the suggestion half; the notes say "mentals only". Whether
    the monkshood REACTION's impatience relapses is not stated: it comes from the venom.

  poison_resist: |
    "major negative poison resist": poison damage hits harder while it is up. Camus is "A more
    powerful version of Sumac poison" (WIKI), so a scytherus/camus Serpent gains from it. Not
    quantified.

  our_offense: |
    - The 2.25 s window: FRATRICIDE_RELAPSE (:583-589) in selectImpulse (:598-614), measured
      from our send (recordImpulse, :628-632), on getEpoch (:574-581).
    - On the tracker since v4.7.419: onSnapped calls tarAffed("fratricide") when the fratricide
      suggestion was given (:267-284), and onFratricideCured calls erAff (:304-310). Before,
      it wrote tAffs.fratricide directly, so haveAff("fratricide") read false and a lobelia eat
      could never take it off.
    - In V3 a herb eat takes fratricide only when nothing else that herb cures is there
      (herbCureLastV3 in onHerbCureV3, affliction_tracking_core/007_Branching_State_Tracker.lua:130-139,
      :406-420): it is 25, the bottom, in our priorities and the live normal set, and a list
      position cannot express "cured last". Without the rule, one eat over masochism + fratricide
      left masochism believed at 0.67, and the next monkshood impulse dropped the masochism its
      reaction needs.
    - The cure line we listen for, "The look of madness fades from (\w+)'s eyes" (a temp
      trigger registered at load, :2770-2778), is code only, does not check whose eyes, and does
      not match the game's own cured message above. The offense still ORs
      serpent.hypnosis.fratricideActive into its checks (selectImpulse, impatienceConditionsMet,
      focusLockReady). The snap sets it; only that line or a hypnosis reset clears it
      (serpent.hypnosis.reset, :317-321: a target change, a lost or noticed hypnosis, a "too
      perceptive" refusal, switching into a hypnosis or hypnolock mode; :2629-2632,
      :2789-2817, :2455-2459, :2473-2477).
    - It counts as a third condition for PRIORITY 4 (:670-671) and is required for the focus-lock
      push, PRIORITY 5 (focusLockReady, :726-733: fratricide + 4 mentals + focus down +
      impatience + asthma + weariness).

  our_defence: |
    - Priority 25, the bottom (ataxia/001_Default_Curing_Prios.lua:280; row 25 of the live
      normal set, kb/raw/live/curing-priority-list_normal_2026-10-10.txt:33).
    - fratLock (on by default): fratricide -> 4 when fratricide + asthma + slickness are up
      (algedonic_defense_1.0/001_Anti_Priorities.lua:197-202, restored :306-312).
    - v4.7.419: Algedonic.AntiSerpent sends `curing prioaff fratricide` while fratricide and
      scytherus are up and paralysis is not (:746-752), the "cure fratricide at once when
      scytherus is up" rule. PRIOAFF writes no stored priority.
    - Against a detected Serpent, class detection switches to the in-game `serpent` curingset
      (class_detect/001_Class_Detect_Engine.lua:62, :202-215). That set exists
      (kb/raw/live/curingset-list_2026-10-10.txt:17) but its priority list was never captured, so
      the priority actually in force against a Serpent is unknown. fratLock's write and its
      restore land in whichever set is active, and the restore writes the normal table's 25.
```

---

## Affliction Stacking Strategy
```yaml
concept: |
  Affliction stacking is the technique of applying multiple afflictions
  that share the same cure herb/balance to overwhelm the target's curing.
  Since only ONE affliction per herb can be cured per eat balance, stacking
  2-3 afflictions on the same herb creates a "backlog" that takes multiple
  cures to clear.

kelp_stack:
  description: "Most common and powerful stack - sets up the monkshood reaction"
  afflictions: [asthma, clumsiness, sensitivity, weariness]
  critical_note: |
    Asthma + weariness are two of the monkshood reaction's three conditionals, and
    `impulse <target> masochism monkshood` brings the third, so with both up the impulse
    gives impatience (Notes relayed 2026-10-12). Both are kelp/aurum cures: one per eat.
    Clumsiness + weariness are the kalmia reaction's conditionals.
    This is the foundation of Serpent lock strategy.

ginseng_stack:
  description: "Damage-over-time stack"
  afflictions: [addiction, darkshade, haemophilia, lethargy, nausea, scytherus]
  strategy: |
    Stack darkshade + scytherus for pressure; scytherus also makes every later venom
    relapse ("Thin blood", AFFLICTION SHOW). Addiction + nausea set up our scytherus ->
    camus reaction. Add haemophilia to prevent clotting.

goldenseal_stack:
  description: "Mental affliction stack"
  afflictions: [dissonance, dizziness, epilepsy, impatience, stupidity]
  strategy: |
    Impatience blocks focus - critical for true lock. It comes from the monkshood
    REACTION, not from a suggestion (impatience is none) and not from SNAP. Epilepsy and
    stupidity are trivial suggestions, so IMPULSE gives them; aconite gives stupidity and
    larkspur dizziness.

bloodroot_stack:
  description: "Critical lock stack"
  afflictions: [paralysis, slickness]
  strategy: |
    Paralysis: Eat Bloodroot / Eat Magnesium. Slickness: the same, or Smoke Valerian /
    Smoke Realgar (AFFLICTION SHOW).
    Paralysis blocks the tree and active physical movement.
    Slickness blocks salves (can't cure anorexia with epidermal).
    When asthma is present, the victim can't smoke valerian for slickness.
    PRIORITIZE PARALYSIS when asthma blocks smoking.
```

## Kill Routes

### Primary Kill: Impulse Lock (Modern Serpent)
```yaml
type: affliction
summary: DSTAB lock venoms, the monkshood reaction for impatience, then a finisher
status: "ASSUMED: no Serpent fight log in kb/raw/logs; the pieces are WIKI, PLAYER and our code"

prerequisites:
  - "Asthma + weariness on the target: with the impulse's own masochism they fire the monkshood reaction (impatience)"
  - "No sileris/fangbarrier for the impulse or bite (HELP 13.7: the coating stops Serpent bites). DSTAB's weapon venoms are probably not stopped (inferred from a DSL, below)"
  - "Fratricide (optional): each impulse relapses shortly after it lands"

attack_sequence:   # inherited; this page called it "from combat log", but no Serpent log is in kb/raw
  phase_1_kelp_setup:
    - "DSTAB target kalmia vernalius"   # asthma + weariness (BOTH kelp cures)
    - "FLAY <target> SHIELD|REBOUNDING strips those; a bare FLAY <target> strips the sileris coating (HELP 13.7, WIKI). Our offense never sends a bare flay: it strips the coating with slickness (gecko), which works (CONFIRMED in two logs)"
    - "Weapon venoms land through a formed fangbarrier: an Infernal's DSL gave anorexia, then slickness stripped the coating (c.iJVmpL log, 863-873). Not seen for DSTAB itself"

  phase_2_impulse_delivery:
    - "impulse target masochism monkshood"  # masochism (impulse) + disloyalty (monkshood) + impatience (reaction)
    - "DSTAB slike once impatience is up (slikeGateMet, :799-804), or relapse_lock's gecko + slike pre-load"  # anorexia
    - "Fratricide, if up, makes each impulse relapse shortly after it lands (how it is given: unknown)"

  phase_3_lock_completion:
    - "DSTAB target curare gecko"       # paralysis + slickness (BOTH bloodroot)
    - "Target now in true lock"
    - "Finisher: EXECUTE / BEHEAD (below)"

example_rounds:   # ASSUMED (inherited, no log)
  round_1: "DSTAB kalmia vernalius → asthma + weariness"
  round_2: "Flay shield/rebounding if up (DSTAB works through a fangbarrier: inferred, not seen)"
  round_3: "impulse masochism monkshood → impatience, victim can't focus"
  round_4: "DSTAB curare gecko → paralysis + slickness"
  round_5: "DSTAB slike → anorexia, victim can't eat (this said 'impulse <suggestion> slike'; our offense sends slike by DSTAB)"
  result: "TRUE LOCK - victim cannot cure anything"

required_afflictions:
  - asthma: "Blocks smoking; a monkshood conditional (kelp cure)"
  - weariness: "Blocks Fitness; a monkshood conditional (kelp cure - competes with asthma!)"
  - slickness: "Blocks salves (bloodroot cure, or smoke when there is no asthma)"
  - paralysis: "Blocks the tree and physical movement (bloodroot cure - competes with slickness!)"
  - impatience: "Blocks focus. From the monkshood reaction, not a suggestion"
  - anorexia: "Blocks eating. From slike (venom); as a COMPLEX suggestion it cannot be impulsed"
  - fratricide: "Optional: impulses relapse shortly after they land (lobelia/argentum cure)"

cure_competition_insight: |
  KEY: Serpent exploits that bloodroot cures BOTH paralysis AND slickness.
  When asthma present, victim can't smoke valerian for slickness.
  So bloodroot must cure both para and slick - but only one per balance.
  DEFENSE: Prioritize paralysis when asthma blocks smoking!
```

### Alternative Kill: Hypnosis + Impulse Combo
```yaml
type: affliction
summary: Hypnosis for fratricide (an UNVERIFIED route), impulse for mental delivery

steps:
  1: "HYPNOTISE <target>"
  2: "SUGGEST <target> fratricide"     # UNVERIFIED: no such suggestion on the wiki, and the game's record calls fratricide an insidious venom
  3: "SNAP <target>"                   # our fratricide mode snaps without a SEAL; the wiki puts SEAL before SNAP
  4: "Apply asthma + weariness (kelp stack)"
  5: "impulse <target> masochism monkshood"  # impatience via the monkshood reaction; under fratricide the impulse relapses shortly after
  6: "Apply paralysis + slickness"
  7: "DSTAB slike (anorexia)"
  8: "Target locked"

key_insight: |
  Impatience is no suggestion (WIKI), so neither SNAP nor IMPULSE gives it directly; it
  comes from the monkshood reaction. IMPULSE gives TRIVIAL suggestions; the complex ones
  (anorexia, hypochondria, disrupt, ...) need the full HYPNOTISE / SUGGEST / SEAL / SNAP.
  Since 2026-10-23, SUGGEST and SEAL sent OFF balance take a fixed equilibrium, so a Serpent
  who puts them after a balance attack is slower; our offense puts them first.

hypnosis_only_afflictions:   # complex suggestions (WIKI, Hypnosis.wiki:252 onward)
  - disrupt: "Knocks the target off equilibrium briefly, or fully disrupts them if confusion is present"
  - hypochondria: "Gives impatience on its own seconds later (Notes relayed 2026-10-12)"
  - others: [clumsiness, addiction, pacifism, hypersomnia, lethargy, anorexia, generosity, action]
  - fratricide: "NOT a suggestion in the wiki; our code's route only (UNVERIFIED)"

impulse_delivered_afflictions:   # the trivial suggestions (WIKI, Hypnosis.wiki:86-251)
  - [amnesia, paranoia, loneliness, claustrophobia, stuttering, hallucinations, dementia, deadening, epilepsy, agoraphobia, masochism, recklessness, vertigo, confusion, stupidity]

notes: |
  Our code waits 4 s after the hypnotised line before it snaps (SNAP_DELAY, :152; onHypnotised,
  :231-250). WIKI: a trance is sealed for 3 s or more (1 s if the victim has deadening), then
  the suggestions tick every 4 s (every 3 s with deadening).
```

### Alternative Kill: Darkshade/Scytherus Damage
```yaml
type: damage
summary: Stack damage-over-time afflictions for passive damage kill

steps:
  1: "Apply darkshade (damage over time)"
  2: "Apply scytherus (every later venom relapses)"
  3: "Apply sensitivity (increases damage taken)"
  4: "Continue venom pressure while DoTs tick"
  5: "Target dies to accumulated damage"

required_afflictions:
  - darkshade: "'Darkshade makes even the lightest ray of sunlight extremely painful. Stay outside too long and you will surely die.' (AFFLICTION SHOW). Our code's kill clock: 26 s stuck (DARKSHADE_KILL_TIME, :150). A lightwall 'drastically speeds up the progression' (WIKI)"
  - scytherus: "'Thin blood': venoms relapse after a short delay (AFFLICTION SHOW). Our code adds the scytherus -> camus reaction for damage (code only)"
  - sensitivity: "'Sensitive skin increases the damage of any painful attacks you receive.' (AFFLICTION SHOW; no figure given. This page said 50%)"
```

### Finisher: Execute / Behead (truelock)
```yaml
type: execute
summary: PvP lock finisher — the offense file's actual kill commands

code:
  1: "Truelock and the target prone: wield shield scimitar; behead <target> (:1777-1781)"
  2: "Else, finish strategy and joint probability >= 0.90: execute <target>, with no wield (:1782-1790)"

joint_probability_gate: |
  execute only fires when getStateProbabilityV3 of all 5 lock affs
  (anorexia, asthma, slickness, impatience, paralysis) >= 0.90.
  If truelock is per-aff true but jointly shaky, it falls through to the
  lock_reinforce burst instead of gambling the kill on a bluff.
  (002_Serpent_Offense.lua:1782-1790, 2239-2250)

game_data: |
  WIKI (Subterfuge, Execute): "While wielding a whip, you may attempt to execute a prone
  victim." 2.00 s of balance. So EXECUTE wants a PRONE target and a WHIP, while our code
  sends it only when the target is NOT prone (prone goes to BEHEAD) and without wielding
  the whip. BEHEAD is in none of the Serpent's skill pages (the knights' Distract calls it
  one of "the behead or shatter abilities from weaponry"); in Mystor's Shaman log a
  Shaman beheaded a paralysed, truelocked victim who was never prone, with a scimitar
  (kb/raw/logs/2026-10-11_mystor_shikudo-vs-shaman_loss_t54WWU6b.txt:3715-3791; the
  write-up, kb/combat/fights/..._t54WWU6b.md, already notes our prone gate is stricter).
  So the two branches look the wrong way round. UNVERIFIED in a Serpent fight: settle with
  AB SUBTERFUGE EXECUTE and one try each against a prone and a standing target.

notes: |
  GARROTE is NOT a PvP kill route — the PvP offense file never sends it.
  garrote is the PvE basher attack only (ataxiaBasher_serpentBashing,
  basher/002_Class_Bashing.lua:3826).
```

## Offensive Abilities
```yaml
# WIKI (kb/classes/serpent.md) unless marked. No Serpent AB is captured, so the costs are the wiki's.
# Subterfuge / Venom
bite:
  skill: Venom
  balance: "4.00 seconds of balance"
  effect: "Bite with envenomed fangs, applies one venom (the venom only works on adventurers); Ekanelia reactions fire on the bite"
  syntax: "BITE <target> [<venom>]"
  notes: "Single venom application; fangbarrier (sileris/quicksilver) stops it (HELP 13.7)"

doublestab:
  skill: Subterfuge
  balance: "2.80 seconds of balance"
  effect: "Two venoms at once from a dirk envenomed with more than one venom; adventurers only"
  syntax: "DOUBLESTAB/DSTAB <target> [venom1 venom2]"
  notes: "Our default attack. No Ekanelia reaction (fangs only). The wiki says sumac, camus and notechis cannot envenom a weapon"

flay:
  skill: Subterfuge
  balance: "2.00 seconds of balance"
  effect: "Strips the sileris coating (bare FLAY), or rebounding, or a shield; applies the whip's venom if the target is left with neither rebounding nor shield"
  syntax: "FLAY <target> / FLAY <target> REBOUNDING [<venom>] / FLAY <target> SHIELD [<venom>]"
  notes: "Our offense sends only the SHIELD/REBOUNDING forms (:1754, :1763)"

garrote:
  skill: Subterfuge
  balance: "varies with weapon speed"
  effect: "With a whip, slip behind the target and choke; armour is useless; always hits a helpless target (paralysed, tied up, frozen, fallen, sleeping, unconscious)"
  syntax: "GARROTE <target>"
  notes: "No hiding requirement in the wiki text (this page said 'Requires hidden, behind target'). Our PvE basher attack only"

execute:
  skill: Subterfuge
  balance: "2.00 seconds of balance"
  effect: "While wielding a whip, execute a PRONE victim"
  syntax: "EXECUTE <target>"
  notes: "See the Finisher: our code sends it on a target that is not prone"

hide:
  skill: Subterfuge
  balance: "Hide: 4.00 seconds of balance; Emerge: 1.00 seconds of balance (this page said eq)"
  effect: "Enter stealth mode"
  syntax: "HIDE / EMERGE"

phase:
  skill: Subterfuge
  balance: "4.00 seconds of balance, 100 mana (this page said eq); endurance drains while phased"
  effect: "Hidden from all unphased adventurers; attacking one unphases you"
  syntax: "PHASE / UNPHASE"

# Hypnosis
hypnotise:
  skill: Hypnosis
  balance: "equilibrium"
  effect: "Seize the victim's mind; this can take several seconds"
  syntax: "HYPNOTISE <target>"
  notes: "Required before suggestions"

suggest:
  skill: Hypnosis
  effect: "Implant a suggestion (trivial or complex) in a hypnotised victim"
  syntax: "SUGGEST <target> <suggestion>"
  off_balance: "Since 2026-10-23: used while OFF balance it takes a fixed, unmodifiable equilibrium (figure not given; admin: to slow Serpent's early game, may be reverted). Our offense sends it before dstab, on balance (002:2026), so it is unaffected (kb/changes/2026-10-23_classleads.md, kb/CONFLICTS.md #45)"

seal:
  skill: Hypnosis
  balance: "2.0 seconds of equilibrium, 200 mana"
  off_balance: "Since 2026-10-23: used while OFF balance it takes an unmodified equilibrium. Our offense seals before dstab, on balance (002:2043)"
  effect: "Primes the trance: a delay of 3 s or more (1 s if the victim has deadening), after which the suggestions tick every 4 s (3 s with deadening)"
  syntax: "SEAL <target> <delay in seconds>"
  notes: "This page said 'SEAL <target> <suggestion>: lock in a suggestion permanently'. Our hypnolock sends `seal <target> <number of suggestions>` (getCommand, :355), i.e. a delay of 1-3 s: with fewer than three suggestions that is under the 3 s minimum unless the victim has deadening. UNVERIFIED in game"

snap:
  skill: Hypnosis
  effect: "Triggers the sealed trance; the suggestions begin to fire"
  syntax: "SNAP <target>"
  notes: "Our fratricide mode snaps without a seal (:361-369)"

impulse:
  skill: Hypnosis
  balance: "1.70 seconds of equilibrium"
  effect: "One TRIVIAL suggestion, without hypnosis"
  syntax: "IMPULSE <target> <suggestion>  (relayed: a venom may follow; see Impulse Mechanics)"

shrugging:
  skill: Venom
  balance: "1.60 seconds of equilibrium, 10.0 second cooldown"
  effect: "Cure one of your own afflictions"
  syntax: "SHRUGGING"
```

## Complete Venom Reference
```yaml
# Venoms are used by Serpents and classes with edged weapons (Knights DWC)
# Listed by combat utility category.
# Venom -> affliction: venom_to_aff (ataxia/001_Miscellaneous_Aff_Tracking_Methods.lua:202-249) and
# the wiki's Venom page; cures: AFFLICTION SHOW (kb/raw/live/affliction_show/).

# === LOCK AFFLICTIONS (Priority for True Lock) ===
kalmia:
  affliction: asthma
  cure: kelp (or aurum)
  effect: "Contracts lungs, blocks smoking pipes"
  lock_role: "Blocks smoke cures (aeon, slickness alt)"

gecko:
  affliction: slickness
  cure: "bloodroot or magnesium; or smoke valerian or realgar"
  effect: "Body coated in slick slime, blocks applying salves"
  lock_role: "Blocks salve cures (anorexia, restoration, mending); strips a fangbarrier (CONFIRMED in two logs)"

slike:
  affliction: anorexia
  cure: "apply epidermal to body, or FOCUS"
  effect: "Lose all desire for food/drink, blocks eating herbs"
  lock_role: "Blocks herb cures (most afflictions)"

curare:
  affliction: paralysis
  cure: bloodroot (or magnesium)
  effect: "Muscles fail to respond, cannot move or act"
  lock_role: "Blocks tree tattoo usage"

xentio:
  affliction: clumsiness
  cure: kelp
  effect: "Become clumsy fool, fumble attacks and actions"
  lock_role: "Often confused with impatience - actually gives clumsiness"
  notes: "For impatience (blocks focus), use different method"

vernalius:
  affliction: weariness
  cure: kelp
  effect: "Strength leaves body, blocks Fitness passive cure"
  lock_role: "Blocks Fitness (asthma auto-cure for most classes)"

# === DAMAGE VENOMS ===
sumac:
  affliction: damage
  cure: none
  effect: "Minor direct damage; cannot envenom a weapon (WIKI)"

camus:
  affliction: damage
  cure: none
  effect: "Concentrated sumac, more potent damage; cannot envenom a weapon, so it is bitten (WIKI)"

darkshade:
  affliction: darkshade
  cure: ginseng (or ferrum)
  effect: "Sun sears flesh when exposed to sunlight (DoT)"
  notes: "Damage over time in outdoor/lit rooms"

scytherus:
  affliction: scytherus   # the game calls it "Thin blood"
  cure: ginseng (or ferrum)
  effect: "'Scytherus causes any venoms you get affected by to relapse after a short delay.' (AFFLICTION SHOW)"
  notes: "One of the Serpent's relapse sources. This page said 'damage when eating/drinking cures'; no game data says so"

voyria:
  affliction: voyria
  cure: immunity_elixir
  effect: "Most deadly venom, rapid damage to death"
  notes: "Only cured by sipping immunity elixir"

# === SENSITIVITY/DAMAGE AMPLIFIERS ===
prefarar:
  affliction: sensitivity
  cure: kelp
  effect: "Increases the damage of painful attacks taken (no figure in the record)"
  notes: "Stacks with kelp affs (asthma, weariness)"

# === UTILITY AFFLICTIONS ===
oleander:
  affliction: blindness
  cure: epidermal (to the head)
  effect: "Visual system fails, eyes no longer function"

colocasia:
  affliction: [blindness, deafness]
  cure: epidermal (to the head, one each)
  effect: "Robbed of sight AND hearing simultaneously"

digitalis:
  affliction: shyness
  cure: goldenseal
  effect: "Become shy, fearful, cannot speak or yell"

aconite:
  affliction: stupidity
  cure: goldenseal (or plumbum, or FOCUS)
  effect: "Brain ceases operating correctly, complete stupor"
  notes: "The record: 'Stupidity makes it harder to do exactly what you want to do. You may fumble some actions.'"

monkshood:
  affliction: disloyalty   # old name: disfigurement (the game treats them as one)
  cure: "smoke valerian or realgar"
  effect: "Horrible facial disfigurement, loyals may turn"
  notes: "The trigger venom of the monkshood reaction (impatience)"

euphorbia:
  affliction: nausea   # this page said "vomiting"; the record: "Nausea causes intermittent, painful vomiting."
  cure: ginseng (or ferrum)
  effect: "Digestive upheaval, spasmodic vomiting"
  notes: "Interrupts eating, purges rift items"

larkspur:
  affliction: dizziness
  cure: goldenseal
  effect: "Induces great dizziness"

delphinium:
  affliction: sleep
  cure: "wake"
  effect: "Slows heartrate, induces peaceful sleep"
  notes: "Target must be woken or cannot act"

vardrax:
  affliction: addiction
  cure: ginseng
  effect: "Instills addiction that cannot be sated"
  notes: "Must smoke constantly or suffer withdrawals"

# === LIMB VENOMS ===
epteth:
  affliction: a level-1 broken arm (venom_to_aff: brokenleftarm, else brokenrightarm)
  cure: "apply mending to arms"
  effect: "Upper limb muscles shrivel, arms become useless"

epseth:
  affliction: a level-1 broken leg (venom_to_aff: brokenleftleg, else brokenrightleg)
  cure: "apply mending to legs"
  effect: "Leg muscles rot and wither"

# === MENTAL AFFLICTIONS ===
eurypteria:
  affliction: recklessness
  cure: lobelia
  effect: "Believe yourself immortal, run into battle recklessly"
  notes: "Target takes more risks, doesn't flee"

# === SPECIAL VENOMS ===
loki:
  affliction: random
  cure: varies
  effect: "Random effects from sickness to death"
  notes: "Chaotic, unpredictable - not reliable for strategies"

selarnia:
  affliction: disrupt_morph
  cure: none
  effect: "Disrupts concentration of shapechangers"
  notes: "Forces druids/sentinels out of morph forms"

oculus:
  affliction: cure_blindness
  cure: none
  effect: "Forcibly heals those with shut eyes or blindness"
  notes: "Anti-venom, removes enemy's blind defense"

nechamandra:
  affliction: shivering
  cure: caloric
  effect: "Blood runs cold, violent shivering"
  notes: "Freezing effect"

notechis:
  affliction: haemophilia
  cure: ginseng
  effect: "Prevents blood from clotting"
  notes: "Target cannot clot bleeding. Cannot envenom a weapon (WIKI): see Class-Aware Venom Routing"

# === VENOM CURE GROUPINGS (for affliction stacking) ===
cure_groups:
  kelp: [asthma, clumsiness, sensitivity, weariness, health_leech]
  lobelia: [agoraphobia, claustrophobia, fratricide, hypochondria, loneliness, masochism, recklessness, vertigo]
  ginseng: [addiction, darkshade, haemophilia, lethargy, nausea, scytherus]
  goldenseal: [dizziness, epilepsy, impatience, shyness, stupidity, dissonance]
  bloodroot: [paralysis, slickness]
  epidermal: [anorexia, blindness, deafness]
  valerian_smoke: [disloyalty, slickness_alt]
  caloric: [shivering, frozen]
  mending: [broken_limbs]   # this said "restoration: crippled_limbs"
```

---

## Ekanelia (Venom Bonus Afflictions)

```yaml
ekanelia_overview:
  source: |
    WIKI (Venom, Ekanelia; kb/raw/wiki/Venom.wiki:383-391): a reaction has a trigger venom
    ("this is what you bite with"), conditionals the victim must already have, and a result;
    some add a bonus conditional and a bonus result. "only the fangs of the serpent are
    sufficient for this purpose" and "** Reactions fire on the bite command." The game lists the
    reactions you know with EKANELIA and explains one with EKANELIA STUDY <reaction>; neither has
    been captured. So every reaction below comes from our own table (EKANELIA_TABLE, :459-509;
    header, :30-37) and is UNVERIFIED. The relayed notes (2026-10-12) agree on one: monkshood.
  description: |
    Ekanelia is a Serpent skill that ADDS bonus afflictions to BITE attacks
    when specific conditionals are present on the target.
    Delivered by BITE, and by IMPULSE when it carries a venom (relayed notes; our code), NOT by
    DOUBLESTAB (a dirk, not fangs). In the lock rotation the main delivery is the impulse
    (selectImpulsePair, :902-933), not a raw bite. File header: "EKANELIA TRANSFORMATIONS
    (BITE/IMPULSE only)" (002_Serpent_Offense.lua:30).

  mechanic: |
    When biting with an Ekanelia-enhanced venom, if the target has ALL
    the required conditional afflictions, the bite delivers BOTH the normal
    venom affliction AND the bonus Ekanelia effect. This makes single bites
    extremely powerful when conditions are met. Whether our "bonus" afflictions
    are the game's results or bonus results is unknown.

  recording: |
    Since v4.7.419 trigger 016 records the reaction's afflictions on the target
    (serpent.EKANELIA_RESULTS, :525-532); trigger 009 records the venom's own.

  tradeoff: |
    Using BITE instead of DSTAB means serpent only applies one venom base,
    but gains potentially 2-3 afflictions total when Ekanelia triggers.

ekanelia_transformations:
  kalmia:
    conditionals: [clumsiness, weariness]
    normal_effect: asthma
    bonus_effect: slickness
    total: "asthma + slickness from single bite"
    notes: "Powerful - gets both lock afflictions in one attack"

  aconite:
    conditionals: [deadening, dementia]
    normal_effect: stupidity
    bonus_effect: paranoia
    total: "stupidity + paranoia from single bite"
    notes: "Double mental pressure"

  monkshood:
    conditionals: [asthma, masochism, weariness]
    normal_effect: disloyalty
    bonus_effect: impatience
    total: "disloyalty + impatience from single bite"
    notes: |
      The MAIN impatience route, not an alternative to impulse (this page said "Alternative
      impatience delivery without Impulse requirement"): `impulse <target> masochism monkshood`
      brings the masochism itself, so only asthma + weariness must already be up (relayed notes,
      PLAYER; our selectImpulsePair). A plain BITE monkshood needs masochism already present
      (selectBiteVenom step 3, :1064-1069).

  curare:
    conditionals: [hypersomnia, masochism]
    normal_effect: paralysis
    bonus_effect: hypochondria
    total: "paralysis + hypochondria"
    notes: "Lobelia + paralysis in one attack. (This page said the reaction consumes hypersomnia; neither our code nor any game data says so.)"

  voyria:
    conditionals: [anorexia, impatience, vertigo]
    normal_effect: voyria
    bonus_effect: [confusion, disrupted]
    total: "voyria + confusion + disrupted from single bite"
    notes: "Triple affliction from one bite"

  loki:
    conditionals: [confusion, recklessness]
    normal_effect: random
    bonus_effect: [nausea, paralysis]
    total: "random + nausea + paralysis from single bite"
    notes: "Loki becomes PREDICTABLE - guaranteed para + nausea"

  scytherus:
    conditionals: [addiction, nausea]
    normal_effect: scytherus
    bonus_effect: camus
    total: "scytherus + camus damage"
    notes: "Heavy damage output when conditions met. (A haemophilia 'bonus conditional' this page listed is in neither our code nor any game data.)"
```

---

## Defensive Abilities
```yaml
scales:
  skill: Subterfuge
  effect: "Mildly protective serpentine scales"
  syntax: "SCALES / SCALES SHED"
  notes: "3.00 seconds of balance (WIKI)"

phase:
  skill: Subterfuge
  effect: "Hidden from all unphased adventurers; cannot interact with items, denizens or unphased adventurers"
  syntax: "PHASE / UNPHASE"
  notes: "Attacking an unphased adventurer unphases you (WIKI); this said they cannot attack while phased"

hiding:
  skill: Subterfuge
  effect: "Cannot be targeted if hidden"
  notes: "Broken by various detections"

hypersight:
  skill: Subterfuge
  effect: "Since 2026-10-23: while active, works as a star sigil against an evading Serpent who has any affliction you gave, or took damage from you recently"
  notes: "Announcement only (kb/changes/2026-10-23_classleads.md). Serpent vs Serpent: the first hit stops the other from slipping away. `hypersight` is only a defence name in our code"
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
enabled: false
notes: "Serpent is affliction-based, not limb-based"
```

## Bashing (PvE)

The game lines quoted in this section were pasted by the user from their own client (the versions
are in CHANGELOG.md). None of them is filed in `kb/raw` yet.

```yaml
# ataxiaBasher_serpentBashing (basher/002_Class_Bashing.lua:3826)
attack_command: "garrote <target>"   # the actual basher attack (NOT "BATTLERAGE BITE")
attack_skill: Subterfuge
sequence:
  - "If shielded: flay <target> shield"   # strip shield first
  - "Assembled battlerage (ataxiaBasher_assembleBattlerage)"
  - "If not shielded: garrote <target>"
  - "...or, with Serpent's Maw or Toxicologist (Mnemosyne boons, v4.7.381): purge;secrete camus;bite <target> (purge added v4.7.383)"
notes: "There is no BATTLERAGE BITE and no 'envenom' battlerage ability."
assassins_blade: |
  v4.7.393. Assassin's Blade (mnemAssassinsBlade): "When hidden from sight, your backstab will resolve
  instantly without a need to channel." Darkwalker: "Defeating a denizen will render you hidden." User:
  "with This and darkwalker it should always open with backstab". BACKSTAB (AB 1250): BACKSTAB <target>
  [<venom>], 2.00s balance, only while hidden. With the boon and the `hiding` defence up (and no shield),
  the round is `backstab <target>` FIRST, then the lightwall and battlerage, so neither can reveal us
  before it lands. Darkwalker has no flag: the `hiding` defence is the gate.
  v4.7.394, user: "backstab needs a dirk in our hand" -- the round starts `wield shield dirk;backstab <target>`.
  v4.7.408: Darkwalker's kill line "You swiftly return to concealment in the wake of your triumph." ("this rehides
  us also", trigger serpent/020) counts as hidden for 3s (`ataxiaBasher_serpentHidden`), because it
  arrives before GMCP's Defences.Add and the next denizen's round is built in that gap. It also
  re-queues the round at once. A GMCP Remove of `hiding` cancels it. It never writes ataxia.defences.
  v4.7.409: "You are already hidden." (the HIDE refusal) stamps the same way; v4.7.410: so does the
  successful HIDE line "You conceal yourself using all the guile you possess."
  v4.7.411: the backstab's landed line "You leap from the shadows and plunge your dagger into <mob>'s
  unsuspecting back!" (serpent/021) is highlighted bold chartreuse and drops the hidden window and the
  `hiding` defence (user: "When we backstab we become unhidden"), ahead of GMCP's Remove.
  v4.7.412: "Your attack has brought you out of hiding." (serpent/022) does the same, without a highlight.
  v4.7.413: "You must be hiding or phased to backstab." (serpent/023) marks us unhidden the same way and
  re-sends the round at once, so the garrote / camus bite goes out instead (user-directed).
  The cycle (user): backstab once to open, kill, Darkwalker rehides us, backstab again. The wield stays
  `wield shield dirk` (user: "wield shield dirk is fine"; v4.7.408 had briefly sent `wield dirk`).
venom_agony_purge: |
  v4.7.392, user: "We need to purge in this instance" on "You scream out in agony as a vicious venom tears
  through your body." serpent/019 sends a direct `purge` (like serpent/014's secrete refusal), at most once
  per 2s, so it never touches a queued attack or escape. Start-of-line match, full stop optional.
venom_boons: |
  User (v4.7.381): "we should use venom instead of garrote with these boons" -- "secrete camus;bite target".
  Serpent's Maw (mnemSerpentsMaw): venoms deal unblockable damage to denizens, base damage +50%.
  Toxicologist (mnemToxicologist): venoms relapse against denizens, dealing damage again after a delay.
  Camus (AB 1292): SECRETE CAMUS / BITE <target>, works on denizens; "can not be used to envenom a weapon".
  Highlights (v4.7.384): our bite ("You sink your fangs into <x>, injecting just the proper amount of <venom>.")
  in bold chartreuse (highlighting/068); Toxicologist's relapse ("<x> screams out in agony, struck by the
  effects of a vicious venom.") in bold yellow (mnemosyne/108), which also re-latches mnemToxicologist.
battlerage: |
  Table (_groups.yaml ataxiaBasher.battlerage.Serpent): small = thrash, large = throatrip,
  special = obliviate, raze = excoriate. Serpent runs the SHARED path (ataxiaBasher_standardBattlerage,
  basher/001); special threshold 28.
  Costs/cooldowns (Battlerage wiki page, WIKI confidence unless marked AB):
    thrash     14 rage, 16s  -- heavy damage. Fire line "You crack <whip> over your head before
                               repeatedly lashing <x> with it." (trigger 330; NOT culling blade)
    throatrip  36 rage, 23s  -- damage. Fire line in trigger 331.
    obliviate  28 rage, 41s  -- amnesia (AB 2115, kb/raw/ab/serpent_obliviate_2115.txt). Fire line
                               "You draw <x>'s attention with the wavering tip of one finger, then quickly
                               snap your fingers ..." (trigger 332; matched on its opening since v4.7.421,
                               the full line wrapped and could never match, so its 42s timer never armed)
    excoriate  17 rage       -- strips a denizen shield.
    flagellate 25 rage, 27s  -- sensitivity. NOT in the table (no fire line captured).
    snare      25 rage, 23s  -- more damage vs reckless/inhibited. NOT in the table (no fire line captured).
  Order (v4.7.421, user: use every battlerage when the damage ones are on cooldown): one denizen
  thrash -> throatrip -> obliviate; 2+ denizens obliviate first (unchanged). The ~1s global battlerage
  cooldown is honoured, and a refused battlerage gives a Rage-Fuelled charge back.
  Rage-Fuelled removes the COST, never the cooldown: at 98-100 rage (the 2026-10-12 log) it buys nothing
  extra until flagellate/snare join the rotation.
```

## Fighting Against This Class
```yaml
# CRITICAL: Understanding the modern Serpent lock

impatience_prevention:   # this was "impulse_prevention: Impulse requires asthma + weariness + no sileris"
  description: |
    IMPULSE itself has no stated requirement (WIKI). What asthma + weariness enable is the
    monkshood REACTION: `impulse <you> masochism monkshood` brings its own masochism, and with
    asthma + weariness up the reaction adds impatience (Notes relayed 2026-10-12). Fangbarrier
    stops the bite (HELP 13.7), and so, by our code's reading, the impulse's venom.
  defense:
    - "Keep fangbarrier up: the live normal set keeps it at defence priority 25 (kb/raw/live/curing-priority-defence-list_normal_2026-10-10.txt:27). Slickness strips it (two logs) and so does a bare FLAY (HELP 13.7)"
    - "When asthma + weariness are both up, cure asthma first (astWear: asthma -> 3 against a Serpent target)"
    - "Asthma and weariness are BOTH kelp cures - you can only cure one at a time"
    - "Curing masochism in advance does NOT stop the impulse route (the impulse brings it); it only stops a plain BITE monkshood"
    - "Hypochondria gives impatience on its own seconds later: cure it early (AntiSerpent prioaff, v4.7.419)"

bloodroot_competition:
  description: "Paralysis and slickness BOTH cure with bloodroot"
  defense:
    - "When asthma present, you can't smoke valerian for slickness"
    - "So bloodroot must handle BOTH paralysis and slickness"
    - "PRIORITIZE PARALYSIS when asthma blocks smoking"
    - "Paralysis blocks the tree and physical movement; slickness only blocks salves"

fratricide_handling:
  description: "Each impulse relapses shortly after it lands (game: 'a short time'; relayed: 2.25 s), and poison resistance drops"
  defense:
    - "Cure with lobelia or argentum (Eat Lobelia / Eat Argentum)"
    - "fratLock: fratricide -> 4 when asthma + slickness are up too (on by default)"
    - "AntiSerpent: `curing prioaff fratricide` while scytherus is up and paralysis is not (v4.7.419)"
    - "The record times the relapse from the impulse's introduction, not from a cure. Our reading (UNVERIFIED; the record gives no count): it brings an affliction back once, and an affliction cured after that should stay cured"

tree_timing:
  description: "Tree is your emergency escape - don't wait until locked"
  defense:
    - "Touch tree when APPROACHING lock, not when LOCKED"
    - "Approaching lock = asthma + slickness + (impatience OR anorexia)"
    - "If paralyzed, you CANNOT tree - cure para first"
    - "Tree before paralysis is applied!"

ekanelia_defense:
  description: |
    Ekanelia STACKS bonus afflictions on BITE attacks when conditionals met.
    A single bite can deliver 2-3 afflictions - extremely dangerous.
    (Every reaction is from our own table; see the Ekanelia section.)

  critical_combinations:
    kalmia_setup:
      conditionals: [clumsiness, weariness]
      danger: "Single bite gives asthma + slickness (both lock affs)"
      defense: "Cure clumsiness OR weariness to block"

    monkshood_setup:
      conditionals: [asthma, masochism, weariness]
      danger: "Impatience; the impulse brings the masochism, so only asthma + weariness must be up"
      defense: "Cure asthma OR weariness. Curing masochism blocks only a plain bite (and the curare reaction)"

    loki_trap:
      conditionals: [confusion, recklessness]
      danger: "Loki becomes PREDICTABLE - guaranteed nausea + paralysis"
      defense: "Cure confusion OR recklessness before they bite"

  defense_priorities:
    - "Cure asthma or weariness early - they gate the monkshood impatience"
    - "Don't let clumsiness + weariness stack (enables kalmia→slickness)"
    - "Track conditional combos to predict incoming afflictions"
    - "Ekanelia fires on BITE (WIKI) and, by the relayed notes and our code, on an IMPULSE that carries a venom; not on DSTAB. In our offense the impulse is the main lock-rotation delivery"

priority_cures:
  - asthma: "HIGHEST vs Serpent - a monkshood conditional, and blocks smoking"
  - weariness: "Blocks Fitness; a monkshood conditional (kelp - competes with asthma)"
  - paralysis: "Blocks the tree and physical movement - prioritize over slickness when can't smoke"
  - slickness: "Blocks salves - cure with bloodroot OR smoke valerian (if no asthma)"
  - hypochondria: "Gives impatience on its own seconds later (relayed: 10 s)"
  - fratricide: "Impulses relapse shortly after landing; poison resistance down"
  - impatience: "Restore focus ability"
  - anorexia: "Restore eating ability"
  - sensitivity: "Reduce incoming damage"

dangerous_abilities:
  - doublestab: "Two venoms per attack (2.80 s, WIKI) - can apply asthma+weariness in one hit"
  - bite_ekanelia: "Single bite delivers 2-3 affs when conditionals met"
  - impulse: "A trivial suggestion on 1.70 s of equilibrium; with a venom (relayed) it also bites: masochism + monkshood gives impatience when asthma + weariness are up"
  - fratricide: "Each impulse relapses shortly after it lands (how it is given: unknown)"
  - hypnosis: "Complex suggestions (anorexia, hypochondria, disrupt, ...) via HYPNOTISE/SUGGEST/SEAL/SNAP"
  - phase: "Makes them untargetable; attacking you unphases them"
  - flay: "Strips shield, rebounding, or the sileris coating (bare FLAY). DSTAB's weapon venoms probably land through a fangbarrier anyway (a DSL's did, c.iJVmpL log 863-873; not seen for DSTAB)"
  - execute/behead: "PvP finisher. EXECUTE needs a prone target and a whip (WIKI)"

avoid:
  - "Letting asthma + weariness stack (sets up the monkshood impatience)"
  - "Letting paralysis + slickness stack when asthma present"
  - "Waiting too long to tree (tree when APPROACHING lock)"
  - "Leaving hypochondria up (impatience follows on its own)"
  - "Ignoring fratricide when scytherus is up (impulses relapse; poison resistance down)"
  - "Standing still when they're hidden"
  - "Low health with darkshade/scytherus active"
  - "Letting clumsiness + weariness stack (enables Ekanelia kalmia→slickness)"
  - "Ignoring masochism (the curare reaction, and a plain monkshood bite)"

recommended_strategy: |
  MODERN SERPENT DEFENSE PRIORITY:

  1. DENY THE MONKSHOOD IMPATIENCE: Cure asthma immediately when weariness is present.
     Both are kelp - only one cure per balance. Asthma is higher priority.
     The impulse brings the masochism, so asthma + weariness are what you can deny.

  2. HYPOCHONDRIA AND FRATRICIDE EARLY: hypochondria hands over impatience on its own
     seconds later; fratricide makes each impulse relapse shortly after it lands. Cure
     fratricide at once when scytherus is up.

  3. TREE EARLY: Touch tree when you have asthma + slickness + (impatience OR anorexia).
     This is "approaching lock" - tree NOW before paralysis locks you out.

  4. PARALYSIS OVER SLICKNESS: When asthma blocks smoking, bloodroot must
     cure both para and slick. Prioritize paralysis.

  5. MAINTAIN FANGBARRIER: it stops bites (HELP 13.7), and by our code's reading the
     impulse's venom, but probably not DSTAB's weapon venoms (a DSL's landed through one in
     a log; not seen for DSTAB). Slickness strips it (two logs) and so does a bare FLAY -
     re-apply quicksilver at once; the shell forms about 10 s after the application
     (CONFIRMED, Infernal logs).

  6. KELP STACK AWARENESS: Track your kelp stack. If kelp is depleted
     and you have asthma + weariness, you're in serious danger.

anti_serpent_function: |
  Algedonic.AntiSerpent (src_new/scripts/levi_ataxia/levi/levi_scripts/algedonic_defense_1.0/001_Anti_Priorities.lua:700-753).
  Algedonic.Prioritize() calls it on every GMCP affliction gain and loss
  (004_Aff_gains_losses.lua:367, :444) when OUR TARGET is a Serpent in the NDB
  (ataxiaNDB_getClass(target), :108-109) - not when an unknown Serpent attacks us.
  In order, first match wins:
  1. Approaching lock (asthma + slickness + impatience or anorexia) and we can tree (not
     paralysed, not both arms broken, tree balance) -> `touch tree` (:707-720)
  2. impatience, no paralysis -> `curing prioaff impatience` + `cq all;touch shield` (:722-728)
  3. hypochondria, no paralysis -> `curing prioaff hypochondria` (:741-744, v4.7.419)
  4. fratricide + scytherus, no paralysis -> `curing prioaff fratricide` (:746-752, v4.7.419)
  PRIOAFF writes no stored priority, so 3 and 4 are right in whichever curingset is active.
  This page used to list eight "key triggers". Two are real: approaching lock -> tree (branch 1,
  older than v4.7.419; the old list said "asthma + slickness + mental", the code checks
  impatience or anorexia) and fratricide + scytherus (branch 4, a prioaff since v4.7.419). The
  "asthma cure" item is the astWear swap below, not an AntiSerpent branch. The other five
  (impulseLockThreat, the two "impulseEnabled" items, a quicksilver re-apply, Ekanelia
  prevention) exist nowhere in the code.

  Persistent swaps (Algedonic.ApplySwaps / RestoreSwaps in the same file; toggles in
  swaps/002_Priority_Management.lua, `aconfig prios`):
  - astWear (on): asthma -> 3 when asthma + weariness and the target is a Serpent (:190-195)
  - astImp (on): impatience -> 1 when paralysis + asthma and the target is an Alchemist or Serpent (:141-148)
  - paraAst (on): paralysis -> 1 when asthma + paralysis + slickness (:183-188)
  - fratLock (on): fratricide -> 4 when fratricide + asthma + slickness (:197-202)
  - hypoImp (on): hypochondria -> 1 and impatience -> 4 when lethargy, nausea or addiction is up too (:167-174)
  - scyPara (OFF by default, swaps/002:37): scytherus -> 2 when paralysis is up too (:126-131)
  Each is restored when its affliction is cured (:242-312). They write STORED priorities into
  whichever curingset is active, and against a detected Serpent class detection switches to the
  in-game `serpent` set, whose priority list has never been captured.
```

## Implementation Notes
```
Lines our triggers read (patterns from the code; none captured in kb/raw as of 2026-10-12):
- Victim side (determine_class/002_Serpent_Class_Grab): "^(\w+) quickly pricks you with \w+ dirk\.$"
  and "^(\w+) sinks \w+ fangs into you, injecting .+ venom\.$". This page used to list
  "jabs you with a dirk coated in" and "bites you viciously"; neither is in any trigger or capture.
- Our offense: dstab (serpent/001), bite (009), reaction (016), impulse (017), relapse (018);
  see "What the offense records on the target".
- Fangbarrier on the target: up on "A supple metallic shell of quicksilver has formed around <T>."
  (442; CONFIRMED in the Infernal logs, about 10 s after the application); our bite refused (707,
  code only); stripped (706): our flay lines (code only) and "The protective coating covering the
  skin of <T> sloughs off." (CONFIRMED, c.iJVmpL log, 1078).

Ekanelia Detection:
- When serpent uses BITE instead of DSTAB, check for Ekanelia bonus
- Track target conditionals - if clumsiness+weariness, kalmia bite = asthma+slickness
- If masochism present, curare/monkshood bites gain bonus effects
- Bite gives fewer base venoms than DSTAB, but more total affs when Ekanelia procs

GMCP considerations:
- Track gmcp.Char.Afflictions for current affs
- Venom tracking via attack messages
- Hidden state not in GMCP, must use triggers
- Track kelp stack count for curing decisions

Priority swaps: see anti_serpent_function above. They live in
algedonic_defense_1.0/001_Anti_Priorities.lua (Algedonic.ApplySwaps / RestoreSwaps). There is no
029_Priority_Swaps.lua, and swaps/003_Priority_Swaps.lua is an empty stub saying so.

Edge cases:
- Double venom means 2 afflictions per attack
- Hypnosis: a sealed trance fires its suggestions every 4 s after the seal's delay (3 s with deadening) (WIKI)
- IMPULSE: a trivial suggestion on 1.70 s of equilibrium; asthma + weariness matter only to the monkshood reaction
- Phase hides them; attacking unphases them
- Garrote is the PvE basher attack only, NOT a PvP finisher (execute/behead handle PvP)
- Paralysis and slickness COMPETE for bloodroot cure
- Asthma and weariness COMPETE for kelp cure
- Ekanelia BITE can deliver 2-3 affs when conditionals met (check tAffs)
- Ekanelia loki becomes PREDICTABLE (nausea+para) with confusion+recklessness (our table)

Venom cure groupings (same herb):
- Kelp: asthma, clumsiness, sensitivity, weariness
- Ginseng: addiction, darkshade, haemophilia, lethargy, nausea, scytherus
- Goldenseal: dissonance, dizziness, epilepsy, impatience, stupidity
- Lobelia (or argentum): agoraphobia, claustrophobia, fratricide, hypochondria, loneliness, masochism, recklessness, vertigo
- Bloodroot: paralysis, slickness

DEPRECATED: impSnap swap (impatience is no suggestion; swaps/002_Priority_Management.lua:22)
```

## Searing Light (Mnemosyne boon, v4.7.307) -- LIGHTWALL as a room nuke

*"Conjuring a lightwall now deals fire damage to all denizens in your location."* User: *"in a
room of 2 or more denizens the first thing we need to do is conjure lightwall in any direction."*

**AB Lightwall (Subterfuge 1244):** `CONJURE LIGHTWALL <direction>` / `SNUFF LIGHTWALLS`, "Works
on/against: Adventurers and room", **4.00 seconds of equilibrium**, 45 mana. Passing through
afflicts darkshade and the wall speeds darkshade's progression for anyone standing near it.

| Fact | Handling (`ataxiaBasher_searingLightwall`, `basher/002`) |
|---|---|
| 4.00s of EQUILIBRIUM | rides beside the balance garrote; prepended FIRST, per the user, even ahead of the shield flay |
| 45 mana | 250-mana floor (`LIGHTWALL_MANA`) -- never scrape a dry pool for a rider |
| "all denizens in your location" | **no crowd gate** (user, v4.7.309: "regardless of denizen as it does fire damage one time" -- v4.7.307's 2+ gate withdrawn); **once per room per ripple, full stop** (user, v4.7.310 -- the 60s re-arm withdrawn); rooms conjured this ripple are remembered, so a room patrolled back into is not conjured twice; a new ripple's rooms are new |
| needs a direction | first PLANAR exit of the room's known exits, sorted; a refused direction (`There is already a lightwall in that direction.`, trigger `serpent/001`) is skipped next time |
| confirmation | trigger `mnemosyne/088`: the conjure line restamps the room from the landed moment and releases the replay; the detonation line prints only with the boon and re-latches the flag |

**Lines, pasted by the user from their client on 2026-09-16 (not yet filed in `kb/raw`):**

```
You form a ball of light in your palm and hurl it northwards.
A bright, fiery detonation flares outwards as the lightwall takes shape, searing the location with solar force.
```

**Open question, deliberately not guessed:** whether our own lightwall darkshades us when the
sweep or the escape ladder walks through it. If so, `SNUFF LIGHTWALLS` on room clear is the fix.
