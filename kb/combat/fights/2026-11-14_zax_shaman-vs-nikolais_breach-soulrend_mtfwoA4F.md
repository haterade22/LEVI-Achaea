# Zax (Shaman) vs Nikolais: breach + soulrend fashion burst

> Source: `kb/raw/logs/2026-11-14_zax_shaman-vs-nikolais_breach-soulrend_mtfwoA4F.txt` (Zax's own log, a Mudlet extract of 1,232 lines; downloaded by the maintainer 2026-11-14). **The date of play is unknown.** Confidence: LOG for what the lines show. Every timing is ANOTHER PLAYER's (Zax; his artefacts are not known), not ours. Unconfirmed by our own logs.
> Zax's system replaces some game lines (`You: Invoke soulrend 13 -> Nikolais`). Our own raw soulrend line is the pattern in `src_new/triggers/levi_ataxia/for_levi/leviticus/ataxia/007_Soulrend.lua`.

## What the log shows

- **Logger: Zax, a Shaman. Target: Nikolais.** The tip behind it: `kb/raw/players/shaman-breach-soulrend-2026-11-14.txt`.
- **`curse Nikolais breach invoke soulrend` is accepted with no curseward.** The game prints "Your attempt to breach finds no curseward." (434, 496, 1086, 1156, 1216), then the rend.
- **The combo charges jinx:** "Your malign power may be unleashed in the form of a jinx against your victim." follows each one (442, 504, 1094, 1164). Breach is a jinx charger, like a regular curse.
- **Fashions per rend**, Zax's `You: Invoke soulrend N` line, against the target's mana from his VODUN STATUS line just before it: 60.4% -> 13, 74.9% -> 10, 72.8% -> 10, 61.1% -> 13, 59.2% -> 13 (lines 440, 502, 1092, 1162, 1222). Lower target mana gave more fashions. His prompt `F:` went 5 -> 51 over the five rends (about 13 s).
- **Timing printed by Zax's system:** Bal Spent 0.9 s, Eq Spent 0.85 s. Breach is 1.00 s BASE (`kb/classes/shaman.md`); ours is BASE x `ataxia_eqFactor` (`kb/mechanics/balance-and-queueing.md`, "Our speed factors"). Not measured on our side.
- **Target affs at the rends:** manaleech and asthma were up at all five; paralysis was NOT up at any. The tip's gate (manaleech + asthma + paralysis) is therefore wider than needed: paralysis only blocks the tree.
- **Rotation:** Zax alternates a jinx and a breach + soulrend, so the 0.9 s breach is the jinx charger in place of a 2.2 s regular curse.

## Open (UNVERIFIED by our logs)

- The server accepting the combo for us, our real balance, and our fashion counts per rend. The 007_Soulrend echo will record them; add them to `.claude/classes/shaman.md` ("Fashion burst") when seen.
- The tip's "about 10 fashions per rend, 2 per eat cycle = 20" (another player; the log shows 10 to 13 per rend).
- The "86% target mana" tactic needs the target's mana, which we only have from VODUN STATUS.
