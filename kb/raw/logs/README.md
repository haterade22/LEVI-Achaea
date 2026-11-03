# Combat logs

Verbatim text of combat logs, kept as evidence. Never edited after they are filed; what each one
shows is written up in a curated page that cites it.

| File | Fight | Whose log | Curated in |
|---|---|---|---|
| 2026-08-19_leviticus_blademaster-vs-sentinel_loss_Sentinel.txt | Our Blademaster dies to Grulk, a Sentinel, 123 s, by SKULLBASH. Copied unchanged from the user's desktop on 2026-11-01. Millisecond prompts | Ours, before the fight recorder existed | [.claude/classes/sentinel.md](../../../.claude/classes/sentinel.md), [docs/kill-paths.md](../../../docs/kill-paths.md) |
| 2026-10-11_shikudo-vs-runewarden-snb_attacker.txt | A Shikudo monk (staff "a twisted oaken staff") kills Claes, a Runewarden (sword and Shield of Absorption), by DISPATCH, about 86 s | The Shikudo's | [combat/shikudo.md](../../combat/shikudo.md), [combat/runewarden-snb.md](../../combat/runewarden-snb.md) |
| 2026-10-11_runewarden-snb-vs-shikudo_defender.txt | Claes kills Dominius, a Shikudo monk ("a dark ash wood staff"), by impale and DISEMBOWEL, Oniar Estate arena | Claes's (the Runewarden) | the same two pages |
| 2026-10-11_mystor_shikudo-vs-depthswalker_loss_EveP2TVe.txt | Mystor (Shikudo) loses to Belaziel, a Depthswalker: SHADOW DICTATE, about 49 s (Colosseum arena) | Mystor's (the Shikudo); he ran MIND SAPIENCE on the opponent in five of six | [combat/shikudo.md](../../combat/shikudo.md) |
| 2026-10-11_mystor_shikudo-vs-infernal-dwc_win_FceAmb0o.txt | Mystor (Shikudo) beats Agathon, an Infernal with two scimitars (DSL); finished with KAI CHOKE | Mystor's (the Shikudo); he ran MIND SAPIENCE on the opponent in five of six | [combat/shikudo.md](../../combat/shikudo.md) |
| 2026-10-11_mystor_shikudo-vs-apostate_win_LcJC-rJ5.txt | Mystor (Shikudo) beats Agathon as an Apostate (deadeyes, truestare, daegger, loyals) | Mystor's (the Shikudo); he ran MIND SAPIENCE on the opponent in five of six | [combat/shikudo.md](../../combat/shikudo.md) |
| 2026-10-11_mystor_shikudo-vs-infernal-dwc_win_c.iJVmpL.txt | Mystor (Shikudo) beats Agathon, Infernal DSL; finished with MIND SCYTHE | Mystor's (the Shikudo); he ran MIND SAPIENCE on the opponent in five of six | [combat/shikudo.md](../../combat/shikudo.md) |
| 2026-10-11_mystor_shikudo-vs-shaman_loss_t54WWU6b.txt | Mystor (Shikudo) loses to Agathon as a Shaman (curse, jinx, invoke), truelocked; no Sapience in this log | Mystor's (the Shikudo); he ran MIND SAPIENCE on the opponent in five of six | [combat/shikudo.md](../../combat/shikudo.md) |
| 2026-10-11_mystor_shikudo-vs-infernal-dwc_win_vNTjvghY.txt | Mystor (Shikudo) beats Agathon, Infernal DSL; finished with KAI CHOKE | Mystor's (the Shikudo); he ran MIND SAPIENCE on the opponent in five of six | [combat/shikudo.md](../../combat/shikudo.md) |
| 2026-11-03_shikudo-group-alias-2.txt | The same day, 10:21-10:26, the same party, on v4.7.471. We died to two Depthswalkers. It holds `ours/2026-11-03_102138_Tabethys` and about 100 s after it, so `kb_timing.SAME_FIGHT` keeps it out of every count. It holds other players' tells; the user chose to file it | Ours, screen log | [combat/shikudo.md](../../combat/shikudo.md), [docs/kill-paths.md](../../../docs/kill-paths.md) |
| 2026-11-03_shikudo-group-alias.txt | Our first alias-round fight with people attacking: a party led by Tabethys, 07:56-08:22, with no death for us. It holds the three recordings `ours/2026-11-03_080944_Lauryyn`, `081009_Froedine` and `081532_Tabethys`, so `kb_timing.SAME_FIGHT` keeps it out of every count. It holds other players' tells; the user chose to file it | Ours, screen log, with the echoes that a recording leaves out | [mechanics/balance-and-queueing.md](../../mechanics/balance-and-queueing.md), [combat/shikudo.md](../../combat/shikudo.md) |
| 2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt | Tabethys (Magi) leads a group (Agathon, Ryzant, Valkael, Naxx) on the World Tree and kills Kalys, a Serpent, with STORMHAMMER at about 50% health: magma, dehydrate, dehydrate, then two stormhammers | Tabethys's (the Magi) | [.claude/classes/magi.md](../../../.claude/classes/magi.md) ("In play"), `kb/CONFLICTS.md` Resolved 2026-10-19, #37 and #38 |

