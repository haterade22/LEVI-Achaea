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
-- Reaper: each denizen kill permanently (for the run) adds +1% damage dealt; the
-- tithe trigger (023) counts kills and echoes the running total. Frontier pattern
-- so a boon named e.g. "Soulreaper" can't false-match.
if matches[2]:lower():find("%f[%a]reaper") then mnemReaper = true end
-- Bloodscent: senses out every denizen (name/#id/room) on entering a ripple; the
-- sense-line trigger (028) parses it into the swarm module's recon.
if matches[2]:lower():find("bloodscent") then mnemBloodscent = true end
-- Kai Unleashed: kai choking a denizen bursts magic damage on ALL denizens in the
-- room (30s cooldown); the Shikudo basher fires KAI CHOKE in Rain form at 2+ mobs.
if matches[2]:lower():find("kai unleashed") then mnemKaiUnleashed = true end
-- Senseless Flurry: balance recovers 30% faster while the numbness defence is up;
-- the Shikudo basher keeps NUMB up in Rain form (eq rider, choke outranks it).
if matches[2]:lower():find("senseless flurry") then mnemSenselessFlurry = true end
-- Panoply: WEAVE FLURRY scales with strikes landed (60-200% per attack); the Psion
-- basher swaps its deathblow bash to flurry while it's up.
if matches[2]:lower():find("panoply") then psionPanoply = true end
-- Might of Sycaerunax: draconic BLAST +25% damage and the breath weapon PERSISTS;
-- the dragon basher drops the re-summon from its blast weave while it's up.
if matches[2]:lower():find("sycaerunax") then dragonMightSycaerunax = true end
-- Draconic Rampage: TRAMPLE deals a large room-wide cutting nuke on a 40s proc;
-- the dragon basher spends the balance swing on it at 2+ denizens, off cooldown.
if matches[2]:lower():find("%f[%a]rampage") then dragonRampage = true end
-- Flashforward: +20% damage while the chrono blur defence is up; the Depthswalker
-- basher keeps CHRONO BLUR up (eq rider, age-capped) while it's claimed.
if matches[2]:lower():find("flashforward") then dwFlashforward = true end
-- Army of the Dead: SUMMON HANDS OF THE GRAVE also damages every denizen in the room;
-- the Infernal basher casts it at 2+ denizens.
if matches[2]:lower():find("army of the dead") then infArmyOfDead = true end
-- Daemon Jaws: hyena maul cooldown -66%; shrinks the maul safety timer to match.
if matches[2]:lower():find("daemon jaws") then infDaemonJaws = true end
-- Indiscriminate: ARC works on denizens; the Infernal basher swings the room-wide arc
-- instead of its single-target attack at 2+ denizens.
if matches[2]:lower():find("indiscriminate") then infIndiscriminate = true end
-- Necrotic Aura: attacks inhibit denizen healing while the DEATHAURA defence is up;
-- the Infernal basher keeps that defence raised.
if matches[2]:lower():find("necrotic aura") then infNecroticAura = true end
-- Fury of Ages: FURY becomes near-permanent (+8 str, +20% balance) at the cost of
-- quadrupled endurance; the basher holds it on while EP allows.
if matches[2]:lower():find("fury of ages") then infFuryOfAges = true end
-- Winter's Heart: DEEPFREEZE works on denizens and hits the whole room with cold;
-- cast at 2+ denizens (eq cast, so it rides free on balance-attack classes).
if matches[2]:lower():find("winter's heart") or matches[2]:lower():find("winters heart") then mnemWintersHeart = true end
-- Resourceful: -10% endurance/willpower costs, and each denizen kill restores 10% of the
-- class resource (life essence for Infernal) -- which makes Tyranny effectively free, so
-- the basher summons gravehands in every room with a denizen.
if matches[2]:lower():find("resourceful") then mnemResourceful = true end
