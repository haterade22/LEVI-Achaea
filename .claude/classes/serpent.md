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

`kb/raw/logs/` holds four fights against other Serpents (2026-11-01), logged from the victim's seat. So the
victim's side of a Serpent's commands is MEASURED there (see the theorycraft section). Since 2026-11-07 it also
holds ONE fight of our own Serpent: a spar against Saibel on v4.7.478, raw rounds, no kill and no death
(`kb/raw/logs/ours/2026-11-07_164635_Saibel.log`, cited below as `FL <row>`; the screen log of the same fight is
`kb/raw/logs/2026-11-07_serpent-spar-saibel.txt`). Our dstab, impulse, bite, reaction and flay lines and their
costs are MEASURED from that one fight (see "Our first Serpent fight"). A plain BITE, BLOCK, ORDER, the relapse and
snap lines, and the finishers are still not seen from our seat. Saibel's class (Depthswalker) comes only from the
NDB cache and is UNVERIFIED. The spar gives inputs about OUR seat only: no Saibel number is a victim default.

Code anchors are `src_new/scripts/levi_ataxia/levi/levi_scripts/serpent/002_Serpent_Offense.lua`
(written `:<line>` below) unless another file is named. Every anchor was re-read against that file on 2026-11-08
(3518 lines, with the deep review's fixes in), so a bare `:<line>` is current. "Until v4.7.419" or "v4.7.479" in the
text dates a change, not a line number. Nothing from the 2026-11-08 review has run in Mudlet yet.

---

## Offense Modes & Aliases (002_Serpent_Offense.lua)

```yaml
# The everyday keys are class-shared aliases. On a Serpent each sets a mode, then attacks once.
shared_aliases:
  zz:  "serp_setmode_lock(); serp_ekanelia_offense()       # 152_First_Attack_(All_Classes).lua:49-51"
  xx:  "serp_setmode_hypnolock() only; it sends no attack  # 155_Second_Attack_(All_Classes).lua:44-46"
  vv:  "serp_setmode_darkshade(); serp_ekanelia_offense()  # 153_Fourth_Attack_(All_Classes).lua:19-21"
  sr:  "serp_setmode_group(); serp_ekanelia_offense(true)  # 154_Group_(All_Classes).lua:33-36; true = a group press (see Group presses below)"
  srr: "serp_setmode_scytherus(); serp_ekanelia_offense()  # 157_Scytherus_(All_Classes).lua:14-16"
  srd: "serp_setmode_scytherus(); serp_ekanelia_offense(true)  # serpent/006_Group_Damage.lua (a group press; group damage, camus; same action as srr; Shikudo's shikudo/009 srd is guarded to Monk, v4.7.485)"
  sn:  "the same as vv (aliases .../serpent/001_Darkshade). It called a global the offense no longer has until 2026-11-08. Like vv and ekdark it leaves the mode on darkshade"

# The offense's own aliases (tempAlias, :3355-3365)
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

# One round: serp_ekanelia_offense (:2786) maps the mode to a strategy (auto: determineStrategy,
# :1395; the other modes inline, :2868-2958), selectVenoms (:1525) picks the DSTAB venoms, and
# serp_ekanelia_attack (:1861) builds the command. It dispatches only with balance (:2790), and only
# once per balance (attackInFlight, cleared on the balance-regained edge, :2808-2816, :3330-3340).
# A round the game refused spends no balance, and that used to leave the guard set for good: every
# later press returned in silence (kb/raw/logs/ours/2026-10-27_135412_Tabethys.log:4920-4924). Since the
# 2026-11-08 review the next press sends again once 1.5 s have passed with no balance drop
# (ATTACK_NO_SPEND, :151), with the echo "the last round spent no balance (refused?), sending again."
# It holds while we are slowed (aeon or retardation), where a new send would restart the delay.
# A part name is completed before the round is built (completeTargetName, :2770-2784): `t sai` with one
# listed name starting that way attacks that person in full. It goes through 016's isTargeted, so a full
# name that has left the room is not renamed to a longer listed name; the press prints "Target not in room!".

# Every round goes out as ONE send() (v4.7.479: serp_sendAttack :2722-2755, buildRound :2616-2714).
# Mudlet splits it on the separator, so the game gets one command per piece. Only the FIRST piece goes
# into `queue addclear freestand`; the others go raw, in order. The offense sends only with balance up,
# so the queued piece runs at once. A raw piece that needs balance and comes after the attack is refused
# and HELD ("... was added to your balance queue."), and the game runs it at the next recovery
# (FL 235-259). This said "ONE queue entry" until v4.7.479. That was never what the game got
# (kb/mechanics/balance-and-queueing.md, kb/CONFLICTS.md #53).
purge:      "purge  # residual venom cleared. It needs no balance: in the spar it ran right after the pinshot spent balance, with no hold (the cost line FL 235, the purge FL 240)"
adder_pet:  "order adder kill <target>, ONLY when our death adder is here (v4.7.479, adderOrder :2570-2581): a living snake in our room by GMCP Char.Items (attrib holds 'm' and no 'd', name from ataxiaBasher_CLASS_PETS.Serpent, 'death adder'; isRoomSnake :2509-2513, onRoomItems :2517-2541), or the mount we ride (ridingSnake :2544-2551). Else the round goes without it and one `ADDER:` echo per target says so (:2576-2579). With no room list since the load it asks GMCP once (`Char.Items.Room`, askRoom :2562-2568). Its bite records fratricide and its trip enables the EXECUTE (see Fratricide Mechanics and the Finisher). Why: in the spar no adder was out (user: 'we have an adder I just didnt put it out there'), the game refused all 39 orders, and trigger 641 read some of the refusals as the target leaving (see the spar fixes). Since 2026-10-23 its sileris strip is PROGRESSIVE: the coating degrades each tick and strips after a number of hits; darkshade speeds it, scytherus speeds it a lot, both strip at once (admin; kb/CONFLICTS.md #49). The wiki's Snake ability summons a different snake per city (Mhaldor: adders); the command always says adder"

# The order inside a round (v4.7.479, buildRound :2657-2690). `aconfig serpent attackfirst on|off`
# (configs/034_Serpent_Attack_First.lua; ataxia.settings.serpentattackfirst, default off) picks one.
round_order:
  off: "the default: purge, the adder order, combatQueue's commands (g body, g gold, stand), then the offense's wield and attack (:2683-2689; the sigils lead a first round that has no bow opener). The order before the spar, with the adder fix"
  on: "the attack goes FIRST. Only these go before it: a raw `stand` when we are prone, in front of the queue command (a freestand entry cannot run while prone, HELP 4.6.1); the wield, only when GMCP shows the weapon is not in hand (wieldNeeded :2451-2475); and an equilibrium step the offense puts before the attack (suggest, seal, hypnotise), which must go on balance. Purge, the adder order, the sigils and combatQueue's commands come after it (:2671-2682). A snap, which the offense puts after the attack, stays after it"
  why_on: "in the spar the game answered the second and later commands of a send about 0.09 s after the first, so an attack sent behind six commands landed about 0.12 s later on our clock. Whether it also lands later at the server is open (the A/B question, below). The setting is the probe, so it is off by default"
  weapon_ids: "the user's dirk and whip are artefacts (`Thoth's fang`, `Elentari's Scourge`), so a wielded item's name does not say which weapon it is. The id is learned: after a round that wielded `shield <weapon>`, the one new wielded item that is not the shield is that weapon (learnWeapon :2414-2437), kept in ataxiaTemp.serpentWeaponIds (transient). An unknown hand counts as not in hand: an extra wield costs milliseconds, a wrong weapon the round"

# Round-1 opener (v4.7.479: buildOpener :2321-2346, assembled at buildRound :2657-2670), once per target
opener:
  dispel:       "dispel <target>, the first piece of the first round on each target, in both orders (:2652-2655): a reflection would take the attack"
  useOpener:    "master toggle (default on, :190)"
  useBowOpener: "default on (:191). Never on a group press (`sr`, `srd`, `serpent.state.groupPress`; the user, 2026-11-11: 'Not needed. Waste of balance.' The 2026-11-11 group log had 15 pinshots, about 42 s of balance, more than all our DSTABs); the group opener is dispel and the round. Otherwise the bow is skipped only for the person a pinshot is already in: tpinshot holds that NAME for 21 s, compared case-blind (:2331-2333, serpent/002_Pinshot). It was a boolean, so a new target within 21 s of a pinshot in the old one got none. The countdown echoes still name the current target. The round is: dispel, purge, a stand only when prone, `remove bow`, `wield bow`, `pinshot <target> foot`, then the round's own wield and attack STRAIGHT AFTER the pinshot (`wield shield dirk` when the attack brings no wield), then the adder order, the sigils, and combatQueue's commands without its three idle ones (g body, g gold, stand: IDLE_PRE :2361, which did nothing in 39 of 39 rounds). Why: the pinshot spends balance, so the game held six commands in its balance queue and refused the flay behind them without holding it ('You must regain balance first.' with no 'added' line, FL 235-257). The coating strip slipped a whole round. With the wield and the attack first in that queue, the attack runs at the recovery. Our `pinshot Saibel foot` (FL 214) landed ('Your arrow slams into the foot of Saibel.', FL 234), so the body-part form works; whether the wiki's bare `PINSHOT <target>` works is untested"
  useSigils:    "drop incandescent sigil; attach monolith sigil to incandescent sigil (default off, :195)"

# Per-round denial (config useExitBlock, default off, :194)
exit_block: "`block <dir>` for an exit not blocked in the last 5 s (nextExitToBlock :2294-2307). Since v4.7.479 it goes LAST in the round, after the attack, in every order (:2736-2747, :2690). It went out raw just before the round, on the belief that the whole round was queued. No log shows what BLOCK costs: if it spends balance, a block in front would make the attack the second balance action and slip it a whole balance"
```

### Class-Aware Venom Routing (CLASS_LOCK_VENOM, :872-891)
pickVenom sends curare while paralysis is missing (:938). Once paralysis is up, the next venom is
the target class's lock venom, when its affliction is missing (:945-951):

| Target class | First lock venom | Blocks |
|--------------|------------------|--------|
| apostate, pariah | voyria | sip-based healing/plagues |
| monk, shikudo, tekura | vernalius | weariness → Fitness |
| magi, sylvan | notechis | haemophilia → blood/passive cures |
| infernal, paladin, runewarden, unnamable | xentio | clumsiness → parry+stance |
| psion, alchemist | aconite | stupidity → weave queue / transmute |
| depthswalker | eurypteria | recklessness → shadow cures. Held until the target is locked (v4.7.479, below) |
| druid, sentinel | kalmia | asthma → smoke + morph |

The class is our TARGET's, from `ataxia_targetClass()` (ataxia/ataxia/007_Pariah_things.lua:68; read by
getClassLockAff :898-900 and wantClumsiness :846-848). It takes the NDB class first, ignoring Unknown, and
otherwise classDetect's class only when its attacker is the target, case-blind. So a bystander's class line
does not change the venom, and a target the NDB lacks does not inherit the last target's. An unknown class
gets the standard order. The old `tarClass` was never assigned and is gone. Since v4.7.479 a class venom that
gives recklessness (eurypteria) goes only on a locked target (venomAllowed, :254-256, read at :946); until
then pickVenom falls through to its standard order.

**The clumsiness rule (the user, 2026-11-08; PLAYER).** Clumsiness goes on every class it affects: "When fighting a class that is impacted by clumsiness, it is important to use clumsiness to slow them down. 33 percent chance to miss your target is huge. Additionally, it starts the kelp stack needed to stick Asthma. That is why we do clumsiness."
The immune list is the user's: "Tekura Monk, Sylvan, Magi, Blademaster, and Elemental Lords are all immune to clumsiness." CLUMSINESS_IMMUNE (007_Pariah_things.lua:93-99, read by ataxia_wantClumsiness :110) holds monk, tekura, sylvan, magi, blademaster, airlord, earthlord, firelord and waterlord; clumsinessClassKey (:103) folds "Earth Lord", "Earth Lady", "earth Elemental Lord" and "air Elemental Lady". Against these pickVenom never sends xentio. With paralysis up the class venom goes first where the class has one (monk and tekura vernalius, magi and sylvan notechis; :945-951), then asthma and weariness in whichever order is left (:953-962). Blademaster and the four Lords have no class venom, so they get asthma, then weariness. Every other class, Shikudo and an unknown class included, gets xentio first. The flay's xentio branch reads the same gate (:1924), and so does Pariah's routing (pariah/001:54).
Compared with v4.7.479: Occultist, Bard, Jester, Druid and Sentinel get clumsiness now. Blademaster, Monk, Tekura and the Lords no longer do. Magi and Sylvan were already off the order, and only the flay still gave them xentio. Blademaster has no CLASS_LOCK_VENOM row now (:884-885), so with paralysis up it takes `dstab <t> kalmia vernalius`.
Trap: nothing writes "Tekura", so a monk reads "Monk" until a staff line says "Shikudo" (determine_class/006). A Shikudo whose kick arrives before any staff line, or one the API filled in, can read "Monk" and lose clumsiness until the staff hits us; that the API returns "Monk" for a Shikudo is READ, not tested. With two attackers a kick no longer rewrites a known Shikudo to Monk (006:85-89). The logs leave open whether immune means no miss or no affliction: a Blademaster and an Earth Lord take it and spend a cure on it, and three rows show an Earth Lord's clumsy miss (kb/CONFLICTS.md #81, open).
**Not adopted: asthma and weariness before the class venom (the user, 2026-11-08).** The proposal was MODEL, not from a log: impatience 1.6 to 2.0 s sooner in every case, time to lock unsettled. The user: "Depends, we usually use curare because it is usually HIGHER on the curing priority list and will be eaten before Asthma. Sending Asthma Weariness you now have to try and figure out if they have asthma or weariness when they eat kelp." So curare stays first (:938), then the class venom (:945-951): paralysis sits higher on the curing priority and is eaten before asthma, and asthma + weariness together makes a kelp eat ambiguous. Curare went first in the proposal too, so the order behind paralysis for a class venom that is not curare (vernalius, notechis, aconite and others) got no explicit ruling. It stays as it was.
None of this has run in Mudlet or been seen in a fight.

