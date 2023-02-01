-- battery % by voltage
-- you need to enable the relevant option in the widget config menu
-- supported on horus class radios only

local voltageDrop = 0.15
local useCellVoltage = false;

--[[
local dischargeCurve = { 
  {3.40,  0}, 
  {3.46, 10}, 
  {3.51, 20}, 
  {3.53, 30}, 
  {3.56, 40},
  {3.60, 50},
  {3.63, 60},
  {3.70, 70},
  {3.73, 80},
  {3.86, 90},
  {4.00, 99},
  }
--]]
local dischargeCurve = { 
  {3.40*6, 0}, 
  {3.46*6, 10}, 
  {3.51*6, 20}, 
  {3.53*6, 30}, 
  {3.56*6, 40},
  {3.60*6, 50},
  {3.63*6, 60},
  {3.70*6, 70},
  {3.73*6, 80},
  {3.86*6, 90},
  {4.00*6, 99},
  }

return {voltageDrop=voltageDrop,useCellVoltage=useCellVoltage,dischargeCurve=dischargeCurve}