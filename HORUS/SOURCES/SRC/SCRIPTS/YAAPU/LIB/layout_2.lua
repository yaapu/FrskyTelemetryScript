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

---------------------------------
-- LAYOUT
---------------------------------










local function drawExtendedStatusBar(drawLib,conf,telemetry,status,battery,alarms,frame,utils,gpsStatuses)
  -- LEFT label
  lcd.drawText(153,165,"Alt("..unitLabel..")",SMLSIZE+BLACK+RIGHT)
  lcd.drawText(68,165,"VSI("..conf.vertSpeedLabel..")",SMLSIZE+BLACK+RIGHT)
  
  -- altitude
  local alt = utils.getMaxValue(telemetry.homeAlt,11) * unitScale
  if math.abs(alt) > 999 then
    lcd.drawNumber(153,178,alt,MIDSIZE+RIGHT+WHITE)
  elseif math.abs(alt) >= 10 then
    lcd.drawNumber(153,178,alt,MIDSIZE+RIGHT+WHITE)
  else
    lcd.drawNumber(153,178,alt*10,MIDSIZE+RIGHT+PREC1+WHITE)
  end
  -- vertical speed
  local vSpeed = utils.getMaxValue(telemetry.vSpeed,13) * 0.1 * conf.vertSpeedMultiplier
  if (math.abs(telemetry.vSpeed) >= 10) then
    lcd.drawNumber(68,178, vSpeed ,MIDSIZE+RIGHT+WHITE)
  else
    lcd.drawNumber(68,178,vSpeed*10,MIDSIZE+RIGHT+PREC1+WHITE)
  end
  -- min/max arrows
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(3, 178 + 3,true,false,utils)
    drawLib.drawVArrow(68-70, 178 + 3,true,false,utils)
  end
  
end

local function draw(myWidget,drawLib,conf,telemetry,status,battery,alarms,frame,utils,customSensors,gpsStatuses,leftPanel,centerPanel,rightPanel)
  if leftPanel ~= nil and centerPanel ~= nil and rightPanel ~= nil then
    drawLib.drawRArrow((LCD_W/2),180,22,math.floor(telemetry.homeAngle - telemetry.yaw),WHITE)--HomeDirection(telemetry)
    centerPanel.drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils,customSensors)
    -- with dual battery default is to show aggregate view
    if status.batt2sources.fc or status.batt2sources.vs then
      if status.showDualBattery == false then
        -- dual battery: aggregate view
        rightPanel.drawPane(285,drawLib,conf,telemetry,status,alarms,battery,0,gpsStatuses,utils,customSensors)
        -- left panel
        leftPanel.drawPane(0,drawLib,conf,telemetry,status,alarms,battery,0,gpsStatuses,utils,customSensors)
      else
        -- dual battery:battery 1 right pane
        rightPanel.drawPane(285,drawLib,conf,telemetry,status,alarms,battery,1,gpsStatuses,utils,customSensors)
        -- dual battery:battery 2 left pane
        rightPanel.drawPane(-37,drawLib,conf,telemetry,status,alarms,battery,2,gpsStatuses,utils,customSensors)
      end
    else
      -- battery 1 right pane in single battery mode
      rightPanel.drawPane(285,drawLib,conf,telemetry,status,alarms,battery,1,gpsStatuses,utils,customSensors)
        -- left panel
      leftPanel.drawPane(0,drawLib,conf,telemetry,status,alarms,battery,0,gpsStatuses,utils,customSensors)
    end
  end
  drawLib.drawStatusBar(3,conf,telemetry,status,battery,alarms,frame,utils,gpsStatuses)
  drawExtendedStatusBar(drawLib,conf,telemetry,status,battery,alarms,frame,utils,gpsStatuses)
  utils.drawTopBar()
  drawLib.drawFailsafe(telemetry,utils)
  drawLib.drawArmStatus(status,telemetry,utils)
end

return {draw=draw}

