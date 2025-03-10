--
-- A FRSKY SPort/FPort/FPort2 and TBS CRSF telemetry widget for the Ethos OS
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

local HUD_W = 240
local HUD_H = 130
local HUD_X = (480 - HUD_W)/2
local HUD_Y = 18

local function getTime()
  -- os.clock() resolution is 0.01 secs
  return os.clock()*100 -- 1/100th
end

local function getBitmapsPath()
  -- local path from script root
  return "./../../bitmaps/"
end

local function getLogsPath()
  -- local path from script root
  return "./../../logs/"
end

local function getYaapuBitmapsPath()
  -- local path from script root
  return "./bitmaps/"
end

local function getYaapuAudioPath()
  -- local path from script root
  return "./audio/"
end

local function getYaapuLibPath()
  -- local path from script root
  return "./lib/"
end


local mapLib = {}

local status = nil
local libs = nil

--------------------------
-- MAP properties
--------------------------
local MAP_X = 0
local MAP_Y = 0
local VEHICLE_R = 20
local TILE_BORDER = 25

local DIST_SAMPLES = 10

-- map support
local posUpdated = false
local myScreenX, myScreenY
local homeScreenX, homeScreenY
local estimatedHomeScreenX, estimatedHomeScreenY
local tile_x,tile_y,offset_x,offset_y
local home_tile_x,home_tile_y,home_offset_x,home_offset_y
local tiles = {}
local tilesXYByPath = {}
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

local TILES_X = 8
local TILES_Y = 3
local TILES_SIZE = 100
local TILES_DIM = 76.5
local TILES_IDX_BMP = 1
local TILES_IDX_PATH  = 2

local zoomUpdateTimer = getTime()
local zoomUpdate = false

local n1,n2

local function getMapBitmapsPath()
  -- local path from script root
  return status.conf.mapTilesStoragePathPrefix.."/bitmaps/"
end

function mapLib.clip(n, min, max)
  return math.min(math.max(n, min), max)
end

function mapLib.tiles_on_level(level)
  if status.conf.mapProvider == 1 then
    return 2^(17-level)
  else
    return 2^level
  end
end

--[[
  total tiles on the web mercator projection = 2^zoom*2^zoom
--]]
function mapLib.get_tile_matrix_size_pixel(level)
    local size = 2^level * TILES_SIZE
    return size, size
end

--[[
  https://developers.google.com/maps/documentation/javascript/coordinates
  https://github.com/judero01col/GMap.NET
--]]
function mapLib.google_coord_to_tiles(lat, lng, level)
  lat = mapLib.clip(lat, MinLatitude, MaxLatitude)
  lng = mapLib.clip(lng, MinLongitude, MaxLongitude)

  local x = (lng + 180) / 360
  local sinLatitude = math.sin(lat * math.pi / 180)
  local y = 0.5 - math.log((1 + sinLatitude) / (1 - sinLatitude)) / (4 * math.pi)

  local mapSizeX, mapSizeY = mapLib.get_tile_matrix_size_pixel(level)

  -- absolute pixel coordinates on the mercator projection at this zoom level
  local rx = mapLib.clip(x * mapSizeX + 0.5, 0, mapSizeX - 1)
  local ry = mapLib.clip(y * mapSizeY + 0.5, 0, mapSizeY - 1)
  -- return tile_x, tile_y, offset_x, offset_y
  return math.floor(rx/TILES_SIZE), math.floor(ry/TILES_SIZE), math.floor(rx%TILES_SIZE), math.floor(ry%TILES_SIZE)
end

function mapLib.gmapcatcher_coord_to_tiles(lat, lon, level)
  local x = world_tiles / 360 * (lon + 180)
  local e = math.sin(lat * (1/180 * math.pi))
  local y = world_tiles / 2 + 0.5 * math.log((1+e)/(1-e)) * -1 * tiles_per_radian
  return math.floor(x % world_tiles), math.floor(y % world_tiles), math.floor((x - math.floor(x)) * TILES_SIZE), math.floor((y - math.floor(y)) * TILES_SIZE)
end

function mapLib.google_tiles_to_path(tile_x, tile_y, level)
  return string.format("/%d/%.0f/s_%.0f.jpg", level, tile_y, tile_x)
end

