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























--------------------------
-- CUSTOM SENSORS SUPPORT
--------------------------


local customSensorXY = {
  { 110, 90, 110, 101},
  { 196, 90, 196, 101},
  { 110, 123, 110, 132},
  { 196, 123, 196, 132},
  { 110, 163, 110, 173},
  { 196, 163, 196, 173},
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
        lcd.setColor(CUSTOM_COLOR,0x0000)
        lcd.drawText(x+customSensorXY[i][1], customSensorXY[i][2],label, SMLSIZE+RIGHT+CUSTOM_COLOR)
        
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

        local color = 0xFFFF
        local sign = sensorConfig[6] == "+" and 1 or -1
        
        -- max tracking, high values are critical
        if math.abs(value) ~= 0 and status.showMinMaxValues == false then
          color = ( sensorValue*sign > sensorConfig[9]*sign and 0xF800 or (sensorValue*sign > sensorConfig[8]*sign and 0xFE60 or 0xFFFF))
        end
        
        lcd.setColor(CUSTOM_COLOR,color)
        
        local voffset = (i>2 and flags==MIDSIZE) and 5 or 0
        -- if a lookup table exists use it!
        if customSensors.lookups[i] ~= nil and customSensors.lookups[i][value] ~= nil then
          lcd.drawText(x+customSensorXY[i][3], customSensorXY[i][4]+voffset, customSensors.lookups[i][value] or value, flags+RIGHT+CUSTOM_COLOR)
        else
          lcd.drawNumber(x+customSensorXY[i][3], customSensorXY[i][4]+voffset, value, flags+RIGHT+prec+CUSTOM_COLOR)
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
--]]local function drawPane(x,drawLib,conf,telemetry,status,alarms,battery,battId,gpsStatuses,utils,customSensors)
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
      utils.drawBlinkBitmap("cell_red_small",x+110+1,16 + 7)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red_small"),x+110+1,16 + 7)
    elseif status.battLevel1 == false and alarms[7][2] > 0 then
      --lcd.setColor(CUSTOM_COLOR,0x0000) -- black
      utils.drawBlinkBitmap("cell_orange_small_blink",x+110+1,16 + 7)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange_small"),x+110+1,16 + 7)
      lcd.setColor(CUSTOM_COLOR,0x0000) -- black
    end
  end
  flags = CUSTOM_COLOR
  --PREC2 forces a math.floor() whereas a math.round() is required, math.round(f) = math.floor(f+0.5)
  if battery[1+battId] * 0.01 < 10 then
    lcd.drawNumber(x+110+2, 16, battery[1+battId] + 0.5, PREC2+DBLSIZE+flags)
  else
    lcd.drawNumber(x+110+2, 16, (battery[1+battId] + 0.5)*0.1, PREC1+DBLSIZE+flags)
  end
  local lx = x+180
  lcd.drawText(lx, 19, "V", SMLSIZE+flags)
  lcd.drawText(lx-2, 35, status.battsource, SMLSIZE+flags)
  
  lcd.setColor(CUSTOM_COLOR,0xFFFF) -- white  
  -- battery voltage
  drawLib.drawNumberWithDim(x+110,48,x+110, 46, battery[4+battId],"V",MIDSIZE+PREC1+RIGHT+CUSTOM_COLOR,SMLSIZE+CUSTOM_COLOR)
  -- battery current
  drawLib.drawNumberWithDim(x+178,48,x+178,48,battery[7+battId],"A",MIDSIZE+RIGHT+PREC1+CUSTOM_COLOR,SMLSIZE+CUSTOM_COLOR)
  -- display capacity bar %
  if perc > 50 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 255, 0))
  elseif perc <= 50 and perc > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,0, 0))
  end
  lcd.drawBitmap(utils.getBitmap("gauge_bg_small"),x+47,29)
  lcd.drawGauge(x+47, 29,58,16,perc,100,CUSTOM_COLOR)
  -- battery percentage
  lcd.setColor(CUSTOM_COLOR,0x0000) -- black
  
  local strperc = string.format("%02d%%",perc)
  lcd.drawText(x+63, 27, strperc, 0+CUSTOM_COLOR)
  
  -- battery mah
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  local strmah = string.format("%.02f/%.01f",battery[10+battId]/1000,battery[13+battId]/1000)
  lcd.drawText(x+180, 71+4, "Ah", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+180 - 22, 71, strmah, 0+RIGHT+CUSTOM_COLOR)
    
  lcd.setColor(CUSTOM_COLOR,0x5AEB)
  --lcd.drawText(475,124,battId == 0 and "B1+B2" or (battId == 1 and "B1" or "B2"),SMLSIZE+CUSTOM_COLOR+RIGHT)
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
