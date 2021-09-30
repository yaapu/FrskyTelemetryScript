--
-- A FRSKY SPort/FPort/FPort2 and TBS CRSF telemetry widget for the Horus class radios
-- based on ArduPilot's passthrough telemetry protocol
--
-- Author: Alessandro Apostoli, https://github.com/yaapu
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY, without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, see <http://www.gnu.org/licenses>.
--
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"

--[[
  Example data based on a 18 minutes flight for quad, battery:5200mAh LiPO 10C, hover @15A
  Notes:
  - when motors are armed VOLTAGE_DROP offset is applied!
  - number of samples is fixed at 11 but percentage values can be anything and are not restricted to multiples of 10
  - voltage between samples is assumed to be linear
--]]
local battPercByVoltage = {
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
  {4.00, 99}
  }

function getBattPercByCell(cellVoltage)
  if cellVoltage == 0 then
    return 99
  end
  if cellVoltage >= battPercByVoltage[11][1] then
    return 99
  end
  if cellVoltage <= battPercByVoltage[1][1] then
    return 0
  end
  for i=2,11 do
    if cellVoltage <= battPercByVoltage[i][1] then
      --
      local v0 = battPercByVoltage[i-1][1]
      local fv0 = battPercByVoltage[i-1][2]
      --
      local v1 = battPercByVoltage[i][1]
      local fv1 = battPercByVoltage[i][2]
      -- interpolation polinomial
      return fv0 + ((fv1 - fv0)/(v1-v0))*(cellVoltage - v0)
    end
  end --for
end

-- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1
--[[
BATT_CELL 1
BATT_VOLT 4
BATT_CURR 7
BATT_MAH 10
BATT_CAP 13

BATT_IDALL 0
BATT_ID1 1
BATT_ID2 2
--]]
local function drawPane(x,drawLib,conf,telemetry,status,alarms,battery,battId,utils)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  local perc = 99
  if conf.enableBattPercByVoltage == true then
    --[[
      discharge curve is based on battery under load, when motors are disarmed
      cellvoltage needs to be corrected by subtracting the "under load" voltage drop
    --]]
    if telemetry.statusArmed then
      perc = getBattPercByCell(0.01*battery[1+battId])
    else
      perc = getBattPercByCell((0.01*battery[1+battId])-0.15)
    end
  else
  perc = battery[16+battId]
  end --conf.enableBattPercByVoltage
  --  battery min cell
  local flags = 0
  --
  lcd.setColor(CUSTOM_COLOR,0xFFFF) -- white
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and alarms[8][2] > 0 then
      utils.drawBlinkBitmap("cell_red_blink_86x30",x+7,20)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red_86x30"),x+7,20)
    elseif status.battLevel1 == false and alarms[7][2] > 0 then
      --lcd.setColor(CUSTOM_COLOR,0x0000) -- black
      utils.drawBlinkBitmap("cell_orange_blink_86x30",x+7,20)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange_86x30"),x+7,20)
      lcd.setColor(CUSTOM_COLOR,0x0000) -- black
    end
  end
  flags = CUSTOM_COLOR
  --PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if battery[1+battId] * 0.01 < 10 then
    lcd.drawNumber(x+75+2, 16, battery[1+battId] + 0.5, PREC2+DBLSIZE+RIGHT+flags)
  else
    lcd.drawNumber(x+75+2, 16, (battery[1+battId] + 0.5)*0.1, PREC1+DBLSIZE+RIGHT+flags)
  end

  local lx = x+76
  lcd.drawText(lx, 32, "V", flags)
  lcd.drawText(lx, 18, status.battsource, flags)

  lcd.setColor(CUSTOM_COLOR,0xFFFF) -- white
  -- battery voltage
  drawLib.drawNumberWithDim(x+75,48,x+75, 58, battery[4+battId],"V",RIGHT+MIDSIZE+PREC1+CUSTOM_COLOR,SMLSIZE+CUSTOM_COLOR)
  -- battery current
  local lowAmp = battery[7+battId]*0.1 < 10
  drawLib.drawNumberWithDim(x+75,68,x+76,83,battery[7+battId]*(lowAmp and 1 or 0.1),"A",DBLSIZE+RIGHT+CUSTOM_COLOR+(lowAmp and PREC1 or 0),0+CUSTOM_COLOR)
  -- display capacity bar %
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,255, 255))
  lcd.drawFilledRectangle(x+10, 105,80,21,CUSTOM_COLOR)
  if perc > 50 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 255, 0))
  elseif perc <= 50 and perc > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,0, 0))
  end
  lcd.drawGauge(x+10, 105,80,21,perc,100,CUSTOM_COLOR)
  -- battery percentage
  lcd.setColor(CUSTOM_COLOR,0x0000) -- black

  local strperc = string.format("%02d%%",perc)
  lcd.drawText(x+35, 101, strperc, MIDSIZE+CUSTOM_COLOR)

  -- battery mah
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  local strmah = string.format("%.02f/%.01f",battery[10+battId]/1000,battery[13+battId]/1000)
  --lcd.drawText(x+90, 138+2, "Ah", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+90, 138, strmah, 0+RIGHT+CUSTOM_COLOR)

  lcd.setColor(CUSTOM_COLOR,0x0000)
  lcd.drawText(x+90,126,battId == 0 and "B1+B2(Ah)" or (battId == 1 and "B1(Ah)" or "B2(Ah)"),SMLSIZE+RIGHT+CUSTOM_COLOR)

  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+75+11, 16 + 8,false,true,utils)
    drawLib.drawVArrow(x+75+11,48 + 3, false,true,utils)
    drawLib.drawVArrow(x+75+11,68 + 10,true,false,utils)
  end
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawPane=drawPane,background=background}