With a lightwall in the room (`ataxia.lightwall`: GMCP room items and misc_alerts/005, cleared by the next room list or a
room Remove of a lightwall, update_stuff/003; one flag per room) and darkshade missing, darkshade goes before gecko
(hasLightwall :924-926, pickVenom :964). The rule read a flag nothing wrote since v4.3.5, so it is live again. It costs one
stab of slickness: whether that order is wanted is open for the user.

**Notechis may not ride a DSTAB.** The wiki says notechis "can not be used to envenom a weapon"
(`kb/raw/wiki/Venom.wiki:302`), and DSTAB delivers the venoms on a dirk. Our routing sends it by
DSTAB against Magi and Sylvan (above), in `ginseng_pressure` (:1729) and as the haemophilia piece
of `lock_reinforce` (AFF_TO_VENOM, :250). UNVERIFIED in game; if the game refuses it, notechis has
to be bitten.

### Advanced Mid-Fight Behaviors
```yaml
lock_reinforce_burst: |
  Lock, group, darkshade and bitepayload modes at truelock until a voyria impulse has gone out,
  and lock/darkshade at hardlock in the relapse phase (:2871-2879, :2886-2895, :2909-2916, :2942-2946).
  Group joined on 2026-11-08: it stayed on "group" at truelock, nothing in group mode set
  voyriaSent, the finish could not be reached, and every round was curare + kalmia onto a full
  lock (comment, :2888-2891). So group mode at truelock now sends one voyria impulse, then finishes.
  selectVenoms (:1665-1715): curare while paralysis is under 0.90 (haveAff_locked, :1669) with a
  second venom, then voyria (+eurypteria for recklessness) -> vardrax + euphorbia (addiction +
  nausea). The 0.90 is new: at 0.30 a paralysis a tree may have taken (0.875) was never sent again,
  and truelock never came back.
  The second venom is the class lock venom, if it is not curare, its affliction is missing and
  venomAllowed agrees (:1678-1680); else voyria (:1681-1682); else pickVenom("curare") (:1684). It
  went out as "curare curare" for Occultist, Shaman and Jester, whose lock affliction is
  paralysis, and whenever voyria was already up. Those three classes now get voyria while it is missing.
  Since v4.7.479 each eurypteria here (P1's class venom, P2, P4) waits for a locked target
  (:1679, :1692, :1713); P2 then sends curare and P4 vardrax. Truelock can hold bloodfire in
  place of a soft-lock piece, and that does not count as locked.
  PRIORITY 7 (:2099-2114) impulses scytherus once addiction + nausea are up and scytherus is not
  (camus, by our reaction table). The voyria impulse (with a vertigo suggestion when vertigo is
  missing, :2107-2111) needs TRUELOCK, anorexia + impatience, and no voyria impulse sent yet
  (:2104-2105). It marks voyriaSent, which hands over to the finish strategy. Below truelock the
  round is the curare DSTAB until paralysis reads 0.90. It was the voyria impulse every round at
  hardlock, so the curare never went and truelock never came (2026-11-08 review, F8 and X5).

relapse_lock: |
  Lock and darkshade modes only, from the moment serpent.state.impatienceDelivered is set
  (trigger 016, on our monkshood reaction; it sets relapsePhase, :2862) until hardlock (:2877-2881,
  :2915-2918). selectVenoms (:1644-1656) pre-loads gecko + slike once asthma + weariness are up and
  neither slickness nor anorexia is. PRIORITY 7 (:2117-2126) runs selectRelapseImpulse (:1150-1185): the
  monkshood pair again when slickness + anorexia are up and impatience reads under 0.70 (the impatience
  check is v4.7.419) and, at 0.30 or more, the reaction can fire (monkshoodCanReact, :1137-1139), else ONE
  stupidity impulse per relapse phase. That impulse waits while stupidity is
  up (:1167): it is not used up, and the round is the relapse DSTAB until she cures it. Nothing here is timed to
  fratricide: the only fratricide clock is the 2.25 s window inside selectImpulse (see
  Fratricide Mechanics), and the stupidity impulse does not go through selectImpulse. (This
  entry said "timed to the fratricide ~3s relapse window" until v4.7.419.)

bitepayload_ladder: |
  selectBiteVenom (:1213-1261) picks the bite in bitepayload mode (PRIORITY 6, :2075-2081) and,
  in every mode, the venom the rebounding pre-empt's impulse carries (:2001-2002, falling back
  to pickVenom). It returns nil while sileris/fangbarrier is up (:1214). Priority: scytherus
  (camus loop) -> the monkshood reaction (asthma + masochism + weariness, and since v4.7.419
  only while impatience reads under 0.70; at 0.30 or more it also needs asthma, weariness and masochism at
  0.70, because a bite brings no suggestion; the pre-empt's impulse brings its own masochism, so it passes true and skips that bar, :1229-1233) -> the kalmia, loki and aconite reactions (never curare: it consumes scytherus) ->
  curare / kalmia / vernalius for a missing lock piece. A BITE costs 4.00 s of balance (WIKI)
  against DSTAB's 2.80 s.

rebounding_reapply_preempt: |
  Our strip line "You flay away X's aura of rebounding defence." stamps the clock
  (onReboundingFlayed, :3264-3269). A drop only a raise or rebound line showed is stamped at the
  next round (:1884-1887). 8.15 s later one `impulse <target> <suggestion> <bite venom>` goes out
  if the bite can land and no hypnosis step is due (PRIORITY 1.5, :1997-2010): the impulse spends
  equilibrium, so it waits for a due suggest, seal or snap, and the clock stays armed. When its
  bite is monkshood the suggestion is masochism (:2004).
  The stamp came at the next ROUND until 2026-11-08, about a balance after the strip (FL 305 to
  FL 333), so the pre-empt came 9.7 s or more after the strip. The code assumes rebounding returns
  about 8.5 s after it goes (comment, :1986). What is measured is 8.40-8.57 s (p10-p90) after
  the target's SMOKE (kb/mechanics/clocks.md:43, n=460), and our clock counts from the strip, so a
  smoke later than the strip makes the impulse early. Timing it from the smoke is not done.
  Since v4.7.419 the clock is getEpoch (see "What the offense records").
  Since v4.7.479 only a rebounding a game line SHOWED arms the clock
  (serpent.state.reboundingSeen, :1884-1887). The target reset only ASSUMES rebounding, and in
  the spar the first flay found "a non-existent aura of rebounding" (FL 305); that drop armed
  the clock and the pre-empt fired 9.87 s later (FL 566) for a rebounding that never existed.
  reboundingSeen is set by a "tar afflicted" rebounding (a raise line, 430; a rebound line, 274,
  serpent/001, 011; onTargetAfflicted :3236-3248). It is cleared by both of our flay's lines,
  the strip and "You try to flay a non-existent aura of rebounding from X." (onReboundingFlayed
  :3264-3269, temp triggers :3484-3496; the strip line arms the clock, the other does not), by
  each stamp, and by a target change (:3307).

gecko_strip: |
  When the target's sileris/fangbarrier blocks the bite and the monkshood pair is the impulse we
  want, the round DSTABs gecko + another venom once (geckoStripAttempted), and the round after
  it sends curare + slike if impatience landed (postGeckoLockdown) (:2175-2189, :1534-1541).
  It needs no hypnosis step due and impatience under 0.70. It never runs in scytherus mode or
  relapse_lock (:2177-2178); scytherus mode's own block for a blocked bite only echoes (:2192-2196).
  Since 2026-11-08 a new target has no coating assumed (016 targetresetafflictionslevi, :531-532;
  it assumed both up, and only a coating line ever cleared them). The offense can impulse or bite a
  fresh target until 442 (a shell forming, the quicksilver or purple berry form) or 707 (a bite the
  coating stopped) shows one. Rebounding is still assumed, except on a group press (`sr`, `srd`):
  there neither rebounding nor a shield is assumed, and the coating is UNKNOWN until a line
  tells it (Group presses, below).
  Slickness does strip the coating: CONFIRMED twice ("The protective covering coating your skin
  sloughs off." right after slickness lands: kb/raw/logs/2026-10-11_mystor_shikudo-vs-depthswalker_loss_EveP2TVe.txt:771,
  2026-10-11_mystor_shikudo-vs-infernal-dwc_win_c.iJVmpL.txt:873). A bare FLAY <target> strips
  it too (HELP 13.7, WIKI), but the offense never sends a bare flay. (This entry said "NOT
  flay"; that is true of our code, not of the game.) A FLAY of the shield or rebounding also rips
  a coating that is up (rule `attack.flay.coating`, 23 of 23 packets; az 2235-2236).
  A FLAY of a defence the target does not have stripped it too, once. We sent `flay Saibel
  rebounding curare` (FL 283); the game printed "You try to flay a non-existent aura of
  rebounding from Saibel." (FL 305), then "The protective coating covering the skin of Saibel
  is ripped away with their protections." (FL 308), the whip (FL 315) and the paralysis
  (FL 318), in one packet. Rule `attack.flay.missing` (kb/sim/rules_hand.json): MEASURED, n=1,
  value "coating". Its alternative "nothing" is the victim-seat reading of X 5328, where a whip
  landed and the coating stayed up; that command is not seen. Open, n=1 each way (kb/CONFLICTS.md #67).

cure_tracking: |
  serpent.trackCure (:1364-1389) counts the target's kelp, ginseng, bloodroot and focus cures in a
  6 s window (ginseng only while a kelp affliction is up). The callers are herbs/003_Kelp_(Unknown):61
  (kelp and aurum; new on 2026-11-08, so ekstatus's Kelp Cures is no longer always 0),
  herbs/005_Bloodroot_TEST:52, herbs/007_Ginseng:64 and 398_Focus_(UNK):63.
  More than 2 ginseng cures with a ginseng stack under 3 switches auto mode to ginseng_pressure
  (:1472-1480); darkshade mode switches on the first one (:2902-2906).
  Every call rolls the 6 s window first (:1367-1373), so a kelp eat or a focus can clear an expired
  ginseng count and end ginseng_pressure sooner. The focus and bloodroot counts are display only.
  The ADAPTIVE line in ekstatus (:3202-3208) reads these counts. Its "pushing DARKSHADE" text
  describes no code path.

execute_safety: |
  serp_ekanelia_offense recomputes the locks at graded confidence (:2842-2853): softlock = 3 of
  anorexia/asthma/slickness/bloodfire at 0.70; hardlock = that + impatience or sandfever at
  0.70; truelock = that + paralysis at 0.90 (haveAff_locked / haveAff_tactical, :99-106).
  EXECUTE also needs prone at 0.90 and getStateProbabilityV3 of the five lock afflictions plus
  prone >= 0.90 (PRIORITY 2, :1978-1983). See the Finisher.

lock_piece_bars: |
  Since the 2026-11-08 review a decision that DELIVERS a lock piece again reads it at 0.70
  (haveAff_tactical; the comment at :108-117): asthma and slickness in pickVenom and the group and
  relapse pickers, anorexia in slikeGateMet, impatience in reactionSpent, selectBiteVenom's monkshood,
  the normal impulse gate (:2156) and the gecko strip (:2175). So a piece one cure may have
  taken (0.667) goes out again. A decision that BUILDS ON a piece still reads haveAff's 0.30.
  The one exception to "goes out again" is monkshood sent for an impatience between 0.30 and 0.70
  (selectRelapseImpulse, selectBiteVenom, the normal impulse gate). It also needs monkshoodCanReact
  (:1137-1139): asthma and weariness at 0.70. An aurum eat, then a plumbum eat, leaves impatience 0.667,
  asthma 0.667 and weariness 0.333, and no branch holds both pieces. The impulse repeated with no
  reaction possible, in place of the DSTAB that lands the piece back. pickVenomGroup reads weariness at
  0.70 for this reason (its default never sends vernalius; pickVenom and pickVenomRelapse fall through to it).
  targetLocked is unchanged.
```

