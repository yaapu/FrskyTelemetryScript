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
















--------------------------
-- CUSTOM SENSORS SUPPORT
--------------------------

local customSensorXY = {
  { 110, 91, 110, 102},
  { 196, 91, 196, 102},
  { 110, 124, 110, 133},
  { 196, 124, 196, 133},
  { 110, 164, 110, 174},
  { 196, 164, 196, 174},
}

local function drawCustomSensors(x,customSensors,utils,status)
    if customSensors == nil then
      return
    end
    
    local label,data,prec,mult,flags,sensorConfig
    for i=1,6
    do
      if customSensors.sensors[i] ~= nil then 
        sensorConfig = customSensors.sensors[i]
        
        if sensorConfig[4] == "" then
          label = string.format("%s",sensorConfig[1])
        else
          label = string.format("%s(%s)",sensorConfig[1],sensorConfig[4])
        end
        -- draw sensor label
        lcd.drawText(x+customSensorXY[i][1], customSensorXY[i][2],label, SMLSIZE+RIGHT+BLACK)
        
        mult =  sensorConfig[3] == 0 and 1 or ( sensorConfig[3] == 1 and 10 or 100 )
        prec =  mult == 1 and 0 or (mult == 10 and 32 or 48)
        
        local sensorName = sensorConfig[2]..(status.showMinMaxValues == true and sensorConfig[6] or "")
        local sensorValue = getValue(sensorName) 
        local value = (sensorValue+(mult == 100 and 0.005 or 0))*mult*sensorConfig[5]        
        
        -- default font size
        flags = (i<=2 and MIDSIZE or (sensorConfig[7] == 1 and MIDSIZE or DBLSIZE))
        
        -- for sensor 3,4,5,6 reduce font if necessary
        if i>2 and math.abs(value)*mult > 99999 then
          flags = MIDSIZE
        end

        local colr = WHITE
        local sign = sensorConfig[6] == "+" and 1 or -1
        
        -- max tracking, high values are critical
        if math.abs(value) ~= 0 and status.showMinMaxValues == false then
          colr = ( sensorValue*sign > sensorConfig[9]*sign and RED or (sensorValue*sign > sensorConfig[8]*sign and lcd.RGB(0xFF,0xCE,0x00) or WHITE))
        end
        
        local voffset = (i>2 and flags==MIDSIZE) and 5 or 0
        -- if a lookup table exists use it!
        if customSensors.lookups[i] ~= nil and customSensors.lookups[i][value] ~= nil then
          lcd.drawText(x+customSensorXY[i][3], customSensorXY[i][4]+voffset, customSensors.lookups[i][value] or value, flags+RIGHT+colr)
        else
          lcd.drawNumber(x+customSensorXY[i][3], customSensorXY[i][4]+voffset, value, flags+RIGHT+prec+colr)
        end
      end
    end
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
local function drawPane(x,drawLib,conf,telemetry,status,alarms,battery,battId,gpsStatuses,utils,customSensors)
  local perc = battery[16+battId]
  --  battery min cell
  local colr = WHITE
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and alarms[8][2] > 0 then
      utils.drawBlinkBitmap("cell_red_small",x+110+1,16 + 7)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red_small"),x+110+1,16 + 7)
    elseif status.battLevel1 == false and alarms[7][2] > 0 then
      utils.drawBlinkBitmap("cell_orange_small_blink",x+110+1,16 + 7)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange_small"),x+110+1,16 + 7)
	  colr = BLACK
    end
  end
  --PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if battery[1+battId] * 0.01 < 10 then
    lcd.drawNumber(x+110+2, 16, battery[1+battId] + 0.5, PREC2+DBLSIZE+colr)
  else
    lcd.drawNumber(x+110+2, 16, (battery[1+battId] + 0.5)*0.1, PREC1+DBLSIZE+colr)
  end
  local lx = x+180
  lcd.drawText(lx, 19, "V", SMLSIZE+colr)
  lcd.drawText(lx-2, 35, status.battsource, SMLSIZE+colr)
  
  -- battery voltage
  drawLib.drawNumberWithDim(x+110,48,x+110, 46, battery[4+battId],"V",MIDSIZE+PREC1+RIGHT+WHITE,SMLSIZE+WHITE)
  -- battery current
  drawLib.drawNumberWithDim(x+178,48,x+178,48,battery[7+battId],"A",MIDSIZE+RIGHT+PREC1+WHITE,SMLSIZE+WHITE)
  -- display capacity bar %
  if perc > 50 then
    colr = GREEN
  elseif perc <= 50 and perc > 25 then
    colr = lcd.RGB(255, 204, 0) -- yellow
  else
    colr = RED
  end
  lcd.drawBitmap(utils.getBitmap("gauge_bg_small"),x+47,29)
  lcd.drawGauge(x+47, 29,58,16,perc,100,colr)
  -- battery percentage
  local strperc = string.format("%02d%%",perc)
  lcd.drawText(x+63, 27, strperc, 0+BLACK)
  
  -- battery mah
  local strmah = string.format("%.02f/%.01f",battery[10+battId]/1000,battery[13+battId]/1000)
  lcd.drawText(x+180, 71+4, "Ah", SMLSIZE+RIGHT+WHITE)
  lcd.drawText(x+180 - 22, 71, strmah, 0+RIGHT+WHITE)
    
  -- lcd.setColor(CUSTOM_COLOR,0x5AEB)  -- 0x5AEB = 0x5A5D5A = grey tone
  lcd.drawBitmap(utils.getBitmap("battbox_small"),x+42,21)

  -- do no show custom sensors when displaying 2nd battery info
  if battId < 2 then
    drawCustomSensors(x,customSensors,utils,status)
  end
  
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(LCD_W-12, 16 + 8,false,true,utils)
    drawLib.drawVArrow(x+110+5,48 + 6, false,true,utils)
    drawLib.drawVArrow(x+178+4,48 + 6,true,false,utils)
  end
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawPane=drawPane,background=background}
