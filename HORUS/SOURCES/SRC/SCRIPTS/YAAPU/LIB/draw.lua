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

local statusArmTimeout = 0	-- timeout counter for "armed" dialog

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


-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()
local yawRibbonPoints = {"N",nil,"NE",nil,"E",nil,"SE",nil,"S",nil,"SW",nil,"W",nil,"NW",nil}


local drawLine = nil

if string.find(radio, "x10") and tonumber(maj..minor..rev) < 222 then
  drawLine = function(x1,y1,x2,y2,flags1,flags2) lcd.drawLine(LCD_W-x1,LCD_H-y1,LCD_W-x2,LCD_H-y2,flags1,flags2) end
else
  drawLine = function(x1,y1,x2,y2,flags1,flags2) lcd.drawLine(x1,y1,x2,y2,flags1,flags2) end
end

local function drawHArrow(x,y,width,left,right,drawBlinkBitmap)
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
--
local function drawVArrow(x,y,top,bottom,utils)
  if top == true then
    utils.drawBlinkBitmap("uparrow",x,y)
  else
    utils.drawBlinkBitmap("downarrow",x,y)
  end
end

local function drawHomeIcon(x,y,utils)
  lcd.drawBitmap(utils.getBitmap("minihomeorange"),x,y)
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
        code = bit32.bor(code,8);
    elseif y > ymax then --above the hud
        code = bit32.bor(code,4);
    end
    --
    return code;
end

-- Cohen–Sutherland clipping algorithm
-- https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm
local function drawLineWithClippingXY(x0,y0,x1,y1,style,xmin,xmax,ymin,ymax,color,radio,rev)
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
      if bit32.band(outcodeOut,4) ~= 0 then --point is above the clip window
        x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0)
        y = ymax
      elseif bit32.band(outcodeOut,8) ~= 0 then --point is below the clip window
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
    drawLine(x0,y0,x1,y1, style,color)
  end
end

local function drawLineWithClipping(ox,oy,angle,len,style,xmin,xmax,ymin,ymax,color,radio,rev)
  local xx = math.cos(math.rad(angle)) * len * 0.5
  local yy = math.sin(math.rad(angle)) * len * 0.5
  
  local x0 = ox - xx
  local x1 = ox + xx
  local y0 = oy - yy
  local y1 = oy + yy    
  
  drawLineWithClippingXY(x0,y0,x1,y1,style,xmin,xmax,ymin,ymax,color,radio,rev)
end

local function drawNumberWithDim(x,y,xDim,yDim,number,dim,flags,dimFlags)
  lcd.drawNumber(x, y, number,flags)
  lcd.drawText(xDim, yDim, dim, dimFlags)
end

local function drawRArrow(x,y,r,angle,color)
  local ang = math.rad(angle - 90)
  local x1 = x + r * math.cos(ang)
  local y1 = y + r * math.sin(ang)
  
  ang = math.rad(angle - 90 + 150)
  local x2 = x + r * math.cos(ang)
  local y2 = y + r * math.sin(ang)
  
  ang = math.rad(angle - 90 - 150)
  local x3 = x + r * math.cos(ang)
  local y3 = y + r * math.sin(ang)
  ang = math.rad(angle - 270)
  local x4 = x + r * 0.5 * math.cos(ang)
  local y4 = y + r * 0.5 *math.sin(ang)
  --
  drawLine(x1,y1,x2,y2,SOLID,color)
  drawLine(x1,y1,x3,y3,SOLID,color)
  drawLine(x2,y2,x4,y4,SOLID,color)
  drawLine(x3,y3,x4,y4,SOLID,color)
end

--[[
 x,y = top,left
 image = background image
 gx,gy = gauge center point 
 r1 = gauge radius
 r2 = gauge distance from center
 perc = value % normalized between min, max
 max = angle max
--]]
local function drawGauge(x, y, image, gx, gy, r1, r2, perc, max, color, utils)
  local ang = (360-(max/2))+((perc*0.01)*max)
  
  if ang > 360 then
    ang = ang - 360
  end
  
  local ra = math.rad(ang-90)
  local ra_left = math.rad(ang-90-20)
  local ra_right = math.rad(ang-90+20)
  
  -- tip of the triangle
  local x1 = gx + r1 * math.cos(ra)
  local y1 = gy + r1 * math.sin(ra)
  -- bottom left
  local x2 = gx + r2 * math.cos(ra_left)
  local y2 = gy + r2 * math.sin(ra_left)
  -- bottom right
  local x3 = gx + r2 * math.cos(ra_right)
  local y3 = gy + r2 * math.sin(ra_right)
  
  lcd.drawBitmap(utils.getBitmap(image), x, y)

  drawLine(x1,y1,x2,y2,SOLID,color)
  drawLine(x1,y1,x3,y3,SOLID,color)
  drawLine(x2,y2,x3,y3,SOLID,color)
