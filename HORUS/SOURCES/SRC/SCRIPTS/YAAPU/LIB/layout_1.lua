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
--#define LOADSCRIPT
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








---------------------------------
-- LAYOUT
---------------------------------






-- x:300 y:135 inside HUD











--------------------------
-- CUSTOM SENSORS SUPPORT
--------------------------

local customSensorXY = {
  { 80, 193, 80, 203},
  { 160, 193, 160, 203},
  { 240, 193, 240, 203},
  { 320, 193, 320, 203},
  { 400, 193, 400, 203},
  { 480, 193, 480, 203},
}

local function drawCustomSensors(x,customSensors,utils,status)
    lcd.setColor(CUSTOM_COLOR,0x0000)
    lcd.drawFilledRectangle(0,194,LCD_W,35,CUSTOM_COLOR)
    
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
        lcd.setColor(CUSTOM_COLOR,0x8C71)
        lcd.drawText(x+customSensorXY[i][1], customSensorXY[i][2],label, SMLSIZE+RIGHT+CUSTOM_COLOR)
        
        mult =  sensorConfig[3] == 0 and 1 or ( sensorConfig[3] == 1 and 10 or 100 )
        prec =  mult == 1 and 0 or (mult == 10 and 32 or 48)
        
        local sensorName = sensorConfig[2]..(status.showMinMaxValues == true and sensorConfig[6] or "")
        local sensorValue = getValue(sensorName) 
        local value = (sensorValue+(mult == 100 and 0.005 or 0))*mult*sensorConfig[5]        
        
        -- default font size
        flags = sensorConfig[7] == 1 and 0 or MIDSIZE
        
        -- for sensor 3,4,5,6 reduce font if necessary
        if math.abs(value)*mult > 99999 then
          flags = 0
        end
        
        local color = 0xFFFF
        local sign = sensorConfig[6] == "+" and 1 or -1
        -- max tracking, high values are critical
        if math.abs(value) ~= 0 and status.showMinMaxValues == false then
          color = ( sensorValue*sign > sensorConfig[9]*sign and lcd.RGB(255,70,0) or (sensorValue*sign > sensorConfig[8]*sign and 0xFE60 or 0xFFFF))
        end
        
        lcd.setColor(CUSTOM_COLOR,color)
        
        local voffset = flags==0 and 6 or 0
        -- if a lookup table exists use it!
        if customSensors.lookups[i] ~= nil and customSensors.lookups[i][value] ~= nil then
          lcd.drawText(x+customSensorXY[i][3], customSensorXY[i][4]+voffset, customSensors.lookups[i][value] or value, flags+RIGHT+CUSTOM_COLOR)
        else
          lcd.drawNumber(x+customSensorXY[i][3], customSensorXY[i][4]+voffset, value, flags+RIGHT+prec+CUSTOM_COLOR)
        end
      end
    end
end

local function draw(myWidget,drawLib,conf,telemetry,status,battery,alarms,frame,utils,customSensors,gpsStatuses,leftPanel,centerPanel,rightPanel)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  centerPanel.drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils)
  --lcd.setColor(CUSTOM_COLOR,0xFE60)
  drawLib.drawRArrow(240,174,20,math.floor(telemetry.homeAngle - telemetry.yaw),CUSTOM_COLOR)--HomeDirection(telemetry)
  -- with dual battery default is to show aggregate view
  if status.batt2sources.fc or status.batt2sources.vs then
    if status.showDualBattery == false then
      -- dual battery: aggregate view
      rightPanel.drawPane(380,drawLib,conf,telemetry,status,alarms,battery,0,gpsStatuses,utils)
      -- left pane info
      leftPanel.drawPane(0,drawLib,conf,telemetry,status,alarms,battery,0,gpsStatuses,utils)
    else
      -- dual battery:battery 1 right pane
      rightPanel.drawPane(380,drawLib,conf,telemetry,status,alarms,battery,1,gpsStatuses,utils)
      -- dual battery:battery 2 left pane
      rightPanel.drawPane(0,drawLib,conf,telemetry,status,alarms,battery,2,gpsStatuses,utils)
    end
  else
    -- battery 1 right pane in single battery mode
    rightPanel.drawPane(380,drawLib,conf,telemetry,status,alarms,battery,1,gpsStatuses,utils)
    -- left pane info  in single battery mode
    leftPanel.drawPane(0,drawLib,conf,telemetry,status,alarms,battery,0,gpsStatuses,utils)
  end
  utils.drawTopBar()
  local msgRows = 4
  if customSensors ~= nil then
    --utils.drawBottomBar()
    msgRows = 1
    -- draw custom sensors
    drawCustomSensors(0,customSensors,utils,status)
  end
  drawLib.drawStatusBar(msgRows,conf,telemetry,status,battery,alarms,frame,utils,gpsStatuses)
  drawLib.drawFailsafe(telemetry,utils)
  drawLib.drawArmStatus(status,telemetry,utils)
end

return {draw=draw}

