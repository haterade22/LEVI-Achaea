---
topic: locks
confidence: guide (community) unless tagged
sources:
  - kb/raw/guides/lock-types.txt
  - kb/raw/help/conditional-afflictions-for-the-achaean-forms.txt
see_also:
  - .claude/classes/lock_types.md      # the established, longer lock reference
  - .claude/databases/locks.yaml       # machine-readable lock definitions
last_verified: 2026-10-10
---

# Locks

A lock is a set of afflictions where **each one blocks the cure for another**, so the target
cannot cure any of them. Each lock below adds one more channel to the shut list (see
[cure-channels.md](cure-channels.md)). This page is the short version.
`.claude/classes/lock_types.md` is the long one.

| Lock | Afflictions | Channels shut | How it is escaped |
|---|---|---|---|
| **Softlock** | asthma, anorexia, slickness | eat, apply, smoke | FOCUS cures anorexia -> eat bloodroot (slickness) -> eat kelp (asthma). Also the tree. |
| **Venomlock** | + paralysis | + tree | FOCUS -> anorexia, then the same chain |
| **Truelock / Hardlock** | + impatience | + focus | None from curatives. Only a **class cure** ([class-cures.md](class-cures.md)) or outside help, so add that class's lock affliction (weariness, voyria, stupidity, recklessness, ...). |
| **Focuslock** | venomlock + several mentals (instead of impatience) | tree | FOCUS works, but picks randomly among mentals. Each focus that misses anorexia buys a round. |
| **Riftlock** | two broken arms + slickness + asthma | cannot outrift herbs, cannot apply mending, cannot smoke valerian | Smoke valerian -> mend arms -> rift herbs. **Addiction** (vardrax) helps: broken-armed targets eat whatever is already in hand. |
| **Salvelock** | two arm breaks at **level 2+** + slickness + asthma | as riftlock, and RESTORE cannot heal level-2 breaks | Very hard. Needs several mending applications. |
| **Sleeplock** | sleep x3 in rapid succession | everything while asleep | 1st sleep strips **insomnia**, 2nd strips the **instant-wake** defence, 3rd sleeps them. |
| **Aeonlock** | aeon + asthma (+ more kelp afflictions) | one action at a time; cannot smoke elm/cinnabar for aeon | Cure asthma (eat kelp/aurum) -> smoke elm. A kelp stack (clumsiness, sensitivity, weariness, healthleech) keeps asthma stuck. |

## Corrections to the source text

- **Sleeplock defences.** The guide says the second sleep strips "the Gypsum/Kola defence".
  HELP 13.7.1 says **gypsum (= cohosh) gives insomnia** and **quartz (= kola) lets you wake
  instantly**. The order is therefore: 1st strips insomnia (cohosh/gypsum), 2nd strips
  instant-wake (kola/quartz), 3rd sleeps them.
- **Truelock vs hardlock.** The guide treats these as the same thing. Our
  `.claude/databases/locks.yaml` separates hardlock (+impatience) from truelock (+the class
  affliction). Use the yaml's terms in code.

## Passive cures and voyria

Passive cures fire about every 10 seconds and **cure voyria before anything else**. Against
a class with a passive cure (Apostate, Bard, Priest, Paladin, Pariah, Runewarden,
Druid/Sylvan, Jester/Occultist, Magi, Air Lord):
1. Keep voyria up.
2. When the passive fires, it takes voyria. Use the window to land another lock affliction.
3. Reapply voyria before the next tick.

(HELP "Conditional afflictions for the Achaean forms" and the guide both say this.)
