----------------------------------------
-- custom sensors configuration file
----------------------------------------
--[[
S1:Pump,A4,2,V,1,+,1,
S2:Fuel,Fuel,0,ml,1,+,1,
S3:ENG,RPM,0,krpm,100,+,1,
S4:EGT,Tmp1,0,C,1,+,1,
S5:THRO,Thro,0,%,1,+,1,
S6:Status,Tmp2,0,C,1,-,1
--]]
local sensors = {
  -- Sensor 1
  {
    "Pump",   -- label
    "A4",     -- OpenTX sensor name
    2,          -- precision: number of decimals 0,1,2
    "V",         -- label for unit of measure
    1,          -- multiplier if < 1 than divides
    "+",        -- "+" track max values, "-" track min values with
    1,          -- font size 1=small, 2=big
    5,        -- warning level (nil is do not use feature)
    10,        -- critical level (nil is do not use feature)
  },

  -- Sensor 2
  {
    "Fuel", -- label
    "Fuel", -- OpenTX sensor name
    0,      -- precision: number of decimals 0,1,2
    "mL",   -- label for unit of measure
    1,      -- multiplier if < 1 than divides
    "+",    -- "+" track max values, "-" track min values
    1,      -- font size 1=small, 2=big
    1000,     -- warning level
    2000,     -- critical level
  },

  -- Sensor 3
  {
    "ENG",    -- label
    "RPM",    -- OpenTX sensor name
    2,        -- precision: number of decimals 0,1,2
    "krpm",   -- label for unit of measure
    0.001,    -- multiplier if < 1 than divides
    "+",      -- "+" track max values, "-" track min values with
    2,        -- font size 1=small, 2=big
    1000,     -- warning level
    2000,     -- critical value
  },

  -- Sensor 4
  {
    "EGT", -- label
    "Tmp1", -- OpenTX sensor name
    0,      -- precision: number of decimals 0,1,2
    "C",   -- label for unit of measure
    1,      -- multiplier if < 1 than divides
    "+",    -- "+" track max values, "-" track min values with
    2,      -- font size 1=small, 2=big
    100,     -- warning level
    200,     -- critical level
  },

  -- Sensor 5
  {
    "THRO", -- label
    "Thro", -- OpenTX sensor name
    0,      -- precision: number of decimals 0,1,2
    "%",   -- label for unit of measure
    1,      -- multiplier if < 1 than divides
    "+",    -- "+" track max values, "-" track min values with
    2,      -- font size 1=small, 2=big
    90,     -- warning level
    100,     -- critical level
  },

  -- Sensor 6
  {
    "Status", -- label
    "Tmp2", -- OpenTX sensor name
    0,      -- precision: number of decimals 0,1,2
    "",   -- label for unit of measure
    1,      -- multiplier if < 1 than divides
    "+",    -- "+" track max values, "-" track min values with
    2,      -- font size 1=small, 2=big
    100,     -- warning level
    100,     -- critical level
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
}

collectgarbage()

return {
  sensors=sensors,lookups=lookups
}