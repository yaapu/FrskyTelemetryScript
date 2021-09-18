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






-- x:300 y:135 inside HUD








-----------------------
-- COMPASS RIBBON
-----------------------






-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()

local function drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils)

  local r = -telemetry.roll
  local cx,cy,dx,dy--,ccx,ccy,cccx,cccy
  local yPos = 0 + 20 + 8
  local scale = 1.85 -- 1.85
  -----------------------
  -- artificial horizon
  -----------------------
  -- no roll ==> segments are vertical, offsets are multiples of 18.5
  if ( telemetry.roll == 0 or math.abs(telemetry.roll) == 180) then
    dx=0
    dy=telemetry.pitch * scale
    cx=0
    cy=18.5
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -telemetry.pitch
    dy = math.sin(math.rad(90 - r)) * telemetry.pitch * scale
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * 18.5
    cy = math.sin(math.rad(90 - r)) * 18.5
  end
  local rollX = math.floor((LCD_W-280)/2 + 280/2)
  -----------------------
  -- dark color for "ground"
  -----------------------
  -- 140x90
  local minY = 18
  local maxY = 18 + 134
  
  local minX = (LCD_W-280)/2 
  local maxX = (LCD_W-280)/2 + 280
  
  local ox = (LCD_W-280)/2 + 280/2 + dx
  local oy = 85 + dy
  local yy = 0
  
  lcd.drawBitmap(utils.getBitmap("hud_bg_280x134"),(LCD_W-280)/2,18) --160x90  
  -- HUD
  -- angle of the line passing on point(ox,oy)
  local angle = math.tan(math.rad(-telemetry.roll))
  -- prevent divide by zero
  if telemetry.roll == 0 then
    drawLib.drawFilledRectangle(minX,math.max(minY,dy+minY+(maxY-minY)/2),maxX-minX,math.min(maxY-minY,(maxY-minY)/2-dy+(math.abs(dy) > 0 and 1 or 0)),lcd.RGB(0x63,0x30,0x00)) -- 0x623000 = old brown
  elseif math.abs(telemetry.roll) >= 180 then
    drawLib.drawFilledRectangle(minX,minY,maxX-minX,math.min(maxY-minY,(maxY-minY)/2+dy),lcd.RGB(0x63,0x30,0x00)) -- 0x623000 = old brown
  else
    -- HUD drawn using horizontal bars of height 2
    -- true if flying inverted
    local inverted = math.abs(telemetry.roll) > 90
    -- true if part of the hud can be filled in one pass with a rectangle
    local fillNeeded = false
    local yRect = inverted and 0 or LCD_H
    
    local step = 2
    local steps = (maxY - minY)/step - 1
    local yy = 0
    
    if 0 < telemetry.roll and telemetry.roll < 180 then
      for s=0,steps
      do
        yy = minY + s*step
        xx = ox + (yy-oy)/angle
        if xx >= minX and xx <= maxX then
          lcd.drawFilledRectangle(xx, yy, maxX-xx+1, step,lcd.RGB(0x63,0x30,0x00)) -- 0x623000 = old brown
        elseif xx < minX then
          yRect = inverted and math.max(yy,yRect)+step or math.min(yy,yRect)
          fillNeeded = true
        end
      end
    elseif -180 < telemetry.roll and telemetry.roll < 0 then
      for s=0,steps
      do
        yy = minY + s*step
        xx = ox + (yy-oy)/angle
        if xx >= minX and xx <= maxX then
          lcd.drawFilledRectangle(minX, yy, xx-minX, step,lcd.RGB(0x63,0x30,0x00)) -- 0x623000 = old brown
        elseif xx > maxX then
          yRect = inverted and math.max(yy,yRect)+step or math.min(yy,yRect)
          fillNeeded = true
        end
      end
    end
    
    if fillNeeded then
      local yMin = inverted and minY or yRect
      local height = inverted and yRect - minY or maxY-yRect
      lcd.drawFilledRectangle(minX, yMin, maxX-minX, height,lcd.RGB(0x63,0x30,0x00)) -- 0x623000 = old brown
    end
  end

  
  -- parallel lines above and below horizon
  local linesMaxY = maxY-2
  local linesMinY = minY+10
  -- +/- 90 deg
  for dist=1,6
  do
    drawLib.drawLineWithClipping(rollX + dx - dist*cx,dy + 85 + dist*cy,r,(dist%2==0 and 80 or 40),DOTTED,(LCD_W-280)/2+2,(LCD_W-280)/2+280-2,linesMinY,linesMaxY,WHITE,radio,rev)
    drawLib.drawLineWithClipping(rollX + dx + dist*cx,dy + 85 - dist*cy,r,(dist%2==0 and 80 or 40),DOTTED,(LCD_W-280)/2+2,(LCD_W-280)/2+280-2,linesMinY,linesMaxY,WHITE,radio,rev)
  end
  
  --[[
  -- horizon line
  drawLib.drawLineWithClipping(rollX + dx,dy + HUD_Y_MID,r,200, SOLID, HUD_X+2,HUD_X+HUD_WIDTH-2,linesMinY,linesMaxY,lcd.RGB(160,160,160),radio,rev)
  --]]
  
  -- hashmarks
  local startY = minY + 1
  local endY = maxY - 10
  local step = 18
  -- hSpeed 
  local roundHSpeed = math.floor((telemetry.hSpeed*conf.horSpeedMultiplier*0.1/5)+0.5)*5;
  local offset = math.floor((telemetry.hSpeed*conf.horSpeedMultiplier*0.1-roundHSpeed)*0.2*step);
  local ii = 0;  
  local yy = 0  
  for j=roundHSpeed+20,roundHSpeed-20,-5
  do
      yy = startY + (ii*step) + offset - 14
      if yy >= startY and yy < endY then
        lcd.drawLine((LCD_W-280)/2, yy+9, (LCD_W-280)/2 + 4, yy+9, SOLID, lcd.RGB(120,120,120))
        lcd.drawNumber((LCD_W-280)/2 + 7,  yy, j, SMLSIZE+lcd.RGB(120,120,120))
      end
      ii=ii+1;
  end
  -- altitude 
  local roundAlt = math.floor((telemetry.homeAlt*unitScale/5)+0.5)*5;
  offset = math.floor((telemetry.homeAlt*unitScale-roundAlt)*0.2*step);
  ii = 0;  
  yy = 0
  for j=roundAlt+20,roundAlt-20,-5
  do
      yy = startY + (ii*step) + offset - 14
      if yy >= startY and yy < endY then
        lcd.drawLine((LCD_W-280)/2 + 280 - 14, yy+8, (LCD_W-280)/2 + 280-10 , yy+8, SOLID, lcd.RGB(120,120,120))
        lcd.drawNumber((LCD_W-280)/2 + 280 - 16,  yy, j, SMLSIZE+RIGHT+lcd.RGB(120,120,120))
      end
      ii=ii+1;
  end
  
  -------------------------------------
  -- hud bitmap
  -------------------------------------
  lcd.drawBitmap(utils.getBitmap("hud_280x134"),(LCD_W-280)/2,18) --160x90
  
  -------------------------------------
  -- vario
  -------------------------------------
  local varioMax = 5
  local varioSpeed = math.min(math.abs(0.1*telemetry.vSpeed),5)
  local varioH = varioSpeed/varioMax*52
  --varioH = varioH + (varioH > 0 and 1 or 0)
  if telemetry.vSpeed > 0 then
    varioY = 19 + (52 - varioH)
  else
    varioY = 85 + 15
  end
  --00ae10
  lcd.drawFilledRectangle(372, varioY, 8, varioH, lcd.RGB(0xFF,0xCE,0x00), 0) -- yellow
  
  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- DATA
  -- altitude
  local alt = utils.getMaxValue(telemetry.homeAlt,11) * unitScale
  if math.abs(alt) > 999 or alt < -99 then
    lcd.drawNumber((LCD_W-280)/2+280+1,85-16,alt,MIDSIZE+lcd.RGB(0x00,0xED,0x32)+RIGHT) -- green
  elseif math.abs(alt) >= 10 then
    lcd.drawNumber((LCD_W-280)/2+280+1,85-20,alt,DBLSIZE+lcd.RGB(0x00,0xED,0x32)+RIGHT) -- green
  else
    lcd.drawNumber((LCD_W-280)/2+280+1,85-20,alt*10,DBLSIZE+PREC1+lcd.RGB(0x00,0xED,0x32)+RIGHT) -- green
  end
  -- telemetry.hSpeed is in dm/s
  local hSpeed = utils.getMaxValue(telemetry.hSpeed,14) * 0.1 * conf.horSpeedMultiplier
  if (math.abs(hSpeed) >= 10) then
    lcd.drawNumber((LCD_W-280)/2+2,85-20,hSpeed,DBLSIZE+lcd.RGB(0x00,0xED,0x32)) -- green
  else
    lcd.drawNumber((LCD_W-280)/2+2,85-20,hSpeed*10,DBLSIZE+lcd.RGB(0x00,0xED,0x32)+PREC1) -- green
  end
  -- lcd.setColor(CUSTOM_COLOR,0xFFFF)  
  -- min/max arrows
  if status.showMinMaxValues == true then
    drawLib.drawVArrow((LCD_W-280)/2+68, 85-12,true,false,utils)
    drawLib.drawVArrow((LCD_W-280)/2+280-79, 85-12,true,false,utils)
  end
  
  -- vspeed box
  -- lcd.setColor(CUSTOM_COLOR,0xFFFF)
  local vSpeed = utils.getMaxValue(telemetry.vSpeed,13) * 0.1 -- m/s
  
  local xx = math.abs(vSpeed*conf.vertSpeedMultiplier) > 999 and 4 or 3
  xx = xx + (vSpeed*conf.vertSpeedMultiplier < 0 and 1 or 0)
  
  if math.abs(vSpeed*conf.vertSpeedMultiplier*10) > 99 then -- 
    lcd.drawNumber((LCD_W)/2 + (xx/2)*12, 127, vSpeed*conf.vertSpeedMultiplier, MIDSIZE+WHITE+RIGHT)
  else
    lcd.drawNumber((LCD_W)/2 + (xx/2)*12, 127, vSpeed*conf.vertSpeedMultiplier*10, MIDSIZE+WHITE+RIGHT+PREC1)
  end
  
  -- compass ribbon
  drawLib.drawCompassRibbon(18,myWidget,conf,telemetry,status,battery,utils,240,(LCD_W-240)/2,(LCD_W+240)/2,25,true)
  -- pitch and roll
  local xoffset =  math.abs(telemetry.pitch) > 99 and 6 or 0
  lcd.drawNumber(248+xoffset,90,telemetry.pitch,lcd.RGB(0xFF,0xCE,0x00)+SMLSIZE+RIGHT) -- yellow
  lcd.drawNumber(214,76,telemetry.roll,lcd.RGB(0xFF,0xCE,0x00)+SMLSIZE+RIGHT)
  -- lcd.setColor(CUSTOM_COLOR,0xFFFF)  
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawHud=drawHud,background=background}
