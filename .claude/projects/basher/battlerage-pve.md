# Battlerage for PvE (bashing / tower-climbing)

Battlerage abilities are the **only** class-adjacent abilities in Achaea that are useful **on denizens** (they do nothing to players). Everyone gets 6 per class via the **Attainment** skill (unlocked by levelling: 6, 10, 20, 35, 50, 65; Provoke at 100). They're powered by **Rage**. For a bashing/tower-climber, using them well is a big deal — this doc is the reference the LEVI basher is built around.

## Rage — the resource
- **Gained** by doing damage to denizens, at a constant rate tied to your attack speed. Multiple simultaneous hits still only grant the **first** hit's rage. Group members share a % of your rage gain (2 ppl 10% … 15 ppl 0.3%).
- **Fades** after **15s** of not using or gaining rage (`The surge of terrible rage leaves you.`), so keep attacking.
- **See it:** prompt `*R` (custom) / `R`; or `BR` / `SHOW RAGE`. LEVI reads it as `ataxia.vitals.rage`.
- **Global cooldown:** there is a **~1-second global cooldown** on ALL battlerage abilities (`You must wait a short time before you can use a battlerage ability again.`). Queuing a second BR inside that window wastes it — LEVI tracks this (`ataxiaTemp.brGlobalReadyAt`, trigger `329`) and skips a BR while it's up.
- Each ability also has its **own** cooldown + rage cost (`AB ATTAINMENT <ability>`).

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

Afflictions arrive from **any** source — our battlerage, proc-boons (Wayward Heir → random BR aff / charm, Haskor's Bravado → recklessness, Temporal Anomaly → aeon), or groupmates — and LEVI captures them into `ataxiaTemp.denizenState[id].affs` (see `008_Denizen_State`). **Capture status:** **charm, recklessness, aeon, weakness, stun** are captured from real game lines (triggers `011`–`020`, applied/ended pairs); **feared, sensitivity, clumsy, inhibit, amnesia** are not yet captured.

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
