# Battlerage for PvE (bashing / tower-climbing)

Battlerage abilities are the **only** class-adjacent abilities in Achaea that are useful **on denizens** (they do nothing to players). Everyone gets 6 per class via the **Attainment** skill (unlocked by levelling: 6, 10, 20, 35, 50, 65; Provoke at 100). They're powered by **Rage**. For a bashing/tower-climber, using them well is a big deal — this doc is the reference the LEVI basher is built around.

## Rage — the resource
- **Gained** by doing damage to denizens, at a constant rate tied to your attack speed. Multiple simultaneous hits still only grant the **first** hit's rage. Group members share a % of your rage gain (2 ppl 10% … 15 ppl 0.3%).
- **Fades** after **15s** of not using or gaining rage (`The surge of terrible rage leaves you.`), so keep attacking.
- **See it:** prompt `*R` (custom) / `R`; or `BR` / `SHOW RAGE`. LEVI reads it as `ataxia.vitals.rage`.
- **Global cooldown:** there is a **~1-second global cooldown** on ALL battlerage abilities (`You must wait a short time before you can use a battlerage ability again.`). Queuing a second BR inside that window wastes it — LEVI tracks this (`ataxiaTemp.brGlobalReadyAt`, trigger `329`) and skips a BR while it's up.
- Each ability also has its **own** cooldown + rage cost (`AB ATTAINMENT <ability>`). The game announces that cooldown expiring **by name**, which is authoritative and beats any client-side arithmetic — see *Cooldown truth — the game's own ready lines* below.

## Ability types
1. **Damage** — straight / DoT / burst.
2. **Afflicting** — inflict a denizen affliction (below).
3. **Conditional Damage** — bonus damage **if the denizen already has a particular affliction**. ← the big lever: apply the aff, then cash it in.
4. **Shield Breakers** — remove a denizen's shield.

## The 10 denizen afflictions — what each does, and why it matters

Ordered by **defensive value** — *any rage ability that stops a denizen hitting us is critical* on the tower (no-flee), so these come first.

