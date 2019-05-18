--
-- An FRSKY S.Port <passthrough protocol> based Telemetry script for the Taranis X9D+ and QX7+ radios
--
-- Copyright (C) 2018. Alessandro Apostoli
--   https://github.com/yaapu
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
-- Passthrough protocol reference:
--   https://cdn.rawgit.com/ArduPilot/ardupilot_wiki/33cd0c2c/images/FrSky_Passthrough_protocol.xlsx
--
---------------------
-- GLOBAL DEFINES
---------------------
--#define X9
--#define 
-- always use loadscript() instead of loadfile()
-- force a loadscript() on init() to compile all .lua in .luac
--#define COMPILE
---------------------
-- VERSION
---------------------
---------------------
-- FEATURES
---------------------
--#define BATTMAH3DEC
-- enable altitude/distance monitor and vocal alert (experimental)
--#define MONITOR
-- show incoming DIY packet rates
--#define TELEMETRY_STATS
-- enable synthetic vspeed when ekf is disabled
--#define SYNTHVSPEED
-- enable telemetry reset on timer 3 reset
-- always calculate FNV hash and play sound msg_<hash>.wav
-- enable telemetry logging menu option
--#define LOGTELEMETRY
-- enable max HDOP alert 
--#define HDOP_ALARM
-- enable support for custom background functions
--#define CUSTOM_BG_CALL
-- enable alert window for no telemetry
--#define NOTELEM_ALERT
-- enable popups for no telemetry data
--#define NOTELEM_POPUP
-- enable blinking rectangle on no telemetry
---------------------
-- DEBUG
---------------------
--#define DEBUG
--#define DEBUGEVT
--#define DEV
--#define MEMDEBUG
-- calc and show background function rate
--#define BGRATE
-- calc and show run function rate
--#define FGRATE
-- calc and show hud refresh rate
--#define HUDRATE
-- calc and show telemetry process rate
--#define BGTELERATE
---------------------
-- TESTMODE
---------------------
-- enable script testing via radio sticks
--#define TESTMODE


---------------------
-- SENSORS
---------------------












-- Throttle and RC use RPM sensor IDs





------------------------
-- MIN MAX
------------------------
-- min

------------------------
-- LAYOUT
------------------------
  










--#define HOMEDIR_X 42




--------------------------------------------------------------------------------
-- MENU VALUE,COMBO
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- ALARMS
--------------------------------------------------------------------------------
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
--]]


-----------------------
-- UNIT SCALING
-----------------------
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"



-----------------------
-- HUD AND YAW
-----------------------
-- vertical distance between roll horiz segments

-- vertical distance between roll horiz segments
-----------------------
-- BATTERY 
-----------------------
-- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1



-- X-Lite Support

-----------------------------------
-- STATE TRANSITION ENGINE SUPPORT
-----------------------------------







-- SYNTH VSPEED SUPPORT
local vspd = 0
local synthVSpeedTime = 0
local prevHomeAlt = 0

local yawRibbonPoints = {}

yawRibbonPoints[0]="N"
yawRibbonPoints[1]=""
yawRibbonPoints[2]="NE"
yawRibbonPoints[3]=""
yawRibbonPoints[4]="E"
yawRibbonPoints[5]=""
yawRibbonPoints[6]="SE"
yawRibbonPoints[7]=""
yawRibbonPoints[8]="S"
yawRibbonPoints[9]=""
yawRibbonPoints[10]="SW"
yawRibbonPoints[11]=""
yawRibbonPoints[12]="W"
yawRibbonPoints[13]=""
yawRibbonPoints[14]="NW"
yawRibbonPoints[15]=""

