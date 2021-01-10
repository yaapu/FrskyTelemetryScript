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
-- enable code to draw a compass rose vs a compass ribbon
--#define COMPASS_ROSE

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
-- enable MESSAGES DEBUG
--#define DEBUG_MESSAGES
---------------------
-- DEBUG REFRESH RATES
---------------------
-- calc and show hud refresh rate
--#define HUDRATE
-- calc and show telemetry process rate
-- #define BGTELERATE

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

--
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
-- enable hor bars HUD drawing, 2 px resolution
-- enable hor bars HUD drawing, 1 px resolution
--#define HUD_ALGO4






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
--]]

--[[ 
    On hybrid vehicle we have voltage and current from battery 1, mah from battery 2
--]]
local function drawPane(x,drawLib,conf,telemetry,status,alarms,battery,battId,gpsStatuses,utils)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)  
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
  -- PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if battery[1+1] * 0.01 < 10 then
    lcd.drawNumber(x+75+2, 16, battery[1+1] + 0.5, PREC2+DBLSIZE+RIGHT+flags)
  else
    lcd.drawNumber(x+75+2, 16, (battery[1+1] + 0.5)*0.1, PREC1+DBLSIZE+RIGHT+flags)
  end
  
  local lx = x+76
  lcd.drawText(lx, 32, "V", flags)
  lcd.drawText(lx, 18, status.battsource, flags)
  
  lcd.setColor(CUSTOM_COLOR,0xFFFF) -- white  
  -- battery current
  local lowAmp = battery[7+1]*0.1 < 10
  drawLib.drawNumberWithDim(x+75,68+86,x+76,83+86,battery[7+1]*(lowAmp and 1 or 0.1),"A",DBLSIZE+RIGHT+CUSTOM_COLOR+(lowAmp and PREC1 or 0),0+CUSTOM_COLOR)
  --[[
  -- display capacity bar %
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,255, 255))
  lcd.drawFilledRectangle(x+BATTGAUGE_X, BATTGAUGE_Y,BATTGAUGE_WIDTH,BATTGAUGE_HEIGHT,CUSTOM_COLOR)
  if perc > 50 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 255, 0))
  elseif perc <= 50 and perc > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,0, 0))
  end
  lcd.drawGauge(x+BATTGAUGE_X, BATTGAUGE_Y,BATTGAUGE_WIDTH,BATTGAUGE_HEIGHT,perc,100,CUSTOM_COLOR)
  --]]
  -- battery percentage
  --[[
  lcd.setColor(CUSTOM_COLOR,COLOR_BLACK) -- black
  
  local strperc = string.format("%02d%%",perc)
  lcd.drawText(x+BATTPERC_X, BATTPERC_Y, strperc, BATTPERC_FLAGS+CUSTOM_COLOR)
  --]]
  
  -- battery mah is from battery 2
  -- we display remaining liters vs used liters as usual
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  local strmah = string.format("%.01fL/%.01fL",(battery[13+2]-battery[10+2])/1000,battery[13+2]/1000)
  lcd.drawText(x+90, 133, strmah, 0+RIGHT+CUSTOM_COLOR)
  -- fuel gauge from battery 2
  -- battery % only from battery 2
  local perc = battery[16+2]
  
  lcd.setColor(CUSTOM_COLOR,0xF800)
  drawLib.drawGauge(393,54,"fuelgauge_75x75", 430, 94, 25, 8, perc, 125, CUSTOM_COLOR, utils)
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawPane=drawPane,background=background}
