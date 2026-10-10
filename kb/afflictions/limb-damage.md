---
topic: limb-damage
confidence: CONFIRMED (HELP 13.9), partly dated, see notes
sources:
  - kb/raw/help/13.9_body-part-damage.txt
see_also:
  - docs/limb-damage-mechanics.md      # the established, detailed reference
  - memory/slc.md                      # our own limb tracking (Self Limb Counter)
last_verified: 2026-10-10
---

# Body part (limb) damage

There are six parts: **head, torso, left arm, right arm, left leg, right leg**. An attack aimed
at a part damages both your health and that part. The health damage is lower than an unaimed
attack's. Each part moves through states:

| Part | State 1 | State 2 |
|---|---|---|
| Head | stupidity | concussion |
| Body (torso) | minor bleeding | serious bleeding |
| Limbs | limb breaks | limb is mutilated and broken. **Restoration must be applied before mending works.** |

**Damage is not the same as a break** (HELP's own emphasis). A damaged limb has lost its ability
to heal: mending alone does nothing until restoration has been applied.

**Parrying:** with PARRYING (Weaponry) and a weapon that can parry wielded, attacks aimed at a
body part can be parried for no damage. Aiming at body parts needs TARGETTING (Weaponry).

## How this maps to our code

- Our affliction names use the current scheme: `broken<limb>` (mending), `damaged<limb>` /
  `mangled<limb>`, `damagedhead` / `mangledhead` (restoration), plus `concussion`,
  `crackedribs` and the trauma/fracture families. HELP 13.9's "State 1 / State 2" wording is
  older than these names. Treat it as the concept, and the catalog's code keys as the vocabulary.
- **Salve order is a real trade-off.** Mending/restoration share the salve balance with burning,
  crackedribs, fractures and traumas. See [cure-channels.md](cure-channels.md).
- Our own limb damage percentages are tracked by SLC (`selfLimbDamage`). Target limbs are tracked
  by `lb[target]`.
