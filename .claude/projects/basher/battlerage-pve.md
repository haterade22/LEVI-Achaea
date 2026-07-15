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

Afflictions arrive from **any** source — our battlerage, proc-boons (Wayward Heir → random BR aff / charm, Haskor's Bravado → recklessness, Temporal Anomaly → aeon), or groupmates — and LEVI captures them all in `ataxiaTemp.denizenState[id].affs` (see `08_Denizen_State`).

## How the LEVI basher uses this
- **Per-denizen state** (`basher/008_Denizen_State.lua`): each mob's afflictions/HP tracked with real durations (lazy-expiring), PvP-inert. `ataxiaBasher_dsExploit(id)` returns the ability that cashes in the mob's current state (shielded→shatter, reckless/feared→headstrike, sensitivity/inhibit→burst, ablaze→fire).
- **Rotation** (`ataxiaBasher_blademasterBattlerage`) spends rage by priority so it never idles, and cashes afflictions in for bonus damage. Priority **in Mnemosyne** (survival > speed):

  **Culling Blade → Stun/Amnesia/Aeon/Clumsy (hit-prevention) → damage battlerages → other afflictions → small damage**

  Outside Mnemosyne it's damage-forward (mitigation drops below the damage abilities). Cooldowns come from the shared `battleRage_Timers` (triggers 330–333) where tracked, else a reload-safe **timestamp** cooldown.

## Blademaster's six (this character)
| Ability | Cmd | Rage | CD | Type | Aff / note |
|---|---|---|---|---|---|
| Leapstrike | `LEAPSTRIKE` | 14 | 16s | damage/execute | cheap filler |
| Shatter | `SHIN SHATTER` | 17 | ~global | shield breaker | on a shielded mob |
| Nerveslash | `NERVESLASH` | 22 | 31s | afflicting | **Weakness** |
| Headstrike | `STRIKE … HEAD` | 25 | 23s | **conditional dmg** | bonus vs **reckless / feared** |
| Daze | `SHIN DAZE` | 26 | 33s | afflicting | **Stun** — the key mitigation |
| Spinslash | `SPINSLASH` | 36 | 23s | damage | big single-target dump |
| Provoke | `PROVOKE` | 32 | 20s | taunt (lvl 100) | forces the mob onto you (inverse of charm; costs 2.5s bal/eq) |

Line catalog + capture status: [denizen-lines-catalog.md](denizen-lines-catalog.md).