| Affliction | Effect on the denizen | Dur | Tactical value |
|---|---|---|---|
| **Stun** | does **nothing** | 4s | ★ best mitigation — total hit-prevention |
| **Charm** | attacks the **other** denizens for you | 5s | ★ turns a mob into a temporary ally (swap off it, keep it alive) |
| **Feared** | **flees** every couple seconds | 8s | mitigation, but the mob may leave the room |
| **Amnesia** | misses the next **2–3 attacks** | (count) | hit-prevention |
| **Clumsy** | misses **33%** of attacks | 7s | hit-prevention |
| **Aeon** | attacks at **66% speed** | 6s | hit-reduction |
| **Weakness** | deals **66%** damage | 7s | damage-reduction (doesn't stop hits) |
| **Inhibit** | doesn't actively **heal** | 9s | offense — lets your damage stick; burst window |
| **Sensitivity** | takes **+33%** damage | 8s | offense — **burst** it while up |
| **Recklessness** | **can't shield** | 15s | offense — enables Conditional-Damage abilities (e.g. Headstrike) + no shields to break |

Afflictions arrive from **any** source — our battlerage, proc-boons (Wayward Heir → random BR aff / charm, Haskor's Bravado → recklessness, Temporal Anomaly → aeon), or groupmates — and LEVI captures them into `ataxiaTemp.denizenState[id].affs` (see `008_Denizen_State`). **Capture status:** **charm, recklessness, aeon, weakness, stun** are captured from real game lines as applied/ended pairs (triggers `011`–`020`, plus `021` for the Bard-boon AoE stun and `030` for Golden Dragon Deaden → aeon); **amnesia** has both ends via Golden Dragon Psidaze (`highlighting/028` applies, `031` clears); **clumsy** (`022`) and **inhibit** (`023` Ripplestrike, `024` necrotic aura) have an apply line only and rely on lazy expiry from their `BR_AFFS` duration. Only **feared** and **sensitivity** are still uncaptured entirely.

## How the LEVI basher uses this
- **Per-denizen state** (`basher/008_Denizen_State.lua`): each mob's afflictions/HP tracked with real durations (lazy-expiring), PvP-inert. `ataxiaBasher_dsExploit(id)` returns the ability that cashes in the mob's current state (shielded→shatter, reckless/feared→headstrike, sensitivity/inhibit→burst, ablaze→fire).
- **Rotation** (`ataxiaBasher_blademasterBattlerage`) spends rage by priority so it never idles, and cashes afflictions in for bonus damage. Priority **in Mnemosyne** (survival > speed):

  **Culling Blade → Stun/Amnesia/Aeon/Clumsy (hit-prevention) → damage battlerages → other afflictions → small damage**

  Outside Mnemosyne it's damage-forward (mitigation drops below the damage abilities). Cooldowns come from the shared `battleRage_Timers` (fire-line triggers `330` Leapstrike / `331` Spinslash / `332` Daze — trigger `333` exists but is Shaman-only) where tracked, else a reload-safe **timestamp** cooldown (Headstrike, Nerveslash — no fire-line trigger).
- **No rage-reserving for Daze.** In-game logs confirm Daze fires roughly **every ~33s** (its cooldown ceiling) on its own under this priority, so LEVI does **not** starve the cheaper abilities to feed it. A short-lived "hold rage for Daze" tweak was reverted (v4.7.65) because it only cost Nerveslash/Leapstrike damage for zero extra mitigation.
- **Visibility** (`ataxiaBasher_dsAlert`): when one of our attacks lands a captured affliction, LEVI highlights the triggering game line and echoes a coloured `(BR):` tag to the console (charm cyan, recklessness orange, aeon yellow, weakness green, stun magenta) so the rotation is visible in the combat spam. Toggle with `ataxiaBasher.brAlerts` (default on).

## Blademaster's six (this character)
| Ability | Cmd | Rage | CD | Type | Aff / note |
|---|---|---|---|---|---|
| Leapstrike | `LEAPSTRIKE` | 14 | 16s | damage/execute | cheap filler |
| Shatter | `SHIN SHATTER` | 17 | ~global | shield breaker | on a shielded mob |
| Nerveslash | `NSL <t>` | 22 | 31s | afflicting | **Weakness** |
| Headstrike | `STRIKE … HEAD` | 25 | 23s | **conditional dmg** | bonus vs **reckless / feared** |
| Daze | `SHIN DAZE` | 26 | 33s | afflicting | **Stun** — the key mitigation |
| Spinslash | `SPINSLASH` | 36 | 23s | damage | big single-target dump |
| Provoke | `PROVOKE` | 32 | 20s | taunt (lvl 100) | forces the mob onto you (inverse of charm; costs 2.5s bal/eq) |

## Magi's six (`ataxiaBasher_magiBattlerage`, basher/001)

Magi has its own rotation (`ataxiaBasher_magiBattlerage`), invoked from `magiBashing` (basher/002). Like Bard/Blademaster it **owns culling** (excluded from the shared culling check, so `reap` fires from inside the rotation). Cast syntax is `cast X at <t>` for everything **except Squeeze** (`cast squeeze <t>`, no "at").

| Ability | Cmd | Rage | CD | Type | Aff / note |
|---|---|---|---|---|---|
| Windlash | `cast windlash at <t>` | 14 | 16s | damage | cheap filler |
| Disintegrate | `cast disintegrate at <t>` | 17 | — | shield breaker | **never fired** (see below) |
| Firefall | `cast firefall at <t>` | 25 | 23s | **conditional dmg** | bonus vs **clumsy / reckless** |
| Stormbolt | `cast stormbolt at <t>` | 25 | 27s | afflicting | **Sensitivity** (+33% dmg taken) |
| Dilation | `cast dilation at <t>` | 35 | 35s | afflicting | **Aeon** — the key mitigation |
| Squeeze | `cast squeeze <t>` | 36 | 23s | damage | big single-target dump |

Culling: `reap <t>` (36 rage, AoE finisher).

**Priority** (spend the highest affordable, off-cooldown value so rage never idles):
1. **Culling reap** (rage ≥ 36; owned here, blocked in the World Tree area).
2. **In Mnemosyne — Dilation → Aeon** (mob attacks at 66% speed = mitigation on the no-flee climb), when not already aeon'd.
3. **Firefall** on a clumsy / reckless target (bonus damage — Magi's own kit applies neither, so this only cashes an aff from a boon/groupmate).
4. **Stormbolt → Sensitivity** when the mob isn't sensitive yet — sets up the Squeeze burst.
5. **Squeeze** (big damage, lands harder while that Sensitivity is up).
6. **Dilation** surplus, outside Mnemosyne (spend + Aeon).
7. **Windlash** (cheap 14-rage filler).

**Disintegrate is never fired.** `magiBashing` casts the free `erode` shield strip when the mob is shielded, so spending 17 rage on Disintegrate is the worse trade (same rule as Monk shatter-over-spinkick).

**Cooldowns.** Squeeze uses the shared `battleRage_Timers.large` (real, from fire-line trigger `331` "vice-like squeeze"). The rest have **no** fire-line trigger (they aren't in 330/332), so they use reload-safe **timestamp** cooldowns (`ataxiaTemp.magiWindlashReadyAt` / `magiDilationReadyAt` / `magiFirefallReadyAt` / `magiStormboltReadyAt`) — else a doomed cast would re-fire every prompt until the cooldown lapsed. Dilation and Stormbolt **also** gate on their affliction (Aeon via trigger `015`; Sensitivity has no capture yet) so they skip when the aff is already up from another source. The rotation respects the shared ~1s global BR cooldown (`ataxiaTemp.brGlobalReadyAt`) and arms it on its own fire.

**Bloodboil is NOT a battlerage.** It's an Elementalism **main skill** (75 mana, 4s equilibrium) that takes the **equilibrium slot** in `magiBashing`, alongside — not instead of — the battlerage. `ataxiaBasher_magiShouldBloodboil` (basher/001) fires it to **cure** (3+ real afflictions while OUR own tree tattoo is on balance, via `ataxiaTemp.usedTree`) or to **heal** (with the Hot Springs Mnemosyne boon it also restores 25% max HP + 5% willpower at HP% < 60, like the Shaman's invoke-regeneration; flag `magiHotSprings`, no client-side cooldown).

**Reload-safety note:** `battleRage_Timers` (and `tBals`, `shape`) get idempotent load-time inits (`X = X or …`) at the top of basher/001, and `bashStats` in basher/003. These were previously created only in `levilogin()`, so a SYSUPDATE/reload that didn't re-fire login left them nil and the always-live rotation code crashed.

Line catalog + capture status: [denizen-lines-catalog.md](denizen-lines-catalog.md).

---

## Rage floor — threshold gear (v4.7.141)

Some gear pays a flat damage bonus **while battlerage stays at or above a threshold**
(live example: *"Your attacks will deal 23% bonus damage so long as you have 40
battlerage or more."*). Spending down through that line silently forfeits the bonus on
every attack until rage rebuilds, which makes "spend freely" vs "hold the line" an
economics question rather than a style choice.

**Policy.** `ataxiaBasher.rageFloor = N` (command `bash floor <n|off>`) makes every
rotation spend only the SURPLUS: an ability costing C fires at `C + N`. One helper does
it all — `ataxiaBasher_rageAfford(rage, cost)` (basher/001) — wired into the generic
assembler, `standardBattlerage`, `crowdControlBattlerage`, and the class-owned
bard/blademaster/magi/monk (001) + Golden Dragon/Psion (002) rotations.

- **nil / 0 = off**, and provably behaviour-identical (the pre-existing battlerage suites
  pass unmodified — that's the regression guarantee).
- **Culling reap is never floored.** An execute that ends the fight outright dominates a
  per-swing multiplier, and flooring it (76 rage at floor 40) would idle the cooldown.
- **Clamped to 46.** Rage caps at 100 and the priciest gated ability costs 54 (rageraze
  `bigRage`); above a 46 floor that ability could never be afforded, and a rotation that
  *banks* for an unaffordable cast (Golden Dragon's control-first rule) would stop
  producing battlerage entirely.
- Golden Dragon's banking rule composes cleanly — a control just banks until `cost +
  floor`. The in-flight pick replay is deliberately NOT re-checked against the floor: the
  pick was floor-validated when chosen, and command stability across the 0.3s
  `addclearfull` re-queue loop outranks re-litigating it mid-flight.

**Blademaster costs** (the class this shipped against): reap 36 (exempt), spinslash 36,
daze 26, headstrike 25, nerveslash 22, leapstrike 14. At floor 40 the whole kit stays
reachable (leapstrike from 54, spinslash from 76).

## Rage probe — measuring the bonus (`bash probe`)

`basher/009_Rage_Probe.lua` answers "does the bonus exist, does it apply to our bash
attacks, and how big is it" from ordinary play — no A/B protocol needed, because rage
oscillates across the threshold naturally while bashing.

**Method.** One hook in trigger `350_Damage_Dealt` (placed BEFORE the crit flag resets)
records each **non-crit** damage line as `{rage, damage, mob, class}`. Crits are counted
but excluded — the 16x/32x/64x tail swamps a 23% signal. Samples are keyed by mob **and**
class (denizen armour differs; a class switch would blend two damage profiles) and
FIFO-capped at 1500 so the saved `ataxiaBasher` table stays bounded.

| Command | Purpose |
|---|---|
| `bash probe on` / `off` | start/stop recording (samples are kept when off) |
| `bash probe report [filter]` | per-mob mean hit at `>= threshold` vs `<`, plus the ratio — a real +23% reads as **~1.23** |
| `bash probe bands [filter]` | mean per 10-rage band — locates the REAL breakpoint instead of assuming 40 |
| `bash probe at <n>` | move the threshold and re-analyse the same samples |
| `bash probe dump [n]` | raw recent samples for offline analysis |
| `bash probe clear` / `status` | reset / show state |

**Reading it honestly.** Hits with rage inside a **±4 band** around the threshold are
discarded: `ataxia.vitals.rage` is last-prompt (pre-attack) data, so boundary hits
misclassify. Trust a ratio only with **≥30 non-crit hits per bucket on the same mob** —
the report flags thin rows. The per-mob rows are the answer; the TOTAL row mixes mobs and
is only a sanity check.

**Deferred:** a full A/B trial harness (labelled windows accumulating `bashStats` deltas,
kills/hr + non-crit dmg/min, ABBA interleaving, corruption guards for stats-reset/death/
SYSUPDATE) is designed but intentionally NOT built — the probe is expected to settle the
question first. Note if it is ever built: **Mnemosyne is disqualified as a trial venue**
(Reaper's +1%/kill drift, per-run boon rosters, ripple-scaled mob mixes).

## Cooldown truth — the game's own ready lines (v4.7.167)

Any cooldown with no fire-line trigger behind it was a **guess**: the rotation stamped an
epoch at send time (002:1512) and compared it against a hardcoded `cd` constant baked into
the rotation table (`RW_BR` / `DW_BR` / `PSION_BR` / `GDRAGON_BR` in basher/002 — e.g.
Etch's `cd = 23` at 002:1460, tested at 002:1501). That guess is wrong in **both**
directions:

- **too slow** when the real cooldown is shorter than the constant (boons, gear, stat
  reductions), so the ability idles after the server had already made it available;
- **too fast** when a stamped pick never executed — the `addclearfull` rebuild wiped the
  queued line, the round was refused for broken arms, the target died — so the rotation
  believes an ability is spent that never fired.

The server settles it. Achaea names the exact ability coming off cooldown, in two
wordings:

> You can use Collide again.
>
> Your Collide ability could be used again but you lack the necessary Rage.

The second is simply the first seen through an empty rage bar — the cooldown expired, we
just cannot pay for it yet. **Both mean READY NOW.** Trigger `328_Battlerage_Ready.lua`
matches both patterns (328:34-37) and calls `ataxiaBasher_brReady(verb)`
(`basher/011_Battlerage_Ready_Lines.lua:91`), which is deliberately **class-agnostic**:
the verb is captured from the line, lower-cased, stripped of non-letters, and looked up in
`BR_READY_MAP` (011:60-81) to find the epoch table and key that own it. Clearing that
stamp is what "ready" means to the rotation loops — they test `(now - stamp) >= cd`, so a
nil stamp is unconditionally ready. An unknown verb is ignored, which is what makes it
safe to leave the trigger on for every class.

Two details are load-bearing:

- **Culling blade routes elsewhere** (`BR_SHARED`, 011:85-87). It is gated on
  `ataxiaTemp.bladeCooldown` — a flag owned by the culling trigger, not a rotation stamp —
  so a `Cullingblade` ready line clears the flag instead.
- **A ready ability is by definition not the one still in flight.** If a pending replay is
  holding that same verb, `brReady` drops it (011:110-113) so the next round re-decides
  rather than replaying a pick whose cooldown the game just reset.

**Not yet wired for Blademaster or Magi.** `BR_READY_MAP` currently lists only the four
rotations that keep their own epoch tables — Runewarden, Golden Dragon, Psion,
Depthswalker. The Blademaster and Magi timestamp cooldowns described above
(`bmHeadstrikeReadyAt`, `bmNerveslashReadyAt`, `magiWindlashReadyAt`,
`magiDilationReadyAt`, `magiFirefallReadyAt`, `magiStormboltReadyAt`) have no entry, so
those two rotations still run on the hardcoded constant. The trigger and the handler are
already class-agnostic, so extending the feed is cheap — but note the shapes differ: a
`BR_READY_MAP` entry is a `{table, field}` pair cleared as `ataxiaTemp[tbl][field] = nil`,
whereas the Blademaster/Magi values are flat `ready-at` epochs in `ataxiaTemp`, so they
would need a second branch (clearing the scalar) rather than a new row.

Trigger `329_Battlerage_Global_Cooldown.lua` — "You must wait a short time before you can
use a battlerage ability again." — is **the same signal inverted**: the server telling us
an ability is *not* ready. 328 is numbered immediately before it on purpose. Together they
bracket the true window from the server rather than from our arithmetic. 329 arms the ~1s
global stamp (`ataxiaTemp.brGlobalReadyAt`, 329:44) and, because a *rejected* battlerage
did not land, drops the in-flight hold on every owned rotation (329:53-55) so the replay is
not re-sent straight back into the same rejection. Its send-side cooldown stamp
deliberately stays — it self-heals on its own timer, and clearing it there would let a
rejected ability be retried instantly, forever.

Live evidence: the 2026-07-30 Runewarden Mnemosyne log announced Collide, Bulwark, Etch
and Cullingblade this way repeatedly while the rotation sat rage-starved — roughly ten free
cooldown facts in three minutes, every one discarded. The pre-existing gag
(`006_GAG.lua:48-50`) hides only the **Chaosgate** forms of these lines, so adopting the
generic forms cost no existing behaviour.

### The general rule: every owned rotation needs a fire line AND a refusal line

Any rotation that tracks its own cooldowns without a real timer needs **both**:

- a **fire line** to confirm the ability actually went out — restart the cooldown from the
  moment it landed, and release the in-flight pick replay; and
- a **refusal line** to cancel a pick that did not — drop the replay so the next round
  re-decides instead of re-sending a command the server just rejected.

An ability with neither burns cycles invisibly, and the log will not obviously show it.
That is exactly what happened to Runewarden **Etch**: the one entry in `RW_BR` with no
fire-line trigger, so its ~3s pick replay (`ataxiaTemp.rwBrPending`, tested at 002:1489)
had nothing to release it. After the queued etch really fired, the next two rebuilds
re-queued the *same* etch and the server rejected both, back to back. `375_Runewarden_Etch_Landed.lua`
now captures the fire line ("You trace the outline of a rune in the air with <weapon>...")
and calls `ataxiaBasher_rwConfirm("etch")` (002:1467), which restamps the cooldown and
clears the hold. The ready lines above are the third leg of the same structure: they cover
every ability whose fire line we have not captured yet, and they cost nothing to add.


## Rage-Fuelled: a kill banks a free battlerage (v4.7.179)

Mnemosyne boon — *"When slaying a denizen, your next battlerage attack will cost no
resource."* A kill banks **one** free battlerage. It is a **state, not a timer**: the charge
sits in `ataxiaTemp.brFreeCharge` until a battlerage actually goes out, mirroring the game.

### Why it is a two-line change and not a per-rotation rewrite

`ataxiaBasher_rageAfford(rage, cost)` is already the **single** gate every rotation's
affordability check runs through — 37 call sites across the shared assembler, the owned
`GDRAGON_BR` / `PSION_BR` / `DW_BR` / `RW_BR` tables and the per-class handlers. So:

```lua
function ataxiaBasher_rageAfford(rage, cost)
  if ataxiaBasher_brFree() then return true end   -- Rage-Fuelled: this one is free
  local floor = tonumber(ataxiaBasher and ataxiaBasher.rageFloor) or 0
  return (tonumber(rage) or 0) >= ((tonumber(cost) or 0) + floor)
end
```

lands the boon on **every class at once**. It short-circuits the **rage floor** as well, which
is correct rather than incidental: the floor exists to preserve a spendable surplus, and a
free ability consumes no surplus.

### The one path that needed explicit handling

**Culling reap deliberately bypasses `rageAfford`** to stay floor-exempt (`basher/001:849,
897, 1031`; `basher/002:202, 471, 1268, 1493` — seven sites testing `rage >= 36` directly).
It would therefore have been the single path the boon missed — and a free AoE execute is the
best thing a charge can buy. Now `(rage >= 36 or ataxiaBasher_brFree())`.

### The commit point, and why it got consolidated

`ataxiaTemp.brGlobalReadyAt = ... + 1` marked "a rotation is committing to a battlerage" in
**six** separate places. Arming the ~1s global cooldown and spending the free charge have to
stay in lockstep, and a seventh call site added later that remembered one but forgot the
other would leak a free battlerage **silently** — no error, no refusal, just a charge that
never gets spent. Both facts now live in one function:

```lua
function ataxiaBasher_brSent()
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.brGlobalReadyAt = (getEpoch and getEpoch() or 0) + 1
  ataxiaTemp.brFreeCharge = nil
end
```

The pre-existing rotation suites passing **unchanged** is what proves that consolidation
behaviour-identical when the boon is absent — a stronger check than the new tests.

### Spent on send, not on a fire line

Several battlerage abilities have no fire-line trigger at all (Runewarden Etch had none until
v4.7.166, and its trigger was then dead until v4.7.170), so a confirmation-based spend would
silently never fire for them. The error directions are **not symmetric**:

| We believe | Reality | Cost |
|---|---|---|
| spent | still banked | one missed free cast; self-corrects on the next kill |
| banked | already spent | one rejected command |

Both mild; send-based picks the quieter one.

Armed in `340_Slain`, which is already denizen-gated on a numeric `target` — so it cannot arm
off a player kill, and no new gating had to be written. Lifecycle is the standard boon shape:
`mnemRageFuelled` from trigger `mnemosyne/051` + the `BOON CLAIM` intercept, reset on run
start, cleared on the confirmed run end along with any banked charge.

### Rage-Fuelled picks the DEAREST ready ability (v4.7.189)

Each rotation table is ordered by value-per-rage -- cheap reliable fillers sit near the top
*because* they are affordable. A free cast makes that the wrong question, so `brPickOrder`
re-sorts descending by cost while a charge is banked and returns the table untouched
otherwise. Ties break on the table's own index rather than being left to `table.sort`, which
is **not stable in Lua**: several rotations carry two abilities at the same cost, and an
unstable sort would make the pick vary between identical rounds -- which the in-flight replay
would then faithfully repeat.

### The charge leaked for seven of eleven rotations (v4.7.192, found by review)

The READ side (`rageAfford`) was global from day one; the SPEND side was wired only where an
`ataxiaTemp.brGlobalReadyAt` assignment already existed to be replaced. Seven rotations never
had one, so they read the charge and never cleared it -- one kill made every battlerage free
for the rest of the run. Fixed with `ataxiaBasher_brCommit(cmd)` wrapping the CONSUMPTION
points. **Rule: when you make a read global, audit the write globally -- and a migration that
works by replacing an existing line silently skips every site that never had that line.**

### One consequence found while counting the call sites

The 37 sites are 32 in `basher/001` (shared assembler + per-class handlers), 4 in
`basher/002` (the owned rotations) and **one in `basher/010`** — the Mnemosyne card layer,
which uses `rageAfford` to ask *"can we afford the battlerage that cashes in this card's
affliction?"* before spending a Covenant/Xylthus charge.

A banked Rage-Fuelled charge makes that answer `true`, which is **literally correct** — the
payoff really is free — but the two do not compose perfectly. The card plants its affliction
on *confirmation*, a round later, by which point the free charge has usually been spent on
whatever the rotation picked first. So the card can be drawn on the strength of a free cast
it never actually gets.

This is an inefficiency, not a bug, and the guard against it is already there in another
form: the card also requires its payoff to be **off cooldown** (`ex.ready()`), so it will not
draw into a payoff that cannot fire at all. Left alone deliberately — tightening it would
mean the card layer reasoning about charge ownership across rounds, which is a lot of
coupling for a card that fires every 45s.

Tests: `src_new/tests/test_rage_fuelled.lua`.


## v4.7.193 -- the eighth culling gate, and the replay-record convention

**Culling reap has EIGHT gates, not seven.** v4.7.179 added `or ataxiaBasher_brFree()` to the
seven owned ones (`001:868`, `001:916`, `001:1050`, `002:234`, `002:585`, `002:1433`,
`002:1659`). The eighth is the SHARED branch inside `ataxiaBasher_assembleBattlerage`
(`001:~1183`) -- the branch every class that does NOT own a rotation actually runs: Infernal,
Paladin, Unnamable, Serpent, Apostate, Pariah, Alchemist, Jester, Occultist, Priest, Sentinel,
Sylvan, Druid, the Elemental Lords, most Dragons. It compares `ataxia.vitals.rage >= bigRage`
directly rather than calling `rageAfford`, which is exactly why a shape-based sweep skipped it.

Nothing leaked -- the charge stayed banked and was spent on a cheaper battlerage further down
the same function -- so it was silent. But a free AoE execute is the single best use of a
charge, and the majority of the roster was declining it. Fixed to
`rage >= bigRage or ataxiaBasher_brFree()`.

**Replay records store the ROTATION KEY in `verb`.** `basher/011_Battlerage_Ready_Lines.lua`
releases a held pick with `pend.verb == field`, where `field` is the `BR_READY_MAP` key. The
canonical record is `{ verb = ab.key, cmd = <full command>, at = nowT }` -- Runewarden and
Depthswalker always did this. Psion stored `verb = ab.cmd` and was never released (fixed).
Golden Dragon also stores `ab.cmd` and works only because its four commands happen to equal
their keys; that is a coincidence, not a design, so do not copy it into a fifth rotation.

**One resource spender per assembled round.** The chain is a single queue entry, so a helper
gating on current balance/word/shin state cannot see what an earlier element of the same chain
already claimed. Blademaster now threads `shinSpent`; Depthswalker now threads `wordUsed`. When
the cooldown stamp lives inside the helper, the caller must skip the CALL, not the result.
