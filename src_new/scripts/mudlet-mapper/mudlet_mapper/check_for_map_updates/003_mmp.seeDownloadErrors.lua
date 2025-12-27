--[[mudlet
type: script
name: mmp.seeDownloadErrors
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Check for map updates
attributes:
  isActive: 'no'
  isFolder: 'no'
packageName: ''
eventHandlers:
- sysDownloadError
]]--

-- this should be off by default
function mmp.seeDownloadErrors(...)
  display{...}
end