# LEVI-Achaea Changelog

---

## 2026-07-24 — README overhaul: Mnemosyne suite, Dementia Mapper, bashing HUD (docs only)

The GitHub README had fallen behind the last two months of work — no mention of the Mnemosyne
systems at all. Added a **Mnemosyne Suite** feature table plus a full deep-dive section (run
telemetry with the serial-queue/gating/error-recovery design, per-ripple 4×4 mini-map,
run history + affix library, auto-explorer, `BOON CLAIM` class integration, `mnem` command
reference), a **Dementia Mapper** standalone-package section with download pointer, a
**Bashing HUD** row in the basher feature table, and refreshed the repository-structure tree
and documentation index (`dmap_src/`, `.claude/projects/mnemosyne/`, CONTRIBUTING, artefacts +
limb-mechanics references). No code or version change — README/CHANGELOG only.

---

## 2026-07-23 — New: standalone Dementia Mapper package (dmap 0.1.0)

A second, self-contained Mudlet package in this repo (`dmap_src/` → `dmap_build.sh` →
`Dementia_Mapper.mpackage`) that maps + auto-explores the Mnemosyne with **no LEVI dependency**.
The dementia-tolerant map (BFS relayout, known-exit-graph routing, `Room.WrongDir` wall
condemnation, ice-slip handling) and the auto-explorer are ported from `mnemosyne/005_Ripple_Map`
+ `008_Explorer` into a `dmap` namespace, **decoupled from the basher**: navigation only, with
combat as an optional pluggable hook (`dmap attack <cmd>`; default is map-only — the sweep waits
for you to clear each room). Own denizen tracking from `gmcp.Char.Items` (correct `attrib`
flag-set). Commands: `dmap map|show|hide|status|explore|attack`. 18 ported-logic unit tests
(`lua dmap_src/tests/test_dmap.lua`). See `dmap_src/README.md`. Does not touch the LEVI package.

---

## 2026-07-23 — charstats: order-independent knight weapon-spec reads (v4.7.102)

The final GMCP-audit item. `004_ataxia_Vitals_Update` already parses `Char.Vitals.charstats` by name into `ataxia.vitals.knight` (the weapon Spec, unprefixed), but **33 combat sites** re-read it positionally with exact strings — `gmcp.Char.Vitals.charstats[3]/[4] == "Spec: Dual Blunt"`. The `charstats` array order isn't guaranteed (Runewarden's Spec lands at `[3]`, Infernal's at `[4]`), so the code duplicated both indices to cope, and `Login_Function:176` compared `charstats[3] == "Dual Cutting"` **without** the `"Spec: "` prefix every sibling used — a permanently-dead branch (Runewarden Dual-Cutting auto-wield never fired).

All 33 sites now read the order-independent `ataxia.vitals.knight == "X"`: the five attack aliases (152–156), `Engaged_Disengage`, `Login_Function`, `Limb_Counter_Window`, `276_Limb_Prompt`, `637_Target_Left`, and `004_dealt_limb_damage`. The `[3]`-vs-`[4]` hedges collapse to a single check, and the dead login branch is fixed. Behaviour-identical otherwise; a server-side charstat reorder can no longer silently disable knight weapon-spec dispatch.

**Login timing fix:** `levilogin()` resets `ataxia.vitals = {}` and runs its wield branches synchronously, before the first `Char.Vitals` event repopulates `knight` via the parser — so login now seeds `ataxia.vitals.knight` from the live charstats (order-independent scan) before those branches. In-combat callers already have it populated.

Deferred (still positional, need parser additions + intent analysis): the Form/Stance/Kata/Age reads (`shikudo`, `depthswalker`, `Engaged_Disengage`/`Login` stance-vs-form detection) and two display-only debug echoes. Tracked in the backlog.

---

## 2026-07-23 — GMCP field captures: affliction cures + defence descriptions (v4.7.101)

Two more audit fields we were dropping, now captured as reference tables (additive, no behaviour change):

- **`Char.Afflictions.cure`** → `ataxia.affCures[aff] = "<cure command>"` (e.g. `"EAT GOLDENSEAL"`), accumulated in `004_Aff_gains_losses` (List + Add). The server's authoritative cure command per affliction, available for the manual-cure paths instead of re-deriving from the hardcoded herb table.
- **`Char.Defences.desc`** → `ataxia.defenceDescs[def] = "<description>"`, accumulated in `001_Defence_API` (List + Add). Authoritative "what this defence does" text, no client-side table to maintain.

Wiring these into the manual-cure branches / a `def info`-style display is a follow-up (needs live verification); this ships the data layer.

**Deliberately skipped** (stay in backlog, need live verification): `IRE.Target.Set` retarget integration (touches the basher's target-gone handling — risky blind, and the server target id is already available via `IRE.Target.Info.id`); `Room.Info.details` helper (the ~44 call sites are almost all inside the bundled third-party mudlet-mapper, which shouldn't be churned — LEVI-core has only ~2, so the dedup value isn't there).

---

## 2026-07-23 — GMCP consumers: chat, skills, time, status, disconnect (v4.7.100)

A batch of GMCP-audit items, all additive/low-risk data plumbing.

- **New `030_GMCP_Consumers.lua`** registers passive handlers (reload-safe, kill-before-register) that stash server data into `ataxia.*`, none changing combat: **`Core.Goodbye`** → `ataxia.lastGoodbye` + a loud echo, so an unattended basher records *why* it dropped (idle-kick vs death vs boot); **`IRE.Time`** → `ataxia.time` (was negotiated but never read); **`Char.StatusVars`** → `ataxia.statusVars` caption map; **`Char.Skills.Groups`** → `ataxia.skills` `{skillset = rank}` (requested once at login via `Char.Skills.Get {}`) so future gating can check real skill rank; **`Comm.Channel.List`** → `ataxia.channels` authoritative channel→caption map.
- **Chat off the deprecated `Comm.Channel.Start` event.** The active handler (`update_windows/001_showChat`) now registers on the non-deprecated `Comm.Channel.Text` and reads the channel as `Start or Text.channel` — byte-identical behaviour while the server still sends `Start`, and it survives if the server drops it. (The legacy `003_Chat_Capture_Things` handler was already disabled dead code, left untouched.)

**Deliberately skipped:** `Comm.Channel.Players[].channels` for NDB citizenship — it only lists orgs *shared with you*, mixed city/guild/clan with no reliable way to tell which is the city, and the NDB drives enemy highlighting/targeting, so the corruption risk outweighed the marginal gain. Stays in the backlog.

---

## 2026-07-23 — Explorer Room.WrongDir + denizen-HP attribution guard (v4.7.99)

Two more GMCP-audit items, both in the Mnemosyne/bashing path.

- **`Room.WrongDir` — instant failed-exit detection.** The server sends `Room.WrongDir` (the non-existent direction) the moment you try to move through a wall. A new handler condemns that exit and prunes it from the ripple-map's known-exit graph immediately, instead of waiting out the ~10s `MOVE_TIMEOUT` + retry. Because `WrongDir` fires *only* for a genuinely nonexistent exit, it cleanly separates a wall from an ice-slip/prone/lag (which keep their own retry paths), and pruning the dementia-faked exit stops `pathKnown`/relayout re-routing through it — the routing fragmentation behind the explorer's "nowhere left to patrol / just quits" dead-ends. Only acts on an in-flight explorer move. 2 new tests.
- **Denizen HP attribution guard.** `010_Prompt_Running` fed `gmcp.IRE.Target.Info.hpperc` into the per-denizen state keyed by our `target`. But `hpperc` describes the server's authoritative target (`Info.id`), so on retarget-lag/illusion (when `Info.id != target`) it wrote the server target's HP onto the wrong denizen's row. Now it feeds only when `Info.id` agrees with `target`, consuming the previously-ignored `Info.id` field.

---

## 2026-07-23 — GMCP targeting safety + Splinterbark tree-curing (v4.7.98)

Three fixes from the GMCP capability audit, plus a Mnemosyne self-harm safety.

- **Denizen targeting honours the `attrib` flag set.** `Char.Items` `attrib` is a set of characters (`m`=monster, `d`=dead, `t`=takeable, `x`=should-not-be-targeted/loyal-to-city-or-player), but `003_ataxia_RoomContents_Update.lua` matched it by whole-string equality. Now it tests membership: it excludes `x` (protected/loyal NPCs — previously they leaked into `ataxia.denizensHere` **and** got written to the persistent auto-learn `targetList`) and `d` (corpses). The `Char.Items.Add` path additionally never checked `d` and lacked a nil-guard, so a corpse added to the room became an attackable "denizen" — both fixed. Mirrored in the `002_showRoomItems` display list.
- **`Char.Name` self-exclusion bug.** `Stormhammer_Targeting.lua` and `Party_Magi_Coordination.lua` compared a name **string** against the `gmcp.Char.Name` **object** `{name, fullname}` — never equal, so Stormhammer could auto-target the caster and the Magi-coordination self-check never fired. Now compare against `gmcp.Char.Name.name`.
- **Splinterbark tree-curing safety (Mnemosyne).** With the `Splinterbark` ongoing effect active, every tree-tattoo touch bleeds you and inflicts a random malady. The bot now sends `curing tree off` the moment the status screen shows Splinterbark (transition-guarded, gated on being in a run) and `curing tree on` when the run ends. Telemetry-independent (plain status-screen trigger). 4 new tests.

---

## 2026-07-23 — Bashing HUD: live mob health bar (v4.7.97)

The Mob health bar now renders reliably and tracks the fight live. It reads the denizen's HP% from the denizen-state layer (`ds.hpp`), which we feed every prompt from `gmcp.IRE.Target.Info.hpperc` — so it survives the render moment when the raw GMCP field is briefly nil right after a retarget (the reason the bar never appeared in Mnemosyne). It falls back to the live GMCP field for a freshly-acquired target the prompt hasn't fed yet, and is skipped only when neither source has a value. The HUD now also refreshes on `gmcp.IRE.Target.Info` (pushed each combat round), so the Mob bar — and the other live bars — update as the fight progresses instead of only on room/target changes. Refresh handlers are guarded so they no longer stack up on a SYSUPDATE reload.

---

## 2026-07-18 — Bashing HUD: read HP/WP/EP straight from GMCP (v4.7.96)

The HUD's HP/WP/EP bars now compute from `gmcp.Char.Vitals` (hp/maxhp, wp/maxwp, ep/maxep) directly, and XP from `gmcp.Char.Vitals.nl`, instead of the derived `ataxia.vitals` copy — the live GMCP values, with no dependence on the vitals-update pipeline having run. Rage still comes from `ataxia.vitals` (it's parsed out of `charstats`, not a top-level GMCP field). Nil-safe as before (a bar it can't compute is skipped).

---

## 2026-07-18 — Mnemosyne explorer: stop quitting while a `?` room is still reachable (v4.7.95)

The auto-sweep would give up ("nowhere left to patrol") with an unexplored room (a gold `?` on the mini-map) still on the grid — and couldn't route back to it. Cause: the map places every room from the **exit graph** (so it renders + shows `?`), but the explorer routed only over the **walked-edge graph**, which needs each move's direction to be determinable. In the demented tower (Creville's Legacy fakes gmcp exits) that determination can fail, so a visited room's walked edge is silently dropped — fragmenting the walked graph so BFS can't reach the room.

- **Known-graph routing fallback.** New `MAP.pathKnown` — BFS over the known-exit graph (∪ walked edges), the same graph `relayout` uses to place every room. Backtrack and patrol now try `MAP.path` (walked) first, then `MAP.pathKnown`, so a walked-graph gap can't strand a placed, unexplored room. A wrong (faked) exit just fails the move, which marks it failed and self-corrects.
- **One-shot failed-exit retry.** Before quitting, if any exit was blacklisted this ripple, the sweep clears `explore.failed` and re-decides once (`_retriedFailed`) — a spurious move-timeout or lingering prone shouldn't permanently strand a real exit. Reset per ripple.
- Test: `MAP.pathKnown` routes over the exit graph when the walked graph is fragmented. Suite **316/316**.

---

## 2026-07-18 — Mnemosyne explorer auto-resumes on GO + HUD shows in the tower (v4.7.94)

- **GO auto-resumes the sweep.** After you pick a boon and wade, the new wave's `GO!` now auto-resumes a boon-screen pause: the GO trigger → `exploreOnGo` sends `look` (the ripple's holding room, whose only exit is `down` into the 4x4 — and dementia can otherwise leave a stale room around you), then un-pauses the sweep. So a full dive runs hands-free through the boon screens; `mnem explore on` still resumes manually. Resume logic is now shared via `_exploreResume()`.
- **Bashing HUD now shows in Mnemosyne.** The vitals/DPS/session panel was gated on `gmcp.IRE.Target.Info`, which isn't reliably set in the tower — so the panel (HP/WP/EP bars, DPS, Session) vanished while bashing there, leaving only the target name + class line + denizens. It's now gated on `ataxiaBasher.enabled`; only the **Mob** bar (which genuinely needs the target's hp%) is conditional, so everything else renders regardless.
- Tests: `exploreOnGo` (LOOK + un-pause, no-op when not paused). Suite **315/315**.

---

## 2026-07-18 — Mnemosyne: harden the line-capture so boons can't be dropped (v4.7.93)

Follow-up to v4.7.91. The boon (and effects) capture uses a single-slot lock (`_capturing`): while one capture is active, a new one was **silently ignored**. If a prior capture ever wedged — a stream of lines can keep resetting its silence-timeout so `finish` never fires — every later boon/effects capture was dropped and the report never posted.

- **Fix:** `_captureLines` now **force-finishes** any still-active prior capture (`M._captureForceFinish`) before starting the new one, instead of dropping it. Boons/effects can no longer be lost to a wedged lock.
- Combined with v4.7.91 (post `/boons_offered` immediately, not gated on the slow contemplate chain), boon reporting is now robust end-to-end.
- **Note:** auto-update applies at *login* — a long continuous session keeps whatever version it started on, so this fix (and v4.7.91) only take effect after a re-login. Confirm with `lua ataxiaVersion`.
- Test pins the force-finish behavior. Suite **314/314**.

---

## 2026-07-17 — Bashing HUD polish: session stats + readable numbers (v4.7.92)

Follow-up polish to the v4.7.90 bashing HUD (`windows/001_Limb_Counter_Window.lua`):

- **Thousand separators** on the DPS `Total` (and other counts) — `9737013` → `9,737,013`.
- **New Session block** under DPS: `Kills` / `Crits`, `Gold` gained, and `Time` + kills-per-hour — all read from `bashStats` (`slain`/`crits`/`gainedGold`/`dpsSessionStart`).
- **Class lines restyled** to match the bars — Blademaster `Shin`/`Stance`, Monk `Kai`/`Kata`/`Form`, Runewarden/Infernal `Momentum` now use the same coloured-label, single-line format instead of the old ragged `Label: value` style.
- Added `_fmtNum` (thousand separators) and `_fmtTime` (compact `8m03s` / `1h02m`) helpers.

Syntax-checked; suite 313/313.

---

## 2026-07-17 — Mnemosyne: fix boons never reaching the API tracker (v4.7.91)

The tracker showed monsters for every ripple but the boons stayed on "No boons offered yet." Cause: `_reportBoonsOfferedEnriched` gated the `/boons_offered` POST behind a **BOON CONTEMPLATE enrichment chain** (`contemplate` is ON by default) — one sequential contemplate per offered boon at ~2.5s each. That chain races the *next* ripple's line captures for the single shared `_capturing` slot; when it loses (routine with `mnem explore` sweeping fast), it **stalls and the whole `/boons_offered` is silently dropped**. Even on success it could post after you'd waded, landing the boons on the wrong ripple.

- **Fix:** `onBoonsOffered` now posts `/boons_offered` **immediately** with the name + description read straight off the offer screen — no enrichment gate, no race, correct ripple. That's exactly what the tracker displays.
- Rarity / echo-count / quote were the only things the contemplate enrichment added; they're optional on the API and are still learned locally from the BOONS list (trigger 013) and `mnem boonfill`.
- Test: `test_mnemosyne.lua` pins that `/boons_offered` fires immediately even with `contemplate` ON. Suite **313/313**.

---

## 2026-07-17 — Bashing HUD: health bars, target names, decluttered (v4.7.90)

Reworked the bashing panel in the Limb Counter window (`windows/001_Limb_Counter_Window.lua`) from a raw-number dump into a scannable HUD.

- **Target name** — shows `a HaHaHa lancer  #625689` (from `ataxia.denizensHere[target]`) instead of a bare numeric id.
- **Colored health bars** — the mob and your HP/WP/EP now render as `██████░░░░ 76%` bars, colored green→yellow→red by %, using the `maxhp/maxwp/maxep` GMCP fields. A basher can read "kill imminent" / "getting low" at a glance instead of parsing five raw numbers. All nil-safe — a bar that can't be computed is skipped, never errors.
- **Rage + XP** collapsed onto one line; the redundant Magi/Blue-Dragon willpower echo removed (the WP bar covers it); Shaman `SwiftC` / Pariah `Epitaph` kept.
- **Decluttered** — the PvP lock/affliction readout (`[V3: N branches]`, `[LOCK:%]`) is now suppressed when the target is a denizen (numeric id); the full PvP view is unchanged for player targets.
- **Cleaner sections** — consistent `──` headers, denizen count in the header, and the current target marked in the denizen list.

Bars use block glyphs (`█`/`░`); if a client's font lacks them they can be swapped to ASCII. Syntax-checked; suite 312/312.

---

## 2026-07-17 — Mnemosyne explorer: boon screen pauses (basher stays on) instead of stopping (v4.7.89)

`mnem explore` used to fully **stop** at the ripple's boon screen and, if it had raised the basher, turn it back **off** — so after picking a boon and wading you had to re-enable the basher *and* re-run explore.

Now the boon screen **pauses** the sweep: navigation halts (so you pick a boon and wade) but the basher stays **on**, fully in explore mode (manual / autoLearn / no-flee). `mnem explore on` **resumes** the sweep for the next ripple.

- Implemented as a `explore.pausedAtBoon` flag with `on` kept `true`, so the existing lifecycle still cleanly restores your original basher settings on the *real* stop — leaving the tower, dying, or `mnem explore off` all restore correctly (the tick's leave-tower check runs before the pause gate). No leak of manual/no-flee mode after Mnemosyne.
- The resume path re-asserts the explore-mode basher flags (guards `inMnemosyne` flickering between floors) and resets sweep progress (`hunting`/`patrolQueue`) for the new ripple, **without** re-saving the original pre-sweep state.
- The pause is independent of the run-lifecycle pause (`WHISPER … grow still`) added in v4.7.88.
- `mnem explore status` shows `paused (boon screen)`. The watchdog goes quiet during the pause (no stray `ql`).
- Reviewed (adversarial trace of the state machine: clean, no basher-restore holes; 3 LOW hygiene items fixed). Tests: `test_mnemosyne.lua` +3 (pause / resume-no-leak / paused-tick-still-detects-leave). Suite **312/312**.

---

## 2026-07-17 — Basher: reload-safety hardening + Magi Bloodboil (cure & Hot Springs heal) + Mnemosyne pause (v4.7.88)

**Reload-safety — three more nil-crash globals.** Following the `battleRage_Timers` live crash, an audit of everything `levilogin()` alone initializes (43 globals) found the same "nil after a SYSUPDATE/reload that didn't re-fire login" pattern in two more that always-live code indexes: **`tBals`** (prompt `@tarbals` tag, focus-knock, Anti_Priorities) and **`shape`** (an Earth Lord magma-seethe trigger does `shape = shape + 1`). All three now get load-time idempotent inits at the top of `basher/001_Bashing_Functions.lua` (`X = X or <default>`; `tBals` uses its full shape since `.timers` is indexed). Six other candidates were cleared as guarded/safe.

**Magi Bloodboil — active self-cure + heal, woven into the bash loop.** Bloodboil (Elementalism main skill, 75 mana, 4s eq) now fires from `magiBashing`'s equilibrium slot (battlerage still fires alongside — it is NOT a battlerage). Two reasons:
- **CURE** — 3+ real afflictions while **our own** tree tattoo is on balance. Gated on `ataxiaTemp.usedTree`, which is now set on **both** tree-fire lines (the successful "You touch the tree of life tattoo." *and* the cure-nothing "…glows faintly… leaving you unchanged.", `curing_bals/001`), so it actually latches during bashing (SSC emits the latter). *Not* the target's `tBals.tree`. The count skips `incoming_*` predictions and cured-to-0 stacks.
- **HEAL** — with the **Hot Springs** Mnemosyne boon, Bloodboil also heals 25% max HP + 5% willpower; the basher fires it at **HP% < 60** (like the Shaman's `invoke regeneration`), with no client-side cooldown so the `addclearfull` re-queue can't clobber the pending cast.
- New Hot Springs boon flag (`magiHotSprings`) wired 1:1 with the other Mnemosyne boons (BOONS-list trigger + boon-claim alias + run-start/run-end resets).

**Mnemosyne pause/resume.** `WHISPER … beseech that it grow still` ("You whisper to the Mnemosyne and beseech that it grow still for a time.") pauses a run without ending it server-side — the next wade is the **same** wade. The tracker now resumes via `/run_exists` instead of minting a new `public_id` with `/run_start`. The pause flag clears **unconditionally** on a confirmed run-end (found in review — otherwise a paused-then-ended run with telemetry off would hijack the next fresh wade into a resume that never registers the new run).

**Reviewed** (two adversarial agents): fixed the stale-`paused` run-end bug (HIGH) and the heal-cooldown queue-clobber (MEDIUM). Suite **309/309**.

**Needs one in-game confirmation:** that the "…glows faintly… leaving you unchanged." tree line does put the tree on cooldown (the regain line follows it) — the Bloodboil cure gate assumes so; log evidence supports it.

---

## 2026-07-17 — Basher: crash fixes (eq/balance bars + bashStats) + Magi ashbeast/Kkractle (v4.7.87)

Four fixes from live Magi bashing — two class-agnostic crashes plus two Magi-specific additions.

- **eq/balance bars restored** (`014_Balance_Timers.lua`) — on a fresh/reloaded session the stopwatch globals are nil, so `stopStopWatch(nil)` in `endEQTimer`/`endBalTimer` threw and **aborted the EQUILIBRIUM trigger before `EQHighlight()` ran** — the timers vanished mid-bash. Both now guard `if ataxiaEQStopwatch then … end` / `if ataxiaBalStopwatch then …`. The bars show `0.000` for the first cycle, then correct once the stopwatch is created.
- **`bashStats` never nil** (`003_Bash_Stats_Functions.lua`) — combat triggers indexed `bashStats` before it existed (`attempt to index global 'bashStats' (a nil value)`). `resetBashingStats` now builds a **complete** default (all 15 fields + the `criticals` subtable) and takes a `silent` flag, with a load-time `if not bashStats then resetBashingStats(true) end`. A live table survives SYSUPDATE (the guard skips re-init, so counts aren't clobbered); `loginGold` reads gmcp defensively at load.
- **Ashbeast on the do-not-kill list** (`002_Check_For_Any_Missing_Variables.lua`) — "a blazing ashbeast" is the Magi's own Artificing summon and was showing as a target. Added to the `ownDenizens` default **and** back-filled into existing saves.
- **Aspect of Kkractle boon → ELEMENTAL SURGE** (Mnemosyne) — with this boon, Elemental Surge becomes an AoE fire nuke on every denizen in the room. New `magiKkractle` flag (set by the BOONS-list trigger + boon-claim alias, reset at run-start and confirmed run-end — 1:1 with `bmShatteredStar`); `magiBashing` sends `elemental surge` (no target) when it's up, after the `erode` shield-strip and before stormhammer/horripilation.
- **Magi battlerage double-call fix** — `magiBashing` is invoked twice per cycle (a discarded stormhammer/GUI pre-call in the autobash loop, then the real send). Harmless while Magi used `standardBattlerage` (a pure read), but `magiBattlerage` **arms its cooldowns on fire** — the pre-call would arm them and the real call would send **no battlerage at all**. Split the prep into `ataxiaBasher_magiStormPrep()`; the pre-call runs prep only, the send path runs prep + battlerage.
- Suite **293/293**. Reviewed (single-agent adversarial pass — clean on all four; the double-call was surfaced by an informational note and fixed).

---

## 2026-07-16 — Basher: Magi battlerage rotation — completes the kit + owns culling (v4.7.86)

Magi gets a real rotation, following the Blademaster/Monk pattern. Before this, Magi fell through to `standardBattlerage` (fires only small/large/special), so **Disintegrate, Firefall, and Stormbolt were dead config**, and the shared culling check suppressed the whole rotation.

- **Completed the config** (`_groups.yaml` Magi): added `specialafflict = "cast stormbolt at <t>"` (Sensitivity), `specialuse = "cast firefall at <t>"` (conditional), `raze = "cast disintegrate at <t>"` (denizen shield break). **Cast syntax confirmed vs AB:** all `cast X at <t>` except `squeeze` (no "at").
- **New `ataxiaBasher_magiBattlerage`** — priority: **culling reap (≥36)** → **Mnemosyne Dilation→Aeon** (mob slower, mitigation) → **Firefall on a clumsy/reckless target** (bonus, from any source) → **Stormbolt→Sensitivity** when not sensitive (sets up the burst) → **Squeeze** (+33% while sensitive) → Dilation surplus → **Windlash filler** so rage never idles. Respects the ~1s global BR cooldown.
- **Never fires Disintegrate** — `magiBashing` casts the free `erode` shield strip, so 17 rage on Disintegrate is the worse trade (the Monk shatter-over-spk rule).
- **Magi owns culling** — excluded from the shared culling check (`class ~= "Magi"`, `P and true` for every other class) and reaps at 36 in its own rotation.
- **Cleaned up `magiBashing`** — `assembleBattlerage()` was called **twice** (the second result discarded — a double-arm now that a rotation stamps cooldowns) and had a dead `raze` local; both fixed. Shielded path strips (`erode`) **before** battlerage so a still-up shield doesn't absorb it.
- **Cooldowns confirmed via AB:** Windlash 16s, Dilation 35s, Squeeze 23s, Firefall 23s, Stormbolt 27s. Squeeze uses the real `battleRage_Timers.large` (trigger 331); the rest have no fire-line trigger so they use reload-safe timestamps (incl. Windlash — without a gate it would re-fire a doomed cast for 16s). Dilation/Stormbolt also gate on their affliction so they skip when it is already up from another source.
- Tests: `test_basher_battlerage.lua` +10 Magi cases (culling, Mnemosyne mitigation, Firefall on clumsy/recklessness, Stormbolt→Squeeze, never-Disintegrate, filler, global-cd, PvP-inert). Suite **292/292**.
- **Two-agent adversarial review** caught and fixed: the Sensitivity aff-gate was inert (no capture trigger) → made the fallback timestamp the aff duration; Firefall checked the wrong key `reckless` → `recklessness`; the shielded branch reordered brage-before-erode → restored erode-first.

**Still needs in-game capture (like the other classes):** the **Stormbolt Sensitivity land-line** (to add the capture so the rotation skips Stormbolt when Sensitivity is already up); whether Dilation prints the existing aeon line (trigger 015); that `erode` reliably strips denizen shields. Cast syntax and cooldowns are now confirmed from AB.

---

## 2026-07-16 — Basher: stop double-weaving the swiftcurse recharge (v4.7.85)

The swiftcurse recharge was firing twice in a row, **costing a balance each time**.

- **Root cause: a dead in-flight guard.** `swiftcursing` is set to `false` by `shaman/011` ("You weave your fingers together…") and `shaman/012` ("empowered with another N curses") — but **nothing ever set it to `true`, and nothing ever read it**. The two resets are the only references in the entire codebase. The intent is obvious from them: *mark a weave outstanding when you send it, let the confirm-line clear it* — but the "set" and "check" halves were never written. With no guard, `ataxiaBasher_shamanBashing` re-issued `stand;wield shield;swiftcurse` on the next prompt, before the first weave's confirm-line had landed.
- **Fixed by writing the missing halves**: set `swiftcursing` when the recharge is sent, and skip while one is outstanding. `011`/`012` already clear it, so the existing triggers complete the loop untouched.
- **Paired with a timestamp** (`ataxiaTemp.swiftcurseSentAt`, 3s): a gagged or swallowed confirm-line must not strand the shaman permanently unable to recharge — after 3s we assume the weave was lost and retry. Note `011`/`012` both call `deleteFull()`, so those lines *are* gagged while bashing, making a lost confirm a real possibility rather than a theoretical one.
- Guarded the command assembly so an in-flight skip sends the battlerage alone instead of trailing a bare separator (`brage..sp..""`).

Suite **281/281**.

**Still redundant** (unchanged): `ataxiaBasher_detectSwiftcurseCharge` (`genrunning/004`) infers the charge from two consecutive EQ-only recoveries, which structurally cannot conclude until the recharge has been cast twice — the exact behaviour just fixed. With the in-flight guard in place it should never be the deciding writer, but it's still guessing at something `011`/`012` observe directly.

---

## 2026-07-16 — Basher: Shaman uses swiftcurse regardless of binding (+ two latent bugs) (v4.7.84)

- **Swiftcurse no longer requires the aelkesh binding.** `ataxiaBasher_shamanBashing` gated its swiftcurse branch on `shaman.spiritisbound("aelkesh")`; that check is gone, so swiftcurse is used whether or not the spirit is bound.
- **The default bashType was a typo — `"swiftcure"`, not `"swiftcurse"`.** It never equalled the `bash_type == "swiftcurse"` branch, so the *default* silently fell through to jinx/curse and **swiftcurse was never actually the default**, binding or no binding. Fixed.
- **`curseCharge <= 1` could kill the whole attack.** `curseCharge` is a plain global with no initialiser — nil until the first charge is observed — so a bare compare throws `attempt to compare nil with number`, and `ataxiaBasher_shamanBashing` returns nothing. Now `(curseCharge or 0)`, matching how `genrunning/004:61` already guards it. This mattered more after the two fixes above, which make the swiftcurse branch the common path.
- Also scoped `atk` to a local (it was an implicit global).

Suite **281/281**.

### Noted, not yet changed: the swiftcurse recharge fires twice
`curseCharge` has three writers — `shaman/011` (the real *"You weave your fingers together…"* line → 14), `shaman/012` (the authoritative *"empowered with another N curses"* → N), and `ataxiaBasher_detectSwiftcurseCharge` (`genrunning/004`), which **infers** the charge from **two** consecutive EQ-only recoveries (`eqOnlyCount >= 2`). Since each bare `swiftcurse` is exactly one EQ-only recovery, that heuristic cannot conclude the charge landed until it has been cast twice — while `011` already knows from the first line. Nothing anywhere decrements `curseCharge`. Pending in-game confirmation of `curseCharge` after a single weave before removing the heuristic.

---

## 2026-07-16 — Basher: transmute tops up to 99% (v4.7.83)

- **`transmuteto` 90 → 99**. With `transmuteat` at 70, a gap-filler transmute now refills essentially to full rather than leaving you at 90%. Safe to push: the sip-balance gate means it only ever spends mana in the window server-side sipping can't cover, so a higher ceiling costs nothing while sip balance is up.
- **The migration now covers every default this key has shipped with** — v4.7.70 shipped `transmuteto = 70` and v4.7.82 migrated it to `90`, so a save can legitimately hold either; both now move to `99`. A hand-tuned value is still left alone.
- Default, the rotation's inline fallback, its doc comment, and the wizard display all updated together.
- In practice at 12160 max health: drop to 69% with sip balance down → `transmute 3500` → back to ~98%.

Suite **281/281**.

---

## 2026-07-16 — Basher: transmute earlier — fire at 70% health, top up to 90% (v4.7.82)

- **`transmuteat` 50 → 70**: the Monk gap-filler transmute now starts covering at 70% health (while sip balance is down), rather than waiting until you're half dead.
- **`transmuteto` 70 → 90**: raised alongside it out of necessity. `transmuteat` and `transmuteto` cannot both be 70 — you'd fire at 69% and heal back to 70%, i.e. heal nothing. 90% is where the pre-v4.7.70 code topped up to, so this restores that ceiling while keeping the sip-balance gate that stopped it burning mana every balance.
- **Migrated, not just re-defaulted.** The values are serialized, and the backfill only fills `nil`, so changing the default alone would never reach an existing save. `ataxiaCheckForMissing` now rewrites the old shipped defaults (50→70, 70→90). Safe because `ataxia setup sipping <key> <value>` is advertised but has **no setter** — the panel is display-only — so a stored 50/70 can only be the old default, never a deliberate choice. A hand-tuned value (e.g. 65/85) is left untouched.
- Aligned the rotation's inline fallbacks and the wizard's displayed defaults so all three sources agree — the class of drift that had the old code doing 90/15 while its comment claimed 75/45.

Suite **281/281**.

---

## 2026-07-16 — Basher: capture Ripplestrike/Inhibit + fix its phantom cooldown gate (v4.7.81)

The Ripplestrike fire-line (`You quickly strike <mob> with the tips of your fingers, targeting specific nerves.`) wasn't captured — which surfaced a real bug in the v4.7.76 Monk rotation.

- **Ripplestrike had NO cooldown tracking.** `ataxiaBasher_monkBattlerage` gated on `battleRage_Timers.specialafflict` — **which nothing ever sets**. The shared fire-line triggers (`330`/`331`/`332`) only cover `small`/`large`/`special`, so that gate was permanently `false` → with healing up, RPST re-fired on *every* attack, burning 25 rage against a 27s cooldown it couldn't see. Now gated on a reload-safe **timestamp** (`ataxiaTemp.monkRipplestrikeReadyAt`) stamped by the real fire, matching how Headstrike/Nerveslash already work.
- **New trigger `023_Denizen_Inhibit_Applied`** — sets **Inhibit** (9s, mob cannot heal) on the current target, stamps the 27s cooldown, and gives it the standard line-highlight + `(BR):` echo (orange-red) that charm/recklessness/aeon/weakness/stun/clumsy already had. `inhibit.apply` in `ataxiaBasher_BR_AFFS` was the last `nil` among the hit-prevention/burst afflictions.
- Tests: +2 (respects the cooldown timestamp instead of re-firing; fires again once elapsed). Suite **281/281**. Catalog updated.

---

## 2026-07-16 — Mnemosyne: `mnem boonfill` — learn what boons you already own (v4.7.80)

The catalogue only learns a boon when its **offer screen** goes past — so everything claimed before v4.7.77 existed was unknowable, and the descriptions were gone for good. Except they aren't: `BOON CONTEMPLATE` re-prints the full detail on demand.

- **New `mnem boonfill`** — `BOON CONTEMPLATE`s every owned boon that has no description yet, and writes what it learns into the catalogue. Run `BOONS` first (that's what tells us which boons you own), then `mnem boonfill`. Reports how many it will fetch and roughly how long, then how many it learned.
- Reuses the existing enrichment machinery rather than duplicating it: `_captureContemplate` → `_parseContemplate` already returns `{ rarity, num_echoes_possible, description, quote }`. Sequential with the same 0.5s spacing as the offer-screen path — deliberately not parallel, since each CONTEMPLATE is a captured block and concurrent ones would interleave.
- Trigger `013` now records owned boons into `ataxiaTemp.boonsOwned` as the BOONS list scrolls (not serialised; rebuilt each time). Note the *library* is everything ever **offered**, which is a different set from what you **own** — boonfill is the bridge.
- Only fetches what's missing: re-running it once the catalogue is complete says so and sends nothing.

Suite **279/279**.

---

## 2026-07-16 — Basher: finish the areaKey migration for real + fix the boon library (v4.7.79)

An adversarial deep review (21 findings raised, 11 confirmed, 10 refuted) caught that the areaKey migration was **still** incomplete after two "final" sweeps — and that the v4.7.77 boon library never worked at all on a default install.

**Why the sweeps kept missing sites:** they grepped `targetList[gmcp...`, which only finds *direct* indexing. Every site doing `local area = gmcp.Room.Info.area` and then `targetList[area]` was invisible — as was all of `_groups.yaml`, whose inline Lua isn't a `.lua` file.

- **CRITICAL — `340_Slain.lua:56`**: the single highest-traffic `targetList` writer (every kill) still keyed on the raw area. Under dementia it created a bogus `targetList["the Northern Ithmia"]`, filed tower denizens into a genuine hunting list, and disagreed with `search_targets` (which reads `""`). The bogus entry also made `ataxiaBasher_areabash()`'s `if targetList[curArea]` truthy.
- **HIGH — `_groups.yaml` inline `ataxiaBasher_addmob` / `elevatemob` / `remmob`**: the canonical write path, called from `340_Slain` on every kill. Missed by *both* prior sweeps because `_groups.yaml` holds embedded Lua. This also created a read/write split: `bash room` listed `targetList[areaKey()]` while its own `[E]`/`[R]` links mutated `targetList[<fake area>]` — clicking `[R]` said "not on the list", and `[E]` called `table.remove(t, nil)` → **error**. Echoes now name the tower instead of printing `"Added X to 's target list."`.
- **MEDIUM — `001_Bashing_Functions.lua:547`** (Blood Maiden cloak): a missed consumer *in the file the migration edited*. `targetCount` stayed 0 in Mnemosyne, so bloodshield never fired.
- **LOW — `007_Mob_Damage_DB.lua:99`**: hits recorded against the hallucinated area. Also `or "Unknown"` never fired for the tower — `""` is truthy in Lua — so the empty key now gets a real label.

**Boon library (v4.7.77) — it was dead on arrival:**
- **`onBoonsOffered` was gated on `_inRun()`**, which requires the *remote tracker* enabled **and** tokened (`_auto() = cfg().enabled and _hasToken()`; the shipped default is `enabled = false`). So on a default install the catalogue never learned a single description, and every BOONS row printed the "not learned yet" fallback — forever, with a promise that could never come true. Learning is local data, so it now happens **before** the gate; only the telemetry POST stays gated.
- **`_learnBoon` never persisted** — every other `_historySave()` caller sits behind a telemetry gate, so rarity back-filled from the BOONS list died with the session. New debounced `_historySaveSoon()` (a BOONS list calls `_learnBoon` once per row; this coalesces 30 writes into one).
- **The fallback line is gone** — unknown boons are simply rarity-coloured with no annotation, instead of doubling a 30-row list with placeholders.

Suite **279/279**.

---

## 2026-07-16 — Basher: finish the areaKey migration — aliases + triggers (v4.7.78)

v4.7.74 introduced `ataxiaBasher_areaKey()` but only converted the **scripts**. Everything else still read `gmcp.Room.Info.area` directly — which the incurable-dementia boon fakes — so half the system was keyed on a hallucinated area while the other half used `""`. The two never agreed.

- **Aliases (11 sites)** — `lists/001_Display_Mobs_In_Area`, `002_Display_Mobs_To_Add`, `004_Ignore_Mobs`, `006_Dangerous_Mobs`, `009_Set_Mobs_That_Don't_Break_Shield`, `010_Set_Culling_Blade_Keyword`. This is the reported symptom: the add/list commands read `targetList["the Northern Ithmia"]` (empty) instead of the tower's `""` list, so **nothing showed up to add**.
- **Triggers (4 sites)** — `ataxia_chat_capture/002_Capture_Msg`, `denizen_attacks_misc_lines/004_Denizen_Emotes`, `007_Denizen_Attack_Find`. The last two fire in combat and index `targetList[area]` unguarded.
- `010_Set_Culling_Blade_Keyword` also echoed the raw area while writing to the real key — it claimed to configure somewhere it never touched. Now reports the key it actually wrote (`the Mnemosyne` for `""`).
- **Every `targetList` consumer in the codebase now goes through `ataxiaBasher_areaKey()`** — verified by sweep. Suite **279/279**.

---

## 2026-07-16 — Mnemosyne: boon library — see what your boons actually DO (v4.7.77)

The BOONS list tells you what you own but never what any of it does — it's only `Boon | Echoes | Rarity`. Only the *offer* screen carries descriptions, and once you claim, that text is gone. So we learn every boon we're ever offered and join the two.

- **New all-time boon catalogue** `ataxia.mnemosyne.history.boonLibrary` — `name -> { description, rarity, maxEchoes }`, persisted with the rest of the local history. Populated automatically from every offer screen (`_recordOffers` already parsed `name`/`description`; it now also calls `_learnBoon`). **Merges rather than overwrites**, because each source knows different fields: the offer screen supplies the description, the BOONS list supplies rarity, and the `BOON <name>` detail screen supplies maxEchoes — none may blank a field another filled.
- **BOONS rows are now annotated** (`mnemosyne/013_Boons_List_Row`): each `<name>  <echoes>  <rarity>` row is coloured by rarity and followed by what that boon does, pulled from the library. Rows you've never been offered say so explicitly rather than printing a confusing blank. Rarity back-fills into the library from these rows. Pattern is anchored on the rarity word, verified to match every real row (including multi-word names like `White Heaven's Shattered Star`) and to reject the header, prose, offer lines, and `BOON CLAIM ...`.
- **Rarity colours** `ataxia.mnemosyne.RARITY_COLOUR` / `rarityColour(r)` — common grey, uncommon green, rare cyan, legendary orange, mythical magenta. Names verified against `misc_scripts/007_Custom_Colour_Table` (which wholesale-replaces `color_table` — no `ansi_*` namespace).
- New `ataxia.mnemosyne.boonInfo(name)` for anything that wants to reason about a boon.
- Suite **279/279**.

Note: the catalogue only knows boons this character has been *offered* since the update — it fills in as you climb.

---

## 2026-07-16 — Basher: Monk rotation — spend Inhibit where healing actually happens (v4.7.76)

Delivers the parked Ripplestrike/Inhibit work, now that the trigger condition is known: the wade affix **Sanguine Restoration** — *"Pools of blood shall heal nearby denizens."*

- **New `ataxiaBasher_monkBattlerage()`.** Monk previously fell through to `ataxiaBasher_standardBattlerage`, which only ever fires `small`/`large`/`special` — so the `rpst`/`mind blast` entries added in v4.7.67 were dead config and **Ripplestrike never fired at all**. Monk now owns its rotation (like Bard/Blademaster); no other class is touched.
- **Priority:** (1) **Ripplestrike → Inhibit**, but *only where healing is real* — the `Sanguine Restoration` affix, or a denizen matched by the new `ataxiaBasher.healerDenizens` list. Inhibit stops a denizen healing, so it's dead rage against a mob that never heals. Skipped if the mob already has Inhibit (`dsHasAff`, lazily expiring). (2) damage — `tnk` then `sbp` filler, so rage never idles. (3) surplus → `mind scramble` (Clumsy, mob misses 33%) as mitigation on the no-flee climb.
- **Mindblast is deliberately not prioritised.** Its bonus wants Weakness or Sensitivity and **nothing in Monk's kit applies either** (Scramble = Clumsy, Ripplestrike = Inhibit), so it can never self-enable — it's a flat 25-rage hit unless a boon or groupmate supplies one.
- **`spk` stays unreachable** — both specs break shields free (`shatter` / `rhk`), per v4.7.67.
- **New `ataxia.mnemosyne.hasAffix(name)`** — case-insensitive query over the current run's recorded ongoing effects.
- New `ataxiaBasher.healerDenizens` (empty default, backfilled) — name substrings worth an Inhibit outside Mnemosyne.
- Tests: 7 cases (fires on the affix, doesn't waste it when nothing heals, skips an already-inhibited mob, surplus → Clumsy, `spk` unreachable, cheap-filler fallback, PvP-inert). Suite **279/279**.

---

## 2026-07-16 — Basher: capture the REAL exits from text (dementia-proof adjacency) (v4.7.75)

Groundwork for a self-mapping 4x4. The breakthrough: **the exit line is true even under incurable dementia** — only gmcp lies.

- Observed in one ripple room: it rendered as `Within the hills.` with a Neraeos/ocean description, and gmcp reported `exits = {n=773, nw=797, sw=775, w=798}` (a real Northern Ithmia room) — while the text said **`You see exits leading north and south.`**, which is what actually existed. So `gmcp.Room.Info.exits` is **not** a usable adjacency source in the tower; the text is.
- That explains the stall: the explorer reads `MAP.rooms[num].exits` (built from gmcp), so it was pathing over phantom Ithmia rooms and walking exits that don't exist — `[explore] room clear -> moving ne.` in a room whose real exits were `north and south`. It wasn't lost; it was walking into walls.
- **New trigger `353_Real_Exits`** parses the line into `ataxiaTemp.realExits` (normalised `n/s/e/w/ne/nw/se/sw/up/down/in/out`, never serialised — it describes only the room we're standing in). Verified against every form seen in the logs: `down`, `north and south`, `east and southeast`, `northeast and northwest`, `southeast and west`, and the 3-exit `north, east and southwest`.
- This also removes the need for a failed-move detector: with real adjacency we only ever walk exits that exist, so moves succeed and dead-reckoning stays honest.
- Suite **272/272**.
- **Next:** point the explorer's `usableUnexplored`/room-pick at `realExits` and dead-reckon our own x/y over a self-owned 4x4, so room identity (`num`) is never trusted inside a ripple.

---

## 2026-07-16 — Basher: pin the targetList key in Mnemosyne (restores auto-add + targeting under dementia) (v4.7.74)

Fixes a regression from v4.7.72 and the real cause of "auto-add stopped working" in the tower.

- **v4.7.72 gated auto-learn off entirely while in Mnemosyne.** Wrong call: the tower *needs* auto-learn — that is how the basher learns what to attack there. Reverted.
- **The actual bug is the KEY, not the gate.** Both auto-learn and lookup use `ataxiaBasher.targetList[gmcp.Room.Info.area]`, and `Creville's Legacy` (incurable dementia) makes gmcp report a hallucinated **real** area for the whole climb. That does two bad things at once: tower denizens get filed into a genuine hunting list (`targetList["the Northern Ithmia"]`, persisted to disk), **and** `search_targets` then looks *up* under that same fake area — so the basher finds nothing to attack. It also spammed "Added the Northern Ithmia to areas." on every room change.
- **New `ataxiaBasher_areaKey()`** — the single key both sides use. Returns the gmcp area normally, but pins to **`""`** while in Mnemosyne: the key the tower has always used (its real area is `""`), so existing lists keep working and the hallucinated area can never be a key. Applied to auto-learn (`update_stuff/003`), the area-registration echo (`update_stuff/002`), `genrunning/002_search_targets` (5 sites — the lookup that actually finds targets), and `can(x)/002_Misc_CanDo`.
- Tests: +3 (real area passthrough, pins through a hallucinated area, pins for the genuine empty area). Suite **272/272**.

---

## 2026-07-16 — Basher: Mnemosyne presence is owned by the wade/ripple lifecycle (v4.7.73)

Completes the incurable-dementia work. The principle: **we already know, from triggers, when a wade starts, when each ripple starts, and when we stop wading — so presence should be driven by those, never inferred from gmcp**, which `Creville's Legacy` fakes wholesale for the entire run.

- **New `ataxiaBasher_mnemHere(why)`** — one place that asserts presence and cancels any pending "did we leave?" ask. Wired to every unambiguous Mnemosyne marker, each of which only ever prints inside a wade and which dementia cannot fake away:
  - **wade start** (`001_Run_Start`) — "You begin to wade out into the depths of the Mnemosyne"
  - **wade status / ripple** (`002_Ripple_Level`) — "You wade N ripples deep into the tides of memory:"
  - **boon screen** (`004_Boons_Offered`) — "...flickers of power that may aide you..." (observed printing under a hallucinated `Tangled forest.`)
  - **SURVEY** (`351`) — "You are in wading the Mnemosyne."
- **Self-heals a missed run-start.** Previously a missed wade-start line (reconnecting mid-climb, a gagged line) left the flag off for the whole run — and `onRipple`'s context guard *requires* in-Mnemosyne context to bootstrap a run, so it could never recover. Any later ripple or boon screen now re-asserts, and both markers assert *before* the handlers run so those see the correct context.
- **Only two things clear it:** the *confirmed* `onRunEnd()` (the real "we stopped wading"), or a SURVEY that names a real place (`352`). Never the area.
- Tests: +3 (asserts through a fake area, an authoritative yes cancels a pending ask and a late reply can't eject us, idempotent across repeated markers). Suite **269/269**.

---

## 2026-07-16 — Basher: the wade lifecycle + SURVEY own Mnemosyne presence (incurable dementia) (v4.7.72)

Follow-up to v4.7.71, now that the cause is fully understood: the boon **Creville's Legacy** ("You attack 20% faster but you have incurable dementia", common, echoes 3x) makes dementia a **permanent condition of the run** — so this can never be cured or waited out, and every Mnemosyne system has to work through it.

- **Dementia fakes `gmcp.Room.Info` wholesale.** Captured in a ripple: `area = "the Northern Ithmia"`, `num = 774`, `exits = {n=773, nw=797, sw=775, w=798}`, real `coords`/`map`/`desc`, `environment = "Forest"`. Not garbage — a *coherent, plausible real room*. GMCP is not a truth source in the tower, ever.
- **Presence is now owned by the wade lifecycle**, which brackets it exactly: the run-start line sets `inMnemosyne`, and the *confirmed* `onRunEnd()` clears it (alongside the boon flags, and deliberately not on the deferred maybe, so a mid-run message re-read cannot drop no-flee). Both are unconditional — independent of telemetry.
- **SURVEY is the re-sync authority** (free, and truthful through dementia). A non-empty area no longer clears anything by itself: it only *asks*. Trigger `351` keeps the flag; new trigger **`352`** clears it only when SURVEY names a *real* place. Gated on `ataxiaTemp.mnemSurveyPending`, so only the answer to **our** survey counts — an unrelated "You are in ..." line can never eject us mid-climb. The old timeout remains as a fallback for a lost reply.
- **Auto-learn no longer pollutes real hunting lists.** It filed by `gmcp.Room.Info.area` with no Mnemosyne gate, so under dementia tower denizens were written into `targetList["the Northern Ithmia"]` — a genuine area list, persisted to disk. Now skipped entirely while in Mnemosyne (an instance whose denizens belong to no area).
- Tests: 9 cases covering asks-not-assumes, no-flee held during the window, no SURVEY spam, 351 keeps / 352 clears, unsolicited-answer ignored, pending-ask consumed, and the timeout fallback. Suite **266/266**.
- **Still open:** whether the fake room ids are *stable per real room*. If dementia maps each tower room to a consistent fake, the explorer's graph is topologically the real 4x4 and the sweep works as-is now that it can start. If the fake is re-rolled per look, the ripple map accretes phantom rooms and the sweep needs a different anchor.

---

## 2026-07-16 — Basher: Mnemosyne presence is SURVEY-verified (dementia + stale no-flee flag) (v4.7.71)

Dementia hallucinates a real location while you are still in the tower, which broke every Mnemosyne system at once — and the same flag could be stale-**on** out in the world.

- **Root cause.** `ataxia_Room_Update()` treated any non-empty `gmcp.Room.Info.area` as *proof* we had left, and cleared `ataxiaBasher.inMnemosyne`. Inside the tower `area` is `""`, so that single check was the entire basis for "am I in Mnemosyne" — and dementia's hallucinated area tripped it. Everything downstream gates on that flag: **no-flee turned OFF (the basher tries to flee an instance you cannot flee — a death)**, the explorer stopped mid-sweep, the ripple map hid, telemetry gated off, and auto-learn filed tower denizens into the hallucinated area's `targetList`.
- **The mirror bug.** `ataxiaBasher` is serialized, so `inMnemosyne` survives logout — quitting mid-climb left no-flee **on** in the open world until the next room change, suppressing flee where we want it. Confirmed in game: `inMnem = true` while standing in the Shamtota Hills.
- **Fix — ask, don't assume.** `SURVEY` is free and still reports the truth while demented:
  `You have no idea where you are.` / `Your environment conforms to that of Forest.` / **`You are in wading the Mnemosyne.`**
  A non-empty area now only *opens a confirmation window*: send a free `survey`; trigger `351` cancels it if we are still inside; otherwise the window expires and we clear. Mirrors the proven `onRunEndMaybe`/`onRunEnd` pattern, and fixes **both** directions — dementia can no longer drop no-flee, and a stale flag self-clears on the first room change.
- **The explorer starts under dementia again.** `canStart()` hard-required `area == ""`, so a hallucinated area blocked the sweep outright; it now uses the SURVEY-verified flag, which is the better authority (and a stale flag self-clears rather than starting a phantom sweep).
- Tests: 6 cases — asks instead of clearing, **no-flee held during the window**, no SURVEY spam, `351` keeps the flag, window-expiry clears, re-arms afterwards. Suite **263/263**.
- **Still open:** whether dementia also falsifies `gmcp.Room.Info.num`/`exits`. If it does, guaranteeing the 4×4 sweep needs dead-reckoning (track our own x/y from the moves we issue). A `display(gmcp.Room.Info)` taken *while demented* settles it.

---

## 2026-07-16 — Basher: Monk transmute is now a gap-filler, not a constant mana drain (v4.7.70)

The Monk bash prepended a transmute to **every** attack, topping health back to 90% of max — burning mana non-stop for health the server's own curing was already sipping back, and starving Regeneration (which converts that same mana into health).

- **New behaviour.** Transmute fires only in the window server-side sipping cannot cover: **sip balance DOWN** (`ataxia.vitals.sipbal == false`) **and** health at or below **`transmuteat`** (new, default **50%**). It then tops up to **`transmuteto`** (70%), never spending mana past the **`manause`** floor (30%). Health sipping itself is server-side (`CURING SIPHEALTH`, 80) — LEVI never decided it.
- **Wired up settings that were dead.** `sipping.transmuteto` (70) and `sipping.manause` (30) already existed and were advertised in `ataxia setup sipping`, but **nothing read them** — the code hardcoded 90%/15%, while its comment claimed 75%/45%. Three sets of numbers, none agreeing. All three values now come from config; new `sipping.transmuteat` defaulted and backfilled for existing saves.
- **nil-safety:** the gate tests `sipbal == false`, not `not sipbal`. `ataxia.vitals` is reset to `{}` on login and only `balances/002,003` ever set `sipbal`, so it is **nil until the first sip of a session** — nil must not read as "off balance", or we would transmute with sip balance in hand.
- **Latent bug fixed:** the mana floor is fractional, so the transmute amount could be too — `transmute 1234.5` is not a valid command. Now floored.
- Tests: 6 cases (sip-up, sipbal-nil, above threshold, fires + tops to `transmuteto`, mana floor respected, integer output). Suite **257/257**.
- **Known gap (pre-existing):** `ataxia setup sipping <key> <value>` is advertised by the wizard, but no code assigns `ataxia.settings.sipping[key]` — the sipping panel is display-only. Tune via Lua for now.

---

## 2026-07-16 — Basher: stop the wasted transition after every Shikudo form change + capture Clumsy (v4.7.69)

Live-log follow-up to v4.7.68, which fixed the wrong half of the problem.

- **Corrected diagnosis.** A rejected `TRANSITION` does **not** reset the game's kata chain — the log shows `chain of 3` → rejected → next combo → `chain of 6` → transition succeeds. The `-= reset kata =-` echo is only our own `shikudo/002_Reset_Failsafe` trigger zeroing `ataxia.vitals.kata`; the real chain keeps climbing. So it was never a livelock, and raising `leaveAt` to 5 (v4.7.68) did not address the actual cause.
- **The real bug: stale kata after a form change.** A *successful* transition resets the chain to 0, but charstats keeps reporting the pre-transition kata for a tick. The next prompt therefore reads the old kata (e.g. 6), re-appends a transition, and that one resolves against a chain of only 3 → `A kata of at least 5 must be performed…` — one wasted attempt after **every** form change. Fixed by zeroing `ataxia.vitals.kata` optimistically when we emit a transition; charstats re-reports the truth on its next tick, and `002_Reset_Failsafe` also zeroes it on a rejection, so a wrong guess self-corrects within one tick either way.
- **Clumsy is now captured** (`denizen_attacks_misc_lines/022`) — it was the last `apply = nil` hit-prevention affliction in `ataxiaBasher_BR_AFFS`. Our **Scramble** battlerage (`MIND SCRAMBLE`, 22 rage) fire-line (`You rummage quickly through <mob>'s mind, finding the link to fine motor control…`) sets **Clumsy** (7s, mob misses 33% of attacks) on the current target, with the standard line-highlight + `(BR):` echo. Pattern mirrors `332_Battlerage_Special`, which matches the same line for the shared `special` cooldown — both fire, no shared mutable state.
- Confirmed from the log that Monk's battlerage cooldowns are all tracked already: `sbp` (Spinningbackfist) in `330`, `tnk` (Tornadokick) in `331`, `mind scramble` in `332`. Suite **251/251**.

---

## 2026-07-16 — Basher: Shikudo never changed form — the kata < 5 livelock (v4.7.68)

In game the Shikudo rotation never transitioned: every combo was chased by a rejected `TRANSITION`, and the rejection reset the kata chain, so it could never grow to the 5 a transition needs.

- **Root cause.** `leaveAt = 2` bet on the queued combo's 3 actions landing *before* the transition was evaluated (2 + 3 = 5). In game the transition resolved while the chain was still **3**, the game rejected it (`A kata of at least 5 must be performed in order to flow from the Live Oak to another.`), and `shikudo/002_Reset_Failsafe` zeroes `ataxia.vitals.kata` on that very line — so the next pass rebuilt the same doomed command. An infinite fail loop: the basher never left its starting form, and the intended 4:2:2 Willow split never happened.
- **Fix 1 — gate on a chain that is already legal.** `leaveAt` is now the kata the chain must **already** be at, and it is `>= 5` for every transit form (Rain/Oak/Tykonos/Gaital/Maelstrom); Willow keeps 9. A transition is then legal on its own, whatever the queued combo contributes, so the loop cannot form. This matches the rule the existing PvP code already encodes — `shikudo.shouldTransition()`: `if kata < 5 then return nil -- Need at least 5 kata to transition`.
- **Fix 2 — use COMBO's inline TRANSITION.** Per `AB SHIKUDO COMBO` the syntax is `COMBO <target> <attack1> [limb] [attack2] [limb] [attack3] [limb] [TRANSITION <form>]`. The transition is now emitted as that inline suffix (`combo <t> hiru hiraku flashheel left transition rain`) instead of a separate `transition to the <form> form` command racing the three attacks that build the chain it depends on.
- Combos are 3 actions, so the chain steps 0,3,6,9,12 and first satisfies `>= 5` at **6** → 4 combos in Willow, 3 in each of Rain/Oak (~40% Willow — versus the 50% the old table aimed for but never achieved, since it never transitioned at all).
- Tests: no-transition-below-5 asserted across all five transit forms × kata {0,2,3,4} (the livelock guard), plus the inline-suffix shape. Suite **251/251**.
- **Needs in-game confirmation:** the exact inline form-name spelling — `transition rain` (assumed, from `TRANSITION <form>`) vs `transition to the rain form`.

---

## 2026-07-16 — Basher: fix Shikudo silent no-attack + rebuild the form rotation around Willow (v4.7.67)

Shikudo autobashing sent no attacks at all: the basher engaged, armour swapped to `stickpve`, and you stood there taking hits with no error message.

- **Root cause — `ataxia.settings.crushbash` was never initialised.** It was absent from `ataxia_defaultSettings()`, and the only code that ever wrote it was the `aconfig monk` toggle alias, so unless it had been toggled an even number of times it was `nil`. Two of the three Shikudo branches in `ataxiaBasher_monkBashing2()` gated on `ataxia.settings.crushbash == false`; `nil == false` is **false** in Lua, so no branch ran, `command` kept only its battlerage prefix, and the basher sent `queue addclearfull freestand stand;<brage>` — stand up, do nothing, silently. (The third branch used a plain `elseif shikudo then`, which made it look intermittent.) Fixed by defaulting `crushbash = false` in `ataxia_defaultSettings()` and backfilling existing saves in `ataxiaCheckForMissing()` with an `== nil` test (not `not ...` — `false` is a real value here).
- **Rotation rebuilt around Willow.** The old thresholds (Rain `>= 19` of a 24 cap vs Willow `>= 6` of 12) deliberately parked in Rain, giving Willow ~23% of combos. Per `HELP KATA` a `TRANSITION` needs a 5-action chain and resets it, and `shikudo.transitions` makes `Willow → Rain → Oak → Willow` the shortest legal cycle through Willow — so we now ride Willow to its 12-kata cap and leave Rain/Oak the moment a transition is legal. Combos are 3 actions (kata steps 0,3,6,9,12), giving **4 Willow : 2 Rain : 2 Oak — 50% of combos in Willow**.
- **Gaital and Maelstrom now attack.** All three old chains covered only Rain/Oak/Willow/Tykonos with no `else`, so those two forms produced no attack even with the `nil` bug fixed. Both now have combos (built from `shikudo.formAttacks`) and rejoin the cycle via Rain and Oak; Tykonos (where a stumble dumps you) transitions straight back to Willow. An unrecognised form now **echoes once** instead of failing silently.
- **Spec detection by charstats key, not index.** `gmcp.Char.Vitals.charstats[4]:find("Stance"/"Form")` was a hardcoded positional index with no nil guard — a shifted index sets both flags false, i.e. the same silent bail. Now uses `ataxia.vitals.stance` / `.form` from the vitals parser (which resolves by key), matching what the attack aliases already do.
- **Fixed a second silent gap:** shielded with `rageraze` on but rage < 17 matched neither inner branch and produced no attack. Shield handling is now hoisted out of the spec branches.
- **Monk never spends rage on denizen shields.** Both specs carry a *free* shield breaker — `shatter` for Shikudo (uniquely usable in the flow of **any** form, unlike every other technique) and `rhk` for Tekura — so the 17-rage Splinterkick raze (`ataxiaBasher.battlerage.Monk.raze = "spk"`) is always the worse trade; that rage is worth more on damage/afflictions. `ataxiaBasher.rageraze` is now deliberately ignored inside `ataxiaBasher_monkBashing2()` (it still governs every other class), and the shielded path always uses the combo's own shield breaker.
- **Stopped resetting the kata chain on every bash start.** `003_Engaged_Disengage.lua` guarded the staff-wield/`adopt rain form` with `form ~= "Rain" or form ~= "Oak" or form ~= "Willow"`, which is always true (any form differs from at least one). `or` → `and`.
- The three near-identical Shikudo if-chains — which are why this bug survived in two of three copies — collapse into one table-driven builder (`SHIKUDO_BASH_ROTATION` + `SHIKUDO_BASH_COMBOS`).
- Files: `basher/002_Class_Bashing.lua`, `001_Save_Load_Settings.lua`, `002_Check_For_Any_Missing_Variables.lua`, `genrunning/003_Engaged_Disengage.lua`. Suite **249/249**. Rotation verified by driving the real `ataxiaBasher_monkBashing2()` through a simulated session: cycle and 4:2:2 split confirmed, all six forms attack and route back toward Willow, and `crushbash = nil` now produces an attack.
- **New `test_basher_monk.lua` (9 cases)** — Monk had *zero* test coverage, so the green suite said nothing about this path. Locks in: shatter/rhk used over `spk` (including with `rageraze` on — the regression guard), battlerage skipped while shielded, the Willow→Rain→Oak→Willow transitions, nil-kata tolerance, and crushbash mode.
- **Completed the Monk battlerage config** (`_groups.yaml` `get_Battlerage`): added the two missing abilities — `specialafflict = "rpst"` (**Ripplestrike → Inhibit**, 25 rage, the anti-healer tool) and `specialuse = "mind blast"` (**Mindblast**, 25 rage, conditional damage vs Weakness/Sensitivity) — plus the full kit documented inline (rage/cooldown per ability). **These two slots are inert for now**: `ataxiaBasher_standardBattlerage` only fires `small`/`large`/`special`, so they wait on a Monk-specific rotation (the planned Ripplestrike-priority-vs-healing-denizens work).
- **Needs in-game confirmation:** the Gaital and Maelstrom combos are inferred from `formAttacks`, not copied from known-good code, and `shatter` is used by the existing four forms but is not itself listed in `formAttacks`.

---

## 2026-07-15 — Basher: Blademaster multislash on the Shattered Star boon (v4.7.66)

Mnemosyne boon-aware bashing for Blademaster, mirroring the existing Bard Warmarch pattern.

- **White Heaven's Shattered Star** (legendary Mnemosyne boon) makes **multislash strike 3 extra times** (6 total), out-damaging the single drawslash. When the boon is active, `ataxiaBasher_blademasterBashing()` swaps its melee verb `drawslash <t> sternum` → `multislash <t> sternum` (both drawslash paths; the plain shielded-raze path is unchanged).
- Detection mirrors `bardWarmarch`: a new global `bmShatteredStar` set by the BOONS-list trigger (`mnemosyne/012_Shattered_Star.lua`) and the boon-claim alias, reset each run on run-start and confirmed run-end. Mnemosyne-scoped and reset per run, so it never leaks to normal bashing.
- Tests: `test_basher_blademaster.lua` (6 cases — swap on/off across the not-shielded and rageraze+shielded paths, plain-raze path untouched, infuse-fire preserved) + a `bmShatteredStar` onRunEnd reset case. Suite **240/240**. Two-agent adversarial review — reset parity verified 1:1 with `bardWarmarch`, drawslash path byte-identical; renamed the trigger 011→012 to avoid a prefix collision with `011_Ice_Slip.lua`.

---

## 2026-07-15 — Basher: BR affliction echoes/highlighting + stun/weakness capture (v4.7.65)

Visibility pass on the Blademaster basher, plus more affliction capture — driven by live Mnemosyne combat logs.

- **In-game alerts for battlerage afflictions.** New `ataxiaBasher_dsAlert(msg, colour)` highlights the triggering game line and echoes a coloured `(BR):` tag to the console so what our attacks are doing to the mob stands out in the combat spam. Wired into charm (cyan), recklessness (orange), aeon (yellow), weakness (green), and stun (magenta). Toggle with `ataxiaBasher.brAlerts` (default on). The `cecho` is pcall-guarded so a bad colour name can never throw.
- **Stun + Weakness capture from real lines.** Our **Daze → Stun** (`019` applied, `020` ended: `… is no longer stunned.`) and **Nerveslash → Weakness** (`017` applied, `018` ended: `… stands up straight, having overcome the weakness …`), both duration-tracked in `BR_AFFS` (stun 4s, weakness 7s) with the ended-triggers as a safety net.
- **Reverted the "reserve rage for Daze" tweak.** Live logs proved Daze already fires ~every 33s (its cooldown ceiling) under the mitigation-first priority, so reserving rage would only cost Nerveslash/Leapstrike damage for no mitigation gain. Rotation behaviour is unchanged from v4.7.64.
- Tests: added stun/weakness duration + capitalised-ended-line name-resolution cases. Suite **233/233**. Two-agent deep review — one MEDIUM fixed (invalid `ansi_*` colour names on the stun/aeon alerts → valid `magenta`/`yellow`, plus the pcall guard); revert verified clean (no dangling `spendCheap`, rage never stranded).

---

## 2026-07-15 — Basher: mitigation-first rotation + global BR cooldown + PvE docs (v4.7.64)

Refines the Blademaster battlerage rotation (Stage 2) with the player's priority spec and the global battlerage cooldown.

- **Global ~1s battlerage cooldown** is now respected: queuing a second BR inside the window gets it rejected (`You must wait a short time…`) and wastes the cycle's rage. The rotation skips a BR while a **reload-safe timestamp** (`ataxiaTemp.brGlobalReadyAt`) is up, armed on our own fire and by the new reactive trigger `329` (which also backstops a BR fired outside the rotation).
- **Mitigation-first priority in Mnemosyne** (survival > speed — *any rage ability that stops a denizen hitting us is critical* on the no-flee climb): **Culling → Stun (Daze) → damage battlerages (Headstrike/Spinslash) → other afflictions (Nerveslash = Weakness) → small damage (Leapstrike)**. Outside Mnemosyne it's damage-forward. Gated on `ataxiaBasher.inMnemosyne`. Added **Nerveslash** (Weakness) to the rotation with a reload-safe timestamp cooldown.
- **New doc: [`battlerage-pve.md`](.claude/projects/basher/battlerage-pve.md)** — rage mechanics + the global cooldown, all 10 denizen afflictions (what each does + tactical/defensive value, mitigation-first), how the rotation uses them, and Blademaster's kit.
- Tests: 17 rotation cases (both mnem/non-mnem priority, global-cooldown skip+arm, Nerveslash cooldown). Suite **230/230**. Adversarial-reviewed — no CRITICAL/HIGH; one narrow LOW noted (a rageraze+shielded bash that discards the computed `brage` can phantom-arm Headstrike/Nerveslash — to be resolved once we capture their fire-lines and track cooldowns from real fires).

---

## 2026-07-15 — Basher: Blademaster rage-rotation fix (Stage 2) (v4.7.63)

Fixes the observed bug where **100+ battlerage rage sat unused** while abilities were off cooldown (and `The surge of terrible rage leaves you.` fired repeatedly). **Isolated to Blademaster** — every other class flows through `assembleBattlerage` byte-identically (deep-review-proven), so nothing else can regress.

- **`ataxiaBasher_blademasterBattlerage()`** — Blademaster now owns its battlerage (excluded from the shared culling check, like Bard), so the two rage-stranding defects are gone: culling no longer suppresses the class rotation below `bigRage`, and cheap abilities are no longer gated behind `special` being on cooldown. It **spends rage by priority so it never idles**: Culling reap → **Headstrike on a reckless/feared target (bonus damage)** → Spinslash → Leapstrike → Daze (surplus/stun), using the shared `battleRage_Timers` (330/331/332) cooldowns + a reload-safe **timestamp** cooldown for Headstrike (no fire-line trigger exists for it).
- **Denizen affliction capture** for the exploit: **recklessness** (`013`/`014`) closes the Headstrike loop; **aeon** (`015`/`016`) is tracked (mitigation). Both from real game lines.
- Tests: `test_basher_battlerage.lua` (12 cases — rage-never-idle guarantee, priority, culling/World-Tree, Headstrike gate + cooldown, dsExploit-nil safety, stranding boundary). Suite **224/224**. Passed a 3-agent deep review (cross-class regression / rotation correctness / trigger correctness) — no CRITICAL/HIGH; the one MEDIUM (reload-stuck Headstrike cooldown) fixed with a timestamp.

---

## 2026-07-15 — Basher: per-denizen combat-state capture (Stage 1) (v4.7.62)

Foundation for a smarter tower-climber basher: a live per-denizen combat-state layer so the basher can see what our (and others') attacks have done to each mob and act on it. **Additive and behaviour-neutral** — it only *populates* state this stage; nothing reads it to change combat yet.

- New `basher/008_Denizen_State.lua`: `ataxiaTemp.denizenState[id]` (under `ataxiaTemp` — transient, never serialized) plus a **data-driven `ataxiaBasher_BR_AFFS`** spec of the 10 battlerage afflictions with real durations, `role`, and `exploitedBy` (which battlerage ability gains bonus damage from each). Afflictions **auto-expire on their duration** (lazy on read), so state self-heals if an "ends" line is missed. Pure functions (`dsSync/dsSetAff/dsHasAff/dsExploit/dsResolveNameToId/dsPickAlt/…`), fully **PvP-inert** (keys off numeric denizen ids only; players are strings). `ataxiaBasher_dsStatus()` dumps live state.
- Wired in: lifecycle reconcile in `update_stuff/003` (synced with `ataxia.denizensHere`), current-target HP% feed in `010`, and **charm** capture — `denizen_attacks_misc_lines/011` (applied) + `012` (ended) — the headline case (a charmed mob fights the others for us).
- Reference: [.claude/projects/basher/denizen-lines-catalog.md](.claude/projects/basher/denizen-lines-catalog.md). Tests: `test_denizen_state.lua` (17 cases). Suite 212/212. Passed a 4-agent deep review (Lua standards / combat correctness / trigger correctness / completeness) — no CRITICAL/HIGH; consensus fix applied (`dsSetAff` auto-creates so an affliction is never dropped before sync).

Next stages (planned): rage-rotation rewrite so battlerage rage is actually spent by priority (the "100+ rage sitting unused" bug) and afflictions are cashed in for bonus damage; charm-swap targeting; first-hit auto-parry.

---

## 2026-07-13 — Mnemosyne explorer: snappier moves + never walk `up` (v4.7.61)

Two live-testing fixes:

- **Faster off the last kill.** The decision tick had a single 0.5s debounce used for both arrivals and denizen changes. Split it: arrivals still wait `TICK_DELAY` (0.5s) so the new room's `Char.Items` can load before deciding (don't walk past a room whose mobs hadn't arrived), but a **denizen change** now schedules `FAST_TICK` (0.15s) — `denizensHere` is already current when `"targets updated"` fires, so "killed the last mob → move on" no longer eats the full settle delay.
- **Never walk `up`.** The 4×4 is planar; the only non-planar walked edge is the entry holding room's `down`/`up`. `MAP.path` (BFS over walked edges) would happily return the `up` back to the holding room, so **patrol** (which queued *all* visited rooms, including the holding room) walked `up` out of the grid. Fixed: the patrol queue now excludes pure-vertical rooms (`roomHasPlanarExit`), and both patrol and backtrack reject any non-planar first step (`planarStep`). The forward descent `down` into the grid is unaffected (it's a `usableUnexplored` pick, not a path step).

Suite 194/194.

---

## 2026-07-13 — Mnemosyne explorer: stop the sweep when slain (v4.7.60)

Being slain in the tower ("You have been slain by Chief Constable Beck.") boots you out of the ripple — you respawn elsewhere — but the auto-explorer kept running, trying to walk and fight from the wrong place. The Mnemosyne death trigger (`mnemosyne/007_Death.lua`) now also calls `ataxia.mnemosyne.exploreOnDeath(killer)`, which stops a running sweep (restoring the basher to its pre-sweep state via `_exploreStop`). It's independent of telemetry — the sweep runs off `ataxiaBasher.inMnemosyne`, not the tracked run, so the stop fires even with reporting off — and no-ops when the explorer isn't running. Suite 192/192.

---

## 2026-07-13 — Mnemosyne: fix monster reporting; QL to resync stale rooms (v4.7.59)

**Monsters were never reported.** The spawn line ("A multitude of sibilant voices chant… as ormyrr warriors and priests march across Krenindala.") is captured by a one-shot trigger armed on the countdown "0". That `^.*$` trigger is armed *while the "0" is being processed* and Mudlet fires it on that very "0" — which is exactly why the code had an all-digit guard — but the guard ran **after** the `killTrigger`, so on the "0" the trigger killed itself and never lived to see the spawn line on the next line. The capture decision is now extracted to `M._mobCaptureLine()`, which **survives** blank and countdown-digit lines (returns "keep waiting") and only stops once it captures the first real prose line (or hits GO! with no spawn that wave). `onCountdownZero` also arms on `_auto()`/in-Mnemosyne rather than strict `_inRun()` (arming just fills a local; `onGo` still re-checks `_inRun` before reporting). The whole spawn line is sent verbatim.

**QL to resync stale room contents.** A **stale GMCP snapshot** — a denizen has died/left (or we've moved) but Achaea hasn't pushed a fresh `Room.Info` / `Char.Items`, so `ataxia.denizensHere` lists a phantom and the basher swings at nothing. A **QL** (quicklook — the codebase idiom for a room/denizen refresh, free of balance) forces a re-push that resyncs `denizensHere`.

- **Target-not-here reflex (basher-wide).** `denizen_attacks_misc_lines/003_Target_Not_Here.lua` caught the "not here" replies ("You cannot see that being here.", "I do not recognise anything called that here.", etc.) but only `deleteFull()`d in *auto* mode — in **manual / Mnemosyne** mode it just echoed "Target is gone!" and left the stale target. It now sends a **debounced `ql`** whenever the basher is on (one per burst via `ataxiaBasher._targetGoneQL` + a 1.5s tempTimer).
- **Mnemosyne explorer stall watchdog.** On a 30s stall `M._armWatchdog` runs `M._watchdogNudge()`, which sends `ql` (forcing the `gmcp.Room` / `"targets updated"` refresh the explorer already listens on) and `_scheduleTick()`s to re-decide on fresh data. Extracted so it's unit-testable.
- **Ice-slip livelock guard (adversarial-review finding).** A watchdog `ql` fired *during* the ice-slip retry loop would be seen by the arrival handler as an arrival, aborting the loop and resetting the `MAX_ICE_SLIPS` counter — livelocking the sweep on one stuck icy exit. Fixed two ways: `_watchdogNudge` no-ops while a move is in flight, and the arrival handler (`M._onExploreRoom`, extracted) now treats "still in the room we left" as *not arrived*, so a same-room `ql`/re-push never aborts an in-flight move.

Suite 190/190.

---

## 2026-07-12 — Mnemosyne: only `down` is a valid non-planar move + fix `gmcp.Room` crash (v4.7.58)

Two fixes from live explorer testing:

1. **Explorer looped on `moving u`.** A room reported a spurious `up` exit, and v4.7.56's non-planar allowance ("any non-planar exit from a room with no planar exit") let the sweeper take it — then bounce back — forever. **There is no `up` in Mnemosyne: only the entry holding room has a non-planar move, and it is always `down`.** `usableUnexplored` (`008_Explorer.lua`) now allows a non-planar exit *only when it is `down`* — `up`/`in`/`out` are never taken, and a 4×4 room's deeper `down` still isn't taken (it always has planar exits). New test asserts an `up`-only / `out`-only room yields no move.

2. **`attempt to index field 'Room' (a nil value)` spam.** `search_targets()` runs every prompt and indexed `gmcp.Room.Info.area` unguarded; `gmcp.Room` is briefly nil during Mnemosyne transitions (GO!/wade, boon screen, between-room hops), so the prompt trigger flooded the error console. Added a `hasRoomInfo()` guard to every function in `002_search_targets.lua` that reads `gmcp.Room.Info` (`search_targets`, `preCombatLdeck`, `stormhammer`, `shieldedTarget`). Also **de-duplicated** that file — its entire body had been accidentally pasted twice.

Suite 182/182. Docs: [07-explorer.md](.claude/projects/mnemosyne/07-explorer.md), CLAUDE.md, memory.

---

## 2026-07-11 — Sysupdate hardening: verify the install, cross-check the version (v4.7.57)

A `sysupdate` reported "System package v4.7.53 has been successfully installed" while the repo was at 4.7.56, and the Package Manager window (open during the update) showed no Levi_Ataxia at all. Diagnosis: the install itself *had* succeeded (the success echo only fires from the `sysInstallPackage` event) — but two real gaps surfaced:

1. **Wrong version installed silently.** Tags v4.7.54–56 were pushed ~a day after those versions were built, and even after the push GitHub's `releases/latest/download/` redirect stayed CDN-cached on the old asset for several minutes — so `sysupdate` fetched and installed 4.7.53 as a "success".
2. **No failure path.** If `installPackage` failed after `uninstallPackage`, the system was left uninstalled, the `.mpackage` was deleted by the blind t=4s cleanup, and nothing was echoed.

Changes (`misc_scripts/021_Auto_Update.lua`):

- **Version cross-check**: the login version check now stores `ataxia.updater.latestKnown`; a new anonymous `sysInstallPackage` handler (`onInstalled`, same survive-uninstall pattern as the download handlers) compares the freshly loaded `ataxiaVersion` against it and warns "installed vX but latest is vY — GitHub may still be propagating; retry SYSUPDATE" on mismatch.
- **Failure watchdog**: the blind t=4s `os.remove` is replaced by a t=6s `finishInstall()` — deletes the mpackage only when `_installOk` was confirmed by the event; otherwise keeps the file and tells the user to retry or install it manually.
- **Package Manager hint**: after a self-update install, echoes that an open Package Manager window must be closed/reopened to show the change (Mudlet's list doesn't refresh live — the source of tonight's false alarm).

Process guard (`.claude/hooks/session-start.sh`): session start now warns when `version.txt`'s version has no tag on origin (checked via `git ls-remote`, skipped silently offline) — the drift that let version.txt run ahead of the published release.

---

## 2026-07-11 — Mnemosyne explorer: keep moving through icy rooms (v4.7.56)

Some rooms are icy: leaving can print **"You slip and fall on the ice as you try to leave."** — the move fails (you fall prone) but the *exit is fine*. The explorer's normal move-timeout retry (1) would give up and mark that good exit as failed after a couple of slips.

- New trigger `011_Ice_Slip.lua` → `M.onIceSlip()`: while a sweep move is in flight, it **re-sends the stand+move and re-arms the timeout**, without charging the failed-exit budget — so the explorer keeps trying until it actually leaves. Capped at `MAX_ICE_SLIPS` (15) re-sends before condemning the exit, so a permanently stuck exit still yields. `explore.iceSlips` resets on each fresh move. The internal timeout/ice re-sends are now silent (only the deliberate "slipped on the ice — up and going again" echoes).

Suite 181/181. Docs: [07-explorer.md](.claude/projects/mnemosyne/07-explorer.md) "Icy rooms".

---

## 2026-07-11 — Mnemosyne explorer: hunt the boss on boss ripples (v4.7.55)

On a **boss ripple** (every 5th) the boss spawns *at the end*, after the regular waves are cleared, in any one of the already-swept 4×4 rooms — so "no unexplored exit left" is not the end of the ripple. v4.7.54 stopped there and the boss was never engaged (the boon screen never came).

- When `_nextExploreStep()` returns `nil` (grid swept), the explorer no longer stops — it **patrols** (`_nextPatrolStep`): re-visits the visited rooms round-robin (a refilling, sorted queue) and lets the basher clear whatever it finds. The boon screen is still the real terminus; the patrol is capped at `MAX_PATROL_LOOPS` (3) *fruitless* full loops, and `patrolLoops` resets to 0 whenever a room has denizens, so a genuine boss fight keeps it going.
- Sweeping new ground exits patrol; finding denizens resets the cap.

Tests: +1 (patrol re-visits a prior room + counts loops); suite 181/181. Docs: [07-explorer.md](.claude/projects/mnemosyne/07-explorer.md) "Boss hunt (patrol)".

---

## 2026-07-11 — Mnemosyne: explorer enters the grid + live echoes; full spawn line reported (v4.7.54)

Fixes and refinements after the first in-game test of `mnem explore`:

- **Explorer now enters the grid.** A ripple's entry is a *holding room whose only exit is `down`* into the 4×4, but the v4.7.53 explorer refused all non-planar exits (to avoid walking off-level) and so instantly declared "grid fully swept" and quit. `usableUnexplored` now allows a non-planar exit **only from a room that has no planar exit at all** (the holding room's `down`) — a grid room's *deeper* `down`/`up` (which sits alongside planar exits) is still never taken, so it descends into the grid without wandering off-level.
- **Live progress echoes.** The sweep now announces each step (`room clear -> moving <dir>`) and, once per room, `clearing this room (N denizen(s)) -- basher on it.`, so you can follow it.
- **Monsters reported as the full spawn line.** `onGo` now reports the whole spawn line verbatim (e.g. "Mandibles clatter… as a swarm of Rapo'kir horkval closes in…") — the community-tracker convention — instead of the trimmed noun phrase. `_extractMob`/`MOB_VERBS` are retained as a utility but no longer wired into reporting.

Tests: +3 (holding-room entry, grid-room deeper-exit ignored, full-line monster commit); suite 180/180.

---

## 2026-07-11 — Mnemosyne: `mnem explore` auto-sweeper for the 4×4 (shipped in v4.7.53)

New `008_Explorer.lua` (`mnem explore on|off|status`): auto-sweeps a ripple's 4×4 room grid, clearing each room, and stops at the boon screen for you to pick a boon and wade. It reuses the existing systems rather than adding combat logic:

- **Combat = the autobasher in manual mode** (attacks in place, keeps Mnemosyne's shield-don't-flee, never mapper-walks — the mapper can't route the unmapped tower). The explorer saves/restores your basher state around the sweep.
- **Navigation = this module.** Room-clear is `ataxia.denizensHere` empty (GMCP ground truth); it steps through a usable unexplored exit (planar, non-failed) or backtracks via the ripple-map's BFS `MAP.path` to the nearest room with one, moving with `queue addclear free stand;<dir>` (stands first — you're often prone after a fight). Event-driven (`gmcp.Room` + `"targets updated"` → debounced tick, one move per clear).
- **Stops** at the boon screen (the `flickers of power` line, now also an explorer signal), on leaving the tower, when fully swept, or `mnem explore off`.
- Hardened after an adversarial review: planar-only sweep (no walking off-level), stand-first move + retry, failed-exit tracking that also kills a two-room backtrack ping-pong, a start-guard requiring `area == ""`, a stall watchdog, and a reload reset. Pure logic unit-tested (suite 178/178); the timer/event machine is validated in-game.

Docs: new [.claude/projects/mnemosyne/07-explorer.md](.claude/projects/mnemosyne/07-explorer.md) and [06-history.md](.claude/projects/mnemosyne/06-history.md).

---

## 2026-07-10 — Fix: self-inflicted `db`-proxy crashes from the GUI stripper; exposed init gaps (v4.7.53)

Once the loader was un-stuck (v4.7.52) the GUI-object crashes stopped, but the GUI stripper introduced a
new one and the now-completing load surfaced older latent bugs:

- **Root regression — never index `.hide`/`.show` on arbitrary tables.** `isRuntimeObject`/`sanitizeForSave`
  probed `type(t.hide)`. For a Mudlet **`db` proxy** stored under `ataxia` (the `exp_db` hunting DB) that
  fires the proxy's `__index` → `DB.lua:1669: attempt to access sheet 'hide' … does not exist`, and since
  `ataxia_saveSettings` runs at end-of-load and on `basher enabled`/Mnemosyne events, it spammed everywhere
  (and interrupting those handlers garbled GMCP). Fix (`ataxia/001_Save_Load_Settings.lua`): detect runtime
  objects with **`getmetatable`** only (Geyser AND db proxies carry metatables — no side effects), and use
  **`rawget`** for the GUI-field checks. Zero `.hide`/`.show` indexing remains.
- **`ataxiaNDB API`** — guarded `pairs(t.characters)`: a truncated/garbled online download now echoes a
  message instead of `bad argument #1 to 'pairs' (table expected, got nil)`.
- **`Check For Any Missing Variables`** — self-heal `ataxiaBasher.noShieldBreak = {mobs={}, threshold=0}`
  for older basher saves; `ataxiaBasher_canShield()` indexed it directly and spammed index errors each
  prompt once the basher actually loaded.
- Test suite **174/174**. Version 4.7.52 → **4.7.53** (verify in-game: `lua ataxiaVersion`).
- Architecture recorded in [docs/adrs/001-no-gui-objects-in-saved-state.md](docs/adrs/001-no-gui-objects-in-saved-state.md).

Still open (pre-existing, likely GMCP-corruption downstream): `Prompt Substitution … field 'IRE'` and the
GMCP JSON decode errors — re-assess after this build, as several were fed by the `db`-proxy save-throw
interrupting GMCP processing.

---

## 2026-07-10 — Mnemosyne tracker: reliability hardening + local history (v4.7.52)

Hardening informed by reviewing an alternate community tracker, plus a new local-history feature. Test suite **174/174**; the changes were adversarially reviewed before release (which caught the watchdog, `bardWarmarch`, and toggle bugs below).

- **`/run_start` failure recovery.** The HTTP client gained an `onError` path; `startRun` now clears `run.active` when `/run_start` fails — by a 500 (the reported error) **or** a timeout / dropped response (the watchdog now also fires `onError`). Previously a failed start left the client POSTing `ripple`/`monsters`/`boss`/`effects`/`boons` at a run the server never created.
- **Run-end false-positive guard.** The "releases its hold, weaving N threads" reward line also prints when re-reading the Achaea message mid-run, so it no longer ends the run on its own — it waits for the `"You just received message #N from Achaea."` confirmation. `bardWarmarch` now clears only on that confirmed end (moved out of the trigger), so a mid-run re-read can't drop a Bard's paean bonus.
- **Accurate echo count.** `_parseContemplate` reads the real `Maximum echoes: N` (was hardcoding 1 for echo-capable boons; the line also no longer leaks into the description).
- **Boon claim resolution.** `boon claim <n>` (slot number) and unique name prefixes now resolve, not just exact names.
- **Ripple context guard.** A wade line only bootstraps a run while actually in Mnemosyne (an active run still advances if the survey flag flickers between floors), so a stray/re-read wade line can't spawn a phantom run.
- **Local history + reports** (new `mnemosyne/007_History.lua`). Records offers/claims/affixes per run to `mnemosyne_history.lua`; `mnem boons | affixes | library` review this run's claims, its active affixes, and the all-time affix catalogue; `mnem quiet [on|off]` silences the automatic boon/affix echoes (still records). Bootstrapped runs get their own history bucket.
- Fixed the `mnem quiet off` and pre-existing `mnem map off` toggles (an `x and false or y` chain fell through to a toggle instead of forcing off).

---

## 2026-07-10 — Fix: `gmcp.Room` handler crashes after the loader was un-stuck (GUI objects in the save)

### Root cause (same underlying issue as the stack overflow)

Live Geyser/Adjustable GUI objects are stored under the **saved** `ataxia` namespace — e.g.
`ataxia.mnemosyne.map.window` / `.container` / `.cells` (`mnemosyne/006_Ripple_Map_Window.lua`) and
`ataxia.data.hunter.window`. `ataxia_saveSettings` serializes all of `ataxia`, so these GUI objects
(which are full of circular references) get written to disk. That circular structure is exactly what
overflowed `deepMerge` before. With the overflow fixed, the loader now *completes* and `mergeLoad`
**merges the stale serialized snapshot into the live Geyser object**, polluting a container's
`windowList` with plain-table (methodless) children. The next `gmcp.Room` → `MAP.window:hide()` /
`:show()` walks that list and dies: `GeyserContainer.lua:139/167: attempt to call method 'hide'/'show'
(a nil value)`.

### Fix (v4.7.52 — robust, after per-key guards proved insufficient)

Per-key guards inside `deepMerge` missed GUI objects nested inside a subtree assigned **wholesale**
(e.g. `ataxia.bars = { hp = { window = <snapshot> } }` when `ataxia.bars` doesn't exist yet → the whole
thing is assigned at once, nested window included → `GeyserLabel:493` crashes). The real fix works on the
whole tree:

- **`ataxia/001_Save_Load_Settings.lua`**
  - **Load — `stripGui(loaded)`**: recursively removes serialized GUI snapshots from the loaded data at
    *any depth* BEFORE merging (detected by GUI-internal fields: `windowList`/`nestedLabels`/`windowname`,
    or a `type` tag with `container`/`stylesheet`). Nothing GUI ever gets merged or assigned. `deepMerge`
    also still refuses to recurse into a live runtime object (metatable / `hide`/`show` method).
  - **Save — `sanitizeForSave(ataxia)`**: strips live GUI objects (reliably: their `hide`/`show` are
    functions, or they have `windowList`/`nestedLabels`) from a data-only copy before `table.save`, so
    files stop accumulating GUI objects at all. Cycle-guarded.
- **`tests/test_settings.lua`** — added "strips GUI snapshots nested inside a wholesale-assigned subtree"
  and "saveSettings strips live GUI objects from the serialized data" (plus the earlier live-object /
  empty-key cases). Suite **159/159**.
- **Version bumped 4.7.51 → 4.7.52** so the running build is verifiable in-game via `lua ataxiaVersion`.

### User action (important)

The currently-loaded session's Geyser containers may already be polluted, and a reinstall alone won't
rebuild them (`MAP.build()` early-returns when `MAP.window` already exists). After installing, **restart
Mudlet** so the GUI rebuilds clean; the fixed loader/`stripGui` then keep it clean, and the next save
writes a GUI-free file. Verify with `lua ataxiaVersion` → `4.7.52`.

---

## 2026-07-09 — Bard bashing: tempo-aware flick for back-position bonus damage (v4.7.51)

Achaea's FOOTWORK change makes bladedance attacks deal **bonus damage from the back position** against denizens, but PvE bashing started every fight in **allegro**, spammed a fixed `blade jab <target> torso`, and re-composed its performance on every attack. This reworks the Bard bashing loop around the new mechanics.

- **Tempo & compose at bash start** (`ataxia/genrunning/003_Engaged_Disengage.lua`, `basher_engaged`): selects **moderato** tempo (config `ataxia.bardStuff.bashTempo`) and composes **`paean prelude scherzo sonata maqam`** (config `bashCompose`) once — via the new shared `ataxiaBasher_bardCompose()` helper, which wields the lyre first (you can't perform without your instrument), composes, and arms the 15-minute timer (debounced to one compose per 2s).
- **Attack** (`basher/002_Class_Bashing.lua`, `ataxiaBasher_bardBashing`): now `blade flick <target> nomos` (psychic damage, back-boosted) — `blade punctuate <target> nomos` when the `bashpunctuate` toggle is on (psychic-resistant denizens), and `blade flick <target> paean` while the Warmarch boon is active. **Compose was removed from the per-attack path** (it doesn't belong on every swing). Also fixed two wield bugs (double-space in the shielded branch; the `bardNeedRapierWield` branch wielding the shield in the right hand).
- **Battlerage** (`basher/001_Bashing_Functions.lua`, `ataxiaBasher_bardBattlerage`): custom rotation — culling blade (reap, handled globally) → charm the 2nd denizen (2+ denizens, ≥32 rage) → trill the target (2+ denizens, ≥28, off its ~42s cooldown) → howlslash (≥36) → moulinet (≥14). The shield-break branch now razes with `blade punctuate <target> paean` (punctuate is our raze) instead of a jab.
- **Warmarch (Mnemosyne)** — while the Warmarch boon is active (`bardWarmarch`; set on boon claim or from the `BOONS` list, cleared on run start/end), the flick becomes `blade flick <target> paean` (Warmarch makes the paean refrain hit denizens for +100% psychic). New trigger `mnemosyne/010_Warmarch.lua`.
- **15-minute refresh** (`timers/.../004_Bard_Performance.lua`): when the performance expires, the timer re-runs `ataxiaBasher_bardCompose()` (wield lyre → compose → re-arm) instead of just flagging it down; disengage disables the timer so it never fires while idle. If it lapses early, the `You can hardly manipulate a grand performance…` line also re-composes (`performance_tracking/005`).
- **Config** (`ataxia/001_Save_Load_Settings.lua`): new `ataxia.bardStuff.bashCompose` (default `paean prelude scherzo sonata maqam`) and `bashPunctuate` (default false); existing saves fall back to the defaults.
- **Aliases**: `bashtempo <adagio|moderato|allegro|none>` (`009`) picks tempo per area (Moderato = best steady-state back share, 2 of every 7 hits; Allegro reaches back fastest for squishy mobs); `bashpunctuate` (`010`) toggles flick↔punctuate for psychic-resistant denizens.
- **Build**: fixed `build.sh` (hardcoded, now-missing `JAVA_HOME=E:/Java`) to resolve a valid Java home, with a clear error if none is found.
- Docs: corrected the `.claude/classes/bard.md` Bashing (PvE) section (previously — and wrongly — listed `BATTLERAGE SLASH <target>`).

---

## 2026-07-09 — Mnemosyne map: fixed 4×4 grid with unexplored slots (v4.7.50)

Every Mnemosyne ripple is a fixed 4×4 room grid, so the map now renders that whole frame instead of auto-sizing to just the rooms you've entered.

- `006_Ripple_Map_Window.lua` — `render()` now draws a stable **4×4 grid**: visited rooms are coloured (current green, unexplored-exit gold `?`, others grey) and every not-yet-visited position shows as a **dim placeholder cell**, so the whole level and its gaps are visible at a glance. The frame is aligned using the "frontier" (grid positions of unvisited rooms a visited room's unwalked exit points at) and padded up to 4×4; if the graph ever spans wider (loop/inconsistency) it windows on the current room. Replaces the old auto-sizing `GRID_MAX` window.
- Placeholder cells aren't clickable; visited rooms keep click-to-walk. No changes to the graph model (`005`) — coordinates still come from `MAP.relayout()`.

*(Released together with the `qwp`/loader-crash fix below.)*

---

## 2026-07-09 — Fix: `qwp` "Name database not currently loaded" (real cause: loader stack overflow)

### Root cause (confirmed from a live client via `pcall(ataxia_loadSettings)` = `stack overflow`)

`qwp` prints the message only when the global `ataxiaNDB` is `nil` (`aliases/.../181_Parse_QWHO.lua`),
and `ataxiaNDB` is assigned **only** inside `ataxia_loadSettings()` (`ataxia/001_Save_Load_Settings.lua`).
The loader was **crashing every run before it reached the NDB block**:

- **Primary cause — `deepMerge` stack overflow.** The `mergeLoad` helper used to load the main `ataxia`
  save deep-merges saved data into the live `ataxia` table via a recursive `deepMerge` with **no cycle
  guard**. When the saved data contains a cyclic/self-referential table (a stray back-reference stored
  into `ataxia` and serialized), `deepMerge` recursed forever → **stack overflow**, aborting the whole
  loader at the *first* step — before basher/paths/extraction/**NDB**. This is why the affected client
  showed `ataxia.settings.class` populated (merged before the overflow) but `ataxia.loaded = nil` and
  `ataxiaNDB = nil`, and why reconnecting never helped (it overflowed identically every time).
- **Secondary gap — loader only bound to `sysLoadEvent`.** `ataxia_loadSettings` was registered *only*
  on `sysLoadEvent`, which fires on profile connect — **not** on `installPackage`. So installing or
  self-updating the package left everything (NDB included) nil until the next reconnect.

Two earlier red herrings, now corrected: it was **not** primarily a corrupt-sub-load-file issue, and
**not** primarily the duplicate `qwp` aliases (that only multiplied the message ×3 — see below).

### Fix

- **`ataxia/001_Save_Load_Settings.lua`**
  - `deepMerge` now takes a `seen` set and returns on re-entry of a source table — **cycle-safe**, so a
    cyclic save can never overflow the loader again. *(This is the actual bug fix.)*
  - The main-settings load is now wrapped in its own `pcall` (and the early `return` when no save file /
    no backup exists was removed) — a failure there warns and falls through to defaults + the remaining
    sub-loads, so nothing before the NDB block can strand it. Defense-in-depth on top of the cycle fix.
  - (From the prior pass, retained) each sub-load (basher, paths, extraction, NDB, SLC, itemCatalog,
    legend deck) is `pcall`-isolated; `ataxia.loaded = true` is set at the **end**; the NDB block loads
    into a temp table and commits only on success; an NDB load-throw with a present file prefers the
    profile backup instead of `ataxiaNDB_Install()` (which would save an empty DB over the good file).
- **`ataxia/003_Install_System.lua`** — `ataxia_updateApplied` (on `sysInstallPackage`) now runs
  `if ataxia and not ataxia.loaded and ataxia_loadSettings then ataxia_loadSettings() end`, so installing
  or self-updating the package loads settings immediately — no reconnect required, and the auto-updater
  no longer leaves the system unloaded.
- **`tools/convert_to_muddler.py`** — wipes each package's `src/<type>/<package>/` output dir
  (`shutil.rmtree`) before writing, so orphaned collision-renamed files from prior runs can't accumulate.
- **`tests/test_settings.lua`** — `ataxia_loadSettings()` suite now includes: **loads without
  stack-overflowing on cyclic saved data**, main-settings load throwing still lets NDB load, clean load
  populates `ataxiaNDB`/sets `ataxia.loaded`, earlier sub-load throw still loads NDB, corrupt `andb` not
  overwritten with an empty install. Suite **155/155**.

### The ×3 (separate, already resolved)

The message appeared three times because the user's profile had three duplicate `qwp` aliases (old
build / reinstall without uninstall). A clean build has exactly one (verified: built `Levi_Ataxia.xml`
contains the alias once); uninstalling the old package before installing collapses it back to one.

### User action

Install the rebuilt package. Because of the `sysInstallPackage` auto-load above, it loads immediately;
if you installed before that fix landed, a reconnect (or `lua ataxia_loadSettings()`) also works.

---

## 2026-07-09 — Dragon: breath summon strictly colour-based (v4.7.49)

### Fix: drop the hardcoded `ice` fallback in the blast weave

`ataxiaBasher_dragonBashing()` (`basher/002_Class_Bashing.lua`) derived the summon element from
`getDragonBreath()` (Blue = ice, Silver = lightning, Red = dragonfire, Green = venom, Black = acid,
Golden = psi) but fell back to a literal `"ice"` if that ever returned nil — a Blue-specific default that
isn't correct for other colours.

- `local ele = getDragonBreath()` now with **no hardcoded default**; the summoned breath is always the
  dragon's own colour.
- Guarded so a nil element can never inject the wrong breath: the normal-rotation weave only blasts/summons
  when `ele` is set, and the shielded shield-break blasts without a summon rather than summoning `ice`.

**File:** `basher/002_Class_Bashing.lua`.

---

## 2026-07-08 — Mnemosyne map: re-layout the whole graph each step (v4.7.48)

The v4.7.46 per-arrival placement still left the map as a single square: `mnem map status` showed `rooms=11 visited=11 placed=1 … bounds=0,0,0,0`, with the current room's exits pointing at real but `[unplaced,visited]` neighbours. Root cause: placing a room *at arrival, relative to a placed `from`* is a chain that can't bootstrap — the first move off the origin never got placed (its `from`↔`here` link wasn't known yet), so every room behind it stayed unplaced and there was never a placed neighbour to anchor to.

Fix (`005_Ripple_Map.lua`): replaced the per-arrival coordinate logic (and the old `_propagate`/`_anchor` helpers) with **`MAP.relayout()`** — on every arrival it rebuilds a **bidirectional** adjacency from *all* rooms' currently-known exits and BFS-assigns coordinates from the origin. Because it re-derives everything from the full accumulated graph each step, a room that couldn't be placed on arrival is placed on a later pass as soon as either side of a link becomes known — and since each room's back-exit is populated the moment you arrive in it, the whole walked chain connects. Anchored on the origin for stable coordinates, with a fallback re-anchor on the current room so the room you're standing in is always on the grid.

Walked edges (for click-to-walk `MAP.path`) are still recorded per-step and kept separate from coordinates. `mnem map status` diagnostics (v4.7.46) unchanged.

Tests: replaced the propagation test with a later-pass placement case; full suite 150/150. Known limitation unchanged: purely non-planar (`up`/`down`/`in`/`out`) links can't be gridded.

---

## 2026-07-08 — Dragon: weave breath BLAST into the incantation/gut bash

### Feature: `bash blast on/off` — blast alongside incantation when breath is up

`ataxiaBasher_dragonBashing()` (`basher/002_Class_Bashing.lua`) previously used BLAST only as a
shield-breaker; the normal (unshielded) rotation sent just `incantation <target>` (or `gut`), wasting
the breath (equilibrium) attack. It now folds a breath blast into the primary attack when dragonbreath
is summoned.

**Why:** BLAST deals damage and breaks shields/lyres on eq while incantation/gut hit on bal, so weaving
it in is free extra output as long as breath is available.

**How:**
- Rewrote the function around two local helpers: `balAttack()` (jab/whip/incantation/gut, unchanged
  selection) and `primary()` (weaves the blast). When `ataxiaBasher.dragonBlast` is on and the primary is
  a real attack (not the ≤5%-willpower `jab` fallback or `wotBash` whip):
  - breath up (`ataxia.defences.dragonbreath`) → `blast <tar>;summon <ele>;<incant/gut> <tar>`
  - breath down → `summon <ele>;<incant/gut> <tar>` (rebuilds breath for the next hit)
- Element now comes from `getDragonBreath()` (Blue = ice, Silver = lightning, …), collapsing the old
  per-colour `blast;summon acid/ice/venom/…` chain in the shielded branch. The shielded branch still
  blasts unconditionally to break the shield (independent of the toggle) and now also appends the bal
  attack for extra damage.
- New toggle `ataxiaBasher.dragonBlast`, **default ON** (initialised in
  `002_Check_For_Any_Missing_Variables.lua`); alias `bash blast on/off`
  (`aliases/.../configs/010_Blast_Bash.lua`, mirrors `bash rageraze`).

**Breath tracking (reused, not new):** `ataxia.defences.dragonbreath` is the defence set true on
defence-add/list (`deffing/001_Defence_API.lua`) and cleared when consumed by blast or by the
"You have not summoned your breath weapon." trigger (`341_No_Breath.lua`).

**Files:** `basher/002_Class_Bashing.lua`, `002_Check_For_Any_Missing_Variables.lua`,
`aliases/.../configs/010_Blast_Bash.lua`.

---

## 2026-07-08 — Mnemosyne map: anchor rooms from the exit graph so the grid fills in (v4.7.46)

Reported symptom: after walking 14 rooms, the map showed a single grey square; `mnem map status` showed `rooms=14 visited=14 placed=1 … bounds=0,0,0,0` with `gmcp exits: se->71057`.

Root cause: gmcp fills a *real* exit destination only for neighbours it already knows (rooms you've **visited**) and reports `0` otherwise. So on first arrival in room B (from A), A's forward exit to B is still `0`, while B's exit **back to A** already carries A's real number. The placement logic only did *forward* inference (`from.exits[dir] == num`) — the value that's still `0` — so no room past the origin ever got coordinates, and `_propagate` (which only runs on already-placed rooms) had no second seed.

Fix (all in `005_Ripple_Map.lua` `MAP.onRoom`):
- **Reverse inference:** when the forward exit doesn't resolve, look at the *new* room's exits for the one pointing back to `from` and take its opposite. This resolves on first arrival and drives both coordinate placement and walked-edge recording (so click-to-walk pathing works without movement capture).
- **Anchor placement (`MAP._anchor`):** if the move direction still can't be determined, position the room next to **any** already-placed neighbour via its own exit graph. Together these bootstrap the whole grid from the origin using the one signal that's reliably populated — exits back to visited rooms.
- Existing signals (explicit `moveDir`, forward inference, `sysDataSendRequest` capture, `_propagate`) are kept as fallbacks.
- `mnem map status` now dumps the current room's **recorded** exits annotated per-dest (`se->71057 [placed,visited]`, `n->0 [unknown]`, `u->… [nonplanar]`) plus `prev=`, so any remaining miss is self-diagnosing.
- Tests: +2 (reverse back-exit placement; anchoring to a non-`from` neighbour). Full suite 150/150.

Known limitation: rooms joined only by non-planar exits (`up`/`down`/`in`/`out`) still can't be grid-placed.

---

## 2026-07-08 — Runewarden falcon rake in PVE bashing (v4.7.45)

### Feature: `falcon rake <target>` on a tracked cooldown

Mirrors the Infernal hyena maul. `ataxiaBasher_runewardenBashing()`
(`basher/002_Class_Bashing.lua`) now prepends `falcon rake <target>` to the bash in
all four specs when the falcon is off cooldown — a free pet hit added to every attack.

- Cooldown state `ataxiaBasher.falconRakeReady` + `ataxiaBasher_falconRakeCooldown()` /
  `ataxiaBasher_falconRakeReady()` in `basher/005_Falcon_Cooldowns.lua`; a 30s
  `falconRakeCooldownSec` timer is a safety net. Initialized on load in
  `001_Save_Load_Settings.lua`.
- Triggers `370_Runewarden_Falcon_Rake_Cooldown` (on "You whistle to your falcon,
  commanding it to assail…" and "You cannot yet order your falcon to rake another
  foe.") and `371_Runewarden_Falcon_Rake_Ready` (on "You may command your falcon to
  rake your foes once more.").

**Tests:** `src_new/tests/test_basher_falconrake.lua` — 4 cases (full suite 148/148).

---

## 2026-07-08 — Mnemosyne map: place rooms from the exit graph (v4.7.44)

Reported symptom: after moving through 4 rooms, `mnem map status` showed `rooms=4 … bounds=0,0,0,0` — every room recorded, but only the origin ever got grid coordinates, so nothing meaningful drew. (Click-to-walk on the lone origin cell did work.)

Two root causes in `MAP.onRoom`, both fixed:
- **String vs number exit ids:** gmcp reports exit destinations as strings (`"67701"`), but they were compared against the numeric room num (`"67701" == 67700` is always false), so the exits-dest direction inference never matched. Exit dests are now coerced with `tonumber`.
- **Over-reliance on capturing keypresses:** placement leaned on the movement direction from `sysDataSendRequest`, which is fragile. Now **topology propagation** — once a room is placed, its neighbours are positioned directly from the game's own `dir → neighbour-num` exit graph. Neighbours are created as unvisited *stubs* (coordinates only) and only render once actually visited; `bounds()`/render draw visited rooms only, so stubs don't stretch or clutter the grid. The grid fills in reliably even when the move direction is unknown.
- `mnem map status` now also reports `visited`/`placed`/`lastMove` and **dumps the current gmcp exits** (`dir->dest`), so if a level still won't map, the output shows whether the game is handing us real neighbour room-nums.
- Tests: +2 cases (topology placement of an unvisited neighbour; string-dest coercion). Full suite 144/144.

---

## 2026-07-08 — Mnemosyne map: fix blank map on a new level + robustness (v4.7.43)

- **New level was blank:** the per-ripple reset fires (from the ripple line) while you're already standing in the new level's first room, wiping it. `onRipple` now re-seeds the current room from `gmcp.Room.Info` immediately after the reset, so the new level's map shows straight away.
- **Robuster "in Mnemosyne" gate:** `MAP.inMnem()` now accepts an active telemetry run as well as `ataxiaBasher.inMnemosyne` (the survey flag is set opportunistically and can be missed between floors).
- **Click-to-walk:** replaced the name-based click callback with a direct function reference (a dotted/nested name may not resolve), so clicking a room actually walks you there; `setToolTip` wrapped in `pcall`.
- Added `mnem map status` — diagnostic echo (inMnem / enabled / rooms / current / ripple / bounds).
- Tests: +1 re-seed case (full suite 142/142).

---

## 2026-07-08 — Mnemosyne: per-ripple room mini-map widget (v4.7.42)

### Feature: `ataxia.mnemosyne.map` ripple mapper

New draggable grid mini-map for Mnemosyne. Each ripple ("level") is a fresh layout, so it builds a room graph as you walk and wipes it each ripple.

- `mnemosyne/005_Ripple_Map.lua` — per-ripple room graph. On each `gmcp.Room` arrival inside Mnemosyne (`ataxiaBasher.inMnemosyne`), records the room's `num`/`name`/`exits`; direction of travel is captured from `sysDataSendRequest` (movement aliases send `.. <dir>`) with a gmcp exits-dest fallback, and rooms are placed on a grid via a `dir → offset` walk. Tracks *walked* edges (for pathfinding) vs *reported* exits (for unexplored detection). `MAP.path()` is a BFS over walked edges; `MAP.unexploredExits()` = reported minus walked.
- `mnemosyne/006_Ripple_Map_Window.lua` — draggable `Adjustable.Container` grid (position auto-persists). Current room green, rooms with unexplored exits gold-bordered (`?`), others grey. Click a room to auto-walk there (queues the path via the game's free queue). Shows only while in Mnemosyne.
- Reset: on Mnemosyne entry and on ripple change (`onRipple → MAP.onRipple`). `onGo` now sends `WADE STATUS` while in Mnemosyne even with reporting off, so the ripple line drives the reset. Toggle: `mnem map [on|off]` (`ataxia.settings.reporting.mapEnabled`, default on).

**Tests:** `test_mnemosyne.lua` +7 graph cases (coordinates, unexplored-exit detection, BFS pathfinding, per-ripple reset, direction normalisation). Full suite 141/141.

---

## 2026-07-08 — Mnemosyne: fix first boon's description showing "BOON CLAIM" (v4.7.41)

The first offered boon was reported with description `"BOON CLAIM <boon name> to pick one of the options."` (the offered-block footer) instead of its real text. Cause: the `BOON CONTEMPLATE` enrichment overwrote each boon's description with the contemplated one, and the *first* boon's contemplate is armed right beside that footer line, capturing it. Fix: enrichment now applies only rarity/quote/echoes (new `_applyContemplate`) and keeps the description from the authoritative offered block; the contemplate capture also skips any `BOON CLAIM` line defensively. Tests: +1 (full suite 134/134).

---

## 2026-07-08 — Mnemosyne: handle more mob spawn structures (v4.7.40)

Reworked `_extractMob` to handle `the <mob> of <place>` (e.g. "the trolls of Riagath", where the creature noun is *before* "of") in addition to `a/an [adj] <quantifier> of <mob>` ("a host of malagmae", "a ghastly horde of the restless dead"). It anchors on `of`, walks left to the article beginning the subject noun phrase (stopping at `as`/comma), and accepts the phrase only when a mob verb immediately follows the object — capturing the mob whichever side of "of" the creature noun sits. Dropped the `MOB_QUANTIFIERS` set; added `wade/surge/swell/teem/...` verbs. Best-effort: an unrecognised action verb falls back to the whole line. Tests: +1 (full suite 133/133).

---

## 2026-07-08 — Basher: exclude your own denizens (pets/allies) from auto-add & targeting (v4.7.40)

### Feature: `ataxiaBasher.ownDenizens` ignore list

**What changed:**

- New keyword list `ataxiaBasher.ownDenizens` — case-insensitive **substrings** matched against denizen names via `ataxiaBasher_isOwnDenizen(name)` (`basher/001_Bashing_Functions.lua`). `falcon` covers "a razor-beaked falcon" and any variant; `baalzadeen` covers Baalzadeen. Seeded with `{"falcon", "baalzadeen"}`.
- Matches are excluded from auto-learn (`update_stuff/003_ataxia_RoomContents_Update.lua`), slain auto-add (`triggers/.../340_Slain.lua`), target selection (`search_targets()` + `shieldedTarget()` in `genrunning/002_search_targets.lua`), and the `bash add` display.
- Unlike `mobIgnore`, a match does **not** skip the room — the basher keeps killing everything else while your pet is present.
- New `bash mine` alias (`aliases/.../lists/012_Own_Denizens.lua`): `bash mine` lists (click-to-remove), `bash mine add <keyword>`, `bash mine rem <keyword>`. Adding a keyword also purges already-learned matches from every `targetList` via `ataxiaBasher_purgeOwnFromTargets()`.

**Why:** With auto-learn on, friendly denizens sharing the room's denizen list (hunting falcons, the Baalzadeen ally) were being learned as bash targets — so the basher would attack your own pets.

**Tests:** `src_new/tests/test_basher_owndenizens.lua` — 9 cases covering keyword matching, target-list purge, and add-with-purge (full suite 132/132).

---

## 2026-07-08 — Mnemosyne: fix monster capture (deterministic + adjectives) (v4.7.39)

Fixes monsters not being reported. The previous approach read the line above `GO!` via `getLines()`, which wasn't reliably returning it. Replaced with a deterministic capture: a new trigger on the countdown `0` (`mnemosyne/005_Countdown.lua` → `onCountdownZero`) arms a one-shot capture of the next (mob spawn) line into `M._mobCandidate`, which `onGo` commits when `GO!` follows. Also made `_extractMob` handle an adjective between the article and the quantifier, so e.g. `"…as a ghastly horde of the restless dead rises…"` → `"a ghastly horde of the restless dead"` (previously only `a <quantifier> of <mob>` matched). Removed the `getLines`-based `_pickMobLine`. Tests: full suite 132/132.

---

## 2026-07-08 — Mnemosyne: automatic run-end on true death / release (v4.7.38)

Wires `/run_end`: new trigger `mnemosyne/009_Run_End.lua` fires on `"The Mnemosyne releases its hold, weaving N shimmering threads into your possession."` — the run's conclusion (Mnemosyne is an endless climb with no victory; it ends on true death or `WADE LEAVE`) — calling `onRunEnd()` → `endRun()`. A normal life-loss death still just reports `/death` and continues the run. This completes the automatic reporting chain: run start · ripple · effects · boss · monsters · boons offered/selected · death · run end. Tests: +2 onRunEnd cases (full suite 123/123).

---

## 2026-07-08 — Serpent: finisher-safety + rebounding-reapply pre-empt (v4.7.37)

### Serpent offense (`serpent/002_Serpent_Offense.lua`)

- **Graded-confidence lock/finisher gating (P0 finisher-safety):** new `haveAff_locked` (0.90) / `haveAff_tactical` (0.70) wrappers over the V3 branching tracker replace the flat 0.30 `haveAff()` bar for lock/finisher decisions. `serp_ekanelia_offense()` recomputes softlock/hardlock/truelock at graded confidence (3-of-4 soft pieces tactical; paralysis must read 0.90 for truelock), and the `execute` finisher is additionally gated on a joint probability (`getStateProbabilityV3` of all five lock affs together ≥ 0.90) so it never fires on an aff the target may have already cured. Falls back to `haveAff()` / no-gate when the V3 tracker isn't loaded.
- **Rebounding-reapply pre-empt (PRIORITY 1.5):** detect when the target's rebounding drops (`lastRebounding` present→absent) and stamp `lastReboundingFlay`; ~8.15s later (just before rebounding reapplies ~8.5s after strip) fire one impulse+bite through the gap instead of eating a reflected hit. Fires once per drop, and is placed after the finisher so a ready kill always wins. New state resets on target change.

Build + full suite 121/121.

---

## 2026-07-08 — Mnemosyne: trim monster spawn to the mob phrase (v4.7.36)

The mob spawn line captured by `onGo` is now trimmed to just the `a/an <quantifier> of <mob>` phrase (e.g. "a host of malagmae", "a group of dryad handmaidens") via the new pure `_extractMob()` in `mnemosyne/004_Parsers.lua` — quantifier + verb word-sets, stopping the mob name at the verb / comma / sentence end, falling back to the whole line when the structure isn't matched. Tests: +3 `_extractMob` cases (full suite 121/121).

---

## 2026-07-08 — Mnemosyne: boss/monsters auto-detect + boon enrichment (v4.7.35)

### Feature: complete the Mnemosyne Run Tracker auto-reporting

**What changed (all under `ataxia.mnemosyne`):**

- **Boss** now auto-detected from the WADE STATUS `Objective:` line — a boss ripple reads `defeat <boss>` (e.g. "defeat Seasone the Industrious") vs a normal `defeat N waves of enemies`. New trigger `triggers/.../mnemosyne/008_Objective.lua` → `onObjective()` → `/boss` (fires after `/ripple_level`, so ordering holds).
- **Monsters** now captured by POSITION instead of flavour wording: the mob spawn line is always the single line between the countdown `0` and `GO!`, so `onGo()` reads the line directly above `GO!` (via `getLines`) and buffers it. Removed the fragile `005_Monsters.lua` "joins the fray" trigger (spawn wording varies per mob). Added a pure, tested `_pickMobLine()`.
- **Boon enrichment** implemented: when `contemplate` is on, each offered boon is probed with `BOON CONTEMPLATE <name>` and `_parseContemplate()` extracts rarity / echoes (`Can echo` Yes→1 / No→0) / description / quote, so `/boons_offered` is sent fully populated. Sequential probe with a small inter-boon delay.

**Why:** finish the auto-reporting the tracker needs — boss fights, the actual mobs per wave, and complete boon metadata for the community boon DB.

**Still manual:** `/run_end` (via `mnem end`) until the run-completion line is captured.

**Tests:** `test_mnemosyne.lua` — added onObjective (boss/wave), `_parseContemplate`, and `_pickMobLine` cases. Full suite 118/118.

---

## 2026-07-08 — Mnemosyne Run Tracker reporting (`ataxia.mnemosyne`)

### Feature: automatic run telemetry to the Mnemosyne Run Tracker API

**What changed:**

- New `ataxia.mnemosyne` module reporting run progress to the Mnemosyne Run Tracker REST API (`http://104.128.56.238:8000`; token in the JSON body, no auth header).
  - `scripts/.../mnemosyne/001_HTTP_Client.lua` — serial POST queue (one request in flight; endpoint-specific response matching; per-request watchdog; idempotent-only retry; anonymous handlers that survive `uninstallPackage`).
  - `002_Reporter_API.lua` — one function per endpoint (`/run_start`, `/run_exists`, `/ripple_level`, `/monsters`, `/boss`, `/effects`, `/boons_offered`, `/boons_selected`, `/death`, `/run_end`) + in-memory run state with synchronous reset on start/end.
  - `003_Commands.lua` — `mnem` alias dispatch (`token/on/off/contemplate/debug/test/start/end/check/ripple/boss/monsters/death`, plus `status`/`help`).
  - `004_Parsers.lua` — parsers for the effects and boons-offered blocks (dashed-divider capture + wrapped-line join), monster buffering, boon-claim canonicalization.
- New triggers `triggers/.../mnemosyne/001-007`: run start, ripple level, effects, boons offered, monsters (`… joins the fray`), `GO!` → auto `WADE STATUS`, and death (`You have been slain by …`).
- New aliases `aliases/.../mnemosyne/001_Mnemosyne.lua` (`mnem`) and `002_Boon_Claim.lua` (intercepts `BOON CLAIM <name>`).
- `001_Save_Load_Settings.lua` — new persisted `ataxia.settings.reporting` (`enabled`, `contemplate`, `token`, `url`), default + load-time self-heal; rides in the main `ataxia` save file / `_ataxia_backup.ataxia` (no new disk file).
- `misc_scripts/020_Setup_Wizard.lua` — new `ataxia setup reporting` page (token / on-off / test).

**Why:** report each Mnemosyne (tides-of-memory) run — ripple depth, monsters, boss, ongoing effects, boons offered/selected, deaths — to the community run tracker automatically as you play.

**Flow:** on `GO!` the system auto-sends `WADE STATUS`; its output drives `/ripple_level` and `/effects`. Monsters spawn just before `GO!`, so they're buffered and flushed after `/ripple_level` (keeping ripple-level first, per the API's ordering rule). The serial queue guarantees `/ripple_level` precedes monsters/effects/boons and `/boons_offered` precedes `/boons_selected`. `_auto()` gates run-start/GO/ripple; `_inRun()` gates the generic-phrase handlers (monsters/effects/boons/death) so they can't report outside a tracked run.

**Still manual (pending game text):** `/boss` and `/run_end` (via `mnem boss` / `mnem end`); BOON CONTEMPLATE enrichment of `/boons_offered` (quote/rarity/echoes) is stubbed.

**Tests:** `src_new/tests/test_mnemosyne.lua` — 21 cases (parser, config, serial-queue ordering + endpoint matching, monster buffering/flush, ripple guard, run-lifecycle reset, boon-claim membership). Full suite 111/111.

---

## 2026-07-07 — Basher no-flee rules for Mnemosyne (v4.7.33)

### Feature: Mnemosyne tower-climb is now a no-flee bashing area

**What changed:**

- New trigger `triggers/.../leviticus/351_Mnemosyne_Survey.lua` — matches the SURVEY line (`^You are in .*Mnemosyne`) and sets `ataxiaBasher.inMnemosyne = true`. Mnemosyne is an unmapped instance (`gmcp.Room.Info.area` is `""`), so it cannot be detected from GMCP — the SURVEY line is the reliable signal.
- `ataxia_Room_Update()` (`update_stuff/002_ataxia_Room_Update.lua`) clears the flag when you enter any real (mapped, non-empty `area`) room. Inside the tower `area` stays `""`, so the flag persists across floors.
- New helper `ataxiaBasher_isNoFleeArea(area)` in `basher/001_Bashing_Functions.lua` generalizes the existing World Tree no-flee check and adds the Mnemosyne flag.
- `ataxiaBasher_dangerLevel()` no longer returns `"flee"` in no-flee areas. Instead, an extreme incoming-damage spike raises a shield as a one-cycle guard (`Shielding.` instead of `Fleeing.`), and low HP shields at the normal threshold — the basher never tries an impossible `goto`.
- `ataxiaBasher_attack()` keeps attacking through the shield in no-flee areas (drops the HP≥70 re-attack gate), so it shields reactively but does not pause the attack loop.
- `inMnemosyne` defaults to `false` in `002_Check_For_Any_Missing_Variables.lua`.

**Why:** Mnemosyne is a tower-climbing PvE mod where fleeing is impossible. The danger system was firing `DANGER: Extreme incoming damage rate detected! Fleeing.` and wasting cycles trying to retreat with nowhere to go.

**Tests:** `src_new/tests/test_basher_noflee.lua` — 8 cases covering shield-instead-of-flee in Mnemosyne and the normal-area flee regression (full suite 90/90).

---

## 2026-07-07 — Armour swap guard no longer gets permanently stuck

### Bug fix: Self-healing swap guard + watchdog in `ataxia.armour`

**What changed (all in `gear_system/002_Armour_Paragons.lua`):**

- Added `swapStartTime` to `ataxia.armour.state` and a module constant `SWAP_TIMEOUT = 5`.
- `ataxia.armour.swap()` now stamps `swapStartTime = os.time()` when it sets the `swapping` guard.
- The guard check is now staleness-aware: if `swapping` is set but older than `SWAP_TIMEOUT`, it is treated as a stuck flag from an interrupted prior swap and cleared, letting the swap proceed instead of blocking forever.
- Added a watchdog `tempTimer(SWAP_TIMEOUT, ...)` in the slots branch that force-clears the guard if the 2s insert-timer callback never did (keyed on `swapStartTime` so a later legitimate swap is never cancelled by an earlier swap's watchdog).

**Why:** The `swapping` guard was a plain boolean cleared only by the fire-and-forget `tempTimer(2, ...)` insert callback (or the traits-only `else` branch). If anything interrupted that clear — a Lua error in the synchronous body before the timer was scheduled, or an error inside the callback before the clear (e.g. the `send()`), or the timer being lost — the flag stuck `true` for the rest of the session. Every subsequent swap then printed `[Armour]: Already swapping. Please wait.` and returned early, which also silently broke auto-swap on basher enable/disable (both handlers route through `swap()`).

**How:** The timestamp-based staleness check guarantees the flag can never permanently block (the next swap after 5s clears it), and the watchdog proactively unsticks it so auto-swaps recover without a manual retry. `swapping`/`swapStartTime` live in non-persisted `ataxia.armour.state`, so no persistence changes were needed.

---

## 2026-05-27 — Serpent offense: Gavai-inspired tempo + bite payload + opportunistic ekanelias

### Feature: Round-1 burst, bite-stacking, shield-break, class-aware routing, underused ekanelias

After reviewing a combat log of Gavai (one of the top-tier serpents in Achaea), audited Levi's serpent offense and identified six tactical gaps. The existing engine is strong at lock completion via Ekanelia + impulse + fratricide-relapse, but lacked the pressure/tempo and room-control overlays that make Gavai's offense feel inescapable. This change layers those overlays on top of the existing lock engine without disturbing the strategy chain.

**What changed (all in `002_Serpent_Offense.lua`):**

- **Round-1 opener (Track 1)**: New `serpent.state.firstAttack` flag set on `tar changed`; `serp_sendAttack()` prepends a `buildOpener()` prefix on the first attack of a fight. Opener can include a bow swap + pinshot (consumes `tpinshot` set by `triggers/.../serpent/002_Pinshot.lua`) and sigil deployment (incandescent + monolith). All three opener pieces are config-gated via `serpent.config.useOpener / useBowOpener / useSigils` so the user can toggle per-fight.

- **Bite payload expansion (Track 2)**: New `selectBiteVenom()` helper picks bite venom based on target state — preserves scytherus-camus loop when scytherus is stuck, but also delivers monkshood (impatience via ekanelia, no EQ cost), kalmia, curare, loki, or aconite depending on which ekanelia is ready. New mode `bitepayload` with `ekbite` alias activates a bite-centric sustained-pressure round. Replaces hardcoded `biteVenom = "scytherus"` at the old line ~1546.

- **Defensive denial (Track 3)**: `serp_sendAttack()` rotates `block <direction>` through `gmcp.Room.Info.exits` with 5s per-direction throttling and a 5s global throttle. Config-gated via `serpent.config.useExitBlock` (default OFF). Sigils handled inline in `buildOpener()`. **Shield-break pressure**: when the target shields, the flay-shield path (PRIORITY 1) now chains monkshood impulse on EQ alongside the flay on BAL, keeping impatience landing to force shield touch-failures (the Gavai "TOUCH SHIELD - IMPATIENCE" cheese).

- **Class-aware venom routing (Track 4)**: New local `CLASS_LOCK_VENOM` table maps target class to its weakest-cure-path venom (apostate→voyria, monk→vernalius, magi/sylvan→notechis, knights→xentio, psion/alchemist→aconite, depthswalker→eurypteria, druid/sentinel→kalmia). `pickVenom()` now checks `getClassLockAff()` after paralysis is locked and prefers the class-specific lock aff when its target aff is missing.

- **Ekanelia expansion (Track 5)**: New `selectOpportunisticEkanelia()` helper fires loki (confusion+recklessness → nausea+paralysis), aconite (deadening+dementia → stupidity+paranoia), or curare-ek (hypersomnia+masochism → paralysis+hypochondria) when normal impatience delivery isn't available. Wired into the impulse-case chain as a fallback before dropping to dstab.

- **State plumbing**: New state fields `serpent.state.firstAttack`, `pinshotSentAt`, `sigilDeployed`, `blockedExits`, `lastBlockSentAt` all initialized at file load and reset on `tar changed`. New config fields `useOpener`, `useBowOpener`, `bowName`, `useExitBlock`, `useSigils` added to `serpent.config`.

- **Test coverage**: New `src_new/tests/test_serpent_helpers.lua` adds 13 tests covering `selectBiteVenom()` (8 cases) and `selectOpportunisticEkanelia()` (5 cases). All 82 project tests pass.

**Why this matters:** Gavai's combat tempo is "shroud → pinshot → adder → block exit → dstab/bite loop → sigil if threatening flee → execute when locked" with 3–4 distinct denial actions packed into one balance round. Levi's existing engine had the lock engine but none of the tempo/denial scaffolding. These changes close the gap without rewriting the strategy chain.

**Game-side commands NOT verified live**: `pinshot <target>` syntax assumes archery default; `block <direction>` balance behavior assumes free-action (throttled fallback to standalone `send`); sigils require user-side inventory. Defaults are conservative — bow opener is ON, exit-block and sigils are OFF, so live behavior change vs. prior is limited to: (a) longer opening command on first attack, (b) shield-break impatience chain. Anti-magic (per-round `point finger`) explicitly NOT added — that's a multiclass ability Gavai has, not a serpent native.

**Aliases**: `ek`, `eklock`, `ekdark`, `ekhyp`, `ekauto`, `ekstatus`, `ekhypstatus`, `ekhl`, `ekgroup`, `ekscyth`, **`ekbite` (NEW)**.

---

## 2026-05-23 — Phantom-mount whip trigger now covers 3rd-person observations

### Feature: Track 3rd-person phantom-mount whip 4-limb breaks

The v4.7.29 phantom-mount whip trigger only matched the 1st-person opening line (`^You whip ...`). When an ally or any other player whipped a phantom mount at our current target, the four subsequent break lines scrolled past with no update to `tAffs` — so any downstream offense decision read stale `brokenleftleg` / `prone` / etc. flags after a major 4-limb-break event delivered by someone else.

**What changed:**

- **`008_Phantom_Mount_Whip.lua`**: line-0 pattern rewritten to `^(?:You whip|\w+ whips) (.+) into a fury, bucking and racing dangerously in a circle, trampling the ground in a frenzy\.$`. The non-capturing alternation matches both "You whip ..." and "<Attacker> whips ..."; the `\w+` cap on the attacker name keeps the match anchored to a single-word player name. Mount capture moves nowhere (still `multimatches[1][2]`), target capture stays at `multimatches[2][2]`, body unchanged. Trigger renamed to `Phantom Mount Whip (1st + 3rd Person)` to reflect the broader scope. `isTargeted()` guard in the body silently no-ops when a phantom whip lands on someone we don't care about, so adding 3rd-person doesn't risk noisy false-positives.

---

## 2026-05-23 — Gear listing trigger updated for new GEAR LIST ALL format

### Fix: Capture slot, set, worn-status, and extended rarities

The `gearAudit.setupListingTriggers()` regex only matched the old 4-column GEAR LIST ALL format (`id name rarity months`) with rarities limited to common/rare/remnant. The current game format adds slot and set columns, prefixes worn items with `*`, and exposes additional rarities (artifact/epic/legendary), so most modern gear rows silently failed to parse and never reached the probe queue.

**What changed:**

- **`001_Gear_Audit.lua`**: `setupListingTriggers()` regex rewritten to `^(\*?)(\d+)\s+(.+?)\s+(common|rare|remnant|artifact|epic|legendary)\s+(\w+)\s+(\w+)\s+(\d+)\s*$`. Captures worn-flag, slot, and setCode in addition to the existing fields; populates `g.slot`, `g.setCode`, and `g.worn` on each `gearAudit.data[id]` entry.

---

## 2026-05-23 — Sentinel phantom-mount whip 4-limb-break tracking

### Feature: Track all 4 limb breaks from "whip mount into a fury"

The Sentinel skirmishing ability that whips a phantom mount into a fury produces 4 sequential break lines (both legs, both arms) on a single target, but had no trigger feeding the affliction tracker. After a successful whip, `tAffs.brokenleftleg` / `brokenrightleg` / `brokenleftarm` / `brokenrightarm` / `prone` stayed false, so downstream offense decisions ran on stale state right after a major 4-limb-break attack.

**What changed:**

- **`008_Phantom_Mount_Whip.lua`** (NEW) in `triggers/.../targeted_strikes/`: multiline trigger anchored on `^You whip (.+) into a fury...` plus the four subsequent break lines (`breaks the left leg`, `crushes the right leg`, `pulverises the left arm`, `smashes the right arm`). Mount name and target are regex-captured so it generalizes across phantom mount types (ankheg, grizzly, etc.) and any target. On match, calls `tarAffed("brokenleftleg", "brokenrightleg", "brokenleftarm", "brokenrightarm", "prone")` when `isTargeted(target)` matches, fanning out to `tAffs` and V3 via the standard wrappers — same pattern used by the existing DWB break triggers (`579_Arms_1.lua`, `580_Legs_1.lua`).

First-person only (anchored on `^You whip`) — won't fire from other players' whips. No `lb.addHit()` update since the game text doesn't report damage percentages for this ability and the existing dealt-damage trigger expects a `%` line.

---

## 2026-05-12 — Apostate deadeye party callout + rbhold default off

### Fix: Drop comma from affliction party callout

The apostate deadeye buffer was announcing afflictions to party with a comma separator (`Tabethys: asthma, paralysis`), inconsistent with the DSL relay which already used spaces.

**What changed:**

- **`462_NEW_DEADEYES.lua`**: Line 91 — changed `table.concat(deadeye_buffer, ", ")` to `table.concat(deadeye_buffer, " ")`. Party callout now reads `Tabethys: asthma paralysis`, matching the DSL relay format in `017_Affliction_Management.lua:168`.

Magi target-priority list (`pt Targets: A, B, C`) intentionally kept comma-separated — those are player names, not afflictions.

### Fix: Force rbhold off on every login

Apostate (and other class) dispatches silently abort when `reboundHold.gate()` is active. The previous init guard (`if reboundHold.config.enabled == nil then ... = false end`) only set the default on first load — a persisted `enabled = true` value would carry across sessions and silently block attacks (e.g. pressing `sr` as Apostate produced no attack with no echo).

**What changed:**

- **`006_Rebound_Hold.lua`**: Line 42 — replaced the `nil`-guarded default with an unconditional `reboundHold.config.enabled = false`. Rbhold now defaults off on every script load / login. Re-enable per-session with `rbhold on`.

---

## 2026-04-14 — Shikudo God Mode (5-Limb Dispatch)

### Feature: New "godmode" dispatch mode for Shikudo monks

Ported Pharaus' 5-limb dispatch strategy. Preps ALL 5 limbs (both legs, both arms, head) to 92%+ before a devastating 3-combo execute sequence that breaks everything simultaneously.

**What changed:**

- **`009_CC_Shikudo_GodMode.lua`** (NEW): Full godmode offense — `shikudo.godmode` namespace with calcLimbs(), light attack system with cumulative damage simulation, form-specific priorities (Rain/Oak/Willow/Gaital/Tykonos/Maelstrom), stateless 3-combo Gaital execute, condition-based form transitions, lock fork fallback, low HP Maelstrom override, status display.

- **`008_CC_Shikudo_Offense_ALL.lua`**: Added `godmode` to valid modes, dispatch branch delegates to `shikudo.godmode.run()`, status display routes to godmode status.

- **`153_Fourth_Attack_(All_Classes).lua`**: `^vv$` alias now sets godmode for Shikudo monks.

**Key mechanics:**
- 3-combo execute: sweep+flashheel (prone+break leg) → ruku+ruku+flashheel (break arms+leg) → needle+staff+flashheel (break head+crushedthroat)
- Light attacks prevent premature limb breaks during build phase
- Lock fork: if crushedthroat cured but arms broken + 3 lock affs → Rain for riftlock
- Reads limb data from `lb[target].hits` (canonical trigger-fed source)

**Usage:** `shikudo.setMode("godmode")` or `skgodmode()` or press `vv`

---

## 2026-04-13 — Psion rebounding removal + alias wiring

### Fix: Remove rebounding handling from Psion offense

Psion attacks no longer blocked by rebounding in Achaea. Removed all rebounding detection and stripping logic from the offense system.

**What changed:**

- **`001_Levi_Psion_Logic.lua`**: Removed `psion.hasRebounding()`, `weaveBypassesRebounding()`, and Priority 3 rebounding strip block from `buildAttack()`. Shield strip via `weave cleave` retained. Defensive `reboundHold.gate()` in dispatch kept (holds our own rebounding).

- **`152_First_Attack_(All_Classes).lua`**: Psion `zz` now explicitly sets mind mode before dispatch.

- **`155_Second_Attack_(All_Classes).lua`**: Added Psion entry — `xx` sets flurry mode + dispatch.

- **`153_Fourth_Attack_(All_Classes).lua`**: Added Psion entry — `vv` sets mind mode + dispatch.

---

## 2026-04-03 — Both-arms-broken flee logic (class-agnostic)

### Feature: SLC — auto-flee + leg parry when both arms are broken

Added a general defensive reaction that triggers whenever both of our own arms are broken, regardless of class or active offense system.

**Why:** When a Tekura monk breaks both arms the system kept spamming DWC attacks that require intact arms ("both arms must be whole and unbound"). More critically, staying in range lets the monk break legs next, enabling backbreaker/vivisect. The correct response is to flee 3+ rooms and fly immediately.

**What changed:**

- **`002_Track_The_Damage.lua`**: Added flee config fields to `selfLimbDamage.config` (`bothArmsFlee`, `fleeDir`, `fleeRooms`, `fleeBurstDelay`, `fleeRepeatInterval`) and flee state fields (`bothArmsFlee`, `_fleeTimerID`) to the namespace.

- **`004_Defensive_Reactions.lua`**: Added `handleBothArmsBrokenFlee()` hooked into the existing `onThresholdChange` dispatcher. When both arms reach "broken" threshold:
  - Sets `selfLimbDamage.bothArmsFlee = true`
  - Parries the less-damaged leg (`ataxia.parrying.shouldparry`)
  - Sends `tumble <dir>` + N raw movement commands + `fly`
  - Starts a repeating timer (default 4s) to re-flee if monk follows
  - Stops automatically when both arms are no longer broken

- **`002_Infernal_DWC_Vivisect_2L.lua`**: Added a gate at the top of `infernalDWC2LVivisect()` — returns immediately if both arms are broken, stopping attack spam.

**Configuration** (defaults — user-adjustable at runtime):
```lua
selfLimbDamage.config.fleeDir = "n"           -- flee direction
selfLimbDamage.config.fleeRooms = 3           -- rooms per burst
selfLimbDamage.config.fleeRepeatInterval = 4  -- re-flee interval (seconds)
selfLimbDamage.config.bothArmsFlee = false    -- disable feature
```

**Files:**
- `src_new/scripts/levi_ataxia/levi/ataxia/self_limb_tracking/002_Track_The_Damage.lua`
- `src_new/scripts/levi_ataxia/levi/ataxia/self_limb_tracking/004_Defensive_Reactions.lua`
- `src_new/scripts/levi_ataxia/levi/levi_scripts/dwc/002_Infernal_DWC_Vivisect_2L.lua`

---

## 2026-04-03 — Bard offense system namespace refactor

### Refactor: `001_LeviBard.lua` — new offense system pattern

Restructured the Bard blade attack script to match the `psion`/`dwc`/`tekura` namespace pattern.

**Why:** The file contained two bare global functions with ~40 lines of duplicated prep/refrain logic, loose globals scattered throughout, and `levibardtwo` was missing the `reboundHold.gate()` call that `levibardone` already had.

**What changed:**
- `bard` namespace with `bard.state` and `bard.config` tables
- `bard.calcPreps()` — limb prep calculation extracted and deduplicated (was copy-pasted verbatim into both functions)
- `bard.selectRefrain()` — refrain priority selection extracted and deduplicated
- `bard.preDispatch()` — shared preamble (getLockingAffliction, checkTargetLocks, flick check, envenomList reset)
- `bard.dispatchOne()` / `bard.dispatchTwo()` — replace function bodies; `levibardone`/`levibardtwo` kept as one-line wrappers
- **Bug fix:** `reboundHold.gate()` added to `bard.dispatchTwo()` (was missing from `levibardtwo`)
- `bard.combatEcho()`, `bard.status()`, `bard.reset()` — new utility functions
- Alias registration with reload-safe cleanup: `bardstatus`, `bardreset`, `barddebug`, `bardecho`
- Bare globals owned by triggers (`bardtempostance`, `bardsunset`, `bardsunrise`, `bladefinale`, `bardtemposequence`, `bardtempo`) left bare — triggers write them directly
- `rapierdamage` bare global preserved — `008_Sunrise.lua` and `009_SunSet.lua` read it to update `lb[target].hits`

**Files:**
- `src_new/scripts/levi_ataxia/levi/levi_scripts/bard/001_LeviBard.lua` — full refactor

---

## 2026-04-01 — Kai Surge trigger + mount lockout window + TK6 break upper fix

### Feature: Monk Kai Surge detection + 15s mount lockout offense window

Added trigger to detect Kai Surge usage and a 15s offense window that capitalizes on the target's mount lockout.

**Why:** The system had no trigger for the Kai Surge output line, so prone was never registered. More importantly, Kai Surge prevents the target from remounting for 15 seconds — during this window Shikudo (Gaital) should sweep to maintain prone and attack the limb the target was parrying, which can't normally be prepped.

**Trigger** (`002_Kai_Surge.lua`): Registers prone on target, sets `shikudo.state.kaiSurgeWindow = true`, clears it after 15s with an echo.

**Shikudo Gaital** (`008_CC_Shikudo_Offense_ALL.lua`): `selectGaitalStaff` now checks `kaiSurgeWindow` first. If there's a tracked parried limb, it prioritizes sweep (to re-prone if they stand) + `kuro <parried-leg>` in slot 2. Falls through to normal logic when window is inactive or no parried limb is known.

**Window flag**: moved from `shikudo.state.kaiSurgeWindow` to `ataxiaTemp.kaiSurgeWindow` so both TK6 and Shikudo share the same flag.

**TK6 `buildBreakUpperAttack`** (`002_Tekura_6Limb_Offense.lua`): replaced `mnk <arm> spp <arm> hkp;hrs` with `sdk spp left spp right;hrs`. Root cause: `;hrs` fires on free-balance before the combo lands when eq is off, switching to Horse stance prematurely while `mnk` (arm kick) is queued. Fix stays in Scorpion stance for the combo — `sdk` breaks torso, `spp left`/`spp right` break both arms, `hrs` transitions after.

**TK6 `buildPrepAttack`** (`002_Tekura_6Limb_Offense.lua`): Kai Surge window check added before all other logic — when `ataxiaTemp.kaiSurgeWindow` and a parried limb is tracked, delegates to the existing `buildParryBypassAttack` (sweep + double-punch parried limb) until the window expires or the limb is prepped.

**Files:**
- `src_new/triggers/levi_ataxia/for_levi/leviticus/monk/002_Kai_Surge.lua` — sets `ataxiaTemp.kaiSurgeWindow`
- `src_new/scripts/levi_ataxia/levi/levi_scripts/shikudo/008_CC_Shikudo_Offense_ALL.lua` — reads `ataxiaTemp.kaiSurgeWindow` in `selectGaitalStaff`
- `src_new/scripts/levi_ataxia/levi/levi_scripts/tekura/002_Tekura_6Limb_Offense.lua` — break upper fix + Kai Surge window in prep

---

## 2026-03-26 — Claude Code hooks and model routing

### Feature: Automated quality gates and context preservation hooks

Added 5 hook scripts to `.claude/hooks/` for development workflow safety, sourced from a review of `toukanno/claude-code-game-studios` and `affaan-m/everything-claude-code` repos.

**New hooks:**
- **`session-start.sh`** — Enhanced session startup context: shows branch, version, last 5 commits, uncommitted changes (replaces previous inline command)
- **`pre-compact.sh`** — Preserves working state (branch, version, staged/unstaged changes, WIP markers) to stderr before context compaction, so it survives into the post-compact context window
- **`protect-config.sh`** — Blocks AI Write/Edit to `.claude/settings*.json` files, preventing accidental permission weakening
- **`block-git-bypass.sh`** — Blocks dangerous git flags (`--no-verify`, `--force`, `--hard`, `--no-gpg-sign`, `git clean -f`)
- **`lint-before-commit.sh`** — Validates Lua syntax via `luac -p` on all staged `.lua` files before `git commit`, with YAML front matter stripping

**Configuration:** Updated `.claude/settings.local.json` with SessionStart, Notification (compact), and PreToolUse (Bash/Write/Edit) hook entries.

**Documentation:** Added "Model Routing Guidance" and "Hooks" sections to `CLAUDE.md` — documents when to use Opus/Sonnet/Haiku and describes all active hooks.

**Files:**
- `.claude/hooks/session-start.sh` — **New**
- `.claude/hooks/pre-compact.sh` — **New**
- `.claude/hooks/protect-config.sh` — **New**
- `.claude/hooks/block-git-bypass.sh` — **New**
- `.claude/hooks/lint-before-commit.sh` — **New**
- `.claude/settings.local.json` — Updated hook configuration
- `CLAUDE.md` — Added Model Routing Guidance and Hooks sections

---

## 2026-03-20 — Vulture's Talon artefact integration

### Feature: Auto-use Vulture's Talon for caloric defense vs Blademaster/Magi

When fighting Blademaster or Magi, if we gain shivering/frozen while off salve balance, the system automatically sends `SCRATCH MYSELF WITH TALON` to restore caloric defense. This bypasses salve balance, giving an extra cure channel when SSC can't apply salves.

**Toggle:** `ataxia.settings.user.artefacts.talon = true` (default: `false`, disabled for users without the artefact).

**Also added:** Self salve balance tracking (`ataxia.bals.used.salve`) — tracks when own salve balance is up/down via text triggers.

**Files:**
- `misc_scripts/022_User_Config.lua` — Added `talon` to artefacts config
- `swaps/005_Vulture_Talon.lua` — **New** — `ataxia_tryVultureTalon()` with 5 gates (artefact, cooldown, aff, class, salve bal)
- `004_Aff_gains_losses.lua` — Hook shivering/frozen gain to talon check
- `algedonic_defense_1.0/001_Anti_Priorities.lua` — Secondary hook in `Blademaster()` and `AntiMagi()`
- `curing_bals/005_Salve_Bal.lua` — Set `ataxia.bals.used.salve = true` on regain
- `curing_bals/010_Salve_Bal_Lost.lua` — **New** — Set salve bal false on self-salve application
- `curing_bals/011_Vulture_Talon.lua` — **New** — Placeholder trigger for success/cooldown text (inactive, needs in-game testing)
- `_groups.yaml` — Init `ataxia.bals.used.salve = true`

---

## 2026-03-18 — Basher flee-heal-return loop

### Feature: Auto-return to combat room after fleeing

Previously the basher fled to a safe room and resumed bashing there after recovering to 70% HP, never returning to finish killing mobs. Now the basher saves the room it fled from, heals to 100% HP, auto-navigates back, and resumes attacking. The cycle repeats if HP drops again, continuing until the room is cleared.

**New state:** `ataxiaTemp.fleeOriginRoom`, `ataxiaTemp.fleeReturning`, `ataxiaTemp.fleeReturnTimer` (15s safety timeout).

**Files:**
- `basher/001_Bashing_Functions.lua` — Save origin room in `executeFlee()`, rewrite `checkFleeRecovery()` for 100% HP + return navigation
- `update_stuff/002_ataxia_Room_Update.lua` — Detect arrival at origin room, clear return state
- `genrunning/004_Autobashing_Functions.lua` — Add `fleeReturning` gate to `tryAttack()` and `patterns()`, cleanup in `areaoff()`
- `genrunning/001_Bashing_API.lua` — Cleanup in `onDeath()` and `onAttacked()`

---

## 2026-03-17 — Fix Weathering, Toughness, Mindnet not raised during defup/keepup

### Fixed: `isDefenceForCurrentClass()` short-circuit bug

The function iterated class tables with `pairs()` (non-deterministic order) and returned `false` the moment it found a defense in any non-matching class table — without checking if it also existed in the player's own class or a universal category. Defenses appearing in multiple tables (e.g., toughness in both `blademaster` and `monk`) were randomly blocked depending on iteration order.

**Fix:** Two-pass logic — first check if the defense belongs to the current class or a universal category (return `true`), then only block if found exclusively in other class tables.

**Cleanup:** Removed `toughness`, `mindnet`, `weathering`, `consciousness` from `blademaster` table — these are Monk (Kaido) and shared skills, not blademaster-exclusive. Eliminates the duplicate entries that triggered the bug.

**File:** `deffing/004_Defence_Sorting_-_Cleaner.lua`

---

## 2026-03-16 — tLimbs removal cleanup: broken function calls + orphaned YAML

### Fixed: 11 broken function calls from tLimbs deletion

Deep dive verification found 11 trigger files still calling deleted tLimbs functions, which would crash at runtime:

- `psion_hitLimb()` — 8 triggers (517_Overhand through 525_Blackout). Removed calls; lb.addHit() from damage trigger already tracks limb damage.
- `magi_setBreakpoint()` — 2 triggers (698_Assess, 703_HYENA_SCENT). Removed calls; `magi_setDestroy()` and surrounding logic preserved.
- `smoteLimb()` — 1 trigger (001_Priest-Smite). Removed else branch; miss/dodge/parry handling preserved.

### Fixed: 8 orphaned _groups.yaml entries

Removed directory entries in `src_new/scripts/_groups.yaml` pointing to deleted folders: leviticus, scythe, backbreaker, earth_lord, i_snb, two_handed (x2), s_n_b. YAML validated after removal.

---

## 2026-03-16 — TK6 Parry avoidance fix + attack spread

### Fixed: PREP phase ignoring known parried limb

`buildPrepAttack()` used `getEffectiveParry()` which checks `canTargetParry()` (prone/paralysis). If V3/V1 affliction tracking had stale prone data, `getEffectiveParry()` returned `"none"` — disabling all parry avoidance. The system would then hit the known-parried limb in all 3 attack slots, wasting entire combos.

**Fix:** PREP now uses `getParried()` (raw parry data) instead of `getEffectiveParry()`. During PREP there's zero cost to always avoiding the parried limb — we just prep a different limb. Debug echo also uses raw parry so PARRY status always displays.

**Files:** `tekura/002_Tekura_6Limb_Offense.lua` — `buildPrepAttack()`, `dispatch.run()` echo

### Added: Attack spread across limbs during PREP

Previously `findSafeLimb()` always picked the lowest-damage limb, causing all 3 attacks (kick + 2 punches) to stack on the same limb when it was far behind. Opponent exploited this by parrying that one limb.

**Fix:** Added `skipLimb` parameter to `findSafeLimb()`. Kick selects normally, punch1 skips the kick limb, punch2 skips the punch1 limb. Skip is soft — if no alternative exists, the skipped limb is used via fallback passes. This spreads attacks across 2-3 different limbs per combo, so opponent can only parry 1 of 3.

`findSafeLimb()` now has 6 passes: non-parried non-skipped → non-parried skipped → parried (for both unprepped and overflow pools).

**Files:** `tekura/002_Tekura_6Limb_Offense.lua` — `findSafeLimb()`, `buildPrepAttack()` punch selection

---

## 2026-03-16 — Removed legacy tLimbs system, consolidated on lb

### Removed: tLimbs limb tracking system

The legacy `tLimbs` system used hardcoded lookup tables to estimate limb damage. The custom `lb` system reads actual damage values from game output and is strictly superior. All actively-used offense systems already used `lb`. This change removes `tLimbs` entirely.

**Why:** tLimbs predicted damage from lookup tables that drifted from actual game values, causing inconsistent break thresholds (97-99.99% across classes), no per-target persistence, no salve/restoration tracking, and no event system. `lb` reads the game's actual "dealt X% damage" output and has none of these problems.

**Deleted (~80 files):**
- `limb_management/` — 9 class-specific tLimbs files (Bard, Dragon/Elord, Magi, Priest, Psion, Knight, Sentinel, Sylvan, core lookup tables)
- `monk/001_Tekura_Limb_Counter.lua`, `monk/002_Shikudo_Limb_Counter.lua` — lookup table damage trackers
- `s_n_b/`, `i_snb/`, `earth_lord/`, `backbreaker/`, `scythe/`, `leviticus/`, `two_handed/` — inactive offense systems
- `levi_scripts/001-013`, `023`, `024`, `032` — old numbered limb attack scripts
- `triggers/` — 26 DIAGNOSE limb status triggers that only wrote to tLimbs

**Edited (~20 files):**
- `shikudo/006`, `shikudo/008` — removed tLimbs init/reads, now fully on `lb`
- `dwc_runie/004_Head_Prep.lua` — replaced 5 tLimbs reads with `lb[target].hits`
- `dwc_runie/001_RIFT.lua`, `002_BASIC_2.lua` — replaced 10 tLimbs reads each
- `016_Targeting_Functions.lua` — removed tLimbs reset, replaced `magi_resetLimbs()` with `lb.resetAll()`
- `login/001_Login_Function.lua` — removed `ataxia_resetLimbTable()` call
- `632_Add_Limb_Damage.lua` — removed tLimbs branch, kept lb-based highlighting
- `_groups.yaml` — replaced Limb Management inline script with lb-delegating stubs
- `012_Prompt_Substitution.lua` — `%tlimbs%`/`%nlimbs%` now use `lb.prompt()`
- `007_Target_Applied_Somewhere.lua` — `target_resetLimb()` calls → `lb.resetLimb()`
- Various triggers — removed dead `bard_addLimbDamage`, `knight_dwbAddHit` calls

---

## 2026-03-16 — Limb damage mechanics corrections

### Fixed: Restoration timer 3.7s → 4.0s

All restoration healing timers were using 3.7s instead of the correct 4.0s game mechanic. The 300ms error could cause the system to assume a limb healed before it actually did.

**Files:** `levi_scripts/limb/002_limb_management.lua` (`lb.salve()`), `ataxia/limb_management/007_Target_Applied_Somewhere.lua` (`target_appliedTo()` — 4 instances)

### Added: Per-hit 100% damage cap on all limb tracking

A single hit that would push a limb above 100% now only brings it to exactly 100% (excess lost). Subsequent hits on already-broken limbs stack normally up to 200% max.

```lua
-- Pattern applied to all damage functions:
local oldDmg = tLimbs[code]
tLimbs[code] = tLimbs[code] + damage
if oldDmg < 100 and tLimbs[code] > 100 then tLimbs[code] = 100 end
tLimbs[code] = math.min(tLimbs[code], 200)
```

**tLimbs systems (5 files):**
- `ataxia/monk/001_Tekura_Limb_Counter.lua` — `tekura_addDamage()`
- `ataxia/monk/002_Shikudo_Limb_Counter.lua` — `shikudo_addDamage()`
- `ataxia/limb_management/008_Knight_Limbcounting.lua` — `knight_addLimbDamage()`, `knight_dwbAddHit()`
- `ataxia/limb_management/006_Psion_Limb_Tracking.lua` — `psion_hitLimb()`
- `ataxia/limb_management/004_Magi-Specific.lua` — `magi_staffStrike()`

**lb system:** `levi_scripts/limb/002_limb_management.lua` — `lb.addHit()`

### Added: SLC 200% damage stacking + restoration indicator

Self Limb Counter now tracks damage up to 200% (was hard-capped at 100%). GUI shows firebrick color for over-broken limbs with `[Nx REST]` indicator showing how many restoration applications are needed.

New helper: `ataxia_selfRestorationsNeeded(limb)` — returns `math.ceil(damage / 100)`.

**File:** `ataxia/self_limb_tracking/002_Track_The_Damage.lua`

### Added: TK6 right-limb tiebreaker in findSafeLimb()

When two limbs have equal damage, `findSafeLimb()` now prefers right limbs. This means left limbs get prepped first → heal first on restoration → right stays broken longer.

**File:** `levi_scripts/tekura/002_Tekura_6Limb_Offense.lua`

### New documentation

- `docs/limb-damage-mechanics.md` — Comprehensive reference: damage levels, per-hit cap, restoration timing, left-limb-first priority, tracking systems, class-specific thresholds
- `docs/limb-prep-classes.md` — Per-class limb offense reference: TK6, TKD, DWC, DWB-Runie, Blademaster, Apostate, Shikudo, Psion, Magi
- `.claude/templates/limb_tracking_template.lua` — Updated header with mechanics reference

---

## 2026-03-16 — Tekura break guards + kai mode config

### Fixed: TK6 parry bypass breaking limbs during PREP

When only 1 unprepped limb remained and it was parried, `buildParryBypassAttack()` sent two punches to the same limb with no break prevention. If `currentDmg + 2*punchDmg >= 100`, the limb broke prematurely instead of getting prepped.

**Root cause:** The parry bypass path short-circuited before the main `simDmg`-based break prevention logic.

**Fix:** Added break guard — checks if two punches would break the limb; if so, uses 1 real punch + overflow/filler for the 2nd slot.

### Fixed: TK6 raze breaking torso during PREP

Rebounding/shield raze used hardcoded `rhk hkp hkp`, which puts 2x punch damage on torso. If torso was already prepped (86%+), this would break it.

**Fix:** New `safeRazePunches()` helper iterates all limbs with simulated damage to find safe punch targets during PREP phase. Falls back to `jbp` fillers when no safe targets exist.

### Fixed: Legacy TKD had zero break guards in all prep builders

The legacy 3-limb system (`tekura` namespace) had `wouldBreakLimb()` defined but never used it in combo builders:

- `buildTorsoPrepAttack()`: `sdk hkp hkp` (53% per combo) would break torso on the 2nd combo. Added simulated damage tracking per attack slot.
- `buildLegPrepAttack()`: `snk focus hfp focus hfp other` could break focus leg if > 61%. Added full simDmg approach with kick/punch redirect to safe targets.
- `buildTorsoBreakAttack()`: Parry fallback sent `swk hfp left hfp right` which broke prepped legs. Changed to `swk hkp hkp;hrs` (sweep prones target, then break torso as intended).

### Added: Kai mode configuration for TK6

New `tekura6.config.kaiMode` setting (`"surge"` or `"cripple"`) controls which kai ability is used when dismounting a mounted target during parry bypass.

- `zz` (First Attack) sets `kaiMode = "surge"` — 31 kai, 3.2s eq, dismount only
- `vv` (Fourth Attack) sets `kaiMode = "cripple"` — 41 kai, 4.0s eq, dismount + level 1 breaks all limbs

**Files:** `tekura/002_Tekura_6Limb_Offense.lua`, `tekura/001_Tekura_Offense.lua`, `152_First_Attack_(All_Classes).lua`, `153_Fourth_Attack_(All_Classes).lua`

---

## 2026-03-16 — Jester bashing + mob damage tracking DB (v4.7.12)

### New: Mob Damage Tracking Database

SQLite-backed system that records non-critical damage dealt to mobs, tracking min/max damage per class, primary stat value, and mob name.

- Crit trigger sets a flag; damage trigger skips recording when flag is set
- Uses existing class-to-stat mapping (e.g., Serpent→dex, Magi→int)
- Records update in-place: min/max damage and hit count per unique (class, stat, mob) combo
- Displayed live in the limb counter window during bashing (below DPS stats)
- Queryable via `ataxiadmg` alias with filtering, deletion, and reset

**New Files:**
- `basher/007_Mob_Damage_DB.lua` — DB schema, class-stat mapping, record/display/delete/reset
- `aliases/.../zdata/003_(ataxiaDmg).lua` — `ataxiadmg` alias

**Modified Files:**
- `334_Crits.lua` — sets `bashStats.lastHitWasCrit` flag
- `350_Damage_Dealt.lua` — records non-crit hits via `ataxia.data.db.recordMobDamage()`
- `001_Limb_Counter_Window.lua` — shows mob damage stats in `tarc` window

**Commands:**
| Command | Purpose |
|---------|---------|
| `ataxiadmg` | Show all records |
| `ataxiadmg <class>` | Filter by class |
| `ataxiadmg <mob/area>` | Filter by mob name or area |
| `ataxiadmg delete <filter>` | Delete matching records |
| `ataxiadmg reset` | Clear all records |

### Improved: Jester Bashing

- Auto-wields blackjack + shield before every attack
- Uses `gallowshumour` instead of `bop` when mob HP drops below 50%

**File:** `basher/002_Class_Bashing.lua`

---

## 2026-03-16 — DWC weapon config fix + combined DSL party callouts (v4.7.12)

### Fixed: DWC systems not wielding configured weapons after login

All 3 DWC systems (vivisect, 2-limb, group lock) initialized their weapon config at script load time, before `ataxia_loadSettings()` ran. This caused `ataxia.settings.weapons` to be `nil`, falling back to the generic type name `"scimitar"` instead of the actual weapon ID (e.g., `scimitar405398`). Result: `wield right scimitar;wield left scimitar` tried to wield the same weapon in both hands, leaving one hand empty and failing DSL/RSL with "You must be wielding two scimitars or battleaxes."

Additionally, `ataxia setup weapons set` and `ataxia setup weapons confirm` only synced `infernalDWC.config` — the group lock and 2-limb configs were never updated.

**Fix:**
- Added `refreshWeapons()` to all 3 DWC namespaces, registered on `"ataxia system loaded"` event to reload weapon IDs from `ataxia.settings.weapons` after settings load
- Extended weapon sync in setup wizard (`020_Setup_Wizard.lua`) and weapon detect confirm (`023_Weapon_Detect.lua`) to also update `infernalGroupLock.config` and `infernalDWC2L.config`

**Files:** `dwc/001_Infernal_DWC_Vivisect.lua`, `dwc/002_Infernal_Group_Lock.lua`, `dwc/002_Infernal_DWC_Vivisect_2L.lua`, `020_Setup_Wizard.lua`, `023_Weapon_Detect.lua`

### Fixed: DSL party callouts now on a single line

DSL (double slash) attacks send two venoms — one per weapon hit. Each hit's venom confirmation trigger independently sent a separate party message, producing two lines:
```
(Party): You say, "Pharaus: paralysis."
(Party): You say, "Pharaus: asthma."
```

Added `dslPartyRelay()` helper function that defers hit 1's callout and combines it with hit 2 into a single message:
```
(Party): You say, "Pharaus: paralysis asthma"
```

**Files:** `017_Affliction_Management.lua` (new `dslPartyRelay` function), all 9 `double_slash/` trigger files (001–006, 008–010)

---

## 2026-03-16 — Fix combatQueue nil crash + serpent improvements (v4.7.11)

### Fixed: `combatQueue()` crash when pressing `xx` before settings load

Pressing `xx` (Second Attack alias) before `ataxia_loadSettings()` completes caused:
```
attempt to index field 'use' (a nil value)
```
`ataxia.settings.use` was nil because the queueing functions accessed `.use.parry` without nil guards. Same issue existed in `depthswalkerQueue()`.

**Fix:** Added nil guards matching the existing defensive pattern from `010_Prompt_Running.lua`:
```lua
if ataxia.settings and ataxia.settings.use and ataxia.settings.use.parry ...
```

**File:** `003_Queueing_Related.lua` (lines 54, 84)

### Improved: Serpent hypno lock suggestions skip already-applied affs

`selectHypnoLockSuggestions()` now filters out afflictions the target already has, avoiding wasted hypnosis stacks.

### Improved: Serpent impatience delivery condition

Added `anorexia + no focus balance` as a valid condition for impatience delivery via Impulse, expanding the window for lock completion.

**File:** `002_Serpent_Offense.lua`

---

## 2026-03-16 — Fix deepMerge dropping settings sub-tables on load (v4.7.5)

### Fixed: `ataxia.settings.defences` (and all other settings sub-tables) nil after login

The `deepMerge` function in `ataxia_loadSettings()` was too conservative — it skipped loading any saved table that didn't already exist in the runtime destination. Since `ataxia.settings` is pre-initialized as `{}` (empty) by `001_Core.lua`, all sub-tables (`defences`, `have`, `use`, `sipping`, etc.) were silently dropped during load.

This caused `aconfig profile create` and other defence profile commands to silently fail (guard clause exits on nil `ataxia.settings.defences`).

**Fix:** `deepMerge` now injects saved tables when `dst[k]` is nil (no runtime object to protect). It still skips when `dst[k]` is a non-table type (function, userdata) to preserve live objects.

**File:** `001_Save_Load_Settings.lua` (lines 143–155, `deepMerge` function)

---

## 2026-03-15 — Fix login GMCP race conditions (v4.7.1)

### Fixed: nil errors on login from GMCP events firing before settings load

Three scripts crash when GMCP events fire before `ataxia_loadSettings()` completes:
- `ataxia_Room_Update` — `ataxia.settings.defences` nil check added
- `Prompt Running` — `ataxia.settings.use` nil check added
- `Deffing Up` / `systemDefup()` — early return if settings not loaded

**Files:** `002_ataxia_Room_Update.lua`, `010_Prompt_Running.lua`, `002_Deffing_Up.lua`

---

## 2026-03-15 — Basher improvements: auto-learn denizens, non-destructive install, startup config

### New: Auto-learn denizen system
Automatically adds room denizens to the area's `targetList` when the basher is active and you enter a room. No more manually adding every denizen in every area. Configurable via `ataxia setup basher autolearn on/off` (default: on).

**Files:**
- `003_ataxia_RoomContents_Update.lua` — auto-learn logic on room entry (gated by `ataxiaBasher.enabled` and `ataxiaBasher.autoLearn`)
- `340_Slain.lua` — also learns denizens on kill (with nil guards)
- `001_Install.lua` (alias) — `autoLearn = true` in defaults
- `020_Setup_Wizard.lua` — toggle command, display row, guide entry, status overview
- `002_Check_For_Any_Missing_Variables.lua` — backfill for existing users

### Fixed: `abinstall` no longer wipes existing basher settings
Both `abinstall` alias and `ataxia setup install basher` now use a merge pattern — only fills in missing keys, preserving existing `targetList`, routes, flee thresholds, etc.

**Files:** `001_Install.lua` (alias), `020_Setup_Wizard.lua`

### Fixed: Login GMCP race condition
`ataxia.defences`, `ataxia.afflictions`, `ataxia.vitals` are now initialized in `_groups.yaml` init script so GMCP events that fire before `levilogin()` don't crash on nil tables.

**File:** `_groups.yaml`

### Added: Startup config for new installs
`ataxia_installSystem()` now sends `config commandseparator ;` and `config usequeueing yes` on first install.

**File:** `003_Install_System.lua`

---

## 2026-03-15 — Hypochondria cure changed: kelp/aurum → lobelia/argentum

### Changed: Hypochondria cure reassignment

**Motivation:** Hypochondria is now cured by lobelia/argentum, NOT kelp/aurum. Updated all cure tables, herb removal priority, kelp stack checks, priority swaps, affliction colouring, and documentation to reflect this change.

**Updates:**
- V2/V3 cure tables updated (afflictions.yaml, venoms.yaml)
- Herb removal priority and kelp stack checks updated in 10+ offense files
- brSlick priority swap updated
- Affliction colouring updated
- `_groups.yaml` inline tables updated

**Files affected:**
- `afflictions.yaml`, `venoms.yaml`
- `001_Core.lua`, `007_Branching_State_Tracker.lua`, `002_Herb_Cures.lua`
- `_groups.yaml`
- `002_Serpent_Offense.lua`, `003_Priority_Swaps.lua`, `008_Affliction_Colouring.lua`
- `001_Default_Curing_Prios.lua`
- 10 offense priority files
- Documentation: `CLAUDE.md`, `serpent.md`, `lock_types.md`

---

## 2026-03-15 — Magi offense: xmagi deep review cleanup

### Deleted: Legacy duplicate resonance triggers (11 files)

**Motivation:** Deep review against xmagi (Tabethys) revealed that legacy per-element resonance triggers in `air/`, `water/`, `earth/` folders duplicate the unified `022_Resonance_Afflictions.lua`, causing double `tarAffed()` calls. Additional bugs: `water/002_Second.lua` had hardcoded "Antoninus" target, `earth/003_Third.lua` had "yourdirected" typo preventing matches, `earth/001_First.lua` had wrong capture group.

**Files deleted:**
- `air/001_First.lua`, `air/002_Second.lua`, `air/003_Third.lua`
- `water/001_Water_First.lua`, `water/002_Second.lua`, `water/003_Third.lua`
- `earth/001_First.lua`, `earth/002_Second.lua`, `earth/003_Third.lua`
- `fire/001_Fire_Third.lua`, `fire/002_Fire_Second.lua` (already disabled)
- **Kept:** `fire/003_Fire_First.lua` — has unique caloric strip tracking (`targetlostfrost`) not in 022

### Deleted: Duplicate emanation triggers (2 files)

**Motivation:** `magi_offense_tracking/002,003` duplicate `enamation/002,003` (the enamation versions have fuller logic including chain tracking and +2 burns).

**Files deleted:**
- `magi_offense_tracking/002_Emanation_Air.lua`
- `magi_offense_tracking/003_Emanation_Water.lua`

### Fixed: `general/002_Calcify_Head_Finish.lua` — case mismatch

- Changed `erAff("Calcifiedskull")` to `erAff("calcifiedskull")` — was mismatched with `tarAffed("calcifiedskull")` in 026_Calcify.lua, causing the affliction to never be properly cleared

### Fixed: `general/005_Firestorm_up.lua` — dead code removal

- Removed `if target == matches[2]` block that never executed — trigger uses substring match (type 3) which has no capture groups, so `matches[2]` was always nil. Burns tracking is handled by `025_Burns_Tracking.lua` on firestorm ticks

### Fixed: `general/021_Freeze.lua` — V3 migration

- Replaced direct `tAffs.shivering`/`tAffs.nocaloric`/`tAffs.frozen` reads with `haveAff()` calls for V3 probability-aware tracking
- Fixed `haveAff("nausea")` no-op queries that should have been `tarAffed("nausea")` — freeze applies nausea as an affliction, not just querying it

### Fixed: `general/015_Dehydrate.lua` — V3 migration

- Replaced all `tAffs.*` reads with `haveAff()` calls for V3 probability-aware tracking
- Removed orphaned `haveAff("weariness")` no-op query in last block (weariness already confirmed by condition)

### Deleted: `fire/003_Fire_First.lua` — duplicate of `014_Temperance.lua`

- Both fire on identical pattern (`^You direct your will against the temperance elixir...`). 014_Temperance.lua is the better version — tracks `tarAffed("notemperance")` with 17s expiry. The `targetlostfrost` flag in both was dead code (never read by any script).

### Fixed: `general/019_Conflagrated.lua` — conflagrate burns should be +2

- Changed `if burns < 2 then burns = 2` to `math.min(burns + 2, 5)` — conflagrate adds 2 burn stacks per xmagi reference, not "set floor to 2". Previous logic did nothing if burns were already >= 2.

### Fixed: `enamation/002_Water_Emanation.lua` — chain logic inverted

- Rewrote water emanation chain progression to use `haveAff()` (V3) instead of mixed `magi.offense.hasAff()`/`tAffs` checks
- Fixed chain: nocaloric (strip caloric) → shivering (if already nocaloric) → frozen (if both nocaloric + shivering)
- Previous logic was inverted: checked shivering first and re-applied it redundantly

### Fixed: `general/005_Firestorm_up.lua` + `003_Firestorm_down.lua` — dead code cleanup

- Removed `magi.firestormm` (double-m typo) — never read by any code. `magi.firestorm` (single-m, stores room number) is the actual state used by offense engine.

### Cleaned up: Temporary files

- Removed extracted `magiaddtriggs.xml` (xmagi reference file, no longer needed)

---

## 2026-03-15 — V3 affliction tracking: ExpertDiagnoser parity + hardening

### Fixed: `scripts/.../affliction_tracking_core/007_Branching_State_Tracker.lua` (deep review)

**Fixes from deep review:**
- **`onSmokeCureV3` now uses weighted branching** — Was using equal probability split; now uses `computeCureWeightsV3()` matching herb/salve handlers for SSC priority-weighted branching
- **Removed epseth/epteth from venom expansion** — These break a SINGLE limb (determined by game output), not both sides. Limb damage triggers track the specific limb directly
- **Removed rebounding→shield+curseward cascade** — Shield, curseward, and rebounding are independent defenses in Achaea. Stripping one does not strip the others
- **Fixed `killNegativeConfirmV3` Lua 5.1 safety** — Was setting keys to nil during `pairs()` iteration (undefined behavior in Lua 5.1). Now kills all timers then reassigns table to `{}`

### Added: `scripts/.../affliction_tracking_core/007_Branching_State_Tracker.lua`

**Motivation:** ExpertDiagnoser comparison revealed multiple feature gaps vs mature combat systems. These enhancements close the most impactful gaps identified in the analysis.

**New features:**
- **Cure priority weighting** — `computeCureWeightsV3()` applies decay weights (4/2/1/1...) to herb/salve cure branching. Highest-priority candidate gets ~57% probability instead of equal 1/N. Matches SSC's strict priority order.
- **Frozen/caloric/shivering interaction** — `applyFrozenInteractionV3()` models the frozen → caloric → shivering chain. Frozen strips caloric defense first; without caloric, adds shivering then frozen.
- **Burning stack levels 1-5** — `targetBurningLevelV3` tracks burning level (0-5). Mending body skips burning cure when level > 1 (only cures at level 1). `getBurningLevelV3()`, `resetBurningLevelV3()`.
- **Venom expansion** — `venomExpansionV3` table expands compound venoms to constituent afflictions: epseth → broken legs, epteth → broken arms, sicken → manaleech + slickness. `applyAffV3` auto-expands recursively.
- **Affliction decay/timeout** — `affLastConfirmedV3` tracks last confirmation timestamps. `pruneStaleAffsV3()` removes unconfirmed affs older than 60s with probability < 0.3. Prevents stale low-probability branches from persisting indefinitely.
- **Target defense model** — `targetDefensesV3` tracks caloric, rebounding, shield, curseward, blindness, deafness, insomnia. `setTargetDefenseV3()`, `hasTargetDefenseV3()`, `resetTargetDefensesV3()`. Rebounding strip cascades to shield + curseward. Affliction-defense interactions: sensitivity strips deafness, transfixation strips blindness, sleep strips insomnia.
- **Intelligent backtracking** — `shouldBacktrackGatingAffV3()` only backtracks gating afflictions (asthma, anorexia, slickness) when dependent afflictions still exist in cache. Reduces false-positive unfolds.
- **Voyria in passive cure pool** — Added `"voyria"` at position 1 in `passiveCurableAffsV3` (highest priority, matching game behavior).

**Fixes:**
- **`killNegativeConfirmV3()`** now iterates ALL entries in `negativeConfirmTimersV3` instead of only killing the timer for `lastGuessV3.cureType`. Prevents orphaned timers when multiple cure types have concurrent neg-confirm timers.
- **`resetStatesV3()`** now also calls `resetCureBalancesV3()` and `killNegativeConfirmV3()` for safety — previously these were only called from the `"changed target"` event handler.
- **Venom expansion names** fixed to match system naming convention (`brokenleftleg` not `crippled_left_leg`).

### Added: `scripts/.../affliction_tracking_core/008_V3_Integration.lua`

**New features:**
- **`onDiagnoseV3(diagnosedAffs)`** — Collapses all branches to a single verified state on DIAGNOSE. Accepts both array and set format. Diagnosis is the strongest verification signal — resets to exactly one branch at 100% probability with the diagnosed afflictions.
- **Illusion detection via cure balance gating** — All 5 cure handlers (`onTargetSmokeV3`, `onTargetApplySalveV3`, `onTargetAteV3`, `onTargetFocusV3`, `onTargetTreeV3`) now check `canTargetCureV3()` before processing. If target fires a cure while still on that cure's balance, it's flagged as an illusion and skipped. Logs via `ataxia.decho`.
- **Focus blocked by impatience** — `onTargetFocusV3()` returns early if `getAffProbabilityV3("impatience") >= 1.0` (confirmed impatience blocks focus).
- **`sysDisconnectionEvent` handler** — Resets all V3 state on disconnect: `resetStatesV3()`, `resetCureBalancesV3()`, `killNegativeConfirmV3()`, `resetBurningLevelV3()`, `resetTargetDefensesV3()`, `resetAffTimestampsV3()`. Prevents stale timers and branches from surviving reconnect.

### Updated: `scripts/.../affliction_tracking_core/003_Backtracking.lua`

- Added deprecation header marking file as superseded by V3 negative confirmation system. All functions overridden by no-op stubs in 008_V3_Integration.lua. Retained for reference only.

### Added: Passive cure cooldown tracking (007 + 008)

**Motivation:** ExpertDiagnoser tracks per-ability passive cooldowns. Without this, offense systems can't know when a passive cure is available again.

**New features (007):**
- **`passiveCooldownsV3` / `passiveCooldownTimingsV3`** — Per-ability cooldown table: 12s (airlord, healingrite, syphon, dagaz, leech, accelerate, alleviate, bloodboil, dragonheal, expunge, fitness, might, purification, purify, salt, shrugging, slough, eruption, continuation, root), 14s (hallelujah), 20s (suntarot, panacea, fool)
- **`startPassiveCooldownV3(abilityKey)`** — Records cooldown expiry timestamp
- **`canTargetPassiveV3(abilityKey)`** — Returns true if cooldown expired
- **`getPassiveCooldownTimeV3(abilityKey)`** — Returns remaining seconds
- **`resetPassiveCooldownsV3()`** — Clears all cooldowns. Called from `resetStatesV3()` and `sysDisconnectionEvent` handler

**New features (008):**
- **`onTargetApplyRestorationV3()`** — Illusion check via `canTargetCureV3("restoration")`, then `collapseAffAbsentV3("slickness")`, starts restoration balance timer
- **`onTargetWritheV3()`** — Starts writhe balance timer (1.8s)

**New timers (007):**
- Restoration balance: 3.8s normal, 5.8s when scalded (same pattern as salve)
- Writhe balance: 1.8s

### Added: 7 class-specific passive cure triggers (022-028)

**Motivation:** The catch-all `001_Passives.lua` treated all passive cures identically. Class-specific triggers enable per-ability cooldown tracking and future class-aware offense decisions.

**New files** in `triggers/.../passive_active/`:
- `022_Air_Lord_Passive.lua` — Air Lord, "tempestuous form...purifying breeze", 12s cooldown
- `023_Sun_Tarot.lua` — Jester/Occultist, "globe of light illuminates", 20s cooldown
- `024_Healing_Rite_(Priest).lua` — Priest, 3 patterns (gentle glow + guardian angel + golden light), 12s cooldown
- `025_Hallelujah_(Bard).lua` — Bard, 2 patterns (song + soft chiming), 14s cooldown
- `026_Syphon_(Apostate).lua` — Apostate, "demonic crimson glow", 12s cooldown
- `027_Dagaz_(Runewarden).lua` — Runewarden, "rune like a rising sun", 12s cooldown
- `028_Leech_(Pariah).lua` — Pariah, "pulses from chest", 12s cooldown

All triggers include: `isTargeted()` check, class check via `ataxiaNDB_getClass()`, voyria-first cure logic, `onClassCureV3()`, `startPassiveCooldownV3()`, line coloring, `targetIshere = true`.

### Updated: `001_Passives.lua` — catch-all cleanup

- Removed 10 patterns now handled by class-specific triggers (022-028)
- Kept 3 generic catch-all patterns: translucent achromatic aura (unknown), cool refreshing mist (uncertain mapping), keening whine (Unnamable — low priority)

### Updated: Writhe triggers (407/408/409) — writhe balance timer

- Added `if onTargetWritheV3 then onTargetWritheV3() end` to all 3 writhe triggers after their `erAff()` calls
- `407_Writhed_Impale.lua`, `408_Writhe_Ropes.lua`, `409_Writhed_Transfix.lua`

### Fixed: `getAllCureBalancesV3()` — missing restoration/writhe (007)

- Added `restoration` and `writhe` entries to the return table so callers get complete cure balance status

### Updated: Existing passive cure triggers (002-020) — cooldown tracking

- Added `startPassiveCooldownV3()` call to all 18 existing passive triggers (002-020, skipping 021 Waking Up)

---

## 2026-03-14 — V3 affliction tracking: major enhancements

### Added: `scripts/.../affliction_tracking_core/007_Branching_State_Tracker.lua`

**Motivation:** ExpertDiagnoser review revealed multiple gaps in our V3 target affliction tracking compared to mature combat systems. These enhancements improve cure prediction accuracy, add timing intelligence, and provide offense systems with richer query APIs.

**Cure table fixes:**
- Added `burning` to `salveCureTableV3.body` — was missing, caused magi burn tracking to be incomplete
- Added `stuttering` to `salveCureTableV3.head` — was missing from head mending group
- Added SSC anorexia priority: body mending now cures anorexia first before other body affs (matches SSC behavior)

**New features:**
- **`countGroupAffsV3(group, minCount)`** — Query probability that target has N+ afflictions from a cure group across all branches. Predefined groups: `mending_body`, `mending_skin`, `mending_head`, `mending_arm`, `mending_leg`, `mending_all`, all herb groups, `smoke`. Returns 0.0-1.0 probability.
- **`getMostLikelyGroupAffCountV3(group)`** — Get count from most likely branch
- **Cure balance timers** — Track when target can next use each cure type. `startCureBalanceV3(type)`, `canTargetCureV3(type)`, `getCureBalanceTimeV3(type)`, `getAllCureBalancesV3()`. Durations: herb 1.3s, pipe 1.3s, salve 0.8s (1.3s when scalded), focus 2.2s, tree 13s
- **Scalded salve balance doubling** — When target has scalded, salve balance automatically uses 1.3s instead of 0.8s
- **Negative confirmation (backtracking)** — When V3 branches on ambiguous cure, starts a timer. If no second cure action within the balance window, unfolds the branch (re-adds all candidates). Prevents wrong guesses from persisting. Config: `affConfigV3.negativeConfirm`
- **`onClassCureV3(specificAffs, numRandom)`** — V3-native class cure processing. Removes specific affs deterministically + handles N random cures via passive cure pool

### Updated: `scripts/.../affliction_tracking_core/008_V3_Integration.lua`

- All verification signal handlers (`onTargetSmokeV3`, `onTargetFumbleV3`, `onTargetVomitV3`, `onTargetSlickFailV3`) now call `killNegativeConfirmV3()` to clear pending backtrack timers
- `onTargetTreeV3()` and `onTargetFocusV3()` now start cure balance timers
- `onTargetApplySalveV3()` now calls `killNegativeConfirmV3()` + `startCureBalanceV3("salve")` — salve application is a cure action
- `onTargetAteV3()` now calls `killNegativeConfirmV3()` + `startCureBalanceV3("herb")` — eating is a cure action
- `onPassiveCureV3()` now calls `killNegativeConfirmV3()` after state updates — passive cures resolve ambiguity

### Updated: `triggers/.../passive_active/*.lua` (21 class cure triggers)

- Replaced dead V2 stubs (`removeAffV2`, `reduceRandomAffCertaintyV2`) with `onClassCureV3()` calls
- All class-specific cures now properly integrate with V3 branching engine

### Fixed: Double `erAff()` calls across 18 class cure triggers

**Motivation:** `onClassCureV3()` internally calls `erAff()` for each specific affliction, but 18 trigger files also called `erAff()` explicitly before `onClassCureV3()`. This caused double event firing (`"target cured aff"`), double GUI refresh, and triple `removeAffV3()` calls per cure.

**Changes (18 files in `triggers/.../passive_active/`):**
- Removed redundant explicit `erAff()` calls from: Accelerate, Alleviate, Bloodboil, Dragonheal, Expunge, Fitness, Fool, Might, Purification, Purify, Rage, Salt, Shrugging, Slough, Continuation, Priest Healing, Sylvan Root, and Passives
- `onClassCureV3()` is now the single entry point for all class cure processing

### Fixed: `021_Waking_Up.lua` — missed V3 migration

- Replaced legacy `erAff("sleep")` with `onClassCureV3({"sleep"})` — this file was skipped during the original V3 migration

### Fixed: `010_Phoenix_(BM).lua` — removed dead V2 code

- Removed residual `if resetAffsV2 then resetAffsV2() end` — redundant with `resetStatesV3()` on the next line

### Fixed: `006_Expunge_(Psion).lua` — duplicate affliction in priority list

- Removed duplicate `"stuttering"` entry (appeared at both position 1 and position 20 in eAffs list)

---

## 2026-03-14 — Fix serpent flay wasting gecko (slickness) without asthma

### Fixed: `scripts/.../serpent/002_Serpent_Offense.lua`

**Motivation:** Flay venom selection could pick gecko (slickness) when the target didn't have asthma. Without asthma blocking smoking, slickness is instantly cured via valerian — a wasted venom slot. Observed in combat: flay rebounding with gecko, target immediately smokes to cure slickness.

**Changes:**
- Added asthma guard on flay fallback: if `envenomList[1]` is gecko but target lacks asthma, substitutes curare
- Added gecko option to flay if/elseif chain (after kalmia): when all 4 base affs present and asthma confirmed, proactively picks gecko
- Gated `scytherus_attack` strategy gecko behind asthma check, falls back to `pickVenom()` without asthma
- Fixed `lock_reinforce` second venom when paralysis missing: now uses `getLockingAffliction("name")` to dynamically look up the target's class-specific lock affliction (e.g., weariness for Knights, voyria for Apostate, haemophilia for Magi), maps it via `AFF_TO_VENOM`, and falls back to voyria. No longer wastes the slot on generic `pickVenom()` output like clumsiness
- Added `voyria` and `haemophilia` entries to `AFF_TO_VENOM` table for lock completion venom lookups

---

## 2026-03-14 — Add auto parry mode to SLC

### Added: `scripts/.../self_limb_tracking/003_Parrying.lua`, `002_Track_The_Damage.lua`

**Motivation:** The existing parry modes (stand, defend, manual, randomarm, randomleg) each use a single static strategy. An `auto` mode dynamically adapts based on enemy class and attack patterns — parrying focused limbs against limb classes (Knights, Monk, Blademaster, etc.) while defaulting to leg bias against affliction classes.

**Changes:**
- New `auto` parry mode: class-aware strategy using `classDetect.state.attackerClass` and hit-pattern detection
- Added `selfLimbDamage.hitHistory` — rolling window of last 6 hits for focus detection
- Added `ataxia_detectLimbFocus()` — analyzes last 4 hits to identify leg/arm/head focus
- Added `ataxia_autoParry()` — computes weighted parry with dynamic bias based on enemy class
- Anti-Shikudo still takes priority in auto mode (delegates to `ataxia_shikudoParry()`)
- Fixed `parryy` alias to use `validModes` table instead of missing `ataxia.parrying.modes`
- Updated `slc parry` and `parryy` help text to include auto mode
- Use: `slc parry auto` or `parryy auto`

---

## 2026-03-14 — Fix armour paragon swap skipping pry/insert

### Fixed: `scripts/.../gear_system/002_Armour_Paragons.lua`

**Motivation:** `armour pvp` (and other profile swaps) would show "Paragons already match profile" and skip pry/insert commands. The `needsSwap` optimization compared `state.currentSlots` against the profile, but `currentSlots` was updated optimistically after sending commands without verifying they succeeded in-game, causing false matches on subsequent calls.

**Changes:**
- Removed the unreliable `needsSwap` check from `swap()` — profile swaps now always send pry + insert commands (idempotent in Achaea, no downside)

---

## 2026-03-14 — Align magi offense with xMagi reference logic

### Fixed: `scripts/.../mage/004_Magi_Offense.lua`

**Motivation:** Multiple logic differences from the xMagi reference system were reducing offense effectiveness.

**Changes:**
- Removed `mode ~= "fire"` gate from glaciate check (Priority 3) — fires whenever hypothermia + dual resonance are met
- Removed `mode ~= "fire"` gate from hypothermia cast (Priority 7) — fires whenever frozen + dual resonance are met
- Removed `mode ~= "fire"` gate from freeze check (Priority 10) — fires whenever shivering + mending pressure conditions are met
- Renamed `countBrokenLimbs()` → `countMendingAffs()` — now counts ALL mending-consuming afflictions (broken limbs + burns + calcified torso/skull), not just broken limbs. Magi is a salve pressure class; freeze is stronger when the target's mending balance is already occupied by burns or calcification
- Erode fallback uses `MAINTAIN` argument to preserve resonance levels when stripping shield (previously used `shield`; ERODE without MAINTAIN drops all resonance by 1)

---

## 2026-03-14 — Fix evibe crash + meteorite syntax

### Fixed: `aliases/.../magi_things/003_Embed_Vibes.lua`

**Motivation:** `evibe` alias crashed with "attempt to index field 'magi' (a nil value)" when `ataxia.magi` hadn't been initialized yet (e.g., first use before toggling any vibes).

**Changes:**
- Added `ataxia.magi = ataxia.magi or {}` and `ataxia.magi.vibes = ataxia.magi.vibes or {}` initialization before accessing the table, matching the pattern in `002_Toggle_Vibes.lua`

### Fixed: `scripts/.../mage/004_Magi_Offense.lua`

**Motivation:** Meteorite cast commands had wrong word order (`cast meteorite <type> at <target>`) — correct Achaea syntax is `CAST METEORITE AT <target> <FLAMING|FROZEN|PURE>`.

**Changes:**
- Fixed all 3 meteorite commands in `selectMeteorite()` to use correct syntax: `cast meteorite at <target> <type> 4` (minimum 4s delay)

---

## 2026-03-14 — Fix hardcoded command separator in Locate Relay

### Updated: `scripts/.../locate_relay/001_Locate_System.lua`, `scripts/.../locate_relay/002_Locate_World.lua`

**Motivation:** Bulk locate relay was joining pt commands with hardcoded `::` instead of using the user's configured command separator (`ataxia.settings.separator`), causing commands to be sent as literal text rather than split into separate commands.

**Changes:**
- Replaced all 3 instances of `table.concat(chunk, "::")` with `table.concat(chunk, sep)` where `sep` reads from `ataxia.settings.separator` (defaulting to `";"`)

---

## 2026-03-14 — Auto-configure travel earrings via II + Probe

### Updated: `scripts/.../misc_scripts/020_Setup_Wizard.lua`

**Motivation:** Manually assigning 9+ earrings to locations required running `II earring`, probing each one individually, then typing `ataxia setup earrings <location> <earringID>` for each. Tedious with 11 earrings.

**Changes:**
- Added `ataxia setup earrings auto` command that automatically discovers and assigns all travel earrings
- Sends `II earring` to collect all earring IDs, then probes each sequentially (0.7s delay) to detect destination via "paired with another held by \<Name\>" pattern
- Displays summary of assigned locations with unmatched earring reporting
- Updated earring setup help text to show the auto option
- Follows existing probe queue patterns from itemCatalog/gearAudit (timer-based end detection, temp trigger cleanup, disconnect handler)

---

## 2026-03-14 — Fix SSC spamming class-specific defenses when not that class

### Updated: `deffing/004_Defence_Sorting_-_Cleaner.lua`, `deffing/002_Deffing_Up.lua`, `class_detect/001_Class_Detect_Engine.lua`

**Motivation:** SSC was repeatedly trying to CAST STONESKIN, CHARGESHIELD, DIAMONDSKIN (magi-only spells) even when the player was not a Magi, producing "[Curing]: CAST STONESKIN / You know of no such spell to cast." spam every prompt.

**Root cause:** `systemDefup()`, `defupFailsafe()`, and `classDetect.reapplyDefencePriorities()` sent all defenses from the active defup profile to SSC without checking whether the player's current class can actually use them.

**Changes:**
- Added `isDefenceForCurrentClass(defName)` helper in `004_Defence_Sorting_-_Cleaner.lua` — cross-references defenses against `ataxiaTables.classDefences` class-to-defense mapping, returning false if the defense belongs to a different class. Universal categories (curatives, shared, tattoos, endgame) always pass.
- Filtered `systemDefup()` and `defupFailsafe()` in `002_Deffing_Up.lua` to skip class-mismatched defenses
- Filtered `classDetect.reapplyDefencePriorities()` in `001_Class_Detect_Engine.lua` to skip class-mismatched defenses after curingset switches

---

## 2026-03-14 — Bulk Locate Relay system (locaterRelay_v3 integration)

### Added: `scripts/.../locate_relay/001_Locate_System.lua`, `002_Locate_World.lua`
### Added: `triggers/.../locate_relay/001_QWC_Parse.lua`, `002_QWC_Total.lua`, `003_Farsee_Success.lua`, `004_WhoB_Parse.lua`, `005_WhoB_End.lua`
### Added: `aliases/.../locate_relay/001_Locate_City.lua`, `002_Locate_Enemies.lua`, `003_Locate_World.lua`, `004_Locate_Data.lua`, `005_Locate_Summary.lua`
### Updated: `triggers/.../locate/001_Locate_Logic.lua`, `scripts/_groups.yaml`, `triggers/_groups.yaml`, `aliases/_groups.yaml`

**Motivation:** The existing locate system only handled single-target farsee requests via party tells. There was no way to bulk-scan an entire city, enemy list, or world to find where players are located. The `locaterRelay_v3.mpackage` provided this capability as a standalone package and has been integrated into the main system.

**Changes:**
- Added `LocateSystem` module — city-specific (`locate mhaldor`) and enemy list (`locate enemies`) bulk scanning with `who b` pre-resolution optimization and sequential farsee queue (0.9s delay)
- Added `LocateWorld` module — global scan (`lw`) of all online players, categorized by city and area with room grouping
- Added 5 triggers in `locate_relay` group (disabled by default, enabled during scans): QWC name parser, total count detector, farsee success handler, who-b line parser, who-b end detector
- Added 5 aliases: `locate <city>`, `locate enemies`, `lw` (world scan), `locate data <location>`, `locate summary`
- Results grouped by room and relayed to party chat (`pt`) in chunks of 20
- Added guard to existing `001_Locate_Logic.lua` to skip when bulk scan is running (prevents double-handling of farsee results)
- Registered `locate_relay` trigger group (isActive: false), `Locate Relay` script group, and `Locate Relay` alias group in `_groups.yaml` files

---

## 2026-03-13 — Chat window colors + handler consolidation (v4.5.1)

### Updated: `update_windows/001_showChat.lua`, `gui_stuff/003_Chat_Capture_Things.lua`

**Motivation:** Chat MiniConsole windows showed all text in white/gray because GMCP `Comm.Channel.Text.text` only contains `\27[0;37m` (white) ANSI — no channel-specific colors. The `ansi2decho()` conversion was faithfully producing white text. Additionally, two duplicate GMCP handlers were both firing on `gmcp.Comm.Channel.Start`.

**Changes:**
- Replaced `ansi2decho()` with `ansi2string()` to strip useless white ANSI wrapper
- Added channel color map (`channelColors`) with distinct decho colors per channel type: green (ct/army), yellow (house), purple (order), orange (clans), cyan (party), magenta (tells), teal (market), red (shout/yell), yellow (newbie)
- All chat text now echoed with channel-appropriate color prefix via `decho()`
- Added `muteList` check before echoing to MiniConsoles (muted users now suppressed in chat windows)
- Disabled legacy `ataxiagui_captureChat` handler — `zgui.showChat()` is now the single active handler
- Removed unused `shortName` variable and `getFgColor()`/`getBgColor()` calls

---

## 2026-03-13 — Basher configurability: wand, stormhammer, gem of cloaking, cleanup

### Removed: `basher/004_Guardians_Of_MoG.lua`
### Updated: `basher/001_Bashing_Functions.lua`, `basher/002_Class_Bashing.lua`, `genrunning/003_Engaged_Disengage.lua`
### Added: `aliases/.../configs/013_Wand_Reflection.lua`, `014_Stormhammer.lua`, `015_Gem_Cloaking.lua`

**Motivation:** Several basher features were hardcoded for a specific player (wand ID, stormhammer always-on, gem of cloaking always-on, Guardians of MoG enemy detection). These are now configurable toggles so any user can enable/disable them.

**Changes:**
- Deleted `004_Guardians_Of_MoG.lua` — inactive script with hardcoded enemy player name, no longer needed
- Removed stale `guardianofmogcunts` variable reference from `003_Engaged_Disengage.lua`
- **Wand of Reflection**: New toggle `ataxiaBasher.wandReflection` (default off) + configurable wand ID via `ataxiaBasher.wandId`. Toggle with `abwand`, set ID with `abwand <id>` (e.g., `abwand wand234800`). Emergency HP check now gated behind toggle.
- **Stormhammer**: New toggle `ataxiaBasher.stormhammer` (default off). Toggle with `abshuse`. Magi multi-target stormhammer only fires when enabled and 3+ valid targets present.
- **Gem of Cloaking**: New toggle `ataxiaBasher.gemCloaking` (default off). Toggle with `abgcuse`. Auto "say Tulahuar" in Moghedu on areabash start now gated behind toggle.

---

## 2026-03-13 — Blood Maiden cloak: configurable auto-activation

### Updated: `basher/001_Bashing_Functions.lua`, `triggers/.../769_Blood_Maiden_Cloak.lua`
### Added: `aliases/.../configs/012_Blood_Maiden_Cloak.lua`

**Motivation:** Blood Maiden cloak is an artefact not everyone owns. The old logic was always-on, counted all denizens (not just targets), had hardcoded Moghedu-specific rules, and didn't model the 3-minute active window correctly.

**Changes:**
- New toggle `ataxiaBasher.bloodMaiden` (default off) — toggle with `bmc` alias
- Trigger now gated on the toggle — won't set `bloodshieldReady` if disabled
- Mob count now only counts mobs in the area's basher target list (not all denizens)
- Removed Moghedu keeper-specific logic — simplified to: 4+ targetable mobs OR boss
- Boss list is configurable via `ataxiaBasher.bloodMaidenBosses` (hash table, persisted)
- Default bosses: Rhuzios, Underlord Seroth, Underlord Dreyvos
- After first activation, tracks a 3-minute active window (`ataxiaTemp.bloodshieldActive`) — cloak can be freely re-activated during this window without needing a new "ready" signal

---

## 2026-03-13 — World Tree area basher restrictions

### Updated: `basher/001_Bashing_Functions.lua`

**Motivation:** The Fathomless Expanse of the World Tree area has mobs that hit hard (triggering false danger/flee) and does not allow Culling Blade. Both needed area-specific suppression.

**Changes:**
- Culling Blade (`reap`) is now skipped when `gmcp.Room.Info.area` is "the Fathomless Expanse of the World Tree"
- Damage-rate flee ("Extreme incoming damage rate") and HP-threshold flee are disabled in the World Tree area — shield and wait checks still apply

---

## 2026-03-13 — Blademaster Ice Path (Quad-Prep) Update

### Updated: `blademaster/005_CC_BM_Ice.lua`

**Motivation:** Refined the quad-prep (`bmdq`) strategy to follow the optimal ice path kill route. Salve curing applies to the left leg first, so always targeting the right leg keeps it broken/mangled longer.

**Changes:**
- Added **flamefist phase** between leg prep and arm break — negates rebounding before the break sequence
- Leg break now always uses **legslash RIGHT** (not balanced) — right stays broken longer since curing restores left first
- Mangle phase now always uses **legslash RIGHT + sternum** — removed the "right to 200% then switch to left" logic
- New state flag `flamefistDone` resets on target change and full reset
- Flamefist pierces rebounding but still razes shield if shielded

**New 6-phase quad-prep order:** arm_prep → leg_prep → flamefist → arm_break → leg_break (RIGHT) → mangle (RIGHT + sternum)

---

## 2026-03-13 — Make system configurable for multiple users

### New: WEAPONLIST auto-detection, configurable weapons/mount/artefacts/earrings

**Motivation:** The system was built for a single character (Leviticus) with hardcoded weapon IDs, mount name, artefact IDs, and earring IDs across ~30 files. This makes the system usable by any player.

**New file:** `misc_scripts/023_Weapon_Detect.lua`
- `ataxia.scanWeapons()` — sends WEAPONLIST, parses output with temp triggers, groups weapons by type
- Auto-suggests slot assignments (DWC weapon1/2, DWB mstar1/2, staff/staff2, etc.)
- Sorts by damage (best weapon = primary slot)
- `ataxia.confirmWeapons()` saves to `ataxia.settings.weapons`
- `ataxia.swapWeaponSlots(s1, s2)` swaps pending assignments before confirming
- `ataxia.setWeaponSlotPending(slot, id)` overrides a slot before confirming

**New file:** `misc_scripts/022_User_Config.lua`
- Centralizes `ataxia.getWeapon(slot)`, `ataxia.getMount()`, `ataxia.getArtefact(slot)`, `ataxia.getEarring(location)`
- All helpers read from `ataxia.settings` at call time (no caching), so Setup Wizard changes take effect immediately
- `ataxia_initUserConfig()` called from `ataxiaCheckForMissing()` on every load
- Added `staff2` slot for Monk/Shikudo staff (separate from Magi `staff`)

**Extended:** `001_Save_Load_Settings.lua`
- `ataxia_defaultSettings()` now initializes `ataxia.settings.weapons` and `ataxia.settings.user` subtables

**Extended:** `020_Setup_Wizard.lua`
- `ataxia setup weapons scan` — auto-detect from WEAPONLIST
- `ataxia setup weapons confirm` — save scan results
- `ataxia setup weapons swap <s1> <s2>` — swap slot assignments
- `ataxia setup weapons set <slot> <id>` — manually set a slot
- `ataxia setup mount <name>` — set mount/companion name
- `ataxia setup artefacts <slot> <id>` — set pendant/bracelet/belt/ring IDs
- `ataxia setup earrings <location> <id>` — set travel earring locations
- `ataxia setup status` now shows mount, artefacts, and expanded weapon list

**Replaced hardcoded weapon IDs** (~30 files):
- `genrunning/003_Engaged_Disengage.lua` — 8 weapon IDs + removed dead `ataxiaTemp.me == "Leviticus"` check
- `dwc_runie/002-007` — scimitar IDs → `ataxia.getWeapon("weapon1"/"weapon2")`
- `dwc/001-002, 002_Group_Lock` — config defaults read from `ataxia.settings.weapons`
- `dwb_runie/001` — config defaults
- `023_LIMB_PREP, 024_RAMPAGE` — wield/wipe/envenom commands
- `i_snb/004_RAMPAGE, 005_LIMB_PREP` — same pattern
- `login/001_Login_Function.lua` — all weapon wielding on login
- `aliases/149_Empower_Weapons.lua` — all 13 weapon variables

**Replaced hardcoded mount name** (5 files):
- "impastus" → `ataxia.getMount()` in 038_TELL_IMPASTUS, 041_DRAGONFORM, 014_Urn, 015_FLYING, 134_NO_STEED_NEED

**Replaced hardcoded artefact IDs** (3 files):
- pendant/bracelet/belt → `ataxia.getArtefact()` in 006_GIVE_ARTIES, 007_WEAR_ARTIES
- ring → `ataxia.getArtefact("ring")` in 013_ICEWALL

**Replaced hardcoded earring IDs** (1 file):
- 9 location→ID pairs → `ataxia.getEarring()` in 080_HELP_Earring.lua
- Refactored from 9 if-then blocks to lookup table + helper function

**Fixed Monk vs Magi staff distinction:**
- `staff` slot = Magi primary staff, `staff2` slot = Monk/Shikudo staff
- Updated `003_Engaged_Disengage.lua` Monk section to use `ataxia.getWeapon("staff2")`
- Updated `login/001_Login_Function.lua` Shikudo wield to use `ataxia.getWeapon("staff2")`

---

## 2026-03-13 — v4.3.5: Fix sysupdate self-update system

**File:** `src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/021_Auto_Update.lua`

**Root cause:** The sysupdate flow called `uninstallPackage("Levi_Ataxia")` from within the package's own YAML-registered event handler. When the package was uninstalled, the `sysDownloadDone` handler was destroyed, making the subsequent `tempTimer` → `installPackage` flow unreliable.

**Fix:**
- Replaced YAML `eventHandlers` with `registerAnonymousEventHandler` — these survive package uninstall since they're registered at the Lua level
- Captured `packageFile` path to a local variable before uninstalling, so the closure doesn't depend on `ataxia.updater` surviving
- Separated `os.remove` into its own 1s timer after `installPackage` to prevent deleting the file before Mudlet finishes reading it
- Added handler cleanup on script reload to prevent duplicate handlers accumulating
- Added status echo at each step for visibility

---

## 2026-03-13 — Serpent: Pharaus V2 offense rewrite

### Major Rewrite: Attack execution, venom selection, and impulse delivery

**File:** `src_new/scripts/levi_ataxia/levi/levi_scripts/serpent/002_Serpent_Offense.lua`

**Motivation:** Ported 9+ improvements from the Pharaus V2 reference implementation to improve serpent lock reliability, reduce wasted EQ, and add new kill pressure mechanics.

**Changes:**

1. **Per-aff fratricide 3s cooldown** — `lastImpulsed[aff] = os.clock()` timestamps + `recordImpulse()` called on every impulse send. Two-pass `selectImpulse(excludeAff)` respects cooldown on Pass 1, ignores on Pass 2 (never returns nil). Replaces hardcoded "confusion" and `selectFallbackSuggestion()`.

2. **canUseSecondary / getPostAction() collision prevention** — Snap/shrug no longer collide with ekanelia impulse delivery. `getPostAction()` returns `(postAction, canUseSecondary)`. Overridden to true when `impatienceConditionsMet()`, `impatienceConditionsRelapse()`, or `kalmiaEkaneliaMet()`.

3. **Kalmia ekanelia during flay** — When `kalmiaEkaneliaMet()` and no eqAction, chains impulse on eq alongside flay on bal (dual-balance attack). Flay venom optimized for kalmia ekanelia context.

4. **Kalmia ekanelia as priority impulse** — Dedicated P3 check before normal impulse. Fires when clumsiness+weariness present, asthma absent, impulse eligible.

5. **Impatience delivery with confidence gates** — `canAttemptImpatience()` (4s cooldown, stamped from confirm trigger) + `impatienceConditionsMet()` (requires third condition: fratricide/hypochondria/scytherus/slickness) + `impatienceConditionsRelapse()` (relaxed: asthma+weariness sufficient). Replaces `serpent.shouldDeliverImpatience()`.

6. **Focus lock push** — `focusLockReady()` fires monkshood impulse when fratricide + 4 mentals + focus down + impatience + asthma + weariness. Overwhelms mental cure capacity.

7. **Enhanced lock_reinforce burst** — Impulse priority: scytherus ekanelia (addiction+nausea → camus spike) → voyria (anorexia+impatience → confusion+disrupted). Sets `voyriaSent`. DStab sequence: paralysis → voyria → vardrax+euphorbia → curare+recklessness.

8. **Unified pickVenom(exclude)** — Priority-based second venom selection with class-aware clumsiness (`wantClumsiness()`), lightwall darkshade (`hasLightwall()`), and slike gate (`slikeGateMet()`). All strategy branches use this instead of strategy-specific `buildSecondVenom*()`.

9. **Behead on prone truelock** — P2 check: truelock + prone → behead (scimitar) before execute.

10. **Rebounding/Shielded globals** — Shield/rebounding detection now also checks `Rebounding` and `Shielded` Ataxia globals (most reliable source).

11. **lastImpulsed cleared on target change** — Prevents stale cooldowns from previous target bleeding into new fight.

**Dead code removed:** `buildSecondVenom()`, `buildSecondVenomGinseng()`, `buildSecondVenomRelapse()`, `serpent.canDeliverAnorexia()`, `serpent.shouldDeliverImpatience()`, `serpent.checkBloodrootExploit()`

### Bug fixes (post-verification)

12. **lastImpatienceAttempt reset on target change** — Impatience cooldown (2.5s) was persisting across target switches, delaying first monkshood attempt on new targets. Now reset to 0 alongside `lastImpulsed = {}`.

13. **complete_softlock requires asthma anchor** — `determineStrategy()` was entering `complete_softlock` with just slickness+anorexia (no asthma), which has no lock value since both are salve/eat cures. Now requires asthma as mandatory anchor before counting anorexia/slickness pieces.

14. **checkImpulseEligible() gecko reset logic** — Was blindly short-circuiting to `true` when `geckoStripAttempted` was set, even if target re-applied quicksilver. Now checks sileris/fangbarrier first and resets `geckoStripAttempted`/`postGeckoLockdown` if defenses are back up, preventing wasted impulse/bite into active fangbarrier.

---

## 2026-03-12 — Serpent: track fangbarrier/sileris strip on flay shield/rebounding

### Bug Fix: Missing flay shield/rebounding patterns in sileris strip trigger

**File:** `src_new/triggers/.../706_Flayed_Sileris.lua`

**Problem:** When flaying shield or rebounding, fangbarrier/sileris is also stripped as a game mechanic side effect, but the trigger was missing the "You flay away X's shield defence" and "You flay away X's aura of rebounding defence" patterns. This meant `checkImpulseEligible()` could still see stale fangbarrier/sileris tracking after a flay.

**Fix:** Added two new regex patterns to trigger 706 to catch flay shield and flay rebounding messages, ensuring `erAff("fangbarrier")` and `erAff("sileris")` fire correctly.

---

## 2026-03-12 — Locate system: farsee + faemirror companion count

### Enhancement: Use farsee with faemirror for locate responses

**Files:** `src_new/triggers/.../locate/001_Locate_Logic.lua`, `003_Party_Locate.lua`, `005_Locate3.lua`, `004_Party_Locate_Scry.lua` (disabled)

All locate triggers now use `farsee` instead of `scry for`. The locate response waits for the faemirror result before replying, including companion count: `[alone]`, `[1 with them]`, `[3 with them]`, etc. Falls back to no companion info after 2s timeout if no faemirror is equipped. Scry bowl trigger disabled (no longer needed).

---

## 2026-03-12 — Fix nil table errors in Room Update and Ally/Enemy trigger

### Bug Fix: Defensive nil checks for uninitialized tables

**Files:** `src_new/scripts/.../update_stuff/002_ataxia_Room_Update.lua`, `src_new/triggers/.../allies_enemies/008_Ally_Enemy_added.lua`

**Problem:** Two race conditions caused `bad argument #1 to 'insert' (table expected, got nil)`:
1. `ataxiaBasher_path` used in Room Update flee logic before basher initialization
2. `ataxiaTemp.allies`/`ataxiaTemp.enemies` used before ALLIES/ENEMIES list trigger populates them

**Fix:** Added nil guards — `ataxiaBasher_path` check before `table.insert`, and `ataxiaTemp[key] = ataxiaTemp[key] or {}` before ally/enemy insertion.

---

## 2026-03-12 — Basher attack gate: block attacks during disabling afflictions

### Enhancement: Expanded basher affliction checks

**Files:** `src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua`

The basher attack send gate now checks for many more disabling afflictions before sending attacks. Previously only checked paralysis, aeon, and peace. Now also blocks on: transfixation, webbed, impaled, constricted, deepsleep, entangled, unconsciousness, and snared. This prevents wasted commands and queue spam when the character can't act.

---

## 2026-03-12 — Auto-flee on PvP attack while bashing

### New Feature: Basher attack detection

**Files:** `src_new/scripts/levi_ataxia/levi/ataxia/genrunning/001_Bashing_API.lua`, `src_new/scripts/levi_ataxia/levi/ataxia/016_Targeting_Functions.lua`

When the basher is enabled and the class detect system fires (`"attacker class detected"` event), the system now automatically:
1. Clears all queues (`cq all`)
2. Turns off auto bash rotation
3. Disables the basher
4. Navigates to Mhaldor via the mapper

Also: `switchTarget` now skips all PvP combat state resets (V3 states, affliction tracking, limb counters, class-specific resets) when bashing is enabled, eliminating the "[V3] States reset" spam during PvE.

---

## 2026-03-12 — Fix: zData hunting database nil errors

### Bug Fix: `mergeLoad` shallow merge wiping functions

**Files:** `src_new/scripts/levi_ataxia/levi/ataxia/001_Save_Load_Settings.lua`

**Problem:** `ataxia.data.db.addChar` and `ataxia.data.db.zoneAdd` were nil at runtime, causing errors on crit hits and zone changes. Both functions are defined in `001_Experience_Database.lua` during script load, but were wiped when `ataxia_loadSettings()` ran on `sysLoadEvent`.

**Root cause:** The `mergeLoad()` helper only merged 1 level deep. When loading saved `ataxia` data from disk, it correctly merged sub-keys of `ataxia.data`, but for nested tables like `ataxia.data.db`, it replaced the entire table with the saved (function-less) copy. Since `table.save` can't serialize Lua functions, the saved `ataxia.data.db` was a plain data table with no `addChar`, `zoneAdd`, `showData`, etc.

**Fix:** Made `mergeLoad` recursive via an inner `deepMerge` function. Now when both the loaded value and existing value are tables at any depth, it merges into the existing table (preserving functions) instead of replacing it.

---

## 2026-03-12 — Item Catalog System

### New Feature: Item Catalog (`catalog`)
A comprehensive inventory cataloging system that scans artefacts, talismans, promo items, and special equipment, cross-referencing each against a knowledge base to identify what every item does.

**Commands:**
| Command | Purpose |
|---------|---------|
| `catalog scan` | Full scan (ARTEFACT LIST + TALISMAN LIST + auto-probe unknowns) |
| `catalog quick` | Quick scan (ARTEFACT LIST + TALISMAN LIST only, no probing) |
| `catalog stop` | Abort an in-progress scan |
| `catalog show [artefacts\|talismans\|promo\|unknown]` | Display cataloged items by type/category |
| `catalog search <keyword>` | Search by name, power, effect, set, or category |
| `catalog info <id>` | Full details for a specific item |
| `catalog note <id> <text>` | Add/update a manual annotation |
| `catalog unknowns` | List unidentified items needing review |
| `catalog save` / `catalog load` | Manual save/load |
| `catalog help` | Command reference |

**Architecture:**
- Knowledge base (`itemCatalog.kb`) covers 200+ artefacts and all known talisman sets with effects, categories, and tiers
- Talisman keyword lookup (`itemCatalog.talismanKB`) maps TALISMAN LIST keywords to effects
- Scans use `tempRegexTrigger` for ARTEFACT LIST and TALISMAN LIST parsing with MORE pagination handling
- Auto-probes unknown items (0.7s delay between probes) and flags them for manual review
- Persistence follows the Legend Deck Manager pattern: `table.save/load` to `getMudletHomeDir()/itemcatalog` with `_ataxia_backup` fallback
- Skip patterns exclude boring consumables (vials, pipes)

### Files added
- `src_new/scripts/.../item_catalog/001_Item_Catalog_Init.lua` — Namespace, config, state machine, echo helpers, skip patterns
- `src_new/scripts/.../item_catalog/002_Item_Catalog_DB.lua` — Knowledge base (~400 lines, 200+ artefacts, all talisman sets)
- `src_new/scripts/.../item_catalog/003_Item_Catalog_Functions.lua` — Scan orchestration, KB matching, display, search, command dispatch
- `src_new/scripts/.../item_catalog/004_Item_Catalog_Save_Load.lua` — Persistence (save/load/backup)
- `src_new/aliases/.../item_catalog/001_Item_Catalog.lua` — `catalog` alias dispatcher

### Files changed
- `src_new/scripts/.../ataxia/001_Save_Load_Settings.lua` — Added `itemCatalog.save()` to `ataxia_saveSettings()` and `itemCatalog.load()` to `ataxia_loadSettings()`

---

## 2026-03-11 — Fix Shalestorm+Scintilla Priority + Burns Double-Counting

### Bug Fixes
- **CRITICAL: Scintilla blocking conflagrate/destroy**: Priority 5 (shalestorm+scintilla) fired every balance, preventing the burning path from ever reaching conflagrate. Burns sat at 5/5 with "CAN BE DESTROYED" but destroy never fired. Fixed by gating scintilla: skip when burns >= 5 (capped) or when conflagrate conditions are met (burns >= 2 + fire >= 2), allowing the burning path to select conflagrate properly.
- **CRITICAL: Burns double/triple counting**: Three pairs of duplicate triggers fired on the same game text, causing burns to increment 2-4x per event:
  - Scintilla spark: `staffcast/004_Immolation` incorrectly added +1 burn on spark (should be +0, ignition 4s later is +1). Deactivated — `010_Scintilla_Spark` is correct.
  - Scintilla ignition: `staffcast/003_Fire_Sco` duplicated `011_Scintilla_Ignition`, both adding +1 = +2 total. Deactivated `003_Fire_Sco`.
  - Emanation fire: `magi_offense_tracking/004_Emanation_Fire` duplicated `enamation/001_Fire_Emanation`, both adding +2 = +4 total. Deactivated `004_Emanation_Fire`.
- **Efreeti burns uncapped**: `025_Burns_Tracking` efreeti increment had no `math.min(..., 5)` cap, allowing burns to exceed 5. Fixed.
- **Misleading burns echo**: `021_Spell_Outcomes` displayed burns counter for all spell patterns (including magma, bombard, mudslide which don't affect burns). Now only shows for fulminate and firelash.
- **Mode echo spam**: `[Magi] Mode set to: salve` echoed on every `zz` keypress even when mode hadn't changed. Now only echoes when mode actually changes.

### Files changed
- `src_new/scripts/.../mage/004_Magi_Offense.lua` — Added burns gates to Priority 5 scintilla; `setMode()` only echoes on actual mode change
- `src_new/triggers/.../staffcast/003_Fire_Sco.lua` — **DELETED** (duplicate of 011_Scintilla_Ignition)
- `src_new/triggers/.../staffcast/004_Immolation.lua` — **DELETED** (duplicate of 010_Scintilla_Spark)
- `src_new/triggers/.../magi_offense_tracking/004_Emanation_Fire.lua` — **DELETED** (duplicate of enamation/001_Fire_Emanation)
- `src_new/triggers/.../general/025_Burns_Tracking.lua` — Added math.min cap to efreeti burns
- `src_new/triggers/.../general/021_Spell_Outcomes.lua` — Burns counter only shows for burn-related spells
- `src_new/scripts/.../limb_management/004_Magi-Specific.lua` — `magi_addBurns()` now syncs from `magi.offense.state.burns` (authoritative) instead of independently incrementing; `magi_checkDestroy()`/`magi_setDestroy()` read from `magi.offense.state.burns` via new `magi_getBurns()` helper

---

## 2026-03-11 — Armour/Paragon System Fixes + Gear Audit README

### Bug Fixes
- **Fixed morph command**: Was sending invalid `armour morph <type>`, now sends correct game command `MORPHARMOUR armour INTO <type>` (`002_Armour_Paragons.lua`)
- **Fixed armour type "(unknown)"**: Auto-detects armour type from current class on init when `currentArmourType` is nil

### Enhancements
- **Paragon type lookup table**: Added `PARAGON_TYPES` with all 24 paragon types and effects. `registerParagon()` now resolves raw game names (e.g., "an aeneaous paragon") to clean display names (e.g., "aeneaous (absorption)"). Stale names re-resolved automatically on load.
- **New `armour types` command**: Shows all 24 paragon types grouped by category (resistance, morphing, combat, regen, storage) with effects
- **README: Gear & Equipment section**: Added Gear Audit (`gearaudit`) and Armour/Paragon (`armour`) documentation to GitHub README

### Files changed
- `src_new/scripts/.../gear_system/002_Armour_Paragons.lua` — PARAGON_TYPES table, resolveParagonName(), morph fix, auto-detect, `types` command
- `CLAUDE.md` — Updated armour section with morph fix, paragon lookup, types command
- `README.md` — Added Gear & Equipment section with gearaudit + armour subsections

---

## 2026-03-11 — Target Priority Queue + Stormhammer Enhancement

### New Feature: Target Priority Queue (`tprio` namespace)
Ordered kill list for group PvP coordination, inspired by Tabethys's Target Priority package. Provides single-key target cycling, party synchronization, and presence-aware auto-targeting.

**New files**:
- `scripts/.../mage/006_Target_Priority.lua` — Core system: `tprio.add()`, `tprio.next()`, `tprio.previous()`, `tprio.first()`, `tprio.switchTo()`, `tprio.autoTarget()`, `tprio.syncEnemies()`, `tprio.pt()`
- `aliases/.../targetting/004_Target_Priority.lua` — `tgh Name1 Name2 Name3` sets priority list
- `aliases/.../targetting/005-011` — `tn` (next), `tb` (back), `tf` (first), `tpt` (party announce), `tpr` (reset), `tps` (show), `tpe` (enemy sync)
- `triggers/.../magi_offense_tracking/016_Party_Target_Priority.lua` — Auto-parses `(Party): X says, "Targets: A, B, C."` to set priority list

**Key features**:
- Position-resync on cycling (handles manual target changes gracefully)
- GMCP room player tracking with incremental add/remove
- Full combat state reset on switch (V3 affs, limbs, burns, balances)
- Ghost/soul filtering from GMCP data

### Enhancement: Stormhammer Mode System
Added runtime mode switching to `magi.storm` with 3 modes:

| Mode | Behavior |
|------|----------|
| `city` (default) | Original — targets enemies from same city as primary target |
| `all` | All enemies in room regardless of city |
| `priority` | Uses `tprio.list` ordering, then fills with remaining enemies |

**Changes to `005_Stormhammer_Targeting.lua`**:
- Added `magi.storm.mode`, `magi.storm.setMode()`, `magi.storm.getMode()`
- Primary target (`target`) always guaranteed in slot 1
- Priority mode iterates `tprio.list` in order for intelligent target selection
- `mm storm` alias cycles through modes (city → all → priority → city)

---

## 2026-03-11 — Stormhammer fires incorrectly after retarget + event name mismatch

### Bug Fix: Scintilla double-counting burns
**Root cause**: `005_Immolation_Staff.lua` added +1 burn via 4s timer on scintilla cast, AND `011_Scintilla_Ignition.lua` added +1 burn when the spark ignited — resulting in +2 burns per scintilla. With shalestorm causing near-instant ignition, both fired giving 2 burns instead of 1.

**Fix**: Removed the burn increment from `005_Immolation_Staff.lua` — the ignition trigger (011) already handles burn tracking when the spark actually ignites.

### Bug Fix: Stormhammer firing at full HP targets
**Root cause**: `targetHealth` (global, set by assess trigger) was never cleared on target switch, death, starburst, or manual reset. `magi.offense.getTargetHP()` checks `targetHealth` before `php`, so stale assess data from a previous target caused stormhammer to fire at HP ≤25% when the new target was actually at 91%+.

**Files changed**:
- `016_Targeting_Functions.lua`: Added `targetHealth = nil` on target switch (next to `php = 100`)
- `016_RESET.lua` (alias): Added `targetHealth = nil` on manual reset
- `401_Target_Has_Died.lua` (trigger): Added `targetHealth = nil` on target death
- `405_Starburst!.lua` (trigger): Added `targetHealth = nil` on target starburst

### Bug Fix: Magi offense and V3 tracker not resetting on target switch
**Root cause**: Event name mismatch — `switchTarget()` raises `"changed target"` but both handlers listened for `"ataxia target changed"` (never raised). This meant `magi.offense.reset()` and `resetStatesV3()` never fired on target change, so burns, shalestorm, scintillaSpark, and V3 affliction probabilities persisted across targets.

**Files changed**:
- `004_Magi_Offense.lua` (line 710): Changed event listener from `"ataxia target changed"` to `"changed target"`
- `007_Branching_State_Tracker.lua` (line 763): Changed event listener from `"ataxia target changed"` to `"changed target"`

---

## 2026-03-11 — Armour & Paragon Management System

### Feature
Configurable armour paragon profile system replacing 8 hardcoded aliases. Supports named profiles with paragon slots (1-3), trait selections, and armour morphing. Auto-swaps between bash and PvP profiles when basher enables/disables. Auto-detects owned paragons via `ii paragon` trigger and current embrasure state via `probe armour` trigger.

### New Files
- **`gear_system/002_Armour_Paragons.lua` (script)**: `ataxia.armour` namespace — profiles, swap logic, morph cooldowns, basher event hooks, persistence
- **`gear_system/002_Armour_Paragons.lua` (alias)**: `armour` command dispatcher (`^armour\s*(.*)$`)
- **`gear_system/001_Paragon_Inventory.lua` (trigger)**: Parses `ii paragon` inventory lines
- **`gear_system/002_Armour_Probe.lua` (trigger)**: Parses `probe armour` embrasure lines

### Deactivated Legacy Aliases
090_Armour_Paragons (`barmp`), 096_Mage_PvE (`magepve`), 097_Serpent_PvE (`serppve`), 098_Shikudo_Pve (`stickpve`), 099_Pariah_PvE (`pariahpve`), 100_BM_Pve_Traits (`bmpve`), 101_stickpvp, 102_Class_PvP (`armourpvp`) — all replaced by `armour <profilename>`

### New Commands
| Command | Purpose |
|---------|---------|
| `armour` | Show all profiles and auto-swap status |
| `armour <name>` | Swap to a named profile |
| `armour add <name>` | Create a new profile |
| `armour remove <name>` | Delete a profile |
| `armour set <n> slot1/2/3 <id>` | Set paragon in slot |
| `armour set <n> traits <...>` | Set trait list |
| `armour set <n> armourtype <t>` | Set morph target (type/auto/none) |
| `armour auto on/off` | Toggle auto-swap on basher enable/disable |
| `armour bash <name>` | Set which profile to use for bashing |
| `armour pvp <name>` | Set which profile to use for PvP |
| `armour morph <type/auto>` | Manually morph armour now |
| `armour scan` | Auto-detect paragons + current embrasures |
| `armour paragons` | Show known paragons |

### Seeded Default Profiles
bash, pvp, stickpvp, magepve, serppve, stickpve, pariahpve, bmpve — matching all legacy alias configurations

---

## 2026-03-11 — Gear Audit BiS (Best in Slot) PvE Analysis

### Feature
Added PvE damage scoring and Best-in-Slot analysis to the gear audit system. Scores each gear item based on offensive stats (damage %, celerity, burst, resistance penetration) and defensive stats (HP, regen, damage reduction), identifies BiS per set per slot AND overall BiS per slot, and generates scrap recommendations with copy-paste `GEAR SCRAP` commands.

### Changes
- **`gear_system/001_Gear_Audit.lua` — config**: Added `bisWeights` (10 stat weights + conditional multipliers) and `scrapThreshold` (0.5 = scrap below 50% of BiS)
- **`gear_system/001_Gear_Audit.lua` — scoreEffect()**: Extracts structured numeric stats from raw effect text (addDmgPct, celerity, burstPct, ignorePct, hpPct, etc. + condition detection)
- **`gear_system/001_Gear_Audit.lua` — calculateScore()**: Applies weighted scoring with burst normalization (per-attack effective value based on cooldown) and conditional multipliers (0.5x location, 0.7x battlerage)
- **`gear_system/001_Gear_Audit.lua` — getBisBySlot()**: Groups items by slot, sorts by score, assigns ranks
- **`gear_system/001_Gear_Audit.lua` — getScrapRecommendations()**: Per-set threshold comparison
- **`gear_system/001_Gear_Audit.lua` — displayBis/displayScore/displayScrap**: Color-coded display with per-set and overall BiS views, detailed score breakdowns, and ready-to-use scrap commands
- **`gear_system/001_Gear_Audit.lua` — command handler**: New subcommands: `bis`, `bis <slot>`, `score <id>`, `scrap`, `scrap <set>`

### New Commands
| Command | Purpose |
|---------|---------|
| `gearaudit bis` | Full PvE BiS analysis (all slots) |
| `gearaudit bis <slot>` | BiS analysis for a specific slot |
| `gearaudit score <id>` | Detailed score breakdown for a gear item |
| `gearaudit scrap` | Scrap recommendations + GEAR SCRAP commands |
| `gearaudit scrap <set>` | Scrap recommendations for a specific set |

---

## 2026-03-11 — Fix basher not attacking after F1 engagement

### Issue
After the Mar 10 refactor of `ataxiaBasher_attack()` into `ataxiaBasher_dangerLevel()`, the basher would engage correctly (find targets, pause mapper) but never send attack commands.

### Root Cause
The refactor removed the `if ataxiaTemp.bashFlee == nil then ataxiaTemp.bashFlee = false end` initialization from the old `ataxiaBasher_attack()`. Without it, `bashFlee` stays `nil` on fresh login. The final guard in `ataxiaBasher_assembleAttack()` used strict equality (`bashFlee == false`) which fails for `nil` since `nil == false` is `false` in Lua.

### Fix
- **`basher/001_Bashing_Functions.lua` — line 339**: Changed `ataxiaTemp.bashFlee == false` to `not ataxiaTemp.bashFlee` (truthy check), matching how all 15+ other callsites already check this variable.

---

## 2026-03-10 — Magi shalestorm+scintilla automation + configurable utility prefixes

### Feature
Automated scintilla casting when shalestorm is active (guarantees spark ignition via shalestorm's automatic damage). Added configurable artefact utility abilities (arachnideye, webbomb) as free-action prefixes.

### Changes
- **`004_Magi_Offense.lua` — selectSpell()**: New priority 5 — when shalestorm is active + torso not calcified + no pending spark + earth>=2, auto-cast `staffcast scintilla`. Works in ALL modes (fire/water/lock/salve/group). Existing lock/salve scintilla branches preserved unchanged
- **`004_Magi_Offense.lua` — sendAttack()**: Added optional utility prefix before `stand::wield`. `useArachnideye` prepends `arachnideye trample <target>` (gated: target not prone). `useWebbomb` prepends `webbomb <target>` (gated: target not entangled). Both default OFF
- **`004_Magi_Offense.lua` — config**: Added `useArachnideye` and `useWebbomb` boolean toggles
- **`004_Magi_Offense.lua` — status()**: Shows arachnideye/webbomb toggle state
- **`004_Magi_Offense.lua` — state**: Added `scintillaSpark`/`scintillaTimer` defaults + reset cleanup
- **`006_Magi_Mode.lua` — mm alias**: Added `mm arach`/`mm web` toggle commands, updated help text

---

## 2026-03-10 — Delete legacy Magi triggers, fix audit gaps

### Issue
16 deactivated legacy Magi triggers were cluttering the codebase. ExpertDiagnoser audit found V3 cure table gaps (6 missing afflictions), missing waking trigger, Slough not clearing weariness, misnamed freeze trigger, and erode line delta too narrow.

### Fix
- **Deleted 16 legacy files**: `general/006-008` (shalestorm), `general/011,013,016,017,018` (spell outcomes), `general/021_Dehydrate_-_Frozen` (misnamed freeze), `destroy-related/001-006` (all), `elementals/001_Efreeti`
- **Removed empty directories**: `destroy-related/`, `elementals/`
- **V3 cure tables** (`007_Branching_State_Tracker.lua`, `008_V3_Integration.lua`): Added `fulminated` (goldenseal), `guilt`+`horror` (lobelia), `pyre` (bellwort), `rebbies` (kelp), `unweavingspirit` (smoke), `stuttering` (focus)
- **`passive_active/021_Waking_Up.lua`** — New: detects target waking from sleep (yawn + gasp patterns), calls `erAff("sleep")`
- **`passive_active/016_Slough_(Fire_Lord).lua`** — Added `erAff("weariness")` before passive cure call
- **`general/021_Freeze.lua`** — New: renamed from misnamed "Dehydrate - Frozen", added target validation
- **`magi_offense_tracking/015_Erode.lua`** — `conditonLineDelta` 1→3 (matches reference, allows intervening combat lines)

---

## 2026-03-10 — Deactivate duplicate shalestorm triggers

### Issue
Three old shalestorm triggers (006, 007, 008 in `general/`) wrote to `magi.shalestorm` which nothing reads — the offense script reads `magi.offense.state.shalestorm` from the new unified `023_Shalestorm.lua`. Both sets fired on the same patterns, causing double `erAff("shield")` calls and dead writes.

### Fix
- **`general/006_Shalestorm_down.lua`** — Deactivated (superseded by 023)
- **`general/007_Shalestorm_shield.lua`** — Deactivated (superseded by 023)
- **`general/008_Shalestorm_up.lua`** — Deactivated (superseded by 023)

---

## 2026-03-10 — Erode trigger + missing class cure triggers + Fitness V3

### Issue
Erode spell had no trigger to parse which defense was stripped beyond shield (rebounding, blindness, etc.). Three class-specific cure abilities (Continuation/Monk, Priest Healing, Sylvan Root) had no tracking triggers. Fitness trigger (007) lacked V3 integration and didn't set `targetIshere`.

### Fix
- **`magi_offense_tracking/015_Erode.lua`** — New multiline trigger: parses eroded defense name from followup line, calls `erAff()` for shield + stripped defense (rebounding, blindness, deafness, caloric, insomnia, cloak, speed), party relay
- **`passive_active/018_Continuation_(Monk).lua`** — New: detects Monk continuation (`gives a great shout of exertion`), clears weariness + 1 random via V3
- **`passive_active/019_Priest_Healing.lua`** — New: detects Priest healing projection, clears voyria if present else 1 random via V3
- **`passive_active/020_Sylvan_Root.lua`** — New: detects Sylvan root (`stands suddenly upright, rooted to the earth`), clears haemophilia + 1 random via V3
- **`passive_active/007_Fitness_(Knights_Monk_BM).lua`** — Added `collapseAffAbsentV3("asthma")`/`collapseAffAbsentV3("weariness")` for V3 branch collapse, added `targetIshere = true`

---

## 2026-03-10 — Magi Trigger Audit: Fix duplicates, add missing triggers

### Issue
5 legacy triggers (011_Mudslide, 013_Fulminate, 016_Bombard, 017_Magma, 018_Firelash) fired on the same regex patterns as 021_Spell_Outcomes.lua, causing double burns counting, double affliction applications, and double scalded tracking. Additionally, 021 had bugs: dehydrate incorrectly incremented burns on cast (before outcome known), fulminate lacked smart chain logic, bombard missed clumsiness, mudslide missed slickness, firelash missed burning.

### Fix
- **Rewrote 021_Spell_Outcomes.lua** with merged logic from all 5 legacy triggers
- **Deactivated 5 legacy duplicates** (`isActive: 'no'`): 011, 013, 016, 017, 018
- **Created 7 new triggers** in `magi_offense_tracking/` (008-014): Transfix, Transfix Unblind, Scintilla Spark/Ignition, Staffcast Lightning/Freeze, Deepfreeze

### Changes
- **`general/021_Spell_Outcomes.lua`** — Full rewrite with merged logic: fulminate smart chain (fulminated→epilepsy→paralysis), dehydrate no longer increments burns on cast, bombard tracks clumsiness, mudslide tracks slickness+prone, firelash tracks burning+burns, magma has 20s scalded timer
- **`general/011_Mudslide.lua`** — Deactivated (superseded by 021)
- **`general/013_Fulminate.lua`** — Deactivated (smart chain merged into 021)
- **`general/016_Bombard.lua`** — Deactivated (clumsiness merged into 021)
- **`general/017_Magma.lua`** — Deactivated (scalded+timer merged into 021)
- **`general/018_Firelash.lua`** — Deactivated (burning+burns merged into 021)
- **`magi_offense_tracking/008_Transfix.lua`** — New: tracks transfix writhing on target
- **`magi_offense_tracking/009_Transfix_Unblind.lua`** — New: detects transfix curing blindness
- **`magi_offense_tracking/010_Scintilla_Spark.lua`** — New: 4s spark timer tracking
- **`magi_offense_tracking/011_Scintilla_Ignition.lua`** — New: burning + burns increment on ignition
- **`magi_offense_tracking/012_Staffcast_Lightning.lua`** — New: staffcast lightning relay
- **`magi_offense_tracking/013_Staffcast_Freeze.lua`** — New: horripilation from staffcast freeze
- **`magi_offense_tracking/014_Deepfreeze.lua`** — New: AoE frozen tracking

---

## 2026-03-10 — README: Fix broken .claude/classes/ link

### Problem
The `.claude/classes/` link in README.md returned a 404 on GitHub. The link target was `LEVI-Achaea/.claude/classes/` — the extra `LEVI-Achaea/` prefix caused a double path since the repo name is already part of the GitHub URL structure.

### Fix
Changed link target from `LEVI-Achaea/.claude/classes/` to `.claude/classes/`.

### Changes
- **`README.md`** — Fixed relative link path for the `.claude/classes/` directory

---

## 2026-03-10 — Limb Counter: Convert to Adjustable.Container

### Summary
Converted the Limb Counter window (`tarc`) from a raw `Geyser.MiniConsole` to an `Adjustable.Container` with an embedded `MiniConsole`. Users can now drag, resize, lock, and pop out the limb counter window, and its position auto-saves across sessions.

### Changes
- **`windows/001_Limb_Counter_Window.lua`** — Wrapped `tarc` in `Adjustable.Container:new({name = "tarc.window"})` with dark styling; embedded `Geyser.MiniConsole` as `tarc.console` inside a `Geyser.Container`; added simple forwarding functions (`tarc:cecho()` → `tarc.console:cecho()`, `tarc:clear()` → `tarc.console:clear()`) for backward compatibility with `tarc.write()` callers

### Notes
- All existing code calling `tarc:cecho(text)` and `tarc:clear()` works without modification
- Window position persists via Adjustable.Container's auto-save (`name = "tarc.window"`)
- Use `zfix tarc.window` to reset position if needed

---

## 2026-03-10 — Serpent: Darkshade mode second venom should be curare

### Issue
In darkshade mode, `apply_darkshade` strategy was hitting with `curare + darkshade` (curare first) instead of `darkshade + curare`. Similarly, `ginseng_pressure` in darkshade mode put curare first. The second venom should always be curare (to maintain paralysis and block tree) unless paralysis is already present.

### Fix
- `apply_darkshade` + darkshade mode: darkshade first, curare second (falls back to `buildSecondVenom()` if paralysis present)
- `ginseng_pressure` + darkshade mode: ginseng aff first, curare second

### Changes
- **`002_Serpent_Offense.lua`** — Reordered venoms in `apply_darkshade` and `ginseng_pressure` strategies for darkshade mode

---

## 2026-03-10 — Serpent: Fix double dispatch on gecko strip round

### Root Cause
The `attackInFlight` guard in `serp_ekanelia_offense()` was defeated by the GMCP vitals event handler, which cleared `attackInFlight` on **every** `gmcp.Char.Vitals` update where `bal == "1"` (level-triggered). When the user mashed the keybind, a second dispatch snuck through within ~100ms because the vitals handler fired between presses with stale `bal = "1"` (server hadn't consumed balance yet).

This caused: gecko strip echo + impulse echo on the same balance, but only the gecko dstab executed. The impulse queued for next balance via `queue addclear freestand`, creating a confusing echo mismatch.

### Fix
Changed the balance recovery handler from level-triggered to **edge-triggered** — `attackInFlight` now only clears on the `0→1` bal transition, not on every prompt where bal happens to be "1".

### Changes
- **`002_Serpent_Offense.lua`** — Edge-triggered `attackInFlight` clear via `serpent.state.lastBalState` tracking; added state init

---

## 2026-03-10 — GUI Simplification

### Summary
Stripped down the GUI to only load essential windows on startup. The full Geyser GUI (`ataxiagui`) is now disabled by default. All scripts remain active (`isActive: 'yes'`) — the change is purely in which windows get built on login.

### Windows that load on startup
- **Chat** — Tabbed chat window (zgui)
- **Map** — Mapper window (zgui)
- **Bash Window** — Basher status console (zgui)
- **Limb Counter** — Target limb tracking (standalone `tarc` namespace)
- **Hunter** — Hunting Scrolls (ataxia.data, loaded independently)

### Windows no longer loaded by default
Target Affs, Room Players, Room Denizens, Vital Bars, Cape gauge, Affliction Lock, Self Affs, Enemy/Ally lists, Prompt window, Stats window, Room Info — all still available via `zshow` if needed.

### Changes
- **`039_EDIT_ME__Startup_Main.lua`** — Removed `buildTarAffs`, `buildRoomPlayers`, `buildRoomDenizens` from `zgui.modules`; added `buildBashWindow`; removed vital bars `ataxia.bars.buildAll()` call; removed `zgui.vitals` init block; cleaned up unused font size vars
- **`002_Check_For_Any_Missing_Variables.lua`** — Default `ataxia.usegui = false` (was `true`) so the full Geyser border GUI doesn't load for new installs
- **`020_Setup_Wizard.lua`** — Updated `ataxia setup gui` to explain simplified GUI; `on`/`off` toggle still works for users who want the full Geyser layout; updated `ataxia setup status` label

### Notes
- Existing users with `ataxia.usegui = true` saved will still get the full Geyser GUI until they run `ataxia setup gui off`
- All update functions (`showAffs`, `showAllies`, `showEnemies`, `showRoomInfo`, `showCape`) remain defined and safe to call — Mudlet silently ignores writes to non-existent consoles
- No nil-guards needed — all call sites are either self-guarding or target consoles that handle missing windows gracefully

---

## 2026-03-10 — Shikudo Party Callout Fix

### Problem
Third-person Shikudo "Calls" triggers (004-007 in `calls/`) fired on effect text visible from ANY monk's attacks, not just the player's. This caused false party callouts (`pt Rat: clumsiness`, etc.) and incorrect affliction tracking when other monks (e.g., Mystor) attacked nearby.

### Fix
Deactivated all 4 redundant third-person triggers — the first-person equivalents (578, 569, 572, 576) already handle the player's own attacks correctly with `isTargeted()` gates:

| Deactivated Trigger | First-Person Equivalent |
|---------------------|------------------------|
| `004_Ruku_Clumsiness_Healthleech.lua` | `578_1Ruku_arms_(healthleech_clumsy).lua` |
| `005_Kuro_Weariness_Lethargy.lua` | `572_1Kuro_(weariness_lethargy).lua` |
| `006_Ruku_Torso_Slickness.lua` | `569_2Ruku_torso_(slickness).lua` |
| `007_Livestrike_Asthma.lua` | `576_Livestrike_(asthma).lua` |

---

## 2026-03-10 — Magi Offense Audit Fixes (P1-P6)

### Summary
Fixed 6 priority issues from reference system audit (xMagi/Tabethys comparison). Burns double-counting, missing burns decrement, fire resonance conditional logic, conflagrate gate, and meteorite variant keyword.

### Issues Fixed

**P1/P3 — Burns double-counting from duplicate triggers**
- Deactivated 3 old triggers that overlapped with new unified triggers:
  - `elementals/001_Efreeti.lua` → duplicated by `025_Burns_Tracking.lua`
  - `fire/001_Fire_Third.lua` → duplicated by `022_Resonance_Afflictions.lua`
  - `fire/002_Fire_Second.lua` → duplicated by `022_Resonance_Afflictions.lua`
- Old triggers under `staffcast/`, `fire/003` kept active (unique patterns, not duplicates)

**P2 — Burns never decrement**
- Added pattern `^The fires consuming (\w+) diminish somewhat\.$` to `025_Burns_Tracking.lua`
- Decrements `magi.offense.state.burns`, clears `burning` aff and `conflagrated` flag when burns reach 0

**P4 — Conflagrate gate too strict**
- Changed from `burning >= 2 and r.fire >= 2 and r.air >= 2` to `burning >= 2 and r.fire >= 2`
- Reference system (xMagi) only requires `fire >= 2`, not `air >= 2`

**P6 — Meteorite missing "pure" keyword**
- Changed `"cast meteorite at "` to `"cast meteorite pure at "` in `selectMeteorite()` fallback

**Fire resonance conditional logic (in 022_Resonance_Afflictions.lua)**
- Fire level 2: Now checks scalded state before incrementing burns (scalded first, then burns if already scalded)
- Fire level 3 blistered: Added `tempTimer(15, ...)` for blistered fade
- Fire level 3 burning: Added burns counter display with `cecho()`
- Uses `magi.offense.setScalded()` for 20s timer management

### Files Changed
- `triggers/.../elementals/001_Efreeti.lua` — `isActive: 'no'`
- `triggers/.../fire/001_Fire_Third.lua` — `isActive: 'no'`
- `triggers/.../fire/002_Fire_Second.lua` — `isActive: 'no'`
- `triggers/.../general/022_Resonance_Afflictions.lua` — fire conditional logic
- `triggers/.../general/025_Burns_Tracking.lua` — burns diminish pattern
- `scripts/.../mage/004_Magi_Offense.lua` — conflagrate gate + meteorite pure

**P9 — Caloric defense tracking (frostbite proxy → direct nocaloric)**
- Changed `caloric` variable from frostbite proxy to direct `not hasAff("nocaloric")`
- `nocaloric` already tracked by existing triggers (391, dehydrate, freeze chain, waterbond)

### Deferred Issues
- P5 (staffcast lightning → stupidity): Unknown game text pattern
- P7 (firestorm target burns): Unknown game text pattern
- P11-P13: Low priority cleanup

---

## 2026-03-10 — Default Curing Priorities Overhaul

### Summary
Complete overhaul of SSC default curing priorities in `ataxia_defaultCuringPrios()`. Many afflictions were at dangerously low priorities (e.g., peace at 16, fear at 20, confusion at 20) with comments about dynamic swaps that were never implemented. Priorities now reflect actual combat urgency.

### File Changed
`001_Default_Curing_Prios.lua` (scripts/levi_ataxia/levi/ataxia/ataxia/)

### Architecture Change
- `ataxia_sendDefaultPrios()` refactored to loop over the `ataxia_defaultCuringPrios()` table instead of hardcoded send strings — eliminates duplication and keeps table+send in sync
- Fixed `local function` → global `function` for `ataxia_sendDefaultPrios()` (was nil when called from alias)

### Priority Changes (24 afflictions adjusted)
| Affliction | Old | New | Reason |
|-----------|-----|-----|--------|
| peace | 16 | 2 | Can't attack or defend — total incapacitation |
| pacified | 14 | 3 | Can't use aggressive actions |
| paralysis | 4 | 3 | User priority: stay unparalyzed. Blocks tree. No bloodroot competition |
| impatience | 6 | 4 | Blocks focus. Hardlock component |
| prone | 9 | 2 | Enables kill combos (impale, vivisect, trample) |
| fear | 20 | 5 | Forces fleeing. Bal-free cure |
| disrupted | 9 | 2 | Blocks tree tattoo. Bal-free cure |
| clumsiness | 14 | 7 | 33% miss chance |
| voyria | 9 | 2 | Class lock aff. Sip-cured (separate balance) |
| nausea | 11 | 8 | Blocks parry. Important vs limb classes |
| stupidity | 18 | 8 | Focus handles normally, but 18 was absurd fallback |
| epilepsy | 18 | 8 | Random seizures lose balance |
| recklessness | 21 | 8 | 50% more damage taken |
| masochism | 21 | 8 | Ekanelia enabler for Serpents |
| confusion | 20 | 8 | Blocks actions. Ash-cured |
| dizziness | 23 | 9 | Vertigo synergy |
| vertigo | 16 | 9 | Dizziness+vertigo = falling |
| healthleech | 14 | 9 | Ticking damage |
| addiction | 11 | 9 | Riftlock enabler |
| horror | 8 | 10 | Less urgent than combat affs |
| paranoia | 17 | 10 | Blocks ally help |
| dementia | 17 | 10 | Random actions |
| shyness | 23 | 12 | Focus fallback was at 23 |
| timeloop | 5 | 4 | DW mechanic — moved from 5 to 4 |

### Stacking Affliction Variants Added
- `burning1`–`burning5` at priority 9
- `pyre1`–`pyre3` at priority 9, `pyre` base at 8
- `horror1`–`horror5` at priority 9
- `unweavingbody1`/`unweavingbody2`/`unweavingmind1`/`unweavingmind2` at 25 (low stacks deprioritized)
- `unweavingbody3`–`5`/`unweavingmind3`–`5` at 2 (high stacks = critical)
- `insomnia` at 26 (SSC custom handling)

### Other Adjustments
- `mangledhead` moved from 9 → 8
- Removed generic `unweavingbody`/`unweavingmind` entries (replaced by leveled variants)
- `indifference` set to 25 (deprioritized)
- Writhe affs (entangled, bound, webbed, etc.) kept at 2
- Priority 1 remains RESERVED for dynamic swap system

---

## 2026-03-10 — Magi Burns: Scintilla Not Incrementing Burns Counter

### Root Cause
`004_Immolation.lua` (scintilla success trigger) only set `timmolation = true` without incrementing `magi.offense.state.burns`. Burns counter stayed at 0 through 6+ scintilla casts, only incrementing when fire resonance passive ("Flames ignite") or efreeti ticks fired.

### Fix
| File | Change |
|------|--------|
| `staffcast/004_Immolation.lua` | Added burns increment + `tarAffed("burning")` + burn counter echo on scintilla hit |

---

## 2026-03-10 — Simultaneity Defense Tracking Fix

### Root Cause
GMCP never reports "simultaneity" as a defense — it's not in `gmcp.Char.Defences.List`. The `def` command only displayed defenses from GMCP, so simultaneity always showed `[-]` even when active.

### Fix
| File | Change |
|------|--------|
| `012_Fortify.lua` | Set `ataxia.defences["simultaneity"] = true` when "You forge a channel" trigger fires |
| `003_Defence_Reporting.lua` | Inject text-tracked defenses (simultaneity) into the `def` display when `ataxia.defences` flag is set |

---

## 2026-03-10 — Magi Offense: Alias Routing per Mode

### Alias Mode Routing (5 files)
| Alias | Regex | Magi Mode | File |
|-------|-------|-----------|------|
| First Attack | `^zz$` | salve (default) | `152_First_Attack_(All_Classes).lua` |
| Second Attack | `^xx$` | fire | `155_Second_Attack_(All_Classes).lua` |
| Third Attack | `^cc$` | lock | `156_Third_Attack_(All_Classes).lua` |
| Fourth Attack | `^vv$` | water | `153_Fourth_Attack_(All_Classes).lua` |
| Group Attack | `^sr$` | group | `154_Group_(All_Classes).lua` (already wired) |
| Scytherus | `^srr$` | stormhammer | `157_Scytherus_(All_Classes).lua` |

Each alias now calls `magi.offense.setMode(mode)` before `magi.offense.dispatch()` so mode is explicit per keybind. Stormhammer (`srr`) uses `magi.storm.fire()` with fallback to raw `cast stormhammer`.

---

## 2026-03-10 — Magi Offense: Mode Logic + Final Trigger Fixes

### Trigger Fixes (continued)
| File | Fix |
|------|-----|
| `024_Meteorite.lua` | Flaming variant missing `tarAffed("burning")` — V3 never knew target was burning from meteorite |
| `024_Meteorite.lua` | Burns increment uncapped — added `math.min(..., 5)` + tburns sync |
| `022_Resonance_Afflictions.lua` | Fire moderate/major branches missing `tarAffed("burning")` — V3 unaware of resonance burns |
| `022_Resonance_Afflictions.lua` | Burns increment uncapped — added `math.min(..., 5)` + tburns sync |

### New Mode Logic (004_Magi_Offense.lua)
- **Salve mode** (`selectSalveSpell()`): Prioritizes earth resonance for salve-curable affs (limb breaks, cracked ribs, calcified torso), magma for salve balance lock, scintilla for calcify
- **Group mode** (`selectGroupSpell()`): Stormhammer threshold raised to 50% HP (vs 25% default), emanation fire/earth at cap for AoE pressure, shalestorm for earth AoE, pure damage fallback
- **Firestorm state sync**: `dispatch()` now syncs `magi.firestorm` legacy global into `magi.offense.state.firestorm`

---

## 2026-03-10 — Magi Offense Bug Fixes & Trigger Updates

Comprehensive review and bug fix pass across the entire Magi offense system. Fixed critical bugs in the core offense script, all 4 emanation triggers, shalestorm, burns tracking, conflagrate fail, and calcify triggers. Updated 16+ files to sync `tburns` with `magi.offense.state.burns`.

### Critical Fixes (004_Magi_Offense.lua)
- **State table clobbered on reload**: Unconditional `state = {...}` wiped runtime state. Changed to merge pattern preserving existing values
- **Missing bal/eq guard in dispatch()**: Would fire selectSpell+sendAttack while off-balance/off-eq. Added GMCP vitals check
- **Water kill route non-functional**: `st.frozen`/`st.hypothermia` state flags were NEVER set by triggers. Replaced with V3 probability queries (`getAffProb("frozen") >= 0.5`)
- **Conflagrate missing air check**: Would attempt conflagrate without `r.air >= 2`, wasting rounds on failed casts

### Trigger Fixes
| File | Fix |
|------|-----|
| `020_Conflagrated_Fail.lua` | Regex typo `noavail` → `no avail` — trigger was NEVER firing |
| `025_Burns_Tracking.lua` | Firestorm pattern tracked self-damage, not target burns — removed incorrect increment |
| `023_Shalestorm.lua` | `erAff("shield")` incorrectly called on limb break (not shield break) — removed |
| `004_Earth_Emanation.lua` | Premature `tarAffed("calcifiedskull")` on emanation cast (process, not result) — removed |
| `001-004 Emanation triggers` | Added target validation (`matches[2] == target`) — prevented wrong-target tracking |
| `001-004 Emanation triggers` | Hardcoded "primordial staff" → flexible `an? \w+ staff` — works with any staff |
| `026_Calcify.lua` | Pattern mismatch with emanation ("elemental" vs "primordial") — made staff-agnostic |
| `002_Water_Emanation.lua` | Updated to use `magi.offense.ptRelay()`, added target validation |
| `003_Air_Emanation.lua` | Updated to use `magi.offense.ptRelay()`, added target validation |

### tburns Sync (16 files)
All trigger/script/alias files using old `tburns` global now sync with `magi.offense.state.burns`:
- Increment: `math.min(state.burns + N, 5)` + `tburns = state.burns`
- Decrement: `math.max(state.burns - 1, 0)` + `tburns = state.burns`
- Reset: `state.burns = 0; tburns = 0`
- Files: efreeti, fire second/third, firestorm tick/up, dehydrate, firelash, increase burning, fire staffcast, immolation, tree decrement, caloric decrement, RESET alias, login function, targeting functions

### Other Fixes
- `001_Resonance.lua`: Fixed event handler accumulation (`killAnonymousEventHandler` before re-register)

---

## 2026-03-10 — Psion Offense Modernization (psion namespace)

Complete rewrite of the Psion offense system. Replaced 720 lines of duplicated functions (`levipsionmind` defined 3 times) and 20+ global variables with a unified `psion` namespace following modern conventions (Shaman/Apostate/Serpent pattern). Added rebounding stripping logic (recent game change: Psion weaves now blocked by rebounding, but unweaves/deconstruct bypass it). Fixed multiple operator precedence bugs and a class-check logic error.

### Modified Files
| File | Changes |
|------|---------|
| `scripts/.../psion/001_Levi_Psion_Logic.lua` | Full rewrite: `psion` namespace with state/config, V3 affliction routing (`psion.hasAff()` → `haveAff()`), dispatch guards (target/aeon/balance/reboundHold), rebounding strip via cleave, `selectPrepare()`/`selectWeave()`/`selectTranscend()`/`buildAttack()`/`sendAttack()`, 2 modes (mind/flurry), combat echo, backward-compat shims (`levipsionmind()`/`levipsionflurry()`), tempAlias registration with reload cleanup |
| `aliases/.../152_First_Attack_(All_Classes).lua` | Added Psion branch → `psion.dispatch()` |

### Bug Fixes
- **Operator precedence**: `tAffs.impatience and not tAffs.stupidity or not tAffs.dizziness` evaluated incorrectly (Lua `and`/`or` precedence) — fixed with parentheses
- **Class check always true**: `~= "Priest" or ~= "Occultist" or ~= "Pariah"` is always true — changed to lookup table
- **Flurry invert gate**: `inverted == true and tAffs.unweavingspirit or tAffs.criticalspirit` triggered on criticalspirit regardless of inverted — fixed with parentheses
- **No weave fallback**: `psionweave[1]` could be nil causing errors — `selectWeave()` now always returns a string

### Rebounding Handling (New)
- Regular weave attacks (overhand, backhand, deathblow, sever, puncture) are blocked by rebounding
- Unweaves (mind/body/spirit) and Deconstruct bypass rebounding
- When rebounding detected + non-bypass weave needed → `weave cleave` strips rebounding (prepare aff still lands)
- Early fight: unweaves are prioritized anyway, so rebounding is bypassed for free

---

## 2026-03-10 — Unified Magi Offense System (magi.offense)

Complete rewrite of the Magi combat system. Consolidated 5 fragmented functions (MagiMain, MagiLock, MagiWaterFocus, MagiFireNew, MagiSalveFocus) across 2 old files into a single unified `magi.offense` namespace with 5 combat modes, full resonance budgeting, meteorite shield breaking, burns tracking, calcify tracking, shalestorm tracking, and V3 affliction integration. Based on reference systems from top Magi players (xMagi decision tree + Tabethys triggers).

### New Files
| File | Purpose |
|------|---------|
| `scripts/.../mage/004_Magi_Offense.lua` | Unified offense (~570 lines): dispatch, 13-priority decision tree, 5 modes, meteorite variants, vibration auto-management, backward-compat wrappers |
| `triggers/.../general/021_Spell_Outcomes.lua` | Spell success detection (magma, dehydrate, fulminate, bombard, firelash, mudslide) |
| `triggers/.../general/022_Resonance_Afflictions.lua` | 12 resonance passive effect triggers (air/earth/fire/water affs on target) |
| `triggers/.../general/023_Shalestorm.lua` | Shalestorm start/hit/shield/end with anti-illusion guard |
| `triggers/.../general/024_Meteorite.lua` | Meteorite shield-break variant detection (flaming/frozen/pure/no-wards) |
| `triggers/.../general/025_Burns_Tracking.lua` | Burns counter from efreeti/conflagrate/firestorm |
| `triggers/.../general/026_Calcify.lua` | Calcified torso/skull detection and fade tracking |
| `aliases/.../magi_things/006_Magi_Mode.lua` | `mm` mode-switch alias (fire/water/lock/salve/group/debug/vibes/reset) |

### Modified Files
| File | Changes |
|------|---------|
| `152_First_Attack_(All_Classes).lua` (zz) | Added Magi branch → `magi.offense.dispatch()` |
| `154_Group_(All_Classes).lua` (sr) | Added Magi branch → group mode dispatch |
| `enamation/001_Fire_Emanation.lua` | Updated burns tracking to use `magi.offense.state.burns` |
| `enamation/004_Earth_Emanation.lua` | Added `magi.offense.state.calcifiedSkull` sync |
| `general/019_Conflagrated.lua` | Synced with `magi.offense.state.conflagrated` and burns |
| `general/020_Conflagrated_Fail.lua` | Added state reset on conflagrate failure |

### Removed Files
| File | Reason |
|------|--------|
| `scripts/.../mage/002_Logic.lua` | Old MagiMain/MagiLock — replaced by 004 |
| `scripts/.../mage/003_Magi_Levi_Logic_2.lua` | Old MagiWaterFocus/MagiFireNew/MagiSalveFocus — replaced by 004 |

### Key Improvements
- **Meteorite shield breaking**: 4 variants (flaming/pure/frozen/erode) selected by resonance state
- **Resonance budgeting**: Never wastes capped resonance, always emanates at cap
- **Burns pipeline**: magma → scalded(20s timer) → burns counter → conflagrate → destroy
- **Glaciate pathway**: Dual-resonance gate (water>=2 AND air>=2) for freeze → hypothermia → glaciate
- **Calcify tracking**: Tracks calcified torso/skull state, adjusts emanation earth priority
- **V3 integration**: Uses `haveAff()`/`getAffProbabilityV3()` for confidence-based gating
- **5 modes**: fire, water, lock, salve, group (via `mm <mode>`)
- **Backward compat**: Old function name wrappers preserved

---

## 2026-03-10 — Remove legacy dispatch calls from master combat aliases

Cleaned all 5 master combat aliases (`zz`, `xx`, `cc`, `vv`, `sr`) by removing legacy bare-function dispatch calls. Only modern namespace-based systems remain.

**Removed legacy calls** (classes without modern systems): Dragon, Bard, Psion, Runie DWC, Infernal SnB, Infernal DWB, Infernal 2H, Magi, Pariah, plus Monk `lock_base_prios()`/`formswaplock()` and Apostate `apostate_group()` wrapper (replaced with direct `apostate.setMode("group"); apostate.dispatch()`).

**Modern systems retained**: Monk (tekura6/shikudo), Runie DWB (dwbRunie), Infernal DWC (infernalDWCVivisect/GroupLock), Depthswalker, Blademaster (bmd/bmdq/bmbs), Apostate, Serpent, Shaman.

| File | Changes |
|------|---------|
| `152_First_Attack_(All_Classes).lua` (zz) | Removed Dragon, Bard, Psion, Runie DWC, Infernal SnB (×2), Infernal DWB, Infernal 2H, Magi, Pariah |
| `155_Second_Attack_(All_Classes).lua` (xx) | Removed Bard, Runie DWC, Dragon, Magi, Infernal DWB, Infernal 2H, Infernal SnB, Psion, Pariah |
| `156_Third_Attack_(All_Classes).lua` (cc) | Removed Monk, Bard, Runie DWC, Infernal SnB, Infernal 2H, Magi, Infernal DWB, Infernal DWC legacy |
| `153_Fourth_Attack_(All_Classes).lua` (vv) | Removed Monk, Infernal DWB, Infernal SnB, Magi; replaced `apostate_group()` with modern dispatch |
| `154_Group_(All_Classes).lua` (sr) | Removed Runie DWC, Infernal DWB, Infernal SnB, Magi; cleaned BM legacy fallback |

---

## 2026-03-10 — Wire Infernal DWC group combat to `sr` alias

The `sr` (group combat) alias for Infernal DWC was calling the legacy `dwcpriosbasicinfernalgroup()`. Replaced with `infernalGroupLockAttack()` which provides full truelock offense with V3 tracking, hellforge exploit, class-aware lock afflictions, and rebounding/shield handling.

| File | Changes |
|------|---------|
| `aliases/.../154_Group_(All_Classes).lua` | Infernal DWC branch now calls `infernalGroupLockAttack()` instead of `dwcpriosbasicinfernalgroup()` |

---

## 2026-03-10 — Magi Group PvP: Transfix/Staffcast Coordination + Smart Stormhammer

### Transfix/Staffcast Coordination (Part A)
When playing Magi, automatically react to transfix events from any source:
- **Self transfix success** (`505_Transfixed.lua`): Auto-queues `staffcast horripilation at target`
- **Self transfix unblind** (`504_Transfix_Unblind.lua`): Auto-queues `cast transfix target` to retry
- **Third-party transfix** (`general/010_Third_Party_Transfix.lua`): New trigger, staffcasts current target
- **Third-party unblind** (`general/011_Third_Party_Transfix_Unblind.lua`): New trigger, re-transfixes named target
- **Party callouts** (`party_targetting/005_Party_Magi_Coordination.lua`): New trigger reacts to "Staffcast: X", "X: Transfixed", "X: Unblind" from any party member

All gated behind `gmcp.Char.Status.class == "Magi"` and use `queue addclearfull freestand`.

### Smart Stormhammer (Part B)
New `storm` alias for group combat stormhammer targeting:
- **Targeting script** (`mage/005_Stormhammer_Targeting.lua`): Picks up to 3 enemies from the **same city as current target** in the room
- **Storm alias** (`magi_things/005_Storm.lua`): `^storm$` → selects targets and fires `cast stormhammer at X and Y and Z`
- **Starburst tracking** (`general/012_Storm_Starburst.lua`): Marks targets that starburst as alive (don't replace)
- **Death replacement** (`general/013_Storm_Death_Replace.lua`): Auto-replaces dead targets with next available same-city enemy

**Files**: 2 edited, 7 new

---

## 2026-03-10 — Overhaul: Default SSC curing priorities

Comprehensive overhaul of default curing priorities sent to Achaea's server-side curing (SSC) system. Many afflictions had priorities set for dynamic swaps that were never implemented (e.g., stupidity at 18 "move to 9 if off focus balance"), leaving dangerous gaps in curing. Additionally, several combat-critical afflictions (peace, fear, confusion, recklessness, masochism) were at very low priority despite being highly impactful.

**23 priority changes** — all raising urgency except horror (8→10, less urgent than recklessness/masochism):

| Affliction | Old | New | Why |
|-----------|-----|-----|-----|
| peace | 16 | 2 | Cannot attack or defend |
| pacified | 14 | 3 | Prevents aggressive actions |
| paralysis | 4 | 3 | User priority: stay unparalyzed. Blocks tree. No bloodroot competition |
| impatience | 6 | 4 | Blocks focus. Hardlock component |
| prone | 9 | 5 | Enables kill combos |
| fear | 20 | 5 | Forces fleeing. Bal-free cure |
| disrupted | 9 | 5 | Blocks tree tattoo. Bal-free cure |
| clumsiness | 14 | 7 | 33% miss chance |
| voyria | 9 | 7 | Sip-cured, class lock aff |
| nausea | 11 | 8 | Blocks parry |
| stupidity | 18 | 8 | Focus fallback was absurdly low |
| epilepsy | 18 | 8 | Seizures lose balance |
| recklessness | 21 | 8 | 50% more damage taken |
| masochism | 21 | 8 | Ekanelia enabler |
| confusion | 20 | 8 | Blocks actions, ash-cured |
| dizziness | 23 | 9 | Vertigo synergy |
| vertigo | 16 | 9 | Falling damage |
| healthleech | 14 | 9 | Ticking damage |
| addiction | 11 | 9 | Riftlock enabler |
| horror | 8 | 10 | Less urgent than combat affs |
| paranoia | 17 | 10 | Blocks ally help |
| dementia | 17 | 10 | Random actions |
| shyness | 23 | 12 | Focus fallback was absurdly low |

**Priority 1 reserved**: No default priorities at 1 — slot is reserved for on-the-fly emergency swaps (paraAst, brSlick, astImp, WATER, hypoImp all boost to 1 dynamically). Old prio 1 affs (aeon, hypothermia, peace) moved to 2; old prio 2 affs (sleeping, slickness, pacified, paralysis) moved to 3.

**Code refactor**: Replaced duplicated hardcoded `send()` calls in `ataxia_resetOnLogin()` and `ataxia_resetPrios()` with a shared `ataxia_sendDefaultPrios()` helper that loops over the `ataxia_defaultCuringPrios()` table. This eliminates desync risk between the table and the SSC commands.

| File | Changes |
|------|---------|
| `scripts/.../ataxia/001_Default_Curing_Prios.lua` | Updated 23 priorities in `ataxia_defaultCuringPrios()`, refactored reset functions to use shared table-driven helper |

---

## 2026-03-10 — Perf: Basher attack hot-path optimization

The basher attack dispatch (`ataxiaBasher_attack()`) ran ~90 lines of deeply nested inline flee logic with recursive calls, redundant function invocations (stormhammer recomputed 3x, search_targets 3x, updateVitals redundantly), all executing every prompt when health was low. The clean danger-level system (`ataxiaBasher_dangerLevel()` / `ataxiaBasher_executeFlee()`) existed but was dead code — never wired into the attack path.

**Fix**: Replaced the entire inline flee/shield/threshold block with clean calls to the existing danger-level system. Removed redundant `ataxiaBasher_stormhammer()` call from `ataxiaBasher_assembleAttack()` (already called once per prompt cycle via dirty-flag in `ataxiaBasher_patterns()`). Eliminated recursive `ataxiaBasher_patterns()` call and redundant `search_targets()` / `ataxiagui_updateVitals()` calls from the attack path.

| File | Changes |
|------|---------|
| `scripts/.../basher/001_Bashing_Functions.lua` | Rewrote `ataxiaBasher_attack()` to use `ataxiaBasher_dangerLevel()` + `ataxiaBasher_executeFlee()`. Removed redundant `ataxiaBasher_stormhammer()` from `ataxiaBasher_assembleAttack()` |

---

## 2026-03-10 — Fix: Chat windows lose original MUD colors

Chat capture was stripping all ANSI escape sequences and applying a flat per-channel color (e.g., all "says" in cyan). This lost the MUD's original per-word coloring (player names, channel tags, speech text).

**Fix**: Replaced `stripAnsi()` + `cecho()` with Mudlet's built-in `ansi2decho()` + `decho()`, which converts ANSI escape codes to decho color format and preserves the original coloring from the server.

| File | Changes |
|------|---------|
| `scripts/.../update_windows/001_showChat.lua` | Removed `stripAnsi()`, `channelColors`, `getChannelColor()`. Use `ansi2decho()` + `decho()` for display |
| `scripts/.../gui_stuff/003_Chat_Capture_Things.lua` | Same changes for the ataxiagui chat system |

---

## 2026-03-10 — Fix: Death/starburst causes double death from basher spam

When dying during bashing, the basher would keep attacking on the next prompt — causing a second death immediately after starburst resurrection. Three root causes:

1. **No trigger for player's own starburst** — trigger 405 only matched when *your target* starburst, not when *you* starburst. The text "Your starburst tattoo flares as the world is momentarily tinted red" was completely unhandled.
2. **`ataxiaBasher_onDeath()` only paused** — set `ataxiaBasher.paused = true` but left `ataxiaBasher.enabled = true`, so the prompt handler still ran `search_targets()` and could dispatch attacks before the pause took effect.
3. **Auto bash rotation never cleared** — `autoBashRotation` stayed true after death, causing `basher_disengaged()` to auto-move to the next bashing area.

**Fix**: `ataxiaBasher_onDeath()` now fully disables the basher (`enabled = false`), clears all queues (`cq all`), kills all active timers (flee, stuck, anti-spam), turns off auto bash rotation, stops mapper movement, and after a 2s delay moves to `mmp.previousroom` (the room before where you died) to heal up safely.

| File | Changes |
|------|---------|
| `scripts/.../genrunning/001_Bashing_API.lua` | Rewrote `ataxiaBasher_onDeath()` — full disable instead of pause, clears rotation, kills timers, moves to safe room |
| `triggers/.../406_Own_Starburst.lua` | **New** — triggers on "Your starburst tattoo flares", calls `ataxiaBasher_onDeath()` |
| `triggers/.../407_Player_Slain.lua` | **New** — triggers on "You have been slain by", calls `ataxiaBasher_onDeath()` (fires before starburst line) |

---

## 2026-03-10 — Fix: Nil guard errors across prompt, display, and event systems

Fixed 7 runtime errors caused by nil field access during early login, blind state, or missing data. All fixes add proper nil guards with fallback defaults.

| File | Error | Fix |
|------|-------|-----|
| `scripts/.../misc_scripts/021_Auto_Update.lua` | `Auto_Update` called as nil — Mudlet `eventHandlers` expects global function matching script name | Added global `Auto_Update(event, ...)` dispatcher routing to `ataxia.updater.onDownloadDone`/`onDownloadError` |
| `scripts/.../defence/001_Pre_Apply.lua` | `slc.percentages` nil when SLC not initialized | Added `if not slc or not slc.percentages then return end` early guard |
| `scripts/.../012_Prompt_Substitution.lua` | `ataxia.vitals.hpp/mpp/epp/wpp` nil on early prompts | Added `local var = ataxia.vitals.xxx or 0` for all 8 colour functions (hcolour, mcolour, ecolour, wcolour, darkh, darkm, darke, darkw) |
| `scripts/.../windows/001_Limb_Counter_Window.lua` | `gmcp.IRE.Target` nil when no target | Added nil guard chain `gmcp.IRE and gmcp.IRE.Target and gmcp.IRE.Target.Info` |
| `scripts/.../windows/001_Limb_Counter_Window.lua` | `mymomentum` nil for non-DWB classes | Changed to `(mymomentum or 0)` |
| `scripts/.../update_stuff/003_ataxia_RoomContents_Update.lua` | `gmcp.Char.Items.Add` accessed during Remove event | Removed erroneous `gmcp.Char.Items.Add.location` check from Remove branch |
| `triggers/.../276_Limb_Prompt.lua` | `gmcp.Char.Vitals.charstats` nil + operator precedence bug | Added nil guard for charstats, fixed `and`/`or` parentheses, added `or 0` fallback |

---

## 2026-03-09 — Auto-Update System (`sysupdate`)

Added in-game auto-update system that checks for new versions on login and allows one-command updates. Uses Mudlet's async `downloadFile` + `sysDownloadDone` event pattern (same as the mapper), not fragile `tempTimer` delays.

**On login (5s after load):**
- Downloads `version.txt` from GitHub, compares against `ataxiaVersion`
- If newer version available: shows notification with "Type SYSUPDATE to update"
- If current: shows "up to date" confirmation

**`sysupdate` command:**
- Downloads latest `Levi_Ataxia.mpackage` from GitHub
- Uninstalls old package, installs new one, cleans up temp file

**Version bump workflow (for releases):**
1. Update `version.txt` with new version string
2. Update `muddler_project/mfile` `"version"` field
3. Build with muddler
4. Push to GitHub (mpackage + version.txt)

| File | Changes |
|------|---------|
| `version.txt` | **New** — Single-line version string (currently `4.1`) |
| `scripts/.../misc_scripts/021_Auto_Update.lua` | **New** — `ataxia.updater` namespace, version check + download + install logic |
| `aliases/.../levi_062424/201_Sysupdate.lua` | **New** — `^sysupdate$` alias |

---

## 2026-03-09 — ClassDetect: Default unsupported curingsets to "normal" + AntiPsion fix

**ClassDetect curingset validation**: Added a `validCuringsets` whitelist so classes that map to curingsets that don't exist in-game fall back to "normal" instead of sending invalid `curingset switch` commands. Also changed Runewarden mapping from "runewarden" to "knights".

**AntiPsion rewrite**: Fixed priority order — mind (≥2) checked first (was second), body (≥2) second, spirit+asthma third. Removed requirement for both body AND mind to be present simultaneously. Spirit no longer requires ≥2 check.

| File | Changes |
|------|---------|
| `scripts/.../class_detect/001_Class_Detect_Engine.lua` | Added `classDetect.validCuringsets` whitelist, validation in `switchCuringset()`, Runewarden → "knights" |
| `scripts/.../algedonic_defense_1.0/001_Anti_Priorities.lua` | Rewrote `Algedonic.AntiPsion()` with correct priority order |

---

## 2026-03-09 — Fix: DWB Runie lag when spamming ZZ + wrong queue command

Spamming `zz` on DWB Runewarden caused massive lag because the dispatch had no balance gate, no anti-spam timer, and sent 9+ commands per keypress. Additionally used `queue addclear freestand` instead of `queue addclearfull free`, causing queued commands to stack instead of replace.

**Root causes:**
1. No balance check before dispatch — sent attacks every keypress regardless of balance state
2. No anti-spam cooldown — unlike basher (0.3s timer) or serpent (balance gate)
3. `queue addclear` only clears the free queue, not all queues — spam stacked commands

**Fix:**
- Added GMCP balance gate at top of `dwbRunie.dispatch()` (`gmcp.Char.Vitals.bal ~= "1"`)
- Added 0.3s anti-spam cooldown timer in `dwbRunie.sendAttack()` (same pattern as basher)
- Changed `queue addclear freestand` → `queue addclearfull free` (same pattern as apostate)

| File | Changes |
|------|---------|
| `scripts/.../dwb_runie/001_DWB_Runie_Logic.lua` | Balance gate + anti-spam in `dispatch()`, queue command fix + cooldown timer in `sendAttack()` |

---

## 2026-03-09 — GUI: Increase SLC window default height

Increased the Self Limb Counter (SLC) GUI window default height by 20% (180 → 216) to fit more data. Existing windows need `zfix selfLimbDamageWindow` to pick up the new default.

| File | Changes |
|------|---------|
| `scripts/.../self_limb_tracking/002_Track_The_Damage.lua` | Default height 180 → 216 |

---

## 2026-03-09 — Fix: TK6 PREP breaks limb prematurely + wastes punches as jabs

During PREP phase, when only 1 unprepped limb remained and a kick would break it (e.g., RL at 84.5% + 18.3% kick = 102.8%), the kick fallback had no break guard and kicked it anyway. Both punches then fell back to generic `"jbp arms"` (wasted jabs to left shoulder) because the candidate pool only contained unprepped limbs.

**Root causes:**
1. Kick fallback (last resort) picked lowest-damage candidate with no break check
2. `allCandidates` only contained unprepped limbs — prepped-but-not-broken limbs were invisible to punch selection
3. Punch fallback used ambiguous `"jbp arms"` instead of explicit limb targeting

**Fix:**
- Expanded candidate pool: `unprepCandidates` (priority) + `overflowCandidates` (prepped-but-not-broken, safe overflow)
- `findSafeLimb()` now searches 4 passes: non-parried unprepped → parried unprepped → non-parried overflow → parried overflow
- When no kick target is safe, uses RHK (roundhouse kick) as filler — does no limb damage
- Punch fallback uses `jbp` filler (no limb damage) instead of ambiguous `"jbp arms"` that targeted random limbs
- JBP filler always ordered first in combo (slot 1) — disables parry for the following real punch in slot 2

| File | Changes |
|------|---------|
| `scripts/.../tekura/002_Tekura_6Limb_Offense.lua` | Rewrote `buildPrepAttack()`: dual candidate pools, RHK filler kick, explicit punch targeting |

---

## 2026-03-09 — Fix: Tekura basher attacks fail when wielding weapons

Tekura combos (`sdk ucp ucp` / `rhk ucp ucp`) require empty hands. Added `unwield all` before all 3 tekura attack paths in the Monk basher (shielded+rageraze, shielded+no-rageraze, normal).

| File | Changes |
|------|---------|
| `scripts/.../basher/002_Class_Bashing.lua` | Prepended `unwield all` (via separator) before all 3 tekura `combo` commands |

---

## 2026-03-09 — Fix: Hunting Scrolls `<ansiMagenta>` rendered as literal text

`ansiMagenta` is not a valid `cecho`/`cechoLink` color name — it's an `hecho` format. All 30+ occurrences in the Hunting Scrolls display were rendering as literal `<ansiMagenta>` text instead of magenta color.

| File | Changes |
|------|---------|
| `scripts/.../zdata/001_Experience_Database.lua` | Replaced all `ansiMagenta` with `magenta` (both variable assignments and inline cecho tags) |

---

## 2026-03-09 — Feature: Players in Area (Mindnet) display in tarc window

When Monk/BM has mindnet defense active, the game fires enter/leave messages for players in the area. The mindnet trigger now maintains a persistent `ataxia.playersInArea` list and displays it in the tarc bashing window with NDB city-based coloring. List clears automatically on area change.

| File | Changes |
|------|---------|
| `triggers/.../telepathy/001_Mindnet.lua` | Added enter/leave tracking to populate `ataxia.playersInArea`, refresh tarc on update |
| `scripts/.../update_stuff/002_ataxia_Room_Update.lua` | Clear `ataxia.playersInArea` on area change via `ataxia._lastMindnetArea` |
| `scripts/.../windows/001_Limb_Counter_Window.lua` | Added "Players in Area:" display section (magenta header, NDB coloring) |

---

## 2026-03-08 — Fix: Stale tAffs reads across offense systems

Multiple offense scripts read `tAffs.<aff>` directly instead of `haveAff("<aff>")`. After V3 correctly cured afflictions, the stale `tAffs` cache could retain `true` values (intermediate 1-30% probability range not cleared by `syncToOldSystemV3()`), causing wrong strategy decisions and incorrect displays.

| File | Changes |
|------|---------|
| `serpent/002_Serpent_Offense.lua` | Replaced all 8 `tAffs.darkshade` with `haveAff("darkshade")` |
| `apostate/015_CC_Apostate.lua` | Replaced `tAffs.dementia`/`tAffs.hypersomnia` with `haveAff()` (nightmare aff tracking) |
| `bard/001_LeviBard.lua` | Replaced 14 bare `tAffs.<aff>` with `haveAff()` (paralysis, asthma, slickness, lethargy, sensitivity, dizziness, addiction). Fixed 2 shield/rebounding checks to use V1 fallback pattern |

---

## 2026-03-08 — Fix: table.load wiping runtime functions and state

`table.load(file_loc, ataxia)` in `ataxia_loadSettings()` replaced the entire `ataxia` table contents on `sysLoadEvent`, destroying runtime sub-tables with functions that were initialized by scripts before the load event. This caused `ataxia.data.db.addChar` (nil), `ataxia.data.movement` (nil), and `ataxiaBasher.ldeckRules` (nil) errors on every prompt/trigger fire.

**Root cause**: `table.save` can't serialize functions. When `table.load` replaces a sub-table, the saved version has data but no functions — wiping `ataxia.data.movement()`, `ataxia.data.db.addChar()`, etc.

**Fix**: Replaced `table.load(path, ataxia)` with a `mergeLoad()` helper that loads into a temp table and merges keys into the existing table, preserving sub-tables that contain runtime functions. Same pattern applied to `ataxiaBasher` load. Added nil guards to `ataxiaBasher_countMobsInRoom()` and `ataxiaBasher_preCombatLdeck()`.

| File | Changes |
|------|---------|
| `ataxia/001_Save_Load_Settings.lua` | Added `mergeLoad()` helper; use it for `ataxia` and `ataxiaBasher` loads |
| `genrunning/002_search_targets.lua` | Nil guard on `ataxia.denizensHere` in `countMobsInRoom()`, nil guard on `ldeckRules` in `preCombatLdeck()` |

---

## 2026-03-08 — Feature: Profile Backup for All Saved Data

Added redundant profile backup alongside existing disk saves. Every save now copies data into a `_ataxia_backup` global table (Mudlet saved variable), providing a fallback if disk files are lost or corrupted. On load, if a disk file is missing, the system automatically restores from the profile backup.

**Backup keys**: `ataxia`, `basher`, `basherpaths`, `ndb`, `extraction`, `slcconfig`, `shaman`, `legenddeck`, `legenddeck_config`, `classDetect`, `gearaudit`, `bars_config`

| File | Changes |
|------|---------|
| `ataxia/001_Save_Load_Settings.lua` | Save: backup 6 datasets to `_ataxia_backup`. Load: fallback from backup for all 6 |
| `shaman_system/002_Save_Load_functions.lua` | Save: backup shaman config. Load: fallback |
| `legend_deck/004_Legend_Deck_Save_Load.lua` | Save: backup deck + config. Load: fallback |
| `class_detect/001_Class_Detect_Engine.lua` | Save: backup classDetect data. Load: fallback |
| `gear_system/001_Gear_Audit.lua` | Save: backup gear data. Load: fallback |
| `build_windows/016_buildVitalBars.lua` | Save: backup bars config. Load: fallback |

**Setup**: Add `_ataxia_backup` as a saved variable in Mudlet's Variables panel (one-time, type: table).

---

## 2026-03-08 — Fix: ataxiaNDB API crash with numeric target (bashing)

Fixed crash in `ataxiaNDB_Exists()` when `target` is a numeric GMCP NPC ID (during bashing). The Prompt Trigger calls `ataxiaNDB_getClass(target)` every prompt, which called `name:title()` on a number. Added type guard `type(name) ~= "string"` in `ataxiaNDB_Exists()` — protects all 50+ NDB API callers across the codebase.

| File | Fix |
|------|-----|
| `ataxia_ndb/003_ataxiaNDB_API.lua` | `ataxiaNDB_Exists()`: reject non-string `name` values (returns `false`) |

---

## 2026-03-08 — User-Facing Command Rename: `levi` → `ataxia`

Renamed all user-facing aliases from `levi` prefix to `ataxia` prefix for consistency with the system name. Internal Lua namespace (`leviSetup`) is unchanged.

| Old Command | New Command |
|-------------|-------------|
| `levi setup` | `ataxia setup` |
| `levi setup class` | `ataxia setup class` |
| `levi setup basher` | `ataxia setup basher` |
| `levi setup sipping` | `ataxia setup sipping` |
| *(all other `levi setup` subcommands)* | *(same with `ataxia setup` prefix)* |
| `levibars` | `ataxiabars` |

Header text in setup wizard changed from "LEVI Setup Wizard" to "Ataxia Setup Wizard".

---

## 2026-03-08 — Nil Guard for `ataxiaBasher.targetList` (F1 Autobash Crash)

Fixed a crash when pressing F1 (autobash) before basher settings were loaded. `search_targets()` accessed `ataxiaBasher.targetList[area]` without checking if `targetList` was initialized, causing a nil index error.

| File | Issue | Fix |
|------|-------|-----|
| `genrunning/002_search_targets.lua` | `ataxiaBasher.targetList` nil before basher settings loaded | Added nil guard: early return if `targetList` is nil |

---

## 2026-03-08 — Nil Guard Fixes for Blind/Startup State

Fixed 8 runtime errors that occurred when logging in blind (no `gmcp.Room` data) or during early connection (incomplete GMCP state).

| File | Issue | Fix |
|------|-------|-----|
| `defence/001_Pre_Apply.lua` | `gmcp.Room.Info.exits` nil when blind | Early return guard |
| `318_Prompt_Trigger.lua` | `ataxiaTables.limbData` nil before init | Wrapped in nil check |
| `016_Targeting_Functions.lua` | `ataxiaTemp.enemies` nil, `ataxia.playersHere` non-table | Default to `{}`, type check |
| `012_Prompt_Substitution.lua` | `ataxiaTemp.mobhealth` nil comparison | Added nil check before `~= 0` |
| `003_ataxia_RoomContents_Update.lua` | `gmcp.Char.Items.List` nil during early connect | Early return guard |
| `006_showAffs.lua` | `target` nil before `:title()` | Added nil check |
| `008_showRoomInfo.lua` | `gmcp.Room.Info` nil when blind | Early return guard |
| `352_Room_Info_Shortener.lua` | `gmcp.Room.Info` nil when blind | Early return guard (already deactivated) |

---

## 2026-03-08 — V3 Affliction Tracker Migration: Single Source of Truth

**Major architecture change**: Migrated from three parallel affliction tracking systems (V1 boolean, V2 certainty, V3 probability) to **V3-only**. The branching probability engine is now the single source of truth, with `tAffs` maintained as a synchronized read cache for backward compatibility.

### Core Changes

**007_Branching_State_Tracker.lua** (V3 engine):
- Set `affConfigV3.enabled = true` permanently
- Removed all toggle guards (`if not affConfigV3.enabled then return end`) from every function
- Removed all `raiseEvent` calls from `applyAffV3()` and `removeAffV3()` — events now owned by public API
- Removed circular `"tar afflicted"` event listener that re-applied affs from V1→V3
- Removed V2 sync block from `syncToOldSystemV3()`
- Removed V2 display delegation from `updateAffDisplayV3()`

**017_Affliction_Management.lua** (public API):
- `haveAff()` now routes to `haveAffV3()` first, with `tAffs` fallback during load order
- `erAff()` now calls `removeAffV3()` internally
- `tarAffed()` now calls `applyAffV3()` internally for each affliction
- All helper functions (`tarSingleAff`, `tarDoubleAff`, `tarTripleAff`, `addAffList`, `tarBonusAff`, `tarZealHit`) updated to call `applyAffV3()`

**008_V3_Integration.lua** (integration layer):
- Simplified all wrapper functions (`targetAteWrapper`, `tarAffedWrapper`, `erAffWrapper`, `haveAffWrapper`) — now thin delegates to public API
- Removed all toggle guards from 14 verification handlers
- Added `treeCurableAffsV3` and `focusCurableAffsV3` cure lists (migrated from V2)
- Added 19 V2 backward-compatibility stubs routing to V3 (`addAffV2`, `removeAffV2`, `haveAffV2`, `targetAteV2`, `onBloodrootApplyConfirmV2`, etc.)
- Removed `enableV3()`, `disableV3()`, `toggleV3()` — replaced with no-op stubs
- `isV3Active()` now always returns `true`

### V2 Deactivation
Set `isActive: 'no'` on 6 V2 files:
- `001_Core.lua`, `002_Herb_Cures.lua`, `003_Backtracking.lua`, `004_Verification.lua`, `005_buildTarAffsV2.lua`, `006_showAffsV2.lua`

### Reset Site Coverage
Added `if resetStatesV3 then resetStatesV3() end` to all 8 `tAffs` reset locations:
- `016_Targeting_Functions.lua`, `001_Login_Function.lua`, `003_TargetOutOfRoom.lua`, `016_RESET.lua`, `011_Reset_Afflictions_on_Target.lua`, `401_Target_Has_Died.lua`, `405_Starburst!.lua`, `010_Phoenix_(BM).lua`

### Offense System Simplification
Simplified 5 class-specific `hasAff()` wrappers to `return haveAff(aff)`:
- `apostate.hasAff()`, `blademaster.hasAff()`, `infernalDWC.hasAff()`, `infernalDWC2L.hasAff()`, `depthswalker.hasAff()`

### Event Architecture
- Events (`"tar afflicted"`, `"target cured aff"`) now fire exclusively from public API (`tarAffed()`, `erAff()`)
- V3 internal functions (`applyAffV3`, `removeAffV3`) no longer raise events — prevents double-firing

### Bug Fixes
- **447_Inundate.lua**: Was bypassing V3 by setting `tAffs` directly. Now calls `tarAffed()` for proper V3 tracking
- **442_Got_Sileris.lua**: Fixed pre-existing typo `"fanbarrier"` → `"fangbarrier"`
- **008_V3_Integration.lua**: Added missing `onBloodrootApplyConfirmV2()` stub

---

## 2026-03-07 — Tekura: Modernize offense with BM/DWC/DWB patterns + fix 6-limb KILL phase

**Improvements applied to both Tekura systems** (001_Tekura_Offense.lua, 002_Tekura_6Limb_Offense.lua):

1. **V3→V2→V1 affliction routing** — `tekura.hasAff()` / `tekura6.hasAff()` replaces raw `tAffs` access. Works with V3 probability, V2 certainty, or V1 boolean tracking.
2. **`wouldBreakLimb()` guard** — Prevents accidental limb breaks during PREP by treating near-break limbs as prepped (DWC pattern).
3. **`attackInFlight` flag** — Anti-desync: prevents `envenomList`-style state corruption while off-balance (DWC pattern).
4. **Target-change auto-reset** — Parry tracking and state automatically cleared when switching targets (DWB pattern).
5. **Echo debounce** — 0.3s guard prevents spam when rapidly pressing attack key (DWB pattern).
6. **Rebounding handling** — New `checkRebounding()` with V1 fallback for GMCP timing gap. Razes rebounding before attacking.
7. **Shield V1 fallback** — `checkShield()` now uses V1 fallback pattern for reliability.
8. **Aeon guard** — Dispatch skipped when under aeon effect.
9. **Centralized `sendAttack()`** — Lock-break check + target presence check before sending (BM pattern).

**Bug fix (both systems)**: KILL phase now uses Bear stance + prone instead of limb damage checks. Bear stance means we already completed the break phases (`;brs` switches to Bear). Previously the 6-limb system required ALL 6 limbs broken (impossible — head never explicitly broken in attack flow), and the 4-limb system checked leg damage that could be cured by the time balance returned. Now: `ataxia.vitals.stance == "Bear" and prone → BBT`.

**Files modified**:
- `src_new/scripts/.../tekura/001_Tekura_Offense.lua` — All 9 improvements
- `src_new/scripts/.../tekura/002_Tekura_6Limb_Offense.lua` — All 9 improvements + KILL phase fix

---

## 2026-03-07 — Monk: Fix Tekura/Shikudo spec detection in zz/xx aliases

**Problem**: Pressing `zz` as a Tekura Monk called `shikudo.dispatch()` unconditionally — wielding a staff and showing `[Shikudo:DISPATCH]` instead of Tekura combat. The `xx` alias had the inverse problem (always called `tekura.dispatch.run()`).

**Fix**: Both aliases now check `ataxia.vitals.stance` (populated from GMCP charstats when Tekura is active). If stance is truthy → Tekura dispatch; otherwise → Shikudo dispatch.

**Files modified**:
- `src_new/aliases/.../152_First_Attack_(All_Classes).lua` — Monk branch: added spec detection
- `src_new/aliases/.../155_Second_Attack_(All_Classes).lua` — Monk branch: added spec detection

---

## 2026-03-07 — Fix literal `<ansi_*>` tags printed as text in cecho() calls

**Problem**: Multiple scripts used `<ansi_yellow>` and `<ansi_light_cyan>` color tags in `cecho()` calls. These rendered as literal text instead of colors (e.g., `<ansi_light_cyan>[Levi]:` in startup, `<ansi_yellow>(44.4%)` in limb damage).

**Fix**: Replaced all `<ansi_*>` tags with standard Mudlet color names: `<ansi_yellow>` → `<yellow>`, `<ansi_light_cyan>` → `<light_cyan>`.

**Files modified** (6 total):
- `src_new/scripts/.../limb/002_limb_management.lua` — limb damage percentage echo
- `src_new/scripts/.../affliction_tracking_core/004_Verification.lua` — softlock echo
- `src_new/scripts/.../affliction_tracking_core/008_V3_Integration.lua` — softlock echo
- `src_new/scripts/.../totem/001_Totem_Checker.lua` — totemChecker.echo()
- `src_new/scripts/.../snipe/001_Snipe_System.lua` — snipe.echo()
- `src_new/scripts/_groups.yaml` — Algedonic.Echo() inline script

---

## 2026-03-07 — Apostate: Fix mental mode impatience loop

**Problem**: Mental mode sent `impatience + paralysis` every round forever. `selectPrimaryCurseMental()` required impatience at 100% V3 probability (`< 1.0`) before advancing to stupidity/dizziness/epilepsy. But the target cures impatience with goldenseal each round, so it never reaches 100%. The goldenseal flood (the whole point of mental mode) never happens.

**Fix**: Changed impatience delivery threshold from 100% to 25% in both primary and secondary mental selectors. Now all mentals use the same 25% "deliver once, move on" threshold. The 100% impatience requirement remains in `mentalReady()` — it gates the *transition to lock*, not delivery.

**Priority reorder**: Removed clumsiness from mental stack. Replaced epilepsy with vertigo (lobelia-cured). New order: impatience → stupidity → dizziness → vertigo. Transition: impatience(100%) + 2 of {stupidity, dizziness, vertigo}.

**Files modified**:
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — Mental selectors: impatience threshold 1.0 → 0.25, removed clumsy, epilepsy → vertigo

---

## 2026-03-07 — Apostate: Fix anorexia not selected when c1=sicken

**Problem**: `selectSecondaryCurse("sicken")` skipped anorexia because it was gated behind `apostate.hasAff("slickness")`, which returned false. When c1=sicken, slickness will be delivered by that same curse round — but the gate didn't account for this. Result: plague selected instead of anorexia.

**Fix**: Added `or c1 == "sicken"` to the anorexia gate, so anorexia is selectable when sicken (slickness delivery) is the primary curse.

**Files modified**:
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — line 341: anorexia gate now checks `c1 == "sicken"`

---

## 2026-03-07 — Apostate: Merge 014 into 015, mental mode updates

**Merge**: Deleted `014_Levi_Apostate.lua` — all backward-compat wrappers, daemon utilities (`bloodworm`, `baalzadeen`, `demon`, `apopentagram`, `bloodPact`, `daemonite`, `fiend`), legacy wrappers (`corruptDmg`, `corruptKill`, `cathCorrupt`), and `nightmare()` tracking moved into `015_CC_Apostate.lua`.

**Mental mode updates**: Priority reordered to clumsiness → impatience → stupidity → dizziness → epilepsy. Clumsiness first for 33% miss hinder. Thresholds changed from 33% to 25% for mentals (impatience stays 100%). Both primary and secondary selectors updated.

**Alias**: `xx` now sets apostate to mental mode (was corrupt). `men` still activates mental mode.

**Files modified**:
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — Absorbed all 014 content; mental mode reordered + thresholds adjusted
- `src_new/scripts/.../apostate/014_Levi_Apostate.lua` — Deleted
- `src_new/aliases/.../155_Second_Attack_(All_Classes).lua` — Apostate block: corrupt → mental

---

## 2026-03-07 — Fix: Chat channel colors not applied in miniconsoles

**Problem**: Most chat channel colors (tells=yellow, says=cyan, clan=white, etc.) appeared as white/default in the GUI chat miniconsoles. Only channels with exact GMCP name matches (like `"shout"`) showed their configured color.

**Root cause**: The color lookup used exact key match (`channelColors[gmcp.Comm.Channel.Start]`), but Achaea's GMCP channel names include suffixes — e.g., `"tells Proficy"` for tells, `"clt Holocaust Inc"` for clans. The exact lookup for `"tells Proficy"` against key `"tell"` returned nil → fell back to `"<white>"`. Window routing already worked because it used `string.starts()` prefix matching.

**Fix**: Added `getChannelColor(ch)` helper that iterates `channelColors` with `string.starts()` prefix matching, replacing the exact key lookup. Applied to both chat display files.

**Files modified**:
- `scripts/.../update_windows/001_showChat.lua` — Added `getChannelColor()`, replaced exact lookup
- `scripts/.../gui_stuff/003_Chat_Capture_Things.lua` — Added `getChannelColor()`, replaced exact lookup

**Shout color**: Changed from red → teal (`<teal>`) in both files.

---

## 2026-03-07 — ClassDetect: Shikudo differentiation + defence priority re-application

**Problem 1**: ClassDetect treated all monks as "Monk", switching to the `monk` curingset even for Shikudo (staff) monks who need the `shikudo` curingset.

**Fix**: The Monk Class Grab trigger now inspects the matched line text for weapon keywords (`whips`, `staff`, `thrust`, `kata`, `sweeps`) to distinguish Shikudo from Tekura. Added `["Shikudo"] = "shikudo"` to `curingsetMap`. Updated anti-Shikudo parry check to accept `attackerClass == "Shikudo"` directly.

**Problem 2**: After switching curingsets, SSC re-applied the curingset's own defence priority list, which may include abilities the player doesn't have (e.g., toughness, shin for a non-BM). This caused "I don't know what X does" spam.

**Fix**: Added `classDetect.reapplyDefencePriorities()` — after every curingset switch, sends `curing priority defence list reset` to wipe the curingset's embedded list, then re-sends the player's own defence profile from `ataxia.settings.defences.defup[current]` using `curing priority defence ... 25`, matching the pattern in `systemDefup()`.

**Problem 3**: Shikudo monks also use kicks (no weapon keywords), causing ClassDetect to flip-flop between "Shikudo" and "Monk" on alternating attack lines. This triggered repeated curingset switches.

**Fix**: Trigger action now checks if the attacker is already identified as Shikudo — if so, kick-only lines just reset the combat timeout instead of downgrading to "Monk".

**Problem 4**: The `362_Shikudo_Bashing_Error` trigger had an overly broad regex (`^I'm sorry, I don't know what "(\w+)" does\.$`) that matched ALL unknown ability errors, not just livestrike. The defence priority spam ("toughness", "shin", "weathering") triggered this, calling `ataxiaBasher_attack()` when the basher wasn't initialized, causing nil errors on `ataxiaBasher.noShieldBreak` and `ataxiaBasher.targetList`.

**Fix**: Removed the broad regex pattern — trigger now only matches the specific livestrike error messages it was designed for.

**Files modified**:
- `triggers/.../determine_class/006_Monk_Class_Grab.lua` — Shikudo vs Tekura keyword detection + no-downgrade guard
- `scripts/.../class_detect/001_Class_Detect_Engine.lua` — Added `["Shikudo"]` to curingsetMap, added `reapplyDefencePriorities()` with defence list reset, called from `switchCuringset()`
- `scripts/.../self_limb_tracking/003_Parrying.lua` — Updated `isShikudo` check to accept `attackerClass == "Shikudo"` directly
- `triggers/.../362_Shikudo_Bashing_Error.lua` — Removed overly broad regex pattern, kept only specific livestrike patterns

---

## 2026-03-07 — Fix: GMCP nil errors when blind

**Problem**: When the player is blind, the server stops sending `gmcp.Room` data (and sometimes `gmcp.Char`), causing `gmcp.Room` to be `nil`. Five triggers accessed `gmcp.Room.Info.*` and `gmcp.Char.*` without nil guards, producing a flood of errors on every prompt line.

**Root cause**: Lua pattern conditions (type 4) in map-switching triggers and inline code in prompt triggers indexed into `gmcp.Room.Info` and `gmcp.Char.Status` directly, with no nil check for the parent tables.

**Fix**: Added nil guards (`gmcp.Room and gmcp.Room.Info and ...`) to all unprotected GMCP accesses. When blind, these triggers now silently skip instead of erroring.

**Files modified**:
- `triggers/.../wilderness_map/002_GMCP_Rooms.lua` — Nil guard on pattern conditions (`gmcp.Room.Info.num`)
- `triggers/.../wilderness_map/003_GMCP_Wilderness.lua` — Nil guard on pattern conditions (`gmcp.Room.Info.num`, `.coords`)
- `triggers/.../wilderness_map/004_GMCP_Oceans.lua` — Nil guard on pattern conditions (`gmcp.Room.Info.environment`, `.num`)
- `triggers/.../leviticus/318_Prompt_Trigger.lua` — Nil guard on `gmcp.Char.Status.class` (BM/Monk/Magi checks) and `gmcp.Room.Info.name` (flying check)
- `triggers/.../leviticus/276_Limb_Prompt.lua` — Nil guard on `gmcp.Char.Status.class` and `gmcp.Char.Vitals.charstats` (DWB momentum check)

---

## 2026-03-07 — Configurable movable vital bars (`levibars`)

**New feature**: Individually movable, configurable gauge bars for Health, Mana, Willpower, Endurance, and Cape (shoulder cape kill tracker). Each bar is an `Adjustable.Container` with auto-save/load positions.

**Files created**:
- `build_windows/016_buildVitalBars.lua` — Full `ataxia.bars` namespace: build, show/hide, toggle, reset, update, config save/load
- `aliases/zgui_redux/007_(LEVIBARS)_Vital_Bars.lua` — `^levibars(?: (.+))?$` alias

**Files modified**:
- `gui_stuff/004_Vitals_Related.lua` — Added `ataxia.bars.update()` call in `ataxiagui_updateVitals()`
- `update_windows/007_showCape.lua` — Added `ataxia.bars.updateCape()` calls in `zgui.showCape()` and `zgui.clearCape()`
- `039_EDIT_ME__Startup_Main.lua` — Added `ataxia.bars.buildAll()` call after module dispatch

**Usage**: `levibars` (status), `levibars on/off` (master toggle), `levibars health/mana/willpower/endurance/cape` (individual toggle), `levibars reset` (reset positions). Default: health+mana+cape on, willpower+endurance off, master disabled.

---

## 2026-03-07 — Fix: Chat window shows raw ANSI codes

**Problem**: Chat miniconsoles displayed raw ANSI escape sequences as visible text (e.g., `[0;37m`, `[0;1;36m`) because GMCP text contains embedded ANSI codes that `cecho()` doesn't interpret.

**Fix**: Added `stripAnsi()` helper to strip ANSI escape sequences before passing text to `cecho()`. Applied in both chat display paths.

**Files modified**:
- `update_windows/001_showChat.lua` — Added `stripAnsi()`, applied to GMCP text
- `gui_stuff/003_Chat_Capture_Things.lua` — Same fix
- Both files: removed duplicate YAML headers

---

## 2026-03-07 — Fix: `an refresh` and auto-honours now capture mark/army/dauntless

**Problem**: Both `an refresh` and the hidden-city auto-honours used `send("honours", false)` which bypasses the Mudlet alias system. The NDB capture triggers (`Get Player Information`, `Check Player City`) were never enabled, so mark, army rank, and dauntless data was silently lost during bulk honours.

**Fix**: Rewrote both systems to use `ataxiaNDB_processRefreshQueue()` — a sequential queue processor that properly sets `_honoursPerson`, enables capture triggers, sends `honours`, and chains to the next player after Close Capturing completes. Includes 8s safety timeout per player.

**Files modified**:
- `006_ataxiaNDB_Success.lua` — Added `ataxiaNDB_processRefreshQueue()` and `ataxiaNDB_onHonoursCaptureComplete()`. Rewrote `ataxiaNDB_drainHonoursQueue()` to use the new queue mechanism.
- `002_Close_Capturing.lua` (trigger) — Added call to `ataxiaNDB_onHonoursCaptureComplete()` to advance the refresh queue after each capture.

---

## 2026-03-07 — NDB: Auto-honours hidden-city players + `an refresh` command

**Files**: `006_ataxiaNDB_Success.lua`, `198_Refresh_Honours.lua` (new)

**Feature 1 — Auto-honours hidden cities**: When the API returns `(hidden)` for a player's city and no prior city is known, the system now queues an automatic `honours` lookup instead of showing a warning. Hidden-city names are collected during the API batch and drained with 2s spacing after the batch completes.

**Feature 2 — `an refresh [city]`**: New alias to send `honours` for all tracked players (or filtered by city) to update mark, army rank, and dauntless status — data only available from in-game `honours`, not from the API. Uses sequential honours capture with proper trigger setup.

---

## 2026-03-07 — Namespace rename: zData → ataxia.data + buildHunter fix

**Problem**: The hunting statistics system (`zData`) used a legacy namespace inconsistent with the standardized `ataxia` namespace. Additionally, `buildHunter` crashed with `attempt to call method 'loadPosition' (a nil value)` on some Mudlet versions.

**Fix — Namespace rename** (`zData` → `ataxia.data`):
- `src_new/scripts/_groups.yaml` — Inline init script: all `zData` refs → `ataxia.data`. Added backward-compat shim `zData = ataxia.data` at end of init block. Group names unchanged (build hierarchy).
- `src_new/scripts/.../zdata/001_Experience_Database.lua` — All `zData` → `ataxia.data`
- `src_new/scripts/.../zdata/002_movement.lua` — All `zData` → `ataxia.data`
- `src_new/scripts/.../zdata/004_buildHunter.lua` — All `zData` → `ataxia.data`
- `src_new/aliases/.../zdata/001_(zBash).lua` — All `zData` → `ataxia.data`
- `src_new/triggers/.../zdata/001-014` — All Lua code `zData` → `ataxia.data` (YAML hierarchy names unchanged)
- `src_new/triggers/.../highlighting/014_Paragon.lua` — `zData` → `ataxia.data`

**Fix — buildHunter loadPosition**: Wrapped `loadPosition()` call in nil check (`if window.loadPosition then`) for Mudlet version compatibility.

**Fix — buildChat startup**: Added `zgui.buildChat = ataxia.buildChat` shim after function definition in `012_buildChat.lua`. The startup module dispatch (`039_EDIT_ME__Startup_Main.lua` lines 89-91) calls `zgui["buildChat"]()` — after the previous rename to `ataxia.buildChat()`, this was nil and the chat never built at startup.

---

## 2026-03-07 — Bugfix: NDB alias crashes on unknown classes

**Files**: `186_Show_Class_Count.lua`, `187_Show_City_Count.lua`, `190_Tracked_of_class.lua`

**Root cause**: The `an classes` and `an cclasses` aliases had hardcoded `classes` tables missing Unnamable, Airlord, Earthlord, Firelord, and Waterlord. When a tracked player had one of these classes, `table.insert(classes[tab.class], ...)` crashed with "bad argument #1 to 'insert' (table expected, got nil)". The `an class` alias was also missing these classes from its `classList` used for the "Classless" filter.

**Fix**:
- Added all 5 missing classes to `classList` in all 3 alias files
- Replaced hardcoded `classes` table with dynamic construction from `classList`
- Added nil guard: `if not classes[tab.class] then classes[tab.class] = {} end`
- Added nil guard on `tab.class` and `tab.level` checks
- Added `math.max(0, ...)` guard on `string.rep` padding (prevents crash on long class names)
- Added nil guard on highlighting colour lookup in `an cclasses` (prevents crash for unknown city)

---

## 2026-03-07 — ClassDetect: Differentiate Shikudo from Tekura monks

**Problem**: ClassDetect set `attackerClass = "Monk"` for all monk attacks, switching to the generic `monk` curingset. Shikudo monks (staff-based) need the `shikudo` curingset for different curing priorities.

**Fix**:
- `src_new/triggers/.../determine_class/006_Monk_Class_Grab.lua` — Action now checks `line` for weapon keywords (`whips`, `staff`, `thrust`, `kata`, `sweeps`). Staff attacks → `"Shikudo"`, bare fist/kick attacks → `"Monk"` (Tekura).
- `src_new/scripts/.../class_detect/001_Class_Detect_Engine.lua` — Added `["Shikudo"] = "shikudo"` to `curingsetMap`.
- `src_new/scripts/.../self_limb_tracking/003_Parrying.lua` — Anti-Shikudo parry check now accepts `attackerClass == "Shikudo"` directly (in addition to legacy `"Monk"` + `shikudostance` fallback).

**Note**: Run `csd setup` in-game to create the `shikudo` curingset if it doesn't exist yet.

---

## 2026-03-07 — Chat: Channel colors + namespace rename (zgui.chat → ataxia.chat)

**Problem**: Chat miniconsoles showed mostly white/uncolored text. The `showChat()` function relied on `ansi2decho(gmcp.Comm.Channel.Text.text)` which doesn't carry the same ANSI coloring as the main console telnet stream. Only `shout` had custom color treatment. Additionally, the chat system used the legacy `zgui.chat` namespace instead of the standardized `ataxia` namespace.

**Fix — Channel colors**:
- `src_new/scripts/.../update_windows/001_showChat.lua` — Added `channelColors` map matching Achaea's CONFIG COLOUR (says=cyan, ct=red, ht/tell=yellow, party=magenta, newbie=green, etc.). Replaced `decho()` with `cecho()` using channel color for full message. Removed shout-only special case (now handled by color map). Removed unused `ansi2decho()` conversion.
- `src_new/scripts/.../gui_stuff/003_Chat_Capture_Things.lua` — Same channel color map and `cecho()` replacement for the ataxiagui chat handler.

**Fix — Namespace rename** (`zgui.chat` → `ataxia.chat`, `zgui.chatSize` → `ataxia.chatSize`):
- `src_new/scripts/.../build_windows/012_buildChat.lua` — `zgui.buildChat()` → `ataxia.buildChat()`, all `zgui.chat` → `ataxia.chat`
- `src_new/scripts/.../build_windows/013_Chat_Cmd_Prompt.lua` — `zgui.chatSend` → `ataxia.chatSend`, all `zgui.chat` → `ataxia.chat`
- `src_new/aliases/.../zgui_redux/006_(ZCHAT)_Toggle_Chat_Command_Line.lua` — Alias renamed `zchat` → `ataxiachat`, all `zgui.chat` → `ataxia.chat`
- `src_new/aliases/.../zgui_redux/002_(ZGUIS)_zGUI_Size.lua` — `zgui.chatSize` → `ataxia.chatSize`
- `src_new/scripts/.../039_EDIT_ME__Startup_Main.lua` — `zgui.chatSize` → `ataxia.chatSize`

---

## 2026-03-07 — Apostate: Disfigure fires on asthma round + CORRUPT V2/V3 reset

**Files modified**:
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — Moved disfigure from manaleech round to asthma round (probes whether target smokes before committing manaleech). Removed `gmcp.Char.Vitals.bal == "1"` guard that prevented disfigure from firing when dispatch was called from reboundHold callback. **Fixed orphaned disfigure**: `queue add free` approach failed because deadeyes ends up in Achaea's auto-queue (not the manual freestand queue), which fires first on balance return and consumes balance — the `free` queue's disfigure then waits for the NEXT balance return and fires alone. Fix: replaced with a one-shot `tempTrigger("curse of asthma", ...)` that sends disfigure when deadeyes text appears in the same server output batch. Trigger cleanup on mode change, target change, and non-asthma rounds.
- `src_new/triggers/.../apostate/007_CORRUPT.lua` — Added `resetAffsV2()` and `resetStatesV3()` calls after `expandAlias("res")`. Demon corrupt resets all target afflictions but the trigger only cleared V1 (via `res` alias). V2 certainty tracking and V3 probability branching states were stale after corrupt.

---

## 2026-03-07 — Full ataxiaNDB Overhaul (7 Phases)

Comprehensive overhaul of the player database system across 7 phases: critical bug fixes, case normalization, hash table conversions, namespace cleanup, robustness improvements, code quality polish, and new features.

### Phase 1: Critical Bug Fixes

**Files modified**:
- `src_new/scripts/.../ataxia_ndb/003_ataxiaNDB_API.lua` — Fixed `ataxia_Echo(...)` typo → `ataxiaEcho(...)`. Added nil guard on `io.open` in `ataxiaNDB_Remove`. All `string.rep` padding calls guarded with `math.max(0, ...)` to prevent crash on long names.
- `src_new/scripts/.../ataxia_ndb/006_ataxiaNDB_Success.lua` — Wrapped `yajl.to_value(s)` in `pcall` with error handling (removes corrupt JSON file on failure). Added nil guards on all API response fields (`t.house`, `t.city`, `t.class`, `t.level`, `t.xp_rank`, `t.player_kills`). Added nil guard on `io.open`. Changed string timer `tempTimer(3, [[honoursPerson = nil]])` to function closure.
- `src_new/scripts/.../ataxia_ndb/007_ataxiaNDB_Failed.lua` — Fixed Windows path separator: `filepath:match("[/\\]([%w_]+)%.json")` (was Unix-only `/`).
- `src_new/scripts/.../ataxia_ndb/005_ataxiaNDB_Display_API.lua` — All `string.rep` padding calls guarded with `math.max(0, ...)`. Added unknown class guard in `displayOnlineClass` (creates bucket dynamically). Added missing classes to classList: Pariah, Psion, Unnamable, Dragon, Airlord, Earthlord, Firelord, Waterlord. Fixed typo "acqusition" → "acquisition" (×2).

### Phase 2: Case Normalization

**Files modified**:
- `src_new/scripts/.../ataxia_ndb/003_ataxiaNDB_API.lua` — Standardized all API functions to use `name:title()` for player lookups: `ataxiaNDB_Exists`, `ataxiaNDB_isMark`, `ataxiaNDB_armyRank`, `ataxiaNDB_getColour`, `ataxiaNDB_getCitizenship`. Removed all dead underworld branches from `getColour` and `getCitizenship`. Simplified `getColour` to a single highlighting table lookup.

### Phase 3: Hash Table Conversions

**Files modified**:
- `src_new/scripts/.../ataxia_ndb/001_Ataxia_NDB_Settings.lua` — Converted `divine` from array to hash (`{Aegis=true, Artemis=true, ...}`). Removed `Underworld = "a_brown"` from highlighting table.
- `src_new/scripts/.../ataxia_ndb/002_Get_Information.lua` — Changed `table.contains(ataxiaNDB.divine, name)` → `ataxiaNDB.divine[name]` for O(1) lookup.
- `src_new/scripts/.../ataxia_ndb/003_ataxiaNDB_API.lua` — Same divine hash lookup change. Converted `apiOnlineFound` dedup from O(n²) `table.contains` to set-based O(1) dedup.
- `src_new/scripts/.../ataxia_ndb/007_ataxiaNDB_Failed.lua` — Converted blacklist to hash: `ataxiaNDB.notPlayers[name] = true` with hash-based `ataxiaNDB_isBlacklisted` using `:title()` fallback.
- `src_new/scripts/.../001_Save_Load_Settings.lua` — Added `migrateArrayToHash()` function that runs after `table.load` to convert existing array-format `notPlayers` and `divine` saves to hash format on first load.

### Phase 4: Namespace & Globals Cleanup

**Files modified**:
- `src_new/scripts/.../ataxia_ndb/002_Get_Information.lua` — `ndbWatcher` → `ataxiaNDB._watcher`. Removed redundant `ataxiaNDB_isBlacklisted and` nil checks.
- `src_new/scripts/.../ataxia_ndb/003_ataxiaNDB_API.lua` — `apiOnlineFound` → `ataxiaNDB._onlineFound` (made `apiNeedUpdate` local as it's only used within `SortOnline`).
- `src_new/scripts/.../ataxia_ndb/005_ataxiaNDB_Display_API.lua` — `parsingCity` → `ataxiaNDB._parsingCity`. Uses `ataxiaNDB._onlineFound`.
- `src_new/scripts/.../ataxia_ndb/006_ataxiaNDB_Success.lua` — `honoursPerson` → `ataxiaNDB._honoursPerson`.
- `src_new/triggers/.../745_Get_Player_Information.lua` — Uses `ataxiaNDB._honoursPerson`, `ataxiaNDB._mark`, `ataxiaNDB._armyRank`, `ataxiaNDB._dauntless`.
- `src_new/triggers/.../additional_information_ndb/001_Check_Player_City.lua` — `honoursPerson` → `ataxiaNDB._honoursPerson`.
- `src_new/triggers/.../additional_information_ndb/002_Close_Capturing.lua` — All globals namespaced: `honoursPerson`, `NDBIsMark`, `NDBARank`, `NDBIsDauntless` → `ataxiaNDB._honoursPerson`, `ataxiaNDB._mark`, `ataxiaNDB._armyRank`, `ataxiaNDB._dauntless`.
- `src_new/triggers/.../additional_information_ndb/003_Army_Rank.lua` — `NDBARank` → `ataxiaNDB._armyRank`.
- `src_new/triggers/.../additional_information_ndb/004_Ivory_Mark.lua` — `NDBIsMark` → `ataxiaNDB._mark`.
- `src_new/triggers/.../additional_information_ndb/005_Quisalis_Mark.lua` — `NDBIsMark` → `ataxiaNDB._mark`.
- `src_new/aliases/.../182_Honours_Person.lua` — `honoursPerson` → `ataxiaNDB._honoursPerson`.
- `src_new/aliases/.../181_Parse_QWHO.lua` — `parsingCity` → `ataxiaNDB._parsingCity`.

### Phase 5: Robustness

**Files modified**:
- `src_new/scripts/.../ataxia_ndb/004_ataxiaNDB_Highlighting.lua` — Removed `collectgarbage("stop")` and `collectgarbage()` GC hack. Switched string callbacks to function closures for `tempTrigger` (faster, no `loadstring`). Added event handler dedup with `ataxiaNDB._highlightHandlerId` (kills old handler before re-registering). Function closure for `enemyHighlights` timer. Removed `"underworld"` from `updateHighlights` condition.
- `src_new/scripts/.../ataxia_ndb/003_ataxiaNDB_API.lua` — Clean trigger ref on `ataxiaNDB_Remove` (`killTrigger` + nil assignment).

### Phase 6: Code Quality Polish

**Files modified**:
- `src_new/scripts/.../ataxia_ndb/005_ataxiaNDB_Display_API.lua` — Cached `getCitizenship` in `displayOnline` (was calling twice per player). Removed underworld from `displayOnline` (`underworld = {}` bucket and dead branch).
- `src_new/scripts/.../ataxia_ndb/003_ataxiaNDB_API.lua` — Simplified verbose boolean patterns in `ataxiaNDB_isEnemy`, `ataxiaNDB_Exists`, `ataxiaNDB_isCitizenOf`.

### Phase 7: New Features — Dauntless Tracking & Lookup Commands

**New files**:
- `src_new/triggers/.../additional_information_ndb/006_Dauntless.lua` — New trigger capturing `^(He|She|Fae) is one of The Dauntless\.$` from honours output. Sets `ataxiaNDB._dauntless = true`.
- `src_new/aliases/.../194_Show_Marks.lua` — `an marks [city]` alias: lists all tracked Mark members (Ivory/Quisalis), optionally filtered by city. Sorted alphabetically, color-coded by city.
- `src_new/aliases/.../195_Show_Army.lua` — `an army [city]` alias: lists all tracked army members sorted by rank descending. Rank 3+ highlighted in red (attackable for sanctions).
- `src_new/aliases/.../196_Show_Dauntless.lua` — `an dauntless [city]` alias: lists all tracked Dauntless members, color-coded by city.
- `src_new/aliases/.../197_Show_Threats.lua` — `an threats [city]` alias: combined threat view showing marks + army rank 3+ + dauntless with counts per category.

**Files modified**:
- `src_new/triggers/.../745_Get_Player_Information.lua` — Added `ataxiaNDB._dauntless = false` initialization alongside existing mark/army inits.
- `src_new/triggers/.../additional_information_ndb/002_Close_Capturing.lua` — Added dauntless save/clear block (sets `.dauntless = true` or clears to nil). Added `ataxiaNDB._dauntless = nil` cleanup.
- `src_new/scripts/.../ataxia_ndb/003_ataxiaNDB_API.lua` — Added `ataxiaNDB_isDauntless(name)` function.
- `src_new/scripts/.../ataxia_ndb/005_ataxiaNDB_Display_API.lua` — Added dauntless display in `displayWho`: shows "The Dauntless" line when player is dauntless.
- `src_new/scripts/.../ataxia_ndb/006_ataxiaNDB_Success.lua` — Preserves dauntless status across API refresh (`local isDauntless = ataxiaNDB_isDauntless(name)` before player record overwrite).

---

## 2026-03-07 — Bugfix: CORRUPT trigger resets V2 and V3 affliction tracking

**Files modified**:
- `src_new/triggers/.../apostate/007_CORRUPT.lua` — Added `resetAffsV2()` and `resetStatesV3()` calls after `expandAlias("res")`. Corrupt clears all afflictions on the target, but the trigger only reset V1 (`tAffs` via `res` alias). V2 certainty table and V3 branching states retained stale afflictions, causing the offense system to think afflictions were still present after corrupt fired.

---

## 2026-03-07 — Fix: Disfigure fires on asthma round instead of manaleech

**Files modified**:
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — Moved disfigure from manaleech round to asthma round. Disfigure now fires inline (`;` separator) with the deadeyes that delivers asthma, acting as an asthma probe: if target smokes before next balance, asthma was cured → skip manaleech (smoke-cured, wasted without asthma). If they don't smoke → asthma confirmed → safe to push manaleech. Also changed `disfigureSent` flag reset from manaleech to asthma gating. Removed debug echoes. Changed separator from `::` to `;` for same-tick execution (bal + eq).

---

## 2026-03-07 — Performance: SLC event handler accumulation + hot path optimization

**Files modified**:
- `src_new/scripts/.../self_limb_tracking/002_Track_The_Damage.lua` — **Critical**: Fixed event handler accumulation on script reload — `registerAnonymousEventHandler` for `"aff gained"`, `"aff cured"`, and `"self limb damaged"` now stores handler IDs and kills old ones before re-registering. Previously, each reload added duplicate handlers (N reloads = N redundant GUI redraws per damage event). Also debounced GUI updates with dirty-flag + `tempTimer(0)` to coalesce rapid hits into single redraw. Moved `shortNames` table to module-level `SHORT_NAMES` constant
- `src_new/scripts/.../self_limb_tracking/003_Parrying.lua` — Moved per-call `limbList` table allocation to module-level `LIMB_LIST` constant (was allocating identical 6-entry table every prompt)
- `src_new/scripts/.../self_limb_tracking/004_Defensive_Reactions.lua` — Fixed event handler accumulation: `"self limb threshold"` handler now cleaned up on reload. Added aeon check to auto-shield (prevents wasting shield tattoo under aeon). Added per-limb `partyCalloutSent` flag to prevent party callout spam (resets when limb returns to safe)

---

## 2026-03-07 — Bugfix: Anti-Shikudo parry never activating + safety fixes

**Files modified**:
- `src_new/scripts/.../self_limb_tracking/003_Parrying.lua` — Fixed critical case mismatch: `attackerClass == "monk"` → `"Monk"` (class detect engine stores titlecase). Anti-Shikudo parry was completely inert. Also wrapped Tykonos/Maelstrom recursive fallback in `pcall` so `cfg.antiShikudo` is always restored even on error
- `src_new/scripts/.../010_Prompt_Running.lua` — Changed hardcoded `tempTimer(3, ...)` parry spam cooldown to use `selfLimbDamage.config.parrySpamCooldown` (configurable, default 3s)

---

## 2026-03-07 — Bugfix: Double `onHerbCureV3()` calls in herb triggers + 002/004 fixes

**Files modified (round 1 — redundant V3 calls)**:
- `src_new/triggers/.../herbs/001_Goldenseal(U).lua` — Removed redundant `onHerbCureV3("goldenseal")` call
- `src_new/triggers/.../herbs/003_Kelp_(Unknown).lua` — Removed redundant `onHerbCureV3("kelp")` call
- `src_new/triggers/.../herbs/006_Ash.lua` — Removed redundant `onHerbCureV3("ash")` call
- `src_new/triggers/.../herbs/007_Ginseng.lua` — Removed redundant `onHerbCureV3("ginseng")` call
- `src_new/triggers/.../herbs/008_Ginseng_with_Flushings.lua` — Removed redundant `onHerbCureV3("ginseng")` call
- `src_new/triggers/.../herbs/009_Bellwort_Cuprum.lua` — Removed redundant `onHerbCureV3("bellwort")` call
- `src_new/triggers/.../herbs/010_Lobelia.lua` — Removed redundant `onHerbCureV3("lobelia")` call

**Root cause**: 7 herb triggers called `targetAteWrapper(herb)` (which internally calls `onHerbCureV3(herb)` when V3 is enabled) AND then directly called `onHerbCureV3(herb)` again. This caused V3 to model two herb cures per eat instead of one, halving affliction probabilities (e.g., 67% → 33%). The apostate `selectPrimaryCurse()` checks `asthmaProb >= 0.33` — with halved probabilities, asthma at 33% borderline fell into the wrong branch, selecting clumsy instead of manaleech.

**Files modified (round 2 — agent review findings)**:
- `src_new/triggers/.../herbs/004_Goldenseal_(Mycalium).lua` — Changed `targetAteWrapper("mycalium")` → `targetAteWrapper("goldenseal")`. "mycalium" is an affliction name, not a herb — `getCurableAffs("mycalium")` returned nil, making the wrapper a silent no-op for all tracking systems (V1/V2/V3). Also removed now-redundant direct `onHerbCureV3("goldenseal")` call. Added `removeAffV3("mycalium")` alongside existing `erAff("mycalium")` for V3 consistency.
- `src_new/triggers/.../herbs/002_Goldenseal_(Madness).lua` — Replaced manual `erAff("anorexia")` + `removeAffV3("anorexia")` + direct `onHerbCureV3("goldenseal")` with `targetAteWrapper("goldenseal")` for proper V1/V2/V3 routing (was missing V2 tracking entirely). Added `removeAffV3("shadowmadness")` alongside existing `erAff("shadowmadness")`. Anorexia clearing is now handled inside `targetAteWrapper()`.

**Not changed**: 005_Bloodroot_TEST — has custom V2 handler `onTargetBloodrootV2()` + direct `onHerbCureV3("bloodroot")`, functionally correct as-is.

---

## 2026-03-07 — Feature: SLC (Self Limb Counter) Complete Revamp

**Files modified**:
- `src_new/scripts/.../self_limb_tracking/001_Different_Attacks.lua` — Cleaned up dead code: removed all empty `confirm_*`/`confirmed_*` functions and tempLineTrigger chains, replaced with single `highlightLimb()` helper
- `src_new/scripts/.../self_limb_tracking/002_Track_The_Damage.lua` — Major rewrite: added full config system with defaults merge, per-limb threshold tracking (safe/warning/critical/broken), configurable torso break detection (100% instead of 97% guess), `"self limb threshold"` and `"self limb damaged"` events, updated GUI with hits-to-break display + `[P]` parry marker + `[!!]`/`[!]` indicators, color-coded thresholds
- `src_new/scripts/.../self_limb_tracking/003_Parrying.lua` — Complete rewrite: replaced broad 25/50/75% damage brackets with precise hits-to-break priority weights from config (`parryWeights`), added anti-Shikudo dynamic parry intelligence (stance-aware: Willow=legs with alternation, Rain=arms, Oak/Gaital=head with hyperfocus fallback to legs)
- `src_new/scripts/.../self_limb_tracking/004_Defensive_Reactions.lua` — **New file**: event-driven defensive reactions listening to `"self limb threshold"` — SSC priority (`curing prioaff`), auto-shield on critical, party callout, class-specific ability framework
- `src_new/aliases/.../slc/005_SLC_Toggle.lua` — **New file**: `slc` runtime toggle alias (`slc on/off`, `slc shield/party/ssc/warn/crit/shikudo on/off`, `slc parry <mode>`, `slc reset`, `slc gui`)
- `src_new/scripts/.../001_Save_Load_Settings.lua` — Added `selfLimbDamage.config` to save/load cycle (persisted as separate `slcconfig` file)
- `src_new/scripts/.../misc_scripts/020_Setup_Wizard.lua` — Added `levi setup slc` section with interactive toggle display and threshold configuration
- `src_new/triggers/.../035_reset.lua` — Rewired from legacy `slc.hitcount` to `ataxia_clearLimbDamage()`
- `src_new/triggers/.../036_Limb_healed.lua` — Rewired from legacy `slc.hitcount` to `ataxia_clearLimbDamage()`

**Files deactivated** (legacy SLC, `isActive: 'no'`):
- `src_new/scripts/.../slc/001_functions.lua`
- `src_new/scripts/.../slc/002_slc_variables.lua`
- `src_new/aliases/.../slc/001_SLC_Display.lua`
- `src_new/aliases/.../slc/002_SLC_Reset.lua`
- `src_new/aliases/.../slc/003_SLC_Set_#_of_Hits_Needed.lua`
- `src_new/aliases/.../slc/004_SLC_geyser_toggle.lua`

**What changed**: The game now shows exact limb damage percentages (e.g., "dealt 13.7% damage to your torso"). The old SLC was a hit-count estimator — obsolete. The new system:
- Tracks exact damage % per limb with threshold states (safe → warning → critical → broken)
- Fires events on threshold transitions for defensive automation
- Smart parry: weight-based algorithm using hits-to-break, configurable per mode (stand/defend/manual/random)
- Anti-Shikudo: dynamic parry that reads opponent's stance and adjusts targets (Willow→legs, Rain→arms, Oak/Gaital→head with hyperfocus detection)
- Full defensive suite: SSC priority changes, auto-shield, party callouts, class ability framework
- Every feature independently toggleable via `slc` alias or `levi setup slc`
- Config persists across sessions via save/load system

---

## 2026-03-07 — Fix: Nil-guard 7 startup/runtime Lua errors

**Files modified**:
- `src_new/scripts/.../016_Targeting_Functions.lua` — `isTargeted()`: added nil guard for `target` global
- `src_new/scripts/.../deffing/003_Defence_Reporting.lua` — `ataxia_reportDefences()`: early return when `ataxia.settings.defences` uninitialized
- `src_new/scripts/.../basher/001_Bashing_Functions.lua` — guarded two `ataxiaBasher.fleeThreshold` comparisons against nil
- `src_new/scripts/.../039_EDIT_ME__Startup_Main.lua` — guarded zgui module function call in startup loop
- `src_new/scripts/.../login/001_Login_Function.lua` — guarded `slc_reset`/`slc_force_display` calls (functions may not exist)
- `src_new/scripts/.../ataxia_ndb/004_ataxiaNDB_Highlighting.lua` — fallback to Rogues colour when city not in highlighting table
- `src_new/triggers/.../chasing/002_PEOPLE_CAPTURE.lua` — quoted bare `north` identifier to string `"north"`

**Problem**: Seven different nil-value errors fired on login and during gameplay — `attempt to index global 'target'`, `attempt to index field '?'`, `attempt to compare number with nil`, `attempt to call field '?'`, `attempt to call global 'slc_force_display'`, `bad argument #1 to 'format'`, and `attempt to concatenate global 'movedirection'`.

**Fix**: Added defensive nil guards to all 7 locations. Each fix is a minimal early-return or fallback — no architectural changes.

Also removed unused Targeting keybind group (6 keys: Left Leg, Right Leg, Torso, Head, left_arm, Right_Arm) from `src_new/keys/` and `_groups.yaml`.

---

## 2026-03-06 — Fix: Alias `regex:` fields not parsed by converter

**Files modified**:
- `tools/convert_to_muddler.py` — `fallback_yaml_parse()`

**Problem**: Aliases with unquoted `regex:` values containing YAML special characters (e.g., `^snt(?: (.+))?$`) failed primary YAML parsing. The fallback parser only fixed `pattern:` lines but not `regex:` lines, causing the file to be silently skipped with a "No YAML header" warning. The Snipe alias (`003_Snipe.lua`) was missing from the built package because of this.

**Fix**: Extended fallback parser regex from `pattern:` to `(?:pattern|regex):` so both trigger patterns and alias regexes are auto-quoted when they contain special YAML characters.

---

## 2026-03-06 — Feature: Snipe system uses SHOOT for knight classes

**Files modified**:
- `src_new/scripts/.../snipe/001_Snipe_System.lua`

**Change**: Runewarden and Infernal classes use `shoot` (Weaponmastery) instead of `snipe` (Subterfuge). Added `snipe.getCommand()` helper that checks `gmcp.Char.Status.class` and returns the correct command. The `snt` alias, success trigger, and failure trigger are unchanged — only the sent command differs.

---

## 2026-03-06 — Fix: Focus trigger now clears impatience from tracking

**Files modified**:
- `src_new/triggers/.../399_Focus_(known).lua` — else branch (non-lovers cure)
- `src_new/triggers/.../398_Focus_(UNK).lua` — all focus uses

**Problem**: When target used Focus and cured a goldenseal aff other than impatience, our tracking didn't infer that impatience was absent. If focus cured something else, impatience can't be present (focus would prioritize it).

**Fix**: Added `erAff("impatience")` + V2/V3 removal on focus use. In 399 (known variant), only in the non-lovers branch (the lovers branch already cleared impatience explicitly). In 398 (UNK variant), on all focus uses (impatience is gone either way — cured by focus or wasn't present).

---

## 2026-03-06 — Fix: Shrugging trigger gated to Serpent only

**Files modified**:
- `src_new/triggers/.../passive_active/015_Shrugging_(Serpent).lua`

**Problem**: The "hunches shoulders" trigger (Shrugging) only fired for Serpent targets (class gate: `class == "Serpent"`). Other classes also use this ability.

**Fix**: Removed the Serpent class gate. Now clears `weariness` + 1 random affliction from V1/V2/V3 tracking for any targeted player.

---

## 2026-03-06 — Tweak: Lower asthma threshold from 50% to 33% for manaleech+disfigure transition

**Files modified**:
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — `selectPrimaryCurse()` (line ~263), `selectSecondaryCurse()` (lines ~326, ~333)

**Change**: Lowered the asthma probability threshold from `>= 0.50` to `>= 0.33` in three places. Once clumsy and weariness are both at 33%, asthma is delivered. As soon as asthma reaches 33%, the system transitions to manaleech+disfigure immediately rather than waiting for 50% certainty. This applies earlier pressure and pairs with the existing disfigure-on-manaleech-round logic.

---

## 2026-03-06 — Fix: Disfigure firing prematurely due to off-balance button spam

**Files modified**:
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — disfigure gate (line ~605)

**Problem**: Spamming the attack button while off-balance caused `selectPrimaryCurse()` to pick manaleech (asthma already tracked as applied from the previous round's trigger). The `buildAttack()` function then appended `disfigure` to the queued command. When balance returned, the queued deadeyes+disfigure fired — but disfigure was computed based on stale state (manaleech hadn't actually been cursed yet).

**Fix**: Added `gmcp.Char.Vitals.bal == "1"` gate to the disfigure condition. Disfigure only appends when actually on balance, ensuring it fires on the real manaleech round, not a pre-queued off-balance press.

---

## 2026-03-06 — Fix: Legacy apostate files still active, causing unwanted disfigure

### Bugfix: Disfigure firing on clumsy+asthma round instead of manaleech round

**Files modified**:
- `src_new/scripts/.../apostate/001_CLUMSY_PRIOS.lua` through `013_LOCK_ATTACK.lua` — all 13 legacy files set to `isActive: 'no'`

**Problem**: All 13 legacy apostate scripts (001-013) were still `isActive: 'yes'` despite being replaced by `015_CC_Apostate.lua`. The legacy `013_LOCK_ATTACK.lua:114` had its own disfigure logic (`want_disloyalty and tAffs.asthma`) that fired as soon as the asthma curse landed (V1 boolean set immediately by trigger), not when asthma was confirmed stuck. This caused disfigure to fire on the first clumsy+asthma round instead of waiting for the manaleech round.

**Fix**: Deactivated all 13 legacy files. The unified `015_CC_Apostate.lua` already has correct disfigure logic gated behind `c1 == "manaleech" or c2 == "manaleech"` (line 605).

---

## 2026-03-06 — Fix: 4 recurring nil-access runtime errors

### Bugfix: Limb Counter Window, Tekura 6-Limb, Capture Msg, Start Shikudo all spamming errors

**Files modified**:
- `src_new/scripts/.../windows/001_Limb_Counter_Window.lua` — nil guard on `lb[target].hits`, removed duplicate YAML header
- `src_new/scripts/.../tekura/002_Tekura_6Limb_Offense.lua` — nil guard on `amount` in `onLimbHitUpdated`
- `src_new/triggers/.../ataxia_chat_capture/002_Capture_Msg.lua` — nil guard on `ataxiaBasher.targetList`
- `src_new/triggers/.../169_Start_Shikudo.lua` — nil guard on `monk` global

**Problems**:
1. **Limb Counter Window:184** — `lb[target].hits[ln]` crashed when `lb[target]` was nil (no limb data initialized for current target). Fired every prompt tick.
2. **Tekura 6-Limb Offense:74** — `amount > 16` crashed when `limb_init.lua` raised `"limb hits updated"` with only 3 args (no amount). Fired on every limb reset.
3. **Capture Msg:6** — `ataxiaBasher.targetList[area]` crashed when `ataxiaBasher.targetList` was nil (basher not initialized). Fired on every say/tell.
4. **Start Shikudo:1** — `monk.shikudo.start()` crashed because `monk` global doesn't exist. Trigger marked `isActive: 'no'` in source but was active in installed profile.

**Fixes**: Added nil guards at each crash site. Also removed duplicate YAML header block in Limb Counter Window and added `or 0` fallback for missing hit values.

---

## 2026-03-06 — Fix: Baalzadeen re-summoned every dispatch

### Bugfix: Apostate offense wastes balance summoning Baalzadeen when already present

**Files modified**:
- `src_new/scripts/.../apostate/014_Levi_Apostate.lua` — `baalzadeen()` function
- `src_new/scripts/.../apostate/015_CC_Apostate.lua` — dispatch Baalzadeen check
- `src_new/triggers/.../apostate/025_BAALZADEEN_SUMMONED.lua` — **New** trigger
- `src_new/triggers/.../apostate/014_NO_BAALZADEEN.lua` — reset flag on failure

**Problem**: Every `apostate.dispatch()` call sent `queue prepend free summon baalzadeen` before the attack, even when the Baalzadeen was already in the room. This consumed balance on a redundant summon every round. Two issues:
1. `baalzadeen()` used `table.contains(zgui.roomDenizenList, "a Baalzadeen")` — exact string match failed if the GMCP name differed in casing/article, or if the entity had a non-`"m"` attrib (landing in `roomItemList` instead)
2. No guard against re-sending the summon while waiting for GMCP to confirm the Baalzadeen appeared

**Fix**:
1. All daemon utility functions (`baalzadeen()`, `bloodworm()`, `demon()`, `daemonite()`, `fiend()`) switched from `zgui.roomDenizenList` to `ataxia.denizensHere` with case-insensitive partial matching. `zgui.roomDenizenList` was not populated; `ataxia.denizensHere` is the reliable GMCP-backed table used by the basher
2. Fixed `daemonite()` and `fiend()` — they iterated `zgui.roomItemList` (wrong list) and called `item.name:match()` on plain string values (would crash)
3. Added `apostate.state.baalzadeenSummoned` flag — set `true` when summon is sent, prevents re-sending every dispatch
4. New trigger `025_BAALZADEEN_SUMMONED.lua` matches "You call out, ordering your Baalzadeen to return to serve your whim." and resets `baalzadeenSummoned = false`
5. `014_NO_BAALZADEEN.lua` also resets the flag so dispatch can retry after a failure

---

## 2026-03-06 — Fix: Root group init script lost during hierarchy flattening

### Bugfix: `ataxiaTemp` / `ataxiagui` / `ataxiaTables` nil on load

**File modified**: `tools/convert_to_muddler.py`

**Problem**: The hierarchy flattening (root group unwrap) promoted children to the top level but dropped the root group's own inline `script:` property. The `Levi_Ataxia` root group in `scripts/_groups.yaml` contained the init script that creates `ataxiaTemp`, `ataxia`, `ataxiaTables`, `ataxiagui`, `ataxiaVersion`, `muteList`, `ataxia.bals`, and the `ataxia_Echo()`/`ataxiaEcho()` functions. Without this script, every prompt trigger, vitals handler, basher function, and limb display crashed with `attempt to index global 'ataxiaTemp' (a nil value)`.

**Symptoms**:
- `[ERROR] Prompt Running: attempt to index global 'ataxiaTemp' (a nil value)`
- `[ERROR] Limb Counter Window: attempt to index global 'ataxiaNDB' (a nil value)`
- `[ERROR] ataxia_Vitals_Update: attempt to index global 'ataxiaTemp' (a nil value)`
- `[ERROR] Bashing Functions: attempt to index global 'ataxiaTemp' (a nil value)`
- Basher sending invalid commands (`lipread`, `scales`, `conjure`) — class not detected due to missing init

**Fix**: When unwrapping a root group, if it has an inline `script:`, inject a synthetic `"Levi_Ataxia Init"` script node at position 0 of the children array. This ensures the init code loads before any child scripts. Only the `scripts` type was affected — triggers, aliases, timers, and keys had no root group inline scripts.

**Root cause**: The flatten plan (2026-03-06) added root group unwrapping to prevent triple-nested `Levi_Ataxia` in Mudlet. The unwrap code at line 440 extracted `children` from the JSON node but did not check for the node's own `script` property.

---

## 2026-03-06 — Documentation Refresh

### Improvement: Comprehensive markdown documentation update

**Files modified**:
- `.claude/AGENTS.md` — Added Combat Systems Quick Reference table (10 offense systems + 2 utility systems), Serpent Offense section, Shaman Offense section, Snipe System section, Setup Wizard section. Updated affliction tracking reference with `erAff()` V1-only warning, added `apostate.hasAff()` and `dwbRunie.hasAff()` to class routing. Expanded Key Files Reference table. Updated basher section with additional files and single-gate architecture notes.
- `docs/ai-includes/agent-teams.md` — Updated Isolated Directories table with correct namespaces (`shamanOffense`, `apostate`, `serp_*`, `dwbRunie`, `snipe`, `infernalDWC2L`). Added setup wizard and shaman spirit system to Shared/Contended Files. Updated trigger ownership to mention class-specific subdirectories.
- `CLAUDE.md` — Updated Combat Systems Index: serpent (Documented, 1 file), shaman (Documented, 1 file), snipe (Documented). Added Setup Wizard section with full command table. Updated class modules list in Ataxia Combat System overview.

**Files verified (no changes needed)**:
- `.claude/classes/README.md` — Already accurate (26 classes, lock table, combat concepts)
- `.claude/databases/README.md` — Already accurate (4 YAML databases)
- `.claude/templates/README.md` — Already accurate (3 templates)

---

## 2026-03-06 — Setup Wizard & Separator Fix

### Feature: In-game setup wizard (`levi setup`)

**Files added**:
- `src_new/scripts/.../misc_scripts/020_Setup_Wizard.lua` — `leviSetup` namespace with guided configuration for all system settings
- `src_new/aliases/.../toggles_settings_etc/021_Setup_Wizard.lua` — `^levi setup ?(.*)$` alias to dispatch the wizard

**What it does**: Provides a single `levi setup` command that walks players through configuring:
- Class detection and weapon setup
- Server-side separator
- Basher settings (gold pack, flee thresholds, target lists)
- Health/mana sipping thresholds
- Affliction tracking mode (V1/V2/V3)
- Combat toggles (party relay, auto-gallop, raid mode, etc.)
- GUI creation and NDB configuration
- Full status overview (`levi setup status`)

Each category: `levi setup class`, `levi setup separator`, `levi setup weapons`, `levi setup basher`, `levi setup sipping`, `levi setup tracking`, `levi setup combat`, `levi setup gui`, `levi setup ndb`, `levi setup install`, `levi setup status`.

### Feature: Installation walkthrough (`levi setup install`)

Added `levi setup install` command that walks players through the three one-time install commands:
- `atinstall` — Core Ataxia system (server-side curing config, prompt, defaults)
- `abinstall` — Basher system (target lists, flee, shield timers)
- `aninstall` — Name Database (player tracking, city highlighting)

Subcommands: `levi setup install all` (runs basher + NDB directly, guides atinstall), `levi setup install ataxia`, `levi setup install basher`, `levi setup install ndb`.

### Feature: Post-install configuration guide (`levi setup guide`)

Added `levi setup guide` with per-subsystem walkthroughs showing every configurable option:
- `levi setup guide ataxia` — Separator, system toggle, custom prompt, defence profiles (defup/defadd/defremove), curing priorities, item highlighting, sipping, room shortening, GUI, raid mode, auto-gallop, gag clotting
- `levi setup guide basher` — Enable/disable, target lists (bash room/add/remove/list), flee thresholds, danger mobs, ignore lists, gold pack, shield swap/timer, rageraze, tree blackout, Dragon-specific options
- `levi setup guide ndb` — City highlight colours, highlight toggle/priority, enemy formatting (bold/italic/underline), player notes, whois/honours lookup, settings display

Each entry shows both the direct in-game command (e.g. `aconfig separator`) and the wizard equivalent (e.g. `levi setup separator`), so users know where to go for quick changes.

### Bugfix: Separator no longer hardcoded on every login

**File modified**: `src_new/scripts/.../002_Check_For_Any_Missing_Variables.lua`

**Problem**: `ataxiaCheckForMissing()` unconditionally set `ataxia.settings.separator = ";"` on every login, overwriting any user-configured separator.

**Fix**: Only set the default when the separator is nil or empty, preserving saved user preference.

---

## 2026-03-06 — Flatten Redundant Levi_Ataxia Nesting

### Improvement: Remove triple-nested Levi_Ataxia wrapper groups

**Files modified**:
- `src_new/scripts/_groups.yaml` — Dissolved `LEVI > Ataxia > Ataxia` and `Levi Scripts` wrappers; moved inner Ataxia init script to root
- `src_new/triggers/_groups.yaml` — Dissolved `For Levi > leviticus` wrappers
- `src_new/timers/_groups.yaml` — Dissolved `For Levi > Levi_062424 > leviticus > Levi Ataxia` chain
- `src_new/keys/_groups.yaml` — Dissolved `Levitax` wrapper
- `tools/convert_to_muddler.py` — Added per-type hierarchy rewriting to strip dissolved group names from file YAML headers; unwrap root group in JSON output so children appear directly in the array
- `tools/flatten_groups.py` — New helper script for flattening `_groups.yaml` intermediate groups

**Problem**: The Mudlet package tree showed 3 levels of `Levi_Ataxia` before reaching actual content groups, caused by three layers combining: (1) Mudlet package import creates a root group, (2) Muddler directory adds another wrapper, (3) JSON root group object adds a third. Each item type also had its own redundant intermediate groups (e.g., scripts had `LEVI > Ataxia > Ataxia`, triggers had `For Levi > leviticus`).

**Fix**: Two-part approach:
1. Flattened `_groups.yaml` files to remove intermediate wrapper groups, promoting their children directly under `Levi_Ataxia`
2. Modified `convert_to_muddler.py` to (a) rewrite stale hierarchy references in file YAML headers to match the new flat structure, and (b) unwrap the root group in JSON output so Muddler doesn't add another layer

Result: Single `Levi_Ataxia` level (the package root), then directly into content groups.

---

## 2026-03-06 — Flatten Alias Hierarchy

### Improvement: Reduce deeply nested alias group structure

**Files modified**:
- `src_new/aliases/_groups.yaml` — Rewritten with flat hierarchy (max 5 levels vs previous 10+)
- 520 alias `.lua` files — All `hierarchy:` YAML headers updated to new paths
- `tools/flatten_alias_hierarchy.py` — New tool for bulk hierarchy path remapping

**Problem**: Alias groups were nested 7-10 levels deep (e.g., `Levi_Ataxia > For Levi > Levi_062424 > Levi > LeviticusREG > Leviticus > BladeMaster`) due to accumulated organizational layers over years. This made navigating the alias tree in Mudlet tedious.

**Fix**: Consolidated all aliases into a clean top-level structure under `Levi_Ataxia`:
- `Classes/` — All 13 class-specific alias groups (Apostate, Blademaster, Knight, Monk, etc.)
- `General/` — Movement, Targeting, Shopkeeping, Freezetag, Egghunt
- `Artefacts/` — LegendDeck, Dragon Talisman, Rageblade
- `Combat/` — Combat Aliases, Defence, Enemy Management, Limb
- `Ataxia/` — NDB, Basher, Config, Crafting, Defence Config, Fishing, Shaman System
- `Systems/` — Gear System, zData, zGUI Redux
- `Utility/` — Echo, delete old profiles, run-lua-code
- `RAGEPULL` (disabled)

All group-level scripts (LegendDeck notes, Infernal forge notes, Dragon Talisman combine, Inkmilling help, Custom Prompt documentation) and `isActive: false` flags preserved.

---

## 2026-03-06 — NDB API Error Handling (Blacklist Non-Players)

### Bug Fix: Non-player names (items, NPCs) cause infinite API lookup spam

**Files modified**:
- `src_new/scripts/.../ataxia_ndb/007_ataxiaNDB_Failed.lua` — Handle "Forbidden" API responses; added `ataxiaNDB_blacklistName()` and `ataxiaNDB_isBlacklisted()` functions
- `src_new/scripts/.../ataxia_ndb/002_Get_Information.lua` — `ataxiaNDB_Acquire()` and `ataxiaNDB_NameList()` skip blacklisted names
- `src_new/scripts/.../ataxia_ndb/003_ataxiaNDB_API.lua` — `ataxiaNDB_SortOnline()` filters blacklisted names from API queue
- `src_new/scripts/.../ataxia_ndb/001_Ataxia_NDB_Settings.lua` — Added `notPlayers` table to default settings
- `src_new/triggers/.../747_Get_Person.lua` — Explorers Rankings skips blacklisted names

**Problem**: Item names like "earrings" were being detected as player names (e.g., from GMCP player lists or explorers rankings). The API returned 403 Forbidden, but the error handler only recognized "Not Found" — Forbidden fell through to a generic echo with no corrective action. On every subsequent WHO/explorers query, the same name was re-discovered and re-queued, producing repeated "Error downloading" + "1 new names identified" spam.

**Fix**: Added a `notPlayers` blacklist persisted in `ataxiaNDB`. When the API returns Forbidden (or Not Found), the name is added to `ataxiaNDB.notPlayers`. All lookup entry points (`ataxiaNDB_Acquire`, `ataxiaNDB_NameList`, `ataxiaNDB_SortOnline`, explorers trigger) now check `ataxiaNDB_isBlacklisted()` before making API calls. First failure adds to blacklist; subsequent queries skip silently.

---

## 2026-03-06 — Converter mStayOpen Fix (Defence List Spam + 50+ Triggers)

### Bug Fix: mStayOpen triggers with children broken by converter

**File modified**: `tools/convert_to_muddler.py` — `_group_to_json()` method

**Problem**: Triggers with `mStayOpen > 0` that also have child triggers (referenced via `hierarchy`) were being split into two XML nodes: a folder (holding children) and a separate leaf trigger (with the pattern/fireLength). Children ended up under the folder (which has no stay-open window), not under the trigger. This broke Mudlet's `mStayOpen` mechanism, which requires children to be nested directly under the trigger.

**Visible symptom**: `"(LEVI): Defences currently active:"` echoed on every prompt line (~25 lines of spam), because the `Defence List` trigger's child `get Defence` was under an inert folder instead of the 99-line stay-open trigger.

**Fix**: When a leaf trigger has `mStayOpen > 0` AND shares its name with an auto-created child group, the converter now merges the trigger's properties (patterns, fireLength, script, multiline settings, filter, highlight, etc.) INTO the group node, sets `isFolder: "no"`, and skips the duplicate leaf. This produces a single XML node that is both a trigger and a parent — exactly what Mudlet expects.

**Scope**: Generic fix handles all 50+ mStayOpen triggers across the codebase that are also hierarchy parents, not just Defence List.

---

## 2026-03-06 — Blademaster Bash Display Fix (Shin, Stance, DPS)

### Bug Fix: Shin, stance, and DPS not showing in bash info window

**Files modified**:
- `src_new/scripts/.../windows/001_Limb_Counter_Window.lua` — Fixed Shin display + added Stance for Blademaster
- `src_new/scripts/.../basher/003_Bash_Stats_Functions.lua` — Implemented missing `bashStats_getDPS()` function

**Problems**:
1. **Shin**: Window used `bmshin` global from disabled `001_Logic.lua` (`isActive: 'no'`). Variable was always nil, guard skipped display. Fix: call `blademaster.getShin()` directly (defined in active `005_CC_BM_Ice.lua`), with fallback to `ataxia.vitals.class`.
2. **Stance**: No Blademaster stance section existed in the window (only Monk had one). Fix: added `ataxia.vitals.stance` display under the Shin line for Blademaster.
3. **DPS**: Window checked `if bashStats and bashStats_getDPS` but `bashStats_getDPS()` was never implemented — only `resetBashingStats()` existed. The damage tracking infrastructure was already working (trigger 350 accumulates `totalDamage`, balance timers record `lastBalanceDamage`/`lastBalanceTime`), but no function computed DPS from it. Fix: implemented `bashStats_getDPS()` returning session DPS and per-balance DPS.

---

## 2026-03-06 — Prompt Newline Fix

### Enhancement: Force prompt onto its own line

**File modified**: `src_new/triggers/levi_ataxia/for_levi/leviticus/318_Prompt_Trigger.lua`

**Problem**: Achaea sends the prompt on the same line as the preceding game text (no newline before the GA telnet signal). This makes the prompt visually merge with combat/room output.

**Fix**: Added `echo("\n")` at the start of the prompt trigger body, before `ataxia_promptCommands()`. This forces a line break so the prompt always appears on its own line.

---

## 2026-03-06 — ataxiaNDB `qwp` Fix (Missing Event Handlers)

### Bug Fix: `qwp` (online player list) never displays results

**Files added**:
- `src_new/scripts/.../ataxia_ndb/006_ataxiaNDB_Success.lua` — `sysDownloadDone` event handler for NDB downloads
- `src_new/scripts/.../ataxia_ndb/007_ataxiaNDB_Failed.lua` — `sysDownloadError` event handler for NDB download failures

**Root cause**: Two scripts from the original XML package — `ataxiaNDB_Success` and `ataxiaNDB_Failed` — were never extracted to `src_new/` during the initial conversion to the Muddler build system. These scripts are the glue between `downloadFile()` and the NDB processing:
- `ataxiaNDB_Success` listens for `sysDownloadDone`, checks if the file is in the `ataxiaNDB/` folder, routes `Online.json` to `ataxiaNDB_SortOnline()`, and parses individual player JSON into `ataxiaNDB.players[]`
- `ataxiaNDB_Failed` listens for `sysDownloadError` and handles download failures (e.g., player not found → removes from DB)

Without these handlers, `qwp` would call `ataxiaNDB_GetOnline()` → `downloadFile()` → download completes → **nothing happens** (no handler routes the file to processing).

**Also affected**: `ndb check <name>`, `ndb update`, and any other command using `ataxiaNDB_Acquire()` — individual player lookups also silently failed.

---

## 2026-03-06 — Converter Fix + Login Bug Fixes

### Critical: Muddler Converter Bug Fix (`tools/convert_to_muddler.py`)

**Problem**: When a non-folder trigger (`isFolder: 'no'`) has children AND a pattern with `mStayOpen`, the converter splits it into two entries: a folder (with children) and a separate trigger (with pattern + fireLength). Muddler auto-matches `.lua` script files by item name — since both entries share the same name, the folder unintentionally picks up the trigger's script. This caused the folder's script to execute on every child match (including every prompt), leading to:

- Game text being invisible (child trigger `^(.+).$` calling `deleteLine()` on every line)
- Defence list repeating "Defences currently active:" on every prompt
- Tattoo display firing on every prompt
- ~70 other multiline trigger groups silently broken

**Fix**: The converter now detects when a trigger shares a name with a sibling folder. In that case, the trigger's script is embedded inline in the JSON (`"script": "..."`) instead of written as a separate `.lua` file. The folder stays script-less. This affected 70 trigger groups (lua file count: 1404 -> 1334).

### Bug Fix: Defence List spam on every prompt

**Files changed**:
- `src_new/triggers/.../leviticus/710_Defence_List.lua` — Added `capturing_defences = true` flag
- `src_new/triggers/.../leviticus/711_get_Defence.lua` — Added `if not capturing_defences then return end` guard
- `src_new/triggers/.../leviticus/712_prompt_2.lua` — Added guard + `capturing_defences = nil` cleanup

**Root cause**: Converter bug (above) caused the folder's children to fire continuously. The `get Defence` child with pattern `^(.+).$` matched every line and called `deleteLine()`, hiding all game text. The prompt child called `ataxia_reportDefences()` on every prompt.

### Bug Fix: Tattoo display repeating on every prompt

**Files changed**:
- `src_new/triggers/.../tattoo_stuff/001_Tattoo_List.lua` — Added `capturing_tattoos = true` flag
- `src_new/triggers/.../tattoo_stuff/002_Gag_Lines.lua` — Added `if not capturing_tattoos then return end` guard
- `src_new/triggers/.../tattoo_stuff/003_Empty_Slot.lua` — Added guard
- `src_new/triggers/.../tattoo_stuff/004_Found_Tattoo.lua` — Added guard
- `src_new/triggers/.../tattoo_stuff/005_End_Capturing.lua` — Changed guard from `if not tattoosOnMe` to `if not capturing_tattoos` + cleanup

**Root cause**: Same converter bug. `tattoosOnMe` persisted after first use, so the old guard never blocked subsequent prompt-fired executions.

### Bug Fix: `ataxia_changeLog` nil error on login

**Files changed**:
- `src_new/scripts/.../ataxia/003_Install_System.lua` — Added nil guard: `if ataxia_changeLog then ataxia_changeLog() end`
- `src_new/aliases/.../172_Show_Changelog.lua` — Added nil guard + user-friendly message

**Root cause**: `ataxia_changeLog()` was called in two places but the function was never defined in the codebase.

### Design Pattern: `capturing_` flags for multiline trigger groups

The converter bug means all multiline trigger groups with children have their children fire continuously. The workaround is a global flag pattern:
1. Parent trigger sets `capturing_<name> = true`
2. All children check `if not capturing_<name> then return end`
3. Prompt/closing child clears `capturing_<name> = nil`

With the converter fix applied, this pattern is technically redundant for new builds but provides defense-in-depth.

### Bug Fix: Game text invisible — Readaura stuff `deleteLine()` on every line

**Files changed**:
- `src_new/triggers/.../leviticus/508_Readaura_stuff.lua` — Added `capturing_readaura = true` flag
- `src_new/triggers/.../leviticus/509_def.lua` — Added `if not capturing_readaura then return end` guard
- `src_new/triggers/.../leviticus/510_End.lua` — Added guard + `capturing_readaura = nil` cleanup

**Root cause**: The "Readaura stuff" multiline group (Occultist readaura) has a child trigger "def" with pattern `^(.+).$` and unconditional `deleteLine()`. Due to the converter bug, this child fires on every line of game text, deleting everything. This was the **primary cause** of all game text being invisible after login.

### Bug Fix: Fullsense-Hyena prompt deleting lines on every prompt

**Files changed**:
- `src_new/triggers/.../leviticus/456_Fullsense-Hyena.lua` — Added `capturing_fullsense_hyena = true` flag
- `src_new/triggers/.../leviticus/457_Each_person.lua` — Added `if not capturing_fullsense_hyena then return end` guard
- `src_new/triggers/.../leviticus/458_prompt.lua` — Added guard + cleanup, moved `deleteLine()` after guard

**Root cause**: Same converter bug. The prompt child called `deleteLine()` unconditionally before checking `fullSensePeople`, deleting the prompt line on every prompt.

### Bug Fix: Fullsense-Demon prompt deleting lines on every prompt

**Files changed**:
- `src_new/triggers/.../leviticus/459_Fullsense-Demon.lua` — Added `capturing_fullsense_demon = true` flag
- `src_new/triggers/.../leviticus/460_Each_person_1.lua` — Added `if not capturing_fullsense_demon then return end` guard
- `src_new/triggers/.../leviticus/461_prompt_1.lua` — Added guard + cleanup, moved `deleteLine()` after guard

**Root cause**: Same as Fullsense-Hyena above, but for the Baalzadeen variant.

### Bug Fix: Defence List prompt — `deleteLine()` ordering

**Files changed**:
- `src_new/triggers/.../leviticus/712_prompt_2.lua` — Moved `deleteLine()` after `capturing_defences` guard

**Root cause**: `deleteLine()` was called before the `capturing_defences` check, so the prompt line was deleted on every prompt even when not capturing defences.
