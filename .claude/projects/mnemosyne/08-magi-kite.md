# The Magi kite: cast, get out, come back (v4.7.530; the fly out v4.7.531)

Code: `src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/018_Magi_Kite.lua` (`ataxia.mnemosyne.magiKite`, `K` below).
Test: `src_new/tests/test_magi_tower_kite.lua`. The class page: `.claude/classes/magi.md`, PvE item 2e.

## The rule

> "Cooldown Abilities via Boons > Stormhammer if not in danger (health) > Run if in danger (health) > hit and run with stormhammer" — user, 2026-11-27

- **Hit and run** is "Cast, step out, return": cast, step to a near room, come back when equilibrium is up, cast again (user, 2026-11-27).
- **Outdoors it flies** (v4.7.531): "both flying and moving rooms should hit and run. Fly, sip health, eat cure, land, hit, fly, sip, land, etc" (user, 2026-11-27). When the sky is open the out is a FLY in the same room, not a step; indoors, or when flight is refused, the step out below, unchanged.
- **Danger** is the escape line the tower retreat already uses: `escapeAt` (`mnem swarm escapeat`, default 35%), health minus the numbness debt.
- **The hit**: "stormhammer only for denizens 3 plus, not 1 or 2. Staffcast is better usage there." (user, 2026-11-27). At 3+ non-own denizens with 1200 mana above the `manause` floor: `cast stormhammer at A and B and C`. Otherwise `staff cast horripilation at <target>` (the round's normal last branch). `ataxiaBasher_magiKiteHit`, `basher/002:2600`.
- **Who**: a Magi (gmcp class) in the tower (`ataxiaBasher.inMnemosyne`), with the swarm able to move (`S._enabled`: explorer, basher, manual movement). `mnem swarm magikite on|off` (saved `swarm.magiKite`, on by default).

## The cycle

State is session state, `ataxiaTemp.magiKite` (never saved; a reload clears it, `018`:117). A reload while we are up leaves no kite to land us; the swarm's stray-flight backstop at the top of `S.onTick` lands us (idle, not hovering, gmcp "Flying above").

At each cast line `K.onCast` (`018`:491) picks the out: **the fly** when `K.flyWhyNot` (`018`:224) is nil, else **the step**.

| Phase | Where | What happens | Ends when |
|---|---|---|---|
| `cast` | the fight room | The round carries the kite's hit (`basher/002:2648`, after the 30 s procs, before deepfreeze and surge). Attacks are not held. | The game's cast line (`K.onCast`, `018`:491): the step out is queued. |
| `out` | still the fight room | `cq all`, then one queue entry `stand/<verb> <dir>` (`S._queueMove`, the alias `lvmove`), the swarm's move watch (`S._watchMove`, re-sends a lost move), the explorer armed for `K.MOVE_MAX` 12 s, and `ataxiaTemp.magiKiteHold` holding the dispatcher (`basher/001:168`). | The room changes. |
| `away` | the near room | Hold kept. After `K.SETTLE` 1.5 s (the denizen list lags the room change): denizens here = they followed (or lived here): this is the fight room now, `cast`. Empty: if `K.healthPermits` and `S._moveAble` (balance, equilibrium, not bound), step back, held the same way. | The step back is queued, or the kite stops. |
| `back` | the near room | As `out`. | We are in the fight room: `cast`, hold released. |

### The fly out (v4.7.531)

`K.flyWhyNot` uses the swarm's own gates, so the kite and the hover never disagree about the sky: indoors (`S._indoors`), Deluge, the ripple latch `S.grounded` (a dragger or a flyer lives on this ripple), bound (`S._canFly`), an ablaze room whose air burns (`S._canHover`), or a fly already refused in this kite. Outdoors, a reason other than "indoors" is said in the step's echo: `(no fly: <why>)`.

| Phase | What happens | Ends when |
|---|---|---|
| `up` (`018`:679) | On the cast line: `cq all`, then one queue entry `stand/fly` (`S._queueMove`, as the hover sends it), the dispatcher held (`ataxiaTemp.magiKiteHold`). The fly goes when the cast's equilibrium is back. Re-queued once we have been able (`S._moveAble`) for `K.FLY_RESEND` 2 s and still are not up (an eaten command). | **Airborne, on the game's evidence**: gmcp's room name "Flying above ..." (`S._gmcpFlying`), or the ring's line after this fly (`022` -> `S.onFlightUp`, `S.flightUpAt`). Never the key press. **Refused**: flight became impossible, or no evidence by `S.FLY_CONFIRM_MAX` 10 s: `cq all` (the queued fly must not lift us later), no more flying this kite, and the step out instead; no cleared room next door: the kite stops. |
| `air` (`018`:719) | Hold refreshed. SSC sips and eats on its own; the kite sends neither. A ground denizen cannot reach us: "While airborne, melee cannot reach us" (live 2026-07-26, `07-explorer.md`, the ring of flying). After `K.SETTLE` 1.5 s up: seen up by gmcp and now on the ground = **knocked down** (the cast phase on foot, `S.grounded` latched: the hover's rule); a denizen in the sky list = **a flyer** (land, latch `S.grounded`). | `K.landReady` (`018`:473) and `K.healthPermits`: land. Not safe to land, or not ready after `K.AIR_MAX` 20 s: the kite ends and **the recovery hover takes the flight** (`S._convertToHover`; it lands at `recoverAt` and cured). |
| `down` (`018`:758) | `land` sent directly (we hold balance and equilibrium, so it goes whether or not LAND costs either), again every `K.LAND_RESEND` 1.5 s. | The land line ("You land easily, back on the ground again.", `022` -> `S.onFlightDown`, stamped `S.flightDownAt` since v4.7.531) or gmcp naming the ground (not under dementia, not when gmcp names no room): the cast phase, its settle from now (the sky's denizen list lags). Not landed by `K.MOVE_MAX` 12 s: the hover takes the flight. |

**The landing rule, and why.** Land when balance and equilibrium are back and nothing binds us (`S._moveAble`), we have been up at least one eat clock (`K.EAT_WINDOW` 1.5 s), and either a health sip came since takeoff or one sip clock has passed (`K.SIP_WINDOW` 4.4 s). The user's cycle is "fly, sip health, eat cure, land": one sip and one eat per cycle, not a hover to full health (the hover does that, and holds every attack). The sip is the game's line: `balances/002_Sip_Used` stamps `ataxiaTemp.healthSipAt` on "The elixir heals and soothes you." (v4.7.531; the mana line is not counted). Without a sip (SSC above its sip line, or the sip balance spent on the ground) the sip clock bounds the wait. Both clocks are the medians of ALL LOGS, mostly other players (`kb/mechanics/foundations.md`: Sip 4.40, Eat 1.50); cure clocks are not equilibrium, so the Diadem factor does not apply, and ours are not measured separately. In practice the cast's equilibrium (stormhammer BASE 6.00 s) and the fly's balance are the longer waits.

**Does FLY or LAND cost balance?** The Metamorphosis FLY is "Cooldown: 4.00 seconds of balance", "Useable entangled: No", "Useable paralysed: No" (ABADMIN 338, `kb/raw/live/captures/kb_capture_2026-11-13_172842.txt`:739-757). The tower's fly is the **ring of flying** (`07-explorer.md`, live 2026-07-26), whose cost is NOT captured. LAND's cost and its refusal lines are not captured (`kb/mechanics/launched-into-sky.md`, "Open"). The kite survives either way: the fly is queued (it waits for whatever it needs) and judged only on the evidence, with a 10 s budget; the land is sent only with balance and equilibrium up and re-sent until the evidence comes.

**Every stop while up lands us** (`018`:383): any phase `up`/`air`/`down` or gmcp "Flying above" with evidence of flight sends `land` and opens the explorer's settle; a stop with the fly still queued and no evidence sends `cq all` instead; a stop that must stay up (`opts.hover`) sets the swarm's mode flag `S.flying` and calls `S._convertToHover`, so the hover owns the flight and lands at its own end. A swarm reset (`S.reset`) stops the kite first, so its land goes too.

**The step out is stamped on the game's line** (`.claude/AGENTS.md`, "Stamp on the confirmation line"), never when the round is built or the key is pressed. It cannot go "at once": the game refuses movement off equilibrium ("You are recovering equilibrium and cannot move yet.", `kb/mechanics/balance-and-queueing.md`), so the queued step goes when the cast's equilibrium returns (stormhammer: BASE 6.00 s; ours about 5.1 s with the Diadem, not measured).

**The cast lines.**

| Hit | Trigger | Pattern | Evidence |
|---|---|---|---|
| stormhammer | `magi_offense_tracking/022_Stormhammer_Cast.lua` | `^The sky above grows dark as you call upon powerful magics\.` | CONFIRMED for one player target, from another Magi's own log (Tabethys, `kb/raw/logs/2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt`:547, 732). UNCONFIRMED for two or three denizens. |
| staffcast | `magi_offense_tracking/023_Staffcast_Horripilation_Cast.lua` | `^You point .+ at .+ and \w+ screams in pain` | UNCONFIRMED. Derived from a third-person line ("Tabethys points an exquisite Mhaldorian staff of sterling silver at a carnivorous lycopod, and he screams in pain as his skin begins to freeze and crack.", `kb/raw/logs/ours/2026-10-28_073547_Tabethys.log`:761). |

**A lapse is not a confirmation.** If our equilibrium goes in the cast phase and no kite cast line (and no Master of Four, Hellfumes or Quake cast line) comes within `K.CAST_GRACE` 1 s, that counts once; `K.MISS_MAX` 2 in a row stop the kite, which says the line is UNCONFIRMED (`watchLapse`, `018`:528). A lapse never moves us. So a wrong pattern costs two rounds standing, then the ladder, never a wedge.

**The end**: in the cast phase, `S._mayReturn()`: `returnAt` (85%) and cured. That is the bar the U-turn rule and the ground recovery use for going back into a room we fled, and the kite goes back into its fight room every cycle, so it reuses the one definition rather than a second opinion ("Nothing followed is not we are ready", `.claude/AGENTS.md`). The band 35% to 85% is the hysteresis: the kite does not restart and stop on every heal.

## Where it meets the swarm (mnemosyne/009)

The hooks: `S.onVitals` (`009`:3087 runs an active kite each prompt, after the tincture and Seclusion; `009`:3132 starts one at the escape point, health only, not on the damage-rate alarm alone), `S.onTick` (`009`:2471 the kite owns the tick; `009`:2671 starts one before the low-HP ladder), `S.reset` (`009`:3396, every swarm teardown stops it), and the basher's danger level (`basher/001`:656: while the kite owns the room it answers `attack`, so neither the disengage nor the last stand runs).

| Rule | With the kite |
|---|---|
| One retreat, then we fight (v4.7.482) | Replaced while in danger. The kite's steps are neither read nor spent as retreats (`S.retreatSpentAt` is untouched): it leaves and re-enters the SAME fight, which is what "kill what is in this room" asked for. The ping-pong that rule stopped is stopped by `K.FOLLOW_MAX`. |
| The U-turn rule (85% and cured to go back) | Replaced: the return is the cycle. Its safety part stays as `K.healthPermits`: not dying fast (`S._dyingFast`: the damage watchdog or raw health at `panicHp` 3000), and no single attack of the last 30 s as big as our health (`ataxiaBasher_biggestHitHere(30, true)`, any room). Not safe: the kite stops and `S._recoverHere` heals here. |
| Pursuit (`S._pursued`) | No start while a retreat was followed. In the kite, followers are hit in the new room the same way (user); after 2 followed steps in a row the kite stops, stamps `S.pursuedAt`, and we fight there. |
| Prey | No start (`S._preyTracks`). |
| Roll Hide / Terror of the Skies | No start: leaving ends the fight there, so the panic tumble and the ladder own it. |
| Lethal hit (v4.7.514) | No start, and a running cast phase stops: the ladder leaves now, with its lethal exemption, instead of standing for a cast. |
| Reckless reveal, both arms out | Not read: those lift the spent retreat, which the kite never reads. Stormhammer and the staffcast show "Requires arms: 0" (ABADMIN 741; an ABADMIN flag is data, not proof of enforcement). |
| Broken legs, prone, ice, mounted | `S.moveVerb` picks the verb (tumble on a bad leg or ice, mountjump mounted, else leap); `stand` leads the queue entry. A tumble in flight is waited on (`S.moveLocked`). |
| The last stand | No start while one holds. While the kite owns the room the danger level does not reach it. When the kite stops, it is there again. |
| Shield-safe stand (v4.7.519) | Ahead of the kite in `onVitals` and in the danger level. |
| Lava | No start; the lava escape owns the queue, and the kite never sends `cq all` in lava. |
| No path, a refused or lost move | `K.outDir` takes only a CLEARED room next door (`S._exitRank` 1; the walked back edge first, then sorted exits; never lava or our own icewall). None: no start, or a stop at the cast line. A step not landed by `K.MOVE_MAX`, or that the move watch calls lost: stop. |
| The hover (outdoors) | The kite flies instead (v4.7.531, the user's "fly, sip health, eat cure, land"): its start sits before the ladder in both paths, so outdoors a Magi casts, flies, heals one sip and one eat, lands and casts again, where the hover would stay up holding every attack until 95% and cured. The hover stays the fallback: when landing is not safe, or the kite cannot land, it takes the flight. |

Every stop echoes `MAGI KITE ends -- <why>`. A failure stop (no exit, a lost step, the lapse, a lethal hit, followed) leaves the room to the ladder for `K.COOL` 10 s (followed: `S.PURSUIT_MEMORY` 45 s). A start that is refused for a reason that is news says `not kiting: <why>` (throttled 5 s); the context gates (another class, outside the tower, above the line) are kept in `ataxiaTemp.magiKiteWhyNot` and shown by `mnem swarm magikite`.

## Not covered

The live game. Both cast lines with denizens. Whether a leap costs balance (the kite uses the swarm's verb). The fly out in the live game: the ring's fly cost, LAND's cost and refusal lines, whether a ground denizen's ranged attack reaches us in the air, and whether Char.Items re-pushes inside `K.SETTLE` after a landing (the hover relies on the same). Dementia: the rooms are the map's keys, as in the swarm, and the lethal check reads any room.
