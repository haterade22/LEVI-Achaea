--Default will show like standard line of: [AFF] Attack line.
--Minimal will show without brackets as: AFF: Attack line.
--Bar will show a more spaced version as:  AFF| Attack Line.

--affconfig minimal
--affconfig bar
--affconfig default

--More possibly to come. Dunno!

--All possible example configurations.

  ataxia.settings.affhl = matches[2]
  ataxia_Echo("Changed highlighting of afflictions as such...")
  if matches[2] == "default" then    
    cecho("\n <maroon>[<red>PAR<maroon>] <reset>Your attack used goes here.")
  elseif matches[2] == "minimal" then
    cecho("\n <red>PAR: <reset>Your attack used goes here.")
  else
    cecho("\n <red> PAR| <reset>Your attack used goes here.")
  end


ataxia_saveSettings(false)