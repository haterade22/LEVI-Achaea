---
topic: mnemosyne-affixes
confidence: mixed (tagged per claim)
sources:
  - kb/raw/live/mnemosyne-tashla-prey_2026-11-10.txt
  - kb/raw/logs/2026-11-20_mnemosyne-nightmare-death.txt
  - the user's Mnemosyne history file (run 223 affix list, read live through Mudlet MCP, 2026-11-10)
code:
  - src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/009_Swarm_Tactics.lua
  - src_new/scripts/levi_ataxia/levi/ataxia/basher/001_Bashing_Functions.lua
  - src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/007_History.lua
last_verified: 2026-11-23
---

# Mnemosyne affixes that change a fight

A wade's affixes are recorded in `ataxiaTemp.mnemAffixes` with telemetry on or off (the affix
registry, `mnemosyne/017_Affix_Registry.lua`, v4.7.511), and with telemetry on also in the history
file (`M.history.affixes`). `M.runHasAffix(name)` matches a whole name; `M.hasAffix(name)`
(`007_History.lua`) matches a SUBSTRING. What our code does about each affix is in
`M.AFFIX_REGISTRY`; the game's sentence for each of the 46 affixes we have seen is in
`raw/live/2026-11-23_mnemosyne-affix-library.txt`. This page holds the affixes whose effect on a
fight we have seen in a log.

## Facts

### Prey: "All denizens are trackers and will chase should you flee."
- In the 2026-11-10 death, a tash'la warrior and a tash'la interceptor followed our leap. The leap
  landed at 12:47:15.977 and both arrived by 12:47:16.541, about 0.6 s later.
- So a ground retreat (leap, tumble, walk) gains nothing. It costs a balance, and the escape holds
  the attacks while it runs.
- **Confidence:** CONFIRMED for this one pair of denizens (one log). Roll Hide and Terror of the
  Skies shed pursuers by their boon text; under Prey this is UNTESTED.
- **Code (v4.7.486):** `S._preyTracks()` (009:574) matches the affix name WHOLE, for this run only,
  and returns false with Roll Hide or Terror of the Skies. `S._retreatBlock` (009:589) then refuses
  every ground retreat. The recovery hover is not a ground retreat and still flies.

### Sanguine Restoration: "Pools of blood shall heal nearby denizens."
- Room prose with a pool: `An ichorous pool of blood sprawls across the ground.`
- The heal, one line per denizen:
  `A tash'la warrior is shrouded by a crimson nimbus as the bloody pool roils with profane intent.`
- In the log the pool healed both denizens twice, 10 s apart (12:47:18.3 and 12:47:28.2). The log
  does not show how much it healed.
- The pool was already there when we leapt into the room. Its source (an earlier kill, or our own
  bleeding) is not known.
- **Confidence:** CONFIRMED lines (one log); the heal amount and the pool's source are UNKNOWN.
- **Code:** only the Monk battlerage reads this affix (Ripplestrike for Inhibit, basher/001). No code
  records pool rooms yet; the user chose not to build that on 2026-11-10.

