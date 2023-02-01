local prefixHashes = {
  --[[
    max prefix length:
    hashes longer than maxLength will not be searched in the hash map
    longer hashes have precedence over shorter hashes, i.e. a prefix hash is
    looked up in the map up until maxLength overwriting status.shortHash
  --]]
  maxLength = 16
}

--[[
    OPTIONS
    true|false,   -- match pattern
    prefix,       -- extra soundfile prefix, used in conjuction with extraGroup and paramGroup
    regex,        -- define max 3 groups
    paramGroup=x  -- index of the param group [1|2|3], will be played as number and also appended to [prefix] and played as soundfile
    suffixGroup=y -- index of the suffix sound file [1|2|3] will be played as soundfile
    extraGroup=z  -- index of the group used for the lookup in the extraMap table, if found the matching value is appended to prefix and played as soundfile
--]]
-- size 5
--shortHashes[158533322] = { true, "trk_", "^.* (%d+) (%a+) %((.*)%).*", paramGroup=1, suffixGroup=2, extraGroup=3 } -- prefixLength size=5, Trick prefixLength
prefixHashes[158533322] = { true, "trk_", "^.* (%d+) (selected) %((.*)%).*", paramGroup=1, suffixGroup=2, extraGroup=3 } -- prefixLength size=5, Trick prefixLength
-- size 12
prefixHashes[121896728] = { false } -- prefixLength size=12, trick aborted
-- size 16
prefixHashes[3351294456] = { false } -- prefixLength size=16, Soaring: Outside MAX RADIUS, RTL
prefixHashes[3538212740] = { false } -- prefixLength size=16, Soaring: restoring previous mode
prefixHashes[142400872] = { false } -- prefixLength size=16, Soaring: Climb below VERTICAL SPEED
prefixHashes[1746499976] = { false } -- prefixLength size=16, Soaring: Exit via RC switch
prefixHashes[981284144] = { false } -- prefixLength size=16, Soaring: Thermal detected
prefixHashes[883458048] = { false } -- prefixLength size=16, Soaring: Enabled
prefixHashes[2561543032] = { false } -- prefixLength size=16, Soaring: Disabled
prefixHashes[4091124880] = { true, nil, "^.* #(%d+).*", paramGroup=1} -- prefixLength size=16, reached command:
prefixHashes[3311875476] = { true, nil, "^.* #(%d+).*", paramGroup=1} -- prefixLength size=16, reached waypoint:
prefixHashes[1997782032] = { true, nil, "^.* #(%d+).*", paramGroup=1} -- prefixLength size=16, Passed waypoint:
prefixHashes[554623408] = { false } -- prefixLength size=16, Takeoff complete
prefixHashes[3025044912] = { false } -- prefixLength size=16, Smart RTL deactivated
prefixHashes[3956583920] = { false } -- prefixLength size=16, GPS home acquired
prefixHashes[1309405592] = { false } -- prefixLength size=16, GPS home acquired

--
prefixHashes.extraMap = {
  -- plane aerobatics
  ["Figure Eight"] = "fig8",
  ["Loop"] = "loop",
  ["Horizontal Rectangle"] = "horrec",
  ["Climbing Circle"] = "clicir",
  ["Vertical Box"] = "verbox",
  ["Immelmann Fast"] = "immfas",
  ["Axial Roll"] = "axirol",
  ["Rolling Circle"] = "rolcir",
  ["Half Cuban Eight"] = "hcu8",
  ["Half Reverse Cuban Eight"] = "hrvcu8",
  ["Cuban Eight"] = "cu8",
  ["Humpty Bump"] = "hubu",
  ["Straight Flight"] = "strfli",
  ["Scale Figure Eight"] = "scfig8",
  ["Immelmann Turn"] = "immtrn",
  ["Split-S"] = "splts",
  ["Upline-45"] = "up45",
  ["Downline-45"] = "dw45",
  ["Stall Turn"] = "statrn",
  ["Procedure Turn"] = "prctrn",
  ["Half Climbing Circle"] = "hfclci",
  ["Laydown Humpty"] = "layhu",
  ["Barrel Roll"] = "barrol",
  ["Straight Hold"] = "strhol",
  ["Partial Circle"] = "parcir",
  ["Multi Point Roll"] = "mproll",
  ["Side Step"] = "sstep",
  -- schedules
  ["SuperAirShow"] = "sashow",
  ["F3AF23"] = "f34f23",
  ["F3AF25"] = "f3af25",
  ["F3AP23"] = "f3ap23",
  ["F3AP25"] = "f3ap25",
  ["F4CScaleExampleSchedule"] = "f4css",
  ["NZClubmanSchedule"] = "nzclub",
  ["Sport_Plane_AirShow"] = "spshow",
  ["StallTurnTest"] = "sttest",
  -- rate based
  ["Roll(s)"] = "roll",
  ["Loop(s)/Turnaround"] = "lotrn",
  ["Rolling Circle"] = "rolcir",
  ["Knife-Edge"] = "kniedg",
  ["Pause"] = "pause",
  ["Knife Edge Circle"] = "kniedc",
  ["4pt Roll"] = "4ptrol",
  ["Split-S"] = "splits",
}

return prefixHashes