## How they were made

The user shared both as Mudlet HTML exports ("main console extract", Mudlet 4.19.1) from a public
log site. They were converted to text with one physical line per row: `<br>` to a newline, tags
dropped, entities decoded. Nothing else changed, except that **log 2 drops eight rows of public
channel chat** ((Order) herald, (Cyrene) city, (Market)), which had nothing to do with the fight.

Reading them:
- **Neither log is from this package.** Echo lines such as `Processed Affliction(Weariness)`,
  `[AFF]: ...`, `[Legacy]: Curing against SnB`, `YOU HIT PARRY!!`, `--- THEY TOUCHED TREE ---`
  and the `Envenomed:` / `Sliced:` / `Shield:` blocks are the loggers' own systems, not game text.
- **Log 1:** a trailing `..` after a line's final `.` is the logger's marker (a cyan span in the
  HTML), so `...thigh of Claes...` is the game line `...thigh of Claes.` A trailing ` (16.8%)` on
  a damage line is the logger's running limb total. The server wraps at about 150 columns.
- **Log 2:** the server wraps at 96 columns, so long lines arrive in two rows. The logger's system
  gags Claes's own attack lines and prints the `Envenomed:` / `Sliced:` summary instead.
- **Log 1 deletes one game line we wanted:** dawnkick's delayed epilepsy (an empty row stands
  just before `Processed Affliction(Epilepsy)`, about 2 s after the kick).

### Mystor's six arena logs (shared by the user, 2026-10-11)

**A name collision:** the user saved two DIFFERENT exports as `LcJC-rJ5.html`, Mystor's Apostate fight
(`Downloads/shikudo fights/`, filed here as `..._mystor_shikudo-vs-apostate_win_LcJC-rJ5.txt`) and Claes
vs Pharaus (filed 2026-11-01 as `2026-11-01_claes_runewarden-vs-apostate_loss_LcJC-rJ5.txt`). Cite Mystor's as "Mystor's Apostate log".

Mystor is a Shikudo monk; the user relayed his notes on them (`kb/raw/players/shikudo-2026-10-11.txt`).
Converted the same way (one row per `<br>`); they carried no channel chat, so nothing was removed.
His client runs its own system, which ADDS lines and GAGS (hides) others, printing a summary instead:
- The prompt is two rows: `[B|E] [CDBK] H:<hp> M:<mp> [<x>] [<Form>]:<kata> K:<kai>% [<his afflictions>]`
  then `HH:MM:SS (<n>) [<target>]: <the target's afflictions as his system believes, with %>`.
- `[Zax]: ...` (his afflictions and defences gained and lost, inventory, priority changes, the command
  it sends), `[Curing]: EAT MAGNESIUM` (his curing), `[Bal Spent: 2.1s]` / `[Eq Spent: ...]` /
  `[Eat Recov: ...]` and similar (timings his system measured).
- `You: <Ability> <limb> -> <Target> <Limb>: <pct>%` REPLACES his own attack line (gagged);
  `<Opponent>: <Ability> <limb> -> You` replaces the opponent's; `My <Limb>: <pct>%` is his own limb
  model. ` Kata is N` is appended to game lines, and `[<Form>]: ` prefixed to the kata-chain line.
- `--> <Opponent>: <command>` is what MIND SAPIENCE shows: the OPPONENT's own typed commands. It is the
  most valuable thing in these logs.
- `[<Name>] HP: [====] (<hp>|<max>) (<pct>%)` replaces the game's ASSESS line.

### Tabethys's Magi log (shared by the user, 2026-10-19)