### Meldscorned: "Denizens cause additional Shadowmancy afflictions on their attacks."
- Each tash'la warrior hit printed `Your own shadow betrays you, leaving your thoughts scattered and
  wan.`, and the next line gave one more affliction: `You feel your strength being leeched away.`,
  `Everything seems so pointless.` (depression), `A terrible sense of unease comes over you.`
  (hypochondria) or `Your sanity begins to escape you.` (`shm` on the prompt). After three of the
  eight hits the prompt also showed stupidity and paralysis (`stu par`).
- Stupidity replaced three of our commands with emotes: `You get down on one knee and serenade the
  world.`, `You pick your nose absently.` and `What do you want to eat?`.
- **Confidence:** CONFIRMED (one log).

### Ricketts: "Attacking a denizen causes some of your limbs to break."
- In the live buffer of 2026-11-23 (OURS, Monk, ripple about 43,
  `raw/live/2026-11-23_ricketts-arm-breaks.txt`) a break prints `Your right arm breaks with a loud
  crack.` In that excerpt both arms broke within 0.2 s, each line after a denizen's bite. So it is
  not clear whether our attack or theirs makes the break. UNCONFIRMED.
- With both arms broken the swing is refused: `You cannot do that because both of your arms must
  be whole and unbound.` Trigger 344 handles it, and a kick-and-uppercut round followed 0.4 s
  later with one arm still broken (`ra1` on the prompt).
- **Confidence:** CONFIRMED lines (one log). **Code:** no Ricketts-specific code; the registry
  row names trigger 344.

### Suffering of Abbadon: a kill can spawn a thornwall or gravehands
- Sentence: "Slaying a denizen has a chance to evoke a memory of the Suffering God and spawn either a
  thornwall or gravehands in your location."
  (`raw/live/2026-11-21_wade-status_ricketts-splinterbark-abbadon.txt`)
- No spawn line is captured: a search of the last 6,000 lines of the live buffer on 2026-11-23,
  in a run with this affix, found no "thornwall", "gravehands" or "Suffering God". UNKNOWN: whether
  a thornwall blocks our exits, and whose side the gravehands take.
- **Code (v4.7.511):** one of the spawn-on-kill affixes: the explorer waits for 90% HP after a
  cleared room (`M._spawnHold`).

### Permanent afflictions: Tenderised Flesh and Outcast
- "You suffer permanent tenderskin and permanent sensitivity." / "You suffer from permanent
  disloyalty." (`raw/live/2026-11-23_mnemosyne-affix-library.txt`)
- **Code (v4.7.511):** `M.runPermanentAffs` (`004_Parsers.lua`) reads this run's affix sentences
  as well as the boons, so `ataxia_permanentAff` names the affix and no cure counts them.
  INFERRED that the game never cures them (the word "permanent"); not tested in a log.

### The tash'la pair, for scale
- Warrior: about 2,400-2,800 per hit (physical blunt); the elbow drop breaks a limb.
- Interceptor: about 1,200-2,400 per hit; the spear-butt hit breaks a leg, the chain throw makes us
  prone, the hair whip deals blunt and cutting together.
- One round from each about every 2.5-2.7 s, about 2,000 HP/s together.
- Our healing in the same window (Death's Demise held, so no death-cape life-steal): elixir sips of
  1,600-3,700 and potash of about 1,040, about 1,030 HP/s. The user gags sip lines, so a sip shows
  only as a health jump on the prompt.
- **Confidence:** CONFIRMED (one log), INFERRED for the sip amounts (prompt differences).

### The manifested nightmare (a Mnemosyne denizen)

From the death of 2026-11-20 (`kb/raw/logs/2026-11-20_mnemosyne-nightmare-death.txt`; OURS, our max
health about 15,696, one log, CONFIRMED). It has three attack lines, and each one also gives us
venom afflictions ("Your blood seethes as deadly venom infects your system.", "You are confused as to
the effects of the venom."):

| Line | Damage seen (OURS) |
|---|---|
| "Cold radiance flares from deep within a manifested nightmare ... leaving you chilled to the core." | cold: 2221, 3353, 2925, 2755, 2805 |
| "A dozen mouths tear open across a manifested nightmare shifting form and unleash a maelstrom of shrieking voices that crashes into you." | psychic: 3413, and 1659 (the killing hit) |
| "The nightmare convulses and a forest of grasping hands erupts from its body ..." | physical cutting: 1001 |

- **Its hits pass the tattoo shield.** After the shield rose (13:08:48:227), 3413 psychic, 1001
  cutting, three colds and the 1659 psychic all landed, each with a `Health lost:` line and no
  shield-break line. The game's own "Health lost: 2086 (unblockable)" in the same fight is our
  retching, not the nightmare.
- **Rate:** about 1,390 HP/s in against about 920 HP/s healed (elixir sips of about 3,200 every
  about 4.5 s and potash of about 1,255 every about 6 s, from prompt differences; INFERRED).
- We stopped attacking with the nightmare at 37%. The fight began while we were reckless, so our
  health read full (`kb/afflictions/README.md`, section 5).
- UNCONFIRMED: a bite ran at 13:08:46:778 after the stand announced "attacks held until 70%" at
  13:08:45:710. The cause is not found (CHANGELOG v4.7.506).

### Boon: Convocation (the brazier tattoo summons a denizen)

Boon text: "You may now use brazier tattoos on non-boss denizens, but your brazier tattoo incurs a
1 minutes cooldown." Raw lines: `kb/raw/live/2026-11-20_convocation_brazier.txt` (OURS, user paste
2026-11-20, CONFIRMED, one capture):

```
You wave your hand over the brazier tattoo and summon an elderly constable to you.
The colour is leeched from your brazier tattoo as it is greatly taxed.
```

- Command: `touch brazier <keyword>` with a keyword of the denizen; the denizen is pulled to us.
- Cooldown: 60 s (the boon text; not yet timed in a log). Our code starts it on the second line
  (`M.onBrazierTaxed`, 004_Parsers.lua).
- Refusal when the keyword matches a denizen already in our room (OURS, 2026-11-20, one capture,
  `kb/raw/live/2026-11-20_convocation_brazier_already_here.txt`): `That person is already here.`
  The command was `touch brazier halfling`, and the room held only "Ironbeard, the Magnanimous". So a
  denizen keyword can be a word that is NOT in its name (probably its race). UNCONFIRMED that
  Ironbeard was the match. Our pick never sends with a denizen in the room, so it does not expect
  this line; the one-try-per-room gate covers it if the room list is stale.
- Refusal for a keyword the game does not know (OURS, 2026-11-21, one capture,
  `kb/raw/live/2026-11-21_convocation_brazier_unknown_keyword.txt`): `I do not recognise anything
  called that here.` It costs equilibrium: `Equilibrium used: 0.85s.` (OURS; with the Aldar Diadem
  x0.85 that is a 1.00 s BASE, by calculation, not from AB). No taxed line follows, so no cooldown.
  The keyword was `life`, from "an acolyte of Life" and "an haruspex of Life": the last word of a
  name is not always a keyword. Since v4.7.508 our rule takes the head noun (the name cut at its
  first comma and first " of "), and a refused keyword is dropped for the ripple.
- UNCONFIRMED: that the head noun is a keyword for every denizen (seen to work for six names).
- A boss cannot be summoned, even from our own room (OURS, 2026-11-21, Dr. Kortoxian, three tries,
  `kb/raw/live/2026-11-21_convocation_brazier_boss.txt`). The game answers with its ordinary "not
  found" refusal, a different wording each time: `You cannot see that being here.`, `I do not
  recognise anything called that here.`, `You detect nothing here by that name.` Each cost
  `Equilibrium used: 0.85s.` (OURS). These are among the five lines of our shared trigger
  `denizen_attacks_misc_lines/003_Target_Not_Here`, so the v4.7.508 refusal handler sees each of
  them. Since v4.7.509 our keyword rule never learns the ripple boss's name (`M.run.boss`).
- Ready line (OURS, 2026-11-21, five captures, `kb/raw/live/2026-11-21_convocation_brazier_ready.txt`):
  `Power returns to your brazier tattoo in a muted flash.` The cooldown measured 59 to 61 s from the
  taxed line each time (the error is the prompt-timestamp bracket, under 1.2 s), so the boon's
  "1 minutes" holds for us. Our trigger 113 ends the cooldown on this line (v4.7.510).
- The head-noun keyword worked for five more names in the same captures: `archer` (an Arcadian
  archer), `sentry`, `minstrel` (a fairy Minstrel of Sidhe), `knight`, `lady`.
- UNCONFIRMED (no capture): the refusal while on cooldown.
- Our use: the explorer sends it in an empty room (`M._brazierPick`, 008_Explorer.lua), see
  `.claude/projects/mnemosyne/07-explorer.md`.

## What the death taught

The swarm's one retreat went into a Prey pursuit and a blood pool. After it, every exit was
refused, and `ataxiaBasher_canShield()` (`can(x)/002`:18) is false while any target-list denizen
is in the room and `noShieldBreak` does not name it, which in the tower is every fight. From 28%
to 15% health the only action left was another attack. **The last stand (v4.7.486,
basher/001:580-736)** shields in that case and holds the attacks until 70% health (85% and cured in a room of shield-safe denizens, v4.7.519) (or until hits pass the shield, v4.7.506, unless the shield blocked another denizen in the room in the last 10 s, v4.7.514). **A shield is per denizen (OURS, the oryx death 2026-11-24, maintainer's quote, not yet filed):** an ochre-necked oryx's charge (physical cutting + unblockable) passed our `touch shield` while a diamond-back rattlesnake in the same room printed "A diamond-back rattlesnake hurls itself against your shield in a futile attempt to harm you." The line shape after `touch shield` is CONFIRMED in `raw/logs/2026-08-19_leviticus_blademaster-vs-sentinel_loss_Sentinel.txt` ("A gossamer butterfly hurls itself against your shield in a futile attempt to harm you."). "Your shield completely absorbs the damage." is a Shield of Absorption line, not this shield (`kb/combat/shikudo.md`). **Some denizens never get through it (OURS, CONFIRMED, `raw/live/mnemosyne-shield-safe-mobs_2026-11-24.txt`):** under Prey, a savage boar (4 lines) and a fearsome lion (3 lines) printed only "hurls itself against your shield in a futile attempt to harm you." for 6 s, with no `Health lost:` line between them; "Your action causes the nearly invisible magical shield around you to fade away." is our own attack dropping it. Since v4.7.519 the basher counts each such line per denizen and keeps it in a saved record, and a room of only such denizens gets the shield instead of a retreat (`.claude/projects/basher/05-safety-systems.md`, "Shield-safe denizens"). See
`.claude/projects/basher/05-safety-systems.md`. **v4.7.490:** the v4.7.486 stand let the next
attack round delete its queued shield (two errant frost elementals, 2026-11-11,
`raw/live/mnemosyne-frost-elemental-laststand_2026-11-11.txt`). A stand now holds every round
from its first `touch shield`, clears the queue first, and gives up after 2 tries. **v4.7.506:** a shield does not stop every denizen (the manifested nightmare, above); two blockable `Health lost` lines while the shield is up end the stand and bar shields in that room.
