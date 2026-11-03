---
topic: mindnet
confidence: mixed (tagged per claim)
sources:
  - kb/raw/live/mindnet_2026-11-03.txt
  - kb/raw/wiki/Telepathy.wiki
code:
  - src_new/triggers/levi_ataxia/for_levi/leviticus/telepathy/001_Mindnet.lua
  - src_new/scripts/levi_ataxia/levi/ataxia/013_Raid_Mode_Things_(WIP).lua
  - src_new/scripts/levi_ataxia/levi/ataxia/misc_scripts/030_GMCP_Consumers.lua
last_verified: 2026-11-03
---

# Mindnet

MINDNET (Telepathy; Blademasters also keep it as a defence) tells you when a player moves into or out of
its range. In a group fight, this is the first warning that the other side is coming, so we call it to
the party.

## Facts

### Mindnet (Telepathy)
- **Syntax:** `MINDNET [ON|OFF]`, `RELAX MINDNET`
- **Cost:** a constant mana drain
- **Effect:** "throws up a telepathic net over the local area, informing you whenever anyone moves into or
  out of range of the net."
- **Line seen:** `<Name> has entered the area.` and `<Name> has left the area.`
- **Confidence:** WIKI for the ability, CONFIRMED (live) for the lines. **Source:** kb/raw/wiki/Telepathy.wiki,
  kb/raw/live/mindnet_2026-11-03.txt
- **Notes:** the lines print many times in a fight, and a player at the edge can flap: Lauryyn entered at
  08:10:22.249 and left at 08:10:22.364. So the party call has no alert sound.

### What `Comm.Channel.List` tells us
- **`party` is in the list while we are in a party.** The save at 08:03 has it, the save before it does not,
  and every other key is the same. **Confidence:** INFERRED from those two saves. **We have not seen `party`
  leave the list when a party ends.**
- **The caption of `ct` is our city's name** (`Mhaldor`). **Confidence:** CONFIRMED (live), from both saves.
- `gmcp.Char.Status.city` is not used here: no code reads it, and we have no record of its format.
- **Code:** `ataxiaGmcpConsumers_onChannelList` (`misc_scripts/030`) stores the list as `ataxia.channels`.

## Who we call (CONFIRMED-in-code, v4.7.472)

`ataxia_mindnetTellParty(name, area)` decides the `pt <name> IN!` / `pt <name> OUT!` line. The first rule
that applies wins:

1. `raid mindnet` is off: no call.
2. `raid on`, or the area is `Annwyn`: call everyone.
3. The area is exactly `Mhaldor` and the player is a city enemy: call, in a party or not.
4. We are not in a party: no call. A list not read yet counts as in a party, because silence is the worse fault.
5. The player is us or is on `ataxiaTemp.allies`: no call.
6. Call if the player's city (`ataxiaNDB_getCitizenship`) differs from ours. `Unknown` and `Rogues` differ.

The clan line (`clt6`), the alert and the box echo do not use this function. They stay with their old cases:
raid on (alert), a city enemy in `Mhaldor` (all three), Annwyn (alert and box), a personal enemy (alert, and
the box while bashing).

**Known limit:** no code holds a party member list, so a rogue or foreign party member who is not an ally
gets a call. Vasyly (NDB city `None`) was in this group.

**Why not the city enemy list:** in this fight it held Xylarys, Nahaj and Akri. It did not hold Grulk, Lauryyn,
Froedine, Kushy, Toscus, Boulden or Tienau.
