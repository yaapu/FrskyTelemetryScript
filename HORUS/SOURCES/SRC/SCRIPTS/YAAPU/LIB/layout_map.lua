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

--[[
  for info see https://github.com/heldersepu/GMapCatcher
  
  Notes:
  - tiles need to be resized down to 100x100 from original size of 256x256
  - at max zoom level (-2) 1 tile = 100px = 76.5m
]]

--------------------------
-- MINI HUD
--------------------------

--------------------------
-- MAP properties
--------------------------





-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()

-- map support
local posUpdated = false
local myScreenX, myScreenY
local homeScreenX, homeScreenY
local estimatedHomeScreenX, estimatedHomeScreenY
local tile_x,tile_y,offset_x,offset_y
local tiles = {}
local mapBitmapByPath = {}
local nomap = nil
local world_tiles
local tiles_per_radian
local tile_dim
local scaleLen
local scaleLabel
local posHistory = {}
local homeNeedsRefresh = true
local sample = 0
local sampleCount = 0
local lastPosUpdate = getTime()
local lastPosSample = getTime()
local lastHomePosUpdate = getTime()
local lastZoomLevel = -99
local estimatedHomeGps = {
  lat = nil,
  lon = nil
}

local lastProcessCycle = getTime()
local processCycle = 0

local avgDistSamples = {}
local avgDist = 0;
local avgDistSum = 0;
local avgDistSample = 0;
local avgDistSampleCount = 0;
local avgDistLastSampleTime = getTime();
avgDistSamples[0] = 0

local coord_to_tiles = nil
local tiles_to_path = nil
local MinLatitude = -85.05112878;
local MaxLatitude = 85.05112878;
local MinLongitude = -180;
local MaxLongitude = 180;





local function clip(n, min, max)
  return math.min(math.max(n, min), max)
end

local function tiles_on_level(conf,level)
  if conf.mapProvider == 1 then
    return bit32.lshift(1,17 - level)
  else
    return 2^level
  end
end

--[[
  total tiles on the web mercator projection = 2^zoom*2^zoom
--]]
local function get_tile_matrix_size_pixel(level)
    local size = 2^level * 100
    return size, size
end

--[[
  https://developers.google.com/maps/documentation/javascript/coordinates
  https://github.com/judero01col/GMap.NET
  
  Questa funzione ritorna il pixel (assoluto) associato alle coordinate.
  La proiezione di mercatore è una matrice di pixel, tanto più grande quanto è elevato il valore dello zoom.
  zoom 1 = 1x1 tiles
  zoom 2 = 2x2 tiles
  zoom 3 = 4x4 tiles
  ...
  in cui ogni tile è di 256x256 px.
  in generale la matrice ha dimensioni 2^(zoom-1)*2^(zoom-1)
  Per risalire al singolo tile si divide per 256 (largezza del tile):
  
  tile_x = math.floor(x_coord/256)
  tile_y = math.floor(y_coord/256)
  
  Le coordinate relative all'interno del tile si calcolano con l'operatore modulo a partire dall'angolo in alto a sx
  
  x_offset = x_coord%256
  y_offset = y_coord%256
  
  Su filesystem il percorso è /tile_y/tile_x.png
--]]
local function google_coord_to_tiles(conf, lat, lng, level)
  lat = clip(lat, MinLatitude, MaxLatitude)
  lng = clip(lng, MinLongitude, MaxLongitude)

  local x = (lng + 180) / 360
  local sinLatitude = math.sin(lat * math.pi / 180)
  local y = 0.5 - math.log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * math.pi)

  local mapSizeX, mapSizeY = get_tile_matrix_size_pixel(level)

  -- absolute pixel coordinates on the mercator projection at this zoom level
  local rx = clip(x * mapSizeX + 0.5, 0, mapSizeX - 1)
  local ry = clip(y * mapSizeY + 0.5, 0, mapSizeY - 1)
  -- return tile_x, tile_y, offset_x, offset_y
  return math.floor(rx/100), math.floor(ry/100), math.floor(rx%100), math.floor(ry%100)
end