The user shared four Mudlet 4.11.2 HTML exports "from Magi". Only `o6UKnyyy` is a Magi fight, and it is
the one filed here, converted the same way (one row per `<br>`), nothing removed. The other three are
the same player on Apostate (corpse notes "This is the end of those who would trifle with Tabethys",
the same pipe 577156) and are not filed: `mWeyVmzu` (a Magi sparring dummy against a Depthswalker,
then Apostate against Kalys, a Serpent), `dQOamabI` and `Fw51FO2M` (Apostate against Kalys, killed by
vivisect). Their system's echoes, as it prints them (not game text):
- `You: <Spell> -> <Target>` in place of the cast line; `<Plane>: <Stage> -> <Target>` in place of the
  game's resonance lines, which it GAGS (`Earth: Brokenrightarm`, `Fire: Scalded > Burning`,
  `Fire: Blistered`, `Water: Frostbite`, `Water: Stuttering`). So this log does not show our
  `general/022_Resonance_Afflictions` patterns. It does show two game lines it leaves alone: the
  temperance strip and `You fan the heat of <T>'s body into consuming flame.`
- `(||||||||----) 8207 82%` replaces the ASSESS line; `[par 1.00 wea 0.67 ...]` is its target tracker
  (three letters, the chance), sometimes with a trailing hot-springs character whose meaning is not known (it is missing on some lines with `bur 1.00`, e.g. :415-416).
