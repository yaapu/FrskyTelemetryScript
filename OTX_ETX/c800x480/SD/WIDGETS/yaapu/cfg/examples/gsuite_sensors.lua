----------------------------------------
-- custom sensors configuration file
----------------------------------------
--[[
GRPc - residual percent
GFlo - flow mL/min
GMFl - max flow mL/min
GAFl - avg flow mL/min
GTp1 - temp 1 C°
GTp2 - temp 2 C°
GRPM - RPM

--]]
local sensors = {
  -- Sensor 1
[1]=  {
    "Eng",   -- label
    "GRPM",     -- OpenTX sensor name
    0,          -- precision: number of decimals 0,1,2
    "rpm",      -- label for unit of measure
    1,          -- multiplier if < 1 than divides
    "+",        -- "+" track max values, "-" track min values with
    2,          -- font size 1=small, 2=big
    nil,        -- warning level (nil is do not use feature)
    nil,        -- critical level (nil is do not use feature)
  },
  -- Sensor 2
[2]=  {
    "Temp1",   -- label
    "GTp1",     -- OpenTX sensor name
    0,          -- precision: number of decimals 0,1,2
    "C",         -- label for unit of measure
    1,          -- multiplier if < 1 than divides
    "+",        -- "+" track max values, "-" track min values with
    2,          -- font size 1=small, 2=big
    nil,        -- warning level (nil is do not use feature)
    nil,        -- critical level (nil is do not use feature)
  },

  -- Sensor 3
[3]=  {
    "Temp2",   -- label
    "GTp2",     -- OpenTX sensor name
    0,          -- precision: number of decimals 0,1,2
    "C",         -- label for unit of measure
    1,          -- multiplier if < 1 than divides
    "+",        -- "+" track max values, "-" track min values with
    2,          -- font size 1=small, 2=big
    nil,        -- warning level (nil is do not use feature)
    nil,        -- critical level (nil is do not use feature)
  },

  -- Sensor 4
[4]=  {
    "Flow",   -- label
    "GFlo",     -- OpenTX sensor name
    0,          -- precision: number of decimals 0,1,2
    "mL",   -- label for unit of measure
    1,          -- multiplier if < 1 than divides
    "+",        -- "+" track max values, "-" track min values with
    2,          -- font size 1=small, 2=big
    nil,        -- warning level (nil is do not use feature)
    nil,        -- critical level (nil is do not use feature)
  },

  -- Sensor 5
[5]=  {
    "AFlow",   -- label
    "GAFl",     -- OpenTX sensor name
    0,          -- precision: number of decimals 0,1,2
    "mL",   -- label for unit of measure
    1,          -- multiplier if < 1 than divides
    "+",        -- "+" track max values, "-" track min values with
    2,          -- font size 1=small, 2=big
    nil,        -- warning level (nil is do not use feature)
    nil,        -- critical level (nil is do not use feature)
  },

  -- Sensor 6
[6]=  {
    "Fuel",   -- label
    "GRpc",     -- OpenTX sensor name
    0,          -- precision: number of decimals 0,1,2
    "%",        -- label for unit of measure
    1,          -- multiplier if < 1 than divides
    "-",        -- "+" track max values, "-" track min values with
    2,          -- font size 1=small, 2=big
    nil,        -- warning level (nil is do not use feature)
    nil,        -- critical level (nil is do not use feature)
  },
}
------------------------------------------------------
-- the script can optionally look up values here
-- for each sensor and display the corresponding text instead
-- as an example to associate a lookup table to sensor 3 declare it like
--
-- [3] = {
--   [-10] = "ERR",
--   [0] = "OK",
--   [10] = "CRIT",
-- }
-- this would display the sensor value except when the value corresponds to one
-- of entered above
-- 
local lookups = {
  -- lookup 2
  --[[
  [6] = {
      [-30] = "ERROR",
      [-20] = "OFF",
      [-10] = "COOL",
      [-1] = "LOCK",
      [0] = "STOP",
      [10] = "RUN",
      [20] = "REL",
      [25] = "GLOW",
      [30] = "SPIN",
      [40] = "FIRE",
      [45] = "IGNT",
      [50] = "HEAT",
      [60] = "ACCE",
      [65] = "CAL",
      [70] = "IDLE",
  },
  --]]
}

collectgarbage()

return {
  sensors=sensors,lookups=lookups
}