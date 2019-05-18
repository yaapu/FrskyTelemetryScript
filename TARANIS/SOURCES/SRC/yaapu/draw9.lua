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
--#define 
--#define X7
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







local function drawHArrow(x,y,width,left,right)
  lcd.drawLine(x, y, x + width,y, SOLID, 0)
  if left == true then
    lcd.drawLine(x + 1,y  - 1,x + 2,y  - 2, SOLID, 0)
    lcd.drawLine(x + 1,y  + 1,x + 2,y  + 2, SOLID, 0)
  end
  if right == true then
    lcd.drawLine(x + width - 1,y  - 1,x + width - 2,y  - 2, SOLID, 0)
    lcd.drawLine(x + width - 1,y  + 1,x + width - 2,y  + 2, SOLID, 0)
  end
end

local function drawVArrow(x,y,h,top,bottom)
  lcd.drawLine(x,y,x,y + h, SOLID, 0)
  if top == true then
    lcd.drawLine(x - 1,y + 1,x - 2,y  + 2, SOLID, 0)
    lcd.drawLine(x + 1,y + 1,x + 2,y  + 2, SOLID, 0)
  end
  if bottom == true then
    lcd.drawLine(x - 1,y  + h - 1,x - 2,y + h - 2, SOLID, 0)
    lcd.drawLine(x + 1,y  + h - 1,x + 2,y + h - 2, SOLID, 0)
  end
end


local function drawHomeIcon(x,y)
  lcd.drawRectangle(x,y,5,5,SOLID)
  lcd.drawLine(x+2,y+3,x+2,y+4,SOLID,FORCE)
  lcd.drawPoint(x+2,y-1,FORCE)
  lcd.drawLine(x,y+1,x+5,y+1,SOLID,FORCE)
  lcd.drawLine(x-1,y+1,x+2,y-2,SOLID, FORCE)
  lcd.drawLine(x+5,y+1,x+3,y-1,SOLID, FORCE)
end


local function computeOutCode(x,y,xmin,ymin,xmax,ymax)
    local code = 0; --initialised as being inside of hud
    --
    if x < xmin then --to the left of hud
        code = bit32.bor(code,1);
    elseif x > xmax then --to the right of hud
        code = bit32.bor(code,2);
    end
    if y < ymin then --below the hud
        code = bit32.bor(code,4);
    elseif y > ymax then --above the hud
        code = bit32.bor(code,8);
    end
    --
    return code;
end
-- Cohen–Sutherland clipping algorithm
-- https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm
local function drawLineWithClipping(ox,oy,angle,len,style,xmin,xmax,ymin,ymax)
  --
  local xx = math.cos(math.rad(angle)) * len * 0.5
  local yy = math.sin(math.rad(angle)) * len * 0.5
  --
  local x0 = ox - xx
  local x1 = ox + xx
  local y0 = oy - yy
  local y1 = oy + yy    
  -- compute outcodes for P0, P1, and whatever point lies outside the clip rectangle
  local outcode0 = computeOutCode(x0, y0, xmin, ymin, xmax, ymax);
  local outcode1 = computeOutCode(x1, y1, xmin, ymin, xmax, ymax);
  local accept = false;
  while (true) do
    if ( bit32.bor(outcode0,outcode1) == 0) then
      -- bitwise OR is 0: both points inside window; trivially accept and exit loop
      accept = true;
      break;
    elseif (bit32.band(outcode0,outcode1) ~= 0) then
      -- bitwise AND is not 0: both points share an outside zone (LEFT, RIGHT, TOP, BOTTOM)
      -- both must be outside window; exit loop (accept is false)
      break;
    else
      -- failed both tests, so calculate the line segment to clip
      -- from an outside point to an intersection with clip edge
      local x = 0
      local y = 0
      -- At least one endpoint is outside the clip rectangle; pick it.
      local outcodeOut = outcode0 ~= 0 and outcode0 or outcode1
      -- No need to worry about divide-by-zero because, in each case, the
      -- outcode bit being tested guarantees the denominator is non-zero
      if bit32.band(outcodeOut,8) ~= 0 then --point is above the clip window
        x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0)
        y = ymax
      elseif bit32.band(outcodeOut,4) ~= 0 then --point is below the clip window
        x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0)
        y = ymin
      elseif bit32.band(outcodeOut,2) ~= 0 then --point is to the right of clip window
        y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0)
        x = xmax
      elseif bit32.band(outcodeOut,1) ~= 0 then --point is to the left of clip window
        y = y0 + (y1 - y0) * (xmin - x0) / (x1 - x0)
        x = xmin
      end
      -- Now we move outside point to intersection point to clip
      -- and get ready for next pass.
      if outcodeOut == outcode0 then
        x0 = x
        y0 = y
        outcode0 = computeOutCode(x0, y0, xmin, ymin, xmax, ymax)
      else
        x1 = x
        y1 = y
        outcode1 = computeOutCode(x1, y1, xmin, ymin, xmax, ymax)
      end
    end
  end
  if accept then
    lcd.drawLine(x0,y0,x1,y1, style,0)
  end
