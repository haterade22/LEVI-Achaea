--[[mudlet
type: alias
name: Darkshade
hierarchy:
- Levi_Ataxia
- Classes
- Serpent
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^sn$
command: ''
packageName: ''
]]--

-- `sn`: the darkshade offence, as `vv` sends it on a Serpent (153_Fourth_Attack). This called
-- serpent_darkshade(), which nothing defines since the old Ekanelia offence went (commit
-- 28b9689e), so every press threw and sent nothing (2026-11-08 review, F34).
serp_setmode_darkshade()
serp_ekanelia_offense()
