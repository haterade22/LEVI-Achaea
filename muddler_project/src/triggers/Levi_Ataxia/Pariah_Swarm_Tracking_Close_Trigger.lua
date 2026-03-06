setTriggerStayOpen("Swarm Tracking", 0)

if pariah.burrow then
  tAffs.burrow = true
  if applyAffV3 then applyAffV3("burrow") end
end