# LEVI-Achaea Changelog

---

## 2026-08-06 - Hawkstep and Wavedance recognised as Bard defences (ships in v4.7.222)

`DEFADD`/`KEEPADD` now accept `hawkstep` and `wavedance`, and `defs valid` renders them with
the command that raises them. Previously only `harrying` was listed, so the other two
Bladedance dances were rejected as "not a defence for your class" even though the basher
already knew how to dance them (`BARD_DANCES`, basher/002).

AB confirmed (2026-08-06): `DANCE HAWKSTEP` (2.50s balance, makes attempts to hinder your
escape from a room less likely to succeed) and `DANCE WAVEDANCE` (2.00s balance, you cannot
be parried but do no limb damage).

**All three dances are mutually exclusive** — AB: *"you can only dance one thing at a time, so
the hawkstep is exclusive with the dance of the harrying."* They are eligible for profiles but
must not be put in the SAME keepup profile, or the system would re-raise each in turn forever.
Noted in the code at both tables.

Still unconfirmed: the GMCP defence names for hawkstep/wavedance are *assumed* to match the
dance names, as `harrying` does. A live `DEF` capture while dancing each would settle it; if
they differ, `deffing/004` and `BARD_DANCES` in `basher/002` are the two places to correct.

**Open question flagged, not changed:** the bashing dance-picker justifies wavedance for bosses
by "ignoring 75% of resistance" and hawkstep for crowds by "25% damage resistance". Neither
number appears in the AB text for either ability. Recorded in `.claude/classes/bard.md`.

Files: `src_new/scripts/levi_ataxia/levi/ataxia/deffing/004_Defence_Sorting_-_Cleaner.lua`,
`.claude/classes/bard.md`. Suite 1037 green.

---

## 2026-08-06 - Keep 40 rage: culling stops breaking the floor (v4.7.229)

User: *"We need to keep 40 battlerage at all times in order to increase our damage by 23
percent."*

The mechanism already existed and was built for exactly this gear -- `bash floor 40` makes
every rotation spend only the SURPLUS, so an ability costing C fires at C + 40. **One thing
would have broken it:** culling was exempt from the floor unconditionally, every gate reading
`rage >= 36 or brFree()` directly instead of going through `rageAfford`.

That exemption is right for **Golden Dragon**, where the ability is `reap` -- an EXECUTE, and a
kill beats any per-swing multiplier on swings that will never happen. It is wrong for the
artifact culling blade on a class like **Bard**, where it is simply a 1505 unblockable hit:
firing at 36 rage drops under a 40 floor and switches off a 23% bonus until rage rebuilds. At
~1.8s per swing across culling's own 24s cooldown that is roughly a dozen swings, comfortably
outweighing the one hit.

So the exemption is now a setting. `bash floor culling` toggles it; **default off preserves
today's behaviour exactly**, so reap stays unfloored. All 8 gates across `basher/001` and
`basher/002` route through the new `ataxiaBasher_cullAfford`. A free battlerage still fires
below the floor either way -- it costs no rage, so it cannot breach it, and refusing it would
simply waste the charge.

### Also shipped: gear battlerage-cooldown scaling

Written while I was misreading the request as 40% cooldown reduction, but worth keeping -- the
audit shows ~20 chest pieces and a head carrying exactly that, and every battlerage cooldown in
the system is a hardcoded `tempTimer` at the ability's BASE duration (moulinet 17s, large 24s,
specials 32-46s, culling 24s, cyclone 23s). Nothing scaled them. `ataxiaBasher.brCooldownPct`
now scales all 15 arm sites; **0 (the default) leaves every duration byte-identical**, so it
cannot change behaviour for anyone who has not measured their own reduction. Clamped at 90%,
floored at 1s -- a negative tempTimer delay is not a fast cooldown, it is an undefined one.

Worth recording separately: the game's ready line (*"You can use Moulinet again."*) is parsed
and then **dropped** for Bard. `BR_READY_MAP` covers the owned rotations and culling blade, but
the shared `battleRage_Timers.small/large/special` have no name mapping -- so the game tells us
the ability is ready and we ignore it.

Files: `basher/001`, `basher/002`, `configs/016_Rage_Floor.lua`, triggers `330`/`331`/`332`/`342`.
Suite **1085 -> 1089**; both directions verified by breaking the code back.

---

## 2026-08-06 - Test the invariant, not just the instances (v4.7.228)

Asked whether bonus damage was actually tested, the answer was yes -- five separate tests, and
the summariser and scorer happen to share the identical pattern, which is why the `+23% Bonus
Dmg` in a live audit proves the scorer matched too.

But that is luck, not design, and it is exactly the gap the crit-DoT bug lived in. The
summariser recognised that effect and the scorer did not. Nothing was wrong with either in
isolation: the audit table showed the effect, so it looked handled, while the ranker read it as
worthless -- and `gearaudit scrap` destroys what ranks low.

So the relationship is now asserted rather than each pattern separately: **an effect the
summariser labels must also produce a non-zero score**, across the real game wording for every
family the Mnemosyne set contains. Reverting the crit-DoT fix makes the invariant fail on its
own, without the specific test for it -- which is the point.

The test also guards itself: a case the summariser cannot label proves nothing about the
scorer, so an empty summary fails rather than passing vacuously.

Files: `test_gear_audit.lua`. Suite **1075 -> 1085**.

---

## 2026-08-06 - Score mana regen; a false accusation retracted (v4.7.227)

Answering *"what gear is best to wear for dungeoneer"* meant scoring the set properly, which
turned up the last unscored family: **mana regen** (`while you have any amount of stored
battlerage, your mana will regenerate X% faster`) -- about 11 head pieces sitting at zero.
Weighted 1.5, below HP regen's 2.5 because HP is what actually binds while bashing, but not
dismissed: running out of mana IS a kill condition for some classes (Psion excise, the Kai
Choke 250-mana floor).

**And a correction.** I also reported denizen-type resistance (`+6% vs priest`) as unscored. It
was not -- my probe fed the parser *"You take 6% less damage from priest denizens"* when the
real pattern is `gain (%d+)%% resistance against`. The code was right and the test input was
wrong, twice in the same session; a test asserting the same thing is now in the suite so the
question does not have to be re-litigated from memory.

Files: `gear_system/001_Gear_Audit.lua`. Suite **1073 -> 1075**.

---

## 2026-08-06 - Gear audit: score what it was ignoring, rank per category (v4.7.226)

User: *"We must categorize them.. Best in Slot per category. Best damage, rage generation,
defensive stuff, etc per slot."* -- prompted by a live 178-item audit.

### The scrap hazard, found first

Scoring the real audit turned up two effect families worth **zero**:

* **`Your battlerage abilities will cool down X% faster.`** -- no pattern for it existed
  *anywhere* in the file (`cool down`: 0 occurrences; the only cooldown parsing is for burst
  items). Roughly 20 of the user's chest pieces, plus a head.
* **The crit-on-strike DoT** -- the *summariser* recognised it, but the *scorer* had no stat
  for it. Another ~14 hands pieces.

So ~35 of 178 items ranked below a +1% crit trinket, fell outside `keepPerSet`, and would have
been listed by **`gearaudit scrap` -- which destroys gear**. Both are now scored:
`brCooldownPct` at 2.5 (just above rage generation: rage only *enables* a battlerage, the
cooldown gates how often one can be used at all, and the Semiro log shows both binding in the
same fight) and `critDotPct` at 1.5.

The Mnemosyne restriction is now **named but not discounted**. Every other condition in that
list is a place you pass through; the tower is where this character bashes, so applying
`conditionalMult` would under-rate the gear precisely where it is worn.

### `gearaudit cat` -- best in slot per category

The single-score BiS hid the actual decision. One chest slot holds `+23% bonus damage`,
`+16% rage generation` and `-21% battlerage cooldown`; collapsing those into one number says
which the **weights** prefer, not which to wear. `gearaudit cat` reports a winner per category
per slot -- Damage / Rage-BR / Defensive -- with runners-up, so you can see whether the leader
is a clear win or a coin toss. An item only appears under a category it actually contributes
to. Each stat belongs to exactly one category, so category scores are a strict subset of the
total and the two can never disagree.

### Compact summaries

`Bleed: a denizen, you will automatically clot 18% of it` -> `Auto-clot 18%`;
`Execute: a third of their health, you deal 11% bonus damage` -> `Execute +11%`; and battlerage
cooldown, previously not summarised at all and printed as two full sentences -> `BR cooldown
-19% (Mnem)`. That last one was the single biggest cause of the audit table wrapping.

**A regression caught by an existing test:** the first version hardcoded the on-crit clause as
`as DoT`. It is not always a DoT -- lifesteal (*"returned as health"*) uses the same opener.
The effect is now tagged from its own wording, and anything unrecognised keeps a clipped
version of the real clause rather than claiming something false.

Files: `gear_system/001_Gear_Audit.lua`. Suite **1062 -> 1073**; three behaviours verified by
breaking the code back.

---

## 2026-08-06 - Say whether we are immune, either way (v4.7.225)

User, with a live offer screen: *"Here is an example would be excellent to see if we are immune
or not."*

v4.7.224 only spoke up when a boon's cost was something we **already** blocked. That screen
showed the gap: **Plasmatic** *grants* haemophilia immunity and **Corrupted Blood** costs
nausea, and neither got a word. The annotation now answers the question in all three
directions:

| Boon | Now says |
|---|---|
| `Plasmatic` -- *"You are immune to the haemophilia affliction."* | **GRANTS IMMUNITY** -- what taking it buys |
| `Corrupted Blood` -- *"...but you suffer permanent nausea."* | costs nausea -- **not immune** (or **IMMUNE, free for us**, once we hold it) |
| `Restoration`, `Rage-Fuelled`, `Crystal Blue Protection` | nothing -- no cost to report |

### Two tiers, because the two questions carry different risk

**A. "Is this cost something we block?"** scans only the immunities we actually **hold** -- one
or two specific words -- so it needs no clause restriction and still catches alternate word
forms. Unchanged from v4.7.224 and exactly as safe.

**B. "Does this have a cost we do NOT block?"** has to scan every plausible affliction, so it
is restricted to a **cost clause** (`but`, `however`, `at the cost of`, `you suffer`, ...). The
affliction list is also filtered rather than the full canonical 115: the limb compounds never
appear in prose, and the ordinary-English ones -- *fear, peace, guilt, justice, generosity,
burning, frozen, prone, sleeping, itching* -- would match innocent sentences. Scanning free
text for "peace" and calling it an affliction is how an annotation stops being trusted.

An immunity **grant** is explicitly excluded from the cost scan: without that, a boon reading
*"...but you are immune to nausea"* has its benefit reported as its drawback.

`Stone Stomach`'s *"but you can no longer drink health or mana"* is a genuine cost with a
genuine cost clause and **no affliction** -- it stays quiet rather than being dressed up as
one.

### On verifying the tests

Breaking the code back showed **two of the three safeguards were not actually covered** by the
first set of tests. The cost-clause restriction needed a case where an affliction appears
outside a cost clause (a boon that *cures* nausea), and the grant-exclusion needed a cost
clause *preceding* the grant -- a bare `"You are immune to X"` has no marker at all, so that
test could never have failed. Both are now real.

Files: `mnemosyne/004_Parsers.lua`. Suite **1056 -> 1062**, including the user's screen as a
verbatim fixture.

---

## 2026-08-06 - Call out boon drawbacks we are immune to (v4.7.224)

User: *"We select boons that make us immune to an affliction and I would love for it to echo on
the boon option screen to be able to state we have the immunity to this boon's downside."*

Several boons trade a drawback for a benefit. When the drawback is an affliction we already
block -- **Sure-Footed**: *"You are immune to the dizziness affliction."* -- that boon is
strictly free for us, and the offer screen is the only moment the information is worth
anything. Three seconds later the choice is made.

The offer screen now annotates each boon whose description names an affliction we are immune
to, saying which claimed boon blocks it.

### Derived from claim history, not a new flag

`M.runImmunities()` reads the current run's claims, which already carry their description,
already reset per run, and already survive a SYSUPDATE reload. A parallel latch would have been
a third thing to keep in sync with two that already work.

### Two things that stop it being misleading

**A bounded match.** `immune to the (.-) affliction` with a lazy capture will happily swallow a
whole clause -- *"immune to the sort of thing that causes affliction"* would invent an
affliction nobody has ever had. Rejected on length or an embedded space.

**The standing list is shown when nothing matched.** The per-boon match can only catch wording
we have seen: the grant says `dizziness`, a drawback may say `dizzy`, and no stemming turns one
into the other safely (`dizziness` minus `ness` is `dizzi`). So word forms live in a small
DATA table (`M.IMMUNITY_ALIASES`) extended as real lines appear, rather than a clever rule that
is wrong in ways nobody notices -- and when no offered boon matches, the immunities are simply
listed. A missed drawback reading as *"no drawback"* would be worse than saying nothing.

Deliberately **not** gated on `_inRun()`/telemetry: this is decision support for the player and
must work whether or not `mnem` reporting is on. `pcall`'d, because a display nicety must never
break the capture that feeds the catalogue and the API.

Files: `mnemosyne/004_Parsers.lua`. Suite **1049 -> 1056**; all three safeguards verified by
breaking the code back.

---

## 2026-08-06 - Roll Hide replaces the icewall (v4.7.223)

User: *"If we have roll hide boon, we dont need to icewall, just tumble out."*

Right, and the icewall was always the weaker tool. **It was never a barrier** -- denizens walk
through icewalls without Maklak's Promise, which the swarm doc has said since v4.7.119, so all
it ever did was PACE the swarm. For that it costs a balance-gated `point <bracers>`, a
wall-memory entry, and a melt cycle when the room empties. Roll Hide sheds every pursuer
outright: strictly better than pacing, and free of all three costs.

So while the boon is up, indoors takes the plain pull rather than wall mode, and the pull's
step-out becomes a **tumble**. That changes what the pull IS: a step-out is what lets the swarm
follow us into the funnel room -- the whole reason the funnel branch and the fly-kite exist --
whereas a tumble ends the fight instead of moving it, and those branches simply never fire.

Without the boon, nothing changes: wall mode and the plain step are untouched.

**Why the tumble is safe inside the single queue entry**, which was the one thing worth
checking: the entry's commands do NOT all run on one balance. The wall chain already proves it
-- `point` fires on the next balance and `leap` on equilibrium, draining across ~7s -- so a
balance-gated tumble is HELD by the queue until balance returns rather than rejected.

Files: `mnemosyne/009_Swarm_Tactics.lua`. Suite **1044 -> 1049**; both behaviours verified by
breaking the code back.

---

## 2026-08-06 - Auto-parry: pick by frequency, and stop waiting 3s to change (v4.7.222)

*(Numbered 222, not 221: a concurrent session committed into this same working tree between
this change's `git add` and its `git commit`, so the `v4.7.221` tag landed on THEIR commit --
whose `version.txt` still said 4.7.220. That tag's CI was cancelled and it published no
release, so nothing shipped wrong; the name is simply burnt. Lesson re-learned the hard way:
with a shared tree, stage explicit paths, never `git add -A`.)*

User: *"Our auto parry needs to be better or cleared and requeue faster."* From a Duke Semiro
log: over ~20 swings, **two parries landed**.

Three separate defects, all visible in that one log.

### 1. Following the LAST hit is the wrong rule against a mob that spreads

Semiro interleaves right leg, torso and head. Focus-follow parks the cover on the limb he has
just *finished* with, so we are permanently one swing behind -- the rule is actively
anti-correlated with a mob that alternates.

`selfLimbDamage.hitHistory` (rolling 6) already existed and **nothing in the PvE path was
reading it**. `ataxia_bashingParryFocus()` now takes the most-hit limb, ties broken toward the
more recent so a genuine focus-switch is still followed immediately rather than outvoted by
history. With no history at all it degrades to the old last-hit rule -- one observation is weak
evidence, but the ladder below it is none.

### 2. The broken-limb filter excluded exactly the limb worth covering

Focus-follow skipped any limb already broken. That is precisely backwards in PvE: a broken limb
that keeps getting hit is how `rl1` becomes `Rl2`, and how BOTH legs end up broken -- the state
that refuses our own attacks outright (`Both of your legs must be free and unhindered to do
that.`, which the log ends on). In this fight the right leg was both the most-attacked
parryable limb and broken most of the time, so the filter removed the only call worth making.

The predictive `fixed` path in 005 has always parked on a broken limb deliberately -- *"the
parry still fires on a just-broken limb"* -- so this only brings focus-follow in line with a
decision the codebase had already made and written down.

### 3. A 3-second lockout on a mob swinging every 2 seconds

`parryAttempted` exists to stop re-sending during the round-trip before the server confirms --
about 100-300ms. It was held for a flat 3s, so against Semiro we could change cover at best
every OTHER swing, and even a correct new choice arrived a swing late.

Trigger 757 (the confirm, gagged for display but still firing) now clears the guard the moment
the parry lands; the timer is only the fallback for a confirm that never comes, default cut
3 -> 1.5s. The fallback timer is tracked and killed on re-arm -- otherwise an earlier timer
fires later and clears the guard belonging to a newer send, re-opening the window it was armed
to close. Same stale-timer shape as the stun throttle in v4.7.219.

### The bug the fix created, and the trap behind it

A parried swing emits **no** `dealt N% damage` perceive line, so it never reaches
`ataxia_raiseLimbDamage` -- the only thing feeding `hitHistory`. Counting only unparried hits
would make the history under-represent exactly the limb the parry is succeeding on, so the
frequency pick would drift off it the moment it started working: **the parry would sabotage
itself.** `ataxia_recordSelfHit` is now shared, and `ataxia_parrySuccess` feeds it too.

Files: `self_limb_tracking/002`, `003`, `010_Prompt_Running.lua`, trigger `757_Parrying`.
Suite **1037 -> 1044**; all three fixes verified by breaking the code back.

### Also: the bladedance fire lines (triggers 043/044/045)

User: *"Lets also highlight and echo these"* -- the three `Spiral steps bleed into a perfect
staccato...` lines for Hawkstep, Harrying and Wave Dance.

They turned out to be worth more than a highlight, and the code already said so.
`ataxiaBasher_bardDance` refuses to re-buy a dance it believes is up (`ataxia.defences[def]`),
and `004_Defence_Sorting` records that hawkstep/wavedance had **never been seen in a live DEF
capture** -- so nothing was reliably setting that flag. These are the confirmations, so they
set it.

The three dances are mutually exclusive (AB: *"you can only dance one thing at a time"*), so
landing one CLEARS the other two. Without that the first dance of a session would leave its
flag set forever and the gate would refuse the dance we actually wanted for the rest of the
run. Colours (`deep_sky_blue` / `medium_purple` / `light_sea_green`) verified present in the
wholesale-replaced colour table; none from the reserved orange family.

---

## 2026-08-06 - Documentation pass for v4.7.214-v4.7.220

Docs only -- **no version bump and no tag**. The package contents are byte-identical to
v4.7.220, and bumping would push a release that prompts every user to SYSUPDATE for nothing.

| File | What was stale |
|---|---|
| `CLAUDE.md` | Roll Hide `panicAt` still said 40 and stopped at "10s cooldown"; tactical moves still described as always LEAP; no `S.disengage`; the Taken table still described as "shows only the worst offender"; `/boons_offered` payload; stun had no entry at all |
| `.claude/AGENTS.md` | Three new pitfalls: refusal-set flags need a failsafe; config-default changes need a ONE-SHOT migration; read the API schema instead of inferring field names |
| `.claude/classes/bard.md` | BACKFLIP over LEAP, where it does and does not apply, and the `acrobatics on/off` syntax |
| `mnemosyne/02-reporting.md` | `class`/`race` on `/boons_offered` + the normalisation calls in `M._charInfo()` |
| `mnemosyne/03-parsing-triggers.md` | Seasone row still said the burst SPENDS the tree; new section covering bank-then-leave and its two traps |
| `mnemosyne/05-commands.md` | `mnem swarm panicat` default |
| `mnemosyne/07-explorer.md` | Roll Hide heal-then-return, `S.disengage`, `S.moveVerb` |
| `basher/01-architecture.md` | Taken table (all types, per-type colour), HUD top-alignment, and the warning that this file is not unit-tested |
| `basher/05-safety-systems.md` | New stun section |

Memory files were updated per-release as the work shipped (`mnemosyne`, `bard`, `bug-patterns`,
`gui-windows`); no new memory files, so `MEMORY.md` needed no new index lines.

---

## 2026-08-06 - Send race and class with /boons_offered (v4.7.220)

The tracker author added `class` and `race` as optional arguments to `/boons_offered` so the
offer data can be sliced. Discord queries land Sunday/Monday; the collection starts now, and
data not gathered this week is data those queries will never have.

Field names and types were read from the live schema
(`http://104.128.56.238:8000/openapi.json`) rather than inferred from the sentence -- both are
top-level optional strings on `BoonsOfferedRequest`, not members of `BoonInfo`.

### Two judgement calls in `M._charInfo()`

**Class is normalised, race is not.** "Earth Lord" and "Earth Lady" are one class wearing a
gender suffix; leaving them distinct would halve every per-class count in exactly the queries
this data exists to answer. The basher's existing normalisation is reused verbatim, so the
values also match what the rest of the system already calls a class. Race gets no equivalent
treatment -- there is no known distortion to correct, and normalising against a vocabulary I
cannot verify would corrupt it more quietly than leaving it raw.

**Omitted, never guessed.** Both fields are optional server-side, so an absent or empty GMCP
read sends no key at all. A literal `"unknown"` would appear in the queries as its own cohort,
which is worse than a smaller honest sample.

Both branches of `_reportBoonsOfferedEnriched` -- the immediate post and the contemplate-enriched
one -- route through `reportBoonsOffered`, so the tagging lands on the real path either way.

Files: `mnemosyne/002_Reporter_API.lua`. Suite **1033 -> 1037**.

---

## 2026-08-06 - Stop losing time after a stun (v4.7.219)

User: *"You are no longer stunned. We need to be a bit faster to account for this because
there is a noticeable lag from this message to actually doing something."*

The dispatch itself was already immediate -- trigger 723 calls `ataxiaBasher_attack()` straight
off the line, bypassing the throttle. Two things around it were not.

### 1. The re-queue cooldown outlived the stun

`ataxiaBasher_atk` is the 0.3s window that stops us refreshing the server queue too often. It
is armed by the **last dispatch before the stun latched**, and the `tempTimer` that clears it
runs through the whole stun -- while `affed("stun")` blocked every `tryAttack`, so nothing
re-armed or consumed it. 723's direct call ignores the flag, but the *follow-up* prompt
dispatch does not: if that first round was refused or wiped, we sat out a window that had been
armed for a completely unrelated reason. It is now dropped on the way out, along with its
timer, so the timer cannot fire later and clobber a fresh one.

### 2. The stun flag had exactly one way out and no failsafe

