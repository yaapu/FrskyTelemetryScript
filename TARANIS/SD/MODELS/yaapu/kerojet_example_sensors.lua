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
[1]=  {
    "Celm",   -- label
    "Celm",     -- OpenTX sensor name
    2,          -- precision: number of decimals 0,1,2
    "Vmin",         -- label for unit of measure
    1,          -- multiplier if < 1 than divides
    "-",        -- "+" track max values, "-" track min values with
    1,          -- font size 1=small, 2=big
    3.65,        -- warning level (nil is do not use feature)
    3.30,        -- critical level (nil is do not use feature)
  },

  -- Sensor 2
[2]=  {
    "Celd",   -- label
    "Celd",     -- OpenTX sensor name
    2,          -- precision: number of decimals 0,1,2
    "Vdelta",         -- label for unit of measure
    1,          -- multiplier if < 1 than divides
    "+",        -- "+" track max values, "-" track min values with
    1,          -- font size 1=small, 2=big
    0.2,        -- warning level (nil is do not use feature)
    0.4,        -- critical level (nil is do not use feature)
  },

  -- Sensor 3
[3]=  {
    "Cel1",   -- label
    "Cel1",     -- OpenTX sensor name
    2,          -- precision: number of decimals 0,1,2
    "V1",         -- label for unit of measure
    1,          -- multiplier if < 1 than divides
    "-",        -- "+" track max values, "-" track min values with
    2,          -- font size 1=small, 2=big
    3.65,        -- warning level (nil is do not use feature)
    3.30,        -- critical level (nil is do not use feature)
  },

  -- Sensor 4
[4]=  {
    "Cel2",   -- label
    "Cel2",     -- OpenTX sensor name
    2,          -- precision: number of decimals 0,1,2
    "V2",         -- label for unit of measure
    1,          -- multiplier if < 1 than divides
    "-",        -- "+" track max values, "-" track min values with
    2,          -- font size 1=small, 2=big
    3.65,        -- warning level (nil is do not use feature)
    3.30,        -- critical level (nil is do not use feature)
  },

  -- Sensor 5
[5]=  {
    "Cel3",   -- label
    "Cel3",     -- OpenTX sensor name
    2,          -- precision: number of decimals 0,1,2
    "V3",         -- label for unit of measure
    1,          -- multiplier if < 1 than divides
    "-",        -- "+" track max values, "-" track min values with
    2,          -- font size 1=small, 2=big
    3.65,        -- warning level (nil is do not use feature)
    3.30,        -- critical level (nil is do not use feature)
  },

  -- Sensor 6
[6]=  {
    "Cel4",   -- label
    "Cel4",     -- OpenTX sensor name
    2,          -- precision: number of decimals 0,1,2
    "V4",         -- label for unit of measure
    1,          -- multiplier if < 1 than divides
    "-",        -- "+" track max values, "-" track min values with
    2,          -- font size 1=small, 2=big
    3.65,        -- warning level (nil is do not use feature)
    3.30,        -- critical level (nil is do not use feature)
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