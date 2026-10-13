--[[mudlet
type: alias
name: Water Route
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Magi Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ww$
command: ''
packageName: ''
]]--

-- v4.7.421: Tabethys's Magi water route (magma, dehydrate, dehydrate, fulminate; the mudslide bonk;
-- emanate water, freeze until frozen, glaciate), mode "waterroute" in 004_Magi_Offense. A new key on
-- purpose: vv keeps "water", which runs the fire tree, and no other key changes. Same shape as cc.
if gmcp.Char.Status.class == "Magi" then
  magi.offense.setMode("waterroute")
  magi.offense.dispatch()
end