- `=f PVP` / `+f PVP` and `Alias "stmpvp" will now execute: ...` are its queue and alias echoes.
- Apostate logs only (NOT filed, so not checkable here; the user's Downloads, 2026-10-19):
  `[DEYES]: <aff>+ <aff>+`, and a stage word after the tracker, `softpress`, `hardpress`, `lock`.
  v4.7.429 copied the cast and resonance echoes and the idea of a stage word into ours.
- **Two facts from this log that changed our code:** a body mending prints the application line
  AND "The fires consuming <T> diminish somewhat." (:412-413); and both stormhammers that hit went
  at a Kalys shown "here, hidden" (:525, :706), while both misses came after he had left (:482,
  :490, :683).

### The 2026-11-01 batch (shared by the user)

The user added 25 Mudlet HTML exports. `python tools/kb_log_import.py` filed 20 of them as text, and
`--check` matched each one row by row. The other 5 are not new: two are the 2026-10-11 Runewarden logs
(`Pk1qqH9I` is an exact match, `aJnS5zOu` is that log before the channel rows were removed), and three are
copies (`Vr.NkCGD (1)`, `Vr.NkCGD (2)`, `s98kPGv6 (1)`). The exports stay on disk and are git-ignored.

New files use LF line ends. The older files here use CRLF. Their rows are the same otherwise: the
converter reproduces all 2,733 rows of `2026-10-11_shikudo-vs-runewarden-snb_attacker.txt`.

| Id | Logger, class | Opponent, class | Result | Stamps | Notes |
|---|---|---|---|---|---|
| WO7tC3kL | Claes, Runewarden | Proficy, Apostate | win | ms | 1v1 hunt at Oniar, 403 s; impale, disembowel |
| azbErKcK | Claes, Runewarden | Thato, Serpent | loss | ms | truelock, then vomit "suffocating" with recklessness hiding health |
| 4c_SeyaA | Claes, Runewarden | Reyl, Pariah | loss | ms | SCOURGE |
| CxxKSMq | Claes, Runewarden | Blonk, Runewarden (two handed) | loss | ms | sweep, impale, 2700 unblockable |
| s98kPGv6 | Claes, Runewarden | Talo, Air Lord | loss | ms | pressure counter, clap at 6 |
| WKuEakBZ | Claes, Runewarden | Talo, Pariah | loss | ms | Latency, voyria |
| Vr.NkCGD | Claes, Runewarden | Talo, Pariah | loss | ms | Latency, voyria |
| LcJC-rJ5 | Claes, Runewarden | Pharaus, Apostate | loss | ms | truelock, ankheg trample, VIVISECT |
| J7Xnr_Jg | Claes, Runewarden | Sjeng, Runewarden | win | ms | BISECT |
| X8pRorzR | Nikita, Depthswalker | Archaeon, Serpent | win | cs | truelock, death by symptoms |
| kAQnlFAW | Nikita, Depthswalker | Anzerloi, Bard | win | cs | Degeneration capstone |
| L8LSw7xD | Nikita, Depthswalker | Anzerloi, Bard | win | cs | SHADOW DICTATE |
| 2N1HTSWZ | Elmer, Shikudo | Torvald, Runewarden | win | ms | DISPATCH |
| 3ys7NuHA | Elmer, Shikudo | Astarod, Air Lord | win | ms | DISPATCH |
| g-lD00-h | Elmer, Shikudo | Kalys, Serpent | no result | ms | Kalys left |
| Z5cyffxx | Elmer, Alchemist | Seurimas, Serpent | loss | ms | truelock, scytherus bites |
| KtdftABt | unnamed, Blademaster | Kuririn, Tekura monk | win | 1 s | a staged finisher |
| OwkA-G99 | unnamed, Earth Lord | Alyzar, Blademaster | loss | cs | leg breaks, "Planting his foot" rounds; class from ability lines, no HONOURS line |
| JDvzR7j7 | unnamed, Earth Lord | Vothaec, Sentinel; killed by Arcadian guards | loss | cs | |
| uW_VbgR | unnamed, Earth Lord | Vothaec, Sentinel | no result | cs | truelock, log cut |

All 20 are 1v1 by the party check, although people pass through some of them. Classes come from ability
lines and echoes, so a class here is a reading of the log, not a game record. The Blonk class was first read
as Unnamable; runes flash on the weapons (`CxxKSMq` rows 755, 1198, 1305, 1529). Nine logs share one
player's system and several were played within 30 minutes, so do not treat them as independent samples.

**Prompt stamps differ by family, and a row's time is the NEXT prompt's stamp:**
- Claes: `HH:MM:SS:mmm`. Nikita: `HH:MM:SS.cc`; a `.00` stamp prints one second early.
- Elmer: `SS:mmm`, which wraps at 60. Earth Lord: `MM:SS.cc`. Blademaster: `HH:MM:SS`.
- Treat a margin under 0.5 s as unresolved: lag bursts bundle rows.

**What is game text and what is not:**
- **`Balance used: 2.1s.` and `Equilibrium used: 3.40s.` are GAME text.** They have the same colour as
  `Health lost`, and they print before recovery, which a client cannot know. A victim also prints one for an
  imposed loss (`Balance used: 1.4s.`, `OwkA-G99` row 3141). Mystor's `[Bal Spent: 2.1s]` is this line, renamed.
  Claes's logs show `Equilibrium used` but never `Balance used`. No log of ours has either line.
- **These are loggers' echoes:** `Tree (13.916)` and `(4.38)` after a recovery line, `[INR]: 13 Ginseng (586)`,
  `Processed Cures(...)`, `aff+` / `aff-` (Nikita's tracker), and `AST44 clum44` (Elmer's chance that an
  affliction remains). `[Prio]` rows show the logger's live cure priority.

## Our own fight logs (`ours/`)

Since v4.7.418 the package records our own fights (`fightlog`, `misc_scripts/026_Fight_Log.lua`) to
`<profile>/fightlogs/<date>_<time>_<Opponent>.log`. `python tools/fightlog_import.py` copies them
into `ours/` unchanged and prints a summary of each (opponent, length, how it ended, the afflictions
we got, the commands we sent). Add a log to the table above once it is written up.

Each row is `<HH:MM:SS.mmm> <kind> <text>`, so unlike a client log every row has its time. The kinds:

| Kind | Row |
|---|---|
| `\|` | a game line, as the game sent it, even when the package gags it |
| `P` | a prompt |
| `>` | a command we sent: every one, including those sent without an echo (`send(cmd, false)`) |
| `+aff` / `-aff` | an affliction we gained or lost, from GMCP |
| `+def` / `-def` | a defence we gained or lost, from GMCP |
| `+tar` / `-tar` | an affliction our tracker gave the target or took away (its "tar afflicted" and "target cured aff" events), so what we believed can be checked against the lines |
| `#` | a note: the header (version, opponent, our class, why it started, round delivery) and the stop line (why, rows, seconds) |

Lines the package echoes itself (`(LEVI): ...`) are not recorded, because echoes do not reach triggers.

**Round delivery.** The header ends with `rounds raw` or `rounds alias`, so a control fight can be told from a test
fight. Logs from before that field are `raw`. With `alias` (`aconfig rounds alias`, Monk only),
the `>` rows hold `setalias lvfree a/b/c` when the text changes and `queue addclear free lvfree` for each press. A
`# alias lvfree holds: ...` row after the header gives the text at the start. We expect the game's run line to name the
alias: `Running queued free command: LVFREE` (first seen 2026-11-02).

When it records: on its own when a player attacks us (the class detector's event), or when we send
a queued command naming our target while that target is a player in the room; by hand with
`fightlog on [name]`. It stops 3 s after a kill, our death or an arena verdict, after 60 s with
nothing naming the opponent (automatic recordings only), at 50,000 rows, on disconnect, or with
`fightlog off`.