local function gmapcacther_coord_to_tiles(conf, lat, lon, level)
  local x = world_tiles / 360 * (lon + 180)
  local e = math.sin(lat * (1/180 * math.pi))
  local y = world_tiles / 2 + 0.5 * math.log((1+e)/(1-e)) * -1 * tiles_per_radian
  -- return tile_x, tile_y, offset_x, offset_y
  return math.floor(x % world_tiles), math.floor(y % world_tiles), math.floor((x - math.floor(x)) * 100), math.floor((y - math.floor(y)) * 100)
end

local function google_tiles_to_path(conf, tile_x, tile_y, level)
  return string.format("/%d/%d/s_%d.jpg", level, tile_y, tile_x)
end

local function gmapcatcher_tiles_to_path(conf, tile_x, tile_y, level)
  return string.format("/%d/%d/%d/%d/s_%d.png", level, tile_x/1024, tile_x%1024, tile_y/1024, tile_y%1024)
end

local function getTileBitmap(conf,tilePath)
  local fullPath = "/SCRIPTS/YAAPU/MAPS/"..conf.mapType..tilePath
  -- check cache
  if mapBitmapByPath[tilePath] ~= nil then
    return mapBitmapByPath[tilePath]
  end
  
  local bmp = Bitmap.open(fullPath)
  local w,h = Bitmap.getSize(bmp)
  
  if w > 0 then
    mapBitmapByPath[tilePath] = bmp
    return bmp
  else
    if nomap == nil then
      nomap = Bitmap.open("/SCRIPTS/YAAPU/MAPS/nomap.png")
    end
    mapBitmapByPath[tilePath] = nomap
    return nomap
  end
end

local function loadAndCenterTiles(conf,tile_x,tile_y,offset_x,offset_y,width,level)
  -- determine if upper or lower center tile
  local yy = 2
  if offset_y > 100/2 then
    yy = 1
  end
  for x=1,3
  do
    for y=1,2
    do
      local tile_path = tiles_to_path(conf, tile_x+x-2, tile_y+y-yy, level)
      local idx = width*(y-1)+x
      
      if tiles[idx] == nil then
        tiles[idx] = tile_path
      else
        if tiles[idx] ~= tile_path then
          tiles[idx] = tile_path
        end
      end
    end
  end
  -- release unused cached images
  for path, bmp in pairs(mapBitmapByPath) do
    local remove = true
    for i=1,#tiles
    do
      if tiles[i] == path then
        remove = false
      end
    end
    if remove then
      mapBitmapByPath[path]=nil
    end
  end
  -- force a call to destroyBitmap()
  collectgarbage()
  collectgarbage()
end

local function drawTiles(conf,drawLib,width,xmin,xmax,ymin,ymax,color,level)
  for x=1,3
  do
    for y=1,2
    do
      local idx = width*(y-1)+x
      if tiles[idx] ~= nil then
        lcd.drawBitmap(getTileBitmap(conf,tiles[idx]), xmin+(x-1)*100, ymin+(y-1)*100)
      end
    end
  end
  if conf.enableMapGrid then
    -- draw grid
    for x=1,3-1
    do
      lcd.drawLine(xmin+x*100,ymin,xmin+x*100,ymax,DOTTED,color)
    end
    
    for y=1,2-1
    do
      lcd.drawLine(xmin,ymin+y*100,xmax,ymin+y*100,DOTTED,color)
    end
  end
  -- draw 50m or 150ft line at max zoom
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  lcd.drawLine(xmin+5,ymin+2*100-13,xmin+5+scaleLen,ymin+2*100-13,SOLID,CUSTOM_COLOR)
  lcd.drawText(xmin+5,ymin+2*100-27,scaleLabel,SMLSIZE+CUSTOM_COLOR)
end

local function getScreenCoordinates(conf,minX,minY,tile_x,tile_y,offset_x,offset_y,level)
  -- is this tile on screen ?
  local tile_path = tiles_to_path(conf, tile_x, tile_y, level)
  local onScreen = false
  
  for x=1,3
  do
    for y=1,2
    do
      local idx = 3*(y-1)+x
      if tiles[idx] == tile_path then
        -- ok it's on screen
        return minX + (x-1)*100 + offset_x, minY + (y-1)*100 + offset_y
      end
    end
  end
  -- force offscreen up
  return LCD_W/2, -10
