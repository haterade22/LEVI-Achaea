# Our artefacts (ataxiaArtefacts): the reference that was in CLAUDE.md

> Moved verbatim from `CLAUDE.md` on 2026-11-13 (`docs/adrs/002-knowledge-delivery-tiers.md`). Until then every session loaded this text. It is not yet reconciled with the other documents of this subject: where they disagree, check the code or the game source, then correct the wrong one.

### Our artefacts (`ataxiaArtefacts`, v4.7.494)

A player's report: our docs and logic did not count the artefacts we own (the Aldar Diadem: 15% faster
equilibrium, worn at all times). `misc_scripts/033_Artefacts.lua` reads the PLAYER'S OWN list, so the
package is right for anyone who installs it; never a fixed list.
- **Source:** the game's `ARTEFACT POWER LIST OWNED` (`Item ID | Item Name | Power | Level`). Trigger 802
  (the header) opens a 10 s window and trigger 803 reads each row; the list REPLACES the saved one in
  `ataxia.settings.artefacts.powers` (saved with `ataxia`). Rows are parsed from their END: the name
  column is cut at 35 characters and can run into the power with one space, the power column at 20
  (`class_switch_reducti`, matched by prefix against the known powers), level `-` = no levels. The first
  login with nothing saved asks once (`ataxia_artefactLogin`, 19 s after login). Never scanned, the item
  catalog (`itemCatalog.items[*].kbKey` -> `kb.power/tier`) stands in.
- **API:** `ataxia_artefact(power)` -> `{id, name, level, from}` or nil; `ataxia_artefactLevel(power)`
  (0 = none, 1 = no levels); `ataxia_artefactSize(power, field, default)` reads `A.EFFECTS[power]`, which
  names the source of each size; `ataxia_eqFactor(form)` / `ataxia_eqSeconds(base, form)`: faster_eq
  (x0.93 / x0.85) times Rain (x0.85, `A.RAIN_FACTOR`), with a one-line reason. Quick-witted is named in
  the reason but not counted (its size is unknown). A class script guards every call
  (`if ataxia_artefact then`): `check_orphans.py` check 1c is strict.
- **Readers today:** Shaman's stand-in curse count (trigger `shaman/011`, `genrunning/004`: 10 + the skull
  pendant's 2/4/6; trigger 012's game line stays the real writer), the Tekura punch (`tekura6.classifyHit`
  splits a hit at the midpoint of the learned kick and punch, so a spiked-knuckles punch is not learned as
  a kick; TKD's prep line is `100 - tekura.punchDamage()`), and the Shikudo staff level
  (`ataxia.shikudoLevel` scales `shikudo/006` getAttackDamage's defaults). **A size that only
  `docs/artefacts-reference.md` gives is not used in code** (hamstring +5 s, the tuning fork's x2, the
  Collar's +20%: Release B). The game's `ARTEFACT POWER SHOW` text, filed 2026-11-13 in `kb/raw/artefacts/`,
  states no size, so each size still needs a source: the item's own text, a HELP file or our logs.
- **`aconfig artefact`**: list what we own, what each changes and who reads it; `aconfig artefact scan`
  asks the game again; `aconfig artefact <power> off|on [level]|auto` overrides one
  (`ataxia.settings.artefacts.override`). Tests: `test_artefacts.lua` (the pasted 74-row list,
  `kb/raw/live/artefact_power_list_owned_2026-11-13.txt`), `test_tekura_punch.lua`.
