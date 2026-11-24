# Safety Systems

## Danger Level Assessment

Function: `ataxiaBasher_dangerLevel()` in `basher/001_Bashing_Functions.lua`

Returns one of: `"attack"`, `"shield"`, `"flee"`, `"wait"`

### Decision Tree

```
1. bashFlee == true?                    → "wait"
2. hpp == 0?                            → "wait" (invalid state)
3. aeon, paralysis, or peace?           → "wait" (can't act)
3b. SHIELD-SAFE ROOM (v4.7.519, any area): a stand that replaced a
     retreat, or any stand in a shield-safe room → ataxiaBasher_lastStand
     ("shield"/"wait"); no stand, hpp ≤ fleePct or damage spike, and every
     denizen shield-safe → shield sent, "wait" (no disengage, no flee)
4. No-flee area (World Tree/Mnemosyne)?
     ├─ hpp ≤ fleePct OR damage spike:
     │    ├─ swarm.disengage() worked → "wait"  (spend the round LEAVING THE ROOM)
     │    └─ refused (no route back)  → fall through: fighting in place is the answer
     ├─ LAST STAND (v4.7.486): critical + no retreat + no known
     │    shield-breaker or shield-pass here → "shield", attacks held until 70%
     │    (85% and cured in a shield-safe room, v4.7.519)
     │    (ends early if hits pass the shield, v4.7.506, unless the shield
     │    blocked another denizen here in the last 10 s, v4.7.514)
     ├─ damage spike + can shield       → "shield" (one-cycle guard, keep attacking)
     └─ else                            → skip both flee checks below
5. hpp ≤ fleeThresholdPct (25%)?        → "flee"
6. Extreme damage rate detected?        → "flee"
7. hpp ≤ shieldThresholdPct (40%)?      → "shield" (if can shield)
8. Otherwise                            → "attack"
```

**Step 4's HP branch did not exist until v4.7.243.** `hpp <= fleePct` lived *only* in the
non-no-flee arm, so at 5% HP in Mnemosyne this function returned `"attack"` — which is how we
came to swing Valafar at 1024 HP of an ~18,700 pool. The area is what cannot be fled; the ROOM
can be left, and that is what the swarm ladder is for. A refusal falls through deliberately:
no validated route back means fighting in place is genuinely the best available answer, and
muting the basher there would be lethal.

**`canShield()` no longer gates the alarm**, only the shielding. It returns false whenever a
room denizen is on the area target list — i.e. every real tower fight — so gating the alarm on
it made the whole branch unreachable.

### The last stand (v4.7.486, rebuilt v4.7.490)

`ataxiaBasher_lastStand(hpp)` (`basher/001`:769) decides the round in step 4, after the disengage
(001:638-655). It returns `"shield"`, `"wait"` (build no round) or nil (no last stand). A new stand
starts when `ataxiaBasher_lastStandWanted(hpp)` (001:751, no side effects) is true.

From a death (2026-11-10, `kb/raw/live/mnemosyne-tashla-prey_2026-11-10.txt`): Prey
made both tash'la follow our one retreat, the retreat back was refused, and `canShield()` was
false, so from 28% to 15% health the only action was another attack. Sips and potash healed about
1,030 HP/s against about 2,000 in; the last round was 4,592 into 4,592 health. A shield stops the
2,000. A new stand starts when all of these hold:

- a no-flee area, `ataxiaBasher.lastStand ~= false` (`bash laststand on|off`), no Bravado, no Rimewrought;
- no shield up yet, and no cooldown (`ataxiaTemp.lastStandCoolUntil`, 10 s after a stand that gave up or whose shield broke);
- critical health: HP% at or below the swarm's `escapeAt` (35), or raw HP at or below its `panicHp`
  (3000) -- the two lines the escape ladder uses (`ataxiaBasher_lastStandCritical`, 001:721);
- no denizen in the room on `ataxiaBasher.shieldBreakers`;
- the swarm cannot take us out: it is off, or `S._escapeRouteReady()` is false, and no recovery or
  tumble is under way;