function mapLib.gmapcatcher_tiles_to_path(tile_x, tile_y, level)
  return string.format("/%d/%.0f/%.0f/%.0f/s_%.0f.png", level, tile_x/1024, tile_x%1024, tile_y/1024, tile_y%1024)
end

function mapLib.getTileBitmap(tilePath)
  local fullPath = getMapBitmapsPath().."yaapu/maps/"..status.conf.mapType..tilePath
  -- check cache
  if mapBitmapByPath[tilePath] ~= nil then
    return mapBitmapByPath[tilePath]
  end

  local tmp = io.open(fullPath,"r")
  if tmp ~= nil  then
    print("OK",fullPath)
    io.close(tmp)
    mapBitmapByPath[tilePath] = lcd.loadBitmap(fullPath)
    return mapBitmapByPath[tilePath]
  else
    print("ERROR",fullPath)
    if nomap == nil then
      nomap = lcd.loadBitmap(getMapBitmapsPath().."yaapu/maps/nomap.png")
    end
    mapBitmapByPath[tilePath] = nomap
    return nomap
  end
end

function mapLib.loadAndCenterTiles(tile_x,tile_y,offset_x,offset_y,width,level)
  -- determine if upper or lower center tile
  for x=1,TILES_X
  do
    for y=1,TILES_Y
    do
      local tile_path = mapLib.tiles_to_path(tile_x + x - math.floor(TILES_X/2 + 0.5), tile_y + y - math.floor(TILES_Y/2 + 0.5), level)
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
      tilesXYByPath[tile_path] = {x,y}
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
      tilesXYByPath[path] = nil
    end
  end
  -- force a call to destroyBitmap()
  collectgarbage()
  collectgarbage()
end


function mapLib.drawTiles(width,xmin,xmax,ymin,ymax,color,level)
  for x=1,TILES_X
  do
    for y=1,TILES_Y
    do
      local idx = width*(y-1)+x
      if tiles[idx] ~= nil then
        lcd.drawBitmap(xmin+(x-1)*TILES_SIZE, ymin+(y-1)*TILES_SIZE, mapLib.getTileBitmap(tiles[idx]))
      end
    end
  end
  if status.conf.enableMapGrid then
    -- draw grid
    lcd.pen(DOTTED)
    lcd.color(color)
    for x=1,TILES_X-1
    do
      lcd.drawLine(xmin+x*TILES_SIZE,ymin,xmin+x*TILES_SIZE,ymax)
    end

    for y=1,TILES_Y-1
    do
      lcd.drawLine(xmin,ymin+y*TILES_SIZE,xmax,ymin+y*TILES_SIZE)
    end
  end
  local x = xmin
  local y = ymax
  -- map overlay
  lcd.pen(SOLID)
  local alpha = 0.25
  lcd.color(lcd.RGB(0,0,0,alpha))
  lcd.drawFilledRectangle(3, y-25, x+5+scaleLen, 22)
  --libs.drawLib.drawBitmap(5, y-8, "maps_box_380x20") --160x90
  -- draw 50m or 150ft line at max zoom
  lcd.color(WHITE)
  lcd.font(FONT_STD)
  lcd.drawLine(x+5,y-8,x+5+scaleLen,y-8)
  lcd.drawText(x+5,y-25,string.format("%s (%d)", scaleLabel, status.mapZoomLevel))
end

function mapLib.getScreenCoordinates(minX,minY,tile_x,tile_y,offset_x,offset_y,level)
  -- is this tile on screen ?
  local tile_path = mapLib.tiles_to_path(tile_x, tile_y, level)
  local tcache = tiles_path_to_idx[tile_path]
  if tcache ~= nil then
    if tiles[tcache[1]] ~= nil then
      -- ok it's on screen
      return minX + (tcache[2]-1)*TILES_SIZE + offset_x, minY + (tcache[3]-1)*TILES_SIZE + offset_y
    end
  end
  -- force offscreen up
  return 480/2, -10
end

