--
-- A FRSKY SPort/FPort/FPort2 and TBS CRSF telemetry widget for the Horus class radios
-- based on ArduPilot's passthrough telemetry protocol
--
-- Author: Alessandro Apostoli, https://github.com/yaapu
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
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"


local mapLib = {}

local status
local telemetry
local conf
local utils
local libs

local MAP_X = (LCD_W-300)/2
local MAP_Y = 18
local TILES_X = 3
local TILES_Y = 2

--[[
  for info see https://github.com/heldersepu/GMapCatcher

  Notes:
  - tiles need to be resized down to 100x100 from original size of 256x256
  - at max zoom level (-2) 1 tile = 100px = 76.5m
]]

-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()

-- map support
local posUpdated = false
local myScreenX, myScreenY
local homeScreenX, homeScreenY
local estimatedHomeScreenX, estimatedHomeScreenY
local wpScreenX,wpScreenY
local tile_x,tile_y,offset_x,offset_y
local tiles = {}
local tiles_path_to_idx = {} -- path to idx cache
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

local drawCycle = 0
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

function mapLib.init(param_status, param_telemetry, param_conf, param_utils, param_libs)
  status = param_status
  telemetry = param_telemetry
  conf = param_conf
  utils = param_utils
  libs = param_libs
end

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
local function google_coord_to_tiles(lat, lng, level)
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

local function gmapcacther_coord_to_tiles(lat, lon, level)
  local x = world_tiles / 360 * (lon + 180)
  local e = math.sin(lat * (1/180 * math.pi))
  local y = world_tiles / 2 + 0.5 * math.log((1+e)/(1-e)) * -1 * tiles_per_radian
  -- return tile_x, tile_y, offset_x, offset_y
  return math.floor(x % world_tiles), math.floor(y % world_tiles), math.floor((x - math.floor(x)) * 100), math.floor((y - math.floor(y)) * 100)
end

local function google_tiles_to_path(tile_x, tile_y, level)
  return string.format("/%d/%d/s_%d.jpg", level, tile_y, tile_x)
end

local function gmapcatcher_tiles_to_path(tile_x, tile_y, level)
  return string.format("/%d/%d/%d/%d/s_%d.png", level, tile_x/1024, tile_x%1024, tile_y/1024, tile_y%1024)
end

local function getTileBitmap(tilePath)
  local fullPath = "/IMAGES/yaapu/maps/"..conf.mapType..tilePath
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

local function loadAndCenterTiles(tile_x,tile_y,offset_x,offset_y,width,level)
  -- determine if upper or lower center tile
  local yy = 2
  if offset_y > 100/2 then
    yy = 1
  end
  for x=1,TILES_X
  do
    for y=1,TILES_Y
    do
      local tile_path = tiles_to_path(tile_x+x-2, tile_y+y-yy, level)
      local idx = width*(y-1)+x

      if tiles[idx] == nil then
        tiles[idx] = tile_path
        tiles_path_to_idx[tile_path] = { idx, x, y }
      else
        if tiles[idx] ~= tile_path then
          tiles[idx] = tile_path
          tiles_path_to_idx[tile_path] =  { idx, x, y }
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
      tiles_path_to_idx[path]=nil
    end
  end
  -- force a call to destroyBitmap()
  collectgarbage()
  collectgarbage()
end

local function drawTiles(width,xmin,xmax,ymin,ymax,color,level)
  for x=1,TILES_X
  do
    for y=1,TILES_Y
    do
      local idx = width*(y-1)+x
      if tiles[idx] ~= nil then
        lcd.drawBitmap(getTileBitmap(tiles[idx]), xmin+(x-1)*100, ymin+(y-1)*100)
      end
    end
  end
  if conf.enableMapGrid then
    -- draw grid
    for x=1,TILES_X-1
    do
      lcd.drawLine(xmin+x*100,ymin,xmin+x*100,ymax,DOTTED,color)
    end

    for y=1,TILES_Y-1
    do
      lcd.drawLine(xmin,ymin+y*100,xmax,ymin+y*100,DOTTED,color)
    end
  end
  -- draw 50m or 150ft line at max zoom
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawLine(xmin+5,212,xmin+5+scaleLen,212,SOLID,CUSTOM_COLOR)
  lcd.drawText(xmin+5,198,scaleLabel,SMLSIZE+CUSTOM_COLOR)
end

local function getScreenCoordinates(minX,minY,tile_x,tile_y,offset_x,offset_y,level)
  -- is this tile on screen ?
  local tile_path = tiles_to_path(tile_x, tile_y, level)
  local tcache = tiles_path_to_idx[tile_path]
  if tcache ~= nil then
    if tiles[tcache[1]] ~= nil then
      -- ok it's on screen
      return minX + (tcache[2]-1)*100 + offset_x, minY + (tcache[3]-1)*100 + offset_y
    end
  end
  -- force offscreen up
  return LCD_W/2, -10