end

local function drawFailsafe(telemetry,utils)
  if telemetry.ekfFailsafe > 0 then
    utils.drawBlinkBitmap("ekffailsafe",LCD_W/2 - 90,154)
  end
  if telemetry.battFailsafe > 0 then
    utils.drawBlinkBitmap("battfailsafe",LCD_W/2 - 90,154)
  end
end

local function drawArmStatus(status,telemetry,utils)
  -- armstatus
  if telemetry.ekfFailsafe == 0 and telemetry.battFailsafe == 0 then
    if statusArmTimeout > 0 then
      -- we are displaying "armed"
      if statusArmTimeout < 10 then -- display "armed" for approx. 1.5 seconds
        lcd.drawBitmap(utils.getBitmap("armed"),LCD_W/2 - 90,154)
        statusArmTimeout = statusArmTimeout + 1
      else
	statusArmTimeout = 0
      end
    end
    if status.timerRunning == 0 then
      if (telemetry.statusArmed == 1) then
        lcd.drawBitmap(utils.getBitmap("armed"),LCD_W/2 - 90,154)
        statusArmTimeout = 1 -- trigger incrementing dialog timeout displaying "armed"
      else
        utils.drawBlinkBitmap("disarmed",LCD_W/2 - 90,154)
	statusArmTimeout = 0
      end
    end
  end
end

local function drawNoTelemetryData(status,telemetry,utils,telemetryEnabled)
  -- no telemetry data
  if (not telemetryEnabled()) then
    lcd.setColor(CUSTOM_COLOR,0xFFFF)
    lcd.drawFilledRectangle(88,74, 304, 84, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,0xF800)
    lcd.drawFilledRectangle(90,76, 300, 80, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,0xFFFF)
    lcd.drawText(110, 85, "no telemetry data", DBLSIZE+CUSTOM_COLOR)
    lcd.drawText(130, 120, "Yaapu Telemetry Widget 1.9.3-beta", SMLSIZE+CUSTOM_COLOR)
  end
end

local function drawFilledRectangle(x,y,w,h,flags)
    if w > 0 and h > 0 then
      lcd.drawFilledRectangle(x,y,w,h,flags)
    end
end


--[[
  based on olliw's improved version over mine :-)
  https://github.com/olliw42/otxtelemetry
--]]
local function drawCompassRibbon(y,myWidget,conf,telemetry,status,battery,utils,width,xMin,xMax,stepWidth,bigFont)
  local minY = y+1
  local heading = telemetry.yaw
  local minX = xMin
  local maxX = xMax
  local midX = (xMax + xMin)/2
  local tickNo = 4 --number of ticks on one side
  local stepCount = (maxX - minX -24)/(2*tickNo)
  local closestHeading = math.floor(heading/22.5) * 22.5
  local closestHeadingX = midX + (closestHeading - heading)/22.5 * stepCount
  local tickIdx = (closestHeading/22.5 - tickNo) % 16
  local tickX = closestHeadingX - tickNo*stepCount   
  for i = 1,10 do
      if tickX >= minX and tickX < maxX then
          if yawRibbonPoints[tickIdx+1] == nil then
              lcd.setColor(CUSTOM_COLOR, 0xFFFF)
              lcd.drawLine(tickX, minY, tickX, y+5, SOLID, CUSTOM_COLOR)
          else
              lcd.setColor(CUSTOM_COLOR, 0xFFFF)
              lcd.drawText(tickX, minY-3, yawRibbonPoints[tickIdx+1], CUSTOM_COLOR+SMLSIZE+CENTER)
          end
      end
      tickIdx = (tickIdx + 1) % 16
      tickX = tickX + stepCount
  end
  -- home icon
  local homeOffset = 0
  local angle = telemetry.homeAngle - telemetry.yaw
  if angle < 0 then angle = angle + 360 end
  if angle > 270 or angle < 90 then
    homeOffset = ((angle + 90) % 180)/180  * width
  elseif angle >= 90 and angle < 180 then
    homeOffset = width
  end
  drawHomeIcon(xMin + homeOffset -5,minY + (bigFont and 28 or 20),utils)
  
  -- text box
  local w = 60 -- 3 digits width
  if heading < 0 then heading = heading + 360 end
  if heading < 10 then
      w = 20
  elseif heading < 100 then
      w = 40
  end
  local scale = bigFont and 1 or 0.7
  lcd.setColor(CUSTOM_COLOR, 0x0000)
  lcd.drawFilledRectangle(midX - (w/2)*scale, minY-2, w*scale, 28*scale, CUSTOM_COLOR+SOLID)
  lcd.setColor(CUSTOM_COLOR, 0xFFFF)
  lcd.drawNumber(midX, bigFont and minY-6 or minY-2, heading, CUSTOM_COLOR+(bigFont and DBLSIZE or 0)+CENTER)