end

local function drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils)--getMaxValue,getBitmap,drawBlinkBitmap)
  local r = -telemetry.roll
  local cx,cy,dx,dy
  local yPos = 0 + 20 + 8
  local scale = 0.6
  -----------------------
  -- artificial horizon
  -----------------------
  -- no roll ==> segments are vertical, offsets are multiples of 6.5
  if ( telemetry.roll == 0) then
    dx=0
    dy=telemetry.pitch * scale
    cx=0
    cy=6.5
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -telemetry.pitch * scale
    dy = math.sin(math.rad(90 - r)) * telemetry.pitch * scale
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * 6.5
    cy = math.sin(math.rad(90 - r)) * 6.5
  end
  -----------------------
  -- dark color for "ground"
  -----------------------
  -- 90x70
  local minY = 22
  local maxY = 22+42
  --
  local minX = 7
  local maxX = 7 + 76
  --
  local ox = 7 + 76/2 + dx
  --
  local oy = 43 + dy
  local yy = 0
  
 --lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x0d, 0x68, 0xb1)) -- bighud blue
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x7b, 0x9d, 0xff)) -- default blue
  lcd.drawFilledRectangle(minX,minY,maxX-minX,maxY - minY,CUSTOM_COLOR)
 -- HUD
  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(77, 153, 0))
  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x90, 0x63, 0x20)) --906320 bighud brown
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x63, 0x30, 0x00)) --623000 old brown
  
  -- angle of the line passing on point(ox,oy)
  local angle = math.tan(math.rad(-telemetry.roll))
  -- prevent divide by zero
  if telemetry.roll == 0 then
    drawLib.drawFilledRectangle(minX,math.max(minY,dy+minY+(maxY-minY)/2),maxX-minX,math.min(maxY-minY,(maxY-minY)/2-dy+(math.abs(dy) > 0 and 1 or 0)),CUSTOM_COLOR)
  elseif math.abs(telemetry.roll) >= 180 then
    drawLib.drawFilledRectangle(minX,minY,maxX-minX,math.min(maxY-minY,(maxY-minY)/2+dy),CUSTOM_COLOR)
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
          lcd.drawFilledRectangle(xx, yy, maxX-xx+1, step,CUSTOM_COLOR)
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
          lcd.drawFilledRectangle(minX, yy, xx-minX, step,CUSTOM_COLOR)
        elseif xx > maxX then
          yRect = inverted and math.max(yy,yRect)+step or math.min(yy,yRect)
          fillNeeded = true
        end
      end
    end
    
    if fillNeeded then
      local yMin = inverted and minY or yRect
      local height = inverted and yRect - minY or maxY-yRect
      --lcd.setColor(CUSTOM_COLOR,0xF800) --623000 old brown
      lcd.drawFilledRectangle(minX, yMin, maxX-minX, height ,CUSTOM_COLOR)
    end
  end

  -- parallel lines above and below horizon
  local linesMaxY = maxY-1
  local linesMinY = minY+1
  local rollX = math.floor(7 + 76/2)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  -- +/- 90 deg
  for dist=1,6
  do
    drawLib.drawLineWithClipping(rollX + dx - dist*cx,dy + 43 + dist*cy,r,(dist%2==0 and 40 or 20),DOTTED,7+2,7+76-2,linesMinY,linesMaxY,CUSTOM_COLOR,radio,rev)
    drawLib.drawLineWithClipping(rollX + dx + dist*cx,dy + 43 - dist*cy,r,(dist%2==0 and 40 or 20),DOTTED,7+2,7+76-2,linesMinY,linesMaxY,CUSTOM_COLOR,radio,rev)
  end
  -------------------------------------
  -- hud bitmap
  -------------------------------------
  lcd.drawBitmap(utils.getBitmap("hud_48x48a"),7-2+13,22-3-4)
end