local function drawHud(drawLib,conf,telemetry,status,battery,getMaxValue)
    -- compass ribbon centered +/- 90 on yaw
  local centerYaw = (telemetry.yaw+270+3)%360 -- +3 to center the ribbon on screen
  -- this is the first point left to be drawn on the compass ribbon
  local nextPoint = math.floor(centerYaw/22.5) * 22.5
  -- x coord of first ribbon letter
  local nextPointX = 2 + 34 + (nextPoint - centerYaw)/22.5 * 6.2

  local i = (nextPoint / 22.5) % 16
  for idx=1,12
  do
      local letterOffset = 0
      local lineOffset = 2
      if #yawRibbonPoints[i] > 1 then
        letterOffset = -2
        lineOffset = 3
      end
      if nextPointX >= 34 -3 and nextPointX < 26+64 then
        if #yawRibbonPoints[i] == 0 then
          lcd.drawLine(nextPointX + lineOffset, 0+7, nextPointX + lineOffset, 0+7 + 2, SOLID, 0)
        else
          lcd.drawText(nextPointX + letterOffset,0+7+1 ,yawRibbonPoints[i],SMLSIZE)
        end
      end
      i = (i + 1) % 16
      nextPointX = nextPointX + 6.2
  end
  -- home icon
  local homeOffset = 0 --64-5-14
  local angle = telemetry.homeAngle - telemetry.yaw
  if angle < 0 then
    angle = 360 + angle
  end
  if angle > 270 or angle < 90 then
    homeOffset = ((angle + 90) % 180)/180  * (64-5-12)
  elseif angle >= 90 and angle <= 180 then
    homeOffset = 64-5-10--0
  end
  drawLib.drawHomeIcon(34 + homeOffset,0+7 + 12)
  -- clean right and left
  lcd.drawFilledRectangle(32-2, 0+7, 5, 10, ERASE, 0)
  lcd.drawFilledRectangle(32+64-7, 0+7, 8, 10, ERASE, 0)
  -- HUD
  local r = -telemetry.roll
  local cx,cy,dx,dy,ccx,ccy
  local yPos = 0 + 7 + 8
  -----------------------
  -- artificial horizon
  -----------------------
  -- no roll ==> segments are vertical, offsets are multiples of 6
  if ( telemetry.roll == 0) then
    dx=0
    dy=telemetry.pitch
    cx=0
    cy=6
    ccx=0
    ccy=2*6
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -telemetry.pitch
    dy = math.sin(math.rad(90 - r)) * telemetry.pitch
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * 6
    cy = math.sin(math.rad(90 - r)) * 6
    -- 2nd line offsets
    ccx = math.cos(math.rad(90 - r)) * 2 * 6
    ccy = math.sin(math.rad(90 - r)) * 2 * 6
  end
  local rollX = 128/2 - 1 - 2
  -- parallel lines above and below horizon line
  drawLib.drawLineWithClipping(rollX + dx - ccx,dy + 33 + ccy,r,20,DOTTED,32,32 + 64,8,57 - 1)
  drawLib.drawLineWithClipping(rollX + dx - cx,dy + 33 + cy,r,8,DOTTED,32,32 + 64,8,57 - 1)
  drawLib.drawLineWithClipping(rollX + dx + cx,dy + 33 - cy,r,8,DOTTED,32,32 + 64,8,57 - 1)
  drawLib.drawLineWithClipping(rollX + dx + ccx,dy + 33 - ccy,r,20,DOTTED,32,32 + 64,8,57 - 1)
  -----------------------
  -- dark color for "ground"
  -----------------------
  local minY = 8
  local minX = 32 + 1
  -- vario width is 6
  local maxX = 32 + 64 - 8
  local maxY = 55
  local ox = 64 + dx - 2
  local oy = 33 + dy
  local yy = 0
  -- angle of the line passing on point(ox,oy)
  local angle = math.tan(math.rad(-telemetry.roll))
  -- for each pixel of the hud base/top draw vertical black 
  -- lines from hud border to horizon line
  -- horizon line moves with pitch/roll
  for xx= minX,maxX
  do
    yy = (oy - ox*angle) + math.floor(xx*angle)
    if telemetry.roll > 90 or telemetry.roll < -90 then
      if yy > minY then
        lcd.drawLine(xx, minY, xx, math.min(yy,maxY),SOLID,0)
      end
    else
      if yy < maxY then
        lcd.drawLine(xx, maxY, xx, math.max(yy,minY),SOLID,0)
      end
    end
  end
  vspd = telemetry.vSpeed
  -------------------------------------
  -- vario indicator on right
  -------------------------------------
  lcd.drawLine(32 + 64 - 6, 7, 32 + 64 - 6, yPos + 40, SOLID, 0)
  
  local varioMax = 10
  local varioSpeed = math.min(math.abs(0.1*vspd),10)
  local varioY = 0
  local arrowY = -1
  if vspd > 0 then
    varioY = 33 - 4 - varioSpeed/varioMax*22
  else
    varioY = 33 + 6
    arrowY = 1
  end
  lcd.drawFilledRectangle(32 + 64 - 6, varioY, 6, varioSpeed/varioMax*22, FORCE, 0)
  for i=0,16
  do
    lcd.drawLine(32 + 64 - 4, 9+i*3, 32 + 64-2, 9+i*3, SOLID, ERASE)
    lcd.drawLine(32 + 64 - 3, arrowY+9+i*3, 32 + 64-3, arrowY+9+i*3, SOLID, ERASE)
  end
  -- hashmarks
  local offset = 0
  for i=0,5
  do
  -- left hashmarks
    offset = 48 - ((telemetry.hSpeed - i*8) % 46)/46 * 46
    lcd.drawLine(32+1, 0+7 + offset, 32 + 2, 0+7 + offset, SOLID, 0)
  -- right hashmarks
    offset = 48 - ((telemetry.homeAlt - i*8) % 46)/46 * 46
    lcd.drawLine(32 + 64 - 9, 0+7 + offset, 32 + 64 - 8, 0+7 + offset, SOLID, 0)
  end
  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- lets erase to hide the artificial horizon lines
  -- black borders
  lcd.drawRectangle(32, 33 - 5,   17, 11, FORCE, 0)
  lcd.drawRectangle(32 + 64 -  17 - 1, 33 - 5,  17+1, 11, FORCE, 0)
  -- erase area
  lcd.drawFilledRectangle(32, 33 - 4,   17, 9, ERASE, 0)
  lcd.drawFilledRectangle(32 + 64 -  17 - 1, 33 - 4,  17+2, 9, ERASE, 0)
  -- erase tips
  lcd.drawLine(32 +   17,33 - 3,32 +   17,33 + 3, SOLID, ERASE)
  lcd.drawLine(32 +   17+1,33 - 2,32 +   17+1,33 + 2, SOLID, ERASE)
  lcd.drawLine(32 + 64 -  17 - 2,33 - 3,32 + 64 -  17 - 2,33 + 3, SOLID, ERASE)
  lcd.drawLine(32 + 64 -  17 - 3,33 - 2,32 + 64 -  17 - 3,33 + 2, SOLID, ERASE)
  -- left tip
  lcd.drawLine(32 +   17+2,33 - 2,32 +   17+2,33 + 2, SOLID, FORCE)
  lcd.drawLine(32 +   17-1,33 - 5,32 +   17+1,33 - 3, SOLID, FORCE)
  lcd.drawLine(32 +   17-1,33 + 5,32 +   17+1,33 + 3, SOLID, FORCE)
  -- right tip
  lcd.drawLine(32 + 64 -  17 - 4,33 - 2,32 + 64 -  17 - 4,33 + 2, SOLID, FORCE)
  lcd.drawLine(32 + 64 -  17 - 3,33 - 3,32 + 64 -  17 - 1,33 - 5, SOLID, FORCE)
  lcd.drawLine(32 + 64 -  17 - 3,33 + 3,32 + 64 -  17 - 1,33 + 5, SOLID, FORCE)
    -- altitude
  local alt = getMaxValue(telemetry.homeAlt,11) * unitScale -- homeAlt is meters*3.28 = feet

  if math.abs(alt) < 10 then
      lcd.drawNumber(32 + 64,33 - 3,alt * 10,PREC1+RIGHT)
  else
      lcd.drawNumber(32 + 64,33 - 3,alt,RIGHT)
  end
  -- hspeed
  local speed = getMaxValue(telemetry.hSpeed,14) * conf.horSpeedMultiplier
  if math.abs(speed) > 99 then
    lcd.drawNumber(32+1,33 - 3,speed*0.1,0)
  else
    lcd.drawNumber(32+1,33 - 3,speed,PREC1)
  end
  
  lcd.drawLine(128/2-9-3,33,128/2-4-3,33 ,SOLID,0) -- -1 to compensate for H offset 
  lcd.drawLine(128/2-3-3,33,128/2-3-3,33+3 ,SOLID,0)
  
  lcd.drawLine(128/2+4-3,33,128/2+9-3,33 ,SOLID,0)
  lcd.drawLine(128/2+3-3,33,128/2+3-3,33+3 ,SOLID,0)
  -- vspeed box (dm/s)
  local xx = math.abs(vspd*conf.vertSpeedMultiplier) > 9999 and 4 or 3
  xx = xx + (vspd*conf.vertSpeedMultiplier < 0 and 1 or 0)
  
  lcd.drawFilledRectangle((128)/2 - (xx/2)*5 - 2, LCD_H - 17, xx*5+3, 10, ERASE)
  
  if math.abs(vspd*conf.vertSpeedMultiplier) > 99 then -- 
    lcd.drawNumber((128)/2 + (xx/2)*5, LCD_H - 15, vspd*0.1*conf.vertSpeedMultiplier, SMLSIZE+RIGHT)
  else
    lcd.drawNumber((128)/2 + (xx/2)*5, LCD_H - 15, vspd*conf.vertSpeedMultiplier, SMLSIZE+RIGHT+PREC1)
  end
  lcd.drawRectangle((128)/2 - (xx/2)*5 - 2, LCD_H - 17, xx*5+3, 10, FORCE+SOLID)
    
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(32 +   17 + 4, 33 - 4,6,true,false)
  end
  -- min/max arrows
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(32 + 64 - 24, 33 - 4,6,true,false)
  end
  -- arming status, show only if timer is not running, hide otherwise
  if telemetry.ekfFailsafe == 0 and telemetry.battFailsafe == 0 and status.timerRunning == 0 then
    if (telemetry.statusArmed == 1) then
      lcd.drawText(32 + 64/2 - 15, 20, " ARMED ", SMLSIZE+INVERS)
    else
      lcd.drawText(32 + 64/2 - 21, 20, " DISARMED ", SMLSIZE+INVERS+BLINK)
    end
  end
  -- yaw angle box
  xx = telemetry.yaw < 10 and 1 or ( telemetry.yaw < 100 and -2 or -5 )
  lcd.drawNumber(128/2 + xx - 8, 0+7-1, telemetry.yaw, MIDSIZE+INVERS)
end


return {
  drawHud=drawHud,
  yawRibbonPoints=yawRibbonPoints
}
