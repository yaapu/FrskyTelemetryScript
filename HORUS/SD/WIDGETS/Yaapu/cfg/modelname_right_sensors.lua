----------------------------------------
-- custom sensors configuration file
-- this will be used by the right panel custom sensor layout
-- 5 sensors supported
----------------------------------------

local sensors = {
  -- Sensor 1
[1]=  {
    "Batt",   -- label
    "VFAS",     -- OpenTX sensor name
    2,          -- precision: number of decimals 0,1,2
    "V",         -- label for unit of measure
    1,          -- multiplier if < 1 than divides
    "+",        -- "+" track max values, "-" track min values with
    2,          -- font size 1=small, 2=big
    5,        -- warning level (nil is do not use feature)
    10,        -- critical level (nil is do not use feature)
  },

  -- Sensor 2
[2]=  {
    "Curr", -- label
    "CURR", -- OpenTX sensor name
    1,      -- precision: number of decimals 0,1,2
    "A",   -- label for unit of measure
    1,      -- multiplier if < 1 than divides
    "+",    -- "+" track max values, "-" track min values with
    2,      -- font size 1=small, 2=big
    100,     -- warning level
    200,     -- critical level
  },

  -- Sensor 3
[3]=  {
    "Fuel", -- label
    "Fuel", -- OpenTX sensor name
    0,      -- precision: number of decimals 0,1,2
    "%",    -- label for unit of measure
    1,      -- multiplier if < 1 than divides
    "-",    -- "+" track max values, "-" track min values
    1,      -- font size 1=small, 2=big
    50,     -- warning level
    25,     -- critical level
    true,   -- render as gauge
    60,     -- gauge width
    20,     -- gauge height
    0,      -- gauge min value
    100     -- gauge max value
  },

  -- Sensor 4
[4]=  {
    "ENG",    -- label
    "RPM1",    -- OpenTX sensor name
    0,        -- precision: number of decimals 0,1,2
    "rpm",   -- label for unit of measure
    1,    -- multiplier if < 1 than divides
    "+",      -- "+" track max values, "-" track min values with
    1,        -- font size 1=small, 2=big
    2500,     -- warning level
    4000,     -- critical value
  },

  -- Sensor 5
[5]=  {
    "THR", -- label
    "Thr", -- OpenTX sensor name
    0,      -- precision: number of decimals 0,1,2
    "%",   -- label for unit of measure
    1,      -- multiplier if < 1 than divides
    "+",    -- "+" track max values, "-" track min values with
    2,      -- font size 1=small, 2=big
    30,     -- warning level
    50,     -- critical level
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
  [5] = {
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