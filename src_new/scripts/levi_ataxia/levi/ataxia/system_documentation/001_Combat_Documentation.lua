--[[mudlet
type: script
name: Combat Documentation
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- SYSTEM DOCUMENTATION
attributes:
  isActive: 'no'
  isFolder: 'no'
packageName: ''
]]--

--[[
  For the sake of reducing questions, this script is going to contain variables specific to combat that can be utilised in your scripts and what not.
  As Pariah is quite a tall task, compared to previous classes, this is the class I'll be working on first.
  If you play a different class, let me know and I can work on adding yours here as well in a future update.
 
  -BARD-
  
  ataxiaTemp.rapierJab          - Stores how much % your rapier does (only after assessing).
  ataxia.bardStuff.tunesmith    - Stores what your current tunesmith is set to.
  ataxiaTemp.tvBal              - Whether or not you've used tremolo/vibrato bal.
                                  this will be true if so, otherwise nil.

  --MONK-
  ataxiaTemp.hyperLimb          - Stores which limb you're hyperfocussing, if Shikudo.
  tekura_limbDamage
  shikudo_limbDamage            - Stores limb damage depending on your spec.
  
  -PARIAH-
  ***CURRENTLY NO TRACKING OF YOUR SWARMS***
  ***UNTIL THEY'RE DONE FIXING RELEASE ISSUES I WONT BE ADDING THIS***
  
  
  pariah_canVirulence()         - These two functions work in tandem, the first checks if 3 plagues are present
  pariah_doVirulence()            the second checks the 4th needed to lock with.
  
  pariah_canGraph("xxx")        - will return true if you can use the specific logograph.
                                - eg: pariah_canGraph("nest") will return true if you used serpent last
  pariah.bladePrepared          - will track if you have blood on your blade. THIS RESETS ON TARGET CHANGE.
                                - also clears on transpose, and the 'blood used up' lines as well.
                                  
  pariah.lastLogograph          - kind of speaks for itself, really.
  ataxia.vitals.epitaph         - tracks your current epitaph length.
  tAffs.burrow                  - will track if you have burrow active. Clears on infest/extract usage.
                                - I strongly suggest reading how burrow works, as well.
                                - while the affliction will clear on target change, you still need to recall your swarm.
                                  
  pariah.latency                - if this is active, it means you used latency recently.
  pariah.ensorcell              - another one that speaks for itself.
  pariah.infest                 - active when infest is up.
]]