---
topic: curatives
confidence: CONFIRMED (HELP 13.7.1 / 13.7.2) unless tagged
sources:
  - kb/raw/help/13.7.1_curatives-and-what-they-cure.txt
  - kb/raw/help/13.7.2_afflictions-and-what-cures-them.txt
last_verified: 2026-10-10
---

# Curatives

Every herb has a mineral equivalent: same effect, same balance. HELP 13.7.1 describes the
groups vaguely ("cure for body or mind in disharmony"). The exact affliction lists are in
[../afflictions/catalog.md](../afflictions/catalog.md).

## Herb <-> mineral pairs

| Herb | Mineral | How used | Effect |
|---|---|---|---|
| Kelp | Aurum | eat | Cures the kelp group ("weakened muscles or lower general fitness"): asthma, clumsiness, sensitivity, weariness, healthleech, ... |
| Ginseng | Ferrum | eat | Ginseng group ("impurities of the blood or diseases of the skin"): addiction, nausea, haemophilia, darkshade, lethargy, scytherus, ... |
| Goldenseal | Plumbum | eat | Goldenseal group ("body or mind in disharmony"): impatience, stupidity, epilepsy, dizziness, shyness, dissonance, ... |
| Lobelia | Argentum | eat | Lobelia group ("phobias or pathos"): recklessness, vertigo, agoraphobia, claustrophobia, loneliness, masochism, ... |
| Prickly Ash ("ash") | Stannum | eat | Ash group ("sanity"): confusion, dementia, paranoia, hallucinations, hypersomnia |
| Bellwort | Cuprum | eat | Bellwort group ("excessively altruistic"): peace, pacifism, generosity, justice, lover's effect, indifference |
| Bloodroot | Magnesium | eat | Paralysis, slickness |
| Slippery Elm ("elm") | Cinnabar | **smoke** | Aeon, deadening ("a variety of curses and afflictions") |
| Valerian | Realgar | **smoke** | Slickness, disfigurement (code: `disloyalty`), hellsight, mana leech |
| Prickly Pear ("pear") | Calcite | eat | Underwater breathing (cures drowning). **Cannot be used pre-emptively.** |
| Ginger | Antimony | eat | Reduces artificially raised body fluid (tempered humours) |
| Irid Moss ("moss") | Potash | eat | Heals some health and mana. **Uses the eating balance**, so it competes with every herb cure. |
| Cohosh | Gypsum | eat | Gives the **insomnia** defence (cannot be put to sleep) |
| Kola | Quartz | eat | Lets you **wake instantly**, at will |
| Echinacea | Dolomite | eat | Gives **third eye** |
| Skullcap | Azurite | eat | Gives **deathsight** |
| Skullcap | Malachite | **smoke** | **Rebounding**: weapon attacks bounce until someone takes it down or you act aggressively |
| Sileris | Quicksilver | **apply** | **Fangbarrier**: defends against Serpent fang attacks |
| Bayberry | Arsenic | eat | Gives **blindness** (wanted as a defence) |
| Hawthorn | Calamine | eat | Gives **deafness** (wanted as a defence) |
| Myrrh Gum | Bisemutum | eat | Faster lesson learning |

**Defence-giving curatives** (cohosh, kola, echinacea, skullcap, sileris, bayberry, hawthorn)
are what an opponent strips and SSC re-applies. Blindness and deafness are wanted, so our
curing priority for them is 26 (never cure). Monk and Blademaster raise them with their own
trances instead, to save the eating balance (`deffing/007_Sense_Keepers.lua`).

## Elixirs (SIP)

| Elixir | Effect |
|---|---|
| Health | Restores some health |
| Mana | Restores some mana |
| Immunity | **Cures voyria** |
| Frost | Fire resistance |
| Levitation | Levitate above the ground |
| Speed | Better dodging of some physical attacks |
| Venom | Resistance to damage from some poisons |

## Salves (APPLY)

| Salve | Cures |
|---|---|
| Epidermal | anorexia, blindness, deafness, stuttering ("outer organs like the eyes and ears") |
| Mending | crippled/broken limbs, ablaze ("broken or shrivelled limbs as well as some other things") |
| Restoration | damaged and mangled limbs, concussion, internal trauma (HELP BODY PART DAMAGE) |
| Caloric | freezing / cold afflictions; also a defence against some cold attacks |
| Mass | prevents being moved against your will (a defence, not a cure) |

## Using curatives (HELP 13.7)

Source: `kb/raw/help/13.7_healing-and-curing.txt`.

- **Sleep and meditate** restore health/endurance and mana/willpower. They are slow and need
  you to do nothing else.
- **Elixirs:** `DRINK <fluid>` drinks from the first vial holding that fluid (or
  `DRINK <vial#>`). `PROBE <vial>` shows the contents.
- **Salves:** `APPLY <salve> [TO <part>]`. Mending and restoration can be aimed at the head,
  arms, legs or body. Unaimed, they go to whatever part needs them. Aiming chooses the order
  when several parts need the same salve.
- **Sileris and quicksilver** are applied, not eaten, and coat you against Serpent bites
  (fangbarrier). A Serpent can flay the coating off.
- **Pipes:** `PUT <herb> IN PIPE`, `LIGHT PIPE` (needs a tinderbox), `SMOKE PIPE`. A lit pipe
  goes out if left unsmoked and must be relit.
- **DIAGNOSE** (Survival, AB 1380): `DIAGNOSE` / `DIAG [ME]` lists what ails you and costs
  **1.00 second of equilibrium** (`kb/raw/ab/survival_diagnose_1380.txt`). It is not free.