`ataxia.afflictions.stun` gates `tryAttack`'s affliction check. Two of trigger 722's three
patterns are Vertani-soldier-specific, so in practice the setter is the **refusal** line ("You
are too stunned to be able to do anything") -- which fires for any stun source, because it
only appears when we tried to act. Exactly one line clears it, with nothing behind it.

Miss that clear -- a stun source with different wording, a split line, a lost packet -- and the
flag latches TRUE and the basher is blocked **until the next stun happens to print it**. That
is not lag, it is a stall, and from the chair it looks identical. Achaea stun is bounded at a
few seconds, so the flag now self-expires after 5s and dispatches on the way out: worst case
becomes five seconds instead of forever.

### What this deliberately does not do

Pre-queue during the stun. Beating the client round-trip needs a command already sitting on the
server, and the evidence says it would be burned rather than held: the refusal line exists and
is gagged in `011_GAG2`, which means queued commands *are* attempted mid-stun. Re-queuing
through the stun to compensate would re-run the whole round assembly each time -- spending
battlerage charges, deck picks and cooldown stamps on rounds that get refused, which is the
exact class of bug `ataxiaBasher_brCommit` exists to prevent. Not worth it without confirming
the server's behaviour first; see the note in `basher/001`.

Files: `basher/001_Bashing_Functions.lua`, triggers `722_Stunned`, `723_Stun_Gone`. New
`test_basher_stun.lua`. Suite **1025 -> 1033**; both fixes verified by breaking the code back.

---

## 2026-08-06 - Roll Hide: heal where we land, then go back in (v4.7.218)

User: *"the denizens wont follow so we can use this to our advantage to heal up and then do hit
and run tactics. We should set to do this around 35 percent health."*

### The tumble was only half the tactic

We already tumbled out on Roll Hide. What we did next threw the boon away: the panic dropped
straight to `idle`, which handed back to the explorer, and the `swarmHold` self-cleared after
`HOLD_TIMEOUT` (~8s) -- so within about eight seconds we **navigated back into the room we had
just fled, still at panic HP**. Shedding pursuers is worth nothing if you walk back into them.

The tumble now enters the same recovery state the escape ladder uses: navigation and attack
dispatch held until `recoverAt`% **and** affliction-free, self-ticking so it never waits on an
outside event to notice it healed. Then it hands back and the sweep goes in again -- which is
the hit-and-run cycle asked for.

### A ground recovery is not a hover

The existing recovery state assumed flight, where we are untouchable. This one is standing on
the floor, so it carries `recoverGround` and two differences:

* **a denizen wandering in ends it.** Standing there attack-gated at panic HP while something
  hits us is strictly worse than fighting it, so it hands back to the basher.
* **it does not send `land`.** It never left the ground, and noise in the escape path is how a
  real refusal gets missed.

Also: the panic no longer fires *while* recovering. Roll Hide already shed them, so a second
tumble sheds nothing and only walks us further from the sweep -- previously the 10s cooldown
was the only thing between a slow heal and a tumble every ten seconds, wandering the ripple.

### 40% -> 35%, and why it needed a migration

Changing the default alone would have changed nothing. `_cfg` **writes** its defaults into the
saved table and `ataxia` is serialized wholesale, so a literal `40` is already stored in every
config. Hence a migration -- but **one-shot**, behind a persisted marker: `panicAt` is settable
(`mnem swarm panic <n>`), and an unconditional rewrite would make 40 permanently untypeable,
dragged back to 35 by the next `_cfg()` call on the next tick.

Files: `mnemosyne/009_Swarm_Tactics.lua`. Suite **1019 -> 1025**; all four behaviours verified
by breaking the code back.

---

## 2026-08-06 - Bard backflips instead of leaping (v4.7.217)

User: *"When in bard, we should BACKFLIP (direction) instead of Leap as it is faster balance."*

Acrobatics BACKFLIP recovers quicker than the chitin-greaves LEAP, and every tactical move in
the tower is a retreat we are making because something is going badly -- the balance we get
back is the balance we spend curing.

### Where it applies, and where it deliberately does not

Only `S._tacticalGo` -- the general tactical mover behind the pull retreat, the low-HP escape,
the re-entry and the new disengage. The normal sweep already *walks* (`_exploreMove` sends a
bare direction), so there was no balance to save there in the first place.

**The four known-wall jumps stay on LEAP.** These are not merely movement -- their entire
purpose is to clear our OWN standing icewall, and greaves-LEAP is the ability we have confirmed
does that in both directions (it is why re-entry needs no melt):

| Site | Why it stays |
|---|---|
| `_escapeSuffix` wall-mode (both branches) | raising or crossing our own wall |
| `onTick` wall-mode re-entry | crossing back over it |
| explorer `"a wall blocks the way"` | an authoritative wall signal |

Whether BACKFLIP crosses an icewall is **not confirmed**, and the cost of guessing wrong is not
a slow move -- it is a silent no-op in the indoor low-HP escape, i.e. the anti-death ladder
livelocking at crash HP. That is the exact failure the LEAP was introduced to fix.

`S._tacticalGo` is the ambiguous one: it serves both plain pulls and walled retreats. It now
asks `S.moveVerb(dir)`, which reads the `wallRaised[room]` edge we already track (the panic
tumble reads the same field to avoid tumbling into our own ice) and returns `leap` when
crossing it, `backflip` otherwise. Unresolvable wall state falls back to LEAP -- the
conservative answer is the one that still moves us.

Files: `mnemosyne/009_Swarm_Tactics.lua`. Suite **1013 -> 1019**; both regressions verified by
breaking the code back.

---

## 2026-08-05 - Show every damage type in the Taken table (v4.7.216)

User: *"expand that all of the way"* -- the panel was showing ten types and `+1 more`.

The top-10 cap was mine, from the original "at least top 10" request, and it was the wrong
default. **The tail is where the surprises live.** The leaders are usually unremarkable -- of
course a Bard bashing physical denizens takes physical cutting -- but a 1% type that has no
business being there means something is hitting us we did not know was in the room, and `+1
more` hid exactly the row worth looking at.

The list is self-limiting anyway: it can only be as long as the types actually dealt to us this
session, and Achaea has under twenty. There was never a real risk of it running away.

`ataxiaBasher.takenTop` survives as an opt-in cap for anyone who wants one, and its `+N more`
tail still renders when it is set. The default is now `0`, meaning all.

Files: `windows/001_Limb_Counter_Window.lua`. Suite unchanged at **1013**; syntax-checked by
hand, since this file needs Geyser and the suite does not cover it.

---

## 2026-08-05 - Disengage from Seasone on the second phial burst (v4.7.215)

User: *"try that"* -- accepting the offer made after v4.7.213.

v4.7.213 stopped us wasting the tree tattoo on Seasone's first phial burst. That was right,
but it was only half an answer: **rationing one charge buys exactly one extra burst**, and the
death log has her throwing more than two. Each burst is a fresh truelock and there is one
tattoo. The fight is not winnable by out-curing her, so the second burst is not a cue to cure
harder -- it is the cue to leave.

### What it does

`M.onSeasonePhials` now counts bursts per ripple. On burst two (`ataxia.mnemosyne.phialDisengage`,
default 2) it:

1. **unbanks the tattoo** -- there is no burst three to save it for, and the tree is what keeps
   us alive during the retreat; and
2. calls the new **`S.disengage(reason)`**, which drives the proven escape ladder -- fly-and-hover
   outdoors, pull back to the cleared room indoors.

The recovery gate is what makes this a real disengage rather than a lap of the room: we do not
return until `recoverAt`% **and affliction-free**, so the lock has to actually be gone.

### Why a new entry point rather than reusing the ladder

The existing ladder is entirely **reactive** -- it fires when HP is already low. That is the
right default, and it is useless here. Against a kill pattern of "apply an unsurvivable lock,
then wait", by the time HP crosses `escapeAt` we are locked, and a locked character cannot be
relied on to execute an escape at all. `S.disengage` exists so a caller that can *recognise* a
losing pattern can leave while we are still healthy enough to obey.

It returns false rather than pretending: disabled, on cooldown, or indoors with no validated
route. A failed attempt deliberately does **not** stamp the 10s cooldown -- the caller that
read the fight as lethal gets to retry the moment a route exists.

### The bug found on the way in

Splinterbark took an early `return` that sat above *every* line of `onSeasonePhials`. The affix
taints the tree, so a Splinterbark Seasone got **no tattoo and no disengage** -- the one case
where leaving is the only answer left was the one case that did nothing. The gate now covers
only the tattoo half, and with no charge to ration the disengage moves to the **first** burst.

Also fixed in the test harness: `reset()` never cleared `ataxiaTemp`, so the burst tally leaked
between the Seasone tests and the second one to run silently exercised the disengage branch
instead of the banking branch it claimed to test. It still passed, which is what made it
dangerous rather than merely untidy.

Files: `mnemosyne/004_Parsers.lua`, `mnemosyne/009_Swarm_Tactics.lua`. Suite **1002 -> 1013**;
all three regressions verified by breaking the code back.

---

## 2026-08-04 - Push the HUD panel to the top of its window (v4.7.214)

User: *"Can we move this a bit up as we have the space."*

There was no padding to remove -- the gap is Mudlet's MiniConsole behaviour. A console
SCROLLS, so a buffer shorter than the window renders **bottom-anchored** and short content
floats downward, leaving a dead band above it. The panel had been doing that since it was
built; it only became obvious once the Taken table made the content long enough to notice the
contrast.

So `tarc:cecho` now counts the newlines it writes, and `tarc:padToTop()` appends blank lines
below the content at the end of every render -- which pushes the real content up to the top.

Derived from `getRowCount`, not a fixed number of blank lines, so it stays correct at any
window size and after a drag-resize. `pcall`-guarded and a no-op on failure: that API returns
nil for a console that is not laid out yet, and a HUD that errors is worse than one that sits
low.

### A near-miss worth recording

The first edit wrote `
` into the Lua source as a **literal newline**, producing
`gsub("<newline>", "")` -- an unterminated string, which would have failed to load the entire
window script. The unit tests cannot catch it (the window needs Geyser and is not covered), so
the only things standing between that and a broken HUD were the CI Lua syntax check and my own
`loadstring` check. Now a habit for this file: syntax-check it explicitly after any edit, since
the suite does not.

Files: `windows/001_Limb_Counter_Window.lua`. Suite unchanged at **1002**.

---

## 2026-08-04 - Seasone killed us because we spent the tree too early (v4.7.213)

A death log, and the user's read of it was exactly right: *"they are locking us. It has
happened twice. We should be saving the tree for the right time."*

### What the log shows

Seasone bursts her phials **repeatedly** -- twice in about eight seconds:

```
07:50:19  PHIAL BURST -- touching tree to break the lock (reserve released)
          You touch the tree of life tattoo.   -> cured anorexia, lock broken, 51% HP
07:50:27  PHIAL BURST -- touching tree to break the lock
          Your tree of life tattoo glows faintly for a moment then fades, leaving you unchanged.
          ...repeated to death at 3% HP
```

The first burst was **survivable** -- 51% HP, SSC curing through it. We spent the tattoo on it
anyway, because v4.7.138 made the burst touch tree immediately. Eight seconds later the second
burst landed at 27% with the tree still cooling down, and there was nothing left to break the
lock with.

The old handler then made it worse: it re-touched at +3s, +6s and +10s regardless of cooldown,
which is where all the "glows faintly... unchanged" spam comes from -- three blind sends per
burst into a tattoo that could not fire.

### Bank the tree until it counts

The burst now **arms a watcher** instead of firing. The tree goes out when the lock is still up
**and** either

- HP has fallen to `treeHp` (default **50%**) -- the lock is actually killing us, or
- `treeGrace` seconds have passed (default **5**) -- SSC has had its chance and failed.

If SSC breaks the lock on its own, the tattoo **stays banked for the next burst**. Against a
boss that locks repeatedly, the tree is a limited resource, and spending it on the first lock
guarantees having none for the second. On this log the new logic holds at burst 1 (51% HP,
lock clearing) and fires instantly at burst 2 (27%) -- with a tattoo that is actually ready.

Gated on `ataxiaTemp.usedTree`, the real cooldown flag, so it never fires blind again. And
hooked to the tree-ready line (`curing_bals/004`) as well as the timer, so the instant the
tattoo comes off cooldown mid-lock it goes straight out -- during a truelock the seconds
between ticks are the ones that kill.

The lock test also widened from `asthma and anorexia` to **any** of anorexia / slickness /
asthma / impatience: after the first tree cured anorexia the old condition stopped matching, so
a still-locked character read as clear.

### Two tests deliberately inverted

Two existing tests asserted that the burst touches tree *immediately* -- the v4.7.138
behaviour this death overturns. They now assert the banking instead. **That is a requirement
change driven by a corpse, not a test bent to pass**, and it is called out as such in the test
file, because the diff is indistinguishable from the illegitimate kind.

Nine tests here now, including that a lock SSC handles itself leaves the tree banked, that a
tainted tree is never spent however bad it gets, and that nothing is ever sent into a cooldown.

Suite 996 -> **1002**.

### Not fixed, and worth knowing

The tree cures **one** affliction, and at the moment it fired in this log we were carrying
fifteen. Even a perfectly-timed tattoo is one pull from a large bag. Banking it makes the pull
happen when it matters; it does not make it hit. If Seasone keeps winning, the answer is
probably to disengage on the second burst rather than to out-cure her -- say the word and I
will wire that.

---

## 2026-08-04 - Colour the damage-taken table, and stop prying every embrasure (v4.7.212)

### Damage taken, coloured by type

User: *"Is it possible to highlight these damage takens with their respective colors? Cold
blue, etc."*

`TAKEN_COLOUR` maps type -> colour, matched as an ordered SUBSTRING because the game names a
category and a subtype together: "physical cutting" must hit `cutting` before `physical`, and
"magical" must hit `magic`. Name and amount share the colour so a row reads as one unit -- the
point is to scan the table by colour ("is the blue one growing?"), not to read numbers -- and
the percentage stays grey so it never competes.

cutting steel-grey, blunt rosy-brown, **cold deep-sky-blue**, fire red, electricity yellow,
psychic plum, magic orchid, poison lime, asphyxiation slate, unblockable white, raw light-grey.
An unknown type keeps the old `indian_red`, which is itself the signal that we have not seen it
before.

**Fire is `red`, not the obvious orange** -- the orange family stays reserved. And every one of
the fourteen colours was checked against `007_Custom_Colour_Table` before shipping, by script:
that table WHOLESALE REPLACES Mudlet's, so a plausible-but-absent name (`crimson`, `silver`)
makes `fg()` throw, and in a per-prompt render that kills the entire HUD.

### Only pry the embrasure that changes

User, from a log of a working swap: *"We only need to pry out the one paragon and replace it,
not all of them."*

The swap pried **all three** embrasures and re-inserted **all three**, every time, on the
original reasoning that game state "can't be verified without a probe". But it IS tracked:
`state.currentSlots` is written both by the swap itself and by the `probe armour` trigger.
Borrowed Power changes exactly one slot, so five of the six commands were churn -- and every
needless pry is another chance to half-apply and leave an embrasure empty, which is exactly
the failure v4.7.211 had to fix.

Now a per-slot diff, compared by `paragonKey` so an id and a bare type name for one physical
paragon do not read as a change. A slot that already matches is left alone; an identical
profile sends nothing at all.

**The honesty guard is `slotsKnown`.** Until a swap or a probe has actually told us what is in
the armour, every slot is UNKNOWN and gets the old pry+insert treatment -- skipping on an
assumption would silently leave the wrong paragon in place. A known-empty slot is filled
without a pointless pry; clearing a slot pries without inserting.

Eight tests, including that unknown state still rebuilds all three.

Suite 988 -> **996**.

---

## 2026-08-04 - Borrowed Power emptied an embrasure (v4.7.211)

A live log, and the swap I shipped in v4.7.204 half-failed:

```
[Armour]: Borrowed Power -- the crit paragon is dead weight, swapping in metalliferous
You pry out an auspicious icosagon paragon ...
You pry out a resonate metalliferous paragon ...
You pry out a crucious paragon ...
You insert your paragon into the embrasure.
You insert your paragon into the embrasure.
That is not a valid paragon.          <-- third insert rejected
...
1: an auspicious icosagon paragon      2: a resonate metalliferous paragon      3: Empty.
```

### What went wrong

**A paragon is a physical object: it fits exactly one embrasure.** The live profile was
`{icosagon, metalliferous, crucious}` -- so when the swap replaced the redundant `crucious` it
chose `metalliferous`, *which was already in slot 2*. The resulting profile named one object
twice, the second insert was rejected, and slot 3 was left **empty**.

That is worse than not swapping at all, because by then the crit paragon has already been
pried out. The failure mode of a half-applied gear swap is strictly worse than the no-op it
replaced.

**And I had claimed this was handled.** v4.7.204 shipped a comment reading *"shifting goes
first because the willpower paragon is usually already slotted, and doubling it would waste
the embrasure a second time"* -- and then implemented only an ordering **preference**, with no
check anywhere. A comment describing a safeguard that does not exist is worse than no comment:
it is the reason I never went looking.

### The fix

`borrowedReplacementId(worn)` now takes the set the armour already wears and skips those
candidates. If nothing is spare it returns nil and the swap **refuses**, keeping the crit
paragon rather than emptying an embrasure. An explicit `armour borrowed use <id>` that is
already worn is refused too, rather than silently substituting something else.

### Comparing by TYPE, not by label

The first cut still double-slotted, and the new tests caught it. Comparison was by display
string, and one physical paragon has two spellings: a registered id resolves to whatever
`resolveParagonName` stored (`"metalliferous (7.5% resist)"`) while a bare name resolves
through `PARAGON_TYPES` (`"metalliferous (7.5% shifting resist)"`). A string compare calls
those different.

New `ataxia.armour.paragonKey()` collapses an id, a bare name or a display string to the
canonical type keyword. That is what "the same paragon" actually means here -- and it also
handles owning two paragons of one type, where slotting the second buys nothing anyway.

A second test caught a regression on the way: folding the name-fallback into the preference
loop made a *guessed* `metalliferous` beat a **known, owned** serendipitous. Registered ids
are now exhausted across all preferences before any bare name is tried.

Seven regression tests, built around the exact profile from the log. Suite 981 -> **988**.

### Your armour right now

Slot 3 is empty and the crucious paragon is in your inventory. `armour borrowed off` restores
the bash profile and re-inserts it; `armour bash` does the same. This release stops it
recurring.

---

## 2026-08-04 - Bard: cyclone cashes in stun or clumsy (v4.7.210)

User: *"bard should be using cyclone on mobs with stun or clumsy"*.

Same shape as Runewarden's Etch and Blademaster's Headstrike -- an ability that spends an
affliction **already on the denizen** -- so it reads the same per-denizen state layer
(`ataxiaBasher_dsHasAff`, PvP-inert via its numeric-id guard). Both afflictions come from our
own kit and are already modelled in `ataxiaBasher_BR_AFFS` (stun 4s, clumsy 7s).

**Priority: after the crowd abilities, before generic damage.** An exploit beats howlslash and
moulinet -- that is what makes it an exploit. It yields to charm and trill at 2+ denizens
because charm removes a mob from the fight entirely, and a bonus on one mob does not. Both
directions are tested.

### Three unconfirmed values, made settings rather than silent guesses

I do not know cyclone's command syntax, rage cost or cooldown, and this package has a habit of
turning a plausible guess into config that quietly never works. So all three are overridable:

| setting | default | why that default |
|---|---|---|
| `bardCycloneCmd` | `cyclone` | Bard battlerages here split between bare verbs (howlslash, moulinet) and `play <x> at <t>` (charm, trill); which family cyclone belongs to has not been observed |
| `bardCycloneRage` | 25 | the tier every other affliction-cashing battlerage costs (Headstrike, Etch, Firefall) |
| `bardCycloneCd` | 23s | same tier; tracked as a send-side TIMESTAMP since no fire line is captured -- a stale timestamp expires, a stuck timer id would skip the ability forever |

**If the command is wrong, it will now say so.** The game answers an invalid command with syntax
help, and `highlighting/042` (added yesterday, after the bare-`PERFORMANCE` and bare-`BOONS`
bugs) makes exactly that loud. This is the first feature shipped since that detector existed,
and it is precisely the case it was built for -- a guess that announces itself instead of
failing silently for dozens of releases.

### `ataxiaBasher_bardBattlerage` is no longer file-local

It was the only OWNED rotation still declared `local` (blademaster, monk and magi are all
global), which meant it could not be unit-tested at all -- and there were no bard battlerage
tests. Now global, with nine covering the cyclone branch: each affliction, the ordering both
ways, the cooldown, the rage gate, the configured overrides, and inertness when the
denizen-state layer is absent.

Suite 972 -> **981**.

---

## 2026-08-04 - Tantrum, a top-10 damage-taken table, and the bard defence words (v4.7.209)

Also documents the work that shipped inside v4.7.208 without a CHANGELOG entry: while that
release was being prepared in a concurrent session, I deliberately kept out of `CHANGELOG.md`,
`CLAUDE.md` and the version files to avoid clobbering it, and committed only explicitly-named
source files. Those entries are folded in below, marked.

### Tantrum -- a free battlerage once per ripple

> Your first battlerage ability per ripple costs no rage.

Mechanically this is **Rage-Fuelled with a different trigger**: that boon banks a free
battlerage per KILL, this one per RIPPLE. Both are the same STATE -- "one battlerage is free
right now" -- so both arm the same `ataxiaTemp.brFreeCharge`, and the whole payoff comes for
nothing: `ataxiaBasher_brFree()` already short-circuits all 37 `rageAfford` call sites AND the
eight culling-reap gates, and `brCommit`/`brSent` already spend it. The new code is one arming
function and a flag. Holding both boons needs no special case; modelling it as a counter would
be inventing a mechanic the text does not describe.

**Armed once per ripple, guarded on the ripple NUMBER**, not merely fired from `onRipple` --
the flag can be re-latched mid-ripple by `_relatchBoons`, a BOONS row or the claim alias, and
re-arming on any of those would hand out a second free battlerage in a ripple whose first was
already spent.

*A test caught a real mistake here.* My first cut inserted the `onRipple` call by matching
`ataxiaTemp.mnemNulled = nil` -- which appears **twice** in that file -- so it landed in
`onRunEnd`, firing as the run ENDED rather than as a ripple began. Silent in play (both guards
are false by then); Tantrum would simply never have armed. The fix relocates it by structural
position rather than a string that happens to repeat.

### HUD: top 10 damage taken, not just the worst

The single worst offender tells you what to armour against. The **shape** of the list tells you
something the leader alone cannot: whether one type dominates (worth a resistance paragon) or
the damage is spread across five, where no single resistance helps and the answer is to kill
faster or take fewer rounds.

Render-only -- `bashStats_incomingRanked()` already returned the sorted table. Count is
`ataxiaBasher.takenTop` (10), only rows that exist are drawn, and a `+N more` tail shows what
was clipped rather than silently truncating. New `_fmtShort` keeps columns narrow (`867k`,
`2.2M`), rounding rather than truncating, and names clip at 16 chars rather than wrapping,
since a wrapped row would destroy the alignment the table exists for.

### Bard defence words -- and a table I nearly broke

User: *"for the bard defence acrobatics the command is acrobatics on and acrobatics off"*.

**Three** tables use the word "acrobatics" and they do not mean the same thing:

| table | meaning | acrobatics |
|---|---|---|
| `classDefences` | class membership; only KEYS are read | values are commands -- bard had `"acrobatics on"`, **jester had the bare verb** (fixed) |
| `defenceWords` | what `ashow defs` DISPLAYS as the raising command | had only a depthswalker block, so a Bard was shown **nothing** (fixed) |
| `ataxiaTables.defences` (in `_groups.yaml`) | client-side name -> **server-side name** | `"acrobatics"` is **CORRECT** and must not change |

That third one is the interesting part: I had it queued as a bug and was about to "fix" it.
`supportedDefence()` iterates it as `csd, ssd` -- changing the value to a command would have
broken every `ataxia.defences[actual]` lookup. It was only caught by reading the consumer
before editing.

Two process notes from the same hunt. My `grep -rnE 'acrobatics\s*=\s*"acrobatics"'` returned
nothing because **ERE has no `\s`** -- the pattern silently matched nothing rather than
erroring, and I nearly concluded the entry did not exist. And a substring check reported the
bare form as still present when it was only the prefix of `"acrobatics on"`. Both are the
"verify, don't grep" rule again, in new clothes.

The bard `defenceWords` block lists only the three defences whose command differs from the
defence NAME -- `acrobatics on`, `blade tune`, `dance harrying`. Not aria/lay/songbird/
heartsfury, whose command is their name and which would add a column of noise. Only the
RAISING form is stored, since nothing lowers a defence by command (`defupFailsafe` tells SSC to
stop maintaining it); the OFF form is recorded in the comment because it is the half you need
by hand.

---

### Shipped inside v4.7.208, undocumented at the time

**PERFORMANCE SHOW, not bare PERFORMANCE.** The bare verb is not a command -- the game answers
with syntax help (SHOW / END / SUSPEND / RESUME). Worse than a no-op: trigger 001 never saw an
answer, so the probe always timed out and **always recomposed, every ripple**. A check added to
"ensure our stuff is up" was instead forcing a redundant recompose at every boon screen.

**This was the second time in one day**, and I had written the rule down after the first
(v4.7.203, bare `BOONS`). The test made it worse identically -- `toBe("performance")` pinned
WHAT we send with no notion of whether it was real. It now also asserts the shape
`^performance %a+$`.

So: **`highlighting/042` makes the next one loud.** Any `Syntax:` block is now highlighted with
an echo saying a command was rejected. Both bugs were found only because the user spotted one
in a log; nothing in the package reacted to it, and a rejected command is otherwise perfectly
silent -- no error, no missing state, just a feature that quietly does nothing forever.

**Gag the bard refusals with `deleteLine()`, not `deleteFull()`.** `deleteFull` also arms a
trigger to delete the FOLLOWING line if it is a prompt -- right for the ~50 command responses in
`006_GAG`, wrong for these two, which fire mid-combat-round where the next prompt carries our
vitals. Moved to their own trigger (`056`). I had added them to `006_GAG` twice without ever
reading that trigger's body; the pattern list looked like the whole interface.

**New highlights** (all colours validated against `007_Custom_Colour_Table`, which wholesale
replaces Mudlet's -- a plausible-but-absent name makes `fg()` throw on every match, as
`crimson` would have): clumsy proc (`037`, light_cyan, echo throttled to 3s since clumsy fires
several times a second in a crowd), bloodshield raised/lost (`038`/`039`, firebrick -- the loss
echoed because it arrives unannounced and means we are bare again), Sharp Mind (`040`,
light_blue), sonata cleanse (`041`, medium_sea_green -- deliberately the same green as the
dagaz passive heal, since both are "our passive cured us for free").

**Necromantic thrall** (`mnemosyne/060`) -- the affix line wanted since v4.7.196. A thrall is a
NEW DENIZEN IN A ROOM WE JUST CLEARED, which is exactly the state the auto-explorer trusts to
decide it is finished; it now nudges a room re-read rather than letting the sweep walk out on a
stale snapshot.

Suite 923 -> **972**.

---

## 2026-08-03 - Docs: `gearaudit scrap` is not what three docs said it was

### The docs described a safe command that isn't

`README.md`, `CLAUDE.md` and `GETTING_STARTED.md` all described `gearaudit scrap` as producing
"copy-paste `GEAR SCRAP` commands". It does not. `displayScrap` builds the queue and
**auto-sends every command**, one per balance, with no confirmation prompt -- it destroys gear
the moment you run it. Three docs, one wrong verb, and the one word that mattered was
"copy-paste". All three now say AUTO-SENDS, and `GETTING_STARTED.md` carries an explicit
warning block. `GETTING_STARTED.md` also gained the `show`/`detail` commands it never listed
and a note on the new non-truncating display.

### Never `git push --tags` in this repo

Releasing v4.7.208 followed the documented flow -- and the documented flow was wrong.
`git push --tags` pushes every local tag the remote lacks, and this clone carries stale ones
(`v4.7.46`, `v4.7.66` from July). Each fired the `v*` release workflow, which built **that
tag's old source** and published it. GitHub picks "Latest" by **publish time, not semver**, so
the last stale release to finish became `/releases/latest` -- the exact URL `sysupdate`
downloads from (`releases/latest/download/Levi_Ataxia.mpackage`).

For a few minutes `sysupdate` would have installed a two-week-old package while `version.txt`
on raw `main` still advertised 4.7.208. Only the `onInstalled` version cross-check (v4.7.57)
stood between that and a silent downgrade. **The version CHECK reads raw `main`; the version
DOWNLOAD reads `releases/latest`. They are different sources and they can disagree** -- "the
updater is fine, it reads version.txt" is a half-truth.

Repaired with `gh release edit v4.7.208 --latest`, then
`gh release delete <stray> --yes --cleanup-tag=false` on both strays -- which drops the bogus
release but keeps the tag, so the July commits stay referenceable.

The instruction is corrected at both sites that carried it: the release-flow step in
`CLAUDE.md` and step 4 of the `/build` skill now say `git push origin v<version>`, with the
reasoning attached so it doesn't get "simplified" back.

**Files:** `README.md`, `CLAUDE.md`, `GETTING_STARTED.md`, `.claude/skills/build/SKILL.md`.

---

## 2026-08-03 - The gear table stops lying about what your gear does (v4.7.208)

### Three separate truncations, and the worst one was invisible

`gearaudit show` rendered a box table whose column widths were four hardcoded literal border
strings. It cut text in three places, and only two of them left a `..` to tell you it had:

- **Set column** -- `:sub(1, 28)` with **no ellipsis at all**, which is why every row read
  `Death Knight's Steel Encasem` and `Dungeoneer's Accoutrements o`. Silent.
- **Effects column** -- `> 40` chars became `sub(1, 38) .. ".."`.
- **`summarizeEffect`'s fallback** -- `effects[1]:sub(1, 30) .. ".."`, and this was the real
  damage. **Roughly half of a 147-item inventory hit that fallback**, because
  `summarizeEffect` had no pattern for those effect families at all. What looked like a
  cramped column was actually the summarizer giving up and printing a sentence fragment:
  `Your attacks will deal 15% bon..`, `Increases the damage of your c..`,
  `When sustaining bleeding from ..`.

The table is now **auto-sized**: ID/Set/Slot take the width of their widest actual value,
Effects takes whatever is left of the console (`getColumnCount()`, pcall-guarded, clamped to
`config.display.maxWidth`, floored at `config.display.minEffects`), and long effect text
**wraps onto indented continuation rows** instead of being cut. Nothing is truncated anywhere
in `gearaudit show` / `set` / `slot` / `effect` any more. The four literal border strings that
had to be kept in lockstep by hand collapsed into `gearAudit.tableRule()` /
`gearAudit.tableRow()`, with `gearAudit.wrapText()` doing word-boundary wrapping (and
hard-splitting any single word too long for the column, so a pathological effect string can't
push the border out of alignment).

`gearaudit bis` gets the same treatment -- its own `> 35` cut is gone, with continuation lines
aligned under an uncoloured twin of the row prefix.

`gearaudit scrap`'s 60-char summary and `gearaudit detail` (which always printed raw effects
in full) are unchanged.

### The effect families nothing could read

The fallback was hiding the actual bug: `summarizeEffect` **and** `scoreEffect` were both
missing ~10 whole families of gear effect. Because `scoreEffect` feeds `calculateScore`, that
meant `gearaudit bis`, `gearaudit score` and `gearaudit scrap` were valuing crit damage, crit
chance, rage generation and bonus denizen damage at **exactly zero** -- a hands slot full of
crit gear ranked purely on whatever else the item happened to carry.

Now summarized and scored: bonus damage (`bonusDmgPct`, 10.0 -- it is the same stat as
`addDmgPct`), crit chance (5.0), crit damage (4.0), battlerage damage (3.0), rage generation
(2.0, **negative for the "generate N% less rage" form**), battlerage rage generation (2.0) and
bleed-conditional damage (2.0). Also summarized but deliberately **not** scored: on-crit
clauses, stored-battlerage clauses, execute thresholds, respawn modifiers, and XP-loss
reduction -- none of them are PvE damage output.

The "generate N% **less**" pattern is tested before the generic "generate N%" one in both
functions; reversed, a rage penalty scores as a bonus.

Every new pattern is **safe-fail by construction**: a wrong guess about the tail of a sentence
simply doesn't match, and the row then falls through to the full raw text -- which is now
readable rather than a 30-char stub, and is exactly what a corrected pattern gets written
from.

### Two pattern bugs fixed

- **`ignore (%d+)%% of a denizen's (.+) resistance`** -- effects are concatenated with a space
  before matching, so the greedy `(.+)` swallowed every following sentence into the resistance
  *type*. That is the `Ignore 8% Phys blunt resistance. Your ..` row. Now `(.-)`.
- **`chanceEffect:sub(1, 20)`** -- a second truncation buried inside the summarizer, producing
  `5% trigger a defence wh`. Removed; the display wraps instead.

### Note on `gearaudit scrap`

`displayScrap` builds `GEAR SCRAP <id> CONFIRM` for every recommendation and **auto-sends the
queue immediately**, one per balance, with no confirmation prompt. Adding stats to the scoring
changes which items fall below `scrapThreshold`, so it changes what gets destroyed. Review the
new `gearaudit bis` ordering before running it.

**Files:** `gear_system/001_Gear_Audit.lua` (config `display` block + 7 new `bisWeights`;
`consoleWidth`/`wrapText`/`tableRule`/`tableRow` helpers; `summarizeEffect`, `scoreEffect`,
`calculateScore`, `display`, `displayBis`), new `tests/test_gear_audit.lua` (47 tests),
`.luacheckrc` + `.vscode/settings.json` (`getColumnCount` and friends as known Mudlet globals).

---

## 2026-08-03 - DPS reworked, and what is hitting us tracked by type (v4.7.207)

### Both DPS numbers were misleading, each differently

**"Avg" was `totalDamage / wall clock since the stats were reset`.** Every second spent not
fighting divided it down -- walking to the next area, resting, hovering to heal, sitting on
the boon screen, going AFK. It measured *how long the client had been open*, not how hard we
hit. Reset your stats and idle an hour and a perfectly good session reads near zero.

It now divides by **active combat seconds**: `bashStats.combatTime` accumulates only the gaps
between hits that are short enough to still be a fight (`bashStats_COMBAT_GAP`, 10s). A test
pins the difference -- 10,000 damage over 5 seconds of fighting followed by an hour idle now
reads **2000.0/s**; the old figure was 2.8/s.

**"Now" was a single balance's damage over that balance's duration.** One crit spiked it, one
miss zeroed it. It flickered too hard to read mid-fight, which is the only time you'd look.

It is now a rolling **10s window** -- the same shape the incoming-damage watchdog already used
(`ataxiaBasher_dmgSamples`), so the pattern was proven in this codebase before being borrowed.
Dividing by the whole window rather than by the span of the samples is deliberate: it decays
to 0 when we stop hitting instead of showing the last burst forever.

Both labels now say which is which (`10s`, `fighting`), because the numbers mean something
different from what they used to and a stale reading of either is worse than none.

### Damage taken, by type

> Health lost: 1488 (physical cutting).

New trigger `351_Health_Lost_By_Type` tallies incoming damage per type for the session.

Deliberately **separate from `bashStats.damageByType`**, which is our *outgoing* damage -- the
two would be trivially easy to conflate and the resulting panel would be nonsense. Incoming
lives in `incomingByType` / `incomingTotal` / `incomingHits`.

The type is kept **whole** ("physical cutting", not "cutting"): the game names a category and
a subtype, and collapsing them would merge things that want different answers. Case and stray
whitespace are normalised so one type stays one bucket.

**The HUD shows only the worst offender**, with its share -- because that is the one figure you
act on mid-hunt: it picks the resistance paragon, the Blademaster infuse to keep up, and which
curing priorities matter. The full ranking is in `bashstats`, biggest first, ties broken
alphabetically so the order is stable between calls.

New `test_bash_stats.lua` (20 tests) covers both. Suite 903 -> **923**.

Files: `basher/003_Bash_Stats_Functions.lua`, `350_Damage_Dealt.lua`, new
`351_Health_Lost_By_Type.lua`, `windows/001_Limb_Counter_Window.lua`,
`levi/003_Show_Bashing_Stats.lua`, new `tests/test_bash_stats.lua`.

---

## 2026-08-03 - Bravado: the affix that takes our answers away (v4.7.206)

> **Bravado:** You are perpetually reckless and unable to benefit from shields, prismatic
> barriers, or blood barriers.

User: *"we need to be careful since we will never know our health pool. We need to hit and run
at two denizens instead of 3 as it can get pretty wild."*

### It removes answers rather than adding a threat -- which is worse

Most affixes make something hurt more. This one silently turns **three** of the basher's
defensive responses into no-ops, and each keeps costing us while returning nothing:

| what | cost of the no-op |
|---|---|
| `touch shield` | the danger-level response **and** the escape ladder's fallback -- a whole round, and the basher then believes it is covered |
| **Maran** | the emergency 5000hp *prismatic* barrier -- charges regenerate **one per hour** |
| `activate bloodshield` | the Blood Maiden cloak's *blood* barrier -- one charge costs **five kills** |

All three are now gated on `ataxiaBasher_bravado()` / `mnemBravado` at their spend sites, in
both the out-of-tower path and the Mnemosyne card layer.

The shield one is worth separating out, because skipping it is not a saving -- it is a
**correction**. `danger == "shield"` used to spend the round on `touch shield` and return.
Under Bravado that round bought nothing *and* the code carried on as though mitigated. It now
falls through to the attack, because clearing the room is the only mitigation the affix leaves.

### Hit and run a denizen earlier

`S.threshold()` clamps to `swarm.bravadoThreshold` (default **2**) while the affix is up. It
**clamps down only** -- a threshold already at 2 is untouched and a higher one is pulled in
rather than overwritten, so the setting still means something the rest of the time. It clamps
the deep-ripple threshold too, not just the base one.

The user's framing is the right mental model and worth recording: *"we will never know our
health pool."* With every mitigation off, the number on the prompt is all there is -- nothing
absorbs the spike, nothing eats the burst -- so the swarm tactics become the only thing left
standing between us and a bad round.

### A sloppy assertion of mine

The first Maran test asserted that nothing at all is drawn at 15% HP under Bravado. Wrong: at
15% both Maran (<=20) and **Seasone** (<=35) qualify, and Seasone is an *elixir*, not a
barrier -- Bravado has no opinion about it, so drawing it is correct. The assertion is now
"not Maran, and the elixir instead", plus a second case where Maran is the only card that
could qualify. The code was right; the test premise was not.

Affix flags now **four** (`mnemHaemophiliac`, `mnemDeluge`, `mnemLastWord`, `mnemBravado`),
so the run-start reset block is 32 boons + 4 affixes = 36 lines.

Files: `basher/001_Bashing_Functions.lua`, `basher/010_Mnemosyne_Legend_Deck.lua`,
`mnemosyne/009_Swarm_Tactics.lua`, `mnemosyne/004_Parsers.lua`, `mnemosyne/001_Run_Start.lua`,
new trigger `mnemosyne/059_Bravado.lua`, tests `test_swarm_tactics.lua`, `test_mnemosyne.lua`,
`test_mnem_ldeck.lua`. Suite 892 -> **903**.

### Captured in the same screenshot, still NOT implemented

- **Necromantic:** *Denizens may revive as mindless thralls.* (flagged since v4.7.196 -- the
  one I would most want a capture of, since a room that clears and then repopulates from its
  own corpses is exactly what `_roomHasDenizens` is trusted for)
- **Meldscorned:** *Denizens cause additional Shadowmancy afflictions on their attacks.*

---

## 2026-08-03 - Paragons by name (game change, same day) (v4.7.205)

> Paragons can now be referred to by the paragon name. For example, INSERT CRUCIOUS INTO
> FULLPLATE will now work instead of having to know your crucious paragon's ID.

This lands the day after the armour layer grew a feature that depended on knowing IDs, and it
removes that layer's one real dead end.

**A profile slot may now hold either form** -- a registered id (`paragon514466`) or a bare type
keyword (`crucious`) -- so every reader has to cope with both. `ataxia.armour.paragonName`
resolves in that order: a registered id wins (it is *proven* to exist on this character), then
a known type keyword, then the raw string. `isBorrowedRedundant` inherits this, so a
name-slotted profile is understood exactly like an id-slotted one.

**Borrowed Power no longer gives up when nothing has been scanned.** It used to return "no
willpower/shifting paragon known -- run `armour scan`" and do nothing, which meant the whole
feature was inert on a character who had never scanned. A name works without a scan, so the
fallback is now the type keyword `metalliferous`. A registered id is still preferred where we
have one.

### The stub that hid the bug

Five tests failed against a *correct* implementation, because the test file stubbed
`ataxia.armour.paragonName` with a one-liner that only read `config.paragons[id]` -- and that
stub is precisely the function whose new name-resolution the tests existed to check. **A stub
of the function under test proves nothing about it.**

Fixed by slicing the real `PARAGON_TYPES` and `paragonName` out of the source alongside the
Borrowed Power helpers, rather than reimplementing them in the fixture. Same lesson as the
`darkshadeTracker` fixture in v4.7.194, from the other direction: there a fixture *invented*
state production never created; here a stub *simplified away* behaviour production does have.
Either way the fixture was the thing being tested.

Files: `gear_system/002_Armour_Paragons.lua`, test `test_borrowed_power.lua`.
Suite 885 -> **892**.

---

## 2026-08-03 - Borrowed Power swaps the dead paragon out, and Bard checks its performance (v4.7.204)

### Borrowed Power

> Your critical hits can now reach plane-razing level without requiring paragons or the Psion
> class. **This does not stack with those effects, however.**

That last sentence is the actionable part: while the boon is up, the paragon buying crit tier
sits in an embrasure doing nothing. User instruction -- put the willpower or shifting-damage
one there instead.

**Which paragon is dead.** Plane-razing is a crit TIER, so it is `crucious` (crit multiplier).
`icosagon` is crit CHANCE -- how *often* we crit, which the boon does not grant -- so it is
deliberately left alone. The boon says it does not stack with the tier effect, not that it
replaces the whole crit kit. `ataxia.armour.config.borrowedRedundant` holds that judgement if
the reading proves wrong.

**How.** Rather than prying slots by hand, it builds a `borrowed` PROFILE from the bash one and
hands it to `ataxia.armour.swap`, which already owns the pry/insert sequencing, the morph
handling, the swap guard and its watchdog. It is an ordinary profile: visible in `armour show`,
editable with `armour set`.

**Reverting matters more than swapping.** The boon is per-RUN. A swap left in place would
quietly cost the crit paragon everywhere *outside* the tower, on every mob, indefinitely -- a
far worse outcome than never swapping at all. It reverts on the confirmed run end, and
`armour borrowed off` forces it back by hand for a run that ends without that confirmation.
Three tests cover the revert specifically, including reverting to whatever `bashProfile`
actually names rather than a hardcoded "bash".

Timing: the swap runs from the `BOON CLAIM` intercept as well as the BOONS row, because
claiming happens at the boon screen -- out of combat, explorer paused. That is when it is safe
to be prying armour apart.

`armour borrowed [on|off|use <paragonID>]` to inspect or override. Refuses safely and says so
when no willpower/shifting paragon is known, rather than guessing at an ID.

### Bard: ask PERFORMANCE after the boon screen

User: *"When in Bard after selecting the boons, we should send the command PERFORMANCE to
ensure we have our stuff up and running."*

Everything else that knows about the bash performance is **reactive** -- the fade line (002),
the "not in fact performing" error (005), the "already performing" refusal (006, new
yesterday). Every one of them needs something to go wrong first. `PERFORMANCE` is the one cheap
way to *ask*, and the boon screen is exactly the gap a performance can lapse across unseen.

`M._bardPerformanceCheck()` runs from both explorer entry points, next to the armour re-wear --
`_exploreResume` being the per-ripple one that GO calls after every boon screen. Trigger 001
parses the answer and clears the probe stamp; if nothing clears it inside 2s the honest reading
is "not performing", whatever the game actually said, so it recomposes. That covers a reply
wording we have never captured **without guessing at it**.

Boon flags now **32**.

Files: `gear_system/002_Armour_Paragons.lua`, `mnemosyne/008_Explorer.lua`,
`mnemosyne/004_Parsers.lua`, `mnemosyne/001_Run_Start.lua`, `mnemosyne/002_Boon_Claim.lua`,
new trigger `mnemosyne/058_Borrowed_Power.lua`, `performance_tracking/001`, new test
`test_borrowed_power.lua`, `test_mnemosyne.lua`. Suite 865 -> **885**.

---

## 2026-08-03 - The boon re-latch has never worked, and the compose was on a timer (v4.7.203)

Both found in one live log the user posted about a mis-timed recompose.

### The re-latch sent a command that does not exist

The log carried this, unprompted, in the middle of combat:

```
Syntax:
   BOON CLAIMED
   BOON OPTIONS
   BOON CLAIM <boon name>
   BOON CONTEMPLATE <boon name>
```

That is the game rejecting a command. `M._relatchBoons()` sends **`boons`** -- and `BOONS` is
not one of the four valid forms. **So the boon re-latch has never re-latched anything since it
shipped in v4.7.188.** It fired once per run, printed a syntax block into the combat scroll,
and did nothing.

Sobering, because the function was worked on three times without anyone checking the command
existed: shipped in v4.7.188; "corrected" in v4.7.192 when its guard was moved off the
serialized namespace (a real bug -- inside a no-op); and read by the Codex adversarial review.
Every pass reasoned about *when* to send and never about *what*.

The unit test made it worse rather than catching it: it asserted `expect(seen[1]).toBe("boons")`
-- pinning the implementation string with no notion of whether it was a real command, so it
passed for the feature's entire dead life. **A test that asserts what we send is not a test
that we send something meaningful.** It now also asserts the `boon <verb>` form that every
other boon command in the package already used -- `boon claim`, `boon contemplate` -- which was
the tell sitting in plain sight the whole time.

Now sends `boon claimed`: it lists owned boons as `<name>  <echoes>  <rarity>`, exactly the row
`mnemosyne/013_Boons_List_Row` parses and exactly the shape of every per-boon flag trigger
(`^Songstep\s+\d+\s+\w+`).

### The compose was driven by a timer instead of the performance

> (LEVI): Bard bash: composed paean prelude scherzo sonata maqam
> **You are already performing, wordsmith.**
> ...
> **Your performance fades away into silence.**

User: *"I think this happened too soon... we should've put it back up based on the
performance."* Exactly right, and the log shows the full failure: the 15-minute timer fired
while the song was still running (refused), and then the performance ended moments later with
nothing to replace it -- leaving the bard performing **nothing** until some later command
errored and trigger 005 finally noticed.

A timer cannot stay in phase with the real thing. The package's own rule -- prefer the game's
own line to a guess about timing -- just had not been applied here:

- **`002_Performance_Ended`** ("Your performance fades away into silence.") now recomposes.
  That is the authoritative end and the right moment to put a new one up.
- **New `006_Already_Performing`** handles the refusal. It is not noise: it says the song is
  still up, so it re-asserts `bardperformance` and pushes the backstop timer out from *now*
  rather than letting it retry immediately -- which is what kept it out of phase.
- The 15-minute timer stays as a backstop for a fade line we somehow miss; trigger 005 stays
  as the last-resort catch.

### Seen in the log, left alone

`You aren't wearing a Lasallian lyre.` -- `ataxiaBasher_bardCompose` opens with
`remove lyre;wield left lyre`, and the `remove` fails harmlessly when the lyre is not worn. I
have not touched the sequence: the `remove` presumably exists for a reason I cannot see from
one log, and guessing at it risks breaking the compose for the case it was added for. Worth a
look if it bothers you.

Files: `mnemosyne/008_Explorer.lua`, `performance_tracking/002_Performance_Ended.lua`, new
`performance_tracking/006_Already_Performing.lua`, test `test_mnemosyne.lua`.
Suite 864 -> **865**.

---

## 2026-08-03 - Roll Hide: tumble at a real HP number, and go somewhere known-safe (v4.7.202)

> **Roll Hide** (rare) -- Tumbling out of a room will cause you to lose all pursuing denizens.

User: *"We are entering critical health, like 3000, we should tumble out into the room we
just cleared."* Two changes to a boon that already worked.

### An absolute HP floor beside the percentage

