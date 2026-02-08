function levilogin()
enableV3()
sendGMCP('Core.Supports.Add ["Comm.Channel 1"]')
sendGMCP('Core.Supports.Add ["IRE.Target 1"]')
sendGMCP('Core.Supports.Add ["IRE.Time 1"]')
registerAnonymousEventHandler('gmcp.Char.Vitals', 'timerOnBalUsed')
registerAnonymousEventHandler('gmcp.Char.Vitals', 'timerOnEQUsed')
ataxiaToggle("on")
ataxia.defences = {}
ataxia.afflictions = {}
ataxia.vitals = {}
ataxiaTemp.class = gmcp.Char.Status.class
ataxiaTemp.me = gmcp.Char.Status.name
battleRage_Timers = {}
mmp.startup()
resetBashingStats()
ataxia_resetLimbTable()
load_Combat_Tables()
ataxia_createParry()
ataxiaCheckForMissing()
ataxia_precacheQueue()
populate_keepOut()
zgui.buildBashWindow()
tracklegenddeckcountreset()
ataxia_resetPariah()

tempTimer(5, [[ slc_reset();slc_force_display() ]])
tempTimer(7, [[ataxiaNDB.highlightNames = true;ataxiaNDB_loadHighlights()]])

ataxia.vitals.focusbal = true
tftracking = false
dwbparrying = false
dwbexpendtorso = false
DWBWhirlDamage = DWBWhirlDamage or 0

if parrying == nil then parrying = "randomleg" end
expandAlias("parry randomleg")
if ataxiaTemp.parriedLimb == nil then ataxiaTemp.parriedLimb = "none" end
tempTimer(10, [[send("queue add free get 50 ink from palette")]])
tempTimer(12, [[send("queue add inr all")]])

tempTimer(30, [[setafflictionstackslevi()]])
tempTimer(30, [[targetresetafflictionslevi()]])
tempTimer(15, [[send("queue add avoid physical")]])


slow = 0
shape = 0
tAffs = {blindness = true, deafness = true, shield = false, rebounding = false, curseward = false}
ataxia_Echo("Reset target afflictions.")
affcount = 0
can_enlighten = false
engaged = false
ataxiaTemp.parriedLimb = "none"
mindlocked = false
corrupted = false
truelock = false
softlock = false
hardlock = false
daeggerhunt = false
freshblood = false

pm = 100
php = 100
tAffs.bleed = 0
mindinvert = false
spiritinvert = false
bodyinvert = false
blast_count = 0
tburns = 0
wantmindlock = false
need_dwcempower = true
need_falcon = true
inc_imp = false
timpale = false
rtiwaz = false
haveshadow = false
mypreapply = false
bardperformance = false
bardtempo = false
tBals = {tree = true, focus = true, plant = true, salve = true, timers = {}, passive = true}
expandAlias("t Penwize")
tempTimer(14, [[send("queue add freestand wear armour")]])



if gmcp.Char.Status.class == "Depthswalker" then
	ataxia_depthswalkerReset()
  ataxia_depthswalkerReset()
  send("wield left scythe;wield right shield")
  send("queue add eq shadow cloak")
  
end

if gmcp.Char.Status.class == "Monk" then
if gmcp.Char.Vitals.charstats[4]:find("Stance") == 1 then
expandAlias("defswitch tek")
expandAlias("defup tek")
else
expandAlias("defswitch shi")
expandAlias("defup shi")
send("wield staff489282")
send("curingset switch normal")
end
end

if gmcp.Char.Status.class == "Psion" then
expandAlias("defswitch psion")
expandAlias("defup psion")
send("wield shield")
send("curingset switch normal")
end

if gmcp.Char.Status.class == "Bard" then
expandAlias("defswitch bard")
expandAlias("defup bard")
send("wield left rapier;wield right lyre")
send("compose paean sonata scherzo maqam prelude")
send("curingset switch normal")
end