function mapLib.drawMap(widget, x, y, w, h, level, tiles_x, tiles_y, heading)
  lcd.setClipping(x,y,w,h)
  setupMaps(x, y, w, h, level, tiles_x, tiles_y)

  if mapLib.tiles_to_path == nil or mapLib.coord_to_tiles == nil then
    return
  end

  local minX = math.max(0, MAP_X)
  local minY = math.max(0, MAP_Y)

  local maxX = math.min(minX+w, minX+TILES_X*TILES_SIZE)
  local maxY = math.min(minY+h, minY+TILES_Y*TILES_SIZE)


  if status.telemetry.lat ~= nil and status.telemetry.lon ~= nil then
    -- position update
    if zoomUpdate or (getTime() - lastPosUpdate > 50) then
      posUpdated = true
      lastPosUpdate = getTime()
      -- current vehicle tile coordinates
      tile_x,tile_y,offset_x,offset_y = mapLib.coord_to_tiles(status.telemetry.lat, status.telemetry.lon,level)
      -- viewport relative coordinates
      myScreenX,myScreenY = mapLib.getScreenCoordinates(minX,minY,tile_x,tile_y,offset_x,offset_y,level)
      -- check if offscreen, and increase border on X axis
      local myCode = libs.drawLib.computeOutCode(myScreenX, myScreenY, minX+TILE_BORDER, minY+TILE_BORDER, maxX-TILE_BORDER, maxY-TILE_BORDER);

      -- center vehicle on screen
      if myCode > 0 then
        mapLib.loadAndCenterTiles(tile_x, tile_y, offset_x, offset_y, TILES_X, level)
        -- after centering screen position needs to be computed again
        tile_x,tile_y,offset_x,offset_y = mapLib.coord_to_tiles(status.telemetry.lat, status.telemetry.lon,level)
        myScreenX,myScreenY = mapLib.getScreenCoordinates(minX,minY,tile_x,tile_y,offset_x,offset_y,level)
      end
    end
    -- home position update
    if getTime() - lastHomePosUpdate > 30 and posUpdated then
      lastHomePosUpdate = getTime()
      if homeNeedsRefresh then
        -- update home, schedule estimated home update
        homeNeedsRefresh = false
        if status.telemetry.homeLat ~= nil then
          -- current vehicle tile coordinates
          home_tile_x,home_tile_y,home_offset_x,home_offset_y = mapLib.coord_to_tiles(status.telemetry.homeLat, status.telemetry.homeLon, level)
          -- viewport relative coordinates
          homeScreenX,homeScreenY = mapLib.getScreenCoordinates(minX,minY,home_tile_x,home_tile_y,home_offset_x,home_offset_y,level)
        end
      else
        -- update estimated home, schedule home update
        homeNeedsRefresh = true
      end
      collectgarbage()
      collectgarbage()
    end

    -- position history sampling
    if getTime() - lastPosSample > 50 and posUpdated then
        lastPosSample = getTime()
        posUpdated = false
        -- points history
        local path = mapLib.tiles_to_path(tile_x, tile_y, level)
        posHistory[sample] = { path, offset_x, offset_y }
        collectgarbage()
        collectgarbage()
        sampleCount = sampleCount+1
        sample = sampleCount%status.conf.mapTrailDots
    end

    -- draw map tiles
    mapLib.drawTiles(TILES_X, minX, maxX, minY, maxY, status.colors.yellow, level)

    -- draw home
    if status.telemetry.homeLat ~= nil and status.telemetry.homeLon ~= nil and homeScreenX ~= nil then
      local homeCode = libs.drawLib.computeOutCode(homeScreenX, homeScreenY, minX+11, minY+10, maxX-11, maxY-10);
      if homeCode == 0 then
        libs.drawLib.drawBitmap(homeScreenX-11, homeScreenY-10, "homeorange")
      end
    end

    -- draw vehicle
    if myScreenX ~= nil then
      if heading ~= nil then
        libs.drawLib.drawRArrow(myScreenX, myScreenY, VEHICLE_R-5, heading, status.colors.white)
        libs.drawLib.drawRArrow(myScreenX, myScreenY, VEHICLE_R, heading, status.colors.black)
      else
        lcd.color(WHITE)
        lcd.drawCircle(myScreenX, myScreenY, VEHICLE_R-3)
        lcd.color(BLACK)
        lcd.drawCircle(myScreenX, myScreenY, VEHICLE_R)
      end
      -- wp support
      if status.wpEnabledMode == 1 and status.wpEnabled == 1 and status.telemetry.wpNumber > 0 then
        -- draw current waypoint info in white
        -- calc new position on odd cycles
        if status.wpLat ~= nil and status.wpLon ~= nil then
          tile_x, tile_y, offset_x, offset_y = mapLib.coord_to_tiles(status.wpLat,status.wpLon,level)
          wpScreenX, wpScreenY = mapLib.getScreenCoordinates(minX, minY, tile_x, tile_y, offset_x, offset_y, level)
        end
        if wpScreenX ~= nil and wpScreenY ~= nil then
          local myCode = libs.drawLib.computeOutCode(wpScreenX, wpScreenY, minX+11, minY+10, maxX-11, maxY-10);
          lcd.color(WHITE)
          if myCode == 0 then
            lcd.pen(DOTTED)
            lcd.drawLine(myScreenX, myScreenY, wpScreenX, wpScreenY)
            lcd.drawRectangle(wpScreenX-2, wpScreenY-2, 4, 4)
            lcd.font(FONT_STD)
            lcd.drawText(wpScreenX, wpScreenY, status.telemetry.wpNumber)
          else
            libs.drawLib.drawLineByOriginAndAngle(myScreenX, myScreenY, status.telemetry.wpBearing-90, 2*(maxX-minX), minX, minY, maxX, maxY, false)
          end
        end
      end

    end
    -- trailing dots
    lcd.color(status.colors.yellow)
    for p=0, math.min(sampleCount-1,status.conf.mapTrailDots-1)
    do
      if p ~= (sampleCount-1)%status.conf.mapTrailDots then
        -- check if on screen
        if tilesXYByPath[posHistory[p][1]] ~= nil then
          local x = tilesXYByPath[posHistory[p][1]][1]
          local y = tilesXYByPath[posHistory[p][1]][2]
          lcd.drawFilledRectangle(minX + (x-1)*TILES_SIZE + posHistory[p][2]-1, minY + (y-1)*TILES_SIZE + posHistory[p][3]-1,3,3)
        end
      end
    end
  end


  if zoomUpdate == true then
    lcd.color(WHITE)
    lcd.font(FONT_XXL)
    lcd.drawText(480/2, 272/2 - 15, string.format("ZOOM %d", level), CENTERED)

    if getTime() - zoomUpdateTimer > 100 then
      zoomUpdate = false
    end
  end
  lcd.setClipping()
