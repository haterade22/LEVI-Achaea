if (targreb == true or targshield == true) and tengage == false then
send("cq all|stand|unwield left|unwield right|wield left morningstar511732|wield right morningstar511735|hyena slay " ..target.. " |hellforge invest " ..hellf.. " |fracture " .. target.. " |engage " ..target.. " |assess " ..target)
elseif (targreb == true or targshield == true) and tengage == true then
send("cq all|stand|unwield left|unwield right|wield left morningstar511732|wield right morningstar511735|hyena slay " ..target.. " |hellforge invest " ..hellf.. " |fracture " .. target.. " |assess " ..target)

elseif tengage == false then
send("cq all|stand|wield left flail343168|wield right flail408566|hyena slay " ..target.. " |hellforge invest " ..hellf.. " |pulp " ..target.. " |engage " ..target)
elseif tengage == true then
send("cq all|stand|wield left flail343168|wield right flail408566|hyena slay " ..target.. " |hellforge invest " ..hellf.. " |pulp " ..target)
end
