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














-----------------------
-- COMPASS RIBBON
-----------------------




-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()

local function drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils)

  local r = -telemetry.roll
  local cx,cy,dx,dy
  local yPos = 0 + 20 + 8
  -----------------------
  -- artificial horizon
  -----------------------
  -- no roll ==> segments are vertical, offsets are multiples of 25
  if ( telemetry.roll == 0) then
    dx=0
    dy=telemetry.pitch
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -telemetry.pitch
    dy = math.sin(math.rad(90 - r)) * telemetry.pitch
  end
  local rollX = math.floor((LCD_W-158)/2 + 158/2)
  -----------------------
  -- dark color for "ground"
  -----------------------
  -- 140x110
  local minY = 24
  local maxY = 24 + 90
  
  local minX = (LCD_W-158)/2 + 1
  local maxX = (LCD_W-158)/2 + 158
  
  local ox = (LCD_W-158)/2 + 158/2 + dx + 5
  local oy = 69 + dy
  local yy = 0
  
  lcd.drawFilledRectangle(minX,minY,158,maxY-minY,lcd.RGB(0x7B,0x9D,0xFF)) -- default blue
  -- angle of the line passing on point(ox,oy)
  local angle = math.tan(math.rad(-telemetry.roll))
  -- for each pixel of the hud base/top draw vertical black 
  -- lines from hud border to horizon line
  -- horizon line moves with pitch/roll
  if math.abs(telemetry.roll) < 90 then
    if oy > minY and oy < maxY then
      lcd.drawFilledRectangle(minX,oy,158,maxY-oy + 1,lcd.RGB(0x63,0x30,0x00)) -- 0x623000 = old brown
    elseif oy <= minY then
      lcd.drawFilledRectangle(minX,minY,158,maxY-minY,lcd.RGB(0x63,0x30,0x00)) -- 0x623000 = old brown
    end
  else
    --inverted
    if oy > minY and oy < maxY then
      lcd.drawFilledRectangle(minX,minY,158,oy-minY + 1,lcd.RGB(0x63,0x30,0x00)) -- 0x623000 = old brown
    elseif oy >= maxY then
      lcd.drawFilledRectangle(minX,minY,158,maxY-minY,lcd.RGB(0x63,0x30,0x00)) -- 0x623000 = old brown
    end
  end
  --
-- parallel lines above and below horizon
  --
  local hx = math.cos(math.rad(90 - r)) * -(telemetry.pitch%45)
  local hy = math.sin(math.rad(90 - r)) * (telemetry.pitch%45)
  
  --drawLineWithClipping(rollX - hx, 69 + hy,r,50,SOLID,(LCD_W-158)/2,(LCD_W-158)/2 + 158,minY,maxY,WHITE)
  
  for line=0,4
  do
    --
    local deltax = math.cos(math.rad(90 - r)) * 20 * line
    local deltay = math.sin(math.rad(90 - r)) * 20 * line
    --
    drawLib.drawLineWithClipping(rollX - deltax + hx, 69 + deltay + hy,r,50,DOTTED,(LCD_W-158)/2,(LCD_W-158)/2 + 158,minY,maxY,WHITE,radio,rev)
    drawLib.drawLineWithClipping(rollX + deltax + hx, 69 - deltay + hy,r,50,DOTTED,(LCD_W-158)/2,(LCD_W-158)/2 + 158,minY,maxY,WHITE,radio,rev)
  end

  local xx = math.cos(math.rad(r)) * 70 * 0.5
  local yy = math.sin(math.rad(r)) * 70 * 0.5
  --
  local x0 = rollX - xx
  local y0 = 69 - yy
  --
  local x1 = rollX + xx
  local y1 = 69 + yy   
  --
  drawLib.drawLineWithClipping(x0,y0,r + 90,70,SOLID,(LCD_W-158)/2,(LCD_W-158)/2 + 158,minY,maxY,WHITE,radio,rev)
  drawLib.drawLineWithClipping(x1,y1,r + 90,70,SOLID,(LCD_W-158)/2,(LCD_W-158)/2 + 158,minY,maxY,WHITE,radio,rev)
  -------------------------------------
  -- hud bitmap
  -------------------------------------
  lcd.drawBitmap(utils.getBitmap("hud_160x90_rus"),(LCD_W-158)/2,24) --160x90
  -------------------------------------
  -- vario bitmap
  -------------------------------------
  local varioMax = 5
  local varioSpeed = math.min(math.abs(0.1*telemetry.vSpeed),5)
  local varioH = varioSpeed/varioMax*35
  if telemetry.vSpeed > 0 then
    varioY = 24 + 35 - varioH
  else
    varioY = 24 + 55
  end
  --00ae10
  lcd.drawFilledRectangle(310, varioY, 10, varioH, lcd.RGB(0xFF,0xCE,0x00), 0) -- yellow
  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- DATA
  -- altitude
  local alt = utils.getMaxValue(telemetry.homeAlt,11) * unitScale
  if math.abs(alt) > 999 then
    lcd.drawNumber((LCD_W-158)/2+158 - 42,69-10,alt,lcd.RGB(0x19,0xFF,0x52)) -- 0x1FEA = 0x19FF52 = bright green
  elseif math.abs(alt) >= 10 then
    lcd.drawNumber((LCD_W-158)/2+158 - 42,69-14,alt,MIDSIZE+lcd.RGB(0x19,0xFF,0x52)) -- 0x1FEA = 0x19FF52 = bright green
  else
    lcd.drawNumber((LCD_W-158)/2+158 - 42,69-14,alt*10,MIDSIZE+PREC1+lcd.RGB(0x19,0xFF,0x52)) -- 0x1FEA = 0x19FF52 = bright green
  end
  -- telemetry.hSpeed is in dm/s
  local hSpeed = utils.getMaxValue(telemetry.hSpeed,14) * 0.1 * conf.horSpeedMultiplier
  if (math.abs(hSpeed) >= 10) then
    lcd.drawNumber((LCD_W-158)/2+44,69-14,hSpeed,MIDSIZE+RIGHT+lcd.RGB(0x19,0xFF,0x52)) -- 0x1FEA = 0x19FF52 = bright green
  else
    lcd.drawNumber((LCD_W-158)/2+44,69-14,hSpeed*10,MIDSIZE+RIGHT+lcd.RGB(0x19,0xFF,0x52)+PREC1) -- 0x1FEA = 0x19FF52 = bright green
  end
  -- min/max arrows
  if status.showMinMaxValues == true then
    drawLib.drawVArrow((LCD_W-158)/2+50, 69-9,true,false,utils)
    drawLib.drawVArrow((LCD_W-158)/2+158-57, 69-9,true,false,utils)
  end
    -- compass ribbon
  drawLib.drawCompassRibbon(120,myWidget,conf,telemetry,status,battery,utils,140,(LCD_W-140)/2,(LCD_W+140)/2,15)
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawHud=drawHud,background=background}