if gmcp.Char.Status.class == "Apostate" then
expandAlias("defswitch apoo")
expandAlias("defup apoo")
send("wield right shield;summon baalzadeen;summon daegger")
send("curingset switch normal")
end

if gmcp.Char.Status.class == "Blademaster" then
expandAlias("defswitch bm")
expandAlias("defup bm")
send("unwield left;unwield right;sheathe blade")
send("curingset switch normal")
end

if gmcp.Char.Status.class == "Serpent" then
expandAlias("defswitch serp")
expandAlias("defup serp")
send("wield right dirk;wield left shield")
send("curingset switch normal")
end

if gmcp.Char.Status.class == "Runewarden" then
  if gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt" then 
    send("wield left morningstar511732; wield right morningstar511735")
    expandAlias("defswitch rdwb")
    expandAlias("defup rdwb")
  end

  if gmcp.Char.Vitals.charstats[3] == "Spec: Sword and Shield" then 
    send("wield left longsword;wield right shield")
    send("queue add free empower priority set isaz sleizak inguz")
    expandAlias("defswitch rdwc")
    expandAlias("defup rdwc")
    end

  if gmcp.Char.Vitals.charstats[3] == "Dual Cutting" then 
    send("wield left scimitar405398;wield right scimitar405403")
    send("empower priority set isaz sleizak kena")
    expandAlias("defswitch rdwc")
    expandAlias("defup rdwc")
  end


  if gmcp.Char.Vitals.charstats[3] == "Spec: Two Handed" then 
    send("wield bastard")
    send("empower priority set isaz sleizak tiwaz")
    expandAlias("defswitch rdwc")
    expandAlias("defup rdwc")
    end
send("falcon recall")
end

if ataxia_isClass("infernal") then
	if gmcp.Char.Vitals.charstats[4] == "Spec: Sword and Shield" then 
  send("wield left longsword;wield right shield")
  expandAlias("defswitch isnb")
  expandAlias("defup isnb")
  send("mastery on;hyena recall;order hyena follow me")
  end
  if gmcp.Char.Vitals.charstats[4] == "Spec: Dual Blunt" then 
    send("wield left morningstar511732; wield right morningstar511735")
    expandAlias("defswitch idwb")
    expandAlias("defup idwb")
  end
if gmcp.Char.Vitals.charstats[4] == "Spec: Dual Cutting" then 
    send("unwield left;unwield right;wield left scimitar405403; wield right scimitar405398")
    expandAlias("defswitch idwc")
    expandAlias("defup idwc")
end
if gmcp.Char.Vitals.charstats[4] == "Spec: Two Handed" then 
  send("wield bastard")
  expandAlias("defswitch i2h")
  expandAlias("defup i2h")
  send("hyena recall;order hyena follow me")
  end
  tempTimer(20, [[send("wear armour;hellforge channel relentless;hellforge channel conqueror")]])
  send("queue add freestand hyena recall")
end

if  gmcp.Char.Status.class == "earth Elemental Lord" then
expandAlias("defup earthlord")
tempTimer(20,[[send("terran tremorsense")]])
end
if ataxia_isClass("Silver Dragon") then
	expandAlias("defup dragon")
end
if ataxia_isClass("Blue Dragon") then
	expandAlias("defup dragon")
end
if ataxia_isClass("Golden Dragon") then
	expandAlias("defup dragon")
end
if ataxia_isClass("Red Dragon") then
	expandAlias("defup dragon")
end
if ataxia_isClass("Green Dragon") then
	expandAlias("defup dragon")
end
if ataxia_isClass("Black Dragon") then
	expandAlias("defup dragon")
end

if ataxia_isClass("Earth Lord") then
	expandAlias("defup earth")
end


sendGMCP("IRE.Rift.Request")

if ataxia.settings.autogallop then
	mmp.settings:setOption("gallop", false)
end




tempTimer(7, [[ sendAll("allies", "enemies") ]])

raiseEvent("logged in")

end