`panicAt` was a percentage only (40%). Percent and absolute answer genuinely different
questions and both matter: **40% means "this fight is going badly", 3000 means "the next hit
can kill me".** With a large max HP the percentage alone leaves an enormous buffer before it
fires; with a small one it fires far too early. So `swarm.panicHp` (default **3000**) sits
alongside it and **whichever line is crossed first** triggers the tumble.

`mnem swarm panichp <hp|off>` configures it; `off`/`0` restores percentage-only behaviour.
A missing or blackout HP reading never fakes a panic -- 0 means "unknown", and the percentage
branch is already the general safety net.

Both the per-tick gate and the per-prompt `onVitals` gate now route through one predicate
(`S._panicHpHit`) so the two can never drift apart.

### Tumble into the room we just cleared

The old direction rule was "any planar exit that is not back toward the swarm room" -- which
means it deliberately preferred an **unexplored** room, and an unexplored room can hold
anything. That is a poor destination at 3000 HP.

The cleared room is the one square on the grid we know is empty, and since Roll Hide sheds
every pursuer we arrive there **alone** -- which is the entire point of tumbling rather than
walking. `S._backDir()` already computes the validated route to it (planar, adjacency-checked
against the reported-exit graph, never "up" into the holding room); it is the same machinery
the escape ladder's indoor retreat uses. The old heuristic remains as the fallback for when
no validated back-route exists -- still better than dying in place.

### The wall the test remembered

The first cut preferred the back-route unconditionally, and a test failed immediately: **the
indoor icewall tactic raises its wall on exactly that back edge and LEAPS over it.** A plain
`tumble <back>` would have walked into our own ice and failed -- wasting the panic *and* its
10s cooldown at the worst possible moment. The back-route is now checked against
`S.wallRaised` first and falls through to the heuristic when the edge is walled.

That test ("panic tumble avoids the walled edge in a fight-in-place room") was written for
exactly this class of mistake, and it earned its keep on the first run.

Files: `mnemosyne/009_Swarm_Tactics.lua`, `mnemosyne/003_Commands.lua`, test
`test_swarm_tactics.lua`. Suite 856 -> **864**.

---

## 2026-08-03 - Hawkstep at ripple 25, not 5 (v4.7.201)

User, correcting yesterday's guess: *"Higher ripples at like 25 plus. That is when the
difficulty increases."*

`ataxiaBasher.bardHawkstepRipple` 5 -> **25**.

I had anchored the guess on the boss cadence -- every 5th ripple is a boss -- and that was
the wrong reasoning, not just the wrong number. **Boss frequency is not difficulty.** The
practical cost of being wrong by a factor of five: the bard would have switched into
defensive Hawkstep at ripple 5 and stayed there for twenty ripples of easy rooms, trading
away Harrying's **+50% damage** for a resistance bonus against nothing much -- and paying a
balance swing for the privilege of doing so.

A second test now pins the easy range explicitly (ripples 1, 5, 10, 15, 20 all stay on
Harrying), because "5" passing was exactly what a too-low threshold would look like.

All three Songstep thresholds are now the user's numbers rather than inferred: ripple 25,
2+ denizens, and bosses.

**Recorded as general tower knowledge, not just a bard setting:** ripple ~25 is where
Mnemosyne's difficulty steps up. That is the number to reach for anywhere depth-scaling is
wanted -- notably `mnem swarm deep <r> <n>`, whose `deepAt` has no default and has been
waiting for exactly this.

Files: `basher/002_Class_Bashing.lua`, `mnemosyne/057_Songstep.lua`, test
`test_bm_infuse.lua`. Suite 855 -> **856**.

---

## 2026-08-03 - Songstep: a dance is a state, not a rider (v4.7.200)

New legendary Bard boon:

> **Songstep** -- Your dances gain additional bonuses. Hawkstep: Gain 25% resistance to
> damage. Wavedance: Ignore 75% of a denizen's resistance. Harrying: Deal 50% bonus damage.

### The cost is the whole design

AB Hawkstep (3193) is **"3.00 seconds of BALANCE"**, and the AB says outright that *"you can
only dance one thing at a time"*. Those two facts decide the entire shape.

Every previous Mnemosyne rider in this package -- the Shindo storms, chrono blur, deathaura --
spends EQUILIBRIUM, so it rides free beside the swing and can be re-asserted whenever the
defence drops. A dance cannot. It spends the swing itself, and the dances are mutually
exclusive, so this is a **state we switch**, not a buff we maintain. A naive "keep the right
dance up" rider would have attacked *never*.

So `ataxiaBasher_bardDance` returns `""` on almost every round. It sends a dance only when the
wanted dance differs from what is actually up, and then holds for 8s so an unconfirmed dance
cannot cost every balance from there on. On a switching round the dance **replaces** the
attack (the battlerage still rides -- that is rage, not balance).

### Which dance

| dance | when | why |
|---|---|---|
| Wavedance | **bosses** | ignoring 75% resistance answers the one denizen whose resistance matters |
| Hawkstep | higher ripples, or **any** room with 2+ denizens | 25% damage resistance; those are the rooms that kill |
| Harrying | lower ripples -- the default | +50% damage when nothing is threatening |

Boss beats crowd: a boss room may hold adds, but the boss is what the round is about. There is
a test for exactly that, and its inverse -- an add in a boss room is not the boss.

### Two honest gaps

**The ripple number is mine, not yours.** You said "higher ripples" without one, so
`ataxiaBasher.bardHawkstepRipple` defaults to **5** and wants tuning from play. The crowd
threshold (`bardHawkstepAt`, 2) and the boss rule are exactly as specified.

**`hawkstep` and `wavedance` as defence names are inferred.** `harrying` IS a GMCP-tracked
defence (it is in the bard block of `deffing/004`), so the dances do surface as defences and
that is the authority for "what am I already dancing". The other two are assumed to follow the
same naming -- consistent, but not verified against a live capture. The attempt-hold is what
makes that safe to ship: if a name is wrong we re-dance once per 8s instead of every round,
which is visible and cheap rather than silent and ruinous. If a capture shows otherwise, only
`BARD_DANCES` needs changing.

Boon flags now **31**.

Files: `basher/002_Class_Bashing.lua`, new trigger `mnemosyne/057_Songstep.lua`,
`mnemosyne/001_Run_Start.lua`, `mnemosyne/002_Boon_Claim.lua`, `mnemosyne/004_Parsers.lua`,
test `test_bm_infuse.lua`. Suite 839 -> **855**.

---

## 2026-08-02 - Gag the nomos refusal spam (v4.7.199)

> The sundering note of the Nomos already keens forth from your blade.

Added to the `GAG` trigger (pattern 51). **`type: 2`, not `type: 3`** -- the tail names the
weapon, so an exact whole-line match would silently never fire, which is the trap that shipped
two dead triggers earlier in this arc. Anchoring at the line head also keeps it from gagging
somebody quoting the line over a channel, which a bare `type: 0` substring would.

Safe to gag: nothing reads this line. The Nomos triggers that do matter are the shield-shatter
and the whiffed-shatter (`335_Mob_Razed`, `composition/008`), and neither is this one.

### Worth a look separately

This is a REFUSAL line, and refusals are state data (AGENTS.md). It says the blade song is
already sung -- so the Bard rotation is naming `nomos` on a blade that already has it, every
swing. `ataxiaBasher_bardBashing` builds `blade flick <t> nomos` / `blade punctuate <t> nomos`
(basher/002:411,415), which is the normal attack syntax rather than a separate re-application.

What is not known, and what decides whether this matters: **when that line prints, does the
flick still land?** If it does, gagging is the whole fix. If the refusal eats the attack, the
basher is losing a swing every time and the rotation should stop naming the song once it is
up. Gagged either way as asked -- the line is spam regardless -- but the answer is worth
capturing, because the fix is very different in each case.

Files: `006_GAG.lua`. Suite unchanged at **839** (a gag pattern has no extractable logic).

---

## 2026-08-02 - Control-first denizens: spend battlerage on their balance, not their health (v4.7.198)

User: *"a manifested nightmare -- when facing this denizen we need to use as many battlerages
that slow their attacks down as possible."*

Some denizens hit hard enough that a battlerage spent on **its** balance is worth more than
the same rage spent on our damage. `ataxiaBasher.controlMobs` is the list of them (seeded
with `manifested nightmare`, managed with `bash control add|rem <name>`), and
`ataxiaBasher_controlFirst()` is the predicate the rotations consult.

**It only REORDERS abilities each class already owns -- it never adds one.** The affliction
model already names the family: `ataxiaBasher_BR_AFFS` calls it `role = "safe"` (aeon, stun,
weakness, amnesia, clumsy).

| class | what control-first promotes |
|---|---|
| Blademaster | Daze (Stun 4s) **and** Nerveslash (Weakness, mob deals 66% damage) ahead of damage |
| Magi | Dilation -> Aeon -- literally "the mob attacks slower" |
| Depthswalker | Chrono Curse -> Aeon |
| Golden Dragon | Deaden (Aeon), Psidaze (Amnesia) |
| Runewarden | Bulwark -- see below |
| Psion, Monk | nothing; neither owns an attack-slowing battlerage |

**Runewarden -- worth being straight about, since it is the current class.** It has *no*
battlerage that slows a denizen: Etch **consumes** aeon/stun rather than applying it, and
onslaught and collide are pure damage. Bulwark (negate 25% of all damage for 15s) is the
nearest equivalent, so it is flagged too -- which keeps it from being displaced by the
Rage-Fuelled "spend the dearest first" rule that would otherwise pick onslaught (36r).

### `slows`, not `control` -- and the test that caught it

The first cut reused the existing `control` key. That key already means something else in
`dwBattlerage` and `goldenDragonBattlerage`: **"bank rage until this is affordable"**. And
v4.7.145 deliberately *removed* banking from Chrono Curse after measuring aeon at ~5.6s
against a 35s cooldown -- ~16% uptime, where holding rage lost more damage than the
mitigation was worth.

So overloading the key silently resurrected a behaviour that had been measured and rejected.
The existing Depthswalker test failed immediately, which is exactly what it was written for.
The flag is now `slows`, and Golden Dragon's two abilities legitimately carry both -- they
bank *and* they slow.

### Composition with Rage-Fuelled

The free-charge rule sorts DESCENDING BY COST so the charge lands on the dearest ability.
Control-first is layered on top rather than replacing it: slowing abilities float to the
front, and the dearest-first ordering still governs within each group. So with a charge
banked against a nightmare, Depthswalker takes Chrono Curse (24) instead of Shadow Lash (36)
-- and that is the case the ordering tests pin, because at plain full rage curse would have
fired anyway and the test would have proved nothing.

### Seeded once, so removal sticks

`deepMerge` copies a saved table INTO the live one and can never delete a key, so a plain
default list would resurrect `manifested nightmare` on every load no matter how often it was
removed. It is seeded once behind `ataxiaBasher.controlMobsSeeded` instead.

Files: `basher/001_Bashing_Functions.lua`, `basher/002_Class_Bashing.lua`,
`002_Check_For_Any_Missing_Variables.lua`, new alias `lists/014_Control_Mobs.lua`, tests
`test_rage_fuelled.lua`, `test_basher_depthswalker.lua`. Suite 827 -> **839**.

---

## 2026-08-02 - The shield is down but the raze is already queued (v4.7.197)

User report: *"The magical shield surrounding a ghostly deckhand fades away."* -- *"we tend
to waste razing a lot when their shield is down"*, and on the diagnosis: **"the problem is an
already queued raze"**. Exactly right, and it is worth being precise about why, because the
obvious suspect was innocent.

### The flag was never the problem

That fade line is already matched -- `335_Mob_Razed.lua:137` has owned it for a long time,
and its body sets `ataxiaBasher.shielded = false` correctly. So shield *detection* was fine.

What the flag controls is what the **next** rebuild looks like. It has no authority over the
raze we have **already sent**, which is sitting in the SERVER-SIDE queue waiting on balance.
When balance returns, that raze executes into a shield that is no longer there: a wasted
swing, and for the rage-raze classes 17+ rage with it.

And the window is not small. The basher's rebuild is **prompt-driven**, so between the
shield-down line and the next prompt the stale raze has a whole balance round in which to
fire. The only operation that can pull it back is another `queue addclearfull`, which
replaces the queue outright -- so we now send a fresh round the moment the shield drops
instead of waiting for the prompt.

### `ataxiaBasher_shieldDropped()`

New in `basher/001`, called from trigger 335 so all ~25 shield-down lines benefit, not just
the fade one -- our raze landing has exactly the same stale-queue problem.

Routed through `ataxiaBasher_attack` rather than `assembleAttack` directly, because that is
where the safety gates live: **swarm hold** (a pull chain is queued as one entry and any
`addclearfull` would wipe it -- the reason `swarmHold` exists at all), **danger level**, and
the player-flee check. A shield dropping mid-pull or mid-flee must not yank us back into
attacking. `danger == "wait"` deliberately leaves the stale raze queued: we are not acting in
that state, so there is nothing better to put in its place.

PvE only (numeric target), off while the basher is disabled or paused, and throttled to one
re-send per second -- a single shield can produce more than one of 335's patterns in a round
(our raze landing **and** the fade line).

### A stale timer found on the way

336 arms `removeShield` to un-stick `shielded` if the shield-down line is never seen. It is
now killed here, and that is not just tidiness: **336 overwrites `removeShield` on the next
shield without killing the old one**, so a timer left armed outlives its own shield and can
clear the flag in the middle of a *later* one -- making us swing into a live shield, the
mirror of the bug being fixed. Cleared even when the re-attack is gated off, since the two
hazards are independent; a test pins that.

### Noted, not changed

335's body clears `ataxiaBasher.shielded` unconditionally, so a *different* mob's shield
fading in the same room clears the flag for OUR target too. Pre-existing, and not safely
fixable in this pass: several of the trigger's patterns capture no name at all (the `type: 2`
and `type: 3` ones), so `matches[2]` is nil for them and a naive ownership check would break
those paths. Wants its own change with the capture groups audited per-pattern.

Files: `basher/001_Bashing_Functions.lua`, `335_Mob_Razed.lua`, test `test_rage_fuelled.lua`.
Suite 820 -> **827**.

---

## 2026-08-02 - Last Word: hold the sweep at 90% before the next room (v4.7.196)

New Mnemosyne affix, captured live from the Ongoing-effects block:

> **Last Word:**  Denizens explode on death!

User rule: with this affix up, be at **at least 90% health before moving on to a new room**.

### Why this is pacing, not combat

The explosion is not something we can dodge, cure, or out-gear -- so the only lever is *when
we walk*. And the timing is unusually hostile: the damage lands at the exact moment the room
goes quiet, which is the exact moment the sweep decides the room is clear and steps out. So
the next room's fight would routinely open on a pool the last corpse had just bitten into.

That is the same shape as Haemophiliac (v4.7.119), so it reuses the same post-clear hold in
`_exploreTick` -- `M._lastWordHold()`, 1.5s re-checks, an echo when it engages, and the same
90% threshold constant.

**It does not reuse the bleed clause.** Haemophiliac also waits on `ataxia.vitals.bleed`
because its damage is a bleed SSC has to clot down; an explosion is instantaneous, so there
is nothing to clot and nothing to wait on but regeneration. A test pins that difference
explicitly -- at 95% HP with 900 bleed, the haemophiliac hold holds and this one does not.

Standard telemetry-independent affix shape: status-row trigger (`mnemosyne/056`, `type: 1`
because the row is column-padded and an exact-whole-line match would silently never fire),
`inMnemosyne` gate, transition guard, reset on run start, cleared on the confirmed run end.
The trailing `!` is deliberately outside the pattern -- match the frame, not the punctuation.

Either affix holding is sufficient; Haemophiliac is checked first only so its echo wins when
both are up.

### Captured in the same screenshot, NOT implemented

Two more affixes were visible and are recorded so the wording is not lost, but neither was
specified and neither is guessed at:

- **Necromantic:** *Denizens may revive as mindless thralls.*
- **Iceblood:** *Taking damage causes your blood to freeze.*

Necromantic in particular looks like it may matter to the sweep -- a room that "clears" and
then repopulates from its own corpses is exactly the state `_roomHasDenizens` is trusted for
-- but what it actually does to the room, and whether the revived thrall is a fresh denizen
id, has not been observed. Say the word and either can be wired.

Files: `mnemosyne/004_Parsers.lua`, `mnemosyne/008_Explorer.lua`, new trigger
`mnemosyne/056_Last_Word.lua`, `mnemosyne/001_Run_Start.lua`, test `test_mnemosyne.lua`.
Suite 814 -> **820**.

---

## 2026-08-02 - Midnight Snow's Icy Heart: two damage types, one shin slot (v4.7.195)

New Mnemosyne boon, captured live: *"Your Shindo blizzard ability now deals cold damage to
all denizens in your location."*

AB BLIZZARD (315) against AB THUNDERSTORM (314) is the same entry twice -- `SHIN BLIZZARD`,
"Works on/against: Room", **4.00s of EQUILIBRIUM, 30 Shin energy**. The user's summary was
exactly right: *same as thunderstorm but for cold damage.*

### It is not a second rider -- it is the same slot

Identical cost means these two boons compete for one thing, and putting both in a round is
precisely the collision v4.7.193 was about: 60 shin, two 4s equilibrium spends in one queued
line, the second rejected outright after stamping its cooldown. So instead of copying the
crowd gate, `ataxiaBasher_bmShinStorm(sp)` **picks** between
`ataxiaBasher_bmThunderstorm` and `ataxiaBasher_bmBlizzard`, and the shared equilibrium slot
is stamped once -- `ataxiaTemp.bmThunderstormAt` renamed to **`bmShinStormAt`**, since a
stamp named after one ability but guarding both is how the next reader gets misled.

### Owning both is the payoff

The tower's suppression affixes name a damage **type** in their sentence -- Iceproof is *"All
cold damage you deal is reduced by 33%"*. With two types available the picker steps around
whichever is nulled this ripple:

- cold nulled -> thunderstorm
- electric nulled -> blizzard
- both nulled -> cast anyway (a 33% cut still beats no AoE)
- neither -> preference order

This is the second consumer of the `M.damageNulled` layer, and it works for the same reason
`ataxiaBasher_bmInfuse` does: the affix suppresses a damage type, and we happen to have more
than one way to deal damage. Preference is `ataxiaBasher.bmStormPrefs`, defaulting to
`{lightning, ice}` so anyone holding only Divine Thunder sees no behaviour change at all.

Crowd gate is `ataxiaBasher.blizzardAt`, falling back to `thunderstormAt`, default 3+ -- the
binding resource is the 30 shin that infuse and the Bladed Reflexes SHIN AUGMENT also draw
from, which is why the shin nukes gate at 3+ where the balance-spending crowd swings gate at
2+. It still yields the round to SHIN AUGMENT under the v4.7.193 rule.

### Captured, and deliberately not guessed at

- **No blizzard fire line yet**, so there is no confirm trigger and the send-side stamp is
  the only cooldown source. When it is captured, point it at
  `ataxiaBasher_bmThunderstormConfirm` -- it restamps the shared slot, so it already covers
  both. Inventing the line would send garbage.
- **The "temporary obscuring snowstorm"** the AB leaves in the room is unmodelled. Nothing is
  known about whether it hinders our own targeting or denizen visibility, so nothing reads
  it -- but it is recorded as the first suspect if the basher ever starts losing track of
  mobs in rooms it has just blizzarded.

Boon flags now **30**. Counted, not grepped: the run-start reset block has 32 lines and two
of them (`mnemHaemophiliac`, `mnemDeluge`) are AFFIXES.

Files: `basher/002_Class_Bashing.lua`, new trigger `mnemosyne/055_Icy_Heart.lua`,
`mnemosyne/001_Run_Start.lua`, `mnemosyne/002_Boon_Claim.lua`, tests
`test_basher_blademaster.lua`, `test_bm_infuse.lua`. Suite 799 -> **814**.

---

## 2026-08-02 - Three emergency abilities that reloaded permanently disabled, and a crash nobody could see (v4.7.194)

Follow-up sweep after the v4.7.193 Codex review. The v4.7.192 finding (`_boonsRelatched`
stored on the serialized `ataxia` namespace) turned out to be one instance of a family, so I
went looking for the rest of it. Four sites, all the same shape, none previously reported.

### The shape

`ataxia` is serialized wholesale (`table.save(file_loc, sanitizeForSave(ataxia))`) and merged
back on load with an unconditional `dst[k] = v`. A `tempTimer` is **not** serialized and does
not survive a relog or a SYSUPDATE package reload. So any flag that is

> set true on use, and cleared **only** by a tempTimer,

and that lives under `ataxia`, comes back from disk stuck ON with nothing alive to ever clear
it. Not degraded -- **permanently disabled**, silently, until someone edits the save.

### HIGH - three emergency abilities were built exactly that way

| flag | window | what stopped working |
|---|---|---|
| `ataxia.wandReflectionCooldown` | **1 hour** | the emergency wand of reflection at <10% hp |
| `ataxia.maranCooldown` | 65s | the emergency Maran 5000hp barrier at <=25% hp |
| `ataxia.vultureTalon.onCooldown` | 180s | the caloric defence vs Blademaster/Magi |

The wand is the worst of the three, and not because of severity: at an **hour**, being
interrupted mid-cooldown is the *normal* case, not the edge case. Any relog, any crash, any
SYSUPDATE inside that hour and the emergency never fires again.

There is a tell that this was already being half-worked-around: the `wandreflect off` alias
hand-nils `ataxia.wandReflectionActive` and `ataxia.wandReflectionCooldown`. Someone hit the
stuck state and papered over it at the toggle rather than at the cause.

All three now use the convention the battlerage rotations already standardised on -- a
reload-safe **timestamp on `ataxiaTemp`** (`wandReflectAt`, `maranAt`, `vultureTalonAt`).
Worst case after a reload is one early re-use; never a lockout. `ataxia.vultureTalon`
additionally carried a serialized `cooldownTimer` **id**, so after a reload `killTimer` would
have been aimed at whatever timer had since inherited that integer. Config -- thresholds,
recovery %, wand id, `cooldownDuration` -- correctly stays on the saved namespace. Stale keys
are scrubbed from existing saves at load.

### HIGH - `ataxia.darkshadeTracker` was referenced twice and created nowhere

`004_Aff_gains_losses.lua` indexes `ataxia.darkshadeTracker.timerId` on **both** the gain path
and the cure path. Nothing in the package ever creates that table. The only definitions in the
repo were the fixtures in `test_afflictions.lua` and `test_combat_tables.lua`, which
hand-build it -- so the tests passed and the live path threw `attempt to index a nil value`
on the first darkshade.

And because an error aborts the handler, the damage was not confined to the tracker:

- **gain path** -- `ataxia_lockBreak()` and `raiseEvent("aff gained", aff)` never ran
- **cure path** -- `raiseEvent("aff cured", aff)` and `Algedonic.RestoreSwaps(aff)` never ran,
  so the anti-Serpent priority swaps darkshade had applied were never restored

Against a Serpent this is not a cosmetic tracker: darkshade held for 26 seconds **is** the
kill route, and the feature meant to auto-prioritise its cure was dead on every profile.

Fixed by initialising it, and by moving `timerId`/`prioritized` to `ataxiaTemp` (same trap as
above -- a persisted `prioritized = true` would reload with no timer to reset it). `threshold`
stays as saved config. **Both test fixtures were deleted**, so the suite now exercises the
real uninitialised starting state; verified by restoring the old code and watching the four
new tests fail with the exact nil-index.

### Checked and deliberately NOT changed

- **The orange family.** I had noted `highlighting/004_HIGHLIGHT_DEADEYES.lua:40` as "a
  surviving violation of the orange reservation" and offered to recolour it. That was my own
  misreading. The rule (CHANGELOG, v4.7.136) is that the existing orange family is
  **grandfathered** and *new* code avoids it -- and orange appears at ~50 sites package-wide,
  so there was never one stray violation to fix. No recolour.
- **~50 bodyless triggers.** A sweep found many triggers with no script body, including the
  two I had flagged (`011_Vulture_Talon`, `001_Warhammer_-_Devestate`). Bodyless does **not**
  imply dead: Mudlet uses name-toggled gate triggers (`limb/002_open_limb_hit_gate` is one)
  and filter-chain parents. Neither of my two is name-referenced, but neither are several
  others whose intent I cannot establish, so mass-deleting on that heuristic would be a guess,
  not a fix. Left alone pending a proper audit.
- **The Vulture Talon trigger body.** Genuinely blocked on live capture -- its success and
  refusal lines have never been seen, and inventing game text sends garbage. The scaffold is
  kept and its comments rewritten to say exactly what to capture and to stop teaching the
  now-removed `onCooldown` pattern.

Files: `004_Aff_gains_losses.lua`, `swaps/005_Vulture_Talon.lua`,
`basher/001_Bashing_Functions.lua`, `configs/013_Wand_Reflection.lua`,
`curing_bals/011_Vulture_Talon.lua`, tests `test_afflictions.lua`, `test_combat_tables.lua`,
new `test_reload_safe_cooldowns.lua`. Suite 780 -> **799**.

---

## 2026-08-01 - Codex adversarial review: four ways one queued line eats itself (v4.7.193)