### What the offense records on the target (v4.7.419)
```yaml
dstab:    "serpent/001_Doublestab: on our dstab line, tarAffed for the two venoms we SENT (envenomList[1], envenomListTwo[1]). When a reflection takes the first prick, the second venom is credited only after the second prick's line and a following line that is neither a rebound nor a second reflection (2026-11-08). No attacker-seat log shows that for a dirk: the order is inferred from the victim seat (X8pRorzR 868-871, 713-716) and from Shikudo's attacker-seat form"
bite:     "serpent/009_Bite: tarAffed(venom_to_aff(venom)) for the venom named in our bite line (not loki or camus)"
reaction: |
  serpent/016_Ekanelia_Success, since v4.7.419: tarAffed(serpent.EKANELIA_RESULTS[venom])
  (:607-614): monkshood impatience, kalmia slickness, loki nausea + paralysis, curare
  hypochondria, aconite paranoia, voyria confusion + disrupted; nothing for scytherus (camus is
  damage). On monkshood it also stamps the 2.5 s impatience cooldown (stampImpatienceCooldown,
  :751-753, which nothing called before) and sets serpent.state.impatienceDelivered. Before
  v4.7.419 it recorded nothing, so our own impatience reached the tracker only if the target
  printed the boredom line (414_Impatience_1), and PRIORITY 4, PRIORITY 7 and selectBiteVenom
  kept re-sending monkshood after it had worked.
impulse:    "serpent/017_Impulse_Suggestion: tarAffed(suggestion)"
relapse:    "serpent/018_Impulse_Relapse: tarAffed(suggestion) again"
fratricide: "tarAffed('fratricide') on the pet snake's bite (serpent/024, new on 2026-11-08), and at the snap if the fratricide suggestion was given (onSnapped, :332-372, the tarAffed at :350); erAff in onFratricideCured (:374-380). See Fratricide Mechanics"
timers: |
  Since v4.7.419 the offense's own timers (the 2.5 s impatience cooldown, the 2.25 s fratricide
  window and the 8.15 s rebounding pre-empt) run on getEpoch (now(), :677-679). They ran on
  os.clock, which Lua 5.1 defines as CPU time: wall time only under Windows' C runtime, so on
  Linux and macOS they ran many times slower than real time.
lines: |
  Every pattern above is our code's. The 2026-11-07 spar captured four of these lines from our
  seat, each with the tracker's +tar row after it, so 001, 009, 016 and 017 match the game:
  "You quickly prick Saibel with your dirk." (FL 359-360), "You craft the impulse of confusion
  in the mind of Saibel." (FL 584-585), "You sink your fangs into Saibel, injecting just the
  proper amount of curare." (FL 590-591), "You sense the weakness in Saibel as your monkshood
  takes hold." (FL 1275-1276; loki prints the same words, FL 1411). The second DSTAB venom
  prints "Striking like a snake, you prick Saibel a second time with your dirk." (FL 363). The
  relapse (018) and snap lines are still code only.
tests: "src_new/tests/test_serpent_notes.lua (36 tests at v4.7.419, 58 now) and test_serpent_spar_fixes.lua (153 at v4.7.479, 214 now)"
```

### The spar fixes in the offense (v4.7.479)
Each comes from the 2026-11-07 spar (see "Our first Serpent fight"). Anchors are this release's.
Not yet run in Mudlet: `src_new/tests/test_serpent_spar_fixes.lua` covers them, through whole
rounds built by serp_ekanelia_offense(). The deep review that followed has its own section, below.

```yaml
recklessness_gate: |
  THE USER'S RULE (2026-11-07): "We shouldnt be doing recklessness unless we have locked them.
  Else that is a wasted attack". targetLocked() (:130-132) is the soft lock: anorexia + asthma +
  slickness, so eating, smoking and salves are shut, each at haveAff_tactical's 0.70 (:103-106).
  A hard or true lock holds the same three pieces, so it counts. The offense's own softlock also
  takes bloodfire in place of a piece (3 of 4); bloodfire does not stop eating, so that case does
  not count here. recklessnessAllowed() (:136-138) gates every recklessness choice:
    - eurypteria as the class lock venom in pickVenom (venomAllowed :254-256, read at :946);
    - the recklessness suggestion in selectImpulse, both passes (:701-704), so the next one in
      IMPULSE_PRIORITY goes instead;
    - the loki pair, when recklessness is its one missing conditional (selectImpulsePair,
      :1074-1075): the loop goes on to the next reaction;
    - lock_reinforce's eurypteria at P1, P2 and P4 (:1679, :1692, :1713).
  Why: in the spar 7 DSTABs carried eurypteria (FL 339, 384, 651, 834, 879, 928, 973), and a
  focus or tree of hers followed each within about 2 s (FL 361-372, 405-422, 994-1050); that it
  took the recklessness is INFERRED (kb/CONFLICTS.md #65). One impulse spent its suggestion on
  recklessness for the loki reaction (FL 1388). `ekstatus` shows "Recklessness: ALLOWED (target locked)" or "HELD (target not locked)" (:3217-3218).
adder_gate: "the death adder is ordered only when it is here (round order above, adderOrder :2570-2581). `ekstatus` shows 'Death Adder: HERE' or 'NOT HERE (no order sent)' (:3213-3214). Another Serpent's adder in our room counts as ours: open"
attack_first: "aconfig serpent attackfirst on|off (round_order above). `ekstatus` shows it (:3215-3216); the setup wizard's combat page has a row for it (020_Setup_Wizard.lua:760) and `ataxia setup guide ataxia` entry 16 explains it (:1057-1061). A Serpent fight log's header has ` | serpent attackfirst on|off` just before ` | rounds raw|alias`, which stays the last field (026_Fight_Log.lua:274-283), so a log says which order it holds"
opener: "the round's wield and attack straight after the pinshot, the three idle commands left out (opener above)"
one_balance_action: |
  ONE BALANCE ACTION PER ROUND. PRIORITY 1 (:1904-1958) sends the flay ALONE. It used to chain
  an impulse behind the flay (the kalmia reaction, or the monkshood "shield-break"), on the belief
  that an impulse uses only equilibrium. Every venom impulse in the spar spent BOTH: "Equilibrium
  used: 1.44s." and "Balance used: 1.7s." (13 of 13, e.g. FL 1270 and FL 1278), and a second
  balance action after a spender is refused (after the pinshot's cost line, FL 235, the flay got
  "You must regain balance first.", FL 257).
  So the next round sends the impulse (PRIORITY 3 or 4) once the defence is down. An equilibrium
  action (hypnosis or snap) can still ride with the flay (:1946-1954).
rebounding_preempt: "arms only on a rebounding a game line showed (rebounding_reapply_preempt above)"
weapon_ids: "learned per weapon in ataxiaTemp.serpentWeaponIds (round_order above)"
not_changed: |
  - xentio (clumsiness) still goes out against a Depthswalker in lock mode: 6 of the spar's 24
    DSTABs carried it (FL 432, 521, 700, 745, 791, 1021), from pickVenom's wantClumsiness order
    (ataxia_wantClumsiness, ataxia/ataxia/007_Pariah_things.lua:110; a Depthswalker is not on the immune list).
  - slike went out in none of the spar's 39 rounds. slikeGateMet (:906-911) opens only on
    impatience, or on the target's focus down with asthma up. Anorexia is one of the recklessness
    gate's three pieces, so no recklessness goes out until slike has landed and stuck.
  - BLOCK's and ORDER's balance costs are unknown.
```

### The deep review of the offense (2026-11-08)
A code and log review after the spar fixes, on the same branch. Each item is in the code and has a test
in `src_new/tests/test_serpent_spar_fixes.lua` or `test_serpent_notes.lua`. The code calls them "2026-11-08 review".
**None of this has run in Mudlet, and no fight has been played on it.** Every game line it cites is from a filed log.
Where the review changed a section above, that section has the detail. These have no section of their own:

```yaml
monkshood_masochism: |
  The monkshood impatience impulse always suggests masochism, even when masochism is believed up
  (MONKSHOOD_SUGGESTION, :628, comment :616-627). Four places: selectImpulsePair's all-met case (:1072),
  PRIORITY 1.5 when its bite is monkshood (:2004), PRIORITY 4 (:2043) and reactionNeeds (:634-645), so a
  keybind suggestion cannot swap it. PRIORITY 5 keeps its own suggestion: impatience is already up
  there, so no reaction is wanted (:2055).
  Why: `impulse Saibel confusion monkshood` (FL 1344) leaned on a held masochism, she focused
  (FL 1345), the impulse and bite landed (FL 1364-1370) and no reaction came. All 7 masochism
  impulses reacted (FL 1275, 1324, 1551, 1596, 1643, 1943, 2033).
  OPEN: that an IMPULSE of a suggestion the target already holds still bites and fires the reaction.
  It is not seen from our seat, and only weakly from a victim's (azbErKcK 3872-3876).
spent_reactions: |
  selectImpulsePair skips a reaction whose results and own venom affliction are all up
  (reactionSpent, :1031-1045; read at :1065). Scytherus has no result entry, so it is never spent.
  Group mode no longer spends an impulse round on a spent loki or aconite reaction, and falls to
  its DSTAB. The pair ekstatus shows may now be another pair, or none.
group_order: |
  pickVenomGroup step 5 counts the first venom's gecko (:983-984). So paralysis + asthma + weariness +
  impatience sends `dstab <t> gecko slike`, as lock mode does. The second venom was a second curare.
flay_venom: |
  While the kalmia reaction waits and paralysis is up, the flay's venom adds a missing affliction
  (kalmiaFlayVenom, :1834-1845): pickVenom("kalmia"), then slike, euphorbia, vardrax, aconite,
  notechis, the first missing and allowed, with vernalius as the last fallback. It was vernalius,
  onto the weariness the reaction needs. This slike skips slikeGateMet on purpose.
class_detection: |
  An enemy Serpent is detected on the flay, the impulse bite, the impulse command, the snap and the
  hypnotise line as well as the first prick (determine_class/002_Serpent_Class_Grab). The old
  bite pattern matched no line.
removed: |
  tarClass (never assigned); the shrug path (canShrug, shouldShrug; ataxia_lockBreak's own shrug,
  can(x)/003_Lock_breakers.lua, is untouched); the behead branch (the Finisher);
  getFocusCooldownRemaining (no caller; the target's focus balance is tBals.focus, kept by trigger 398);
  trigger 648_Darkshade_Failsafe. MENTAL_AFFS now names "pacified", the real key (:814).
not_run_in_mudlet: |
  Everything in this section, the 0.70 bars, the prone EXECUTE, the 024 fratricide row and the class
  gates. Expect more PRIORITY 4 and 5 monkshood impulses with the adder out, since 024 feeds
  impatienceConditionsMet (:775-776), focusLockReady (:825-832) and selectImpulse's window.
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
| `impulse masochism monkshood` "now exists" and gives impatience with asthma + weariness | The wiki's IMPULSE takes no venom; masochism is a trivial suggestion; the reaction list was never captured. Our spar (2026-11-07): every impulse with a venom bit (13 of 13), and the monkshood reaction fired on 8 of 10 monkshood bites, all 7 masochism impulses among them | Venom form CONFIRMED (13 of 13); the reaction is SEEN (8 of 10), its conditionals still our table's | Already sent, with the target, from several paths |
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
- **Measured (other Serpents, 2026-11-07).** DSTAB to the next attack: median 1.83 s, p10 1.73, min 1.545 (n=195,
  `kb/mechanics/clocks.md`; rule `attack.gap.others.dstab`, not usable: p90-p10 is over 0.2). Far below the wiki's 2.80.
- **Measured (ours, the 2026-11-07 spar).** The game prints "Balance used: 1.8s." for our DSTAB (24 of 24). From that
  line to "You have recovered balance on all limbs.": median 1.634 s, p10 1.578, p90 1.741 (n=24; rule
  `attack.cost.own.dstab`). Our round as played, land to land, was slower: median 1.977 after a DSTAB (n=24), against
  the other Serpents' 1.83 (see "Our first Serpent fight"). The cost is the game's; the gap is ours.
- **Our code.** DSTAB is the default attack (`attackMode = "dstab"`, :85; header :21-24). The normal
  round is `wield shield dirk;dstab <target> <v1> <v2>` (:2236-2238).
- **Settle.** `AB DOUBLESTAB` in game. The cadence is timed (above).

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
  so it comes through HYPNOTISE / SUGGEST / SEAL / SNAP, not IMPULSE. The curare reaction also gives
  it (fratricide + nausea + scytherus, and it consumes them: the user's table, 2026-11-11), and our
  offence never picks that reaction.
- **Our code, offense.** The offense gives hypochondria two ways: it is the first of hypnolock's
  three complex suggestions (selectHypnoLockSuggestions, :520-530), and the curare reaction's result,
  which the offence no longer picks (since v4.7.488; trigger 016 still records it if it fires). It reads it twice: as a PRIORITY 4 "third condition" for the
  monkshood impulse (impatienceConditionsMet, :777), and as one of the four mentals the focus-lock
  push counts (MENTAL_AFFS, :810-815, for focusLockReady, :825-832). It does not wait for the free
  impatience, as the Depthswalker offense does (`depthswalker.selectInstillLock`, `depthswalker/015_CC_Depthswalker.lua:519`).
  Nothing models the delay: `017_Affliction_Management.lua` has no hypochondria clock, and the
  boredom-line trigger (`414_Impatience_1`) records impatience alone, deliberately without
  back-filling hypochondria.
- **Our code, defence.** Hypochondria is priority 5 (`ataxia/001_Default_Curing_Prios.lua:254`;
  row 5 of the live normal set). hypoImp (on by default) raises it to 1 and impatience to 4 when
  lethargy, nausea or addiction is up too (`algedonic_defense_1.0/001_Anti_Priorities.lua:189-196`).
  Since v4.7.419 `Algedonic.AntiSerpent` sends `curing prioaff hypochondria` while it is up and
  paralysis is not (:780-783 of that file), the branch AntiDepthswalker already had (:452-453).
- **Settle.** A `fightlog` recording of hypochondria on someone without nausea, left uncured; then
  one cured within a couple of seconds, to see whether the impatience still comes.

### 3. IMPULSE MASOCHISM MONKSHOOD

- **Game data (WIKI).** `IMPULSE <target> <suggestion>`, 1.70 s of equilibrium: "you may inflict
  them with one of the trivial suggestions(*) that are known to you" (`kb/raw/wiki/Hypnosis.wiki:43-50`).
  No venom argument, no stated requirement. The wiki does list the trivial suggestions
  (Hypnosis.wiki:86-251): amnesia, paranoia, loneliness, claustrophobia, stuttering, hallucinations,
  dementia, deadening, epilepsy, agoraphobia, **masochism**, recklessness, vertigo, confusion and
  stupidity, exactly our TRIVIAL_SUGGESTIONS (:208-212). So IMPULSE can give masochism. The complex
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
  weariness -> impatience, :542-548): the impulse brings its own masochism, so only asthma +
  weariness must already be up.
- **Measured (our spar, 2026-11-07).** The venom form works, and it costs both balances. All 13 of
  our impulses ("You craft the impulse of <suggestion> in the mind of <target>.") had "You sink your
  fangs into <target>, injecting just the proper amount of <venom>." 0.000-0.007 s later, in the same
  packet, then "Equilibrium used: 1.44s." and "Balance used: 1.7s." (rule `attack.impulse.venom`;
  e.g. FL 1269-1278). Equilibrium came back first 13 of 13: 1.242 s median from its cost line
  (`attack.cost.own.impulse_eq`) against the bite's 1.563 s (`attack.cost.own.bite`), so the bite's
  balance gates the next round. The header's "BAL+EQ" (:25) was right (kb/CONFLICTS.md #68: the spending
  is answered, whether it NEEDS balance is open). The monkshood reaction
  printed "You sense the weakness in Saibel as your monkshood takes hold." and then her impatience
  line ("Saibel shuffles her feet in boredom.") on 8 of 10 monkshood bites (FL 1275-1277; rule
  `reaction.monkshood.seen`). All 7 masochism impulses fired it. Of the 2 confusion impulses one
  did (FL 1693) and one did not (FL 1364); the stupidity impulse did not (FL 1741). Both misses
  came about 0.13 s after a cure that likely took a condition (a focus, FL 1345; a tree, FL 1719).
  Our seat cannot see her afflictions, so the conditionals stay our table's (`reaction.monkshood`,
  ASSUMED).
- **Unverified.** Whether fangbarrier blocks it (our code assumes so; no log shows an impulse on
  the coating); whether impatience is the reaction's result or its bonus result; whether an impulse
  needs balance as well as equilibrium (all 13 were sent with both up). The relayed form leaves out
  `<target>`, which the wiki requires; our sends include it.
- **Our code.** It sends `impulse <target> masochism monkshood`:
  - PRIORITY 4 (:2036-2048): asthma + weariness plus one "third condition" (fratricide,
    hypochondria, scytherus, slickness, or anorexia with focus down; impatienceConditionsMet,
    :771-781), or asthma + weariness alone in relapse_lock (impatienceConditionsRelapse, :784-789),
    and not inside the 2.5 s impatience cooldown. The third condition is our choice, not the game's
    (comment, :767-768).
  - PRIORITY 7's normal branch (:2156-2170) sends the same pair on asthma + weariness alone, through
    selectImpulsePair (:1047-1084).
  - PRIORITY 1.5, when its bite is monkshood (:2004).
  - The shield-break flay chained it on equilibrium until v4.7.479. The impulse
    spends balance too, so the flay now goes alone (one balance action per round, the spar fixes).
    relapse_lock re-sends it once slickness + anorexia are up (selectRelapseImpulse, :1156-1162).
  - Since 2026-11-08 the suggestion is masochism even when masochism is believed up
    (MONKSHOOD_SUGGESTION, :628; "The deep review of the offense"). It used to impulse another
    suggestion then, and the reaction hung on a masochism she could focus away (FL 1344-1370).
  - v4.7.419: every monkshood send calls checkImpulseEligible (sileris/fangbarrier). Three did
    not (the shield-break, PRIORITY 4, PRIORITY 5), so with fangbarrier up the round sent a blocked
    impulse every round and never reached the gecko strip.
  - v4.7.419: monkshood is no longer sent FOR impatience onto a target that already has it
    (selectBiteVenom step 3, :1229-1233; selectRelapseImpulse, :1156). PRIORITY 5 (:2054-2060) still
    carries its mental impulse on monkshood and requires impatience (focusLockReady, :825-832), so
    the reaction's impatience is wasted there; that is left as it is.
  - The keybind suggestion override does not replace a suggestion the reaction needs (reactionNeeds,
    :634-645, read at :2249). Monkshood's masochism counts since 2026-11-08 even when it is up.
- **Defence.** Since the impulse brings the masochism, curing masochism beforehand does not stop
  this route; it still stops a plain BITE monkshood. The conditionals a victim can deny in advance
  are asthma and weariness: astWear (on by default) raises asthma to 3 against a Serpent target
  when both are up (`algedonic_defense_1.0/001_Anti_Priorities.lua:207-212`).
- **Settle.** `AB HYPNOSIS IMPULSE` and `EKANELIA STUDY MONKSHOOD` in game. The reaction line and the
  costs are read (above).

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
- **Our code.** `FRATRICIDE_RELAPSE = 2.25` (:681-687; it was 3.0, from no stated source).
  selectImpulse will not re-impulse an affliction it sent less than 2.25 s ago while fratricide is
  believed up (:696-730), since the relapse is about to bring it back; a second pass ignores the
  window rather than return nothing. The window runs from our SEND (recordImpulse, :734-736), while
  the game counts from landing, so 2.25 s plus our latency is the matching figure. The tracker
  follows the relapse itself, not a clock: trigger 018 re-records the affliction on its relapse line.
- **Settle.** A `fightlog` recording of us impulsing under fratricide: the gap between 017's line
  and 018's line for the same suggestion.

### 5. "Three sources of relapsing effects"

| Source | Game data | Serpent's? |
|---|---|---|
| Scytherus ("Thin blood") | "Scytherus causes any venoms you get affected by to relapse after a short delay." Cure: Eat Ginseng / Eat Ferrum (`kb/raw/live/affliction_show/scytherus.txt`) | Yes: SECRETE SCYTHERUS / BITE (WIKI) |
| Fratricide | "causes hypnotic impulses to relapse a short time after being first introduced" | Yes by its effect. The pet snake's bite gives it: all 46 fratricide gains in the four Serpent logs come within three rows after the bite line (Z5 900-901) |
| (third) | Not found in the game data. Candidates: hypochondria's delayed symptoms (one log; the game never calls them a relapse); our reaction table's scytherus -> camus (code only); the Toxicologist boon (PvE, Mnemosyne only) | -- |

Not Serpent, listed so they are not confused with these: Shaman SYVIS, "causing diseases that your
victim believes they have cured to relapse shortly there after" (`kb/raw/wiki/Spiritlore.wiki:148`);
knight flail expends, "relapse a short while after they are first given, striking for a second time"
(`kb/raw/wiki/Weaponmastery.wiki:288`); Pariah infest, "The plague your swarm is carrying will relapse
twice at a later time" (`kb/raw/wiki/Pestilence.wiki:130`).

**Our code:** trigger 018 records fratricide's impulse relapses on the target, and trigger 024
records the fratricide itself when a pet snake bites the target (since 2026-11-08). Nothing in the
target tracker models scytherus's venom relapses.

---

## CRITICAL: Impulse Mechanics (checked 2026-10-12)

**Impulse is how a Serpent gives a trivial suggestion without hypnosis, and, with a venom (relayed
notes), how its main reaction, monkshood's impatience, is delivered.**

```yaml
impulse:
  game: "IMPULSE <target> <suggestion>, 1.70 s of equilibrium; one TRIVIAL suggestion; no venom argument and no stated requirement (WIKI, kb/raw/wiki/Hypnosis.wiki:43-50)"
  trivial_suggestions: [amnesia, paranoia, loneliness, claustrophobia, stuttering, hallucinations, dementia, deadening, epilepsy, agoraphobia, masochism, recklessness, vertigo, confusion, stupidity]  # WIKI, Hypnosis.wiki:86-251; = TRIVIAL_SUGGESTIONS (:208-212)
  trivial_rule: "kb/sim/rules_hand.json `attack.impulse.suggestions` (READ) holds the same 15, in the same order, and tools/test_kb_rules.py checks it against both lists. The engine refuses an impulse of any other word (tools/sim/attackers.lua A.parse). The game says 'known to you'; which ones this character knows (AB HYPNOSIS) is not captured. Our selectImpulse picks from IMPULSE_PRIORITY (:216-228), 11 of the 15: amnesia, claustrophobia, stuttering and agoraphobia are never picked. The spar used four: masochism 7, confusion 3, stupidity 2, recklessness 1"
  complex_only: [clumsiness, addiction, pacifism, hypersomnia, lethargy, anorexia, disrupt, generosity, action, hypochondria]  # WIKI, Hypnosis.wiki:252 onward: full hypnosis only
  not_a_suggestion: "impatience (it comes from the monkshood REACTION), fratricide (see Fratricide Mechanics)"
  victim_line: "'<Serpent> fixes his gaze to yours and hisses a sharp command.' Printed by an IMPULSE that bites: in the four victim-seat logs all 22 BITEs have this line in their packet and all 22 lines have a BITE there, with the suggestion's affliction between them (az 1238-1242, Z5 534-537, X 293-296; census in kb/sim/events.md)"
  venom_form: "CONFIRMED in our spar (2026-11-07): `impulse <target> <suggestion> <venom>` delivers a bite of the venom in the impulse's own packet, 13 of 13 (rule attack.impulse.venom, MEASURED). It was PLAYER, UNVERIFIED (relayed notes) until then. Our code sends that form on every impulse (:2008, :2021, :2046, :2058, :2224, :2251)"
  cost: "Wiki: 1.70 s of equilibrium. MEASURED (13 of 13): it prints 'Equilibrium used: 1.44s.' and 'Balance used: 1.7s.' (the bite). From each line to its recovery: equilibrium 1.242 s median (p10 1.201, p90 1.289), balance 1.563 s (p10 1.477, p90 1.581). Equilibrium is back first every time, so the BALANCE gates the next round, and no other balance action can go in the same round (v4.7.479: PRIORITY 1 sends the flay alone)"

our_eligibility_rule: |
  checkImpulseEligible (:1272-1286) refuses an impulse while the target has sileris or
  fangbarrier. Since v4.7.420 every impulse path calls it. Before v4.7.419 the three monkshood
  sends (the shield-break, PRIORITY 4, PRIORITY 5) did not, and until v4.7.420 neither did scytherus
  mode's (PRIORITY 7, :2139-2143). Each sent a blocked impulse every round. A new target has no
  coating assumed since 2026-11-08 (gecko_strip, above). The rule is ours: HELP 13.7 says the coating gives "protection
  against bites from adventurers of the Serpent class" (kb/raw/help/13.7_healing-and-curing.txt:78-81),
  and a reaction "fires on the bite command", so an impulse's venom is presumably bitten. Our spar
  shows it IS bitten: the fang line comes in the impulse's packet, 13 of 13. No capture shows
  fangbarrier blocking IMPULSE.

asthma_weariness: |
  NOT an impulse gate. With masochism they are the monkshood reaction's conditionals, and that
  reaction is where the impatience comes from. `impulse <target> masochism monkshood` brings the
  masochism, so asthma + weariness are the only conditionals that must already be up (Notes
  relayed 2026-10-12, item 3).