local function drawMap(myWidget,drawLib,conf,telemetry,status,battery,utils,level)
  if tiles_to_path == nil or coord_to_tiles == nil then
    return
  end
  
  local minY = 18
  local maxY = minY+2*100
  
  local minX = (LCD_W-300)/2 
  local maxX = minX+3*100
  
  if telemetry.lat ~= nil and telemetry.lon ~= nil then
    -- position update
    if getTime() - lastPosUpdate > 50 then
      posUpdated = true
      lastPosUpdate = getTime()
      -- current vehicle tile coordinates
      tile_x,tile_y,offset_x,offset_y = coord_to_tiles(conf,telemetry.lat,telemetry.lon,level)
      -- viewport relative coordinates
      myScreenX,myScreenY = getScreenCoordinates(conf,minX,minY,tile_x,tile_y,offset_x,offset_y,level)
      -- check if offscreen
      local myCode = drawLib.computeOutCode(myScreenX, myScreenY, minX+17, minY+17, maxX-17, maxY-17);
      
      -- center vehicle on screen
      if myCode > 0 then
        loadAndCenterTiles(conf, tile_x, tile_y, offset_x, offset_y, 3, level)
        -- after centering screen position needs to be computed again
        tile_x,tile_y,offset_x,offset_y = coord_to_tiles(conf,telemetry.lat,telemetry.lon,level)
        myScreenX,myScreenY = getScreenCoordinates(conf,minX,minY,tile_x,tile_y,offset_x,offset_y,level)
      end
    end
    
    -- home position update
    if getTime() - lastHomePosUpdate > 50 and posUpdated then
      lastHomePosUpdate = getTime()
      if homeNeedsRefresh then
        -- update home, schedule estimated home update
        homeNeedsRefresh = false
        if telemetry.homeLat ~= nil then
          -- current vehicle tile coordinates
          tile_x,tile_y,offset_x,offset_y = coord_to_tiles(conf,telemetry.homeLat,telemetry.homeLon,level)
          -- viewport relative coordinates
          homeScreenX,homeScreenY = getScreenCoordinates(conf,minX,minY,tile_x,tile_y,offset_x,offset_y,level)
        end
      else
        -- update estimated home, schedule home update
        homeNeedsRefresh = true
        estimatedHomeGps.lat,estimatedHomeGps.lon = utils.getHomeFromAngleAndDistance(telemetry)
        if estimatedHomeGps.lat ~= nil then
          local t_x,t_y,o_x,o_y = coord_to_tiles(conf,estimatedHomeGps.lat,estimatedHomeGps.lon,level)
          -- viewport relative coordinates
          estimatedHomeScreenX,estimatedHomeScreenY = getScreenCoordinates(conf,minX,minY,t_x,t_y,o_x,o_y,level)
        end
      end
    end
    
    -- position history sampling
    if getTime() - lastPosSample > 50 and posUpdated then
        lastPosSample = getTime()
        posUpdated = false
        -- points history
        local path = tiles_to_path(conf,tile_x, tile_y, level)
        posHistory[sample] = { path, offset_x, offset_y }
        sampleCount = sampleCount+1
        sample = sampleCount%20
    end
    
    -- draw map tiles
    lcd.setColor(CUSTOM_COLOR,0xFE60)
    drawTiles(conf,drawLib,3,minX,maxX,minY,maxY,CUSTOM_COLOR,level)
    -- draw home
    if telemetry.homeLat ~= nil and telemetry.homeLon ~= nil and homeScreenX ~= nil then
      local homeCode = drawLib.computeOutCode(homeScreenX, homeScreenY, minX+11, minY+10, maxX-11, maxY-10);
      if homeCode == 0 then
	    if conf.enableTxGPS then
		  -- home position is the radio position
		  if getTxGPS() == nil then
            -- internalgps option not included in the OpenTX build - blink the red rcradio symbol
			utils.drawBlinkBitmap("radiored",homeScreenX-11,homeScreenY-10)
          else
            -- draw solid radio
            lcd.drawBitmap(utils.getBitmap("rcradioorange"),homeScreenX-11,homeScreenY-10)
          end
		else
		  -- home position is the armed position, draw a symbol of a house
          lcd.drawBitmap(utils.getBitmap("homeorange"),homeScreenX-11,homeScreenY-10)
		end
      end
    end
    
    --[[
    -- draw estimated home (debug info)
    if estimatedHomeGps.lat ~= nil and estimatedHomeGps.lon ~= nil and estimatedHomeScreenX ~= nil then
      local homeCode = drawLib.computeOutCode(estimatedHomeScreenX, estimatedHomeScreenY, minX+11, minY+10, maxX-11, maxY-10);
      if homeCode == 0 then
        lcd.setColor(CUSTOM_COLOR,COLOR_RED)
        lcd.drawRectangle(estimatedHomeScreenX-11,estimatedHomeScreenY-11,20,20,CUSTOM_COLOR)
      end
    end
    --]]
    
    -- draw vehicle
    if myScreenX ~= nil then
      lcd.setColor(CUSTOM_COLOR,0xFFFF)
      drawLib.drawRArrow(myScreenX,myScreenY,17-5,telemetry.yaw,CUSTOM_COLOR)
      lcd.setColor(CUSTOM_COLOR,0x0000)
      drawLib.drawRArrow(myScreenX,myScreenY,17,telemetry.yaw,CUSTOM_COLOR)
    end
    -- draw gps trace
    lcd.setColor(CUSTOM_COLOR,0xFE60)
    for p=0, math.min(sampleCount-1,20-1)
    do
      if p ~= (sampleCount-1)%20 then
        for x=1,3
        do
          for y=1,2
          do
            local idx = 3*(y-1)+x
            -- check if tile is on screen
            if tiles[idx] == posHistory[p][1] then
              lcd.drawFilledRectangle(minX + (x-1)*100 + posHistory[p][2], minY + (y-1)*100 + posHistory[p][3],3,3,CUSTOM_COLOR)
            end
          end
        end
      end
    end
    -- DEBUG
    lcd.setColor(CUSTOM_COLOR,0xFFFF)
    lcd.drawText((LCD_W-300)/2+5,18+5,string.format("zoom:%d",level),SMLSIZE+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,0xFFFF)
    
    -- LEFT ---
    
    -- ALT
    lcd.setColor(CUSTOM_COLOR,0x0000)
    lcd.drawText(10, 50+16, "Alt("..unitLabel..")", SMLSIZE+0+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,0xFFFF)
    lcd.drawNumber(10,50+27,telemetry.homeAlt*unitScale,MIDSIZE+CUSTOM_COLOR+0)
    -- SPEED
    lcd.setColor(CUSTOM_COLOR,0x0000)
    lcd.drawText(10, 50+54, "Spd("..conf.horSpeedLabel..")", SMLSIZE+0+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,0xFFFF)
    lcd.drawNumber(10,50+65,telemetry.hSpeed*0.1* conf.horSpeedMultiplier,MIDSIZE+CUSTOM_COLOR+0)
    -- VSPEED
    lcd.setColor(CUSTOM_COLOR,0x0000)
    lcd.drawText(10, 50+92, "VSI("..conf.vertSpeedLabel..")", SMLSIZE+0+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,0xFFFF)
    lcd.drawNumber(10,50+103, telemetry.vSpeed*0.1*conf.vertSpeedMultiplier, MIDSIZE+CUSTOM_COLOR+0)
    -- DIST
    if getGeneralSettings().imperial == 0 then
      -- metric, special handling for km
	  local dist = telemetry.homeDist*unitScale
	  if dist > 9999 then
	    -- add "k" for kilo
        lcd.setColor(CUSTOM_COLOR,0x0000)
        lcd.drawText(10, 50+130, "Dist(k"..unitLabel..")", SMLSIZE+0+CUSTOM_COLOR)
        lcd.setColor(CUSTOM_COLOR,0xFFFF)
        lcd.drawNumber(10, 50+141, telemetry.homeDist*unitScale/1000, MIDSIZE+0+CUSTOM_COLOR)
      else
        lcd.setColor(CUSTOM_COLOR,0x0000)
        lcd.drawText(10, 50+130, "Dist("..unitLabel..")", SMLSIZE+0+CUSTOM_COLOR)
        lcd.setColor(CUSTOM_COLOR,0xFFFF)
        lcd.drawNumber(10, 50+141, telemetry.homeDist*unitScale, MIDSIZE+0+CUSTOM_COLOR)
	  end
    else
      -- imperial
      lcd.setColor(CUSTOM_COLOR,0x0000)
      lcd.drawText(10, 50+130, "Dist("..unitLabel..")", SMLSIZE+0+CUSTOM_COLOR)
      lcd.setColor(CUSTOM_COLOR,0xFFFF)
      lcd.drawNumber(10, 50+141, telemetry.homeDist*unitScale, MIDSIZE+0+CUSTOM_COLOR)
    end
    -- RIGHT
    -- CELL
    if battery[1] * 0.01 < 10 then
      lcd.drawNumber(410, 15+5, battery[1] + 0.5, PREC2+0+MIDSIZE+CUSTOM_COLOR)
    else
      lcd.drawNumber(410, 15+5, (battery[1] + 0.5)*0.1, PREC1+0+MIDSIZE+CUSTOM_COLOR)
    end
    lcd.drawText(410+50, 15+6, status.battsource, SMLSIZE+CUSTOM_COLOR)
    lcd.drawText(410+50, 15+16, "V", SMLSIZE+CUSTOM_COLOR)
    -- aggregate batt %
    local strperc = string.format("%2d%%",battery[16])
    lcd.drawText(410+65, 15+30, strperc, MIDSIZE+CUSTOM_COLOR+RIGHT)
    -- Tracker
    lcd.setColor(CUSTOM_COLOR,0x0000)
    lcd.drawText(410, 15+70, "Tracker", SMLSIZE+0+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,0xFFFF)
    lcd.drawText(410, 15+82, string.format("%d@",(telemetry.homeAngle - 180) < 0 and telemetry.homeAngle + 180 or telemetry.homeAngle - 180), MIDSIZE+0+CUSTOM_COLOR)
    -- HDG
    lcd.setColor(CUSTOM_COLOR,0x0000)
    lcd.drawText(410, 15+110, "Heading", SMLSIZE+0+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,0xFFFF)
    lcd.drawText(410, 15+122, string.format("%d@",telemetry.yaw), MIDSIZE+0+CUSTOM_COLOR)
    -- home
    lcd.setColor(CUSTOM_COLOR,0xFE60)
    drawLib.drawRArrow(410+28,15+175,22,math.floor(telemetry.homeAngle - telemetry.yaw),CUSTOM_COLOR)
  end
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
end