Independent Codex review of v4.7.165-192, dispatched with the three v4.7.192 findings named
up front and excluded, to force it at what the internal review missed. Five findings, all
five verified against source before being acted on; two of its quoted snippets were
paraphrased wrongly (the `rageAfford` body, boinad's `rage = 32`) but both findings held.
A sixth came out of the parallel pass done while it ran.

Four of the six are the SAME bug wearing different clothes, and it is worth naming because
nothing in the codebase had a name for it:

> **A gate that reads current state cannot see what the same queued line has already
> claimed.** `queue addclearfull <a>;<b>;<c>` is ONE queue entry -- when it fires, every
> command in it executes back to back in the same instant. So `<b>` checking "do I have
> equilibrium / word balance / shin right now?" is answering about a moment BEFORE `<a>`
> ran. Both pass their own gate; only the first can pay; the second is rejected -- having
> already stamped a cooldown, armed a replay, and possibly spent a Rage-Fuelled charge.

### HIGH - Blademaster put SHIN AUGMENT and SHIN THUNDERSTORM in one line

The previous comment in `blademasterBashing` said the storm "sits queued behind the augment
channel and can be wiped by the next addclearfull", and called that tolerable. Wrong model,
and the wrongness mattered: they are in the same queue entry, so the rejection is
DETERMINISTIC, not a race we sometimes lose. The shin arithmetic fails independently of the
equilibrium -- the storm's `shin >= 30` gate reads the pool BEFORE the augment spends from
it, so at 32 shin both clear their own gate and only one can pay.

And `bmThunderstormAt` is stamped on send, so the rejected cast still bought a 4s lockout.
The fix skips the CALL, not the result: the stamp lives inside the helper, so calling it at
all is what costs us. One shin/equilibrium spender per round, augment first.

### HIGH - Infernal burned its once-per-room Tyranny latch on rounds it discarded

`infernalBashing` calls `ataxiaBasher_infGravehands` eagerly and then throws the result away
on its shielded branch -- but the helper had already stamped `ataxiaTemp.infTyrannyRoom`.
That latch is only ever overwritten by a DIFFERENT room number and is never reset, so **one
shielded first contact meant Tyranny never fired in that room again for the rest of the
session.** Every sibling helper (`rwSowulu`, `rwBisect`, `bmThunderstorm`,
`winterDeepfreeze`) already self-guards on `shielded`; this one was the exception.

The rule that follows: **a helper that STAMPS must refuse on exactly the conditions its
caller refuses on**, because the caller's branch is dozens of lines away from the stamp.

### HIGH - Depthswalker's keeper and Boinad both spent the one word balance

`command = ff..dwKeeper(sp)..dwBattlerage(sp)..primary`. Both intone. Both gated on
`ataxiaTables.depthswalker.wordBal`, which is still true while the keeper is merely a string
in the buffer. Boinad lost the race and was rejected after stamping a 38s cooldown, arming
the pending replay, arming the global battlerage cooldown, and possibly spending a free
charge. `dwBattlerage` now takes a `wordUsed` argument -- the caller has to say what the
round already claimed, because no current-state read can. Keeper wins the tie (it fires only
when a defence has actually dropped) and hands the word back once all three are up.

Pre-existing since v4.7.147, outside the reviewed range; found under "anything else".

### MEDIUM - the free battlerage charge never reached the SHARED culling branch

v4.7.179 put `or ataxiaBasher_brFree()` on **seven** culling reap gates. There are **eight**.
The one it missed is the shared branch inside `assembleBattlerage` -- which is the branch
every class that does NOT own a rotation actually runs: Infernal, Paladin, Unnamable,
Serpent, Apostate, Pariah, Alchemist, Jester, Occultist, Priest, Sentinel, Sylvan, Druid,
the Elemental Lords, most Dragons. It compares raw rage rather than going through
`rageAfford`, which is exactly why the v4.7.179 sweep did not see it.

Nothing leaked -- the charge stayed banked and went on a cheaper battlerage further down the
same function. That is why no test caught it, and why it is easy to under-rate: a free AoE
execute is the single best thing a charge can buy, and the majority of the roster was
declining it.

### LOW - Psion's in-flight replay was never released by the ready line

`basher/011` releases a held pick with `pend.verb == field`, where field is the BR_READY_MAP
key (`"barbedblade"`). Psion stored the full command (`"weave barbedblade"`), so that
comparison never matched for **any** of its four abilities: after the game said the ability
was ready again, the stale pick kept being replayed for the rest of its 3s window. Runewarden
and Depthswalker always stored the key; Golden Dragon dodged it only because its four
commands happen to equal their keys. Now stores `key` in `verb` and the command in `cmd`,
matching the other three rotations.

### MEDIUM - the legend-deck replay could redraw at a dead denizen (found in parallel; Codex missed it)

Covenant and Xylthus bake the numeric id into their command via the `<t>` substitution, and
the pending replay resends that string verbatim for up to 4s across the rebuild loop. The
basher retargets the instant a denizen dies -- so a kill inside the window had us drawing an
**hourly-regenerating** card at a mob no longer in the room.

The guard keys on a new `targeted` flag (the card TEMPLATE contained `<t>`), not on
`p.target`: every pending record carries `target` because `Confirm` needs it to attribute
`stampAff`, so keying on that would also have dropped Maran/Seasone/Morimbuul/Matic, whose
commands hold no id that could go stale. My first cut did exactly that and the test caught it.

### Suspects Codex checked and refuted

`brCommit` not arming `brGlobalReadyAt` is correct, not a hole -- arming the global cooldown
at assembly time would make the next `addclearfull` erase a battlerage that had been selected
but not executed, and the rotations that do want send-side suppression still call `brSent`.
The un-nilled `ataxiaTemp` stamps (`rwBrAt`, `dwBrAt`, `psionBrAt`, `gdragonBrAt`,
`bmThunderstormAt`, `mnemLdeckAt`, `dragonRampageAt`, `infDeathauraAt`, `infQuashAt`,
`kaiUnleashedAt`) are monotonic epochs whose staleness only ever reads as "ready";
`mnemLdeckRoom` is reset on ripple/run end, `reaperKills` and `kaiUnleashedAt` on run end.
`infTyrannyRoom` was the one genuinely-wrong lifetime, above. No new dead `type: 3` fragment
in the changed trigger set.

Also verified independently and NOT changed: the `;;` empty segment produced when both
`sowulu` and `brage` are empty is the package-wide `brage..sp..X` idiom, present since well
before this range -- not a regression.

Report kept at `docs/reviews/codex-adversarial-basher-mnemosyne-2026-08-01.md`.

Files: `basher/001_Bashing_Functions.lua`, `basher/002_Class_Bashing.lua`,
`basher/010_Mnemosyne_Legend_Deck.lua`, tests `test_basher_blademaster.lua`,
`test_basher_infernal.lua`, `test_basher_psion.lua`, `test_basher_depthswalker.lua`,
`test_rage_fuelled.lua`, `test_mnem_ldeck.lua`. Suite 752 -> **780**.

---

## 2026-08-01 - Deep review: a leaking free-battlerage charge, and a self-defeating guard (v4.7.192)

Four-agent deep review of v4.7.165-190. Every finding below was independently re-verified
before being acted on; one agent claim was checked and rejected.

### CRITICAL - the Rage-Fuelled charge leaked for seven of eleven rotations

v4.7.179 put the READ side in `ataxiaBasher_rageAfford` - **one predicate, 37 call sites,
every class at once** - and I wrote that up as the elegant part. The SPEND side was wired
only where an `ataxiaTemp.brGlobalReadyAt = ...` assignment already existed to be replaced:
Blademaster, Magi, DW, RW.

**Seven rotations never had that assignment** - `standardBattlerage`,
`crowdControlBattlerage`, `bardBattlerage`, `monkBattlerage`, the `assembleBattlerage`
fallback, `goldenDragonBattlerage`, `psionBattlerage` - so they read the charge and never
cleared it. One kill as Psion, Bard, Monk, Golden Dragon (or any standard-pattern class) and
`brFreeCharge` stayed `true` **for the rest of the run**: every battlerage free, every
`rageAfford` true, the rage floor permanently bypassed. The boon's *"your **next** battlerage
attack"* became *"every battlerage attack, forever"*.

Fixed with `ataxiaBasher_brCommit(cmd)` - spends on a non-empty return, passes the command
through - applied at the **consumption** points (the `assembleBattlerage` dispatcher covers
five rotations at once, plus the two direct call sites). Wrapping rather than patching each
`return` is deliberate: those functions have up to six exits apiece, which is exactly how the
spend got missed the first time.

**Why the tests did not catch it:** `test_rage_fuelled.lua` exercises `brFree`, `rageAfford`
and `brSent` in isolation, and they were all correct. Nothing tested whether the *callers*
used them.

### HIGH - the boon re-latch guard was stored where it defeats itself

`_boonsRelatched` (v4.7.188) lived on `ataxia.mnemosyne`. `ataxia` is serialized wholesale,
and `deepMerge` lets a non-table disk value overwrite unconditionally - while the boon flags
it exists to restore are bare globals that do **not** persist. So after a reload mid-run the
flags came back `nil` and the guard came back `true`: the relatch no-opped and the boons
stayed inert, on the one path where the function was most needed, silently. Moved to
`ataxiaTemp`, with a test asserting it is not on the serialized namespace.

Same class, LOW: `M.ablazeAt` moved to `ataxiaTemp` (its own comment already said it must not
outlive the run; it self-healed via a 12s staleness check, hence LOW).

### Also fixed

- `ataxiaBasher_rwBisect` took an `sp` parameter it never used - misleading signature, since
  a future edit appending after it would silently miss a separator. Removed.
- Documented that `bmThunderstorm` shares the equilibrium slot with `SHIN AUGMENT`.

### Verified clean

Triggers: no critical or high. The two triggers that shipped dead this session are now
correct; the two "clap of thunder" lines and the falcon's third-person/turned-on-us patterns
were proven non-overlapping **in both directions**; every `matches[N]` index correct; every
new trigger `name:` globally unique despite duplicated number prefixes; **771** `type: 3`
patterns swept repo-wide with no new dead ones. Combat: resource-type discipline correct
(bisect replaces, thunderstorm rides), no two balance-spenders in one line, every new ability
self-guards on `shielded` **inside** the helper so none can burn a cooldown on a discarded
round, all crowd gates read the same own-denizen-filtered count.

### One agent claim rejected

Agent 3 reported that the duplicate `You must wait a short time...` pattern shared by `329`
and `345_Gold_Pack` was "silently created" by the new trigger. `git log` shows that pattern
was added in **v4.7.64**. The duplicate is real and worth a cross-reference; the attribution
was not.

### Fourth live affix

`Iceproof: All cold damage you deal is reduced by 33%.` - parses, and is the first of the
four to actually move the infuse picker (`ice` deals cold). Named regression tests added for
all four: Null Magic, Blank Mind, Steel Skin, Iceproof.

### MEDIUM - the re-latch never reached manual-mode users

`M._relatchBoons()` was called only from the two auto-explorer entry points, so a basher who
never runs `mnem explore on` got no automatic re-latch at all. Now also called from
`M.onRipple`, which fires in every mode; the once-per-run guard keeps it to a single send.

### Counts corrected, again

`rageAfford` call sites: **37** - matches what v4.7.180 corrected it to. Boon flags: **29**,
not the 28 the docs claimed. A naive grep of the run-start reset block returns **31** because
two of the `mnem*` flags there (Haemophiliac, Deluge) are AFFIXES, not boons. Third time this
session a count has been asserted rather than counted; the rule is now in `AGENTS.md`.

### Documentation caught up

`.claude/classes/blademaster.md` had no mention of Divine Thunder Cataclysm despite the boon
living in that class; `.claude/projects/basher/battlerage-pve.md` was missing `brPickOrder`
and the leak; `.claude/projects/mnemosyne/07-explorer.md` was missing `_relatchBoons`;
`CLAUDE.md` was missing all three of v4.7.188-190 and still dated 2026-07-27. `.claude/AGENTS.md`
now carries the eleven cross-cutting pitfalls this two-day range produced - the type-3 trap,
global-read/local-write, transient state on `ataxiaTemp`, the invisible wrong-describe test,
resource-type-first for AoEs, frame-not-phrase pattern matching, and verify-don't-grep counts.

Files: `basher/001`, `basher/002`, `mnemosyne/004_Parsers.lua`, `mnemosyne/008_Explorer.lua`,
`triggers/.../mnemosyne/001_Run_Start.lua`, `tests/test_mnemosyne.lua`,
`tests/test_bm_infuse.lua`, `memory/bug-patterns.md`. Suite **752/752**.

---

## 2026-08-01 - Steel Skin was being missed silently (v4.7.191)

> Steel Skin:              All physical damage dealt is reduced by 33%.

**The pattern did not match it.** Compare the three known members:

| affix | text |
|---|---|
| Null Magic | All magic damage **you deal** is reduced by 33%. |
| Blank Mind | All psychic damage **you deal** is reduced by 33%. |
| Steel Skin | All physical damage **dealt** is reduced by 33%. |

The first two both say "you deal", and v4.7.186 was written to that. Steel Skin says "dealt",
so it was **missed silently** - no error, no echo, the affix simply invisible to the system.
That is the exact failure mode the sentence-matching design was meant to prevent, reappearing
one level down: matching the text instead of the affix name removed one brittleness, not all
of them.

The middle is now `(?: [a-z ]+?)?` - any lowercase filler between "damage" and "is reduced
by" - so a third phrasing needs no third patch. The outer frame stays strict enough that
unrelated rows still do not match; verified against `Tundral` and `Mysterious`.

**Generalised lesson recorded:** in a sentence pattern, pin the frame and leave the variable
part loose.

**Residual risk, stated rather than hidden:** a wording with no damage type at all ("All
damage you deal is reduced by...") would still be missed, because the frame requires a word
before "damage". If a global damage-suppression affix exists it needs its own handling.

### What physical suppression actually costs

Nothing routes around this one, and it is worth being straight about why:

- **Runewarden** - `combination <t> slice smash` is physical cutting plus physical blunt,
  with no alternative damage type available. Steel Skin is a flat tax.
- **Blademaster** - `ataxiaBasher_bmInfuse` is unaffected and correctly so: physical is not
  one of the four infusable types (fire / magic / electricity / cold).
- **Bard** - `blade flick` is psychic and is already the default, so the common case is
  fine. Whether `punctuate` is specifically *physical* is **not confirmed** - the code only
  documents it as the non-psychic option - so the inverse (prefer flick under Steel Skin) is
  deliberately **not** wired on an assumption.

Files: `triggers/.../mnemosyne/053_Damage_Nulled.lua`, `tests/test_bm_infuse.lua`,
`memory/mnemosyne.md`. Suite **748/748**.

---

## 2026-08-01 - Divine Thunder Cataclysm: thunderstorm as a crowd rider (v4.7.190)

> Your Shindo thunderstorm ability now deals electric damage to all denizens in your location.

`SHIN THUNDERSTORM` is already a room ability (AB 314, *"Works on/against: Room"*) - the boon
is what makes it hurt **denizens**, turning it into free crowd damage while bashing. Cast at
3+ denizens (`ataxiaBasher.thunderstormAt`).

### It rides, it does not replace - and that is the whole design

AB says **4.00s of EQUILIBRIUM**. The balance swing is untouched, so the storm is prefixed
*alongside* and costs no attack.

Contrast the Thunderclap **bisect** shipped four releases ago: 4s of **BALANCE**, so it
*displaces* the swing and had to be justified on coverage-versus-focus. Same "crowd AoE"
idea, wired oppositely, purely because the resource differs. **That is the first thing to
check for any new AoE** - equilibrium, word-balance, pet orders and free-queue actions ride
alongside; balance ones replace.

### Why 3+ and not the usual 2+

The balance-spending crowd swings gate at 2 because balance is what they contest. Here
balance is free and the binding resource is **shin: 30 per cast**, from a pool that `infuse`
and the Bladed Reflexes `SHIN AUGMENT` are also drawing on. At two mobs a room nuke does not
repay emptying the pool the rest of the round depends on.
`ataxiaBasher.thunderstormReserve` keeps a configurable buffer back for them.

### Fire lines, captured mid-implementation

I had written the cooldown as a send-side stamp with a comment saying the fire line had never
been captured - and then it was, so it now **re-stamps from the confirmed strike**, and the
4s runs from when the storm actually landed rather than from when it was queued. The
send-side stamp stays as the backstop for an eaten cast.

Both lines highlighted on the hyena/falcon convention: the wind-up
(*"Wind swells about your form..."*) `dark_sea_green` for intent, the strike (*"A clap of
thunder presages the unleashed storm..."*) `chartreuse` bold for damage landing.

**Near-miss worth recording:** the Thunderclap bisect line *also* mentions a clap of thunder -
*"...a clap of thunder heralding your strike."* Different opening, different tail, and
verified non-overlapping in both directions before shipping.

Not modelled: *"likely to jangle the nerves of those struck"* is presumably epilepsy on the
denizens, but `ataxiaBasher_BR_AFFS` carries no epilepsy entry and the apply line is
uncaptured.

Files: `basher/002_Class_Bashing.lua`, `triggers/.../mnemosyne/054_Divine_Thunder.lua` (NEW),
`triggers/.../highlighting/036_Thunderstorm.lua` (NEW), `mnemosyne/001_Run_Start.lua`,
`mnemosyne/004_Parsers.lua`, `aliases/.../mnemosyne/002_Boon_Claim.lua`,
`tests/test_bm_infuse.lua`, `memory/blademaster.md`. Suite **745/745**.

---

## 2026-08-01 - Rage-Fuelled spends the charge on the dearest ability (v4.7.189)

> we should always use the most expensive Battlerage of course

Right, and v4.7.179 did not do this - it only removed the affordability gate, so the rotation
still took its normal **priority** pick and often spent a free cast on something cheap.

Each rotation table is ordered by **value per rage**: cheap reliable fillers sit near the top
*precisely because* they are affordable. A free cast makes that the wrong question. Cost stops
being a constraint, so the only thing that matters is getting the biggest ability we are
actually allowed to fire - the cheap ones we can pay for out of pocket anyway.

`brPickOrder(tbl)` re-sorts descending by cost while a charge is banked, and returns the table
**untouched** otherwise. Applied to all four owned rotations (`GDRAGON_BR`, `DW_BR`,
`PSION_BR`, `RW_BR`).

Concretely for Runewarden - bulwark 28, etch 25, onslaught 36, collide 14:

| | pick |
|---|---|
| normal | **bulwark** (priority: mitigation first) |
| charge banked | **onslaught** (36, the dearest ready one) |

### Ties break on the table's own index, deliberately

`table.sort` is **not stable in Lua**, and several rotations carry two abilities at the same
cost. Left to the sort, equal-cost picks would vary between otherwise identical rounds - and
the in-flight replay would then faithfully repeat whichever one it happened to land on. The
comparator falls back to the original index so the table's own priority still decides ties.

Gates are unchanged: cooldowns and affliction requirements still apply, so it is **dearest
READY**, not dearest outright. Culling reap needs no help - it is checked ahead of these loops
and is already joint-dearest in most rotations.

The pre-existing rotation suites passing **unchanged** is the proof that no-charge play is
byte-identical; that matters more here than the six new tests.

Files: `basher/002_Class_Bashing.lua`, `tests/test_basher_runewarden.lua`,
`memory/basher.md`. Suite **739/739**.

---

## 2026-08-01 - Boon flags re-latch once per run (v4.7.188)

Rage-Fuelled (v4.7.179) is working - user-confirmed live. Checking *why* it works turned up
a gap worth closing anyway.

Every boon flag latches from exactly two signals: the `BOON CLAIM` alias intercept at the
moment you take it, or that boon's row in the `BOONS` list. **Neither fires for a boon you
already owned before its handling shipped**, or for a claim made outside the alias. The boon
would be live in the game and inert in the system, silently, with nothing on screen to say
so - and since the payoff is "the rotation quietly does something better", its absence looks
exactly like normal play.

`BOONS` is authoritative for what we own and every boon trigger latches off its rows, so one
send re-latches all of them. `M._relatchBoons()` fires **once per run** from whichever
explorer entry point comes first, and re-arms on run start.

Once per run, not per ripple: the flags only reset at run start, so repeating it would be
pure output spam for no new information.

### The obvious trick that would have been wrong

The tempting fix is to latch from the boon's **description** - the text the user pasted -
mirroring what v4.7.186 does for damage affixes. That is wrong here, and the asymmetry is
worth recording:

- an **affix** description appears in the ongoing-effects block, which lists only what is
  **active**;
- a **boon** description appears on the **offer screen**, which lists boons we were shown
  and **did not take**.

Latching a boon off its description would set flags for boons we declined. The two look like
the same pattern and are not.

Costs one `BOONS` output per run, which trigger `013_Boons_List_Row` already formats into a
coloured what-each-boon-does summary - so it is arguably worth reading. Say the word if it is
noise and it can go quiet or be dropped.

Files: `mnemosyne/008_Explorer.lua`, `triggers/.../mnemosyne/001_Run_Start.lua`,
`tests/test_mnemosyne.lua`. Suite **733/733**.

---

## 2026-08-01 - Blank Mind, and the Bard twin of the infuse picker (v4.7.187)

> Blank Mind:               All psychic damage you deal is reduced by 33%.

**No parser change was needed** - v4.7.186 matches the effect *sentence* rather than the
affix name, so a second member of the family was caught with zero code. That was the point
of the design and it is nice to see it pay immediately.

It also does **not** touch the Blademaster infuse pick, correctly: psychic is not one of the
four infusable types (fire / magic / electricity / cold), so there is nothing to route
around there.

### What it did surface

**Bard already branched on exactly this question.** `blade flick` is psychic; `blade
punctuate` is not - and the basher already chose between them, on a manual `bashPunctuate`
toggle meant for psychic-resistant denizens. A damage-suppression affix is the same question
asked by the *environment* instead of by the *mob*, so it now drives the same branch through
`ataxia.mnemosyne.damageNulled("psychic")`.

Placed in the **first** branch deliberately, so it also overrides the Warmarch flick: that
boon's entire value is **+100% psychic** on the paean refrain, which is precisely what a
psychic-nulling ripple is taxing. The manual toggle sits alongside it, so anyone who asked
for punctuate still gets punctuate.

The generalisable bit, now in memory: **look for an existing damage-type branch before
building a new one.** Bard needed no new mechanism at all - only a second reason to take a
path it already had.

### Still open

The same screenshot carried `Mysterious: All denizens appear identical within their
locations.` That one is **not** handled and I have not guessed at it - it plausibly affects
name-based logic (own-denizen filtering, auto-learn, target-list matching), which is exactly
the machinery that produced the slope-backed-hyena bug. Worth a look before it bites, but it
needs observation rather than speculation.

Files: `basher/002_Class_Bashing.lua`, `tests/test_bm_infuse.lua`, `memory/bard.md`,
`CHANGELOG.md`. Suite **731/731**.

---

## 2026-08-01 - Routing around damage-suppression affixes (v4.7.186)

> Null Magic:              All magic damage you deal is reduced by 33%.

A whole ripple at -33% on one damage type. **Most affixes are things to survive; this one is
a thing to route around** - Blademaster's Shindo INFUSE picks which damage type our slashes
deal, and the affix only nulls one of the four.

### Parsed by the sentence, not the affix name

"Null Magic" is one member of a family, and the other members' names are unknown. But the
effect *text* always names the damage type itself, so the trigger matches that:

```
All (\w+) damage you deal is reduced by (\d+)%\.
```

One pattern covers every present and future sibling, with no name table to go stale the
moment the game adds one. Unanchored, because the row is `<Affix Name>:<padding>All ...`.

### The mapping is the non-obvious part

| infuse | damage type |
|---|---|
| `fire` | fire |
| `void` | **magic** |
| `lightning` | **electricity** |
| `ice` | **cold** |

**Two of the four do not match their own name.** A Null Magic ripple has to move us off
**VOID** - not off some element called "magic", which does not exist. That is precisely why
`ataxiaBasher_bmInfuse` maps element to damage type rather than comparing words.

Preference `fire -> lightning -> ice -> void` (`ataxiaBasher.bmInfusePrefs`), fire first so a
clean ripple behaves exactly as the hardcoded `infuse fire` this replaced. It never returns
nil - an empty infuse would break the attack string - and it survives the mnemosyne module
being absent entirely, for use outside the tower.

Synonyms are accepted per type (electricity/electric/lightning, cold/ice/frost, magic/void)
because only the "magic" wording has been seen live, and a miss would **silently** leave us
infusing the suppressed element - the worst kind of failure here, since nothing on screen
would say so.

### Storage and lifetime

`ataxiaTemp.mnemNulled`, deliberately **not** `ataxia.mnemosyne`: that namespace is
serialized, and a run-scoped fact there would persist across sessions. Cleared on **ripple
change** as well as run start/end, since the effects block is re-read from each ripple's
WADE STATUS - so per-ripple re-latching is both correct and self-healing. Telemetry-
independent status-row trigger, the Splinterbark/Deluge shape.

`ataxia.mnemosyne.damageNulled(<type>)` is the query, so any class can use it - the infuse
picker is just the first consumer.

Files: `mnemosyne/004_Parsers.lua`, `mnemosyne/001_Run_Start.lua`,
`triggers/.../mnemosyne/053_Damage_Nulled.lua` (NEW), `basher/002_Class_Bashing.lua`,
`tests/test_bm_infuse.lua` (NEW), `CLAUDE.md`, `memory/mnemosyne.md`,
`memory/blademaster.md`. Suite **726/726**.

---

## 2026-07-31 - Bisect highlight: wrong colour family (v4.7.185)

The bisect highlight shipped in v4.7.181 and its pattern does match the captured line - but
I chose **deep_sky_blue**, reasoning from the ability (lightning damage) instead of from the
palette. In this package **blue means a defence or a proc**:

- `DodgerBlue` - "our defence is up": shield, paragon, transcendence, tree, daegger
- `deep_sky_blue` - the crit-proc atrophy DoT

So bisect read as something that happened *to* us rather than the room-clearing swing we had
just thrown. Now **chartreuse bold**, the established "damage actually happening" colour used
for the hyena maul and falcon rake landings. Bisect is our own swing rather than a pet's, but
it is the same category of event and the same thing worth spotting mid-scroll.

Deliberately **not** the `orange_red` used by the other AoE nukes (culling blade, rampage
proc): that family is grandfathered only, since orange is reserved for the user.

If you were not seeing any highlight at all rather than the wrong one, the trigger only
exists from **v4.7.181** - `SYSUPDATE` first.

The heralding line is the one distinctive line bisect emits; its damage output is the generic
`Damage dealt: N (<type>).` already handled by `350_Damage_Dealt`. If the Thunderclap third
strike prints something of its own when it splashes onto the other denizens, that line has
not been captured yet and can be added.

Files: `highlighting/035_Bisect_Thunderclap.lua`, `CLAUDE.md`,
`.claude/classes/runewarden.md`, `memory/runewarden.md`. Suite **716/716**.

---

## 2026-07-31 - Bisect: 2+ denizens is a clamped floor, not a default (v4.7.184)

User rule: *"bisect should only be used if it is 2 denizens plus."* It already defaulted to
2, but a default is something you can turn off - and at one denizen the third strike has
nothing to splash to, so the extra 2s of balance buys literally nothing. There is no
configuration in which that is correct, so `ataxiaBasher.bisectAt` is now **clamped**:

```lua
if n < math.max(2, tonumber(ataxiaBasher.bisectAt) or 2) then return nil end
```

It tunes **upward** only. Same shape as `mnem swarm assess <n>`, which validates `n >= 2`
for the same kind of reason.

I had gone out of my way to advertise `bisectAt = 1` as "the lever to make bisect
unconditional". That was surfacing a footgun as if it were a feature - removed from the code
comment, `CLAUDE.md`, `.claude/classes/runewarden.md` and `memory/runewarden.md`.

### A test that passed in the wrong place

The clamp test first landed inside the **Hammer and Nail (sowulu)** describe, because
`it("honours a custom threshold", ...)` appears in *two* blocks in that file and a
first-match replace took the wrong one - which also renamed the sowulu test. It **passed**
there, since `ataxiaBasher_rwBisect` is a global and the body set its own state, so nothing
failed to flag it; only reading the runner output showed the Thunderclap block still had
seven tests. Both blocks are now correct and named for what they cover.

Worth recording: **a passing test in the wrong describe is invisible.** When a helper name
recurs across blocks in one file, anchor edits on something unique to the block.

Suite **716/716**.

---

## 2026-07-31 - The bisect correction missed one site (v4.7.183)

v4.7.182 corrected the backwards bisect-economics framing in five places and I said so - but
the boon trigger `mnemosyne/052_Thunderclap.lua` still carried the old *"roughly a
double-length swing"* text. Caught by my own post-build check (`old framing: STILL PRESENT`),
after the release had already gone out.

Now corrected there too, and swept for both phrasings across `src_new/`, `.claude/`,
`CLAUDE.md` and memory - clean outside the changelog, where the historical entries stay as
written.

Worth recording why it slipped: I corrected the sites I had *edited* when writing the
feature, and the boon trigger was one I had *created*, so it was not on the mental list.
**A correction sweep has to be a grep, not a recollection** - which is exactly what the
post-build check was for, and it worked; I just shipped before reading it properly.

No behaviour change - comments only. Suite **715/715**.

---

## 2026-07-31 - Bisect economics: I had the reasoning backwards (v4.7.182)

v4.7.181 justified the bisect crowd gate as *"gated on the balance cost, not on it being
AoE"*. **That is backwards.** It is gated on the AoE; the balance cost only sets where the
crossover falls. User's correction: **bisect hits multiple, combination hits one.**

Over a 4-second window:

| | swings | targets reached |
|---|---|---|
| `combination <t> slice smash` | 2 | **one** mob, twice |
| `bisect <t>` (Thunderclap) | 1 | the target, **plus electric on every denizen** |

So the trade is *twice the balance for room-wide coverage*, not *twice the balance for one
strike*. At 1 denizen there is nothing to splash to and the extra 2s buys nothing - that is
the **only** case the gate exists to exclude. From 2 upward bisect is already covering ground
combination cannot reach, and the advantage widens with every additional mob.

The framing mattered beyond wording: describing it as a per-swing dps comparison invites the
conclusion that bisect is a *concession* one makes for AoE, when in the tower the objective
is **clearing the room**, not killing one thing fastest - which is exactly the situation
spread damage wins outright.

No behaviour change: the threshold was already 2, which is the correct crossover. Setting
`ataxiaBasher.bisectAt = 1` makes bisect the unconditional swing, and that lever is now
documented rather than implied.

Corrected in the code comment (`basher/002`), `CLAUDE.md`, `.claude/classes/runewarden.md`,
`memory/runewarden.md` and `memory/mnemosyne.md` - including the "rule" I had recorded in
memory, which was generalising the wrong lesson. Suite **715/715**.

---

## 2026-07-31 - Thunderclap: bisect becomes the crowd swing (v4.7.181)

> Thunderclap: Your bisect ability now strikes a third time, dealing bonus electric damage
> to all denizens in your location.

BISECT stops being a single-target finisher and becomes a **room hit**, so
`ataxiaBasher_rwBisect` swings it *instead of* `combination <t> slice smash` at 2+ denizens
(`ataxiaBasher.bisectAt`).

**Gated on the balance cost, not on "it is AoE".** AB Bisect spends **4.00s of balance**
against the SnB combination's ~2s - roughly a double-length swing, so below the threshold it
is a straight dps loss. Exactly the Infernal Arc trade (4.75s vs ~2s dsl, also 2+). It
*replaces* the swing since both spend balance, but the **free falcon rake still rides** -
dropping that with the swing would have quietly cost a free hit.

**Three things from the AB entry that deliberately do not drive logic:**

- The "slain outright at 20 percent health or lower" execute is **adventurers only**. No PvE
  value, so there is no low-hp branch - the AoE is the entire point.
- It **bypasses rebounding and reflections but leaves them intact**, so it needs no raze
  handling and provides none. Shielded rounds still skip it: a denizen shield must be broken
  first.
- `BISECT <target> [venom]` takes an optional venom; unused for bashing.

**An unmanaged prerequisite, by decision.** Bisect requires an edged runeblade with the
**HUGALAZ** rune on the blade. The package had **zero** references to hugalaz, and the
blade-sketch syntax (as opposed to `sketch <rune> on ground`) was never captured - inventing
it would send garbage. Keeping it on the weapon is the user's setup. If the refusal line is
ever captured, this can back off on its own. Note SnB needs no bastard re-wield: an edged
longsword qualifies, confirmed live with Valafar.

Fire line captured and highlighted (`highlighting/035`, deep_sky_blue bold - bisect is
lightning-then-cutting):

> Lightning follows the path of <weapon> as you sweep it at <target>, a clap of thunder
> heralding your strike.

### A latent test trap fixed while adding coverage

`test_basher_runewarden.lua` ends with a shared-state teardown including `target = nil`, and
appended `describe` blocks run **after** it - so two new tests saw a nil target and failed
for a reason unrelated to what they were testing. The teardown now sits at the true end of
the file. The same trap was hit in `test_mnem_ldeck.lua` earlier; worth knowing that in this
suite **appending to a test file means moving the teardown**.

Files: `basher/002_Class_Bashing.lua`, `triggers/.../mnemosyne/052_Thunderclap.lua` (NEW),
`triggers/.../highlighting/035_Bisect_Thunderclap.lua` (NEW), `mnemosyne/001_Run_Start.lua`,
`mnemosyne/004_Parsers.lua`, `aliases/.../mnemosyne/002_Boon_Claim.lua`,
`tests/test_basher_runewarden.lua`, `CLAUDE.md`, `.claude/classes/runewarden.md`, memory.
Suite **715/715**.

---

## 2026-07-31 — Documentation sync for v4.7.174–179, and a count I had wrong (v4.7.180)

Brought every doc surface in line with the releases since the last sync: mounts on the
own-denizen list, `WEAR ARMOUR` before a dive, mana on the HUD, the falcon rake wiring, and
Rage-Fuelled.

Updated: `CLAUDE.md` (boon roster → 27 flags, the HUD's MP row, the explorer's armour check,
mounts on the own-denizen note); `memory/basher.md`, `memory/mnemosyne.md`,
`memory/runewarden.md`, `memory/gui-windows.md`; `.claude/projects/basher/battlerage-pve.md`,
`.claude/projects/basher/denizen-lines-catalog.md`,
`.claude/projects/mnemosyne/07-explorer.md`; `.claude/classes/runewarden.md`.

### The number I shipped wrong

v4.7.179 said Rage-Fuelled rides *"the single gate all **40** rotation call sites already
use"*. **It is 37.** The 40 came from `grep -c` on a mention count, which also swept up the
function definition and four comment lines — the same class of mistake as the "version: OK"
check that passed for the wrong reason two releases ago.

Corrected in `CLAUDE.md`, `CHANGELOG.md` (the v4.7.179 entry in place), `battlerage-pve.md`,
`memory/basher.md`, `memory/mnemosyne.md`, the code comment in `basher/001`, the boon
trigger's comment, and the test file header. The real breakdown: **32** in `basher/001`
(shared assembler + per-class handlers), **4** in `basher/002` (owned rotations), **1** in
`basher/010` (the Mnemosyne card layer).

### What counting properly turned up

That 37th site — the card layer — is a real interaction nobody had looked at. `basher/010`
uses `rageAfford` to ask *"can we afford the battlerage that cashes in this card's
affliction?"* before spending a Covenant/Xylthus charge. A banked Rage-Fuelled charge makes
that `true`, which is literally correct, but the two do not compose: the card plants its
affliction on **confirmation**, a round later, by which point the free charge has usually
been spent on whatever the rotation picked first.

An inefficiency, not a bug, and partly guarded already — the card also requires its payoff to
be **off cooldown**, so it will not draw into a payoff that cannot fire at all. Documented in
`battlerage-pve.md` and deliberately left alone: fixing it means the card layer reasoning
about charge ownership across rounds, which is a lot of coupling for a card that fires every
45s.

Suite **708/708** (docs and comments only).

---

## 2026-07-31 — Rage-Fuelled: a kill banks a free battlerage (v4.7.179)

> Rage-Fuelled: When slaying a denizen, your next battlerage attack will cost no resource.

A kill banks **one** free battlerage. That is a **state, not a timer** — the charge sits
there until a battlerage actually goes out — so it is mirrored as
`ataxiaTemp.brFreeCharge`, armed on the kill and spent on the send.

**The whole payoff routes through one function.** `ataxiaBasher_rageAfford` is already the
single gate every rotation's affordability check runs through — 37 call sites — so a banked
charge short-circuiting it lands the boon on **every class at once**, with no per-rotation
surgery. It short-circuits the **rage floor** as well: a free ability has no surplus to
preserve.

**Culling reap needed explicit handling.** It deliberately bypasses `rageAfford` to stay
floor-exempt (7 sites testing `rage >= 36` directly), so it would have been the one path the
boon missed — and a free AoE execute is the single best thing to spend a charge on. Now
`rage >= 36 or ataxiaBasher_brFree()`.

**Six commit points became one.** `ataxiaTemp.brGlobalReadyAt = ... + 1` appeared in six
places, each marking "a rotation is committing to a battlerage". Arming the cooldown and
spending the charge must stay in lockstep, and a seventh call site that remembered one but
forgot the other would leak a free battlerage silently — so both now live in
`ataxiaBasher_brSent()`.

The charge is spent on **send**, not on a confirmed fire line, because several battlerage
abilities have no fire line at all. The error directions are not symmetric: believing it
spent when it was not costs one missed free cast and self-corrects on the next kill;
believing it still banked costs a rejected command. Both mild, the former quieter.

Lifecycle follows the established boon shape — BOONS-row trigger `mnemosyne/051`, the
`BOON CLAIM` intercept, reset on run start, cleared on the confirmed run end (along with any
charge it had banked). The kill arm lives in `340_Slain`, which is already denizen-gated on a
numeric target, so it cannot fire off a player kill.

Files: `basher/001_Bashing_Functions.lua`, `basher/002_Class_Bashing.lua`,
`triggers/.../340_Slain.lua`, `triggers/.../mnemosyne/051_Rage_Fuelled.lua` (NEW),
`mnemosyne/001_Run_Start.lua`, `mnemosyne/004_Parsers.lua`,
`aliases/.../mnemosyne/002_Boon_Claim.lua`, `tests/test_rage_fuelled.lua` (NEW).
Suite **708/708** — the pre-existing rotation suites pass unchanged, which is what confirms
the six-site consolidation is behaviour-identical when the boon is absent.

---

## 2026-07-31 — Falcon rake highlighted, like the hyena (v4.7.178)

> You whistle to your falcon, commanding it to assail a xorani temple guard.
> A razor-beaked falcon dives at a xorani temple guard, raking his face with its talons.

Mirrors the Infernal hyena maul treatment exactly (trigger `367`), including *where* the
highlight lives: **inside the cooldown trigger, not a separate file**. Those patterns already
match there, and a second copy would be a duplicate-pattern trap. Same three states, same
three colours, and deliberately not the orange family:

| State | Colour | Why |
|---|---|---|
| our order | `dark_sea_green` | muted — intent; nothing has landed yet |
| the rake landing | `chartreuse` **bold** | the free damage actually happening |
| the refusal | `dim_grey` | still on cooldown; nothing happened |

**The two landing lines were not matched at all before this.** Trigger `370` only had the
order line and the refusal, so the falcon has two attack animations (talon dive, beak tear)
and neither was tracked. Adding them also re-arms the cooldown from the moment the rake
*landed* rather than from when it was ordered — the more accurate stamp, and idempotent since
the safety timer is killed and recreated.

**Negative lookaheads, the falcon twin of the hyena's.** When the pet turns on its owner the
lines read *"...dives at **you**, raking **your** face..."* and *"...rips out a chunk of
**your flesh**..."*. Counting those would put the rake on cooldown for a hit we never ordered
— exactly the bug the hyena comment warns about. `(?!you,)` and `(?!your flesh)` keep them
out; trigger `376` still owns the at-us case and orders the falcon passive. Verified all four
lines against all four patterns: each matches exactly one.

Files: `370_Runewarden_Falcon_Rake_Cooldown.lua`, `CHANGELOG.md`, 3 version files.
Suite **696/696**.

---

## 2026-07-31 — Mana on the bashing HUD (v4.7.177)

The `tarc` bashing panel showed HP / WP / EP but not mana. Added an **MP** row directly
under HP — the conventional vitals order — reading `gmcp.Char.Vitals.mp/maxmp` straight from
GMCP like its siblings, and nil-safe in the same way (no reading, no row, rather than a
misleading 0%).

**It uses the same health-style colour ramp** (green >= 66, yellow >= 33, red below) rather
than a flat mana-blue. On a combat HUD the useful signal is "this is getting dangerous", and
running out of mana is a kill condition for us — Psion excise, the Kai Choke 250-mana floor —
exactly as health is. A flat colour would show the number and hide the warning.

No new helpers: `_vitalRow` / `_pct` / `_bar` already took a label and were nil-safe, so this
is one declaration and one echo.

Files: `windows/001_Limb_Counter_Window.lua`, `CHANGELOG.md`, 3 version files.
Suite **696/696**.

---

## 2026-07-31 — The tower owns the curing set, not the basher (v4.7.176)

v4.7.172 keyed the PvE curing profile to `"basher enabled"` / `"basher disabled"`. Inside
Mnemosyne that is the wrong bracket, and the death log that motivated the profile in the
first place shows why:

```
(LEVI): Bashing finished. ...
[Armour]: Basher disabled -- swapping to 'pvp'
(MNEM): [explore] [swarm] reset (basher disabled).
(LEVI): DEATH DETECTED! Basher disabled. Queues cleared. Auto-rotation OFF.
```

Every one of those fired **while still standing in a hostile ripple**. `"basher disabled"` is
a poor proxy for "the fight is over" in the tower — it fires from at least three places
mid-wade:

- **death** — `ataxiaBasher_onDeath` raises it, and the tower death trigger drives
  `_exploreStop` which raises it **again**. Neither clears `inMnemosyne`.
- **the explorer stopping** — `mnem explore off`, the patrol cap, a stall.
- **an areaoff or a manual toggle** between ripples.

Flipping back to the PvP table at any of those is the worst possible timing: it is precisely
when we are about to re-engage at low HP with limbs broken. So the **wade** brackets the
profile now, not the basher. It arms on entry whatever the basher is doing, and releases only
on a confirmed exit.

### Two new events, because there was no way to ask

Nothing in the package raised anything on entering or leaving Mnemosyne — every consumer
polled `ataxiaBasher.inMnemosyne` directly. Worse, *leaving* had **three** separate
implementations that each cleared the flag inline, so there was no single place to hook and
no transition guard:

- `ataxiaBasher_mnemLeftFor()` — SURVEY named a real place
- `ataxiaBasher_mnemLeftConfirm()` — the SURVEY reply never came
- `M.onRunEnd()` — the confirmed wade end (the *normal* exit; the SURVEY paths are the
  "walked out / stale flag" ones)

All three now funnel through a new `ataxiaBasher_mnemLeft(why)` which owns the guard and
raises **`"mnemosyne left"`**, mirroring `ataxiaBasher_mnemHere` which now raises
**`"mnemosyne entered"`**. The explorer's two direct `inMnemosyne = true` writes
(`_exploreResume`, `exploreOn`) were routed through `mnemHere` as well — a silent write is a
write that arms no tower-only mode, and a resume can be the first thing to notice we are
inside.

Both events are **telemetry-independent**: they ride `ataxiaBasher.inMnemosyne`, never
`M.run.active`, which is permanently false when REST reporting is off (`M._inRun()` is
literally `_auto() and ...`, and every `run.active` assignment sits behind a token gate). And
because `mnemHere` is fed by four independent truth sources — the wade-start line, wade
status, the boon screen, and SURVEY — the entry event also self-heals a reconnect mid-climb.

### Suppress the event, never the function

The hold lives in a separate handler (`ataxia_bashProfileOnBasherDisabled`) rather than as a
check inside `ataxia_bashProfileOff`. An explicit `aconfig bashcuring off` and the
`ataxia_sendDefaultPrios` bail-out must still be able to leave the set from inside the tower;
only the *event* is suppressed.

`M.onRunEnd`'s call into `ataxiaBasher_mnemLeft` is cross-file, so it is nil-guarded and falls
back to clearing the flag directly — the crash class in `bug-patterns.md`, and a stranded
`inMnemosyne` would leave no-flee ON in the real world.

### Tests

Six new cases in `test_bash_curing_profile.lua`: the set holds through a basher stop inside
the tower, survives the *repeated* disables a tower death actually produces, releases only on
the real exit, arms on entry with the basher off, still switches off on a normal out-of-tower
stop, and lets an explicit `off` win anywhere. Two in `test_mnemosyne.lua` cover the run-end
exit — which was previously untested — including the nil-guard fallback. 696 pass.

### Same latent issue, not fixed here

**The armour profile and the bashing parry mode have exactly this bug.** Both subscribe to
`"basher disabled"` with no Mnemosyne awareness, so a tower death still flips armour to the
`pvp` paragon set (visible as `[Armour]: Basher disabled -- swapping to 'pvp'` in the log
above) and drops the bashing parry mode. Both are now one `"mnemosyne left"` subscription
away from being fixed.

---

## 2026-07-31 — WEAR ARMOUR before a sweep (v4.7.175)

`mnem explore on` now sends `WEAR ARMOUR` before it starts sweeping. Diving a ripple
undressed is a silent, entirely avoidable damage multiplier, and armour comes off for
ordinary reasons — a morph, a swap, a death.

**Wired at both entry points, which matters more than it sounds.** `M.exploreOn()` is the
explicit turn-on, but `M._exploreResume()` is the *per-ripple* one — `GO` calls it after
every boon screen — so that is where the check actually earns its keep. Armour is now
re-asserted before each dive, not only on the first `explore on`.

Sent **directly, not queued**: the basher rebuilds its command every prompt with
`queue addclearfull`, which wipes queued lines. Same reasoning as the hyena/falcon passive
orders and the disarm recovery. `WEAR` costs no balance, so it rides any round, and
re-wearing what is already on is a harmless no-op.

Deliberately **not** gated on a "do we already have armour on?" check: there is no reliable
worn-state to read, and the failure mode of the guess (skipping the wear because we wrongly
believe it is on) is exactly the thing this exists to prevent. An unconditional free command
is the right trade.

One consequence worth stating: `"You are already wearing this item."` will now print once
per ripple in the common case. I have **not** gagged it — it is a real refusal line, and
hiding it would also hide the pre-existing login-path double-send the v4.7.167 audit found.
Say the word if the noise is worse than the signal.

Files: `mnemosyne/008_Explorer.lua` (`M._wearArmour` + both call sites),
`tests/test_mnemosyne.lua`, `CHANGELOG.md`, 3 version files. Suite **688/688**.

---

## 2026-07-31 — Mounts on the own-denizen list (v4.7.174)

Five personal mounts added to `ataxiaBasher.ownDenizens` so the basher never targets them:
a black Dardanic stallion, a lean grizzly bear, a war elephant, a massive dire wolf, a
withered crypt worm. Mounts share the room's creature list exactly as pets do, so without
this the basher would happily attack one.

**Keywords are the FULL descriptive name, never the bare creature noun** — and that is the
whole design decision here. The own-denizen match is a case-insensitive *substring*, which
is what lets `falcon` cover "a razor-beaked falcon". Seed `bear`, `wolf`, `worm` or
`elephant` and you shadow half the bestiary — and per the slope-backed-hyena lesson
(v4.7.169/170) the failure is silent: `_roomHasDenizens` filters own denizens too, so a room
holding only the shadowed mob reads as *clear* and the sweep walks out of it, trailing a live
aggressive denizen.

So `lean grizzly bear`, not `bear`. Tests assert both directions — the mounts are shielded,
and `a grizzly bear` / `a dire wolf` / `a crypt worm` / `a rabid wolf` / `a cave bear` are
**not**.

Backfilled rather than defaulted, so an existing save picks them up on next load with a
one-line echo per mount.

**Residual risk, stated plainly:** a wild denizen sharing a mount's *full* phrase would still
be shielded. If that ever happens, `bash notmine add <name>` exempts it — do that rather than
loosening the keyword. There is a test for exactly that path.

Files: `002_Check_For_Any_Missing_Variables.lua`, `tests/test_basher_runewarden.lua`,
`CHANGELOG.md`. Suite **687/687**.

---

## 2026-07-31 — Seasone draw syntax: the "for" was English, not syntax (v4.7.173)

> You must draw that card for either ELIXIR or POISON.

Seasone is the only two-variant card, and we were drawing it as
`ldeck draw seasone **for** elixir` — taken literally from the card's own help text,
*"DRAW FOR ELIXIR or FOR POISON"*. That text is prose. The variant is a **bare argument**:
`ldeck draw seasone elixir`.

The package's own `ldm.draw` / `ldm.drawQueued` already build parameterised draws that way
(`003_Legend_Deck_Functions:112-115,129-132` — append the argument, no preposition), so the
evidence was in the codebase the whole time.

**Two sites had it**, and the older one was not mine: the `lsea` alias
(`legenddeck/001_Season_(Elixir_Poison).lua:16`) has carried `for elixir` since long before
the auto-draw layer, so that manual draw has never worked either.

### Backstop for the next one

New trigger `legenddeck_cards/009_LDeck_Needs_Variant.lua`. A refused draw spends no charge,
so nothing about the deck changes — but the auto-draw layer holds its pick in a ~4s in-flight
replay (it must, because the basher's `queue addclearfull` wipes the queued line every
prompt), so a syntax error would be **re-sent on every rebuild for the whole window**. The
trigger lapses the pending pick instead: replay released, interval held, one wasted round
instead of a burst.

Deliberately `Lapse` and not `Rejected` — `Rejected` zeroes the charge count, which is right
for *"lacks the power to invoke its stored potential"* and wrong here. The card is fine; the
command was not.

Files: `basher/010_Mnemosyne_Legend_Deck.lua`,
`aliases/.../legenddeck/001_Season_(Elixir_Poison).lua`,
`triggers/.../legenddeck_cards/009_LDeck_Needs_Variant.lua` (NEW),
`tests/test_mnem_ldeck.lua`, `docs/legend-deck.md`, 3 version files. Suite **684/684**.

---

## 2026-07-31 — The curing table was answering the wrong fight (v4.7.172)

> `[RIFT]: -1 Cuprum.` -- *The terrible sense of foreboding lifts.*
> Fourteen seconds later: *You have been slain by an earth wyrm.*

A Mnemosyne death log, Runewarden SnB against two earth wyrms. Max HP ~32,850 (derived: the
swarm ladder printed `LOW HP (29%)` at a raw HP of 9,526). Thirteen seconds from full
engagement to death, ~21,000 incoming -- roughly **1,600 HP/s**.

Nothing was wrong with the rotation. The system died because
`ataxia_defaultCuringPrios()` is tuned **entirely for PvP**, and it spent both scarce
balances on afflictions that do nothing to a basher.

**Potash and moss share the eating balance with every cure-mineral.** Seven eats in the final
thirteen seconds; exactly ONE was potash:

| Time | Eat | Cured |
|---|---|---|
| 38:633 | cuprum | paranoia |
| 41:060 | cuprum | paranoia |
| 43:746 | argentum | (mental) |
| 45:376 | calamine | (mental) |
| **46:221** | **potash** | **health + mana** |
| 46:973 | cuprum | paranoia |
| 48:827 | plumbum | shyness |

`You may eat another bit of irid moss or potash.` printed at 07:45:36 and the next potash went
down at 07:45:46 -- **ten seconds of heal balance spent on paranoia and shyness** while HP fell
44% -> 25%.

**Mending and restoration share the salve balance with cracked ribs.** `crackedribs` is prio 9,
`brokenrightarm` is 10, so at 07:45:43 the salve went to the torso (`It becomes somewhat easier
to draw breath.`, `Cr(2)` -> `Cr(1)`) while `ra1` was still broken. Cracked ribs are a damage
modifier. A broken arm **refuses the entire SnB attack** -- and four rounds were sent and
refused outright at 07:45:38/39/40/40 (`You cannot do that because both of your arms must be
whole and unbound.`).

The wyrm's kit is heavy damage, BOTH limbs of a pair broken per bite, impale, and a spray of
cosmetic mental afflictions. The PvP table cures every one of those because in PvP they are
lock components. In PvE nothing is locking us: **the table was answering a threat that was not
present, using exactly the resources needed for the one that was.**

### The bash curing profile

New `ataxia/ataxia/008_Bash_Curing_Profile.lua` -- a server-side `bash` **curingset** holding
the PvE ordering, switched on `"basher enabled"` and restored on `"basher disabled"`.

Curingset rather than a priority overlay because `curing priority` is throttled at 4/sec
(`002_Prio_Management.lua`, Announce #5450): pushing ~55 priorities would take ~15 seconds
each way, which is useless as a combat profile switch. `CURINGSET SWITCH` is one command.
Install clones the PvP set first and writes only the ~55 deltas, so anything unlisted keeps
its PvP value.

The ordering is close to the inverse of the PvP one:

- **limbs to 4-6** (from 7-14) -- arms gate our offence and rifting, legs gate stand, tumble,
  leap and fly, i.e. every rung of the escape ladder. Made **symmetric**: the PvP table has
  `damagedleftarm` at 11 and `damagedrightarm` at 13 for no reason, and restoration always
  heals the LEFT limb of a pair first anyway.
- **cure-channel blockers stay ahead of them** -- anorexia (eating -> potash), slickness
  (salves -> mending), paralysis (tree).
- **the real damage math to 6** -- recklessness (+50% taken), sensitivity, hypochondria,
  clumsiness (33% miss), healthleech.
- **salve competitors parked at 20** -- crackedribs, skullfractures, torntendons,
  wristfractures, concussion, both traumas, scalded. None may outbid a limb again.
- **the junk mental spray parked at 25** -- paranoia, shyness, depression, masochism, the
  phobias, dementia, stupidity, dizziness, the horror and tempered stacks, and the rest.

Deliberately unchanged and recorded in the file so a future reader does not "fix" them: the
whole writhe/incapacitation band, **asthma and weariness** (the Seasone phial truelock is
asthma + anorexia, and the mnemosyne/004 counter re-touches tree only while both persist --
demoting asthma would lengthen that lock), nausea (blocks parry, which the SLC bashing parry
mode depends on), epilepsy, and the ticking-damage families.

**Opt-in.** `installed` is false until `aconfig bashcuring install` writes the set, and
`ataxia_bashProfileOn` returns early until then -- an update alone changes nothing.

### Three guards, because parking an affliction has consequences

Each is a direct consequence of the change, not a nicety:

1. **The recovery hover would never land.** `S._afflicted()` (mnemosyne/009) returns true for
   any aff outside `AFF_IGNORE`, and the escape ladder only lands at `recoverAt%` **and**
   aff-free. Affs parked at 25 stay up for the rest of the fight, so every hover would burn
   its full `RECOVER_MAX` cap waiting on a paranoia nobody is curing. A parked affliction is
   one we have DECIDED not to cure and must not hold the hover -- only while the profile is
   active, so PvP is untouched.
2. **classDetect would clobber the switch.** It owns the only other `curingset switch`
   (`:196`, `:237`, `:299`) and never switches back TO `bash`, so one PvP-class detection
   mid-swarm would silently disarm the profile for the rest of the run. Suppressed while the
   profile is active; combat state still clears so a later PvP fight starts clean.
3. **Stored priority writes would rot the set one affliction at a time.** `curing priority
   <aff> <n>` writes to whichever set is ACTIVE. Worse than the write itself,
   `ataxia_restorePrio` would then put the **PvP** default back into the **bash** set. Guarded
   at the choke point (`ataxia_sendCuringPriority`) rather than at ~15 call sites -- Damnation,
   the anti-class handlers, parshield, engage/disengage burning all route through it, and all
   are meaningless against denizens. `curing priority defence ...` and the health/mana sip
   toggle still pass; `curing prioaff` (TEMPORARY, used by SLC's defensive reactions) never
   routes through there at all. `ataxia_sendDefaultPrios` leaves the bash set before resetting,
   or `reset prios` mid-bash would overwrite the profile with the PvP table and leave a
   duplicate of `normal` that still "switches".

### Commands

`aconfig bashcuring [install|show|on|off|status]` -- `show` prints every delta as
`pvp -> bash`, parked values in red.

### Tests

`test_bash_curing_profile.lua` (22 cases) asserts INVARIANTS, not numbers -- the numbers are a
judgement call that will be tuned from live logs, the orderings are the point of the profile:
every limb outranks every salve competitor; left/right pairs are symmetric; every delta names
an aff the default table knows (the `crippled*`/`broken*`/`damaged*` naming split is one the
codebase is genuinely inconsistent about, and a typo would write a priority for an aff that
never fires); no delta repeats its default; nothing at prio <= 2 is ever demoted. Plus the
switching lifecycle and the write guard. Two more in `test_swarm_tactics.lua` cover the hover
landing with parked affs up, and that PvP behaviour is unchanged with the profile off. 683
pass.

### Recorded but NOT fixed here

Found in the same log, left for follow-ups so they are not lost:

1. **The escape ladder fires too late.** 29% HP with ~1,600 HP/s incoming is about six seconds
   of life -- and by then both legs were broken, so the `stand;fly` it queued could not
   execute. `escapeAt` is an HP budget where the situation needs a TIME budget;
   `ataxiaBasher_dmgSamples` already computes the rate.
2. **Broken arms are not in the attack gate** (`basher/001:686`), producing the four refused
   rounds. Triggers 344/345 only echo; they could escalate the limb cure.
3. **Not one health elixir sip in the whole log** despite `curing siphealth 80`, at 25-50% HP
   for thirteen seconds. Related: `ataxia.settings.sipping.*` is written by the setup wizard
   but **never sent to the server** -- install and `setNormalSip()` both hardcode literals and
   disagree (80/80/70/70 vs 80/75/70/70 vs a default table saying 70), and nothing ever sends
   `curing sipping on`.
4. **Bleed is parsed positionally.** `update_stuff/004:118` reads `stats[1]` while every other
   charstat uses the key-scan loop at `:42-90`. This is why `bld(389)` vanished 150ms later in
   the log -- a parse miss, not a clot. It can also hand `nil` to arithmetic comparisons
   (`001_Anti_Priorities:177`) and throws outright if `charstats` is empty.

---

## 2026-07-30 — Dagaz: the self branch that was never written (v4.7.171)

> A rune like a rising sun upon the ground flares, bathing you with healing magic.

Runewarden's **dagaz** rune is the passive heal — it fires on its own timer and cures one
affliction for free. Worth seeing land in combat spam.

**It turned out not to be "add a highlight".** The line was already matched, at
`passive_active/027_Dagaz_(Runewarden).lua:36` — but its entire body sits inside
`if isTargeted(name) and class == "Runewarden"`. The capture is `(\w+)`, so one trigger sees
both sides: an enemy's rune yields their name, **ours yields the literal `"you"`**. And
`isTargeted("you")` is false unless you happen to be targeting someone called "You" — so on
our own proc the trigger fired and **did nothing at all**, not even its own
`fg("NavajoWhite")` highlight. That trigger exists purely to model an *enemy* Runewarden in
the V3 target tracker; all 28 files in `passive_active/` are built that way, and none has a
self-side counterpart — **Fitness included**.

Fixed with an additive `elseif name:lower() == "you"` branch, so the enemy path and its V3
calls are untouched and cannot regress. One trigger keeps owning one game line rather than a
second one being layered alongside it.

Colour: `medium_sea_green` `{60,179,113}`, deliberately **not** `spring_green` `{0,255,127}`,
which already means parry-success/our-proc (`highlighting/027`, `/015`) — the two must not be
confusable mid-fight. Orange remains reserved.

**Highlight only, by decision.** The larger options were declined for a reason worth
recording: our own affliction state is authoritative-from-GMCP and self-correcting
(`lostAff()`, `004_Aff_gains_losses:243-302`, already nils the entry and raises `"aff cured"`),
so a "dagaz cured one" signal adds no bookkeeping. The real gap it *would* fill stays open —
**nothing knows whether our own passive is ready**, because `passiveCooldownsV3` is entirely
enemy-side and no ground rune in the package is tracked as a state at all (sowulu/raido/
thurisaz are send-only with room or ripple latches).

### Two class-doc facts were wrong

Found while documenting this, and corrected against `740_Rune_Found.lua:45-65` (the
authoritative rune→effect table) and the alias that sends each rune:

- *"Watch for sowulu (healing) and thurisaz (defense) runes"* — **wrong on both counts.**
  `sowulu` is the damage/nail rune; `thurisaz` is LoS damage; **dagaz** is the healing one.
- `thurisaz: effect: "Defensive barrier rune"` — also wrong. The alias sends
  `sketch thurisaz on ground **for** <target>` (`137_thurisaz.lua:17`); you do not sketch a
  defensive barrier *for* someone.

Lesson recorded: a rune's effect lives in the rune-found table and the alias that sends it,
not in prose written from memory.

Files: `passive_active/027_Dagaz_(Runewarden).lua`, `.claude/classes/runewarden.md`,
`memory/runewarden.md`, `CHANGELOG.md`, 3 version files. Suite **662/662** (unchanged — no
testable logic added).

---

## 2026-07-30 — Documentation sync, and four bugs the doc pass found (v4.7.170)

A full documentation sync across every surface for v4.7.165–169. Six agents each owned a
disjoint file set, and each got an adversarial verifier that **opened every `file:line`
anchor** written. Those verifiers found four real code bugs and one false claim of mine.

### `type: 3` is EXACT MATCH, and three triggers used it on a fragment

Mudlet's trigger enum, derived empirically from this repo's own 3,400 patterns: `0` =
substring, `1` = regex, `2` = begin-of-line substring, **`3` = exact whole line**. A `type: 3`
pattern that is only part of a line can never match.

- **`375_Runewarden_Etch_Landed` — mine, from v4.7.166.** Pattern `You trace the outline of
  a rune in the air with` is a fragment (the weapon name follows), shipped as `type: 3`. **It
  never fired once.** The two-wasted-cycles fix it carries was dead on arrival. Now `type: 2`.
- **`mnemosyne/032_Seasone_Phials` — pre-existing, and a boss safety.** The phial-burst
  truelock counter keys on `reaches into her robes and withdraws a handful of fragile glass
  phials`, which begins mid-line (her name precedes it), as `type: 3`. **The Seasone truelock
  counter has been dead since v4.7.123.** Now `type: 0`.

An audit of all 656 `type: 3` patterns turned up ~6 genuine fragments; the rest are real whole
lines (headers, dividers) that merely lack terminal punctuation.

### A live trigger calling a nil global

**`037_mangled`** is `isActive: yes` and calls `SLC_broke(matches[2])` — but `SLC_broke` is
defined *only* in `levi_scripts/slc/001_functions.lua`, which is `isActive: no`. At runtime it
is a nil global, so the trigger **errored on every level-2 break** and fed the tracker nothing.
So the self-limb "trio" v4.7.167 claimed to complete actually had one live end, not two.
Repointed at the same V2 path as its level-1 sibling, with the legacy call guarded.

### I described the v4.7.169 failure mode wrongly

I called the shadowed-denizen bug a "hard stall" in four places. **It is not.** The explorer's
`_roomHasDenizens` and `_denizenCount` (`008_Explorer:97,108`) *both* filter own denizens — so
a room holding only the shadowed mob reads as **clear**, and the sweep walks straight out of
it, trailing a live aggressive denizen. Silent, not stuck; arguably the worse of the two.

I reasoned from "the explorer counts denizens" without checking that both of its counters
filter. Corrected in the changelog, two code comments, the alias header, `CLAUDE.md` and
memory. **Lesson recorded: when asserting a failure MODE, trace the actual consumer — do not
infer it from the data the consumer reads.**

### Documentation

`CLAUDE.md` (new basher files, SLC level-1 break + refusal rollbacks + malagma parry patterns,
swarm dragged-from-sky + burning rooms); **new `memory/runewarden.md`** — there was none
despite five releases of Runewarden work — plus its `MEMORY.md` index entry;
`.claude/classes/{runewarden,infernal}.md`; `memory/{slc,basher}.md`; `docs/legend-deck.md`;
`.claude/projects/basher/{02,05,battlerage-pve,denizen-lines-catalog}.md`;
`.claude/projects/mnemosyne/{03,05,07}.md`; `.claude/AGENTS.md` (the seven cross-cutting rules
these releases produced).

Verifier corrections applied inside those docs included fabricated evidence (a claim that all
four RW_BR abilities announced themselves in the log — only three did), a falsifiable
overstatement about re-wielding, and several anchor imprecisions. Bare trigger numbers are now
avoided in prose: this repo has **23 duplicated trigger-number prefixes**.

Suite **662/662**.

---

## 2026-07-30 — "a slope-backed hyena" is a real denizen (v4.7.169)

The own-denizen list matches by **case-insensitive substring** — that is what lets the
keyword `falcon` cover "a razor-beaked falcon" without knowing every variant. It also
means a real, killable denizen whose name merely contains a pet's word is silently
shielded from targeting.

`a slope-backed hyena` is exactly that: a genuine mob, protected by the `hyena` keyword
seeded for the Infernal pet. Two consequences, and the second is the serious one:

- `ataxiaBasher_purgeOwnFromTargets` would **delete it from the learned target list**,
  across every area.
- In the Mnemosyne this is worse than lost xp — **the sweep walks away from a live mob**.
  ~~It counts as a denizen and stalls the room-clear test~~ *(corrected v4.7.170: the
  explorer's `_roomHasDenizens` and `_denizenCount` both filter own denizens too, so a room
  holding only the shadowed mob reads as **clear** and the explorer navigates straight out
  of it, leaving an aggressive denizen following and hitting us. Silent rather than stuck —
  arguably the worse of the two.)*

New `ataxiaBasher.notOwnDenizens`, checked **first** in `ataxiaBasher_isOwnDenizen` and
winning over the pet keywords, so the pet ("a daemonic hyena") stays protected while the
mob is targetable. Managed with `bash notmine [add|rem] <name>`, mirroring `bash mine`.

Seeded via **backfill**, not a default — existing saves already carry the bare `hyena`
keyword, so a fresh-install default would have fixed nobody who hit this.

The obvious alternative — narrowing the seeded keyword to `daemonic hyena` — was rejected:
it only helps fresh installs, and it does nothing for the next collision. The exemption
list is general.

Files: `basher/001_Bashing_Functions.lua`, `002_Check_For_Any_Missing_Variables.lua`,
`aliases/.../lists/013_Not_Own_Denizens.lua` (NEW), `tests/test_basher_runewarden.lua`,
`CHANGELOG.md`, `CLAUDE.md`, memory. Suite **662/662**.

---

## 2026-07-30 — Denizens can drag us out of the sky (v4.7.168)

> A tentacle shoots up from the ground, wraps itself around you, and drags you back to earth.

A third way flight fails in the tower, after the Deluge affix and an eaten FLY — and the
nastiest, because it was **silent to the state machine**. The recovery hover keeps
`S.flying` optimistically true until a flight line confirms (that guard exists because
stupidity can eat a queued fly), and after a drag that confirmation never arrives. So the
hover would re-send `fly` *every tick* while a tentacle yanks us straight back down —
holding us attack-**gated** at crash HP, with the swarm still on us, until `RECOVER_MAX`
finally expired. Strictly worse than never having flown.

`S.onDraggedDown()` (trigger `mnemosyne/050`) latches `S.grounded`, which `S._canFly()`
now honours alongside `mnemDeluge` — so both the escape ladder's outdoor branch and the
fly-kite fall through to the grounded route. It also corrects the flight state and, if a
hover is already running, converts it into the grounded retreat rather than letting it
spin.

**Per-ripple, not per-run** (user call): the denizen that dragged us lives on this ripple
and will do it again, but the next ripple is a different room set. `S.onRipple` clears it.

A test asserted the aborted hover should land back in `recovering`; the code instead goes
to `pulling`, which is correct — falling through to the grounded retreat is the entire
point. The assertion was wrong, not the code.

Files: `mnemosyne/009_Swarm_Tactics.lua`, `triggers/.../mnemosyne/050_Dragged_From_Sky.lua`
(NEW), `tests/test_swarm_tactics.lua`, `CHANGELOG.md`, memory. Suite **658/658**.

---

## 2026-07-30 — Live-log audit: limbs, cooldown feeds, burning rooms (v4.7.167)

A six-lens adversarial audit of a live Mnemosyne Runewarden log (iron/invar malagmae,
`v4.7.165` client) against the codebase. Findings were each independently re-verified
before being acted on; several of the first-pass claims were refuted and are not here.

### The root cause behind the legend-deck failures

**`ldm.matchFullName` could not resolve a comma-suffixed card name.** It took
`fullName:match("^(%S+)")`, so `"Xylthus, the Outcast"` yielded the token `"Xylthus,"`
— *with the comma* — which matches no key. Consequences, all live:

- `001_Identify_Uses` ("A card depicting X may be used N more times…") never resolved a
  key, so **`ldm.deck[card].charges` was never updated from the game**. `initDeck` seeds
  unseen cards at their max, so the deck permanently claimed full charges — the
  "3 charge(s) left" on a card the game then refused.
- `008_LDeck_No_Charges`, the v4.7.166 rejection handler, early-returned on nil, so **the
  fix that was supposed to stop drawing into a wall never ran at all.**

Cards whose key is the first bare word (Maran, Matic, Covenant) worked, which is why this
survived. Now a token scan that strips punctuation, which also handles a leading
honorific (`Lord Nicator, The Chosen One`) the first-word rule could never reach.

**And a bug of my own from v4.7.166:** the pending-window lapse path called
`mnemLdeckConfirm`, which stamps the affliction — so an *unacknowledged* draw still
planted a phantom stun for Etch to buy at 25 rage, exactly the hole that release closed.
Split out `ataxiaBasher_mnemLdeckLapse`: it holds the interval and releases the replay,
and stamps nothing.

Offensive cards (Matic/Covenant/Xylthus) now also skip a mob that is about to die
(`mnemLdeck.conserveAt`, 25%) — the `rageConserveThreshold` idiom, which matters *more*
here since rage refills in seconds and these charges refill once an hour. The GMCP read
is fully guarded: this function runs under `pcall`, so an unguarded index would be
swallowed and would silently disable the whole card layer.

### Limbs — the log's real damage

**`Your <limb> breaks with a loud crack.` had no handler anywhere.** SLC captured both
ends of the trio (`036_Limb_healed`, `037_mangled`) but not the level-1 break, by far the
most common — ~25 of them in 90 seconds in this log. Because `ataxia_brokenLimbFound`
only branches on the `damaged*`/`mangled*` families, a level-1 break never reset the
accumulator: damage kept climbing past the real break, `selfHitsToBreak` pinned at 0, the
threshold latched `critical` forever, and every one-shot reaction latch stayed set.
New trigger `038_Limb_Broken_L1` — the game's own words, naming limb *and* side, which
sidesteps the `crippled*` vs `broken*` vs `damaged*` naming ambiguity entirely.

**Trigger 344 was firing an unthrottled `diag`** on `You cannot do that because both of
your arms must be whole and unbound.` — and *nothing in the package parses our own
DIAGNOSE output*. Six lines of console spam at the worst possible moment, three times in
0.8s. Replaced with the rollback that line actually justifies: it is an authoritative
"the queued round did not execute", so drop every owned rotation's in-flight replay.

**New `345_Broken_Legs_Block`** for `Both of your legs must be free and unhindered to do
that.` — which had no handler either, and whose expensive victim is not a lost swing but
**`leap`**: the swarm escape ladder moves with `stand;leap <dir>`, and a refusal was
silent to that machinery, stalling the low-HP escape until the move timeout expired.

**Denizen parry patterns** for both malagmae. The iron malagma has two arm attacks to one
head attack, and a broken pair of arms doesn't merely hurt — it *refuses the attack
outright*, so the arms are the limbs gating the entire offence. `fixed` not `cycle`:
neither arm line names a side, so an unsynchronised cycle would guard the wrong arm half
the time.

### The cooldown feed we were discarding

The game names the exact ability coming off cooldown — `You can use Collide again.` and
`Your Collide ability could be used again but you lack the necessary Rage.` (the same
event seen through an empty rage bar). Every owned rotation instead *guessed* with a
send-side stamp plus a hardcoded `cd`, which is wrong in both directions: too slow when
boons/gear shorten the real cooldown, too fast when a stamped pick never executed. New
`basher/011_Battlerage_Ready_Lines.lua` + trigger `328` — class-agnostic, verb captured
from the line, unknown verbs ignored. (The pre-existing gag hides only the *Chaosgate*
forms, so this costs no existing behaviour.)

### Burning rooms

`The area is ablaze!` plus `The roaring inferno engulfs you…` for ~800 every few seconds
— about 6% of max HP per tick, indefinitely — matched by nothing. New `M.roomAblaze()`
(latched on the burn line, not the room description, so it self-expires when we leave)
gates the swarm escape ladder's **hover**: flying up to heal is a fine plan in a normal
room and a bad one over a fire that follows you. The kite is deliberately *not* gated —
it lands for every swing anyway.

### Blood Maiden cloak — corrected against TALISMAN INFO

The code read "failing to make a kill within 3 minutes will cause the blood reserves to
deplete" as *"the cloak stays active for 3 minutes (free re-activations)"* and dropped the
mob threshold from 4 to 3 on that basis. Both halves were wrong: BLOODSHIELD is a
**one-shot block of the next attack**, and the 3 minutes is the depletion timer on the
reserves. So a charge earned over five kills was spent and then re-spent every 3s against
a cloak that had nothing left. Now one charge, one activation, consumed on use — and
never while prone (the cloak refuses that under aggression aura, and has a 50% chance to
eat the charge for nothing).

### Also

`376_Falcon_Turned_On_Us` (the Runewarden twin of the hyena flip — `order falcon passive`
is free and balanceless) and `377_Sword_And_Shield_Lost` (`You must be wielding both a
sword and a shield…` → re-wield + re-`grip`; the more dangerous of the two limb-style
refusals, because nothing re-wields, so it would persist forever).

Files: `legend_deck/003`, `basher/001`, `basher/010`, `basher/011` (NEW),
`self_limb_tracking/005`, `mnemosyne/004`, `mnemosyne/009`, triggers `038`, `328`, `344`,
`345`, `376`, `377`, `mnemosyne/049` (NEW), `tests/test_legend_deck_match.lua` (NEW),
`tests/test_mnem_ldeck.lua`, docs, memory. Suite **654/654**.

---

## 2026-07-30 — Card → confirmed → battlerage, and two live bugs (v4.7.166)

Live log of v4.7.165 in the tower. Three faults, all visible in one 90-second stretch.

**1. The ordering was wrong (user-reported).** The draw and the battlerage that cashes
it in went out in the *same* queued line, with the affliction stamped optimistically at
build time. When the draw failed, that stamp was a lie and Etch spent 25 rage on a
phantom stun — the log shows exactly that, twice, while the rotation was rage-starved
("Your Etch/Collide/Bulwark ability could be used again but you lack the necessary
Rage"). The affliction is now recorded **on confirmation**, so the exploiting battlerage
fires on the *following* round against a denizen that really carries it.

**2. `ldm` charge counts are not trustworthy.** `ldm.initDeck()` seeds every card it has
never seen at its **max**, so a deck that has never been `LDECK LIST`ed reports full
charges for everything. The layer read "Xylthus: 3" and drew into a wall: *"A card
depicting Xylthus, the Outcast currently lacks the power to invoke its stored
potential."* New trigger `legenddeck_cards/008_LDeck_No_Charges.lua` treats that line as
the ground truth — zeroes the count and calls `ataxiaBasher_mnemLdeckRejected`, which
drops the in-flight replay (so it isn't re-sent) and stamps no affliction.

Confirmation now also hooks the **generic charge line** ("A card depicting X may be used
N more times...", trigger 001) as well as `ldm.onDraw`. The draw-success wording is not
uniform — Seasone announces itself as "As you draw forth a card depicting Seasone, the
Industrious..." — so the charge line is the reliable feed.

The card is also skipped when its **payoff battlerage is on cooldown** (Etch 23s,
`bmHeadstrikeReadyAt`, `magiFirefallReadyAt`). A charge spent on an affliction we cannot
cash for another 20s is a charge thrown away, and these regenerate hourly.

**3. Runewarden Etch had no fire-line trigger** (pre-existing, unrelated to the cards).
It is the one ability in `RW_BR` whose in-flight pick replay had nothing to release it,
so after the queued etch actually fired the next two rebuilds re-queued the *same* etch
and the server rejected both: *"You must wait a short time before you can use a
battlerage ability again."* — two wasted cycles back to back. The line is now captured:

> You trace the outline of a rune in the air with <weapon>. The edges catch fire as it
> hurtles towards <target>, clipping him slightly as it dissipates.

Trigger `375_Runewarden_Etch_Landed.lua` → `ataxiaBasher_rwConfirm("etch")`. And
`329_Battlerage_Global_Cooldown.lua` now also clears the in-flight hold on **every**
owned rotation (rw/dw/psion/gdragon) — a *rejected* battlerage did not land, so
replaying the held pick is exactly wrong. The send-side cooldown stamp deliberately
stays; it self-heals on its own timer.

Also fixed while writing this: the `ready` closures in `CARD_EXPLOIT` referenced `now`
before its `local` declaration, so they would have captured a nil global (caught by the
linter, never shipped in that state).

Files: `basher/010_Mnemosyne_Legend_Deck.lua`, `basher/002_Class_Bashing.lua` (comment),
`legenddeck_cards/001_Identify_Uses.lua`, `legenddeck_cards/008_LDeck_No_Charges.lua`
(NEW), `329_Battlerage_Global_Cooldown.lua`, `375_Runewarden_Etch_Landed.lua` (NEW),
`tests/test_mnem_ldeck.lua`, `tests/test_basher_runewarden.lua`, `CHANGELOG.md`,
`CLAUDE.md`, `docs/legend-deck.md`, `.claude/classes/runewarden.md`, memory.
Suite **640/640**.

---

## 2026-07-30 — Legend deck cards in the Mnemosyne basher (v4.7.165)

The basher's only legend-deck automation was **mob-name driven** —
`ataxiaBasher.ldeckRules` in `genrunning/002_search_targets.lua` maps "3 elite mhun keepers
in the room" to a draw list — which cannot work in Mnemosyne, where the denizen roster is
different every ripple. New layer `basher/010_Mnemosyne_Legend_Deck.lua` keys off **state**
instead, so it works on whatever the tower spawns:

| Card | Condition | Effect |
|---|---|---|
| **Morimbuul** | while bound | shrug off denizen ropes/bindings, 5 min |
| **Maran** | hp <= 20% | 5000hp barrier on the room, 60s |
| **Seasone** | hp <= 35% | `FOR ELIXIR` — +10% health elixir, 5 min |
| **Matic** | 3+ denizens | next attack is a guaranteed high-end crit |
| **Covenant** | rage for the payoff | plants RECKLESSNESS |
| **Xylthus** | rage for the payoff | plants STUN (never on a boss — it cannot bind one) |

"Enough battlerage to do a battlerage attack that benefits from this" is resolved per
class against the rotations that actually **read** the affliction — Blademaster Headstrike
and Magi Firefall for recklessness, Runewarden Etch for stun, all 25 rage — through
`ataxiaBasher_rageAfford`, so the rage floor composes. As a class with no such payoff
(Psion, Depthswalker, Infernal…) neither card is ever drawn: planting an affliction nothing
can spend would burn a charge for nothing.

**Economy is the design constraint.** These cards hold 2-3 charges and regenerate **one per
hour**, so every gate is deliberately conservative: at most ONE card per round, a per-card
minimum interval (>= the effect duration, so a redraw only ever renews something lapsed),
Matic additionally once per room, a hard `ldm.getCharges` check, and a skip when the
denizen already carries the affliction.

**In-flight replay**, as for the owned battlerage rotations: the basher rebuilds its command
every prompt with `queue addclearfull`, which wipes the queued line — stamping the interval
at build time would drop the draw from the very next rebuild, unsent (the v4.7.129 phantom
cooldown). The pick is held pending and replayed verbatim until `ldm.onDraw` (fed by "You
draw forth the power of X") confirms it landed, or the 4s window lapses.

Details worth recording:
- The layer is computed **before** the attack gate, because Morimbuul answers exactly the
  bindings that gate closes. On a gated round it goes out alone on the free queue —
  **once** per pick, since `queue add free` accumulates (unlike `addclearfull`, which
  replaces); an unguarded resend at 0.3s would empty the card in seconds.
- Xylthus's bind line is **not captured yet**, so the denizen-state layer would never see
  the stun and Etch could not cash it on the round we paid a charge for. The draw records
  `stun` optimistically; `BR_AFFS` lazily expires it in 4s if the bind whiffed. *Live
  capture wanted.*
- The pre-existing global Maran check in `assembleAttack` (hp < 25%, `return`s and forfeits
  the whole attack cycle) now **stands down in Mnemosyne** — running both would double-draw
  a 2-charge card.
- `M.run.boss` is now remembered from the `Objective: defeat <X>` line (cleared on ripple
  change and run end) so the Xylthus boss-skip has something to check.
- Bindings default to the whole family (webbed, entangled, transfixation, constricted,
  snared, roped), not webbed alone — the card covers "denizen ropes or bindings" and every
  one of these stops the basher dead. Narrow via `ataxiaBasher.mnemLdeckBindings`.

Command: `mnem cards [on|off|maran <hp%>|seasone <hp%>|matic <n>]`; bare `mnem cards` prints
charges, intervals and whether this class has a payoff for Covenant/Xylthus.

Files: `basher/010_Mnemosyne_Legend_Deck.lua` (NEW), `basher/001_Bashing_Functions.lua`,
`legend_deck/003_Legend_Deck_Functions.lua`, `mnemosyne/003_Commands.lua`,
`mnemosyne/004_Parsers.lua`, `tests/test_mnem_ldeck.lua` (NEW), `CHANGELOG.md`, `CLAUDE.md`,
`docs/legend-deck.md`, memory. Suite **637/637**.

---

## 2026-07-29 — Runewarden confirmations, bulwark highlight, and a correction (v4.7.164)

**Correction to v4.7.163.** That entry claimed triggers 330/331 carry no Runewarden
fire-lines and that ONSLAUGHT could never fire. **That was wrong.** Both lines exist —
collide at `330:47` ("You charge at <t>, slamming into him and throwing him back.") and
onslaught at `331:47` ("You unleash a ferocious onslaught on <t>...") — and those trigger
bodies are **class-agnostic**, so the shared timers were being set and the alternation
worked. The mistake came from grepping those files for the word "Runewarden", which only
appears inside the per-class `special` blocks. Corrected in the changelog, `CLAUDE.md`, the
code comment, and memory (with the diagnostic rule: grep the ability's **fire text**, never
the class name).

The rotation is still worth owning, for the reasons that *were* real: **Bulwark** was
gated behind `validTargets() >= 2` (it is Self-targeted — mob count is irrelevant), **Etch**
was never wired at all, and the owned table uses real AB cooldowns plus the rage floor,
in-flight pick replay and owned culling.

Now that the lines are known, they are wired as **confirmations** for the timer-free
rotation: 330 → `rwConfirm("collide")`, 331 → `rwConfirm("onslaught")`, 332 →
`rwConfirm("bulwark")` — each restarting its cooldown from the moment it actually landed
and releasing the in-flight hold. The class-agnostic timers still serve every other class.

**Bulwark is highlighted** bold gold on its own line ("The runes on your armour flare
brightly as you adopt a defensive stance.") — 25% damage negation for 15s is the one thing
worth seeing land mid-fight. A line highlight rather than a box echo, so it doesn't bury
the surrounding combat text.

Files: `330_Battlerage_Small.lua`, `331_Battlerage_Large.lua`,
`332_Battlerage_Special.lua`, `basher/002_Class_Bashing.lua` (comment), `CHANGELOG.md`,
`CLAUDE.md`, memory. Suite **614/614**.

---

## 2026-07-29 — Runewarden: owned battlerage + three boons (v4.7.163)

Switched to Runewarden (Sword and Board). Auditing it turned up the **same dead-rotation
bug** as Psion and Golden Dragon, plus a worse one:

- **BULWARK sat behind `validTargets() >= 2`**, so the class's headline mitigation was
  skipped in every single-mob fight — it is Self-targeted, so mob count is irrelevant.
- **ETCH was not wired at all** (the battlerage config only carries small/large/raze/
  special), so its aeon/stun bonus damage was never taken.

> **Corrected in v4.7.164:** this entry originally also claimed that triggers 330/331 carry
> no Runewarden fire-lines and that ONSLAUGHT could never fire. **That was wrong** — both
> lines exist (collide 330:47, onslaught 331:47) and their trigger bodies are
> class-agnostic, so the shared timers were being set and the alternation worked. The
> error came from grepping those files for the word "Runewarden", which only appears in
> class-gated blocks. The rotation is still worth owning for the reasons above.

**Runewarden now owns its battlerage** (`RW_BR`, timer-free, AB values): **Bulwark**
(28r/45s, Self — first, and no target gate) → **Etch** (25r/23s, gated on the denizen
actually carrying **aeon or stun**, which it consumes — the Depthswalker Erasure rule, so
solo it never fires and costs nothing) → **Onslaught** (36r/23s) → **Collide** (14r/16s).
Culling reap owned and floor-exempt; Runewarden added to the shared-culling exclusion list.
Trigger 332's existing Runewarden block now also calls `ataxiaBasher_rwConfirm("bulwark")`,
restarting the cooldown from the confirmed line.

> **Correction worth noting:** Bulwark's **15 seconds is its DURATION** (25% damage
> negation), not its cooldown — the cooldown is **45s**, so 45s is as often as it can
> possibly be held.

Three boons:

- **Falconer's Tactics** — falcon rake cd −66%. The Runewarden twin of Daemon Jaws: the
  game's ready-line comes sooner anyway, so this shrinks the missed-line **safety timer**
  30s → ~10.2s, which would otherwise become the gate.
- **Homebound** — "returning to your raido cures you of all afflictions and restores you to
  full health. Not effective in the same location." The raido must sit somewhere we are
  *not* standing, and the ripple's **holding room** is exactly that — so the explorer
  sketches `raido on ground` immediately before the one `down` that leaves it, once per
  ripple.
- **Hammer and NAIL** (distinct from the existing Hammer and **Anvil**) — with a sowulu
  rune down, attacks splash to a second denizen. The basher sketches `sowulu on ground` at
  2+ denizens, once per room, ahead of the swing; sketching is a free-queue action so it
  costs no balance.

Also confirmed: **`a razor-beaked falcon` was already covered** by the `falcon` keyword in
the own-denizen list (substring match), so the basher never targeted it.

Files: `basher/002_Class_Bashing.lua`, `basher/001_Bashing_Functions.lua` (culling
exclusion), `basher/005_Falcon_Cooldowns.lua`, `mnemosyne/008_Explorer.lua` (raido),
`332_Battlerage_Special.lua`, `mnemosyne/046-048` (NEW), boon claim/reset wiring,
`test_basher_runewarden.lua` (NEW, 15 cases). Suite **614/614**.

---

## 2026-07-29 — Resourceful makes Tyranny free (v4.7.162)

New Mnemosyne boon (the 23rd flag, `mnemResourceful`): *"Your endurance and willpower costs
are reduced by 10% and defeating a denizen restores 10% of your class resources."*

For **Infernal the class resource is LIFE ESSENCE** — so each kill refunds more than three
Tyrannies cost (3% apiece). The whole reason Tyranny was crowd-gated was to protect a
slowly-recovering resource, and that reason disappears when held alongside Army of the
Dead:

- Crowd gate drops from **2 denizens to 1** — gravehands in *every* room that has anything
  in it (user-directed), still once per room.
- Essence floor drops from **20% to 10%**, since kills top it back up.
- `ataxiaBasher.infTyrannyAt` overrides the threshold if you want it back.

Resourceful alone changes nothing — Army of the Dead is what makes the summon worth
casting; Resourceful only removes its cost objection.

Files: `basher/002_Class_Bashing.lua`, `mnemosyne/045_Resourceful.lua` (NEW), boon
claim/reset wiring, `test_basher_infernal.lua` (+4 cases), `.claude/classes/infernal.md`,
trigger catalog, `CLAUDE.md`. Suite **598/598**.

---

## 2026-07-29 — Tyranny is once per ROOM (v4.7.161)

User: *"Each room we enter can get hands of the grave with TYRANNY as Infernal."* The
gravehands belong to the room they were summoned in, so the cadence is **per room** — and
both earlier cuts had it wrong:

- v4.7.148 treated it as a 20s rotation cooldown → re-cast constantly, burning 3% life
  essence each time.
- v4.7.149 over-corrected to "one-time" with a 600s backstop → **skipped rooms**, which is
  the actual value of the ability.

Now the gate is the **room number** of the last cast: walking somewhere new re-arms it,
and returning to a room later summons there again. A blind gmcp (no room number) collapses
to a single "unknown" slot so it can never fire every round. The crowd gate (2+ denizens),
the life-essence floor, and replaces-the-swing behaviour are unchanged.

Files: `basher/002_Class_Bashing.lua`, `test_basher_infernal.lua` (per-room + gmcp-blind
cases), `.claude/classes/infernal.md`, memory. Suite **594/594**.

---

## 2026-07-29 — Parry pattern: an unbound frost elemental (v4.7.160)

New predictive-parry entry from a live log: **`an unbound frost elemental` -> fixed
torso.** Its ice-shard fist slam names the torso in both halves of the swing ("Shards of
ice explode from ... as they slam into your torso with bone-chilling force." then "dealt
30.0% damage to your torso"), and its other output — the frost prickle and humour
tempering — targets no limb at all. So parking the parry on the torso costs nothing and
covers its only limb-targeted attack.

Uses the `fixed` shape (same as the Death Knight and the Infernal Legion ravager): no
observation needed, the parry just sits there from the first swing.

Files: `self_limb_tracking/005_Denizen_Parry_Patterns.lua`,
`.claude/projects/basher/denizen-lines-catalog.md`, memory.

---

## 2026-07-29 — Deepfreeze: keep the PvP trackers out of the bashing loop (v4.7.159)

The live cast line confirmed Winter's Heart works (`Damage dealt: 1312 (cold)`), but it
also showed that two **existing PvP triggers** fire on that same line — and since the boon
makes the basher cast deepfreeze at every crowd, they now run on every bashing round:

- **`tarAffed()` was being fed denizen ids.** During bashing `target` is a numeric denizen
  id, so `magi_offense_tracking/014` and `pummel-related/001` were writing `frozen` /
  `nocaloric` / `shivering` into the **V3 player-affliction tracker** keyed on a denizen —
  every round, in a crowd. Both are now guarded with `type(target) ~= "number"`, the same
  numeric-id-means-denizen convention the denizen-state layer uses to stay PvP-inert.
- **The "baby it's cold outside" banner was going to spam.** A full-width box echo per
  round buries the combat text it sits in, so while the basher is enabled the cast line is
  simply coloured cyan instead; the box is kept for PvP, where it fires once and means
  something.

Files: `magi_offense_tracking/014_Deepfreeze.lua`, `pummel-related/001_Deepfreeze.lua`.

---

## 2026-07-29 — Winter's Heart: deepfreeze as a denizen AoE (v4.7.158)

New Mnemosyne boon (the 22nd flag, `mnemWintersHeart`): *"Your deepfreeze spell can now be
used against denizens and deals cold damage to all denizens in the location."*

- `ataxiaBasher_winterDeepfreeze` casts `deepfreeze` at **2+ denizens** (user-directed;
  tunable via `ataxiaBasher.deepfreezeAt`), skipped on shielded rounds.
- **Deliberately class-agnostic.** Deepfreeze is Elementalism, but the **Bracers of Frost**
  grant it too — the same artefact the swarm module points for icewalls — so it is wired
  into both the Magi and Infernal paths rather than assumed Magi-only.
- **It is an equilibrium cast**, which is what makes it nearly free: on classes whose
  attacks spend balance it rides *alongside* the swing (unlike Arc or Tyranny, which
  replace it), and for Magi it takes the same eq slot horripilation/elemental surge would
  have used. No client cooldown — one cast per equilibrium is its own limit, exactly as
  Kkractle's elemental surge works.

Standard boon lifecycle: claim intercept (matching both `winter's heart` and
`winters heart`), BOONS-row trigger `mnemosyne/044`, reset on run start, cleared on the
confirmed run end.

Files: `basher/002_Class_Bashing.lua`, `mnemosyne/044_Winters_Heart.lua` (NEW), boon
claim/reset wiring, `test_basher_infernal.lua` (+5 cases), trigger catalog, `CLAUDE.md`.
Suite **593/593**.

---

## 2026-07-29 — Swarm funnel window 3s -> 2s (v4.7.157)

User: *"they follow quite quickly."* `FOLLOW_WINDOW` drops again, 3s to 2s — chasers
arrive fast, so anything longer only idles on mobs that were never coming.

Still safe for the same reason as v4.7.156: the window is **refreshed by combat**, so a
mob that did follow and is swinging keeps resetting it and a real fight holds us there
regardless. `WALL_WINDOW` (8s, behind our own icewall) stays put — leakers trickle through
a wall slower.

Files: `mnemosyne/009_Swarm_Tactics.lua`, `CLAUDE.md`, memory. Suite **588/588**.

---

## 2026-07-29 — Swarm funnel window 4s -> 3s (v4.7.156)

User: the funnel wait was slower than the hit-and-run loop needed. `FOLLOW_WINDOW` in
`009_Swarm_Tactics.lua` drops from 4s to 3s — the time we sit in the funnel room waiting
for followers before re-entering and re-assessing.

Safe to shorten because the window is **refreshed by combat**: a mob that actually chased
us keeps resetting it, so a real fight still holds us there. Only the empty case (nothing
followed — the wildcat pattern) gets a second back per cycle. The indoors-behind-our-own-
icewall window (`WALL_WINDOW`, 8s) is unchanged: leakers trickle through a wall slower.

Every call site reads the constant, including the echo ("window 3s"), so nothing else
changed. Suite **588/588** (the swarm tests step the clock by 5s and 10s, both still past
the shorter window and inside the 8s wall window).

Files: `mnemosyne/009_Swarm_Tactics.lua`, `CLAUDE.md`, memory.

---

## 2026-07-29 — Auto-feed from the horn of plenty when starving (v4.7.155)

**Starvation is a combat emergency, not a flavour message.** The 2026-07-29 jungle log
shows exactly why: *"Your legs collapse from under you and consciousness leaves you as you
pass out."* followed by a wall of *"You are unconscious and thus incapable of action."*
while a puma, two cockatrices and our own hyena took ~10k health off us. While
unconscious, **nothing** in this system can help — no curing, no flee, no attack, no
escape ladder. SCORE confirmed the cause: `Hunger : starving to death`.

- New `ataxia_hornFeed(reason, force)` (`misc_scripts/022_Horn_Of_Plenty.lua`):
  `PROBE HORN` → capture the first item id from the listing → `GET <id> FROM HORN` →
  `EAT <id>`. The id must be read from the probe because the contents are randomised
  (`loaf545957`, `potpie268371`, `pork528142`…) and change as the horn refills.
- New trigger `374_Starving` fires it on the SCORE hunger row (captured verbatim from the
  log) and on the standing hunger warnings, with a box echo. 20s cooldown so a burst of
  lines can't queue a dozen probes; a 3s backstop disarms the capture if no listing
  arrives, so a catch-all regex is never left armed over combat text.
- `horn` feeds now (manual, ignores the cooldown); `horn on|off` toggles the automatic
  feed (default **on**, persisted); `horn auto` shows the setting.

The horn holds 6 items and resets to us, so an unnecessary eat costs almost nothing while
a missed one can cost the run — hence feeding eagerly rather than waiting for certainty.

Files: `misc_scripts/022_Horn_Of_Plenty.lua` (NEW), `374_Starving.lua` (NEW),
`configs/019_Horn_Of_Plenty.lua` (NEW), `002_Check_For_Any_Missing_Variables.lua`.

---

## 2026-07-29 — Hyena maul lines highlighted (v4.7.154)

The maul pair is easy to lose in scrolling combat, so it is now coloured. The highlight
lives inside trigger `367` rather than a new trigger, because those exact patterns already
match there and a second copy would be a duplicate-pattern trap.

Three states, three colours — deliberately avoiding the orange family, which is reserved:

- `You command your hyena to maul <t>.` → **dark_sea_green** (our order; nothing has landed
  yet)
- `A daemonic hyena lets loose a wooping cackle as she lunges at <t>...` → **chartreuse
  bold** (the free damage actually happening)
- `A daemonic hyena snarls as she hurls herself at <t>...` → **chartreuse bold** (the other
  maul variant, target form only — the at-you form is trigger 372's pet-turned-on-us case)
- `You cannot yet order your hyena to maul another foe.` → **dim_grey** (still on cooldown,
  nothing happened)

Files: `367_Infernal_Hyena_Maul_Cooldown.lua`, `.claude/classes/infernal.md`.

---

## 2026-07-29 — Fury of Ages + hyena out-of-range recovery (v4.7.153)

**Hyena out of range.** `Your hyena is too far away for you to command like that.` → new
trigger `373_Hyena_Too_Far` sends `hyena recall;order hyena follow me` (10s debounce), so
she comes back and stays with us. It also **releases the maul cooldown**: that order never
landed, and we optimistically arm the cooldown from our own command line, so charging a
full 30s for a maul that never happened would waste real uptime.

**Fury of Ages** (the 21st boon flag, `infFuryOfAges`): *"You can now use your fury ability
for 45 minutes out of every hour, and it grants an additional 8 strength and 20% faster
balance recovery, but endurance costs are quadrupled under its effect."*

Base FURY is deliberately never automated — +2 strength for 500 willpower after the first
daily use, capped at 4 uses per Achaean day. This boon changes the economics entirely, so
the basher now holds it up — while respecting the one real cost:

- **ON** at EP ≥ 60% (`ataxiaBasher.infFuryOnAt`), **OFF** below 25%
  (`infFuryOffAt`). The gap is deliberate hysteresis, backed by a **30s floor between
  toggles** — flapping would be worse than not using it at all, because each activation may
  still cost 500 willpower.
- Endurance is exactly what the boon quadruples and exactly what runs out on a long grind,
  which is why EP (not HP) is the gate.
- On a confirmed run-end the flag clears **and `fury off` is sent**, so fury is never left
  running with a quadrupled EP cost and no payoff.

Live capture still wanted: the fury on/off game lines (to confirm state rather than assume
it — state is currently optimistic), and whether the 500-willpower activation cost still
applies under the boon. If it doesn't, the 30s toggle floor can be relaxed.

Files: `basher/002_Class_Bashing.lua`, `373_Hyena_Too_Far.lua` (NEW),
`mnemosyne/043_Fury_Of_Ages.lua` (NEW), boon claim/reset wiring (+ run-end `fury off`),
`test_basher_infernal.lua` (+7 cases), `.claude/classes/infernal.md`, trigger catalog,
`CLAUDE.md`. Suite **588/588**.

---

## 2026-07-29 — Hyena maul rides every round (v4.7.152)

User: *"hyena maul should be used as much as it can be."* It wasn't — and my own recent
work had made it worse.

HYENA MAUL is a **pet order**: it costs none of our balance or equilibrium, so the only
thing limiting it is its own cooldown. But it lived **inside each spec's swing string**,
so every branch that *replaces* the swing silently dropped it:

- **Tyranny** rounds (v4.7.149) — swing replaced, maul gone.
- **Arc** rounds (v4.7.150) — swing replaced, maul gone.
- **Shielded without rageraze** — that branch emits the razer + battlerage, no swing.
- **Dual Blunt** — never had the maul at all, in any round.

It's now hoisted into its own rider prefixed to every branch, exactly like the deathaura
and quash riders. The one deliberate exception is a **shielded** denizen: a maul splashes
off the shield and burns the whole 30s cooldown for nothing, so it holds the ~3s until the
shield lapses — skipping there is what *maximises* landed mauls.

Also: the cooldown now starts from **our own command line** (`You command your hyena to
maul <target>.`) as well as the hyena's attack line, so a missed pet line can't desync it.
The v4.7.148 safety timer remains the final backstop.

Files: `basher/002_Class_Bashing.lua`, `367_Infernal_Hyena_Maul_Cooldown.lua`,
`test_basher_infernal.lua` (+5 cases covering each previously-dropping branch),
`.claude/classes/infernal.md`. Suite **581/581**.

---

## 2026-07-29 — Necrotic Aura + razeslash spelled out (v4.7.151)

**Necrotic Aura** (the 20th boon flag, `infNecroticAura`): *"While you are empowered by an
aura of death, your attacks will infect the body of your enemy, inhibiting them from
healing."*

- The "aura of death" is the **DEATHAURA** defence (GMCP-tracked, raised by the bare
  `deathaura` command), so the boon turns an ordinary standing defence into a damage
  multiplier against every self-healing denizen — exactly the mobs that otherwise out-heal
  a slow kill. `ataxiaBasher_infDeathaura` re-raises it **only when GMCP says it dropped**
  (10s attempt-hold), prefixed to every round including shielded ones.
- **The proc line is captured**: *"Your sickening aura of death empowers your attack,
  denying vitality from suffusing your foe."* → new trigger
  `denizen_attacks_misc_lines/024` highlights it and records **`inhibit`** on the denizen
  — the same state Monk's Ripplestrike applies, so the denizen-state layer already models
  it and a second inhibit is never spent on a mob that already has one.

**`rsl` → `razeslash`** (user): the shield raze is `razeslash <target>`. `rsl` is a
personal server-side alias rather than a game command — the same class of bug as the old
`st` vs `settarget` retarget failure, which silently did nothing for months. Fixed in all
four knight DWC branches of the basher (Infernal, Paladin, generic knight, Runewarden).
**Not** changed in the PvP `dwc/` files, which send `rsl <target> <venom>` — left alone
deliberately, but worth verifying they actually fire.

Files: `basher/002_Class_Bashing.lua`, `mnemosyne/042_Necrotic_Aura.lua` (NEW),
`denizen_attacks_misc_lines/024_Denizen_Necrotic_Inhibit.lua` (NEW), boon claim/reset
wiring, `test_basher_infernal.lua` (+5 cases), `.claude/classes/infernal.md`, trigger
catalog, `CLAUDE.md`. Suite **576/576**.

---

## 2026-07-29 — Indiscriminate: Arc as a denizen AoE (v4.7.150)

New Mnemosyne boon (the 19th flag, `infIndiscriminate`): *"Your Arc is now effective
against denizens."*

ARC (Weaponmastery, general — all four specs) normally reads **"Works on: Adventurers and
room"**, so it's dead weight in PvE; this boon is exactly what makes it hit denizens. Per
AB, the **untargeted** form damages everyone in the room for **4.75s of balance**, while
naming a target hits only them for 3.00s — we always want the room form.

- `ataxiaBasher_infArc` swings `arc` **instead of** the single-target attack at **2+
  denizens** (user-directed; tunable via `ataxiaBasher.infArcAt`). It spends balance, so
  like Tyranny it replaces the swing rather than riding alongside it.
- The crowd gate is the whole point: at 4.75s against a ~2s `dsl`, one arc costs more than
  two normal swings — it only pays with enough denizens standing in it. At exactly 2 it's
  roughly break-even, so raise `infArcAt` to 3 if it feels slow.
- Yields on shielded rounds (break the shield first), and no venom is applied — denizens
  ignore the affliction.

Standard boon lifecycle: claim intercept, BOONS-row trigger `mnemosyne/041`, reset on run
start, cleared on the confirmed run end.

Files: `basher/002_Class_Bashing.lua`, `mnemosyne/041_Indiscriminate.lua` (NEW), boon
claim/reset wiring, `test_basher_infernal.lua` (+6 cases), `.claude/classes/infernal.md`,
trigger catalog, `CLAUDE.md`. Suite **571/571**.

---

## 2026-07-29 — Tyranny corrected, QUASH wired, life essence tracked (v4.7.149)

Three corrections to yesterday's Army of the Dead work, from the user plus the Oppression
wiki.

- **It's TYRANNY, not "summon hands of the grave"** — that phrasing is the *Apostate*
  branch (the existing gravehands alias already forks on class). The basher now sends the
  right command per class.
- **It's a ONE-TIME summon, and it costs 3% life essence.** The first cut re-cast it on a
  20s rotation cooldown, which would have burned essence continuously — and Hellforge
  users regain essence at *reduced* rates. It is now cast once, gated on a life-essence
  floor (`ataxiaBasher.infEssenceFloor`, 20%), with a long 600s re-arm that exists only as
  a backstop for a lost summon.
- **It spends 3.00s of BALANCE, so it replaces the swing** rather than riding alongside
  `dsl` — the two would otherwise fight over the same balance.
- **Life essence is now parsed** (`ataxia.vitals.essence`, loosely matched in the
  charstats parser since the key wording isn't pinned) and shown on the bashing HUD in a
  new **Infernal block**: Essence % (green/yellow/red), hyena Maul ready/cd, and any
  active Infernal boons.
- **QUASH is wired as the PvE shield answer.** The Oppression wiki lists it as "Adventurers
  **and denizens**", 4.00s of *equilibrium*, dealing damage *and* stripping magical
  shields. Equilibrium is idle while every Infernal attack spends balance, so it strips
  the shield without spending rage (the standing doctrine) and without costing the swing —
  the balance razer still runs in the same round. Shielded rounds only, 4s attempt-hold,
  `ataxiaBasher.infQuash = false` to disable.

Malignity audit (for the record): **no denizen-capable offence at all** — every offensive
ability there is Adventurers-only, including the whole hyena command suite. Its PvE value
is self-buffs (Weathering/Resistance/Gripping, already in the shared defence list) plus
**FURY** (+2 strength), which is deliberately *not* automated: 500 willpower after the
first daily use and capped at 4 uses per Achaean day.

Files: `update_stuff/004_ataxia_Vitals_Update.lua`, `basher/002_Class_Bashing.lua`,
`windows/001_Limb_Counter_Window.lua`, `test_basher_infernal.lua`,
`.claude/classes/infernal.md`. Suite **565/565**.

---

## 2026-07-29 — Infernal: stop attacking your own hyena, + two boons (v4.7.148)

**The basher was killing your pet.** "a daemonic hyena" was never in the seeded
own-denizen list, so it counted as a legitimate denizen — it showed under "Denizens (1)"
and got attacked down to 4% on the mob bar. A mauled hyena turns on its owner, which is
exactly the line that followed: *"A daemonic hyena snarls as she hurls herself at you,
raking her claws across your face."*

- **`hyena` added to the ownDenizens default and back-filled into existing saves**, so it
  is excluded from targeting and auto-learn (the same treatment the Magi ashbeast got).
- **New trigger `372_Hyena_Turned_On_Us`**: on the at-YOU line, with the basher enabled,
  sends `order hyena passive` (10s debounce) — a pet that has *already* flipped keeps
  clawing even once the list is fixed.
- **Trigger 367 gained a `(?!you,)` lookahead.** The maul line for a real foe opens
  identically ("...hurls herself at a royal guard..."), so the at-you form was *also*
  putting the maul on cooldown for a hit we never ordered.

Two new Mnemosyne boons (flags 17 and 18):

- **Army of the Dead** — "When summoning the hands of the grave, you will deal damage to
  all denizens in the location." `ataxiaBasher_infGravehands` casts `summon hands of the
  grave` at 2+ denizens, ahead of the swing, skipped on shield-break rounds. The real
  cooldown isn't in the boon text and hasn't been captured, so it uses a conservative 20s
  stamp (`ataxiaBasher.infGravehandsCd`) — worth tuning once the refusal line is seen.
- **Daemon Jaws** — "The cooldown for commanding your hyena to maul a denizen is reduced
  by 66%." The maul reset is line-driven and the game simply sends its ready-line sooner,
  so the boon needs no help there. What it *did* expose: `basher/005` had **no safety
  timer at all**, so a single missed ready-line stranded `hyenaMaulReady = false` forever
  and the maul would silently never fire again. There's now a backstop (30s), scaled to
  ~10.2s under the boon so it can never become the gate.

Files: `002_Check_For_Any_Missing_Variables.lua`, `basher/002_Class_Bashing.lua`,
`basher/005_Falcon_Cooldowns.lua`, `triggers/.../372_Hyena_Turned_On_Us.lua` (NEW),
`367_Infernal_Hyena_Maul_Cooldown.lua`, `mnemosyne/039_Army_Of_The_Dead.lua` +
`040_Daemon_Jaws.lua` (NEW), boon claim/reset wiring, `test_basher_infernal.lua` (NEW),
`test_basher_owndenizens.lua`, `.claude/classes/infernal.md`. Suite **557/557**.

---

## 2026-07-29 — Depthswalker block on the bashing HUD (v4.7.147)

The `tarc` bashing panel now has a Depthswalker section beside the existing Shaman
(swiftcurse) and Pariah (epitaph) class blocks, so the state the rotation spends is
visible instead of inferred:

- **Age**, colour-coded on the same 250/400/600 thresholds as `getAgeColour` — the same
  ceiling the Flashforward re-up respects (`dwAgeCap`, 400), so you can see when bashing
  is approaching it.
- **Word** balance: `ready` or `spent` — the resource nakail and the Terminus buffs share.
- **Buff chips** — Blur / Trusad / Tsuura / Mainaas — **green** when the defence is
  standing, **grey** when down, and **RED when down while Flashforward is paying +20%
  damage for it**. A `Flashforward +20% dmg while Blur` line shows while the boon is
  claimed.

Files: `windows/001_Limb_Counter_Window.lua`, `.claude/classes/depthswalker.md`,
`CLAUDE.md`. (The HUD needs Geyser so it is not unit-tested; the block's colour/state
logic was simulated across all three states before shipping.) Suite **547/547**.

---

## 2026-07-29 — Flashforward: keep chrono blur up for +20% damage (v4.7.146)

New Mnemosyne boon (the 16th flag, `dwFlashforward`): *"You deal 20% bonus damage while
you possess the chrono blur defence."*

- `ataxiaBasher_dwFlashforward` (basher/002) re-ups `CHRONO BLUR` whenever the boon is
  claimed and the GMCP `blur` defence is down. It is an **equilibrium rider paid in AGE**
  — not the word balance — so it never competes with nakail or the Terminus buffs, and it
  rides shielded rounds too (the buff is on *us*, and a shield round still ends in a
  swing).
- **Age-capped** by `ataxiaBasher.dwAgeCap` (default 400 — the yellow/orange boundary in
  `getAgeColour`): age is the class's PvP currency and bashing must not price out the
  chrono kit. 8s attempt-hold so the defence line has time to land.
- Standard boon lifecycle: claim intercept (`flashforward`), BOONS-row trigger
  `mnemosyne/038_Flashforward`, reset on run start, cleared on the confirmed run end.

Files: `basher/002_Class_Bashing.lua`, `mnemosyne/038_Flashforward.lua` (NEW),
`002_Boon_Claim.lua`, `001_Run_Start.lua`, `mnemosyne/004_Parsers.lua`,
`002_Check_For_Any_Missing_Variables.lua`, `test_basher_depthswalker.lua` (+6 cases),
`.claude/classes/depthswalker.md`, trigger catalog. Suite **547/547**.

---

## 2026-07-29 — Depthswalker: lessons from a live log (v4.7.145)

A Mnemosyne bashing log (Death Knight + soldier of Osterrych) settled three open
questions and exposed two mistakes.

- **Denizen AEON measured at ~5.6s** (landed 12:15:14.0, expired 12:15:19.7) against
  Chrono Curse's **35s cooldown** — ~16% uptime. **Curse no longer banks rage**: holding
  24 rage back and skipping the cheap filler to guarantee a five-second mitigation window
  loses more damage than it saves. It fires when affordable and yields otherwise. (This
  was the exact risk flagged when the rotation shipped; now it's measured, not guessed.)
- **Curse fire line + wear-off captured and wired** —
  `Bending your formidable will upon <t>, you slow the passage of time about him to a
  crawl.` and `<t> abruptly begins to move at normal speed again.` Added to the existing
  denizen-aeon triggers (015/016), which now also confirm the cast
  (`ataxiaBasher_dwConfirm("curse")` restarts the cooldown from the landed moment). This
  is the **first confirmed denizen-aeon apply line in the system** — `BR_AFFS.aeon.apply`
  had been nil for every class.
- **A second intone wording existed and was unmatched.** Augmentation self-buffs print
  `Taking a steadying breath, you turn your focus inward and proclaim, "X".` rather than
  `Imbuing your voice with power, you intone, "X".`, so `wordBal` stayed TRUE after e.g.
  Mainaas and the next word would be sent into a balance we didn't have. It is the same
  balance (Mainaas 12:15:06.4 → word-balance-returned 12:15:12.5 = 6.1s ≈ its 6.50s
  cost). Both wordings now match.
- **The keeper stopped buffing while we're losing.** It intoned Mainaas at 12% HP, prone,
  with two mobs on us; it is now gated on `ataxiaBasher_dangerLevel() == "attack"`.

Also recorded in the class doc: reap damage samples (base non-crit 2515 with 2x/4x/10x
crits), Shadow Drain's tick/end lines and ~9s duration, confirmation that the atrophy DoT
is **gear, not class** (it fired here on DW after first appearing on Golden Dragon), and
the shield-bounce cost (~5 rounds across three shields — `shieldswap` is the lever, since
rage deliberately isn't spent on shields).

Files: `basher/002_Class_Bashing.lua`, `denizen_attacks_misc_lines/015` + `016`,
`depthswalker/009_Word_Bal_Used.lua`, `test_basher_depthswalker.lua`,
`.claude/classes/depthswalker.md`. Suite **541/541**.

---

## 2026-07-29 — Terminus buffs are one-time defences; `defs valid` shows the raising word (v4.7.144)

Two user corrections to the Depthswalker work.

**1. `defs valid` now names the command that raises each defence.** Nothing about the
protocol name `precision` tells you to `INTONE TRUSAD`. New per-class map
`ataxiaTables.defenceWords` + `ataxia_defenceWord(def)` (`deffing/004`), rendered as
`Precision (trusad)` in dim grey. The protocol names are untouched — `defadd`, `keepadd`
and `curing priority defence <def> 25` all key off them; this is display only. Column
width now follows the widest label (3 per row when labels are long) so the grid stays
aligned. Depthswalker mapping: precision→trusad, durability→tsuura(?),
bodyaugment→mainaas(?), antiforce→gaiartha(?), plus disperse/shadowveil→`shadow …`. The
`(?)` entries are inferred from AB text — correct them in that one table if a live `DEF`
disagrees.

**2. Terminus words are ONE-TIME defences** ("used once unless it says works against"),
so re-asserting them on a timer was wrong:

- `ataxiaBasher_dwKeeper` no longer carries the flagless weapon augments
  (mainaad/balateth) on a 30-minute hold. It keeps only the three GMCP-tracked words and
  re-ups one **solely when its defence actually dropped** — with all three standing it
  emits nothing.
- New **`dw setup`** (`class_things/003_Depthswalker_Setup.lua`) raises the full one-time
  list — trusad, tsuura, mainaas, mainaad scythe, balateth scythe, tah'maal, ukhia,
  qamad, dalem — **one per word balance**, chained off the game's own
  `You may intone another word of power.` line (trigger `depthswalker/010`), since all
  intoned words share one balance and can't be batched. Denizen-facing buffs go first so
  an interrupted run still lands the ones that matter. `dw setup force` re-intones
  standing defences; `dw setup stop` clears the queue. Excluded on purpose: **Kail**
  (prismatic barrier stops *us* attacking), **Laiad/Hailad** (denizen-targeted actions,
  not defences), **Tooros** (damages the caster).

Files: `deffing/004_Defence_Sorting_-_Cleaner.lua`,
`configuration_commands/007_Show_Valid_defs.lua`,
`class_things/003_Depthswalker_Setup.lua` (NEW), `depthswalker/010_Word_Bal_Returned.lua`,
`aliases/.../depthswalker/025_DW_Setup.lua` (NEW), `basher/002_Class_Bashing.lua`,
`test_basher_depthswalker.lua`, `.claude/classes/depthswalker.md`. Suite **540/540**.

---

## 2026-07-29 — Rage is never spent on shields (v4.7.143)

User doctrine: *"we don't ever really want to use battlerage to strip shields."* That is
already the codebase convention — `ataxiaBasher.rageraze` defaults **off**, Magi never
fires Disintegrate (it casts the free `erode`), Monk never fires Splinterkick (shatter is
free) — but v4.7.142 made Depthswalker's **Nakail** (a 17-rage battlerage) fire at
shielded denizens unconditionally.

- Nakail is now behind `rageraze` again, like every other class's rage razer. The default
  answer to a shielded denizen is to keep swinging: trigger 336 clears
  `ataxiaBasher.shielded` on a ~3.1s timer, and with `shieldswap` on it retargets to
  another mob instead.
- **Correction to the v4.7.142 entry**, which called this a "shield stall": it wasn't. The
  shield flag self-clears, so there was never an infinite bounce, and the absent razer was
  the intended behaviour rather than a bug. The genuine v4.7.142 fixes stand (culling
  suppression, separator corruption, the nakail shield-flag clear when rageraze *is* on).

Files: `basher/002_Class_Bashing.lua`, `test_basher_depthswalker.lua`,
`.claude/classes/depthswalker.md`. Suite **539/539**.

---

## 2026-07-29 — Depthswalker PvE overhaul: owned rotation, shield fix, Terminus keepers (v4.7.142)

Switched to Depthswalker; audited the class against the wiki (Depthswalker / Aeonics /
Shadowmancy / Terminus) and the code. The basher was 17 lines that wired 2 of the class's
**6 denizen-legal** battlerage abilities and carried three independent defects.

- **SHIELD STALL fixed.** The shielded branch only razed when `ataxiaBasher.rageraze` was
  on — and it defaults OFF — so a shielded denizen bounced forever with no razer at all.
  `intone nakail` (17 rage + the shared word balance) now fires whenever it's affordable,
  gated on neither the rageraze toggle nor the rage floor.
- **CULLING SUPPRESSION fixed** — the actual dead-rotation cause, and *not* the
  Psion/Golden-Dragon missing-fire-line bug (DW's fire-lines exist at triggers 330:43 and
  331:43). The shared culling branch heads the elseif chain and excluded only
  Bard/Blademaster/Magi/Psion, so with culling on Depthswalker returned `""` every round
  below 36/54 rage and neither shadow drain nor shadow lash ever fired. DW is excluded
  there now and owns culling in its own rotation.
- **Depthswalker owns its battlerage** (`DW_BR` + `ataxiaBasher_dwBattlerage`, the
  timer-free pattern): culling reap → **Erasure** (gated on the mob actually carrying
  weakness/amnesia, which it consumes — solo it never fires and costs nothing; it lights
  up beside a Blademaster's Nerveslash or a Golden Dragon's Psidaze) → **Curse** (denizen
  AEON, skipped when aeon is up, banks rage when off cooldown but unaffordable) →
  **Boinad** (opt-in denizen CHARM on the mob we are *not* killing) → **Lash** → **Drain**.
  Real AB costs/cooldowns, send-side stamps, 3s in-flight pick replay, rage-floor aware.
- **Nakail shield-clear**: nakail has no fire-line, and a shielded round emits no
  battlerage, so 330/331/332 never ran and `ataxiaBasher.shielded` never cleared — nakail
  re-fired every round burning 17 rage and the word balance. The intone echo (trigger
  `depthswalker/009_Word_Bal_Used`) now clears the flag and emits a `(BR)` alert.
- **Terminus buff keepers** (`ataxiaBasher_dwKeeper`, from the character's live
  `AB TERMINUS`): `trusad` (crit chance **vs denizens**), `tsuura` (damage reduction
  **from denizens**), `mainaas` (skin resist), `mainaad`/`balateth` (scythe damage/speed).
  These spend the **word balance** — a separate resource from attack balance/eq — so they
  are free uptime while the scythe swings. They yield to nakail and skip when their GMCP
  defence is already up.
- **Separator corruption fixed** (`shadow drain 7;;shadow reap 7`, and a leading `;` when
  the battlerage was empty), battlerage computed lazily past the shielded early-return,
  and the unguarded `ataxiaBasher.battlerage.Depthswalker.raze` dereference removed.
- Toggles: `bash dw boinad|cull|keepers on|off`.

Files: `basher/002_Class_Bashing.lua`, `basher/001_Bashing_Functions.lua` (culling
exclusion), `triggers/.../depthswalker/009_Word_Bal_Used.lua`,
`002_Check_For_Any_Missing_Variables.lua`, `aliases/.../configs/018_Depthswalker_Bashing.lua`
(NEW), `test_basher_depthswalker.lua` (NEW, 18 cases), `.claude/classes/depthswalker.md`
(bashing section rewritten — the old stub claimed a command the basher never sent).
Suite **539/539**.

---

## 2026-07-29 — Rage floor + rage-threshold damage probe (v4.7.141)

User gear: **"+23% damage so long as you have 40 battlerage or more."** Every battlerage
cast that dips below 40 forfeits that bonus on every attack until rage rebuilds — so
spend-freely vs hold-the-floor is an empirical question, not a theoretical one. This
ships the policy knob and the measurement to settle it.

- **Rage floor** (`ataxiaBasher.rageFloor`, `bash floor <n|off>`): with a floor of N an
  ability costing C fires only at C + N rage — the rotations spend only the SURPLUS.
  New pure helper `ataxiaBasher_rageAfford(rage, cost)` (basher/001) wired into EVERY
  rotation: the generic assembler + `standardBattlerage` + `crowdControlBattlerage`, and
  the class-owned bard / **blademaster** / magi / monk (001) and Golden Dragon / Psion
  (002) rotations. **nil/0 = off and provably behaviour-identical** — the whole existing
  suite passes unmodified.
  - **Culling reap is NEVER floored**: an execute that ends the fight outright beats a
    per-swing multiplier, and flooring it (76 rage at floor 40) would idle the cooldown.
  - The alias **clamps the floor to 46** (100-rage cap minus the priciest gated ability,
    54 under rageraze) — above that, an ability could never be afforded, and a rotation
    that banks for an unaffordable cast would stop producing battlerage entirely.
  - Golden Dragon's banking rule composes: a control simply banks until cost + floor.
    The in-flight pick replay is untouched (the pick was floor-validated when chosen;
    command stability across the 0.3s re-queue loop still rules).
- **Rage probe** (`basher/009_Rage_Probe.lua` NEW, `bash probe ...`): records every
  NON-CRIT damage line with the rage we had at the time (one hook in
  `350_Damage_Dealt.lua`, before the crit flag resets). Crits are counted but excluded —
  their heavy tail swamps a 23% signal. Samples are keyed by mob AND class, FIFO-capped
  at 1500.
  - `bash probe report` — mean hit at >= threshold vs < threshold per mob, plus the
    ratio (a real +23% shows as ~1.23). Hits inside a +/-4 ambiguity band are skipped:
    `ataxia.vitals.rage` is last-prompt (pre-attack) data, so boundary hits misclassify.
  - `bash probe bands` — mean per 10-rage band, which locates the REAL breakpoint
    instead of assuming 40 (and would catch a second breakpoint from other gear).
  - Also `on|off|at <n>|dump [n]|clear|status`. Ordinary bashing produces both arms
    (rage oscillates naturally), so 15-30 minutes answers the question with no protocol.

The full A/B trial harness (labelled windows, kills/hr vs dmg/min, ABBA interleaving) is
deliberately deferred until the probe confirms the buff is real and worth chasing.

Files: `basher/001_Bashing_Functions.lua`, `basher/002_Class_Bashing.lua`,
`basher/009_Rage_Probe.lua` (NEW), `triggers/.../350_Damage_Dealt.lua`,
`aliases/.../configs/016_Rage_Floor.lua` + `017_Rage_Probe.lua` (NEW),
`test_rage_probe.lua` (NEW, 15 cases), floor cases in `test_basher_battlerage.lua` +
`test_basher_dragon.lua`. Suite **521/521**.

---

## 2026-07-28 — Deluge affix: no flying underwater (v4.7.140)

User report from the affix screen: "Deluge: All rooms are underwater." — FLY cannot
work, but the swarm module's low-HP escape ladder (outdoor fly+hover recovery) and
the fly-kite assume it can. A queued `fly` fails silently, leaving the "recovering"
state grounded and attack-gated until its 60s cap — blind exactly at low HP.

- New affix flag `mnemDeluge` (trigger `037_Deluge` on the status row — the
  Haemophiliac shape: telemetry-independent, `inMnemosyne` gate, transition guard;
  reset on run start, cleared on the confirmed run end).
- `S._canFly()` gates both flight decisions in `009_Swarm_Tactics`: the escape
  ladder's outdoor branch now falls through to the grounded retreat (or the shield
  fallback with no route), and the kite entry never arms underwater.

Files: `mnemosyne/004_Parsers.lua`, `009_Swarm_Tactics.lua`,
`triggers/.../mnemosyne/037_Deluge.lua` (NEW), `001_Run_Start.lua`,
`test_swarm_tactics.lua` (+1 grounded-escape regression). Suite **500/500**.

---

## 2026-07-28 — Venomous breath echo highlight (v4.7.139)

Fourth breath echo captured live: "An echo of venomous breath rots the corpse of
<target>, afflicting her with a plague of weakness." Added to
`highlighting/034_Breath_Echoes` in bold **green_yellow** (sickly green, venom
family; user-directed) alongside psionic/orchid, flaming/tomato, frigid/cyan.

Files: `highlighting/034_Breath_Echoes.lua`, `.claude/classes/dragon.md`.

---

## 2026-07-28 — Seasone phial counter: touch tree DIRECTLY (v4.7.138)

Second live Seasone truelock (as Golden Dragon) exposed two failures in the v4.7.123
counter: (1) `onSeasonePhials` early-returned when the reserve hadn't armed — a
missed `Objective:` line made the phial burst a complete NO-OP; (2) even released,
`curing tree on` only *permits* SSC to tree, and SSC never did while the truelock
sat for 25+ seconds (the dragon class heal is itself lock-blocked: "Your mind and
body are too disjointed"). User directive: the phial line is when we TOUCH TREE.

- The phial-line counter now sends **`touch tree` directly** (the tattoo works
  prone and through a truelock), with bounded re-touches at 3/6/10s while the lock
  signature (asthma + anorexia) persists — tree balance may be down on the first
  attempt.
- The counter is **reserve-independent**: it fires whether or not the Objective
  line armed `curing tree off`. The reserve release (`curing tree on`) still
  happens when armed, and the Splinterbark taint still wins (a tainted tree is
  never touched).

Files: `mnemosyne/004_Parsers.lua`, `test_mnemosyne.lua` (phial tests rewritten:
direct-touch + no-reserve regression). Suite **499/499**.

---

## 2026-07-28 — Golden Dragon control casts join the (BR) alert + denizen-state system (v4.7.137)

User request: echo the Golden Dragon battlerage casts like the other classes'
battlerage skills. That idiom is the `(BR):` console alert + per-denizen affliction
capture (`008_Denizen_State`, the v4.7.62 overhaul layer).

- **Deaden** (trigger `highlighting/030`): records `aeon` on the target's denizen
  state and echoes `(BR): AEON on <id> -- Deaden landed, mob acts slower`.
- **Psidaze** (trigger `highlighting/028`): records `amnesia` (new `BR_AFFS` entry,
  30s lazy-expiry backstop) and echoes `(BR): AMNESIA on <id> -- Psidaze landed...`.
  The wear-off line (trigger 031) now also resolves the mob name to its id and
  clears the amnesia PRECISELY — plus keeps the measured-uptime echo for tuning the
  backstop. `BR_AFFS` already had a deliberate `amnesia = {dur=nil}` (persist until
  cleared, pinned by a test); with the precise wear-off clear in place it's replaced
  by the 30s self-healing backstop — the persistence test now pins `shielded` (the
  real nil-duration state) and a new case pins amnesia's backstop + precise clear.
- Overwhelm stays echo-quiet deliberately — it applies no affliction and fires every
  16s; its bold highlight already marks it.
- Alerts are gated the standard way: numeric server target + basher enabled +
  `ataxiaBasher.brAlerts` (default on).

Files: `basher/008_Denizen_State.lua`, `highlighting/028/030/031`,
`.claude/classes/dragon.md`.

---

## 2026-07-28 — Atrophy DoT recolour: orange is reserved (v4.7.136)

User request: orange is already in use elsewhere in their setup, so the crit-proc
atrophy DoT lines (apply + tick, trigger `highlighting/029`) move from bold
dark_orange to bold **deep_sky_blue** (spectral-mist blue; distinct from the frigid
echo's cyan and everything else in the highlight palette).

Files: `highlighting/029_Atrophy_Dot.lua`, `.claude/classes/dragon.md`.

---

## 2026-07-28 — Breath-echo proc highlights (v4.7.135)

Live captures (user): dragon breath attacks echo with per-element riders on the
denizen — psionic echo = clumsiness ("...forcing him to stumble clumsily around."),
flaming echo = natural-healing inhibition ("...scorching him and inhibiting his
natural healing."), frigid echo = aeon ("...slowing her movements to a crawl.").
Source unconfirmed (boon/affix?).

- New trigger `highlighting/034_Breath_Echoes` (three patterns, pronoun-tolerant):
  psionic echo bold orchid (control family), flaming echo bold tomato (burn
  family), frigid echo bold cyan (ice family).

Files: `highlighting/034_Breath_Echoes.lua` (NEW), `.claude/classes/dragon.md`.
Suite **497/497**.

---

## 2026-07-28 — DRAGONFLEX: snap bindings instead of writhing (v4.7.134)

AB Flex (1534): DRAGONFLEX, self, 2.00s of balance — "snap through those feeble
attempts to bind."

- On gaining **entangled or webbed** in any Dragon class, the affliction-gained
  handler (`004_Aff_gains_losses.lua`, the existing Bard/Pariah escape branch) now
  prepends `dragonflex` to the eqbal queue (the prone → stand idiom) — one balance
  action instead of repeated writhes; SSC writhing still backstops it if the flex
  gets eaten. Webbed coverage is assumed from the AB wording ("binds") — confirm
  live; entangled is the user-confirmed case.

Files: `004_Aff_gains_losses.lua`, `.claude/classes/dragon.md`. Suite **497/497**.

---

## 2026-07-28 — Draconic Rampage: trample AoE at 2+ denizens (v4.7.133)

New Mnemosyne boon (the 15th flag, `dragonRampage`): "Your draconic trample now deals
a large amount of cutting damage to all denizens in your room. This effect has a 40
seconds cooldown." AB Trample (1564): room-wide, 2.75s of balance; off-proc it only
hits prone targets.

- `ataxiaBasher_dragonRampagePick` (basher/002): at 2+ denizens (Mnemosyne
  `_denizenCount`, the Kai Choke gate) with the proc ready, the round's balance swing
  becomes `trample` (user-directed). The eq blast weave and the battlerage still ride
  beside it; shield-break rounds skip it. Send-side 40s stamp + the v4.7.129
  in-flight hold (the trample round replays verbatim across the re-queue loop).
- **Proc line confirmed live** ("Iron-sharp claws rip and tear into all around
  you...") — trigger `highlighting/033` highlights it bold orange_red and
  `ataxiaBasher_dragonRampageProc()` restamps the 40s cooldown from the LANDED
  moment, releasing the trample hold.
- Standard boon-flag lifecycle: claim intercept (`%f[%a]rampage`), BOONS-row trigger
  `036_Draconic_Rampage`, reset on run start, cleared on the confirmed run end.

Files: `basher/002_Class_Bashing.lua` (rampage pick + proc confirm; `primary()` takes
a balance-override), `mnemosyne/036_Draconic_Rampage.lua` (NEW),
`highlighting/033_Rampage_Proc.lua` (NEW), `001_Run_Start.lua`, `004_Parsers.lua`,
`002_Boon_Claim.lua`, `test_basher_dragon.lua` (+6 cases). Suite **497/497**.

---

## 2026-07-28 — Golden Dragon fire lines: Deaden + Overwhelm confirmed, recovery + DoT highlights (v4.7.132)

Live captures (user): three more Golden Dragon lines land the confirmation upgrade,
plus two extras worth highlighting.

- **Deaden fire line** ("You psychically slam your mind into <t>'s, deadening his
  reactions.") — trigger `highlighting/030`, bold gold + `gdragonConfirm("deaden")`
  (35s cd from the landed moment). This also settles the 332 question: the
  "rummage...deadening it" line there is Psion's, not Golden's.
- **Overwhelm fire line** ("You charge quickly at <t>, throwing your mighty form...")
  — trigger `highlighting/032`, bold orange_red + `gdragonConfirm("overwhelm")`
  (16s cd). Only Psiblast's line remains uncaptured (331:80 is the likely suspect).
- **Psidaze wear-off** ("Sparkles of psi energy cease their distracting dance...") —
  trigger `highlighting/031`, dim_grey + a one-line echo of the MEASURED amnesia
  uptime vs the 41s cooldown (delta from the landed stamp) — answers the
  coverage-gap question from live data.
- **Crit-proc atrophy DoT** (apply: "...kindles ethereal mist to consign him to only
  memory."; tick: "Time wreaks ruin upon <t>, deteriorating before your eyes.") —
  trigger `highlighting/029`, bold dark_orange on both. Source unconfirmed
  (boon/affix/gear?) — noted on the wishlist.

Files: `highlighting/029-032` (NEW x4), `.claude/classes/dragon.md` (fire-line
ledger). Suite **491/491**.

---

## 2026-07-28 — Psidaze fire line: highlight + confirmed cooldown (v4.7.131)

Live capture (user): "You summon sparkles of psi energy around a sturdy troll woman,
causing her to forget her actions as the sparkles distract her." — the Golden Dragon
PSIDAZE fire line, first of the four on the wishlist.

- New trigger `highlighting/028_Psidaze_Lands` (pronoun-tolerant pattern): highlights
  the line bold gold, then calls `ataxiaBasher_gdragonConfirm("psidaze")`.
- `ataxiaBasher_gdragonConfirm(key)` (basher/002, the Monk-ripplestrike direction):
  restamps the cooldown from the LANDED moment (send stamps are pick-time — the
  queued cast can fire seconds later) and releases the in-flight pick hold, so the
  rotation may advance on the next rebuild instead of re-sending a landed cast.
  Deaden/Overwhelm/Psiblast wire in the same way once their lines are captured.

Files: `basher/002_Class_Bashing.lua`, `highlighting/028_Psidaze_Lands.lua` (NEW),
`test_basher_dragon.lua` (+1 case). Suite **491/491**.

---

## 2026-07-27 — Might of Sycaerunax: blast weave stops re-summoning (v4.7.130)

New Mnemosyne boon (the 14th flag, `dragonMightSycaerunax`): "Your draconic blast
ability does 25% more damage, and your breath weapon persists and will not need to be
resummoned upon use." AB Blast (1544): 4.00s of equilibrium, strips shield and/or
lyre, requires summoned breath.

- `ataxiaBasher_dragonBashing` drops the `;summon <ele>` from BOTH the blast weave
  (breath up → `blast <t>;<primary>`) and the shielded reblast (`blast <t>;<bal>`)
  while the boon is up. Breath fully down still summons once — the boon keeps it from
  there. Colour-agnostic.
- Standard boon-flag lifecycle: `BOON CLAIM` intercept (`sycaerunax`), BOONS-row
  re-latch trigger `035_Might_Of_Sycaerunax`, reset on run start, cleared on the
  confirmed run end.

Files: `basher/002_Class_Bashing.lua`, `mnemosyne/004_Parsers.lua`,
`triggers/.../mnemosyne/035_Might_Of_Sycaerunax.lua` (NEW), `001_Run_Start.lua`,
`aliases/.../mnemosyne/002_Boon_Claim.lua`, `test_basher_dragon.lua` (+4 cases).
Suite **490/490**.

---

## 2026-07-27 — Golden Dragon battlerage: aeon/amnesia control rotation (v4.7.129)

User AB dump of the Golden Dragon Attainment kit: DEADEN (24 rage, 35s cd, denizen
**Aeon**), PSIDAZE (28, 41s, denizen **Amnesia**), OVERWHELM (14, 16s, damage),
PSIBLAST (36, 23s, damage). Aeon/amnesia on denizens gut their output — control is the
new priority. The audit also found the old wiring broken the same way as Psion's:
trigger 330 has no Golden Overwhelm fire-line, so `battleRage_Timers.small` never set —
Overwhelm was re-sent into its own 16s cooldown every swing AND the fallback's `elseif`
meant Psiblast could NEVER fire; Deaden/Psidaze were wired nowhere.

- **Golden Dragon owns its battlerage** (`ataxiaBasher_goldenDragonBattlerage`,
  `GDRAGON_BR` — the Psion v4.7.128 pattern): timer-free send-side epoch stamps
  (`ataxiaTemp.gdragonBrAt`) with the AB cooldowns. Priority: rage-conserve → culling
  reap (36+) → **Deaden** → **Psidaze** → Psiblast → Overwhelm.
- **Banking rule** (new vs the Psion shape): a control cast off cooldown but
  unaffordable returns `""` — the damage fillers are skipped so rage banks toward the
  aeon/amnesia cast instead of Overwhelm starving it 14 rage at a time.
- `ataxiaBasher_dragonBashing` routes only Golden to the new rotation; the other five
  colours keep the generic assembler unchanged (incl. Black's dragonfear crowd branch).

Adversarial review confirmed two defects in the send-side stamp pattern (both fixed
here, and the fixes back-ported to the v4.7.128 Psion rotation in the same file):

- **In-flight pick replay** (review HIGH): the basher REBUILDS the attack command every
  prompt/vitals event (0.3s `addclearfull` re-queue loop) while balance is down, and
  each rebuild wiped the previously queued line — stamping a fresh pick per rebuild
  burned the whole rotation phantom-style (controls stamped-then-wiped, only the last
  rebuild's filler fired: priority inversion on exactly the aeon/amnesia casts). A pick
  now stays PENDING (`ataxiaTemp.gdragonBrPending`/`psionBrPending`) for ~one balance
  round and is replayed verbatim (the bloodboil command-stability rule); the rotation
  advances only after the hold expires. Rage-conserve clears the pending so a stale
  cast can't resume on the next mob.
- **Lazy battlerage on shielded rounds** (review MEDIUM): `dragonBashing`'s
  shielded+rageraze branch (and `psionBashing`'s whole shielded branch) computed the
  battlerage eagerly, then discarded it — burning a 35-41s control stamp unsent on
  exactly the shield-break round. Both class functions now compute the battlerage only
  on branches that actually send it.

Files: `basher/002_Class_Bashing.lua`, `test_basher_dragon.lua` (NEW, 10 cases incl.
replay-stability + shielded-no-burn regressions), `test_basher_psion.lua` (+ replay
regression), `.claude/classes/dragon.md` (breath mapping corrected to the
code-confirmed `getDragonBreath` table; battlerage section added). Suite **486/486**.
Live-capture wishlist: the four fire lines (for confirmation-based cooldowns +
denizen-state capture — trigger 331:80's draconic-gaze line is likely Psiblast) and
actual denizen aeon/amnesia durations.

---

## 2026-07-27 — Psion PvE overhaul: rotation, shields, Roth, keepers (v4.7.128)

Implements the wiki audit's tier-one picks, plus a structural fix the review exposed:
triggers 330-332 have NO Psion fire-lines, so `battleRage_Timers` never set for Psion —
Barbedblade and Whirlwind (gated behind "special on cooldown") had NEVER fired; the
rage rotation was Regrowth-only.

- **Psion owns its battlerage** (`ataxiaBasher_psionBattlerage`, the Blademaster/Magi
  pattern; the assembler's dead Psion branch removed, Psion excluded from generic
  culling). Timer-FREE: send-side epoch stamps with the wiki cooldowns. Priority:
  reap (culling, 36) > **Devastate** (36, 23s — the nuke the old table lacked) >
  Whirlwind (25, 23s) > Barbedblade (14, 16s filler). **Regrowth is now opt-in**
  (`ataxiaBasher.psionRegrowth = true`, priority when enabled) for self-healing
  denizen areas — on ordinary mobs its 24 rage bought nothing.
- **Shielded branch fixed** (review): it could build an EMPTY command (no fallback
  without rageraze) or double-break (pulverise + cleave). Now: rageraze + 17 rage →
  `weave pulverise` (rage break) + the damage weave in the SAME round; otherwise
  always `weave cleave`.
- **Roth in the danger ladder**: below 50% HP, `enact roth` (1.30s eq — rides beside
  the balance swing, grants clarity+rupture free) on a 185s send stamp; fires on
  shielded rounds too.
- **Keepers**: `psi transcend` re-upped when its GMCP defence drops (eq rider, 10s
  attempt-hold — the shatter loop previously assumed it was active with nothing
  maintaining it); `weave secondskin` re-woven when it drops (replaces that round's
  swing; skipped while shielded).
- **Defence name map** gains `indomitability` and `clarity` (Emulation defences the
  map predated).

Files: `basher/002_Class_Bashing.lua`, `basher/001_Bashing_Functions.lua`,
`_groups.yaml` (def map), `test_basher_psion.lua` (rewritten, 14 cases),
`test_basher_battlerage.lua`. Suite **475/475**.

---

## 2026-07-27 — Psion attack dispatch fixed: gsub count leaked into tonumber (v4.7.127)

Live failure (error spam on every prompt, NO attacks fired): `Bashing Functions:997:
bad argument #2 to 'tonumber' (base out of range)`. Root cause: `tonumber(
hpperc:gsub("%%",""))` — an unparenthesized `gsub` call as the argument expands to BOTH
its returns, so `tonumber(str, count)` reads the substitution COUNT as a numeric BASE
and throws. The Psion battlerage branch is the first hpperc consumer to run live (the
class only became bashable this week), so the whole attack dispatch died the moment a
Psion engaged.

- Fixed all three instances with truncating parens: the rage-conservation read and the
  Psion branch in `basher/001_Bashing_Functions.lua`, plus a latent copy in the swarm
  module's `S._targetHp` live-GMCP fallback (`mnemosyne/009`).
- Regression tests feed live-shaped `"66%"` strings through the Psion battlerage branch,
  rage conservation, and the swarm fallback; `string.title` added to the test mock.

Files: `basher/001_Bashing_Functions.lua`, `mnemosyne/009_Swarm_Tactics.lua`,
`test_basher_battlerage.lua` (+2), `test_swarm_tactics.lua` (+1), `mock_mudlet.lua`.
Suite **464/464**.

---

## 2026-07-27 — Panoply: Psion bashes with WEAVE FLURRY (v4.7.126)

New Mnemosyne boon (user-directed): "The damage dealt by your weaving flurry ability
scales directly to the number of strikes landed, randomly dealing 60% to 200% of its
damage with each attack." AB Flurry (ID 2704): `WEAVE FLURRY <target>`, works on
denizens, 2.60s of balance.

- **`ataxiaBasher_psionBashing`**: with `psionPanoply` up, the damage weave swaps
  `weave deathblow` → `weave flurry` (straight verb swap, the `bmShatteredStar`
  pattern). `weave cleave` keeps the shield-break role and `psi shatter` keeps its
  transcendence-100 slot.
- **Standard boon lifecycle** (13th flag): claim intercept, BOONS row trigger
  `034_Panoply`, run start/end resets.

Files: `basher/002_Class_Bashing.lua`, `aliases/.../002_Boon_Claim.lua`, trigger
`034_Panoply.lua` (new), `001_Run_Start.lua`, `004_Parsers.lua`,
`test_basher_psion.lua` (new, 4 cases). Suite **461/461**.

---

## 2026-07-27 — Landing blindness: touch down settling, not deciding (v4.7.125)

**First full live run of the escape ladder** (Blazing rocky mountainside, both arms
broken + throat lacerated in one round, shard-storm AoE ~3k): HP hit 19% → the vitals
watchdog flew instantly → hover healed 19%→99% through the smoke → landed → resumed.
One flaw surfaced at the very end:

- **Landing blindness**: while airborne, gmcp `Char.Items` reflects the SKY, so
  `denizensHere` is empty. The landing tick handed control straight back to the
  explorer, which read the still-mob-filled ground room as "room clear" and queued a
  move — walking OUT of the fight the moment we touched down. The landing now
  CONSUMES its tick, opens the arrival settle window, and lets the land's own
  Room/Items re-push drive the next decision on real ground data (scheduled backstop
  tick, so it can never wedge).

Knowledge captured: the **Blazing** affix burns grounded entries (~725 fire) AND smokes
hovering flyers (~511 asphyxiation per ~5s — the hover still out-heals it); "a
miniature storm of shards" is a room-hazard denizen hitting ~3k unblockable AoE and
counts toward the swarm threshold.

Files: `mnemosyne/009_Swarm_Tactics.lua`, `test_swarm_tactics.lua` (2 tests updated).
Suite **457/457**.

---

## 2026-07-27 — Senseless Flurry: keep NUMB up in Rain form (v4.7.124)

New Mnemosyne boon (user-directed): "Your balance recovers 30% faster while you have
the numbness defence." AB Numbness (ID 894): NUMB, self-only, 3.00s of equilibrium —
the same idle-during-combos eq channel Kai Choke rides — and it defers incoming damage
(delivered later in one blow at −40%, strictly good while bashing; the swarm module's
per-prompt vitals watchdog already covers the deferred hit landing).

- **`ataxiaBasher_senselessFlurryNumb`** (basher/002): with the boon up, in Rain form,
  when the GMCP-tracked `numbness` defence is down, prepend `numb;` to the combo —
  gated by the Bladed-Reflexes-style 5s attempt-hold so the channel isn't respammed.
  Fires on shielded rounds too (self-targeted). Fire line live-captured: "You grit
  your teeth and will your pain out of existence."
- **One eq spender per round**: Kai Unleashed's 30s AoE burst outranks the numb
  refresh when both are eligible; numb fills the other Rain rounds.
- **Crowd-gated** (adversarial-review HIGH): while numb is up HP does not move —
  damage is DEFERRED — so every HP-based safety (damage-rate watchdog, danger levels,
  the swarm escape ladder) goes blind, and in a deep-ripple crowd the −40% lump can
  exceed max HP: death from "full HP" with every alarm silent. The keeper therefore
  never numbs at >= the swarm threshold or while a swarm tactic is running — numbness
  is for THIN rooms, where the lump is survivable and the next prompt's hp-delta
  trips the rate-shield normally.
- **Standard boon lifecycle** (12th flag): claim intercept, BOONS row trigger
  `033_Senseless_Flurry`, run start/end resets.

Files: `basher/002_Class_Bashing.lua`, `aliases/.../002_Boon_Claim.lua`, trigger
`033_Senseless_Flurry.lua` (new), `001_Run_Start.lua`, `004_Parsers.lua`,
`test_basher_monk.lua` (+5 cases). Suite **455/455**.

---

## 2026-07-27 — Seasone boss: tree reserved for the phial truelock (v4.7.123)

Live log: the Mnemosyne boss **Seasone the Industrious** throws "a handful of fragile
glass phials ... in a venom-filled explosion of kalmia, gecko, slike and more" — a
denizen-dealt TRUELOCK (prompt showed IMP SLI AST ANO, locks soft+hard) — and the tree
tattoo was on cooldown from routine curing when it landed. User doctrine: "save tree
until this happens when fighting this boss."

- **Tree reserve** (`reserveTreeForBoss`, `TREE_RESERVE_BOSSES = { seasone }`): when the
  boss objective names a reserve-boss, `curing tree off` — SSC can't burn the tattoo on
  incidental afflictions while closing on her. Telemetry-independent (fires from the
  `Objective:` line BEFORE onObjective's `_inRun` gate), inMnemosyne-gated,
  transition-guarded.
- **Release on the burst** (trigger `032_Seasone_Phials`): the phial line flips
  `curing tree on` — SSC spends the tattoo on the lock immediately, exactly when it
  matters. Reserve also releases on ripple change and the confirmed run end, so it can
  never outlive the fight; a Splinterbark-tainted tree is never re-enabled.

Boss knowledge captured: Seasone also strips the protective covering (sileris) before
the venoms land, and her bee-swarm hum hit 2,866 poison.

Files: `mnemosyne/004_Parsers.lua`, trigger `032_Seasone_Phials.lua` (new),
`test_mnemosyne.lua` (+5 cases). Suite **450/450**.

---

## 2026-07-27 — Kai Unleashed corrected per AB + live capture (v4.7.122)

The AB Kaichoke file (ID 896) and a live burst capture corrected two v4.7.121 assumptions:

- **The choke rides EQUILIBRIUM (4s), not balance** — eq is idle while Shikudo combos
  spend balance, so the choke now PREPENDS to the round's combo instead of replacing it:
  burst and swing land in the same round, zero combo cost.
- **Against a denizen the choke requires and consumes NO kai** — the kai gate
  (`kaiChokeCost`) is gone; the only resource is 50 mana, guarded by a 250-mana floor.
- **Confirmation-based cooldown** (live capture: "Your surroundings ripple like a lake's
  surface struck as a transparent wave of kai energy surges outwards from <mob>, wracking
  mind and body." — 8,472 magical AoE; choke itself hit 3,338 asphyxiation): the 30s
  burst cooldown now starts from that line (new trigger `031_Kai_Burst` →
  `ataxiaBasher_kaiUnleashedBurst`, self-proving so it also sets the flag), not from the
  send — an eaten/wiped choke retries after a 6s guard instead of silently forfeiting
  the window. Both stamps cleared on the confirmed run end.

Files: `basher/002_Class_Bashing.lua`, trigger `031_Kai_Burst.lua` (new),
`mnemosyne/004_Parsers.lua`, `test_basher_monk.lua` (retry + confirm cases).
Suite **445/445**.

---

## 2026-07-27 — Kai Unleashed: Shikudo Rain-form AoE choke (v4.7.121)

New Mnemosyne boon (user-directed): "Kai choking a denizen deals a burst of magic
damage to all denizens in its location, including itself. This effect has a 30 seconds
cooldown before it can trigger again."

- **`ataxiaBasher_kaiUnleashedChoke`** (basher/002): with `mnemKaiUnleashed` up, the
  Shikudo basher fires `KAI CHOKE <target>` as the round's attack — replacing the combo —
  when ALL gates pass: **Rain form** (the Willow→Rain→Oak rotation re-visits Rain every
  cycle, so no form-forcing), **2+ denizens** in the room (the burst hits them all — the
  user-specified priority), **kai in hand** (`vitals.class` >= `ataxiaBasher.kaiChokeCost`,
  default 20 — a kai-dry round falls back to the combo WITHOUT spending the window), and
  the **30s cooldown** elapsed (`ataxiaTemp.kaiUnleashedAt`, stamped at send, survives a
  SYSUPDATE reload, cleared on run end). A shielded target's shatter round wins over the
  choke.
- **Standard boon lifecycle**: claim intercept ("kai unleashed"), BOONS row trigger
  `030_Kai_Unleashed`, run start/end resets with the other ten flags.

Files: `basher/002_Class_Bashing.lua`, `aliases/.../002_Boon_Claim.lua`, trigger
`030_Kai_Unleashed.lua` (new), `001_Run_Start.lua`, `004_Parsers.lua`,
`test_basher_monk.lua` (+5 cases). Suite **444/444**.

---

## 2026-07-26 — Haemophiliac hold gates on BLEEDING, not just HP (v4.7.120)

User refinement: the massive post-kill bleed must be CLOTTED before moving on — waiting
on HP alone released the hold at 90% HP with hundreds of bleed still ticking (SSC's
`curing clotat 30` clots it down at the affix's +20% mana cost; our job is to stand
still while it works). `M._haemoHold` now holds while `ataxia.vitals.bleed >= 50`
(live per prompt from gmcp charstats) OR `hpp < 90`; a missing bleed reading counts as
0 so the hold can never wedge. The wait echo now shows the bleed value. Suite
**439/439** (bleed-gate cases added).

---

## 2026-07-26 — Icewall stays up + wall-leap navigation + Bloodscent recon (v4.7.119)

User-directed: "We dont need to take down the icewall, all we have to do is LEAP out of
the room and into the room. Icewall can stay." + "when doing mnem explore and walking
around, if there is an icewall you should LEAP it." Chitin-greaves LEAP clears walls in
BOTH directions, so melting on every re-entry was wasted rounds — and a leap answers any
wall the tower puts up.

- **Re-entry leaps the standing wall**: a single eq-gated `stand;leap <fwd>` replaces
  melt (balance) + walk. The wall keeps pacing the swarm between cycles (a real barrier
  with Maklak's Promise).
- **Leap-only follow-up escapes**: `S.wallRaised[room]` remembers our standing wall (and
  WHICH edge); while set, the escape suffix drops the `point` and goes straight to
  `leap <back>` — the escape fires a full balance-round sooner. A broken/expired wall
  degrades to a plain unwalled pull (mobs walk through walls anyway without the boon).
- **Wall-leap navigation reflex** (`M.onWallBlocked`, trigger `025_Wall_Blocked` on
  "A wall blocks your way." / "A wall bars your path." — the long-sought walk-into-wall
  lines, live-captured): ANY wall that rejects an explorer walk — ours, an affix's, a
  denizen's — gets leapt instead of condemned; shares the ice-slip budget. The legacy
  `766_Wall` manual-walk branches are gated off during explore (they leapt the raw
  `command` string and their `addclearfull` wiped the explorer's own queue).
- **Adversarial-review fixes** (4-agent verify on the wall-stays diff, 6 confirmed):
  - CRITICAL: the low-HP indoor retreat walked a plain move into our own standing wall —
    livelocking the anti-death ladder at crash HP. ALL tactical moves now LEAP
    (`_tacticalGo` sends `stand;leap <dir>`), and the panic tumble avoids the walled edge.
  - HIGH: the end-of-room melt was cleared optimistically at send and could be wiped
    (FAST_TICK preemption / slow balance / a roamer's `addclearfull`) leaving a standing
    wall with no memory. Now: hold-armed for the melt window, cleared only on the melt
    CONFIRMATION line (trigger `026_Wall_Melted`), re-sent while unconfirmed, bounded at
    4 tries (then the leap reflex owns it).
  - MEDIUMs: wall memory survives `mnem explore off/on` mid-ripple (wiped only on a
    genuine ripple change); reset() preserving wall memory and melt-only-from-the-walled-
    room are now pinned by tests.
- **Bloodscent recon parser** (new boon, live-captured): "You sense out your prey upon
  entering a ripple." prints one `You sense <mob> (#id) at <room>.` row per denizen —
  THE parsed recon format the Sleuth raw capture was waiting for. Trigger `028_Sense_Lines`
  batches the rows into `swarm.recon` ({name,id,room} + per-room counts) and echoes a
  summary with crowded-room callouts (`>= threshold`). Flag `mnemBloodscent`, standard
  boon lifecycle (claim intercept, BOONS row `027_Bloodscent`, run start/end resets).
- **Haemophiliac wade-slower pacing** (user-reported: the affix — "Defeating a denizen
  causes you to bleed significantly and your mana costs are increased by 20%." — bleeds
  THOUSANDS after every kill): new status-row trigger `029_Haemophiliac` arms
  `mnemHaemophiliac` (Splinterbark's telemetry-independent shape: inMnemosyne-gated,
  transition-guarded, cleared on run start/confirmed end). While set, the explorer holds
  post-clear navigation until HP is back above 90% (`M._haemoHold`, 1.5s re-checks) —
  the bleed settles before the next room's fight starts. Combat itself is untouched.
- **Encoding cleanup** (user-reported "â€"" mojibake on the Splinterbark echo): all
  typographic characters (em-dashes, arrows, ellipses, curly quotes) swept out of
  string-bearing lines across the shipped source — 140 replacements in 37 files. Echoes
  are now pure ASCII; decorative box-drawing UI borders left as-is.

Files: `mnemosyne/009_Swarm_Tactics.lua`, `008_Explorer.lua`, triggers 025-028 (new),
`766_Wall.lua`, `test_swarm_tactics.lua` (13 new/updated cases). Suite **436/436**.

---

## 2026-07-26 — Reaper boon kill counter: running "+N% damage total" (v4.7.118)

The Reaper boon (legendary: "Each kill on a denizen permanently increases your damage
dealt by 1%.") announces every kill with "You reap a tithe of power from your fallen
foe." — but the game never shows the running total. User request: additive tracking,
"You now have X increased damage total."

- **Tithe counter** (`M.onReaperTithe`, trigger `023_Reaper_Tithe`): every tithe line
  increments `ataxiaTemp.reaperKills` (ataxiaTemp survives a SYSUPDATE reload, so a
  mid-run update keeps the tally) and echoes
  `(MNEM): Reaper: you now have +N% damage total (N kills this run).`
  The tithe line only prints with the boon up, so it is its own proof — seeing it also
  sets `mnemReaper`, and a missed claim/BOONS row can't desync the count.
- **Standard boon-flag lifecycle**: `mnemReaper` set by the `BOON CLAIM` intercept
  (frontier `%f[%a]reaper` so a hypothetical "Soulreaper" can't false-match) and the
  BOONS-list row trigger (`024_Reaper`); flag AND tally reset on run start
  (`001_Run_Start`) and the confirmed run-end (`onRunEnd`) with the other eight flags.
- **Pause/resume keeps the tally** (adversarial-review catch): the run-start trigger
  also fires on the resume-after-pause wade (`WADE STILL` → wade back in), which
  re-enters the SAME server-side run — an unconditional reset there would silently
  understate the total forever (the game never prints it, so the count is
  unrecoverable). `M.reaperOnWade()` runs BEFORE `onRunStart()` (which consumes
  `run.paused` on a resume) and only resets the tally on a genuinely fresh wade.
- Trigger catalog (`03-parsing-triggers.md`) updated with rows 022-024 (022 was a
  pre-existing gap from v4.7.116).

Files: `mnemosyne/004_Parsers.lua`, triggers `023_Reaper_Tithe.lua` + `024_Reaper.lua`
(new), `aliases/.../002_Boon_Claim.lua`, `triggers/.../001_Run_Start.lua`,
`test_mnemosyne.lua` (+5 cases). Suite **427/427**.

---

## 2026-07-26 — Hit-and-run continues while it works (v4.7.117)

Live Putoran-wildcat log (Mnemosyne themed ripple): the pull & funnel loop ran perfectly —
three clean pulls, safe funnels — but **nothing followed** (wildcats don't chase; "peak
followers: 0" every cycle), so each cycle was one free swing that chipped the focused
soldier 94%→83%→78%→71% and killed one. Then the fixed 3-pull budget expired and the
system parked in a 5-mob room; HP yo-yoed 30-50% on potash until the user manually bailed
(bash off + ring fly). User doctrine: "continue hit and run until the room is cleared or
below 3 denizens."

- **Progress refunds the pull budget**: each pull snapshots the room's denizen count and
  the focused target's hp% (`S.entrySnap`, same data chain as the HUD mob bar:
  denizen-state `hpp` / `IRE.Target.Info.hpperc`). On the next assess of that room, a
  DROP in either — a kill, or the same target chipped lower — resets the budget to 0 and
  echoes "hit-and-run continues". Only unproductive cycles (nothing died, no chip — e.g.
  a soldier "tending his wounds" back to full while we funnel) spend budget, so a true
  regen stalemate still caps at MAX_PULLS and fights in place (where the v4.7.116 escape
  ladder is the backstop).

Knowledge captured: wildcat servants/soldiers do not pursue through exits; denizens
regen while you funnel ("A wildcat soldier ceases tending to his wounds"); flying renames
the GMCP room to "Flying above <room>" (the prompt trigger's "YOU ARE FLYING" echo keys
on it). The mid-crisis "Bashing systems disengaged" in the log was the user's own manual
toggle (`ataxiaBasher_manual()`), not a system action — on v4.7.115 the tick-starved
escape couldn't fire; v4.7.116's vitals-driven escape would have flown at 32% unprompted.

Files: `mnemosyne/009_Swarm_Tactics.lua` (`_targetHp`, `entrySnap`, refund in the assess),
`test_swarm_tactics.lua` (+3 cases). Suite **422/422**.

---

## 2026-07-26 — Emergency escape hardening after the Pinnacle death (v4.7.116)

A live death at the Pinnacle (3 angelic razers + a roamed-in inquisitor angel, ~3,000 HP/s
incoming at peak) exposed three stacked failures — the razers' psychic attack applies
STUPIDITY, which randomly replaces queued commands with involuntary actions ("You pull down
your pants and moon the world"), and that single mechanic defeated the pull, the reassess,
and (indirectly) the escape:

- **Vitals-driven emergency wake-up** (`swarm.onVitals` on `gmcp.Char.Vitals`): the
  panic/escape gates were only evaluated on explorer ticks, which are event-driven
  (arrivals, target changes, 30s watchdog) — a stationary slugfest generates almost none.
  HP crossed the 35% escape threshold ~3s before death and the single evaluation in that
  window landed on a potash heal bounce above the trigger. The gates now run on EVERY
  prompt: HP read fresh from the gmcp payload (the shared vitals table can be one prompt
  stale — same event, registration order), `hp <= 0` treated as blackout-unknown, 2s
  cooldown, and the handler acts even while a pull chain is in flight (the explorer
  `moving` guard blinded the tick path for the pull's full 8s) — `M._disarmMove()`
  releases the move machinery with no condemn callback, the escape's reset kills the
  doomed chain. Recovery hovers also self-tick from birth now (previously the first
  post-escape evaluation waited on an outside event too).
- **Pull retry after a lost move**: `_tacticalArm` overwrites `explore.fromRoom/fromDir`
  with the pull itself, so when stupidity ate the step-out, the reassess found "no valid
  pull route" and permanently latched `noTactics` on the room — with a known-good route
  still saved and 2 of 3 pulls unspent. `onMoveFailed` now restores the anchor from the
  tactic's own saved route (adjacency re-validated by `_backDir`; only when still in the
  swarm room) so the reassess re-pulls; MAX_PULLS still bounds it.
- **Flight confirmation** (new trigger `022_Flight_Lines`): the escape's own `fly` can be
  eaten the same way, and `S.flying` was optimistic — grounded-but-gated (attacks held
  while standing in the crowd) is the worst of both worlds. `S.flightConfirmed` now tracks
  the confirmed physical state via the ring-of-flying up-line / land line, and the
  recovery hover re-sends the fly each 2s tick until confirmed (harmless "You are already
  flying." for unknown fly sources).

Knowledge captured: angelic razer psychic = stupidity applicator (~1,000–1,250/hit),
wing-charge = prone; inquisitor angel = ~1,000 bleed rounds + 1,993 fire sweep; mobs roam
in mid-fight. Shin augment: default-3 spend lasted ~2.0s under that fire with a ~6s
re-augment cooldown ("...so soon would be fatal.") — working theory: augment is ABLATIVE
(absorbs damage ∝ shin spent), see `.claude/classes/blademaster.md`.

Files: `mnemosyne/009_Swarm_Tactics.lua` (onVitals, _convertToHover, pull-retry restore,
flight confirm, hover self-tick), `mnemosyne/008_Explorer.lua` (`M._disarmMove`),
`triggers/.../mnemosyne/022_Flight_Lines.lua` (new), `test_swarm_tactics.lua` (+9 cases).
Suite **419/419**.

---

## 2026-07-26 — Documentation sweep for swarm tactics v4.7.111-115 (docs only, no release)

Full knowledge-base sync for the swarm-tactics arc — no code changes, no version bump:

- **README.md**: Swarm Tactics feature row, new "Swarm Tactics & Low-HP Escape (`mnem swarm`)"
  deep-dive section (pull/funnel, icewall walk-through caveat, fly-kite, Roll Hide panic,
  low-HP escape ladder, Sleuth recon), and command-reference rows for the full `mnem swarm`
  / `mnem sense` surface.
- **CLAUDE.md**: swarm paragraph updated to v4.7.111-115 — 8s hold gating BOTH attack entry
  points, hold-protected panic tumble, low-HP escape ladder with the 95%-AND-aff-free landing
  rule, and the live-validated icewall facts (chain drains across bal+eq ~7s; denizens walk
  through walls without Maklak's Promise). Boon line: `SHIN AUGMENT <n>` default 3.
- **Project docs**: 07-explorer.md (recoverAt 95% + aff-free), 05-commands.md (all swarm
  branches LIVE + panicat/escapeat/recoverat rows), basher/05-safety-systems.md (low-HP
  escape supersedes shield-in-place; SLC both-arms flee inert in the tower).
- **Class docs**: blademaster.md augment comment — spend 3 default, 12ms dissipate finding.

---

## 2026-07-26 — Recovery = FULLY healed; icewall live-validated; augment spend fix (v4.7.115)

- **Recovery hover lands only when FULLY healed** (user spec): `recoverAt` HP (default now
  **95%**, migrated from 75) AND affliction-free — broken limbs are afflictions, so
  restoration cycles finish before we drop back in. Kept defences (blindness/deafness/
  curseward/insomnia) never hold the hover.
- **Icewall tactic validated end-to-end in live play** (3-troll room, zero deaths): wall →
  leap → funnel → melt → re-enter → sweep resumed. Knowledge captured: leap line ("You
  bunch your powerful muscles and launch yourself in a majestic leap <dir>wards."), melt
  line ("You send a lash of fire to strike the icewall... it quickly melts."). The chain is
  NOT atomic — `point` waits for the next balance and `leap` for equilibrium (~7s total
  escape; the 8s hold covered it — the review fix that raised it from 5s was load-bearing).
  **Without Maklak's Promise, denizens WALK THROUGH icewalls** (all three followed): the
  wall is pacing, not a barrier, unless the boon is up. Eq-bounced re-entry walks self-heal
  via the queue.
- **Bladed Reflexes augment spend fix**: live log showed `shin augment 1` channeling and
  DISSIPATING 12ms later (twice) — one shin buys ~zero duration, the 20% DR was never up.
  Default spend is now **3** (`ataxiaBasher.bmAugmentAmount` to tune); the keeper waits
  until it holds that much shin.

Suite **410/410**, dmap **33/33**.

---

## 2026-07-26 — Low-HP escape ladder: fly/retreat instead of shield-in-place (v4.7.114)

Driven by a live death (earth wyrm + wandered-in lithic cave bat): at low HP the no-flee
answer — shield and keep swinging — FAILED because both arms were broken (`touch shield`
needs an arm), and the chip-down happened in OUTDOOR rooms where flight was available the
whole time. Two mobs only, below the swarm threshold, so the new trigger is HP-alone.

- **`swarm.escape`** (default on, `escapeAt` 35%): outdoors → `fly` and HOVER — untouchable
  while curing, works with every limb broken; attacks are hold-gated for the duration
  (state `recovering`, re-checked every 2s); land + resume at `recoverAt` (75%) or the 60s
  hard cap. Already-airborne (kiting) converts in place — no land/fly churn. Indoors →
  retreat to the previous cleared room (validated route, no swing — at low HP the point is
  OUT) and cure while fighting the trickle. Indoors with no route → the old shield behavior
  stands. Roll Hide panic keeps top priority when the boon is up.
- Commands: `mnem swarm escape on|off`, `escapeat <hp%>`, `recoverat <hp%>`; status shows
  `escape=true@35%->75%`.
- **SLC both-arms flee is now inert in the Mnemosyne** (004_Defensive_Reactions): it flees a
  FIXED configured direction — blind runs into unexplored tower rooms — and competes with
  the explorer/swarm; the tower escape now belongs to the swarm module.

Tests: 7 new escape cases (HP-alone trigger below threshold count, hover/land cycle, hard
cap, indoors retreat, no-route fallback, kite conversion, config off) + panic-gate test
adjusted to the new ladder. Suite **410/410**, dmap **33/33**.

---

## 2026-07-26 — Swarm: the panic tumble is hold-protected like the pull (v4.7.113)

User-spotted gap: the Roll Hide panic free-queues its tumble, but at panic HP the balance is
down — and the next attack dispatch (sub-second, via gmcp vitals) sends
`queue addclearfull`, wiping the queued tumble before it could fire. The panic now re-arms
`ataxiaTemp.swarmHold` AFTER its teardown (`reset` runs first so its own queue flush can't
land on the tumble), gating every attack path for up to HOLD_TIMEOUT while the escape waits
for balance — a few gated swings while fleeing at panic HP is a feature. For the record, the
other tactics were already safe by construction: pull/wall escapes ARE the attack line
(nothing separate to overwrite, then swarmHold gates until arrival); re-entry/melt/fallback
moves fire from an empty room (no target -> no attack is ever sent); the kite's fly/land
ride inside each attack line so every re-queue replaces itself. Suite 403/403.

---

## 2026-07-26 — Swarm tactics review-2 fixes: panic everywhere + grounded first (v4.7.112)

A second focused deep review over the post-stage-1 diff (stage-2 branches, dmap mirror,
parry upgrades) found one HIGH and several hardening items — all fixed:

- **Panic tumbled while flying** (HIGH): TUMBLE is a ground action; mid-kite the panic was
  rejected in the air, its 10s cooldown burned, and reset landed us into the swarm at <=40%
  HP with no retry. `_maybePanic` now LANDS first, and the tumble is free-queued
  (`queue addclear free stand;tumble <dir>`) instead of raw — at panic HP the balance is
  usually spent and a raw send would bounce.
- **Panic now covers every crowded state**, not just the funnel: it runs at the top of the
  swarm tick, so the fight-in-place fallback (no-route / MAX_PULLS rooms — where the HP
  floor is actually hit) and mid-kite are protected. New `mnem swarm panicat <hp%>`.
- **Pull hold honors its 8s**: `M._tacticalArm` takes a timeout; the pull arms it with
  HOLD_TIMEOUT so the 5s move-timeout can no longer clear the hold while the chain is
  still legitimately queued on a slow balance round (the documented invariant was false).
- **Kite wrap room guard**: `land;<attack>;fly` only wraps while actually in the funnel
  room (same guard the pull decorator already had).
- **Malformed parry entries can't error the prompt path**: a `denizenPatterns` entry with
  neither `fixed` nor `cycle` now predicts nil instead of indexing nil.
- dmap: nil-guard on the re-entry route; `mnem swarm` help lists `panic`/`panicat`.

Suites: LEVI **403/403** (panic-while-flying ordering, fight-in-place coverage, kite room
guard, free-queued tumble, malformed-entry cases), dmap **33/33**.

---

## 2026-07-25 — Mnemosyne swarm tactics: pull & funnel, icewall+leap, fly-kite, panic (v4.7.111)

Deep ripples pack 3-4+ ROAMING denizens per room; standing in the swarm broke arms faster
than curing (live logs). New `mnemosyne/009_Swarm_Tactics.lua` (`ataxia.mnemosyne.swarm`,
`mnem swarm`), designed from a 3-agent code survey + adversarial review + the user's manual
hit-and-run logs:

- **Assess** on every settled arrival (explorer tick delegates to `swarm.onTick()`; a
  consumed tick blocks navigation — without that gate the sweep walked off mid-funnel).
  Threshold `mnem swarm assess <n>` (default 3), depth-scaled via `mnem swarm deep <r> <n>`.
  Back-route VALIDATED (planar + adjacency vs the reported-exit graph) — never "up" into the
  holding room, never a stale fromDir; no route → fight in place.
- **Pull**: one-shot decorator in `ataxiaBasher_assembleAttack` turns the next attack into
  `"<attack>;<backdir>"` — swing + step-out as ONE queued line (atomic on balance; the
  user's manual `ragepull` alias shape). Consumption arms `ataxiaTemp.swarmHold` (new gate in
  `ataxiaBasher_tryAttack` so the next dispatch's `queue addclearfull` can't wipe the chain;
  5s self-clear + load-time reload-safety clear), clears stale `found_target`, kills
  `mobshieldtimer`. No swing within 2.5s → walk out plain.
- **Funnel**: fight followers on chosen ground (they're already targetable — names learned
  from the swarm room's Items.List; one belt-and-braces `ql`); 4s follow window refreshed by
  combat; empty window → re-enter and re-assess; `MAX_PULLS` 3/room then fight in place.
- **Tactical moves never condemn exits**: `M._tacticalArm` + `explore.tacticalMove` guard
  all three condemn paths (move-timeout, ice-slip cap, `Room.WrongDir`) — walked edges must
  never land in `explore.failed`.
- **Resets**: single `swarm.reset` (queue flush) wired into boon screen, `_exploreStop`
  (death/leave-tower), `basher disabled`, sysLoad; `swarm.onRipple` wipes per-ripple budgets.
- **Sleuth/Roll Hide boons**: `mnemSleuth` (triggers 020 + claim alias) → `fullsense` recon
  on GO, captured raw into `swarm.recon` (`mnem sense` manual; format learned from live
  logs); `mnemRollHide` (021) captured for the stage-2 panic tumble. Standard flag lifecycle.
- **Indoors icewall+leap** (`swarm.icewall`, default on): the escape suffix becomes
  `;point bracers417868 <LONG back>;leap <back>` — swing, wall the door, leap our own wall in
  ONE queue entry (a split send could wall the wrong edge from the wrong room); longer hold
  window behind the wall; re-entry MELTS first (`point bracers151113 at icewall`, harmless
  whiff if the wall already broke) then walks.
- **Outdoors fly-kite** (`swarm.kite`, default on): swarm follows the pull → `fly`; every
  attack becomes `land;<attack>;fly` (ground contact only for the swing); lands below
  threshold. If FLY needs balance the trailing fly is rejected that round — degrades to
  grounded fighting, never wedges. Flight is landed on EVERY reset so it can't leak into a
  boon screen or wade.
- **Roll Hide panic** (`swarm.panic` on, `panicAt` 40%): with the boon, tumble out through a
  non-swarm exit at panic HP — sheds all pursuers — then full reset (10s cooldown).
- **dmap 0.2.0**: the standalone Dementia Mapper gets the pull/funnel core (`dmap swarm
  <n|off>`, default off — no basher, so the funnel waits on the user/attack-hook), with the
  same tactical-move never-condemn guard. dmap suite 33/33.
- **Review hardening** (4-agent deep review + fixes): swarmHold gate moved INTO
  `ataxiaBasher_attack()` (several triggers call it directly — stun-gone, blackout, manual
  key — bypassing tryAttack); decorate verifies we are still in the swarm room; HOLD_TIMEOUT
  8s (slow class balance); `S._enabled` requires manual mode (areabash would mapper-move);
  on-GO fullsense delayed 3s past the wade-status/look burst and gated on the tower
  (capture-slot collision stored the wrong block); boon-claim "roll hide" uses a frontier
  pattern (a "Troll Hide" boon must not false-arm the flag).
- **Pre-req chore**: `genrunning/001_Bashing_API.lua` was a verbatim DOUBLE of itself
  (two headers, every handler registered twice — onDeath/onAttacked fired 2x per event).
  Deduped 484→243 lines + kill-before-register handler registry.

Also in this release — **parry upgrades** (hand-tuned from live logs):
- **Fixed-parry patterns**: `selfLimbDamage.denizenPatterns[name] = { fixed = <limb> }` for
  mobs with exactly ONE parryable attack — park the cover there permanently, no observation
  needed. First entries: a steel-encased Death Knight (left leg), a ravager of the Infernal
  Legion (torso).
- **`ataxia_parrySuccess(limb)`** (003) fed by the new trigger `highlighting/027_Parry_Success`
  (`^You parry the assault to your <limb>...`, both manoeuvre spellings): a PARRIED swing
  prints no perceive line, which blinded focus-follow and the cycle tracker exactly while the
  parry worked — the success line now refreshes focus, counts the swing, and heals
  `ataxia.parrying.limb` desync.
- **`lasthit` freshness stamp** (`lasthitAt`, 002): bashing-parry focus-follow only follows a
  hit ≤12s old (mirrors 005's `STALE_AFTER`), and an un-stamped `lasthit` is never followed —
  a previous mob's focus can no longer pin the parry across kills/rooms.
- **Seed bug fixed**: the Self Limb Tracking group init seeded `lasthit = "left leg"`
  (`_groups.yaml`), which made the ladder's default rung unreachable and silently pinned
  unknown-mob parry to left leg (the only reason the Death Knight log looked right — that
  tactic is now the intentional fixed entry above). Seed is `"none"`; regression test mirrors
  the old timestamp-less seed shape the test stub used to mask.
- **Head default** (user preference): with no pattern and no fresh focus, the ladder now
  covers head → right leg → left leg → torso (was right leg → left → torso) — a head break
  is the worst one to eat.
- Log audit of the other Mnemosyne swamp denizens found NO parryable attacks (hellspawn:
  impale names no limb, flurry unblockable; rotskull demon: all poison-typed; mindless
  thrall: gnaw names no limb) — no entries needed, head default applies; recorded in
  `denizen-lines-catalog.md`.

CI/test hygiene: `test_runner` now SORTS discovered files (Windows `dir` vs CI `find`
returned different orders, so an order-dependent leak passed locally and failed CI);
`test_swarm_tactics` restores the mock `send` it overrides (the leak that broke
`test_example`'s send-capture cases on CI). The dmap release workflow sets
`make_latest: false` — a Dementia Mapper release must never claim `releases/latest`, which
is where SYSUPDATE downloads `Levi_Ataxia.mpackage` from.

Tests: `test_swarm_tactics.lua` (37 cases — threshold/deep scaling, back-route validation,
full state-machine walk incl. wall/kite/panic branches, decorator consumption + hold hygiene
+ room-check, resets, recon, onGo gating) + fixed-parry cases in `test_denizen_parry.lua` + staleness / head-default /
seed-regression / `ataxia_parrySuccess` cases in `test_bashing_parry.lua`.
LEVI suite **399/399**, dmap **33/33**.

---

## 2026-07-24 — SLC: new "bashing" parry mode, auto-engaged with the basher (v4.7.110)

Follow-up to v4.7.109: the denizen-pattern prediction is now the top rung of an explicit
**`bashing` parry mode** instead of a global override, and the mode engages itself.

- **`slc parry bashing`** — PvE selection ladder in `ataxia_bashingParry()` (003):
  (1) fixed-cycle denizen → the predicted NEXT swing's limb (005, incl. the cycle opener);
  (2) unknown mob → follow its focus (most recent unbroken hit limb — denizens
  overwhelmingly repeat-hit one limb); (3) nothing observed → unbroken leg (right → left →
  torso; prone gates most class attacks).
- **Auto-switch**: `ataxia_bashingParryOn/Off` on the `basher enabled`/`basher disabled`
  events (same hooks as the armour auto-swap, reload-safe kill-before-register). Enabling
  the basher remembers the current mode and switches to `bashing`; disabling restores it.
  `manual` is never hijacked; a mode picked by hand mid-bash sticks (Off only restores when
  the mode is still `bashing`). Opt out with **`slc bashparry off`** (`cfg.bashingParryAuto`,
  nil counts as ON).
- The PvP modes (stand/defend/auto/anti-2H/anti-Shikudo) no longer carry any PvE logic —
  the v4.7.109 top-of-parryCheck override is gone.

Tests: new `test_bashing_parry.lua` (11 cases — selection ladder incl. broken-limb
fallbacks, switch/restore semantics, manual respect, idempotent enable, mid-bash mode
change, opt-out). Suite **351/351**.

---

## 2026-07-24 — SLC: predictive parry vs fixed-cycle denizens (v4.7.109)

Live logs showed the Mnemosyne **axe-wielding revenant** swings a fixed rotation — right leg
x2 → left leg x2 → torso x2, repeating (each swing lands as TWO "dealt 30.0% damage to your
<limb>" perceive lines). Damage-weighted parry only reacts after damage lands; the new
predictive layer parries the limb the NEXT swing will hit.

New `self_limb_tracking/005_Denizen_Parry_Patterns.lua`:
- `selfLimbDamage.denizenPatterns[name] = { cycle, hitsPer }` — data-driven; the revenant is
  the first entry, more mobs can be added as their cycles are observed.
- `ataxia_denizenParryObserve(limb)` — fed from `ataxia_raiseLimbDamage` (002), attacker
  taken as the basher's `secondTarget` (name-keyed). Dedupes the two same-swing perceive
  lines (1s window) and resets stale streaks (>12s) so a re-engaged same-named respawn
  doesn't inherit the old count (the unit tests caught exactly that bug).
- `ataxia_denizenParryPredict()` — unobserved/stale → the cycle opener (first-hit parry);
  fewer than `hitsPer` swings seen on the current limb → same limb; otherwise the next limb
  in the cycle. Off-pattern jumps resync on the next observed hit.
- Consumed at the top of `ataxia_parryCheck` (003): wins over every parry mode except
  `manual`; the predictor is basher-gated so PvP parry (incl. anti-2H/anti-Shikudo) is
  untouched.

Tests: new `test_denizen_parry.lua` (10 cases — opener, pair-repeat, swing dedupe, full
cycle + wrap, third-swing drift, staleness, off-pattern mob, basher-off, resync). Suite
**340/340**.

---

## 2026-07-24 — Mnemosyne: Bladed Reflexes boon — BM keeps SHIN AUGMENT up (v4.7.108)

The Bladed Reflexes boon grants **20% reduced damage while your reflexes are augmented with
Shin energy** (Shindo AUGMENT). New `bmBladedReflexes` flag (claim alias + BOONS-row trigger
`mnemosyne/019_Bladed_Reflexes.lua`, reset on run start + confirmed run end — 1:1 with
`bmShatteredStar`): while set, `ataxiaBasher_blademasterBashing()` prepends **`shin augment 1`**
to the attack chain when ALL of: shin >= 1 (augment with 0 shin just fails — and infuse fire
competes for the same resource, hence the minimum spend), the **`bodyaugment` defence is down**
(GMCP defence tracking handles expiry — no duration guessing), and a 5s attempt-hold
(`ataxiaTemp.bmAugmentAttempted`) has cleared so the channel wind-up ("You are already
beginning the process...") isn't respammed every swing.

AB knowledge captured in `.claude/classes/blademaster.md`: `SHIN AUGMENT <ALL|amount>`,
start/busy/complete lines, `bodyaugment` defence mapping (deffing keep-map alongside the other
Shindo defs). Tests: 6 bashing-builder cases (incl. the 0-shin gate) + onRunEnd clear,
suite **330/330**.

---

## 2026-07-24 — GMCP: re-assert the IRE.Target module on login/reconnect/reload (v4.7.107)

**The actual root cause of "the Mob bar never showed once."** Live probe: `gmcp.IRE.Target`
was **nil** mid-session — the IRE.Target module was not negotiated, so the server silently
ignored `IRE.Target.Set` (v4.7.106) and never streamed `Info`/`hpperc`. The only
`Core.Supports.Add ["IRE.Target 1"]` lived inside `levilogin()`, which covers just the
original login: Mudlet renegotiates its default module set (no IRE.Target) on every
reconnect, and a SYSUPDATE reload never re-runs login — so any reconnected or mid-updated
session ran with the module off forever, with zero errors (every consumer nil-guards).

Fix in `misc_scripts/030_GMCP_Consumers.lua` (the reload-safe GMCP home):
`ataxiaGmcpConsumers_enableIreTarget()` sends the `Core.Supports.Add` and — when a denizen
target is live — immediately re-sends `IRE.Target.Set` so the stream starts without waiting
for the next retarget. Registered on `gmcp.Char.Name` (fires on login AND reconnect,
kill-before-register) and invoked at file load when already connected (mid-session update).
The levilogin Add stays (harmless). Chain now: module negotiated (030) → server target set
per retarget (002_search_targets, v4.7.106) → `Info.hpperc` streams → prompt `(id|hp%)` +
HUD Mob bar (v4.7.103). Suite 323/323.

---

## 2026-07-24 — Basher: set the server target via GMCP IRE.Target.Set (v4.7.106)

Live test after v4.7.103: the Mob bar still showed `??` and the prompt still showed `(394817)`
with no `|hp%` while actively fighting — the text `settarget` alone was not starting the
`gmcp.IRE.Target.Info` stream. New `ataxiaBasher_setServerTarget(id)` (in
`genrunning/002_search_targets.lua`) sends the text command AND the GMCP protocol set,
`IRE.Target.Set "<id>"` — the documented client→server message the IRE.Target module pairs with
its Info stream (id/short_desc/hpperc, updated per combat round). Used at all three retarget
sites (search_targets, shield-swap, retargetShielded). This was the deferred "IRE.Target.Set
integration" backlog item, now done with live verification pending in-game. Suite 323/323.

---

## 2026-07-24 — Mnemosyne: boon rarity recolour — rare purple, common light goldenrod (v4.7.105)

Display-only tweak to `M.RARITY_COLOUR` (`mnemosyne/007_History.lua`), the single map behind
every boon rarity colour (BOONS-list annotation, `mnem boons`, claim echoes): `rare` cyan →
**purple**, `common` grey → **light_goldenrod**. Both names verified against
`misc_scripts/007_Custom_Colour_Table` (which wholesale-replaces `color_table`). Uncommon/
legendary/mythical unchanged. Suite 323/323.

---

## 2026-07-24 — Mnemosyne: Hammer and Anvil boon — stop razing, attacks bypass shields (v4.7.104)

The Hammer and Anvil boon ("The Smith's raw strength allows your attacks to bypass denizen
shields") makes the basher's entire shield reaction wasted motion. New class-agnostic boon flag
`mnemHammerAnvil`, wired 1:1 with `bmShatteredStar`:

- **Set** by the `BOON CLAIM` intercept (`aliases/.../mnemosyne/002_Boon_Claim.lua`, also clears
  any live `ataxiaBasher.shielded`) and by a new BOONS-list row trigger
  (`triggers/.../mnemosyne/018_Hammer_And_Anvil.lua`) so a resumed/bootstrapped run re-syncs via
  `BOONS`. **Reset** on run start (trigger 001) and the confirmed run end (`004_Parsers.onRunEnd`).
- **Gate**: `336_Mob_Shielded.lua`'s basher branch is skipped entirely while the flag is up — no
  `ataxiaBasher.shielded = true` (which flips every class's raze/blast attack path in
  `002_Class_Bashing`), no shield-swap (`ataxiaBasher_shieldedTarget`), no shield timers. The
  PvP `isTargeted` branch of the trigger is untouched.

Docs: mnemosyne `01-architecture.md` / `03-parsing-triggers.md`, CLAUDE.md, README boon list.
Tests: onRunEnd clear case added, suite **323/323**.

---

## 2026-07-24 — Bashing HUD: Mob bar moved to the bottom + basher settarget fix (v4.7.103)

The Mob health bar (v4.7.97) had never rendered once in live play. Root cause: all three basher
retarget sites (`search_targets`, shield-swap, `ataxiaBasher_retargetShielded` in
`genrunning/002_search_targets.lua`) sent `st <id>` — which is not a game command, only a
personal server-side alias — while the PvP `t` alias pointedly follows its `st` with a real
`settarget` (`016_Targeting_Functions.lua:75`). With no server target set while bashing, the
server never streams `gmcp.IRE.Target.Info` (`hpperc`), so the HUD bar, the prompt's target-hp%
segment (gated on `ataxiaTemp.mobhealth`, set by the gagged "Your target is now" confirmation),
and the rage-conserve mob-hp checks all silently ran without data — no errors, because every
consumer is nil-guarded.

- **All three basher retarget sites now send `settarget <id>`** (quiet). The "Your target is
  now" confirmation stays gagged while bashing, so no new spam.
- **Mob bar anchored at the BOTTOM of the panel** (user request) — after the Denizens list —
  instead of above HP/WP/EP.
- **The bar no longer hides when it has no reading**: with a numeric target it always renders,
  showing a dim `??` row when neither denizen-state `hpp` nor live GMCP has a value (and treating
  `hpperc == "-1"` / negative `hpp` as no-reading, not 0%). An always-`??` bar is now the visible
  symptom of "server target not set / hp not streaming" instead of an invisible absence.

Files: `windows/001_Limb_Counter_Window.lua`, `genrunning/002_search_targets.lua`. Suite 322/322.

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