impulse_afflictions:   # what IMPULSE gives directly: the trivial list above, notably (effects: AFFLICTION SHOW)
  - masochism: "the monkshood reaction's conditional"
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
    The pet snake's bite. All 46 fratricide gains in the four Serpent logs come within three rows
    after the bite line (Z5 900-901), and the game's record calls it a VENOM ("an insidious venom").
    From a third seat the line is "A death adder sinks its fangs into the neck of Grulk, injecting a
    potent dose of toxin." (kb/raw/logs/ours/2026-11-03_081009_Froedine.log:38). Trigger
    serpent/024_Snake_Bite_Fratricide reads it for any pet snake on our target and records the
    fratricide (new on 2026-11-08). It is not gated on our own pet: the bitten target has it either way.
    Fratricide is in no Hypnosis, Venom or Subterfuge page we hold, and not in either suggestion
    list. Our code also gives it as a SUGGESTION: hypnotise -> `suggest <target> fratricide` -> snap
    (fratricide mode, getCommand :443-451), which no game data supports, and which snaps without
    the SEAL the wiki puts before SNAP. Treat that route as UNVERIFIED. Settle it with AB VENOM, AB
    HYPNOSIS and EKANELIA in game, or a log of a Serpent landing it that way.

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
    - The 2.25 s window: FRATRICIDE_RELAPSE (:681-687) in selectImpulse (:696-730), measured
      from our send (recordImpulse, :734-736), on getEpoch (:677-679).
    - On the tracker since v4.7.419: onSnapped calls tarAffed("fratricide") when the fratricide
      suggestion was given (:332-372, the tarAffed at :350), and onFratricideCured calls erAff (:374-380). Before,
      it wrote tAffs.fratricide directly, so haveAff("fratricide") read false and a lobelia eat
      could never take it off.
    - Since 2026-11-08 the pet's bite records it too (trigger 024). That feeds PRIORITY 4's third
      condition, PRIORITY 5 and the 2.25 s window, so expect more monkshood impulses with the adder out.
    - The fratricide suggestion is recorded from the round's own text (pendingSuggestion, set at
      :2707-2708, read by onSuggested :316-330), so a word left queued by combatQueue cannot be credited.
      A new chain starts clean (start, :282).
    - In V3 a herb eat takes fratricide only when nothing else that herb cures is there
      (herbCureLastV3 in onHerbCureV3, affliction_tracking_core/007_Branching_State_Tracker.lua:158,
      :411-495): it is 25, the bottom, in our priorities and the live normal set, and a list
      position cannot express "cured last". Without the rule, one eat over masochism + fratricide
      left masochism believed at 0.67, and the next monkshood impulse dropped the masochism its
      reaction needs.
    - The cure line we listen for, "The look of madness fades from (\w+)'s eyes" (a temp
      trigger registered at load, :3442-3450), is code only, does not check whose eyes, and does
      not match the game's own cured message above. The offense still ORs
      serpent.hypnosis.fratricideActive into its checks (selectImpulse, impatienceConditionsMet,
      focusLockReady). The snap sets it; only that line or a hypnosis reset clears it
      (serpent.hypnosis.reset, :394-412: a target change, a lost or noticed hypnosis, a "too
      perceptive" refusal, switching into a hypnosis or hypnolock mode; :3281-3312,
      :3461-3479, :3498-3506, :3062-3075, :3083-3095).
    - It counts as a third condition for PRIORITY 4 (:775-776) and is required for the focus-lock
      push, PRIORITY 5 (focusLockReady, :825-832: fratricide + 4 mentals + focus down +
      impatience + asthma + weariness).

  our_defence: |
    - Priority 25, the bottom (ataxia/001_Default_Curing_Prios.lua:311; row 25 of the live
      normal set, kb/raw/live/curing-priority-list_normal_2026-10-10.txt:33).
    - fratLock (on by default): fratricide -> 4 when fratricide + asthma + slickness are up
      (algedonic_defense_1.0/001_Anti_Priorities.lua:221-227, restored :331-337).
    - v4.7.419: Algedonic.AntiSerpent sends `curing prioaff fratricide` while fratricide and
      scytherus are up and paralysis is not (:788-790), the "cure fratricide at once when
      scytherus is up" rule. PRIOAFF writes no stored priority.
    - Against a detected Serpent, class detection switches to the in-game `serpent` curingset
      (class_detect/001_Class_Detect_Engine.lua:62, :238). That set exists
      (kb/raw/live/curingset-list_2026-10-10.txt:17) but its priority list was never captured, so
      the priority actually in force against a Serpent is unknown. fratLock's write and its
      restore land in whichever set is active. Since v4.7.480 the restore writes that set's own value,
      read from the game (kb/curing/server-side-curing.md), and nothing if it is not known.
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
status: "ASSUMED for our offence: the four Serpent logs in kb/raw/logs are from the victim's seat (other Serpents), and our one spar (2026-11-07) ended with no lock and no kill; the pieces are WIKI, PLAYER, our code and those logs"

prerequisites:
  - "Asthma + weariness on the target: with the impulse's own masochism they fire the monkshood reaction (impatience)"
  - "No sileris/fangbarrier for the impulse or bite (HELP 13.7: the coating stops Serpent bites). DSTAB's weapon venoms are not stopped: 8 of 8 slickness DSTABs into a hardened coating landed, and the slickness then stripped it (rule defence.sileris.slickness; Z5 438-452, X 141-147)"
  - "Fratricide (optional): each impulse relapses shortly after it lands"

attack_sequence:   # inherited; this page called it "from combat log". Our one spar (2026-11-07) never reached phase 3: slike went out in none of its 39 rounds
  phase_1_kelp_setup:
    - "DSTAB target kalmia vernalius"   # asthma + weariness (BOTH kelp cures)
    - "FLAY <target> SHIELD|REBOUNDING strips those; a bare FLAY <target> strips the sileris coating (HELP 13.7, WIKI). Our offense never sends a bare flay: it strips the coating with slickness (gecko), which works (CONFIRMED in two logs)"
    - "Weapon venoms land through a formed fangbarrier: an Infernal's DSL gave anorexia, then slickness stripped the coating (c.iJVmpL log, 863-873). DSTAB too: 8 of 8 in the four Serpent logs, for example Z5 438 (hardened), 446-451 (paralysis, then slickness, then 'The protective covering coating your skin sloughs off.')"

  phase_2_impulse_delivery:
    - "impulse target masochism monkshood"  # masochism (impulse) + disloyalty (monkshood) + impatience (reaction)
    - "DSTAB slike once impatience is up (slikeGateMet, :906-911), or relapse_lock's gecko + slike pre-load"  # anorexia
    - "Fratricide, if up, makes each impulse relapse shortly after it lands (the pet snake's bite gives it: 46 of 46 in the four Serpent logs)"

  phase_3_lock_completion:
    - "DSTAB target curare gecko"       # paralysis + slickness (BOTH bloodroot)
    - "Target now in true lock"
    - "Finisher: EXECUTE on a prone target (below)"

example_rounds:   # ASSUMED (inherited; no log of ours runs it)
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
  - fratricide: "NOT a suggestion in the wiki; our code's route only (UNVERIFIED). The pet snake's bite gives it (46 of 46)"

impulse_delivered_afflictions:   # the trivial suggestions (WIKI, Hypnosis.wiki:86-251)
  - [amnesia, paranoia, loneliness, claustrophobia, stuttering, hallucinations, dementia, deadening, epilepsy, agoraphobia, masochism, recklessness, vertigo, confusion, stupidity]

notes: |
  Our code has two chains. The lock chain (hypnolock mode, `ekhl` or `xx`) gives its suggestions one
  per round, then `seal <target> 3` (SEAL_DELAY, :205), then snaps once sealed. The fratricide
  chain (hypnosis mode) gives its suggestion and snaps when the 4 s timer marks the phase
  ready_snap (SNAP_DELAY, :201; onHypnotised, :289-314). Since 2026-11-08 that timer moves only the
  fratricide chain to ready_snap. It used to end a lock chain with a suggestion still to give, and
  that chain never sealed or snapped. Left as is: the fratricide chain can still snap without its
  suggestion if the suggest misses the 4 s mark.
  WIKI: a trance is sealed for 3 s or more (1 s if the victim has deadening), then
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
  - darkshade: "'Darkshade makes even the lightest ray of sunlight extremely painful. Stay outside too long and you will surely die.' (AFFLICTION SHOW). Our code's kill clock: 26 s stuck (DARKSHADE_KILL_TIME, :199). A lightwall 'drastically speeds up the progression' (WIKI)"
  - scytherus: "'Thin blood': venoms relapse after a short delay (AFFLICTION SHOW). Our code adds the scytherus -> camus reaction for damage (code only)"
  - sensitivity: "'Sensitive skin increases the damage of any painful attacks you receive.' (AFFLICTION SHOW; no figure given. This page said 50%)"
```

### Finisher: Execute (truelock, prone)
```yaml
type: execute
summary: PvP lock finisher — the offense file's actual kill command

code:
  1: "Truelock, the target prone at 0.90 and the joint gate below: wield shield whip; execute <target> (PRIORITY 2, :1978-1983). Any strategy: a kill that is ready wins"
  2: "A standing truelocked target gets no finisher. The round falls through to the lock_reinforce or finish DSTAB, which keeps the lock until the adder trips them"

joint_probability_gate: |
  execute only fires when getStateProbabilityV3 of the 5 lock affs and prone
  (anorexia, asthma, slickness, impatience, paralysis, prone) >= 0.90. Prone is
  simple-tracked, so it reads 1.0. If truelock is per-aff true but jointly shaky, the
  round falls through to the DSTAB instead of gambling the kill on a bluff.
  (002_Serpent_Offense.lua:1978-1983, 2842-2853)

game_data: |
  WIKI (Subterfuge, Execute): "While wielding a whip, you may attempt to execute a prone
  victim." 2.00 s of balance. Since the 2026-11-08 review the code follows that, and in
  practice EXECUTE fires only when the adder has tripped the target (serpent/009_Prone). It
  used to send EXECUTE to a standing target with the dirk in hand, and a scimitar BEHEAD to a
  prone one. The BEHEAD branch is gone: BEHEAD is in none of the Serpent's skill pages (the
  knights' Distract calls it one of "the behead or shatter abilities from weaponry"). In
  Mystor's Shaman log a Shaman beheaded a paralysed, truelocked victim who was never prone, with
  a scimitar (kb/raw/logs/2026-10-11_mystor_shikudo-vs-shaman_loss_t54WWU6b.txt:3715-3791).
  Removing it rests on the wiki and has not been tried in game. Open: settle with AB SUBTERFUGE
  EXECUTE and one try each against a prone and a standing target.

notes: |
  GARROTE is NOT a PvP kill route — the PvP offense file never sends it.
  garrote is the PvE basher attack only (ataxiaBasher_serpentBashing,
  basher/002_Class_Bashing.lua:4097).
```

## Offensive Abilities
```yaml
# WIKI (kb/classes/serpent.md) unless marked. No Serpent AB is captured. `measured` is our own seat, the
# 2026-11-07 spar (kb/sim/rules_hand.json attack.cost.own.*, client clock, from the game's cost line to the
# recovery line). `printed` is the game's own "Balance used" / "Equilibrium used" figure. Where the 0.09 s
# step after a send's first reply falls is open: if the server paces its output, each cost is about 0.12 s
# higher (each rule's first_reply value).
bite:
  skill: Venom
  balance: "4.00 seconds of balance"
  measured: "only the bite of an IMPULSE is seen: printed 1.7, median 1.563 s (p10 1.477, p90 1.581, n=13; first reply 1.676). A plain BITE was not sent, so its line and cost are unknown"
  effect: "Bite with envenomed fangs, applies one venom (the venom only works on adventurers); Ekanelia reactions fire on the bite"
  syntax: "BITE <target> [<venom>]"
  notes: "Single venom application; fangbarrier (sileris/quicksilver) stops it (HELP 13.7)"

doublestab:
  skill: Subterfuge
  balance: "2.80 seconds of balance"
  measured: "printed 1.8, median 1.634 s (p10 1.578, p90 1.741, n=24; first reply 1.75)"
  effect: "Two venoms at once from a dirk envenomed with more than one venom; adventurers only"
  syntax: "DOUBLESTAB/DSTAB <target> [venom1 venom2]"
  notes: "Our default attack. No Ekanelia reaction (fangs only). The wiki says sumac, camus and notechis cannot envenom a weapon"

flay:
  skill: Subterfuge
  balance: "2.00 seconds of balance"
  measured: "printed 1.7, 1.530 s (n=1, not usable: swept 1.48-2.00; first reply 1.65). It was a FLAY of a rebounding that was not there (FL 305)"
  effect: "Strips the sileris coating (bare FLAY), or rebounding, or a shield; applies the whip's venom if the target is left with neither rebounding nor shield"
  syntax: "FLAY <target> / FLAY <target> REBOUNDING [<venom>] / FLAY <target> SHIELD [<venom>]"
  notes: "Our offense sends only the SHIELD/REBOUNDING forms (:1948-1953). A FLAY of a missing rebounding stripped the coating too (rule attack.flay.missing, n=1; gecko_strip above)"

pinshot:
  skill: Subterfuge
  balance: "3.00 seconds of balance"
  measured: "printed 1.8, 1.742 s (n=1, not usable; first reply 1.856). Our opener's `pinshot <target> foot` landed: 'Your arrow slams into the foot of Saibel.'"
  notes: "The opener's first attack (buildOpener). It spends balance, so the round's attack must come straight after it (v4.7.479)"

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
  notes: "Our code sends it with the whip on a truelocked, prone target only (the Finisher)"

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
  off_balance: "Since 2026-10-23: used while OFF balance it takes a fixed, unmodifiable equilibrium (figure not given; admin: to slow Serpent's early game, may be reverted). Our offense sends it before dstab, on balance (:2233), so it is unaffected (kb/changes/2026-10-23_classleads.md, kb/CONFLICTS.md #45)"