end

local function drawBottomBar(msg,lastMsgTime)
  lcd.drawText(0,56+1,msg,SMLSIZE+INVERS)
end


local function drawGrid()
  lcd.drawLine(62 - 1, 7 ,62 - 1, 57, SOLID, FORCE)
  lcd.drawLine(62 + 88, 7, 62 + 88, 55, SOLID, FORCE)
end

local function drawTopBar(strMode,simpleMode,flightTime,telemetryEnabled)
  -- flight mode
  -- simplemode
  if strMode ~= nil then
    lcd.drawText(1, 0, strMode, SMLSIZE+INVERS)
    if ( simpleMode > 0) then
      local strSimpleMode = simpleMode == 1 and "(S)" or "(SS)"
      lcd.drawText(lcd.getLastRightPos(), 0, strSimpleMode, SMLSIZE+INVERS)
    end
  end  
  lcd.drawTimer(212-1, 0, flightTime, SMLSIZE+INVERS+TIMEHOUR+RIGHT)
  -- RSSI
  if (not telemetryEnabled()) then
    lcd.drawText(69, 0, "no telem!", SMLSIZE+BLINK+INVERS)
  else
    lcd.drawText(69, 0, "RS:", SMLSIZE+INVERS )
    lcd.drawText(lcd.getLastRightPos(), 0, getRSSI(), SMLSIZE+INVERS )  
  end
  -- tx voltage
  local vTx = string.format("Tx%.1fv",getValue(getFieldInfo("tx-voltage").id))
  lcd.drawText(115, 0, vTx, SMLSIZE+INVERS)
end

local function drawFailSafe(showDualBattery,ekfFailsafe,battFailsafe)
  local xoffset = 0
  local yoffset = 0
  if ekfFailsafe > 0 then
    lcd.drawText(xoffset + 62 + 88/2 - 31, 20 + yoffset, " EKF FAILSAFE ", SMLSIZE+INVERS+BLINK)
  end
  if battFailsafe > 0 then
    lcd.drawText(xoffset + 62 + 88/2 - 31, 20 + yoffset, " BATT FAILSAFE ", SMLSIZE+INVERS+BLINK)
  end
end

local function drawNoTelemetry(telemetryEnabled,hideNoTelemetry)
  -- no telemetry data
  if (not telemetryEnabled() and not hideNoTelemetry) then
    lcd.drawFilledRectangle((212-130)/2,18, 130, 30, SOLID)
    lcd.drawRectangle((212-130)/2,18, 130, 30, ERASE)
    lcd.drawText(60, 29, "no telemetry data", INVERS)
    return
  end
end

local function drawRArrow(x,y,rad,angle,flags)
  local x1 = x + rad * math.cos(math.rad(angle - 90))
  local y1 = y + rad * math.sin(math.rad(angle - 90))
  local x2 = x + (rad-1) * math.cos(math.rad(angle - 90 + 140))
  local y2 = y + (rad-1) * math.sin(math.rad(angle - 90 + 140))
  local x3 = x + (rad-1) * math.cos(math.rad(angle - 90 - 140))
  local y3 = y + (rad-1) * math.sin(math.rad(angle - 90 - 140))
  local x4 = x + (rad-1) * 0.5 * math.cos(math.rad(angle - 270))
  local y4 = y + (rad-1) * 0.5 *math.sin(math.rad(angle - 270))
  --
  lcd.drawLine(x1,y1,x2,y2,SOLID,flags)
  lcd.drawLine(x1,y1,x3,y3,SOLID,flags)
  lcd.drawLine(x2,y2,x4,y4,SOLID,flags)
  lcd.drawLine(x3,y3,x4,y4,SOLID,flags)
  lcd.drawPoint(x1,y1,SOLID+flags)
end

return {
  drawFailSafe=drawFailSafe,
  drawTopBar=drawTopBar,
  drawHArrow=drawHArrow,
  drawVArrow=drawVArrow,
  drawRArrow=drawRArrow,
  drawGrid=drawGrid,
  drawBottomBar=drawBottomBar,
  drawHomeIcon=drawHomeIcon,
  drawLineWithClipping=drawLineWithClipping,
  drawNoTelemetry=drawNoTelemetry
  }