- not prone on a bad leg (v4.7.521, `ataxiaBasher_proneNoShield`, 001:287): checked last, and its
  reason is printed ("NO SHIELD: no last stand -- prone on a bad leg: the stand is refused, so no
  shield."), because then no shield can go up (see "The shield needs us standing", below).

**It ignores `canShield()` on purpose.** That function assumes every target-list denizen breaks
shields; the last stand finds out. Trigger "Shield Broken By Denizen"
(`denizen_attacks_misc_lines/029`, substring `your magical shield`) calls
`ataxiaBasher_onShieldLine` (001:894): a line that starts with the name of a denizen in the room
adds that name, lowercased, to the saved `ataxiaBasher.shieldBreakers`. Our own lines (`You...`),
rebounds and players are ignored. One sample line exists: "A small brown lemming rips apart your
magical shield defence with its claws." A tash'la raze line is not yet known.

**The hold starts at the first send (v4.7.490).** From a death (2026-11-11, two errant frost
elementals, `kb/raw/live/mnemosyne-frost-elemental-laststand_2026-11-11.txt`): v4.7.486 sent
`touch shield` at 24% and then, for the 3 s resend window, answered "no last stand". The danger
check fell through to `"attack"`, and every attack round sends `queue addclearfull`, which deleted
the queued shield. A bite the server already held also ran first. The stand printed, no shield went
up, and in the 5.4 s after it we bit twice and culled once; a 750 cold vapour at 750 HP killed us.
Two elementals hit 1,400-3,334 cold plus 950-1,070 blunt (the shadow line) a round. Now:

- From the first send until the stand ends, every round is `"shield"` or `"wait"`, never `"attack"`.
- A send clears the queue first: `ataxiaTemp.lastStandFlush` makes the shield branch of
  `ataxiaBasher_attack` (001:187-200) pass `flush` to `ataxiaBasher_queueShield` (001:298), which
  sends `cq all` before `queue addclear freestand touch shield`, and, when prone,
  `queue prepend eqbal stand` after both (v4.7.521). Not in lava, where `onLava`'s queued escape
  lives in the queue.
- While the shield is down: `"wait"` for `LAST_STAND_RESEND` (3 s) after each send, then send
  again. After `LAST_STAND_TRIES` (2) sends with no shield, the stand ends ("the shield did not go
  up after 2 tries") with the 10 s cooldown, and the basher attacks.
- While the shield is up: `"wait"`. In a no-flee area the attack loop also keeps the HP>=70 gate
  while `ataxiaBasher_lastStandHolding()` (001:782) is true (001:211).

`ataxiaBasher_lastStandHolding()` (001:782) ends the stand at `ataxiaBasher.lastStandRelease` (70%,
`bash laststand release <pct>`), after `LAST_STAND_MAX` (30 s), when a shield it SAW up is down
(broken; 10 s cooldown), or when hits pass the shield (below). Each end prints
`LAST STAND over (<why>) -- attacking.`. The state is `ataxiaTemp.lastStandAt`, `lastStandSentAt`,
`lastStandSends`, `lastStandUp`, `lastStandUpAt`, `lastStandPassHits`, `lastStandCoolUntil`,
`lastStandFlush`, and since v4.7.519 `lastStandSafe` and `lastStandSafeSaid`, never saved. In a
shield-safe room the release is not 70% ("Shield-safe denizens", below).

**A shield that rose does not always block (v4.7.506).** A manifested nightmare (Mnemosyne
denizen, 2026-11-20, `kb/raw/logs/2026-11-20_mnemosyne-nightmare-death.txt`) landed 3413 psychic,
1001 cutting, three colds of 2755-2925 and the killing 1659 psychic with our shield up. The game
printed no shield-break line, so `ataxiaBasher_onShieldLine` learned nothing, the shield read "up"
to the end, and the stand held every attack waiting for 70% (about 1,390 HP/s in, about 920 healed;
`kb/mechanics/mnemosyne-affixes.md`, "The manifested nightmare"). The line that proves a shield
fails is a `Health lost:` line while it is up. Trigger 351 calls `ataxiaBasher_lastStandHit`
(001:956) for each one:

- Only a blockable type counts. `unblockable` and `raw` never do (a shield stops neither, from
  anyone). A hit within 0.5 s of first seeing the shield up does not count: it can share a packet
  with the shield line.
- The second counting hit ends the stand ("<type> hits pass the shield") with the 10 s cooldown
  and stores the room in `ataxiaTemp.shieldPassRoom`.
- **Unless the shield is still blocking someone (v4.7.514).** The shield is per denizen: in the oryx
  death (2026-11-24) the oryx's charge passed it while the rattlesnake "hurls itself against your
  shield in a futile attempt to harm you.", and ending the stand let the rattlesnake's trips land.
  Trigger `denizen_attacks_misc_lines/030` (`^(.+) hurls itself against your shield`) calls
  `ataxiaBasher_onShieldBlocked` (001:1026), which stamps `ataxiaTemp.lastStandBlockedAt`, the room
  and the denizen while a stand runs with the shield up. If that stamp is under 10 s old and in
  this room, the pass hits do not end the stand (001:992): it prints "LAST STAND holds: ..." once.
  The cap, the release health and a broken shield still end it.
- `ataxiaBasher_shieldPassHere` (001:943) reads that room. While it holds, `lastStandWanted`
  (001:751) starts no stand and `ataxiaBasher_canShield` (`can(x)/002`:20) refuses every shield, so
  the spike and shield-threshold branches of `dangerLevel` stop shielding there too. The room is
  forgotten on a room change (a `gmcp.Room.Info` handler, with the read as a backstop) and when the
  basher is off. Session state, never saved.

Tests: `test_basher_noflee.lua`, the shield-pass cases.

**The shield needs us standing (v4.7.521).** Live probe, OURS, 2026-11-24
(`kb/raw/live/shield-touch-prone_2026-11-24.txt`): sitting, a `freestand` TOUCH SHIELD is held, a
`free` one is refused "You must be standing first.", and after "You stand up." the held entry runs
on the same tick. The prone handler (`ataxia/004_Aff_gains_losses.lua`, `aff == "prone"`) queues ONE
`queue prepend eqbal stand` when prone lands; the stand's `cq all` deleted it, so the shield waited
for a stand that never came, and after two tries the stand gave up at critical health. Now every
basher shield goes through `ataxiaBasher_queueShield(flush)` (001:298): an optional `cq all` (not in
lava), then `queue addclear freestand touch shield`, then, when `ataxia.afflictions.prone`, a
separate `queue prepend eqbal stand`. Two entries on purpose: a `;` chain is split by Mudlet, and a
shared `lv*` alias (`ataxia_queueChain`) can be rewritten by another press before the entry runs.
Its callers: the shield branch of `ataxiaBasher_attack` (the last stand and the spike guard), its
resend, `ataxiaBasher_safeStandBegin` (001:1265), `ataxiaBasher_executeFlee` (both shield sends,
001:1703) and `ataxiaBasher_checkPlayerFlee` (001:1817); the full phial lock
(`mnemosyne/004_Parsers.lua`, `M._phialLockResponse`) calls it only when prone.

Prone on a bad leg (any damaged, broken or mangled leg: the swarm's `S._oneLegOut`, or the same
three keys per side when the swarm is not loaded) the stand is refused, so the helper sends nothing
and returns the reason. Then: no new last stand starts (`lastStandWanted`, 001:763); a stand already
on whose shield is not up ENDS on its next round (001:860, no cooldown, so a stand may start again
once we are up) and `safeStandBegin` ends a shield-safe one and returns false, so the swarm's ladder
tumbles instead (the tumble needs no legs, v4.7.513). Holding would only keep the attacks and the
ladder parked behind a shield that cannot rise. A stand whose shield is already up keeps holding:
being knocked down does not drop the shield. The spike guard's one-cycle shield says why
("NO SHIELD: ...", throttled to 5 s) and falls through to the attack, as under Bravado. Tests:
`test_prone_shield.lua`.

Open: whether tash'la raze a shield; what the hold does against a pool that heals the denizens
while we wait (Sanguine Restoration). Tests: `test_basher_noflee.lua`, "the last stand".

### Shield-safe denizens (v4.7.519)

The maintainer (2026-11-24): "there are some mobs who cannot break shields... this has to be tracked
so we know when to touch shield instead of running". The log
(`kb/raw/live/mnemosyne-shield-safe-mobs_2026-11-24.txt`, a Prey room): a savage boar and a fearsome
lion "hurls itself against your shield in a futile attempt to harm you." seven times in 6 s and did
nothing; the stand let go at 72% ("LAST STAND over (health back to 72%) -- attacking.") and the
attack dropped the shield. Code: `basher/001`, section "SHIELD-SAFE DENIZENS" (001:1038-1329).

**The record (saved).** `ataxiaBasher.shieldRecord[key] = { blocked = n, broke = n }`, saved with
`ataxiaBasher` (the `basher` row of `.claude/projects/persistence/README.md`). A missing table or
entry reads as zero, so the new key needs no migration. `key` is `ataxiaBasher_mobKey(name)`
(001:1064): lower case, trimmed, a final period and one leading `a `, `an ` or `the ` cut, so the
trigger's "A savage boar" and the room list's "a savage boar" are both `savage boar`.

- `blocked` +1 per line of trigger `denizen_attacks_misc_lines/030` (`^(.+) hurls itself against your
  shield`), stand or not: `ataxiaBasher_onShieldBlocked` (001:1026) calls `ataxiaBasher_noteShieldBlock`
  (001:1154) first. The line itself proves the shield up, so it does not ask `ataxia.defences.shield`.
  The trigger's folder runs only while the basher runs (genrunning/003), which is when the record is in
  scope; shield lines outside the basher are not recorded.
- `broke` +1 (`ataxiaBasher_noteShieldBroke`, 001:1167) for a shield-break line that starts with the
  denizen's name (trigger 029, `ataxiaBasher_onShieldLine`, which also still fills the old
  `ataxiaBasher.shieldBreakers`), or for a hit THROUGH the shield: trigger 351 calls
  `ataxiaBasher_shieldHit` (001:1238) on every `Health lost:` line while the basher runs. It counts when
  the shield is up, the type is blockable (not `unblockable` or `raw`), and the shield was first seen
  up at least 0.5 s earlier (`ataxiaTemp.shieldUpSeenAt`, stamped by every danger check through
  `ataxiaBasher_noteShieldState` (001:1181) and by the block line). `ataxiaBasher_shieldHitWho`
  (001:1218) lays it on a denizen: the nearest line above that is not a `Health lost:` line (read with
  `getLines`, 4 lines back) names exactly one hostile denizen of the room, by its whole key or by its
  last word of 4+ letters ("The nightmare convulses..."); or the room holds one hostile denizen.
  Anything else lays it on no one and returns the reason. **Never on every denizen in the room**: in
  the oryx death the rattlesnake was blocked while the oryx passed, and one wrong `broke` bars a
  denizen for good.
- **SHIELD-SAFE** (`ataxiaBasher_shieldSafe`, 001:1081): `blocked >= ataxiaBasher_SHIELD_SAFE.MIN_BLOCKED`
  (2), `broke <= MAX_BROKE` (0), and no `shieldBreakers` entry with the same key. A room is shield-safe
  (`ataxiaBasher_shieldSafeRoom`, 001:1119) when it holds at least one hostile denizen (own denizens
  left out, `ataxiaBasher_isOwnDenizen`), every one is shield-safe, and it is not the shield-pass room.
- `bash laststand` lists the record ("blocked/through", SAFE marked); `forget <name>` and `forget all`
  clear it along with the breaker list.

**The shield instead of the retreat.** `ataxiaBasher_safeStandBegin(hpp, cause)` (001:1265) starts a
stand that REPLACES a retreat (`ataxiaTemp.lastStandSafe = true`): it sends `cq all` (not in lava) and
`queue addclear freestand touch shield` itself (nothing if the shield is already up), and prints
`SHIELD-SAFE ROOM: <cause> -- <names> never got through the shield; shielding instead of leaving,
attacks held until <gate>.`. It refuses, with a reason, when: the basher is off; `bash laststand off`;
Bravado or Rimewrought; paralysis or aeon; the stand cooldown runs; the swarm is recovering, a tumble
is in flight or its escape owns the moment; or the room is not shield-safe. Two callers:

- the swarm's low-HP ladder, `S.onVitals` (`mnemosyne/009`:3099), before the bound wait, the Roll Hide
  panic and the retreat (`.claude/projects/mnemosyne/07-explorer.md`);
- the danger check, step 3b above: `ataxiaBasher_safeStand(hpp)` (001:1317, called at 001:621) where
  `dangerLevel` would disengage or flee (HP at `fleeThresholdPct`, or the damage watchdog), in every area.

On any refusal the old ladder and the old danger check run unchanged. The resend after 3 s and the
give-up after 2 sends are the last stand's (`ataxiaBasher_lastStand`).

**The release in a shield-safe room.** `ataxiaBasher_lastStandHolding` (001:801) asks
`ataxiaBasher_standSafeHold()` (001:1133): the room is shield-safe and no hit passed the shield in this
stand. While that holds, ANY last stand (also the old one that started because no retreat was left,
the log's case) does not end at 70%. It ends at the recovery gate (`ataxiaBasher_shieldSafeRecovered`,
001:1142: the swarm's `S._mayReturn()`, `returnAt` 85% and cured; without the swarm, `RECOVER_PCT`
85%), at `STAND_MAX` (120 s, not 30), or when the shield is seen down. It prints once "LAST STAND holds
past 70%: every denizen here is shield-safe (...) -- attacks held until 85% and cured.". When the room
stops being safe (an unknown or unsafe denizen comes in) the old rules apply at once: a stand that
replaced a retreat ends ("... -- back to the escape ladder") when the ladder can leave, else it becomes
an ordinary stand. A blockable hit through the shield in a stand that replaced a retreat ends it at
once, with the cooldown and the shield-pass room, when the ladder can leave (001:972).

Limits: a hit whose attack line names no room denizen, in a room of two or more, marks no one (the
stand still ends or loses its safe hold). The shield-up stamp is refreshed only by danger checks, block
lines and `Health lost:` lines, so a shield dropped and raised between two of them can count the first
hit after the rise against a denizen (the safe direction). Records are per name, not per area: two
denizens with one name share one record. Not tested in the game. Tests: `test_shield_safe.lua` (11),
`test_swarm_tactics.lua` ("asks for a shield-safe stand"), each part broken back.

### Extreme Damage Rate Detection (rewritten v4.7.243)

Function: `ataxiaBasher_isDamageRateExtreme()`.

The original test was `net HP delta over 5s >= maxhp * 0.6`. In the caves-beneath-Kuthalebak
death (~2,150 HP/s sustained against an ~18,700 pool) it could not fire, for three independent
reasons:

1. **Healing subtracted from its own samples.** The feed was `ataxia.vitals.oldhealth - hp` per
   prompt, so a prompt that took 2000 and sipped 1500 recorded 500 — and a net-positive prompt
   recorded nothing at all. The harder we cured, the safer we looked.
2. **The bar was an absolute fraction of a large pool** — 11,220 damage inside five seconds.
3. **It was only ever evaluated inside `ataxiaBasher_attack`, below the three holds**, so it fell
   silent precisely while an escape was in flight.

| Piece | Now |
|---|---|
| Feed | `bashStats_recordIncoming` → `ataxiaBasher_recordIncoming` (trigger `351_Health_Lost_By_Type`) — the damage **before** healing |
| Old feed | kept as a floor in its own window (`ataxiaBasher_dmgSamples`), since the type line does not exist everywhere |
| Combination | `ataxiaBasher_incomingRate()` takes whichever window reports MORE, divided by the elapsed span **clamped UP to `ataxiaBasher_dmgMinSpan` (3s)** |
| Test | time to death: `hp / rate <= ataxiaBasher.dangerTTL` (default **6s**) |
| Legacy test | kept as an OR, so this can only be *more* sensitive than before |
| Also called from | `S.onVitals` (`mnemosyne/009`), which runs every prompt and reads no holds |

`ataxiaBasher_secondsToLive()` exposes the projection for display/diagnostics.

**A burst is not a rate (v4.7.253).** v4.7.243 clamped that divisor to a *minimum* of one
second, so a fight three seconds old would read at its true rate rather than three fifths of
it. Correct for sustained damage, badly wrong for a burst: blows landing together were divided
by the 1s floor and reported as several times the sustained rate — and in a crowded room every
round looks like that. Worked against a live round (925 magical + 1384 cold at the same
instant, 13,678 HP):

| Divisor | Rate | Time to live | Result |
|---|---|---|---|
| 1s (old) | 2,309 HP/s | 5.9s | **trips** |
| 3s (new) | 770 HP/s | 17.8s | quiet |

The alarm had become one that fired on essentially every prompt at 60–83% HP, with the escape
ladder thrashing between rooms and, in one log, abandoning a fight we were winning. Clamping
the divisor **up** to a real measurement window damps a burst to its honest contribution while
leaving genuinely sustained damage untouched — its samples really do span the window, so
2,150 HP/s still reports 2,150 HP/s and still trips.

**Both alarms are throttled (v4.7.253).** `DYING FAST` sat *above* the emergency cooldown in
`S.onVitals`, so it printed whenever the condition held rather than when we acted — dozens of
duplicate lines per fight. It now prints only after the cooldown gate passes and only when the
*rate* (not the HP threshold) triggered the escape. The no-flee `DANGER: … fighting on` echo is
(since v4.7.514) "both arms out -- the weapon attack is refused" instead while `ataxiaBasher_weaponRefused()`
holds, and it is throttled to 5s, because it is evaluated on the attack path and otherwise printed every round
of a fight we had already decided to stand and fight. **An alarm nobody can read past is not an
alarm.**

Time-to-death is the only figure that means the same thing at every pool size: against 2,150 HP/s
it trips at ~12,000 HP — roughly eleven thousand HP earlier than we died — and it does not need
retuning when the pool changes.

### No-Flee Areas

Function: `ataxiaBasher_isNoFleeArea(area)` in `basher/001_Bashing_Functions.lua`

Some areas cannot be fled — there is nowhere to `goto`. In these areas the danger
level **never returns `"flee"`**: an extreme-damage spike or low HP shields instead,
and the attack loop keeps swinging through the shield (the HP≥70 re-attack gate in
`ataxiaBasher_attack()` is dropped for no-flee areas, so it guards reactively rather
than pausing). **Except during a last stand (v4.7.486)**, which keeps the gate until health is
back; see "The last stand" above.

**Swarm-retreat is NOT flee.** The Mnemosyne swarm tactics (`mnemosyne/009_Swarm_Tactics.lua`)
deliberately step one room back from a 3+-mob room to funnel followers — a TACTIC, executed
via the explorer's tactical-move machinery (`M._tacticalArm`), never via `executeFlee`.
`dangerLevel()` is untouched: it still never returns `"flee"` in a no-flee area, the shield
ladder still applies, and none of the flee state (`bashFlee`/`fleeOriginRoom`/`fleeReturning`)
is used. The tactic's own gate is `ataxiaTemp.swarmHold` (attack-dispatch hold while a pull
chain is queued), with its own timeout and reload-safety clears.