end

function setupMaps(x, y, w, h, level, tiles_x, tiles_y)
  if level == nil or tiles_x == nil or tiles_y == nil or x == nil or y == nil then
    return
  end

  MAP_X = x
  MAP_Y = y
  TILES_X = tiles_x
  TILES_Y = tiles_y

  if level ~= lastZoomLevel then
    zoomUpdateTimer = getTime()
    zoomUpdate = true

    libs.resetLib.clearTable(tiles)
    libs.resetLib.clearTable(mapBitmapByPath)
    libs.resetLib.clearTable(posHistory)

    sample = 0
    sampleCount = 0

    world_tiles = mapLib.tiles_on_level(level)
    tiles_per_radian = world_tiles / (2 * math.pi)

    if status.conf.mapProvider == 1 then
      mapLib.coord_to_tiles = mapLib.gmapcatcher_coord_to_tiles
      mapLib.tiles_to_path = mapLib.gmapcatcher_tiles_to_path
      tile_dim = (40075017/world_tiles) * status.conf.distUnitScale -- m or ft
      scaleLabel = string.format("%.0f%s",(status.conf.distUnitScale==1 and 1 or 3)*50*2^(level+2),status.conf.distUnitLabel)
      scaleLen = ((status.conf.distUnitScale==1 and 1 or 3)*50*2^(level+2)/tile_dim)*TILES_SIZE
    elseif status.conf.mapProvider == 2 then
      mapLib.coord_to_tiles = mapLib.google_coord_to_tiles
      mapLib.tiles_to_path = mapLib.google_tiles_to_path
      tile_dim = (40075017/world_tiles) * status.conf.distUnitScale -- m or ft
      scaleLabel = string.format("%.0f%s", (status.conf.distUnitScale==1 and 1 or 3)*50*2^(20-level), status.conf.distUnitLabel)
      scaleLen = ((status.conf.distUnitScale==1 and 1 or 3)*50*2^(20-level)/tile_dim)*TILES_SIZE
    end
    lastZoomLevel = level
  end
end

function mapLib.init(param_status, param_libs)
  status = param_status
  libs = param_libs
  return mapLib
end

return mapLib
