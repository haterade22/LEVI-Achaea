--[[mudlet
type: alias
name: Mnemosyne Boon Claim
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^(?i)boon claim (.+)$
command: ''
packageName: ''
]]--

-- Pass the real command through, then report the selection.
send("boon claim " .. matches[2])
ataxia.mnemosyne.onBoonClaim(matches[2])
-- Warmarch makes the paean refrain hit denizens (+100% psychic); flip bard bashing to paean.
if matches[2]:lower():find("warmarch") then bardWarmarch = true end
-- White Heaven's Shattered Star buffs multislash (+3 strikes); flip blademaster bashing to multislash.
if matches[2]:lower():find("shattered star") then bmShatteredStar = true end
-- Aspect of Kkractle makes ELEMENTAL SURGE an AoE fire nuke on all denizens; flip magi bashing to it.
if matches[2]:lower():find("kkractle") then magiKkractle = true end
-- Hot Springs makes BLOODBOIL also heal 25% max hp + 5% willpower (30s cd); magi uses it as a heal.
if matches[2]:lower():find("hot springs") then magiHotSprings = true end
-- Hammer and Anvil: attacks bypass denizen shields; basher skips razing and shield-swaps.
if matches[2]:lower():find("hammer and anvil") then mnemHammerAnvil = true; ataxiaBasher.shielded = false end
-- Bladed Reflexes: 20% reduced damage while the Shindo augment (bodyaugment) is up; BM basher keeps it up via SHIN AUGMENT 1.
if matches[2]:lower():find("bladed reflexes") then bmBladedReflexes = true end
-- Sleuth: FULLSENSE reveals all denizens in the ripple; swarm module recons each wave on GO.
if matches[2]:lower():find("sleuth") then mnemSleuth = true end
-- Roll Hide: tumbling out of a room sheds all pursuers; swarm panic-abort (stage 2).
-- Frontier pattern: a plain find("roll hide") would also match inside "Troll Hide".
if matches[2]:lower():find("%f[%a]roll hide") then mnemRollHide = true end
