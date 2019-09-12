--
-- An FRSKY S.Port <passthrough protocol> based Telemetry script for the Horus X10 and X12 radios
--
-- Copyright (C) 2018-2019. Alessandro Apostoli
-- https://github.com/yaapu
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

---------------------
-- MAIN CONFIG
-- 480x272 LCD_W x LCD_H
---------------------

---------------------
-- VERSION
---------------------
-- load and compile of lua files
-- uncomment to force compile of all chunks, comment for release
--#define COMPILE
-- fix for issue OpenTX 2.2.1 on X10/X10S - https://github.com/opentx/opentx/issues/5764

---------------------
-- FEATURE CONFIG
---------------------
-- enable splash screen for no telemetry data
--#define SPLASH
-- enable battery percentage based on voltage
--#define BATTPERC_BY_VOLTAGE
-- enable code to draw a compass rose vs a compass ribbon
--#define COMPASS_ROSE
-- enable support for FNV hash based sound files

---------------------
-- DEV FEATURE CONFIG
---------------------
-- enable memory debuging 
--#define MEMDEBUG
-- enable dev code
--#define DEV
-- uncomment haversine calculation routine
--#define HAVERSINE
-- enable telemetry logging to file (experimental)
--#define LOGTELEMETRY
-- use radio channels imputs to generate fake telemetry data
--#define TESTMODE
-- enable debug of generated hash or short hash string
--#define HASHDEBUG

---------------------
-- DEBUG REFRESH RATES
---------------------
-- calc and show hud refresh rate
--#define HUDRATE
-- calc and show telemetry process rate
--#define BGTELERATE

---------------------
-- SENSOR IDS
---------------------
















-- Throttle and RC use RPM sensor IDs

---------------------
-- BATTERY DEFAULTS
---------------------
---------------------------------
-- BACKLIGHT SUPPORT
-- GV is zero based, GV 8 = GV 9 in OpenTX
---------------------------------
---------------------------------
-- CONF REFRESH GV
---------------------------------

---------------------------------
-- ALARMS
---------------------------------
--[[
 ALARM_TYPE_MIN needs arming (min has to be reached first), value below level for grace, once armed is periodic, reset on landing
 ALARM_TYPE_MAX no arming, value above level for grace, once armed is periodic, reset on landing
 ALARM_TYPE_TIMER no arming, fired periodically, spoken time, reset on landing
 ALARM_TYPE_BATT needs arming (min has to be reached first), value below level for grace, no reset on landing
{ 
  1 = notified, 
  2 = alarm start, 
  3 = armed, 
  4 = type(0=min,1=max,2=timer,3=batt), 
  5 = grace duration
  6 = ready
  7 = last alarm
}  
--]]--
--
--

--

----------------------
-- COMMON LAYOUT
----------------------
-- enable vertical bars HUD drawing (same as taranis)
--#define HUD_ALGO1
-- enable optimized hor bars HUD drawing
--#define HUD_ALGO2
-- enable hor bars HUD drawing






--------------------------------------------------------------------------------
-- MENU VALUE,COMBO
--------------------------------------------------------------------------------

--------------------------
-- UNIT OF MEASURE
--------------------------
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"


-----------------------
-- BATTERY 
-----------------------
-- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1
-- 

-----------------------
-- LIBRARY LOADING
-----------------------

----------------------
--- COLORS
----------------------

--#define COLOR_LABEL 0x7BCF
--#define COLOR_BG 0x0169
--#define COLOR_BARSEX 0x10A3


--#define COLOR_SENSORS 0x0169

-----------------------------------
-- STATE TRANSITION ENGINE SUPPORT
-----------------------------------


--------------------------
-- CLIPPING ALGO DEFINES
--------------------------



















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
--]]local function drawPane(x,drawLib,conf,telemetry,status,alarms,battery,battId,gpsStatuses,utils)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)  
  local perc = 0
  if (battery[13+battId] > 0) then
    perc = (1 - (battery[10+battId]/battery[13+battId]))*100
    if perc > 99 then
      perc = 99
    elseif perc < 0 then
      perc = 0
    end
  end
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
  if battId < 2 then
    -- labels
    lcd.drawText(x+12, 154, "Eff(mAh)", SMLSIZE+CUSTOM_COLOR+RIGHT)
    lcd.drawText(x+95, 154, "Power(W)", SMLSIZE+CUSTOM_COLOR+RIGHT)
    -- data
    lcd.setColor(CUSTOM_COLOR,0xFFFF)
    local speed = utils.getMaxValue(telemetry.hSpeed,14)  
    -- efficiency for indipendent batteries makes sense only for battery 1
    local eff = speed > 2 and (conf.battConf == 3 and battery[7+1] or battery[7])*1000/(speed*conf.horSpeedMultiplier) or 0
    eff = ( conf.battConf == 3 and battId == 2) and 0 or eff
    lcd.drawNumber(x+12,164,eff,(eff > 99999 and 0 or MIDSIZE)+RIGHT+CUSTOM_COLOR)
    -- power
    local power = battery[4+battId]*battery[7+battId]*0.01
    lcd.drawNumber(x+95,164,power,MIDSIZE+RIGHT+CUSTOM_COLOR)
    --lcd.drawText(x+95,164,string.format("%dW",power),MIDSIZE+CUSTOM_COLOR)
  end
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+75+11, 16 + 8,false,true,utils)
    drawLib.drawVArrow(x+75+11,48 + 3, false,true,utils)
    drawLib.drawVArrow(x+75+11,68 + 10,true,false,utils)
  end
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawPane=drawPane,background=background}