**At low HP the swarm module also supersedes shield-in-place** (v4.7.114+): at
`swarm.escapeAt`% (default 35, HP-gated only) it flies to hover outdoors / retreats one room
indoors instead of shielding — `touch shield` needs a working arm, which is exactly what a
chip-down death takes first. The shield ladder remains the fallback when no escape route
exists, and SLC's both-arms-broken flee is inert inside the tower (fixed-direction blind
runs; the swarm module owns tower escapes).

| Area | Detection |
|------|-----------|
| the Fathomless Expanse of the World Tree | exact `gmcp.Room.Info.area` match |
| Mnemosyne (tower-climb mod) | `ataxiaBasher.inMnemosyne` flag |

**Mnemosyne detection.** Mnemosyne is an unmapped instance — `gmcp.Room.Info.area`
is `""`, so it cannot be matched from GMCP. Instead the `351_Mnemosyne_Survey`
trigger (`^You are in .*Mnemosyne`) sets `ataxiaBasher.inMnemosyne = true`, and
`ataxia_Room_Update()` clears the flag on entering any real (non-empty `area`) room.
Inside the tower `area` stays `""`, so the flag persists across floors.

**Mitigation-first battlerage supports the no-flee climb.** Since Mnemosyne can't be
fled, hit-prevention matters more than kill speed. When `inMnemosyne` is set, the
Blademaster battlerage rotation reprioritises to fire Daze (→ Stun, mob does nothing
4s) above its damage abilities, reducing incoming damage during the shield-and-swing
survival loop. See [battlerage-pve.md](battlerage-pve.md).

