--[[mudlet
type: alias
name: Season (Elixir|Poison)
hierarchy:
- Levi_Ataxia
- Artefacts
- LegendDeck
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^lsea$
command: ''
packageName: ''
]]--

-- The variant is a BARE argument. "legenddeck draw seasone FOR elixir" is rejected with
-- "You must draw that card for either ELIXIR or POISON." -- the "for" in that sentence is
-- English, not syntax (live 2026-07-31). Matches ldm.draw, which appends the argument bare.
send("clearqueue all;queue add eqbal legenddeck draw seasone elixir")