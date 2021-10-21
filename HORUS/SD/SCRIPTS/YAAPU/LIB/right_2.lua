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
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local perc = battery[16+battId]
  --  battery min cell
  local flags = 0
  --
  lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and alarms[8][2] > 0 then
      utils.drawBlinkBitmap("cell_red",x+41 - 2,13 + 7)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red"),x+41 - 2,13 + 7)
    elseif status.battLevel1 == false and alarms[7][2] > 0 then
      --lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
      utils.drawBlinkBitmap("cell_orange_blink",x+41 - 2,13 + 7)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange"),x+41 - 2,13 + 7)
      lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
    end
  end
  flags = CUSTOM_COLOR
  --PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if battery[1+battId] * 0.01 < 10 then
    lcd.drawNumber(x+41+2, 13, battery[1+battId] + 0.5, PREC2+XXLSIZE+flags)
  else
    lcd.drawNumber(x+41+2, 13, (battery[1+battId] + 0.5)*0.1, PREC1+XXLSIZE+flags)
  end

  --lcd.drawNumber(x+41+2, 13, battery[1+battId] + 0.5, XXLSIZE+flags)
  local lx = x+175
  lcd.drawText(lx, 23, "V", flags)
  lcd.drawText(lx, 58, status.battsource, flags)

  lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white
  -- battery voltage
  drawLib.drawNumberWithDim(x+105,79,x+103, 79, battery[4+battId],"V",DBLSIZE+PREC1+RIGHT+CUSTOM_COLOR,SMLSIZE+CUSTOM_COLOR)
  -- battery current
  drawLib.drawNumberWithDim(x+178,79,x+176,79,battery[7+battId]*(battery[7+battId] >= 100 and 0.1 or 1),"A",DBLSIZE+RIGHT+CUSTOM_COLOR+(battery[7+battId] >= 100 and 0 or PREC1),SMLSIZE+CUSTOM_COLOR)
  -- display capacity bar %
  if perc > 50 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 255, 0))
  elseif perc <= 50 and perc > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,0, 0))
  end
  lcd.drawBitmap(utils.getBitmap("gauge_bg"),x+43-2,117-2)
  lcd.drawGauge(x+43, 117,147,23,perc,100,CUSTOM_COLOR)
  -- battery percentage
  lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black

  local strperc = string.format("%02d%%",perc)
  lcd.drawText(x+98, 114, strperc, MIDSIZE+CUSTOM_COLOR)

  -- battery mah
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local strmah = string.format("%.02f/%.01f",battery[10+battId]/1000,battery[13+battId]/1000)
  lcd.drawText(x+183, 140+6, "Ah", RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+183 - 22, 140, strmah, MIDSIZE+RIGHT+CUSTOM_COLOR)

  lcd.setColor(CUSTOM_COLOR,utils.colors.darkgrey)
  local battLabel = "B1+B2"
  if battId == 0 then
    if conf.battConf ==  3 then
      -- alarms are based on battery 1
      battLabel = "B1"
    elseif conf.battConf ==  4 then
      -- alarms are based on battery 2
      battLabel = "B2"
    end
  else
    battLabel = (battId == 1 and "B1(Ah)" or "B2(Ah)")
  end

  lcd.drawText(x+190, 124, battLabel, SMLSIZE+CUSTOM_COLOR+RIGHT)

  if battId < 2 then
    -- RIGHT labels
    lcd.setColor(CUSTOM_COLOR,utils.colors.black)
    lcd.drawText(478, 165, "Eff(mAh)", SMLSIZE+RIGHT+CUSTOM_COLOR)
    lcd.drawText(395, 165, "Power(W)", SMLSIZE+CUSTOM_COLOR+RIGHT)
    --data
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    -- efficiency for indipendent batteries makes sense only for battery 1
    local speed = utils.getMaxValue(telemetry.hSpeed,14)
    local eff = speed > 2 and (conf.battConf == 3 and battery[7+1] or battery[7])*1000/(speed*conf.horSpeedMultiplier) or 0
    eff = ( conf.battConf == 3 and battId == 2) and 0 or eff
    lcd.drawNumber(478,178,eff,MIDSIZE+RIGHT+CUSTOM_COLOR)
    -- power
    local power = battery[4]*(conf.battConf == 3 and battery[7+1] or battery[7])*0.01
    lcd.drawNumber(395,178,power,MIDSIZE+RIGHT+CUSTOM_COLOR)
  end

  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+41+140, 13 + 27,false,true,utils)
    drawLib.drawVArrow(x+105+4,79 + 10, false,true,utils)
    drawLib.drawVArrow(x+178+3,79 + 10,true,false,utils)
  end
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawPane=drawPane,background=background}