end

-- optimized yaw ribbon drawing
--[[
local function oldDrawCompassRibbon(y,myWidget,conf,telemetry,status,battery,utils,width,xMin,xMax,stepWidth,bigFont)
  -- ribbon centered +/- 90 on yaw
  local centerYaw = (telemetry.yaw + 270 - (bigFont and 16 or 10))%360 -- (-10 needed to center ribbon)
  -- this is the first point left to be drawn on the compass ribbon
  local nextPoint = math.floor(centerYaw/22.5) * 22.5
  -- x coord of first ribbon letter
  local nextPointX = xMin + (nextPoint - centerYaw)/22.5 * stepWidth
  --
  local i = (nextPoint / 22.5) % 16
  for idx=1,12
  do
      local letterOffset = 1
      local lineOffset = 4
      if nextPointX >= xMin -3 and nextPointX < xMax then
        if yawRibbonPoints[i] == nil then
          lcd.setColor(CUSTOM_COLOR,COLOR_LINES)
          lcd.drawLine(nextPointX + lineOffset, y+1, nextPointX + lineOffset, y+7, SOLID, CUSTOM_COLOR)
        else
          if #yawRibbonPoints[i] > 1 then
            letterOffset = -5
            lineOffset = 2
          end
          lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
          --lcd.setColor(CUSTOM_COLOR,COLOR_GREY)
          lcd.drawText(nextPointX+letterOffset,y+(bigFont and -2 or 0),yawRibbonPoints[i],SMLSIZE+CUSTOM_COLOR)
        end
      end
      i = (i + 1) % 16
      nextPointX = nextPointX + stepWidth
  end
  -- home icon
  local homeOffset = 0
  local angle = telemetry.homeAngle - telemetry.yaw
  if angle < 0 then
    angle = 360 + angle
  end
  if angle > 270 or angle < 90 then
    homeOffset = ((angle + 90) % 180)/180  * width
  elseif angle >= 90 and angle <= 180 then
    homeOffset = width
  end
  drawHomeIcon(xMin + homeOffset -5,y + (bigFont and 28 or 20),utils)
  -- yaw angle box
  local xx = 0
  if ( telemetry.yaw < 10) then
    xx = bigFont and 20 or 14
  elseif (telemetry.yaw < 100) then
    xx = bigFont and 40 or 28
  else
    xx = bigFont and 60 or 42
  end
  --lcd.drawNumber(LCD_W/2 + xx - 6, YAW_Y, telemetry.yaw, MIDSIZE+INVERS)
  lcd.setColor(CUSTOM_COLOR,COLOR_BLACK)
  lcd.drawFilledRectangle(LCD_W/2 - (xx/2), y - 1, xx, bigFont and 28 or 20, CUSTOM_COLOR+SOLID)
  lcd.drawRectangle(LCD_W/2 - (xx/2) - 1, y - 1, xx+2, bigFont and 28 or 20, CUSTOM_COLOR+SOLID)
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
  lcd.drawNumber(LCD_W/2 - (xx/2), y - 6, telemetry.yaw, (bigFont and DBLSIZE or MIDSIZE)+CUSTOM_COLOR)
end
--]]

