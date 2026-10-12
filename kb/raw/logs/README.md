# Combat logs

Verbatim text of combat logs, kept as evidence. Never edited after they are filed; what each one
shows is written up in a curated page that cites it.

| File | Fight | Whose log | Curated in |
|---|---|---|---|
| 2026-10-11_shikudo-vs-runewarden-snb_attacker.txt | A Shikudo monk (staff "a twisted oaken staff") kills Claes, a Runewarden (sword and Shield of Absorption), by DISPATCH, about 86 s | The Shikudo's | [combat/shikudo.md](../../combat/shikudo.md), [combat/runewarden-snb.md](../../combat/runewarden-snb.md) |
| 2026-10-11_runewarden-snb-vs-shikudo_defender.txt | Claes kills Dominius, a Shikudo monk ("a dark ash wood staff"), by impale and DISEMBOWEL, Oniar Estate arena | Claes's (the Runewarden) | the same two pages |
| 2026-10-11_mystor_shikudo-vs-depthswalker_loss_EveP2TVe.txt | Mystor (Shikudo) loses to Belaziel, a Depthswalker: SHADOW DICTATE, about 49 s (Colosseum arena) | Mystor's (the Shikudo); he ran MIND SAPIENCE on the opponent in five of six | [combat/shikudo.md](../../combat/shikudo.md) |
| 2026-10-11_mystor_shikudo-vs-infernal-dwc_win_FceAmb0o.txt | Mystor (Shikudo) beats Agathon, an Infernal with two scimitars (DSL); finished with KAI CHOKE | Mystor's (the Shikudo); he ran MIND SAPIENCE on the opponent in five of six | [combat/shikudo.md](../../combat/shikudo.md) |
| 2026-10-11_mystor_shikudo-vs-apostate_win_LcJC-rJ5.txt | Mystor (Shikudo) beats Agathon as an Apostate (deadeyes, truestare, daegger, loyals) | Mystor's (the Shikudo); he ran MIND SAPIENCE on the opponent in five of six | [combat/shikudo.md](../../combat/shikudo.md) |
| 2026-10-11_mystor_shikudo-vs-infernal-dwc_win_c.iJVmpL.txt | Mystor (Shikudo) beats Agathon, Infernal DSL; finished with MIND SCYTHE | Mystor's (the Shikudo); he ran MIND SAPIENCE on the opponent in five of six | [combat/shikudo.md](../../combat/shikudo.md) |
| 2026-10-11_mystor_shikudo-vs-shaman_loss_t54WWU6b.txt | Mystor (Shikudo) loses to Agathon as a Shaman (curse, jinx, invoke), truelocked; no Sapience in this log | Mystor's (the Shikudo); he ran MIND SAPIENCE on the opponent in five of six | [combat/shikudo.md](../../combat/shikudo.md) |
| 2026-10-11_mystor_shikudo-vs-infernal-dwc_win_vNTjvghY.txt | Mystor (Shikudo) beats Agathon, Infernal DSL; finished with KAI CHOKE | Mystor's (the Shikudo); he ran MIND SAPIENCE on the opponent in five of six | [combat/shikudo.md](../../combat/shikudo.md) |

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
