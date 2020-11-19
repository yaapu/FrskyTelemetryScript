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
local function drawPane(x,drawLib,conf,telemetry,status,alarms,battery,battId,gpsStatuses,utils)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)  
  local perc = 99
  if conf.enableBattPercByVoltage == true then
    --[[
      discharge curve is based on battery under load, when motors are disarmed
      cellvoltage needs to be corrected by subtracting the "under load" voltage drop
    --]]
    if telemetry.statusArmed then
      perc = getBattPercByCell(0.01*battery[1+1])
    else
      perc = getBattPercByCell((0.01*battery[1+1])-0.15)
    end
  else
  perc = battery[16+1]
  end --conf.enableBattPercByVoltage
  
  local perc2 = 99
  if conf.enableBattPercByVoltage == true then
    --[[
      discharge curve is based on battery under load, when motors are disarmed
      cellvoltage needs to be corrected by subtracting the "under load" voltage drop
    --]]
    if telemetry.statusArmed then
      perc = getBattPercByCell(0.01*battery[1+2])
    else
      perc = getBattPercByCell((0.01*battery[1+2])-0.15)
    end
  else
  perc2 = battery[16+2]
  end --conf.enableBattPercByVoltage
  
  -- battery 1 cell voltage (no alerts on battery 1)
  local flags = 0
  --
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(200,200,200)) -- white
  lcd.drawFilledRectangle(x+7,16+5,86,52,CUSTOM_COLOR)
  --lcd.setColor(CUSTOM_COLOR,0xFFFF) -- white
  lcd.setColor(CUSTOM_COLOR,0x0000) -- white
  flags = CUSTOM_COLOR
  --PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if battery[1+1] * 0.01 < 10 then
    lcd.drawNumber(x+75+2, 16, battery[1+1] + 0.5, PREC2+DBLSIZE+RIGHT+flags)
  else
    lcd.drawNumber(x+75+2, 16, (battery[1+1] + 0.5)*0.1, PREC1+DBLSIZE+RIGHT+flags)
  end
  
  local lx = x+76
  lcd.drawText(lx, 36, "V", flags)
  lcd.drawText(lx, 18, status.battsource, flags)
  
  --  BATT2 Cell voltage
  flags = 0
  --
  lcd.setColor(CUSTOM_COLOR,0xFFFF) -- white
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and alarms[8][2] > 0 then
      utils.drawBlinkBitmap("cell_red_blink_86x30",x+7,76)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red_86x30"),x+7,76)
    elseif status.battLevel1 == false and alarms[7][2] > 0 then
      --lcd.setColor(CUSTOM_COLOR,0x0000) -- black
      utils.drawBlinkBitmap("cell_orange_blink_86x30",x+7,76)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange_86x30"),x+7,76)
      lcd.setColor(CUSTOM_COLOR,0x0000) -- black
    end
  end
  flags = CUSTOM_COLOR
  --PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if battery[1+2] * 0.01 < 10 then
    lcd.drawNumber(x+75+2, 72, battery[1+2] + 0.5, PREC2+DBLSIZE+RIGHT+flags)
  else
    lcd.drawNumber(x+75+2, 72, (battery[1+2] + 0.5)*0.1, PREC1+DBLSIZE+RIGHT+flags)
  end
  
  lx = x+78
  lcd.drawText(lx, 88, "V", flags)
  lcd.drawText(lx, 72, status.battsource, flags)
  
  -- BATTERY BAR % --
  --[[
  -- batt1 capacity bar %
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
  -- battery 1 percentage
  lcd.setColor(CUSTOM_COLOR,COLOR_BLACK) -- black
  local strperc = string.format("%02d%%",perc)
  lcd.drawText(x+BATTPERC_X, BATTPERC_Y, strperc, BATTPERC_FLAGS+CUSTOM_COLOR)
  --]]
  -- batt2 capacity bar %
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,255, 255))
  lcd.drawFilledRectangle(x+10, 130,80,21,CUSTOM_COLOR)
  if perc2 > 50 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 255, 0))
  elseif perc2 <= 50 and perc2 > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,0, 0))
  end
  lcd.drawGauge(x+10, 130,80,21,perc2,100,CUSTOM_COLOR)
  -- battery 1 percentage
  lcd.setColor(CUSTOM_COLOR,0x0000) -- black
  local strperc2 = string.format("%02d%%",perc2)
  lcd.drawText(x+35, 126, strperc2, MIDSIZE+CUSTOM_COLOR)
  
  -- POWER --
  -- power 1
  lcd.setColor(CUSTOM_COLOR,0x0000)
  local power1 = battery[4+1]*battery[7+1]*0.01
  lcd.drawNumber(x+75,46,power1,MIDSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+77,53,"W",CUSTOM_COLOR)
  -- power 2
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  local power2 = battery[4+2]*battery[7+2]*0.01
  lcd.drawNumber(x+75,103,power2,MIDSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+77,110,"W",CUSTOM_COLOR)
  
  --[[
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+BATTCELL_X+11, BATTCELL_Y + 8,false,true,utils)
    drawLib.drawVArrow(x+BATTVOLT_X+11,BATTVOLT_Y + 3, false,true,utils)
    drawLib.drawVArrow(x+BATTCURR_X+11,BATTCURR_Y + 10,true,false,utils)
  end
  --]]
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawPane=drawPane,background=background}
