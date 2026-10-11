# Combat logs

Verbatim text of combat logs, kept as evidence. Never edited after they are filed; what each one
shows is written up in a curated page that cites it.

| File | Fight | Whose log | Curated in |
|---|---|---|---|
| 2026-10-11_shikudo-vs-runewarden-snb_attacker.txt | A Shikudo monk (staff "a twisted oaken staff") kills Claes, a Runewarden (sword and Shield of Absorption), by DISPATCH, about 86 s | The Shikudo's | [combat/shikudo.md](../../combat/shikudo.md), [combat/runewarden-snb.md](../../combat/runewarden-snb.md) |
| 2026-10-11_runewarden-snb-vs-shikudo_defender.txt | Claes kills Dominius, a Shikudo monk ("a dark ash wood staff"), by impale and DISEMBOWEL, Oniar Estate arena | Claes's (the Runewarden) | the same two pages |

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