## Flee Execution

Function: `ataxiaBasher_executeFlee()` in `basher/001_Bashing_Functions.lua`

1. Set `bashFlee=true`, `paused=true`
2. Save `fleeOriginRoom` (current room)
3. Start circuit breaker timer (20s)
4. Clear command queue (`cq all`)
5. Check movement-blocking afflictions (paralysis, entangled, webbed, impaled, transfixation, stun)
   - If blocked: shield and wait for cures (through `ataxiaBasher_queueShield`, so a prone body is
     stood first; v4.7.521. TOUCH SHIELD is not usable entangled or paralysed, ABADMIN #1476, so a
     queued shield waits for the cure where a plain send was refused)
   - If mobile: navigate to safe room
6. Navigation priority:
   - Area-specific safe room (`ataxiaBasher.safeRooms[area]`)
   - Previous room (`mmp.previousroom`)
   - Random exit direction
   - Shield if no exit available (the same helper)

## Stun (`ataxiaBasher_stunStart` / `ataxiaBasher_stunEnd`, v4.7.219)

`ataxia.afflictions.stun` gates the affliction check in `ataxiaBasher_tryAttack`, and trigger
723 dispatches straight off `You are no longer stunned.` -- the dispatch was never the slow
part. Two things around it were:

1. **The re-queue cooldown outlived the stun.** `ataxiaBasher_atk` (0.3s) is armed by the last
   dispatch BEFORE the stun latched, and its clearing `tempTimer` runs through the whole stun
   while `affed("stun")` blocks every `tryAttack`, so nothing consumes it. 723's direct call
   ignores the flag, but the follow-up prompt dispatch does not -- a refused or wiped first
   round sat out a window armed for an unrelated reason. `stunEnd` now drops it and kills its
   timer, so that timer cannot fire later and clobber a fresh one.