seal:
  skill: Hypnosis
  balance: "2.0 seconds of equilibrium, 200 mana"
  off_balance: "Since 2026-10-23: used while OFF balance it takes an unmodified equilibrium. Our offense seals before dstab, on balance (:2233)"
  effect: "Primes the trance: a delay of 3 s or more (1 s if the victim has deadening), after which the suggestions tick every 4 s (3 s with deadening)"
  syntax: "SEAL <target> <delay in seconds>"
  notes: "This page said 'SEAL <target> <suggestion>: lock in a suggestion permanently'. Our hypnolock sends `seal <target> 3` (SEAL_DELAY :205, getCommand :437), the wiki's minimum on every target (Hypnosis.wiki:28). Until 2026-11-08 it sent the number of suggestions, so one or two of them put the seal under the minimum. The deadened 1 s form is left out: the tracker cannot promise deadening by the time the seal lands. The manual s2 alias is untouched. No seal from our seat is in a log"

snap:
  skill: Hypnosis
  effect: "Triggers the sealed trance; the suggestions begin to fire"
  syntax: "SNAP <target>"
  notes: "Our fratricide mode snaps without a seal (:443-451)"

impulse:
  skill: Hypnosis
  balance: "1.70 seconds of equilibrium"
  measured: "with a venom it spends BOTH: equilibrium printed 1.44, median 1.242 s (p10 1.201, p90 1.289, n=13; first reply 1.353), and the bite's balance (above). Equilibrium is back first 13 of 13, so the balance gates the next round"
  effect: "One TRIVIAL suggestion, without hypnosis (the 15: rule attack.impulse.suggestions)"
  syntax: "IMPULSE <target> <suggestion> [<venom>]  (with a venom it also bites: 13 of 13 in our spar; see Impulse Mechanics)"

shrugging:
  skill: Venom
  balance: "WIKI: 1.60 seconds of equilibrium, 10.0 second cooldown (kb/classes/serpent.md:148). PRINTED for the user: Equilibrium used: 1.36s (n=1, kb/raw/live/shrugging_2026-11-08.txt). INFERRED: 1.36 is 0.85 x 1.60, the ratio IMPULSE shows too (wiki 1.70, printed 1.44): a cost is stated x k (foundations.md, Stated against observed)"
  effect: "Cure one of your own afflictions"
  syntax: "SHRUGGING"
  notes: "The offense no longer has a shrug path (canShrug and shouldShrug had no caller; removed 2026-11-08). The lock-breaker's own shrug waits for equilibrium since v4.7.480 (ataxia_activeCureHeldForEq, can(x)/003_Lock_breakers.lua:113; the user: 'shrugging yes'). Our first-person line is captured: 'Focusing inward, you purge your body of afflictions.', then the cured affliction's own line (confusion in the one capture), then the cost (kb/raw/live/shrugging_2026-11-08.txt). curing_bals/006:42 and serpent/008_Shruggin:34 already held it, so a shrug that worked sets activeCureUsed. Shrugging with equilibrium down is not probed. While bashing (v4.7.484, not yet run in Mudlet), 3 afflictions that a random cure can take also send it; with the Miracle boon the game cures one more (see kb/afflictions/class-cures.md). PvP stays lock-only"
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
    been captured. So every reaction below comes from our own table (EKANELIA_TABLE, :541-591;
    header, :30-37) and is UNVERIFIED. The relayed notes (2026-10-12) agree on one: monkshood.
    Our spar (2026-11-07) saw two fire, with "You sense the weakness in <target> as your <venom>
    takes hold.": monkshood on 8 of 10 bites, each followed by her impatience line (rule
    reaction.monkshood.seen), and loki on 1 of 2, the recklessness impulse, followed by a paralysis
    line and no nausea line (FL 1406-1414; rule reaction.loki). Our seat cannot see her
    afflictions, so the conditionals stay ASSUMED.
  description: |
    Ekanelia is a Serpent skill that ADDS bonus afflictions to BITE attacks
    when specific conditionals are present on the target.
    Delivered by BITE, and by IMPULSE when it carries a venom (relayed notes; our code), NOT by
    DOUBLESTAB (a dirk, not fangs). In the lock rotation the main delivery is the impulse
    (selectImpulsePair, :1047-1084), not a raw bite. File header: "EKANELIA TRANSFORMATIONS
    (BITE/IMPULSE only)" (002_Serpent_Offense.lua:30).

  mechanic: |
    When biting with an Ekanelia-enhanced venom, if the target has ALL
    the required conditional afflictions, the bite delivers BOTH the normal
    venom affliction AND the bonus Ekanelia effect. This makes single bites
    extremely powerful when conditions are met. Whether our "bonus" afflictions
    are the game's results or bonus results is unknown.

  recording: |
    Since v4.7.419 trigger 016 records the reaction's afflictions on the target
    (serpent.EKANELIA_RESULTS, :607-614); trigger 009 records the venom's own.

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
      (selectBiteVenom step 3, :1229-1233).

  curare:
    conditionals: [fratricide, nausea, scytherus]
    normal_effect: paralysis
    bonus_effect: hypochondria
    total: "paralysis + hypochondria"
    consumes: true
    notes: "PLAYER (the user's Ekanelia table, 2026-11-11): the only reaction that CONSUMES its conditionals ('Cons? Yes'). It was hypersomnia + masochism here and in the code, from no source. Since then the offence never picks it (EKANELIA_TABLE `consumes`, skipped by selectImpulsePair; no branch in selectBiteVenom or selectOpportunisticEkanelia): it would eat scytherus (the camus loop) and fratricide for one hypochondria."

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
# ataxiaBasher_serpentBashing (basher/002_Class_Bashing.lua:4097)
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
      defense: "Cure asthma OR weariness. Curing masochism blocks only a plain bite"

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
  - impulse: "A trivial suggestion on 1.70 s of equilibrium (printed 1.44 in our spar); with a venom it also bites (13 of 13 in our spar) and spends the bite's balance: masochism + monkshood gives impatience when asthma + weariness are up (8 of 10 monkshood bites fired the reaction)"
  - fratricide: "Each impulse relapses shortly after it lands (the pet snake's bite gives it: 46 of 46 in the four Serpent logs, Z5 900-901)"
  - hypnosis: "Complex suggestions (anorexia, hypochondria, disrupt, ...) via HYPNOTISE/SUGGEST/SEAL/SNAP"
  - phase: "Makes them untargetable; attacking you unphases them"
  - flay: "Strips shield, rebounding, or the sileris coating (bare FLAY). DSTAB's weapon venoms land through a fangbarrier anyway: 8 of 8 in the four Serpent logs (rule defence.sileris.slickness), and a DSL's did too (c.iJVmpL log 863-873)"
  - execute: "PvP finisher. It needs a prone target and a whip (WIKI)"

avoid:
  - "Letting asthma + weariness stack (sets up the monkshood impatience)"
  - "Letting paralysis + slickness stack when asthma present"
  - "Waiting too long to tree (tree when APPROACHING lock)"
  - "Leaving hypochondria up (impatience follows on its own)"
  - "Ignoring fratricide when scytherus is up (impulses relapse; poison resistance down)"
  - "Standing still when they're hidden"
  - "Low health with darkshade/scytherus active"
  - "Letting clumsiness + weariness stack (enables Ekanelia kalmia→slickness)"
  - "Ignoring masochism (a plain monkshood bite)"

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
     impulse's venom, but not DSTAB's weapon venoms (8 of 8 landed through a hardened one in
     the four Serpent logs; a DSL's did too). Slickness strips it (8 of 8 in those logs, rule
     defence.sileris.slickness) and so does a bare FLAY -
     re-apply quicksilver at once; the shell forms about 10 s after the application
     (CONFIRMED, Infernal logs).

  6. KELP STACK AWARENESS: Track your kelp stack. If kelp is depleted
     and you have asthma + weariness, you're in serious danger.