local function drawStatusBar(maxRows,conf,telemetry,status,battery,alarms,frame,utils,gpsStatuses)
  local yDelta = (maxRows-1)*12
  
  lcd.setColor(CUSTOM_COLOR,0x0000)
  lcd.drawFilledRectangle(0,229-yDelta,480,LCD_H-(229-yDelta),CUSTOM_COLOR)
  -- flight time
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  lcd.drawTimer(LCD_W, 224-yDelta, model.getTimer(2).value, DBLSIZE+CUSTOM_COLOR+RIGHT)
  -- flight mode
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  if status.strFlightMode ~= nil then
    lcd.drawText(1,230-yDelta,status.strFlightMode,MIDSIZE+CUSTOM_COLOR)
  end
  -- gps status, draw coordinatyes if good at least once
  if telemetry.lon ~= nil and telemetry.lat ~= nil then
    lcd.drawText(370, 227-yDelta, telemetry.strLat, SMLSIZE+CUSTOM_COLOR+RIGHT)
    lcd.drawText(370, 241-yDelta, telemetry.strLon, SMLSIZE+CUSTOM_COLOR+RIGHT)
  end
  -- gps status
  local hdop = telemetry.gpsHdopC
  local strStatus = gpsStatuses[telemetry.gpsStatus]
  local flags = BLINK
  local mult = 1
  
  if telemetry.gpsStatus  > 2 then
    if telemetry.homeAngle ~= -1 then
      flags = PREC1
    end
    if hdop > 999 then
      hdop = 999
      flags = 0
      mult=0.1
    elseif hdop > 99 then
      flags = 0
      mult=0.1
    end
    -- HDOP
    lcd.drawNumber(270,226-yDelta, hdop*mult,DBLSIZE+flags+RIGHT+CUSTOM_COLOR)
    -- SATS
    lcd.setColor(CUSTOM_COLOR,0xFFFF)
    lcd.drawText(170,226-yDelta, strStatus, SMLSIZE+CUSTOM_COLOR)

    lcd.setColor(CUSTOM_COLOR,0xFFFF)
    if telemetry.numSats == 15 then
      lcd.drawNumber(170,235-yDelta, telemetry.numSats, MIDSIZE+CUSTOM_COLOR)
      lcd.drawText(200,239-yDelta, "+", SMLSIZE+CUSTOM_COLOR)
    else
      lcd.drawNumber(170,235-yDelta,telemetry.numSats, MIDSIZE+CUSTOM_COLOR)
    end
  elseif telemetry.gpsStatus == 0 then
    utils.drawBlinkBitmap("nogpsicon",150,227-yDelta)
  else
    utils.drawBlinkBitmap("nolockicon",150,227-yDelta)
  end
  
  local offset = math.min(maxRows,#status.messages+1)
  for i=0,offset-1 do
    if status.messages[(status.messageCount + i - offset) % (#status.messages+1)][2] < 4 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,70,0))
    elseif status.messages[(status.messageCount + i - offset) % (#status.messages+1)][2] == 4 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,255,0))
    else
      lcd.setColor(CUSTOM_COLOR,0xFFFF)
    end
    lcd.drawText(1,(256-yDelta)+(12*i), status.messages[(status.messageCount + i - offset) % (#status.messages+1)][1],SMLSIZE+CUSTOM_COLOR)
  end
end

return {
  drawNumberWithDim=drawNumberWithDim,
  drawHomeIcon=drawHomeIcon,
  drawHArrow=drawHArrow,
  drawVArrow=drawVArrow,
  drawRArrow=drawRArrow,
  drawGauge=drawGauge,
  computeOutCode=computeOutCode,
  drawLineWithClippingXY=drawLineWithClippingXY,
  drawLineWithClipping=drawLineWithClipping,
  drawFailsafe=drawFailsafe,
  drawArmStatus=drawArmStatus,
  drawNoTelemetryData=drawNoTelemetryData,
  drawStatusBar=drawStatusBar,
  drawFilledRectangle=drawFilledRectangle,
  drawCompassRibbon=drawCompassRibbon,
  --oldDrawCompassRibbon=oldDrawCompassRibbon,
  yawRibbonPoints=yawRibbonPoints
}

