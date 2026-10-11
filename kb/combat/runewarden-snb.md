---
topic: runewarden-snb-combat
confidence: mixed (tagged per claim)
sources:
  - kb/raw/logs/2026-10-11_shikudo-vs-runewarden-snb_attacker.txt
  - kb/raw/logs/2026-10-11_runewarden-snb-vs-shikudo_defender.txt
code:
  - src_new/triggers/levi_ataxia/for_levi/leviticus/snb/001_slice.lua
  - src_new/triggers/levi_ataxia/for_levi/leviticus/attacks/008_SnB_Slice.lua
  - src_new/triggers/levi_ataxia/for_levi/leviticus/passive_active/027_Dagaz_(Runewarden).lua
last_verified: 2026-10-11
---

# Runewarden, sword and board, in combat

What a Runewarden with a sword and a shield does to you, read from two fights against Shikudo
monks (2026-10-11). Log 1 is the monk's, so it shows Claes's attacks **landing on us**; log 2 is
Claes's own, but her system replaces her attack lines with summary blocks, so it shows her
**choices** rather than the game's text. Lines are **CONFIRMED (live)** unless marked.
`<R>` is the Runewarden.

## One round (log 1, the victim's side)

The slice, with a venom, then the shield, in one balance:

| Line | What it did to us |
|---|---|
| The blade of <R> is a blur as she moves forward, slicing into you. ("...into your torso." / "...into your left leg." when it hits a limb) | 523 physical cutting; a limb slice adds "As <R> carves into you, you perceive that she has dealt 11.8% damage to your torso." |
| You gasp as your fine-tuned reflexes disappear into a haze of confusion. | clumsiness (xentio) |
| You feel suddenly very ill as a blessed legionnaire's longsword strikes you, a rush of nausea threatening to overcome you. | nausea (euphorbia) |
| You feel a tightening sensation grow in your lungs. | asthma (kalmia) |
| <R> quickly lunges to the side, bringing her shield around to smash into your spine. / Your muscles lock in painful contractions in reaction to the blow. | **paralysis** and 131-163 blunt. Seen 20 times: her most common shield strike |
| <R> drives the edge of her shield into your throat, cutting off your air supply. | asthma, 136 blunt |
| <R> draws a Shield of Absorption back, then lunges forward with a savage strike to your ribs. | (no affliction shown) |
| <R> swings her shield around, smashing your temple with a backhanded blow. | (no affliction shown) |
| Cold blue flames wreathe <R>'s runeblade, emanating an icy chill that penetrates you to the bone. | shivering (probably her Nairat rune: in log 2 her system reports `Runeblade: (Nairat)` together with `Afflicted: (Frozen)`; ASSUMED) |
| The sleizak rune flashes bright upon a blessed legionnaire's longsword in the hand of <R>. / The inguz rune flashes bright upon ... | rune procs (log 2 pairs Inguz with sensitivity) |
| <R> misses you with a blessed legionnaire's longsword. | a miss |

Her falcon fought too: "A fierce mountain falcon soars in upon silver wings.", "...dives at you,
raking your face with its talons." (217-334 damage), "...rips out a chunk of your flesh with its
beak." (228 cutting, and "Your levitating defence is ripped apart by its talons.").

## How she cured and defended (log 1)

Kelp, goldenseal, ginseng, bloodroot, irid moss, a health elixir; mending on her legs after
every flashheel; the tree tattoo; FOCUS ("A look of extreme focus crosses the face of <R>.");
the shield tattoo ("A nearly invisible magical shield forms around <R>."); sileris. And two runes
sketched on the ground: **Uruz** (heal) and **Dagaz** ("Heals affs"):
"A rune like a rising sun upon the ground flares, bathing <R> with healing magic." cured
afflictions on a timer. A stone wall also rose to block one exit ("A wall of rough stone rises
from the earth to block the exit to the northwest."; its source is not shown).

## Her kill (log 2): torso, impale, disembowel

Against Dominius (Shikudo) she cut the **torso** round after round (her summary block reads
`Sliced: (Torso) (89.8%)`, then 96.9%, then 104%), with curare, kalmia, xentio and vernalius on
the blade, the **shield strike for paralysis or prone**, Nairat (frozen) and Inguz (sensitivity),
and **RAZE** for his shield and rebounding ("Razed: Shield", "Razed: Rebounding"). With the torso
past 100% she **impaled** him (her summary: "Impaled: Dominius.", "Stunned: Dominius."; the game:
"Dominius looks pale and gaunt as his body shudders on the end of the weapon.") and then:

"With a vicious snarl you carve a merciless swathe through the steaming guts of Dominius, who
gurgles and chokes as you withdraw your dripping blade, glistening with gore." (DISEMBOWEL)

Earlier in the same fight he writhed free once: "With a look of agony on his face, Dominius
manages to writhe himself free of the weapon which impaled him."

## What this means for us

- **Paralysis is her main tool**, from the shield strike every round, so bloodroot/magnesium
  balance is spent on it constantly (Dominius ate 52 magnesium chips in log 2).
- **Torso damage is the kill condition:** past 100% torso she impales, and the disembowel
  follows. Keeping the torso mended and writhing at once are what stop it.
- **Her Dagaz rune cures her afflictions on a timer** while she stands on it, which slows any
  lock. Our package already watches for it (`passive_active/027_Dagaz_(Runewarden).lua`).