end

local function setupMaps(x, y, level, tiles_x, tiles_y)
  if level == nil or tiles_x == nil or tiles_y == nil or x == nil or y == nil then
    return
  end

  MAP_X = x
  MAP_Y = y

  TILES_X = tiles_x
  TILES_Y = tiles_y

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
  drawCycle = (drawCycle+1) % 2
end

function mapLib.drawMap(widget, x, y, level, tiles_x, tiles_y)
  setupMaps(x, y, level, tiles_x, tiles_y)

  if tiles_to_path == nil or coord_to_tiles == nil then
    return
  end

  local minY = MAP_Y
  local maxY = minY+TILES_Y*100

  local minX = MAP_X
  local maxX = minX+TILES_X*100

  if telemetry.lat ~= nil and telemetry.lon ~= nil then
    -- position update on even cycles
    if getTime() - lastPosUpdate > 50 and drawCycle%2==0 then
      posUpdated = true
      lastPosUpdate = getTime()
      -- current vehicle tile coordinates
      tile_x,tile_y,offset_x,offset_y = coord_to_tiles(telemetry.lat,telemetry.lon,level)
      -- viewport relative coordinates
      myScreenX,myScreenY = getScreenCoordinates(minX,minY,tile_x,tile_y,offset_x,offset_y,level)
      -- check if offscreen
      local myCode = libs.drawLib.computeOutCode(myScreenX, myScreenY, minX+17, minY+17, maxX-17, maxY-17);

      -- center vehicle on screen
      if myCode > 0 then
        loadAndCenterTiles(tile_x, tile_y, offset_x, offset_y, TILES_X, level)
        -- after centering screen position needs to be computed again
        tile_x,tile_y,offset_x,offset_y = coord_to_tiles(telemetry.lat,telemetry.lon,level)
        myScreenX,myScreenY = getScreenCoordinates(minX,minY,tile_x,tile_y,offset_x,offset_y,level)
      end
    end

    -- home position update on odd cycles
    if getTime() - lastHomePosUpdate > 50 and posUpdated and drawCycle%2==0 then
      lastHomePosUpdate = getTime()
      if homeNeedsRefresh then
        -- update home, schedule estimated home update
        homeNeedsRefresh = false
        if telemetry.homeLat ~= nil then
          -- current vehicle tile coordinates
          tile_x,tile_y,offset_x,offset_y = coord_to_tiles(telemetry.homeLat,telemetry.homeLon,level)
          -- viewport relative coordinates
          homeScreenX,homeScreenY = getScreenCoordinates(minX,minY,tile_x,tile_y,offset_x,offset_y,level)
        end
      else
        -- schedule home update
        homeNeedsRefresh = true
      --[[
        -- update estimated home,
        estimatedHomeGps.lat,estimatedHomeGps.lon = utils.getLatLonFromAngleAndDistance(telemetry, telemetry.homeAngle, telemetry.homeDist)
        if estimatedHomeGps.lat ~= nil then
          local t_x,t_y,o_x,o_y = coord_to_tiles(conf,estimatedHomeGps.lat,estimatedHomeGps.lon,level)
          -- viewport relative coordinates
          estimatedHomeScreenX,estimatedHomeScreenY = getScreenCoordinates(conf,minX,minY,t_x,t_y,o_x,o_y,level)
        end
      --]]
      end
    end

    -- position history sampling
    if getTime() - lastPosSample > 25 and posUpdated then
        lastPosSample = getTime()
        posUpdated = false
        -- points history
        local path = tiles_to_path(tile_x, tile_y, level)
        posHistory[sample] = { path, offset_x, offset_y }
        sampleCount = sampleCount+1
        sample = sampleCount%10
    end

    -- draw map tiles
    lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
    drawTiles(TILES_X,minX,maxX,minY,maxY,CUSTOM_COLOR,level)
    -- draw home on odd
    if telemetry.homeLat ~= nil and telemetry.homeLon ~= nil and homeScreenX ~= nil then
      local homeCode = libs.drawLib.computeOutCode(homeScreenX, homeScreenY, minX+11, minY+10, maxX-11, maxY-10);
      if homeCode == 0 then
        lcd.drawBitmap(utils.getBitmap("homeorange"),homeScreenX-11,homeScreenY-10)
      end
    end

    --[[
    -- draw estimated home (debug info)
    if estimatedHomeGps.lat ~= nil and estimatedHomeGps.lon ~= nil and estimatedHomeScreenX ~= nil then
      local homeCode = libs.drawLib.computeOutCode(estimatedHomeScreenX, estimatedHomeScreenY, minX+11, minY+10, maxX-11, maxY-10);
      if homeCode == 0 then
        lcd.setColor(CUSTOM_COLOR,COLOR_RED)
        lcd.drawRectangle(estimatedHomeScreenX-11,estimatedHomeScreenY-11,20,20,CUSTOM_COLOR)

      end
    end
    --]]

    -- draw vehicle
    if myScreenX ~= nil then
      lcd.setColor(CUSTOM_COLOR,WHITE)
      libs.drawLib.drawRArrow(myScreenX,myScreenY,17-5,telemetry.yaw,CUSTOM_COLOR)
      lcd.setColor(CUSTOM_COLOR,BLACK)
      libs.drawLib.drawRArrow(myScreenX,myScreenY,17,telemetry.yaw,CUSTOM_COLOR)
      -- WP drawing enabled only for selected flight modes
      -- AUTO, GUIDED, LOITER, RTL, QRTL, QLOITER, QLAND, FOLLOW, ZIGZAG
      if status.wpEnabledMode == 1 and status.wpEnabled == 1 and telemetry.wpNumber > 0 then
        -- wp number and distance
        lcd.setColor(CUSTOM_COLOR,utils.colors.white)
        lcd.drawBitmap(utils.getBitmap("maps_box_60x16"),MAP_X+300-62,MAP_Y+2)
        lcd.drawBitmap(utils.getBitmap("maps_box_60x16"),MAP_X+300-62,MAP_Y+20)
        lcd.drawBitmap(utils.getBitmap("maps_box_60x16"),MAP_X+300-62,MAP_Y+40)
        lcd.drawText(MAP_X+300-2, MAP_Y+2, string.format("#%d",telemetry.wpNumber),SMLSIZE+CUSTOM_COLOR+RIGHT)
        lcd.drawText(MAP_X+300-2, MAP_Y+20, string.format("%d%s",telemetry.wpDistance * unitScale,unitLabel),SMLSIZE+CUSTOM_COLOR+RIGHT)
        lcd.drawText(MAP_X+300-2, MAP_Y+40, string.format("%d",telemetry.wpBearing),SMLSIZE+CUSTOM_COLOR+RIGHT)
        -- draw current waypoint info in white
        -- calc new position on odd cycles
        if drawCycle%2==1 and status.wpLat ~= nil and status.wpLon ~= nil then
          tile_x,tile_y,offset_x,offset_y = coord_to_tiles(status.wpLat, status.wpLon, level)
          wpScreenX,wpScreenY = getScreenCoordinates(minX,minY,tile_x,tile_y,offset_x,offset_y,level)
        end
        if wpScreenX ~= nil then
          local myCode = libs.drawLib.computeOutCode(wpScreenX, wpScreenY, minX+4, minY+4, maxX-4, maxY-4);
          lcd.setColor(CUSTOM_COLOR,utils.colors.white)
          if myCode == 0 then
            lcd.drawLine(myScreenX,myScreenY,wpScreenX,wpScreenY,DOTTED,CUSTOM_COLOR)
            lcd.drawRectangle(wpScreenX-2,wpScreenY-2,4,4,CUSTOM_COLOR)
            lcd.drawText(wpScreenX,wpScreenY,telemetry.wpNumber,SMLSIZE+CUSTOM_COLOR)
          else
            libs.drawLib.drawLineByOriginAndAngle(myScreenX, myScreenY, telemetry.wpBearing-90, 2*300, DOTTED, MAP_X+2, MAP_X+300-2, MAP_Y, MAP_Y+200, CUSTOM_COLOR, false)
          end
        end
      end
    end
    -- draw gps trace
    lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
    for p=0, math.min(sampleCount-1,10-1)
    do
      if p ~= (sampleCount-1)%10 then
        local tcache = tiles_path_to_idx[posHistory[p][1]]
        if tcache ~= nil then
          if tiles[tcache[1]] ~= nil then
            -- ok it's on screen
            lcd.drawFilledRectangle(minX + (tcache[2]-1)*100 + posHistory[p][2], minY + (tcache[3]-1)*100 + posHistory[p][3],3,3,CUSTOM_COLOR)
          end
        end
      end
    end
    lcd.drawBitmap(utils.getBitmap("maps_box_60x16"),MAP_X+3,MAP_Y+3)
    lcd.setColor(CUSTOM_COLOR,WHITE)
    lcd.drawText(MAP_X+5,MAP_Y+2,string.format("zoom:%d",level),SMLSIZE+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    --[[
    if status.cog ~= nil then
      lcd.drawBitmap(utils.getBitmap("maps_box_60x16"),MAP_X+3,MAP_Y+41)
      lcd.drawText(MAP_X+5,MAP_Y+40,string.format("cog:%d",status.cog),SMLSIZE+CUSTOM_COLOR)
    end
    --]]
  end
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
end

return mapLib