anti_serpent_function: |
  Algedonic.AntiSerpent (src_new/scripts/levi_ataxia/levi/levi_scripts/algedonic_defense_1.0/001_Anti_Priorities.lua:725-792).
  Algedonic.Prioritize() calls it on every GMCP affliction gain and loss
  (004_Aff_gains_losses.lua:373, :452) when OUR TARGET is a Serpent in the NDB
  (ataxiaNDB_getClass(target), :108-109) - not when an unknown Serpent attacks us.
  In order, first match wins:
  1. Approaching lock (asthma + slickness + impatience or anorexia) and we can tree (not
     paralysed, not both arms broken, OUR tree off cooldown: ataxiaTemp.usedTree; it read
     tBals.tree, the TARGET's, until 2026-11-01) -> `touch tree` (:733-748). The touch line
     (curing_bals/003) sets the flag on this send too: it no longer needs a `[Curing]` line first
  2. impatience, no paralysis -> `curing prioaff impatience` each time, + `cq all;touch shield`
     at most once per 4 s and only while our shield is down (GMCP Char.Defences, :750-766). The `cq all`
     in front of a redundant touch cleared a held lock-breaker with it. The shield still spends
     equilibrium with asthma up, which holds FITNESS about 3.4 s (kb/CONFLICTS.md #50, open).
  3. hypochondria, no paralysis -> `curing prioaff hypochondria` (:780-783, v4.7.419)
  4. fratricide + scytherus, no paralysis -> `curing prioaff fratricide` (:789-791, v4.7.419)
  PRIOAFF writes no stored priority, so 3 and 4 are right in whichever curingset is active.
  This page used to list eight "key triggers". Two are real: approaching lock -> tree (branch 1,
  older than v4.7.419; the old list said "asthma + slickness + mental", the code checks
  impatience or anorexia) and fratricide + scytherus (branch 4, a prioaff since v4.7.419). The
  "asthma cure" item is the astWear swap below, not an AntiSerpent branch. The other five
  (impulseLockThreat, the two "impulseEnabled" items, a quicksilver re-apply, Ekanelia
  prevention) exist nowhere in the code.

  Persistent swaps (Algedonic.ApplySwaps / RestoreSwaps in the same file; toggles in
  swaps/002_Priority_Management.lua, `aconfig prios`):
  - astWear (on): asthma -> 3 when asthma + weariness and the target is a Serpent (:214-219)
  - astImp (on): impatience -> 1 when paralysis + asthma and we face an Alchemist or Serpent (:153-165).
    Since v4.7.480 (our reading of the user's 'astimp can be implemented', to confirm) not against a Serpent with asthma + weariness up:
    the raise is skipped, an impatience at 1 goes back (Algedonic.AstImpPutBack :124-131; trigger 719 calls it too),
    and astWear's asthma 3 stands. Impatience goes back to 1 on the next gain after the weariness is cured
    (kb/CONFLICTS.md Resolved 2026-11-08, was #74).
  - paraAst (on): paralysis -> 1 when asthma + paralysis + slickness (:206-211)
  - fratLock (on): fratricide -> 4 when fratricide + asthma + slickness (:222-227)
  - hypoImp (on): hypochondria -> 1 and impatience -> 4 when lethargy, nausea or addiction is up too (:190-196)
  - scyPara (OFF by default, swaps/002:37): scytherus -> 2 when paralysis is up too (:139-143)
  Each is restored when its affliction is cured (:274-337). Since 2026-11-08 paraAst, astWear and fratLock (and
  WATER) test the priority first (comment, :168-172): ApplySwaps runs on every gain, and each one re-sent a write
  the server already held, spending the writes the throttle allows. They write STORED priorities into
  whichever curingset is active, and against a detected Serpent class detection switches to the
  in-game `serpent` set, whose priority list has never been captured.
```

## Our first Serpent fight: the spar of 2026-11-07

**The fight.** v4.7.478, raw rounds, one key press per round, 16:47:12-16:48:40. Lock mode (`zz`) first, group mode
(`sr`) from the `say lol what` on (FL 1063). Saibel only cured and never attacked. No kill and no death. Her class
(Depthswalker) comes only from the NDB cache and is UNVERIFIED. The recording (`kb/raw/logs/ours/2026-11-07_164635_Saibel.log`)
and the screen log (`kb/raw/logs/2026-11-07_serpent-spar-saibel.txt`) are one fight (`kb_timing.SAME_FIGHT`), so only the
recording counts. **It is our seat only.** Our costs and our gap are inputs about us. No Saibel number becomes a victim
default, and the gates' holdout waits for the next log from a victim's seat (`kb/mechanics/replay.md` G1-G5 are unchanged,
still FAIL).

**Our costs** (kb/sim/rules_hand.json, MEASURED, client clock, from the game's cost line to the recovery line):

| Ability | Stated (WIKI) | Printed | Median | p10-p90 | n | From the first reply | Rule |
|---|---|---|---|---|---|---|---|
| DSTAB | 2.80 bal | 1.8 | 1.634 | 1.578-1.741 | 24 | 1.75 | `attack.cost.own.dstab` |
| Impulse's BITE | 4.00 bal | 1.7 | 1.563 | 1.477-1.581 | 13 | 1.676 | `attack.cost.own.bite` |
| IMPULSE | 1.70 eq | 1.44 | 1.242 | 1.201-1.289 | 13 | 1.353 | `attack.cost.own.impulse_eq` |
| FLAY | 2.00 bal | 1.7 | 1.530 | - | 1 | 1.65 | `attack.cost.own.flay` (not usable) |
| PINSHOT | 3.00 bal | 1.8 | 1.742 | - | 1 | 1.856 | `attack.cost.own.pinshot` (not usable) |

- An IMPULSE with a venom delivers the bite too and spends BOTH equilibrium (printed 1.44) and balance (printed 1.7):
  13 of 13 (`attack.impulse.venom`; kb/CONFLICTS.md #68). Equilibrium is back first every time, so the bite's balance
  gates the round.
- A FLAY of a rebounding the target did not have still stripped the sileris coating, and its venom landed (FL 283-318;
  `attack.flay.missing`, n=1, alternative "nothing"; kb/CONFLICTS.md #67).
- **The A/B question (open, kb/CONFLICTS.md #69).** Every cost line came in the round's second packet, about 0.09 s after the first reply. If
  that step is on our side (A), the server counts from the cost line, and the medians above are the costs. If the server
  paces its output (B), it counts from nearer the first reply, and our costs are about 0.12 s higher (the "first reply"
  column). The next spar with `aconfig serpent attackfirst on` settles it: under A the round should shorten by about
  0.12 s; under B only the strike line moves earlier on our screen, and the round stays as long.

**The round as played.** Land to land, from one strike line to the next: median 1.965 s (p10 1.772, p90 2.059, n=37;
`attack.gap.own`, not usable as a cost). After a DSTAB 1.977 (n=24), after an IMPULSE 1.925 (n=12), after the FLAY 1.773.
Other Serpents' DSTAB gap is 1.83 (`attack.gap.others.dstab`). So about 0.33 s of each round is dead time. Counted from the
fight log and the screen log, it splits into about 0.12-0.13 s waiting for the next key press (in 38 of 38 rounds exactly one press came
between the `(((( BALANCE` echo and the send), 0.066 s for the first command's round trip, a step of about 0.09 s before
the second and later commands are answered, and about 0.03 s for the commands queued ahead of the attack. From the
send, the medians were: first reply 0.066, purge 0.071, the adder order's refusal 0.161, `g body` 0.167, `g gold` 0.173,
`stand` 0.178, the wield 0.185, the strike line 0.193 (n=38). Under reading A (`kb/CONFLICTS.md` #69), ours to change:
the press wait, the order inside the round and the idle commands; not ours: the costs. Under reading B the server paces
its output, so the order inside the round changes only what our screen shows, and part of the step is cost. The next
spar with `aconfig serpent attackfirst on` decides between them.

**The offense as played (v4.7.478), and what v4.7.479 changed** (the spar fixes, above):
- Lock mode sent eurypteria in 7 DSTABs (FL 339, 384, 651, 834, 879, 928, 973), and a focus or tree of hers followed
  each within about 2 s; that it took the recklessness is INFERRED (`kb/CONFLICTS.md` #65). Now recklessness waits
  for a locked target (the user's rule). It sent xentio in 6 (unchanged).
- slike went out in none of the 39 rounds, so we never gave anorexia and never reached the lock.
- Group mode (`sr`) built asthma + weariness, and the monkshood reaction fired on 8 of 10 monkshood bites, all 7
  masochism impulses among them (`reaction.monkshood.seen`; FL 1275, 1324, 1551, 1596, 1643, 1693, 1943, 2033). This is
  the first capture of the reaction (`kb/CONFLICTS.md` #20).
- No adder was out. The game refused all 39 `order adder kill` orders, and trigger 641 read 18 of the refusals as the
  target leaving: the TargetOutOfRoom timer erased target afflictions in 7 ticks and reset V3 twice. Now the order goes
  only with the adder here, and 641 ignores a refusal while GMCP lists the target.
- The opener's pinshot spent balance, the game held six commands, and the flay behind them was refused without a hold
  (FL 235-257). Now the attack comes straight after the pinshot.
- The rebounding pre-empt fired for a rebounding that never existed (FL 566). Now it needs a rebounding a line showed.
- combatQueue's `g body`, `g gold` and `stand` did nothing in 39 of 39 rounds. The opener now leaves them out.
- Masochism's self-harm lines recorded 2 of 5 (433 read only the revulsion line and the jaw line with "her"). 433 now
  reads the gut and stomp lines too (FL 1329, 1556, 1952).

**Saibel's curing, from our seat** (one opponent, class UNVERIFIED; facts about this fight, never defaults):
- Herb eat to eat: never under 1.506 s (FL 869 -> 916), median 1.665 (47 gaps). Focus to focus: at least 2.417 s
  (FL 963 -> 1050). Tree to tree: 13.99-14.41 s (six trees, FL 422, 735, 1059, 1378, 1719, 2051).
- Her eats: magnesium 29, aurum 10, plumbum 8, ferrum 1, potash 4, argentum none. Her order read magnesium > plumbum >
  aurum > ferrum.
- **Potash has its own clock.** All 4 potash eats fell inside her herb eat to eat: one 0.001 s after a magnesium (FL 415,
  418), three between two herb eats that stayed 1.506-1.707 s apart (FL 682, 910, 1419). This settles `kb/CONFLICTS.md` #11 (now under Resolved, 2026-11-07).
- On an open eat she cured paralysis fast: at the 9 landings that came 1.506 s or more after her last herb eat, 8 were
  eaten within 0.064 s and one at 0.216 (FL 1098-1105) (`ssc.delay.gain.Saibel`, an alternative only, `--ssc-gain saibel`).
- Counted in the spar analysis (not filed as a rule): her paralysis waited for a cure only when our strike came under
  1.506 s after her last eat (16 of 16, her eat still down), and it never lasted to our next attack (0 of 27).

**Open after v4.7.479.** `kb_events` has no attacker-seat stream, so the spar is not in the race table. Another Serpent's
adder in our room counts as ours. ORDER's and BLOCK's balance costs are unknown. The A/B question. A plain BITE's line
and cost. Whether fangbarrier blocks an impulse.

**Open after the 2026-11-08 review.** For the user: the lightwall order (Class-Aware Venom Routing). In game: an impulse of a suggestion already held (deep review); EXECUTE on a prone target, on a standing
one, and BEHEAD (the Finisher); `suggest <t> fratricide`; shrugging with equilibrium down. A FLAY of a MISSING shield taking the coating is open (`attack.flay.missing`), and 706 does not read that
line. Left as it is on purpose: EXECUTE on a standing target. Since 2026-11-09 our anti-class defences answer whoever hits us, not our target (kb/CONFLICTS.md Resolved, was #75), and a due lock-breaker goes before the shield (was #77).
Decided by the user on 2026-11-08 and done in v4.7.480: the clumsiness list, the shrugging equilibrium hold, and
the curing set priorities (kb/curing/server-side-curing.md, "One priority list per set"). The user confirmed astImp beside astWear on 2026-11-09 (kb/CONFLICTS.md Resolved, was #74). Immune to clumsiness means the affliction lands and causes no miss (the user, 2026-11-09). Open: xentio on those classes for the kelp stack alone (#81).
Monks, the user 2026-11-09: "Tekura Monk is kick, punch, punch and Shikudo is kick, staff, staff". Trigger 006 reads this: a first kick reads Monk until the same combo's staff line. Asthma and weariness before the class venom: not adopted. The user said "Depends", usually curare. Curare goes first either way (:938), so the order for a class venom that is not curare got no explicit ruling (Class-Aware Venom Routing).

## Group presses (`sr`, `srd`): target switch, no assumed defence (2026-11-10, v4.7.487)

**The fight.** A group fight at 11:27-11:38 on 2026-11-10, mostly with `sr`. The screen log is
`C:\Users\mikew\OneDrive\Desktop\serp_group.txt` and the fight log is
`<profile>/fightlogs/2026-11-10_112805_Mycen.log` (header "version 4.7.478"). Neither is filed in
`kb/raw/logs/` yet. The client ran **4.7.478**, imported from the stale
`LEVI-Achaea\muddler_project\build` folder, so no fix from v4.7.479-485 was in it: the 13 refused
adder orders and the 6 impulses before a lock are fixed already (v4.7.479).

**What the log showed (counts from the fight log).**
- 52 attack rounds and 55 target changes. 100 presses printed "Target not in room!".
- 7 opening flays met no rebounding and no shield. 4 stripped a sileris coating and 3 delivered
  the venom. These are 7 more rows for `attack.flay.missing` (n=1 in `kb/sim/rules.md`), not yet filed.
- DISPEL printed no cost line: each of the 18 "You point a finger at X to dispel all her
  illusions." lines is followed at once by the next command's reply.

**The user's rules (2026-11-10).**
- "For target absent, during those situations in group mode, I'd much rather move onto the next
  target that isn't Mhaldorian. Switch targets automatically because I set the party leader to a
  person and follow their calls but sometimes they are slow."
- "In group (sr, srd) we should not start out with flaying, we should just hit unless it is a bite
  (need a flay or dstab with slickness) - This factors into rebounding in group (sr, or srd
  aliases) we should probably state in the beginning (new target) they dont have rebounding or
  shield."

**What the code does (serpent/002).**
- `sr` and `srd` call `serp_ekanelia_offense(true)`; every other caller passes nothing. The
  argument sets `serpent.state.groupPress` on each press.
- **Target switch** (`serpent.groupRetarget`). On a group press, before the balance guard: if GMCP
  does not list the target, the new target is the first player in `ataxia.playersHere` who is not
  on `ataxiaTemp.allies` and whose `ataxiaNDB_getCitizenship` differs from our city (the caption
  of the `ct` channel, `ataxia.channels.ct`, as mindnet reads it). "Unknown" is passed over (a
  city mate the NDB lacks would be attacked); "Rogues" is taken. With `ct` unread there is no
  switch. It goes through the `t` alias (so the game target and highlights follow) and echoes
  `GROUP: <old> is not here -- now <new> (<city>)`. No party message. The leader's next call
  sets the target as before. With nobody to take, the round prints "Target not in room!" as before.
- **No assumed defence** (`serpent.onGroupTarget`, last in the "changed target" handler). On a
  group press a new target gets `tAffs.rebounding = false` and `tAffs.shield = false` (016 assumed
  rebounding in tAffs only). So the first round is a DSTAB. A DSTAB that rebounds teaches it
  ("The attack rebounds back onto you!", `serpent/001`), and the next round flays (PRIORITY 1).
  A solo press still assumes rebounding.
- **The coating before a bite** (`serpent.state.coatingUnknown`). A group target's coating is
  unknown, and `checkImpulseEligible()` says no until a line tells it. Slickness on the target
  clears it (rule `defence.sileris.slickness`), and so do a shell forming (442), a stopped bite
  (707) and 706's strip lines (`serpent.onCoatingGone`). In `sr` the lock needs slickness before
  any impulse, and the gecko strip (impatience pair) sends a gecko DSTAB. In `srd`
  (scytherus_attack) the DSTAB's first venom is gecko while the coating is unknown. A solo press
  clears the mark.

**Open.** A target that steps out for a moment is replaced at the next press. A party member of
another city who is not on the allies list can be taken (no party roster is read). Not run in
Mudlet yet.

**A DSTAB into a reflection (v4.7.487, the user: "reflection shouldnt count").** The game says
a prick hit a reflection in two ways: "A reflection of X blinks out of existence." (victim's seat,
X8pRorzR:868-871) and "The attack harmlessly passes through one of X's reflections." (our seat,
2026-11-10 fight log :8426-8432: the prick line, then two such lines, and no "Striking like a
snake" line, so neither prick delivered). `serpent/001` read only the first, so that DSTAB was
recorded as paralysis + anorexia and called to the party during Akri's truelock. Its `reflected()`
now reads both, on prick 1 (nothing recorded, no party call) and on the line after prick 2. When
prick 2 still strikes, its venom is recorded as before (F36). Open: prick 1 lands and only prick 2
hits a reflection; no log shows that case, and the normal branch still records both venoms.

**DISPEL stays once per target** (the user: "dispel should only be once"). New reflections after
the first round ("There suddenly appear to be three versions of Akri", 11:36:38.700) are not
dispelled again; our DSTAB at 11:36:39.228 hit one.

## Theorycraft: the DSTAB against the eat (2026-11-07)

Plan: `~/.claude/plans/if-we-understand-achaea-s-idempotent-sprout.md` (master plan step 7.2, stage 1). Tools only: no
package code changed, and nothing here is a verdict for live code.

**The race, from the four Serpent logs** (`kb/sim/events.md`, `tools/kb_events.py`). A DSTAB and the next attack form a
pair. The strike "wins" when the victim's eat is still down at the next attack. PHASE is the eat's return time minus the
strike's time: a positive PHASE means the eat was down when the strike landed.
- The strike came first in 165 of 194 paired DSTABs (85%). These are the LOGGERS' curing, not ours.
- Golden row, Z5 row 196: PHASE +0.602 at the strike, strike first by 0.567 s. The eat clock (1.613 s) is shorter than the
  gap (1.807 s), so the PHASE decided the race, not the clock lengths. `kb_events.py --check` fails if this row moves.
- The victim's SSC delay has two cases since v4.7.479 (rules `ssc.delay.gain` and `ssc.delay.return`, MEASURED from
  the four logs, drawn by `draw.shape`). An affliction that lands on an OPEN channel: median 0.104 s (p10 0.064, p90 0.198,
  n=23). A channel that comes back with an affliction waiting: median 0.145 s (p10 0.050, p90 0.239, n=163). They
  replace `ssc.delay` (0.10-0.18 uniform). Saibel's open-channel figure from our seat (median 0.055, n=9) is an
  alternative only (`ssc.delay.gain.Saibel`, `--ssc-gain saibel`), never a default.
- A window is not a cause: "winners strike just after a key is spent" is refuted (`kb/mechanics/foundations.md`).

**The CLI** (`tools/theorycraft.py`; every output is MODEL, not a log):
```
# The user's example: two curare/kalmia DSTABs, then gecko/slike, against a Runewarden, medians only
python tools/theorycraft.py --victim runewarden --gap 1.83 --median --script "dstab curare kalmia" "dstab curare kalmia" "dstab gecko slike"
# The same with noise: P(strike first) per race over 400 seeds
python tools/theorycraft.py --victim runewarden --gap 1.83 --seeds 400 --script "dstab curare kalmia" "dstab curare kalmia"
# A real log in the engine's columns, rows 196-260
python tools/theorycraft.py --log Z5 --from 196 --to 260
# A fork: start from Z5 row 204's board and clocks, then send our own actions
python tools/theorycraft.py --log Z5 --at 204 --then "dstab curare vernalius" --median --seeds 40
```
- Actions: `dstab V1 V2`, `bite V`, `impulse SUGGESTION V` (v4.7.479: one of the 15 trivial suggestions, rule
  `attack.impulse.suggestions`; the bite comes in the same packet and its balance sets the next action, and a second
  impulse also waits for our equilibrium), `flay [shield|rebounding] [V]`, `give AFF`, `wait SECONDS`.
- Our own gap (v4.7.479): `--gap` takes seconds, or `raw` (1.965, our land-to-land as played, `attack.gap.own`),
  `queue` (our costs, as if each round fired from the server queue: DSTAB 1.634, an impulse round 1.563),
  `queue-late` (the same costs from each round's first reply: 1.750 and 1.676) or `others` (other Serpents' median gap
  after each kind, DSTAB 1.83). The CLI does not pick one: which a fight runs is a choice, and where the 0.09 s step
  falls is open. Every run prints an OURS line with the spar's figures. `--flay-missing nothing` runs the alternative of
  `attack.flay.missing`. The FLAY line cites that rule, and ALT lists it, only when a FLAY naming a missing defence met the
  coating (the attack event's `coatUp`). A scripted run never has the coating, so there the flag changes nothing and the
  page says so. `attack.gap.others.bite` (n=21) is an impulse-round gap: each of the 22 BITEs came in an impulse's packet,
  and no plain BITE is measured.
- Victims: `runewarden` (FITNESS and Dagaz, Claes's clocks), `alchemist` (Salt, Elmer's), `depthswalker` (Accelerate,
  Nikita's), `monk` and `shikudo` (Elmer's clocks). A fork takes the log's victim (az, Z5, g, X).
- With noise, the example's first race gives P(strike first) = 0.11 (44 of 399 paired seeds, seed 1 on); over 4,000
  seeds it is 0.10 (395 of 3,987). (Re-run for v4.7.479, after the SSC delay split; it was 0.12 and 0.11.) A seed with no eat spent before the next attack is unpaired and not counted. Each
  race's odds are counted by its label (`1->2`), not by its place in the list, and the line says in how many seeds that
  race exists at all.
- The draw shape is a choice (rule `draw.shape`, ASSUMED): a clock is drawn from its quantiles, each tail held to one
  p10-p90 width past p10 or p90, because a log's min and max are often a lost line (`clock.rebounding` max 250.253).
  `--clock-draw normal` runs the alternative. It moves the P above to 0.07 (259 of 3,983). Read the second decimal of a
  model P as noise: at 400 seeds one standard error is about 0.016, so two runs can differ by about 0.03, and the shape
  alone moved this P by 0.034. A `--median` fork rests on the shape too: a clock already running at the row takes the
  median of the part of its spread above the time already run, and the shape sets that part. The `--seeds` runs of a
  `--median` page draw. A SEEDS line says how: the tree's pick and the gap as `--tree-pick` and `--gap-sd` set them, and
  the first Dagaz tick when the log prints none. An ALT value marked `--median` is the median run's only.
- Each run lists the ASSUMED, WIKI and PLAYER rules it used, the MEASURED clocks it could only sweep, and an ALT line for
  each rule whose alternative ran. `--median` runs `ssc.phi` 1.0 and `tree.pick` priority, and for a Runewarden with no
  printed Dagaz tick also `class.dagaz.phase` half a period. Another Serpent's gap prints a GAP line: its median 1.83 only;
  a draw adds the gap's own noise (`--gap-sd`, rule `attack.gap.own.sd`), not that rule's p10-p90 spread. That rule shows
  as ASSUMED only when a gap really is drawn with noise: a drawn run or `--seeds`, `--gap-sd` above 0, and a non-wait
  action or a fork's first gap. A run that the
  horizon cuts prints a HORIZON line: the script stops at the horizon. If the eat that was down at the last action that
  ran is still down at the horizon, the run holds until it comes back, and the line gives that time; else the run stops
  at the horizon. If no action ran, the line says so. A race is unpaired
  "because the horizon cut the script" only when the cut actions hold an attack. A negative `--gap-sd` is refused, and
  with `--gap-sd 0` no line says the gap is drawn. An affliction that only the lungs or the elixir cures prints NO CHANNEL (the
  engine runs neither), and says when no random cure can take it either (pressure).
- A gap under the floor is refused: 0.3 s (BUNDLED, two lines within 0.3 s are one attack), or `--gap-floor`. A fork
  with no `--gap` runs 1.83, so a `--gap-floor` above 1.83 needs a `--gap` too.
- A fork starts from the row's own state:
  - the board and the channel clocks (drawn past the time already run);
  - the victim's balance and equilibrium, from "Equilibrium used: 3.40s." and the prompt's flags (az prints no flags).
    A second cost line that lands while one is open ends it, and only its own cost counts: a CONCENTRATE after
    disrupted (az 2995: back at 3034, 0.03 s from its own 2.00 s), and g's kata costs, whose per-limb return lines the
    stream does not read. The impulse's cost line is the exception: it adds (X 529 and 575 came back together at 638).
    A prompt that shows a flag down with no line for its return (Z5 5468-5590: disrupted, then death) keeps it down;
  - the defences the logger keeps. A FLAY of the shield in the log brings the shield back one re-raise delay later. The
    logger's own movement or action dropping its shield (Z5 78) is not a FLAY, and a shield down with no FLAY stays
    down. A skullcap or malachite smoke brings rebounding (rule `defence.rebounding.smoke`: 48 of 49 smokes, 7.59-8.59 s
    later). An apply of the coating with no hardening line yet brings the coating 10.0 s after it (rule
    `defence.sileris.harden`: 43 of 49 applies, 9.75-10.12 s). A pet's bite that meets the coating proves it up (X 38).
    Slickness strips the coating as it lands (rule `defence.sileris.slickness`: 8 of 8 in the logs, all DSTABs, X
    144-146; the engine does the same for a give and a FLAY's venom), and an apply does not harden while slickness is on
    at its 10 s mark (rule `defence.sileris.slickness_harden`: none of the 43 that hardened, 5 of the 6 that did not; the
    sixth, Z5 1891, had slickness cured 0.1 s before the mark). The START line says a pending coating hardens only if
    slickness is off by then (az 3779), and the timeline prints `W sileris.unhardened` when slickness stops it.
  - The first forked action comes one gap after the log's last attack, drawn like every other gap. Under a per-kind
    preset (`queue`, `queue-late`, `others`) it is that attack's own kind's gap: X 552's last attack is the FLAY at X
    545, so `--gap others` gives +1.64 (1.642), not +1.83 (`start.firstGap`, tools/theorycraft.py:1423-1442). A gap whose
    longest draw (median + 3 x `--gap-sd`, held at the floor) still lands at or before the fork row decides nothing: the
    page reads "at or before the row" (az 654, a FLAY 3.33 s back), and the gap's rules are not listed. A `--gap-floor`
    above a first gap it would change is refused: "Give a --gap-floor at or under it, or a numeric --gap."
  - A row after the log's last prompt (the death line, or a row with no event after it, X 6614-6631) cannot be forked.
    A later physical row of a wrapped prompt is that prompt's own row (X 590 is the board row of prompt 589).
- `--random-pool package` runs the package's tree pool instead of the NoRandomCure reading; `--flay-order auto` runs the
  engine's own order for a FLAY that names nothing (shield, else rebounding, else sileris) instead of the named target.
- A FLAY of the shield or rebounding also rips the sileris coating when it is up: 23 of 23 such packets in the four logs,
  none of the 33 made with it down (rule `attack.flay.coating`; the quicksilver shell of Z5, g and X counts too).
- The fork example above (Z5 row 204, `--median`): the eat spent at row 154 comes back at +0.61, Salt cures the paralysis
  at +0.10, and the forked DSTAB at +1.83 lands with the eat down again (strike first by 0.41; the log's own DSTAB at row
  248 came at +1.81). Over 40 seeds the log's race `row 196->#1` is strike first in 40 of 40.

**What it cannot say.** It has no win rates and no "best" offence. It describes the four loggers' curing and never predicts
a live opponent's herb. Our own costs are measured since the 2026-11-07 spar (one fight, our seat), but our gap is a
choice as well as a cost, so `--gap` is still required in a scripted run. The spar gives no victim input: Saibel's
numbers are not defaults, and the gates' holdout waits for the next log from a victim's seat.
The stream reads every gain line as a gain: 67 of the 662 gain lines in the four logs (10%) name an affliction that is
already on the board a fork reads there (the prompt, plus the gain and cure lines after it), and no logger tag is next to
them. 17 are fratricide from the pet's bite while fratricide is on (Z5 900-901: the viper's bite, then "Something subtle
and yet insidious overcomes you."); g 320 and 1479 are darkshade under DARK. The gain counts of `kb/sim/events.md`
include them. A fork's board does not change, because it holds them already.

## Implementation Notes
```
Lines our triggers read (patterns from the code; the victim-side ones below are not captured as
written, and four of our offense's lines are captured since 2026-11-07, see below):
- Victim side (determine_class/002_Serpent_Class_Grab, rewritten 2026-11-08): the first prick, the
  second prick ("Striking like a snake, X follows the first attack with another."), the impulse's
  bite ("X sinks his fangs into your body and you wince in pain."), the impulse's command ("X fixes
  his gaze to yours and hisses a sharp command."), the flay ("X flays away your shield defence."
  or aura of rebounding), the snap and the hypnotise stare. These are in the four Serpent logs; the
  whip-crack line is left out by the one-row limit. This page used to list "jabs you with a dirk
  coated in" and "bites you viciously"; neither is in any trigger or capture.
- Our offense: dstab (serpent/001), bite (009), reaction (016), impulse (017), relapse (018);
  see "What the offense records on the target". dstab, bite, reaction and impulse are captured in
  our spar (FL 359, 590, 1275, 584), each with its +tar row; relapse is not.
- Fangbarrier on the target: up on "A supple metallic shell of quicksilver has formed around <T>."
  (442; CONFIRMED in the Infernal logs, about 10 s after the application) and on "A supple purple
  shell of sileris berry juice has formed around <T>." (442, since 2026-11-08; Lauryyn log, kb/raw/logs/ours/2026-11-03_080944_Lauryyn.log, 955). Our
  bite refused (707, code only). Stripped (706): our flay lines and "The protective coating covering
  the skin of <T> sloughs off." (CONFIRMED, c.iJVmpL log, 1078). Since 2026-11-08 706 checks that it
  is our target's coating (it erased ours on anyone's). It reads both forms of the rip: "... is ripped
  away with their protections." (FL 308, after a FLAY of a rebounding that was not there, FL 305) and
  "... ripped away along with his protections" (Lauryyn log 74). The adder line "fangs sinking into his fang
  barrier defence" is NOT read as a strip: it left the coating up (kb/raw/logs/2026-11-03_shikudo-group-alias.txt:3570,
  ripped by a flay at 3880). On the victim's seat a pet's strip prints "The protective barrier coating
  your skin dissolves." (az 16-18); the third-seat form is open.
- Our FLAY of the shield erases only the shield on the tracker (serpent/003, 335) and leaves
  rebounding up. It does rip the coating: rule attack.flay.coating, 23 of 23 (az 2235-2236), and 706
  reads that from "You flay away X's shield defence." Only serpent/010's second-assault line proves both defences down.

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
- IMPULSE: a trivial suggestion on 1.70 s of equilibrium (printed 1.44); with a venom it bites too and spends balance (13 of 13, our spar); asthma + weariness matter only to the monkshood reaction
- Phase hides them; attacking unphases them
- Garrote is the PvE basher attack only, NOT a PvP finisher (execute handles PvP)
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
