--[[mudlet
type: alias
name: Reload
hierarchy:
- Levi_Ataxia
- For Levi
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^rrr$
command: ''
packageName: ''
]]--

-- NOTE: Old dofile() reload removed. Use the build pipeline:
-- python tools/mudlet_build.py --src ./src_new --output packages/Levi_Ataxia.xml
-- Then reinstall the package in Mudlet.