local initDone = false

local function init(conf,utils,level)
  if level ~= lastZoomLevel then
    utils.clearTable(tiles)
    utils.clearTable(mapBitmapByPath)
    utils.clearTable(posHistory)
    
    sample = 0
    sampleCount = 0    
    
    world_tiles = tiles_on_level(conf,level)
    tiles_per_radian = world_tiles / (2 * math.pi)
    
    if conf.mapProvider == 1 then
      coord_to_tiles = gmapcacther_coord_to_tiles
      tiles_to_path = gmapcatcher_tiles_to_path
      tile_dim = (40075017/world_tiles) * unitScale -- m or ft
      scaleLabel = tostring((unitScale==1 and 1 or 3)*50*2^(level+2))..unitLabel
      scaleLen = ((unitScale==1 and 1 or 3)*50*2^(level+2)/tile_dim)*100
    elseif conf.mapProvider == 2 then
      coord_to_tiles = google_coord_to_tiles
      tiles_to_path = google_tiles_to_path
      tile_dim = (40075017/world_tiles) * unitScale -- m or ft
      scaleLabel = tostring((unitScale==1 and 1 or 3)*50*2^(20-level))..unitLabel
      scaleLen = ((unitScale==1 and 1 or 3)*50*2^(20-level)/tile_dim)*100
    end

    lastZoomLevel = level
  end
end

local function changeZoomLevel(level)
end

local function draw(myWidget,drawLib,conf,telemetry,status,battery,alarms,frame,utils,customSensors,gpsStatuses,leftPanel,centerPanel,rightPanel)
  -- initialize maps
  init(conf,utils,status.mapZoomLevel)
  drawMap(myWidget,drawLib,conf,telemetry,status,battery,utils,status.mapZoomLevel)
  drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils)
  utils.drawTopBar()
  drawLib.drawStatusBar(2,conf,telemetry,status,battery,alarms,frame,utils,gpsStatuses)
  drawLib.drawArmStatus(status,telemetry,utils)
  drawLib.drawFailsafe(telemetry,utils)
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {draw=draw,background=background,changeZoomLevel=changeZoomLevel}

