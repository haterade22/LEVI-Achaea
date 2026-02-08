if ataxia.mountid ~= "urn/"..ataxiaTemp.me then
  ataxia.mountid = "urn/"..ataxiaTemp.me
  ataxiaEcho("Mount id has been updated to urn/"..ataxiaTemp.me..".")
end
  if not dontMount then
    send("curing mount "..ataxia.mountid,false)
  else
    send("queue addclear free order "..ataxia.mountid.." follow me")
  end
  
dontMount = nil