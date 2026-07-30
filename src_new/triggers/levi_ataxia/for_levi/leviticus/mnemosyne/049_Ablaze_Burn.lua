--[[mudlet
type: trigger
name: Mnemosyne Ablaze Burn
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Mnemosyne
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^The roaring inferno engulfs you as you fight to find a way out\.$
  type: 1
]]--

--[[
    A BURNING ROOM (live 2026-07-30). The room description carries "The area is
    ablaze!" and the ground then burns for ~700-880 every few seconds for as long as
    we stand in it -- roughly 6% of max HP per tick, indefinitely, on top of whatever
    the denizens are doing.

    We latch on the BURN LINE, not on the room description. Two reasons: the room text
    arrives mid-line ("The sky darkens with the onset of night. The area is ablaze!"),
    and more importantly the burn line is the thing that proves the fire is still
    hurting US -- it self-expires when we leave, with no "the fire goes out" line
    needed (we have never captured one).

    Read by the swarm low-HP escape ladder: its outdoor branch flies up and HOVERS
    until fully healed, which is a good plan in a normal room and a bad one over a
    fire, since the burn follows and eats the regeneration. There is a documented
    precedent -- the Blazing affix smokes hovering flyers for ~511 asphyxiation every
    5s and the hover was judged to out-heal THAT. This is a different, larger number
    against the same mechanism, so the ladder now prefers the grounded retreat while
    the ground burns.
]]--

if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onAblazeBurn then
	ataxia.mnemosyne.onAblazeBurn()
end