2. **The flag had one way out and no failsafe.** Two of trigger 722's three patterns are
   Vertani-soldier-specific, so in practice the setter is the REFUSAL line ("You are too
   stunned to be able to do anything") -- which fires for ANY stun source, because it only
   appears when we tried to act. Exactly one line cleared it. Miss that line (different
   wording, split line, lost packet) and the flag latched TRUE and the basher was blocked until
   the next stun happened to print it: a STALL, indistinguishable from lag at the keyboard. The
   flag now self-expires after `ataxiaBasher_STUN_FAILSAFE` (5s) and dispatches on the way out,
   so the worst case is five seconds instead of forever.

**Not done, and why:** pre-queuing during the stun would beat the client round-trip, but the
refusal line exists and is GAGGED in `011_GAG2`, which means queued commands are attempted and
burned mid-stun rather than held. Re-queuing to compensate would re-run the whole round
assembly each time, spending battlerage charges, deck picks and cooldown stamps on rounds that
get refused -- the class of bug `ataxiaBasher_brCommit` exists to prevent. Needs the server's
queue-during-stun behaviour confirmed first.

## PvE Auto-Parry (v4.7.222)

From a Duke Semiro log: over ~20 swings, **two parries landed**. Three separate defects.

1. **Following the LAST hit is the wrong rule** against a mob that spreads. Semiro interleaves
   right leg, torso and head, so focus-follow parked the cover on the limb he had just finished
   with -- permanently one swing behind, actively anti-correlated with an alternating attacker.
   `selfLimbDamage.hitHistory` (rolling 6) already existed and **nothing in the PvE path read
   it**. `ataxia_bashingParryFocus()` now takes the MOST-hit limb, ties broken toward the more
   recent so a genuine focus-switch is still followed rather than outvoted by history.
2. **The broken-limb filter excluded exactly the limb worth covering.** Skipping a limb because
   it is already broken is backwards in PvE: re-hits are how `rl1` becomes `Rl2`, and how BOTH
   legs break -- the state that refuses our own attacks outright. The predictive `fixed` path
   (005) had always parked on broken limbs deliberately; focus-follow now matches.
3. **A 3-second lockout on a mob swinging every 2 seconds.** `parryAttempted` exists to cover
   the round-trip until the server confirms (~100-300ms). Trigger 757 -- the confirm, gagged for
   display but still firing -- now frees it on landing; the timer is the fallback only, cut
   3 -> 1.5s, tracked and killed on re-arm so a stale timer cannot clear a newer guard.

**The trap this created:** a PARRIED swing emits no `dealt N% damage` perceive line, so it never
reaches `ataxia_raiseLimbDamage`. Counting only unparried hits would under-represent exactly the
limb the parry is succeeding on -- the parry would sabotage itself. `ataxia_recordSelfHit` is
shared and `ataxia_parrySuccess` feeds it.

*General shape: when you start scoring an event stream, check which events the SUCCESS case
removes from the stream.*

## Circuit Breaker

Function: `ataxiaBasher_startFleeTimer()` — 20-second timeout (configurable via `ataxiaBasher.fleeTimeout`).

If flee state persists after timeout, calls `ataxiaBasher_areaoff()` to fully disable the basher as a safety measure, preventing zombie bashing loops.

## PvP Detection

Function: `ataxiaBasher_onAttacked()` in `genrunning/001_Bashing_API.lua`

Triggered by `"attacker class detected"` event:
1. Immediately disables basher
2. Clears all queues and flee state
3. Navigates to Mhaldor (`expandAlias("goto Mhaldor")`)

### Player Flee (Per-Area)

Function: `ataxiaBasher_checkPlayerFlee()` in `basher/001_Bashing_Functions.lua`

- Configured via `ataxiaBasher.fleeFromPlayers[area]` — list of player names
- When hostile player detected: calls `areaoff()`, shields, alerts

## Death Handling

Function: `ataxiaBasher_onDeath()` in `genrunning/001_Bashing_API.lua`

Triggered by `"player death"` event:
1. Save death area (before respawn changes it)
2. Disable basher, clear all modes
3. Kill ALL timers (flee, return, stuck, attack)
4. Pause mapper
5. Raise `"basher disabled"` event
6. After 2s: unpause mapper, navigate to safe room

## Room Skip (scanRoom)

Function: `ataxiaBasher_scanRoom()` in `genrunning/001_Bashing_API.lua`

Sets `ataxiaBasher_skipRoom = true` when:
- Mob in `ataxiaBasher.mobIgnore` is present
- Dangerous mob count exceeds `ataxiaBasher.dangerCount`
- Non-ignored player present (except Mhaldor)

## Own Denizens (pets/allies — never targeted, room NOT skipped)

Function: `ataxiaBasher_isOwnDenizen(name)` in `basher/001_Bashing_Functions.lua`

`ataxiaBasher.ownDenizens` is a list of **case-insensitive substring keywords** for
denizens that belong to you (falcons, Baalzadeen, summons). Unlike `mobIgnore`, a
match does **not** skip the room — the basher keeps killing everything else while
your pet stands there. Matches are excluded from:

- auto-learn (`update_stuff/003_ataxia_RoomContents_Update.lua`)
- slain auto-add (`triggers/.../340_Slain.lua`)
- target selection (`search_targets()` and `shieldedTarget()` in `genrunning/002_search_targets.lua`)
- the `bash add` manual candidate list

Seeded with `{"falcon", "baalzadeen", "ashbeast", "hyena", "homunculus"}`
(`002_Check_For_Any_Missing_Variables.lua:159`; the backfill at :186 adds all five, so
existing saves get them too). Managed via `bash mine` (see configuration doc); adding a
keyword also purges already-learned matches from every target list via
`ataxiaBasher_purgeOwnFromTargets()`.

### The substring match cuts both ways — `notOwnDenizens` (v4.7.169)

Substring matching is what lets one keyword cover a whole family of pet names without
enumerating the variants, and it is also why a **real, killable denizen** whose name merely
contains a pet's word is silently shielded. `a slope-backed hyena` is exactly that: a genuine
mob, protected by the `hyena` keyword seeded for the Infernal pet, and
`ataxiaBasher_purgeOwnFromTargets()` additionally **deleted it from the learned target list
across every area**.

Outside the tower that costs xp. Inside Mnemosyne it stalls the run, because the whole tower
stack agrees with the mistake: the explorer filters own denizens through the same predicate
in both of its room readings (`M._roomHasDenizens`, `mnemosyne/008_Explorer.lua:142`, and
`M._denizenCount`, `008:108`), so a shielded mob is invisible to the sweep as well as
unpickable by `search_targets`. The room reads *clear* while a live denizen stands in it: the
explorer moves on, no boon screen arrives (a ripple ends only when its denizens are dead —
`M.onBoonScreen`, `008:684`), and the grid-swept boss/straggler patrol burns its
`MAX_PATROL_LOOPS` (3, `008:55`) hunting something it cannot see before giving up with
"no boss / straggler found after patrolling; stopping" (`008:532`). The 30s stall watchdog
(`008:52`) does not catch it either: it is re-armed on every progress event and the patrol
keeps arriving in rooms, so it never trips — and when the patrol gives up, `_exploreStop`
kills it outright (`008:643`). Nothing errors and nothing warns; the run simply ends on a
ripple that was never cleared.

`ataxiaBasher.notOwnDenizens` is the exemption list and it **wins**: it is scanned first in
`ataxiaBasher_isOwnDenizen` (`basher/001_Bashing_Functions.lua:847-870`), so the pet
("a daemonic hyena") stays protected while the mob is targetable again. Seeded by backfill
rather than as a default (existing saves already carry the bare keyword), and managed with
`bash notmine [add|rem] <name>`. Narrowing the seeded keyword to `daemonic hyena` was
considered and rejected: it only helps fresh installs, and does nothing for the next
collision. **When adding a pet keyword, prefer the most specific form that still covers the
variants, and expect collisions — the exemption list is the general answer.**

## Attack Gate Afflictions

The basher blocks attacks when any of these afflictions are active:
paralysis, aeon, peace, transfixation, webbed, impaled, constricted, deepsleep, entangled, unconsciousness, snared

## Emergency Systems

### Wand of Reflection
- Threshold: `ataxia.wandReflectionThreshold` (default 10% HP)
- Recovery: `ataxia.wandReflectionRecovery` (default 70% HP)
- Command: `point [wandId] at me`
- Cooldown: 1 hour

### Maran Barrier (Legend Deck)
- Threshold: `ataxia.maranThreshold` (default 25% HP)
- Requires: Maran card charge available
- Command: `ldeck draw maran`
- Cooldown: 65 seconds (the barrier lasts 60)
- **Stands down in Mnemosyne** (v4.7.165, `basher/001_Bashing_Functions.lua:1163-1168`): when
  `inMnemosyne` and `mnemLdeck.enabled`, the tower card layer owns Maran along with five
  other cards. This path `return`s and forfeits the whole attack cycle, the card layer rides
  the assembled round instead — running both would double-draw a 2-charge card.

### Blood Maiden Cloak (model corrected v4.7.167)
- Trigger: 4+ mobs matching the area target list, **or** any mob in
  `ataxiaBasher.bloodMaidenBosses` — and never while `prone`
- Charge: `ataxiaTemp.bloodshieldReady`, one charge, set by `A cloak of the Blood Maiden
  seems to grow hot against your skin.` (trigger `769_Blood_Maiden_Cloak.lua`, which also
  gags the line while bashing) and **consumed by one `activate bloodshield`**
- Guard: `ataxiaTemp.bloodshieldCooldown`, a 3-**second** anti-double-send flag, not a
  cooldown on the cloak

BLOODSHIELD blocks **the next attack**, once. The code used to read TALISMAN INFO's "failing
to make a kill within 3 minutes will cause the blood reserves to deplete" as *"the cloak
stays active for 3 minutes, so re-activation is free"*, and dropped the mob threshold from 4
to 3 on that basis. Both halves were wrong — the 3 minutes is the depletion timer on the
reserves, not an uptime — so a charge earned over five kills was spent and then re-spent
every 3s against a cloak that had nothing left. One charge, one activation, spent only on a
genuinely dangerous room. The prone exclusion is its own mechanic: under aggression aura the
cloak refuses while prone, and has a 50% chance to eat the charge for nothing.

## Timing Summary

| System | Duration | Configurable |
|--------|----------|-------------|
| Anti-spam delay | 0.3s | No |
| Flee circuit breaker | 20s | `fleeTimeout` |
| Return navigation timeout | 15s | No |
| Stuck detection | 15s | `stuckTimeout` |
| Shield duration (default) | 3.1s | `shieldTimerDefault` |
| Damage rate window | 5s | No (`ataxiaBasher_dmgWindowSec`) |
| Danger time-to-death floor | 6s | Yes (`ataxiaBasher.dangerTTL`) |
| Damage-rate minimum span | 3s | Yes (`ataxiaBasher_dmgMinSpan`) |
| Throttle pause | 2s | No |
| Max attacks/sec | 5 | No |

**Vitals-pinning effects vs the safety ladder (v4.7.124):** the Senseless Flurry numb
keeper is CROWD-GATED because numbness defers damage — HP pins while it is up, and until
v4.7.512 that blinded every HP-based safety until the deferred lump landed as one −40%
blow. In a swarm-threshold room that lump can exceed max HP. The keeper therefore only
numbs in thin rooms (< swarm threshold, no tactic running). The gate stays after v4.7.512,
because the debt below is an estimate. General rule: any effect that pins or fakes vitals
must be gated away from exactly the situations these safeties exist for, or its hidden
cost must be counted where the safeties read.

## The numbness debt (v4.7.512)

`basher/016_Numb_Debt.lua`. The game facts and their source: `kb/defences/numbness.md`.

**The problem, from the log of 2026-11-23.** Numbness defers every hit for about ten seconds
and then takes the total, 40% smaller, in one prompt (seen: up to 11,036 of 20,061 health). The
blow has no `Health lost:` line, so only the net-delta feed saw it, and that feed read 8,591
health in one prompt as a RATE: 8,591 over the 3 s floor is 2,864 a second, 4 s to live,
`DANGER: Extreme incoming damage`. Outside a no-flee area that is a flee, caused by damage ten
seconds old. And for those ten seconds every safety read full health.

**The model.** Each absorbed hit is owed. The debt is session state on `ataxiaTemp.numb`
(`{ upAt, hits, debt, owed, paid, unknown, fadedAt }`).

| Game line (trigger) | Call | Effect |
|---|---|---|
| up line (`highlighting/060`) | `ataxia_numbRaised(true)` | opens a cycle; starts the NUMB recovery |
| absorbed hit (`highlighting/075`) | `ataxia_numbAbsorbed()` | `hits + 1`; adds one estimate to the debt and gives it to `ataxiaBasher_recordIncoming`; opens a cycle when no up line was seen |
| `Health lost: N (type).` | `ataxia_numbNoteTyped(n, type)` from `bashStats_recordIncoming` | a typed hit (not `raw`) is a reading for the estimate; inside a cycle it gives back what its fall of health paid |
| fall of health (Char.Vitals) | `ataxia_numbNoteDrop(n, from, to)` from `update_stuff/004` | pays the debt; returns the part the debt does not explain, and only that goes to `ataxiaBasher_recordDamage` |
| fade line (`highlighting/074`) | `ataxia_numbFaded()` | closes the cycle, learns the blow per hit, echoes `NUMB WORE OFF: -N HP (a -> b, p% of max) from H absorbed hits. Estimate was E.` |
| ready / refusal lines (`highlighting/076`) | `ataxia_numbReady()` / `ataxia_numbRefused()` | end or start the recovery that `ataxia_numbCooling()` reports to the keeper |

**The estimate of one absorbed hit** (`ataxia_numbHitEstimate`): the LARGER of 0.6 x the mean of
our last 12 typed hits and the last blow divided by its absorbed hits, each at most 120 s old.
Too small a debt is the unsafe direction. With neither reading the hit is `unknown`: it adds no
debt, the echo and the alarm text say so, and the blow that pays for it goes to the net feed
whole (the behaviour before v4.7.512).

**The readers.** `ataxia_effHp()` / `ataxia_effHpp()` are health minus the debt (1 at least,
because 0 means "unknown" to every reader; never above the plain reading).
`ataxiaBasher_safeHp()` / `ataxiaBasher_safeHpp()` wrap them, and these read them:
`ataxiaBasher_isDamageRateExtreme`, `ataxiaBasher_secondsToLive`, `ataxiaBasher_dangerLevel`,
`ataxiaBasher_lastStandCritical`, `ataxiaBasher_lastStandHolding`, the shielded-attack check and
the flee recovery check (`basher/001`); the swarm's `hpp()` and `hppFresh()`, `S._panicHpHit` and
`S._dyingFast` (`mnemosyne/009`). One reader keeps the game's own number: the Righteous Fire
detector looks for a jump in health, and a debt that ends would look like one. An alarm that
fires beside a prompt at full health names its reason: `[numb debt ~8200 HP]`.

**Order.** The debt is paid on the fall of health, not on the fade line. In the logged cycle
Char.Vitals came first and the danger level was read between the two; a debt still standing
then would count the same damage twice. When the fade line comes first, the debt stands until
the fall of health arrives (1 s at most). "Has the blow landed?" is answered by the cycle's own
payments: yes when its falls of health paid half of the estimate. A bleeding tick pays almost
nothing, so it is not taken for the blow; the blow reported is the largest fall of the cycle.

**Bounded stops.** A cycle with no fade line ends 12 s after its up line (the longest seen was
10.03 s). A fade with no fall of health settles after 1 s and says so. The recovery ends 14 s
after the up line if the ready line never comes.

**Not covered.** The debt is not shown on the prompt. `bashStats` does not count the blow as
damage taken. The Legend Deck's numbness opens a cycle only from its first absorbed hit.
