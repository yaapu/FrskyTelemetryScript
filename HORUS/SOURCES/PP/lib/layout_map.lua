#include "includes/yaapu_inc.lua"
--[[
  for info see https://github.com/heldersepu/GMapCatcher
  
  Notes:
  - tiles need to be resized down to 100x100 from original size of 256x256
  - at max zoom level (-2) 1 tile = 100px = 76.5m
]]--

--------------------------
-- MINI HUD
--------------------------
#define HUD_Y 24
#define HUD_H 48
#define HUD_W 48
#define HUD_X 21
#define HUD_Y_MID 48
#define R2 10

--------------------------
-- MAP properties
--------------------------
#define MAP_W 300
#define MAP_H 200
#define MAP_X (LCD_W-MAP_W)/2
#define MAP_Y 18


#define HOME_R 10
#define VEHICLE_R 17
#define SAMPLES 10
#define DIST_SAMPLES 10


#define TXT_X_LEFT 10
#define TXT_Y_LEFT 50
#define TXT_X_RIGHT 410
#define TXT_Y_RIGHT 15
#define TXT_ALIGN 0

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

#define MAP_MAX_ZOOM_LEVEL 17

#define TILES_X 3
#define TILES_Y 2

#define TILES_WIDTH 100
#define TILES_HEIGHT 100
#define TILES_DIM 76.5

#define TILES_IDX_BMP 1
#define TILES_IDX_PATH 2

local function tiles_on_level(level)
 return bit32.lshift(1,MAP_MAX_ZOOM_LEVEL - level)
end

local function coord_to_tiles(lat,lon)
  local x = world_tiles / 360 * (lon + 180)
  local e = math.sin(lat * (1/180 * math.pi))
  local y = world_tiles / 2 + 0.5 * math.log((1+e)/(1-e)) * -1 * tiles_per_radian
  return math.floor(x % world_tiles), math.floor(y % world_tiles), math.floor((x - math.floor(x)) * TILES_WIDTH), math.floor((y - math.floor(y)) * TILES_HEIGHT)
end

local function tiles_to_path(tile_x, tile_y, level)
  local path = string.format("/%d/%d/%d/%d/s_%d.png", level, tile_x/1024, tile_x%1024, tile_y/1024, tile_y%1024)
  collectgarbage()
  collectgarbage()
  return path
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
  if offset_y > TILES_HEIGHT/2 then
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
      else
        if tiles[idx] ~= tile_path then
          tiles[idx] = nil
          collectgarbage()
          collectgarbage()
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
  for x=1,TILES_X
  do
    for y=1,TILES_Y
    do
      local idx = width*(y-1)+x
      if tiles[idx] ~= nil then
        lcd.drawBitmap(getTileBitmap(conf,tiles[idx]), xmin+(x-1)*TILES_WIDTH, ymin+(y-1)*TILES_HEIGHT)
      end
    end
  end
  if conf.enableMapGrid then
    -- draw grid
    for x=1,TILES_X-1
    do
      lcd.drawLine(xmin+x*TILES_WIDTH,ymin,xmin+x*TILES_WIDTH,ymax,DOTTED,color)
    end
    
    for y=1,TILES_Y-1
    do
      lcd.drawLine(xmin,ymin+y*TILES_HEIGHT,xmax,ymin+y*TILES_HEIGHT,DOTTED,color)
    end
  end
  -- draw 50m or 150ft line at max zoom
  lcd.setColor(CUSTOM_COLOR,COLOR_WHITE)
  lcd.drawLine(xmin+5,ymin+TILES_Y*TILES_HEIGHT-13,xmin+5+scaleLen,ymin+TILES_Y*TILES_HEIGHT-13,SOLID,CUSTOM_COLOR)
  lcd.drawText(xmin+5,ymin+TILES_Y*TILES_HEIGHT-27,scaleLabel,SMLSIZE+CUSTOM_COLOR)
end

local function getScreenCoordinates(minX,minY,tile_x,tile_y,offset_x,offset_y,level)
  -- is this tile on screen ?
  local tile_path = tiles_to_path(tile_x,tile_y,level)
  local onScreen = false
  
  for x=1,TILES_X
  do
    for y=1,TILES_Y
    do
      local idx = TILES_X*(y-1)+x
      if tiles[idx] == tile_path then
        -- ok it's on screen
        return minX + (x-1)*TILES_WIDTH + offset_x, minY + (y-1)*TILES_HEIGHT + offset_y
      end
    end
  end
  -- force offscreen up
  return LCD_W/2, -10
end

local function drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils)--getMaxValue,getBitmap,drawBlinkBitmap)
  local r = -telemetry.roll
  local cx,cy,dx,dy,ccx,ccy,cccx,cccy
  local yPos = TOPBAR_Y + TOPBAR_HEIGHT + 8
  -----------------------
  -- artificial horizon
  -----------------------
  -- no roll ==> segments are vertical, offsets are multiples of R2
  if ( telemetry.roll == 0) then
    dx=0
    dy=telemetry.pitch * 0.75
    cx=0
    cy=R2
    ccx=0
    ccy=2*R2
    cccx=0
    cccy=3*R2
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -telemetry.pitch * 0.75
    dy = math.sin(math.rad(90 - r)) * telemetry.pitch * 0.75
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * R2
    cy = math.sin(math.rad(90 - r)) * R2
  end
  -----------------------
  -- dark color for "ground"
  -----------------------
  -- 90x70
  local minY = HUD_Y
  local maxY = HUD_Y+HUD_H
  --
  local minX = HUD_X
  local maxX = HUD_X + HUD_W
  --
  local ox = HUD_X + HUD_W/2 + dx
  --
  local oy = HUD_Y_MID + dy
  local yy = 0
  
 --lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x0d, 0x68, 0xb1)) -- bighud blue
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x7b, 0x9d, 0xff)) -- default blue
  lcd.drawFilledRectangle(minX,minY,maxX-minX,maxY - minY,CUSTOM_COLOR)
 -- HUD
  #include "includes/hud_algo_inc.lua"
  -- parallel lines above and below horizon
  local linesMaxY = maxY-1
  local linesMinY = minY+1
  local rollX = math.floor(HUD_X + HUD_W/2)
  lcd.setColor(CUSTOM_COLOR,COLOR_WHITE)
  -- +/- 90 deg
  for dist=1,8
  do
    drawLib.drawLineWithClipping(rollX + dx - dist*cx,dy + HUD_Y_MID + dist*cy,r,(dist%2==0 and 40 or 20),DOTTED,HUD_X+2,HUD_X+HUD_W-2,linesMinY,linesMaxY,CUSTOM_COLOR,radio,rev)
    drawLib.drawLineWithClipping(rollX + dx + dist*cx,dy + HUD_Y_MID - dist*cy,r,(dist%2==0 and 40 or 20),DOTTED,HUD_X+2,HUD_X+HUD_W-2,linesMinY,linesMaxY,CUSTOM_COLOR,radio,rev)
  end
  -------------------------------------
  -- hud bitmap
  -------------------------------------
  lcd.drawBitmap(utils.getBitmap("hud_48x48a"),HUD_X-2,HUD_Y-3)
end

local function drawMap(myWidget,drawLib,conf,telemetry,status,battery,utils,level)
#ifdef TESTMODE
  -- move hor
  if getValue("ch1") > 100 then
    telemetry.lon = telemetry.lon + 0.000005
  elseif getValue("ch1") < -100 then
    telemetry.lon = telemetry.lon - 0.000005
  end
  -- move ver
  if getValue("ch2") > 100 then
    telemetry.lat = telemetry.lat > 0 and telemetry.lat + 0.000005 or telemetry.lat - 0.000005
  elseif getValue("ch2") < -100 then
    telemetry.lat = telemetry.lat > 0 and telemetry.lat - 0.000005 or telemetry.lat + 0.000005
  end
#endif  
  local minY = MAP_Y
  local maxY = minY+TILES_Y*TILES_HEIGHT
  
  local minX = MAP_X 
  local maxX = minX+TILES_X*TILES_WIDTH
  
  if telemetry.lat ~= nil and telemetry.lon ~= nil then
    -- position update
    if getTime() - lastPosUpdate > 50 then
      posUpdated = true
      lastPosUpdate = getTime()
      -- current vehicle tile coordinates
      tile_x,tile_y,offset_x,offset_y = coord_to_tiles(telemetry.lat,telemetry.lon)
      -- viewport relative coordinates
      myScreenX,myScreenY = getScreenCoordinates(minX,minY,tile_x,tile_y,offset_x,offset_y,level)
      -- check if offscreen
      local myCode = drawLib.computeOutCode(myScreenX, myScreenY, minX+VEHICLE_R, minY+VEHICLE_R, maxX-VEHICLE_R, maxY-VEHICLE_R);
      
      -- center vehicle on screen
      if myCode > 0 then
        loadAndCenterTiles(conf, tile_x, tile_y, offset_x, offset_y, TILES_X, level)
        -- after centering screen position needs to be computed again
        tile_x,tile_y,offset_x,offset_y = coord_to_tiles(telemetry.lat,telemetry.lon)
        myScreenX,myScreenY = getScreenCoordinates(minX,minY,tile_x,tile_y,offset_x,offset_y,level)
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
          tile_x,tile_y,offset_x,offset_y = coord_to_tiles(telemetry.homeLat,telemetry.homeLon)
          -- viewport relative coordinates
          homeScreenX,homeScreenY = getScreenCoordinates(minX,minY,tile_x,tile_y,offset_x,offset_y,level)
        end
      else
        -- update estimated home, schedule home update
        homeNeedsRefresh = true
        estimatedHomeGps.lat,estimatedHomeGps.lon = utils.getHomeFromAngleAndDistance(telemetry)
        if estimatedHomeGps.lat ~= nil then
          local t_x,t_y,o_x,o_y = coord_to_tiles(estimatedHomeGps.lat,estimatedHomeGps.lon)
          -- viewport relative coordinates
          estimatedHomeScreenX,estimatedHomeScreenY = getScreenCoordinates(minX,minY,t_x,t_y,o_x,o_y,level)        
        end
      end
      collectgarbage()
      collectgarbage()
    end
    
    -- position history sampling
    if getTime() - lastPosSample > 50 and posUpdated then
        lastPosSample = getTime()
        posUpdated = false
        -- points history
        local path = tiles_to_path(tile_x, tile_y, level)
        posHistory[sample] = { path, offset_x, offset_y }
        collectgarbage()
        collectgarbage()
        sampleCount = sampleCount+1
        sample = sampleCount%SAMPLES
    end
    
    -- draw map tiles
    lcd.setColor(CUSTOM_COLOR,COLOR_YELLOW)
    drawTiles(conf,drawLib,TILES_X,minX,maxX,minY,maxY,CUSTOM_COLOR,level)
    -- draw home
    if telemetry.homeLat ~= nil and telemetry.homeLon ~= nil and homeScreenX ~= nil then
      local homeCode = drawLib.computeOutCode(homeScreenX, homeScreenY, minX+11, minY+10, maxX-11, maxY-10);
      if homeCode == 0 then
        lcd.drawBitmap(utils.getBitmap("homeorange"),homeScreenX-11,homeScreenY-10)
      end
    end
    -- draw vehicle
    if myScreenX ~= nil then
      lcd.setColor(CUSTOM_COLOR,COLOR_WHITE)
      drawLib.drawRArrow(myScreenX,myScreenY,VEHICLE_R-5,telemetry.yaw,CUSTOM_COLOR)
      lcd.setColor(CUSTOM_COLOR,COLOR_BLACK)
      drawLib.drawRArrow(myScreenX,myScreenY,VEHICLE_R,telemetry.yaw,CUSTOM_COLOR)
    end
    -- draw gps trace
    lcd.setColor(CUSTOM_COLOR,COLOR_YELLOW)
    for p=0, math.min(sampleCount-1,SAMPLES-1)
    do
      if p ~= (sampleCount-1)%SAMPLES then
        for x=1,TILES_X
        do
          for y=1,TILES_Y
          do
            local idx = TILES_X*(y-1)+x
            -- check if tile is on screen
            if tiles[idx] == posHistory[p][1] then
              lcd.drawFilledRectangle(minX + (x-1)*TILES_WIDTH + posHistory[p][2], minY + (y-1)*TILES_HEIGHT + posHistory[p][3],3,3,CUSTOM_COLOR)
            end
          end
        end
      end
    end
    -- DEBUG
    lcd.setColor(CUSTOM_COLOR,COLOR_WHITE)
    lcd.drawText(MAP_X+5,MAP_Y+5,string.format("zoom:%d",level),SMLSIZE+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
    
    -- LEFT ---
    
    -- ALT
    lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)
    lcd.drawText(TXT_X_LEFT, TXT_Y_LEFT+25, "Alt("..UNIT_ALT_LABEL..")", SMLSIZE+TXT_ALIGN+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
    lcd.drawNumber(TXT_X_LEFT,TXT_Y_LEFT+37,telemetry.homeAlt*UNIT_ALT_SCALE,MIDSIZE+CUSTOM_COLOR+TXT_ALIGN)
    -- SPEED
    lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)
    lcd.drawText(TXT_X_LEFT, TXT_Y_LEFT+60, "Spd("..UNIT_HSPEED_LABEL..")", SMLSIZE+TXT_ALIGN+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
    lcd.drawNumber(TXT_X_LEFT,TXT_Y_LEFT+72,telemetry.hSpeed*0.1* UNIT_HSPEED_SCALE,MIDSIZE+CUSTOM_COLOR+TXT_ALIGN)
    -- VSPEED
    lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)
    lcd.drawText(TXT_X_LEFT, TXT_Y_LEFT+95, "VSI("..UNIT_VSPEED_LABEL..")", SMLSIZE+TXT_ALIGN+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
    lcd.drawNumber(TXT_X_LEFT,TXT_Y_LEFT+107, telemetry.vSpeed*0.1*UNIT_VSPEED_SCALE, MIDSIZE+CUSTOM_COLOR+TXT_ALIGN)
    -- DIST
    lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)
    lcd.drawText(TXT_X_LEFT, TXT_Y_LEFT+130, "Dist("..UNIT_DIST_LABEL..")", SMLSIZE+TXT_ALIGN+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
    lcd.drawNumber(TXT_X_LEFT, TXT_Y_LEFT+142, telemetry.homeDist*UNIT_DIST_SCALE, MIDSIZE+TXT_ALIGN+CUSTOM_COLOR)
    
    -- RIGHT
    -- CELL
    if battery[BATT_CELL] * 0.01 < 10 then
      lcd.drawNumber(TXT_X_RIGHT, TXT_Y_RIGHT+5, battery[BATT_CELL] + 0.5, PREC2+TXT_ALIGN+MIDSIZE+CUSTOM_COLOR)
    else
      lcd.drawNumber(TXT_X_RIGHT, TXT_Y_RIGHT+5, (battery[BATT_CELL] + 0.5)*0.1, PREC1+TXT_ALIGN+MIDSIZE+CUSTOM_COLOR)
    end
    lcd.drawText(TXT_X_RIGHT+50, TXT_Y_RIGHT+6, status.battsource, SMLSIZE+CUSTOM_COLOR)
    lcd.drawText(TXT_X_RIGHT+50, TXT_Y_RIGHT+16, "V", SMLSIZE+CUSTOM_COLOR)
    -- aggregate batt %
    local perc = battery[BATT_PERC]
    local strperc = string.format("%2d%%",perc)
    lcd.drawText(TXT_X_RIGHT+65, TXT_Y_RIGHT+30, strperc, MIDSIZE+CUSTOM_COLOR+RIGHT)
    -- Tracker
    lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)
    lcd.drawText(TXT_X_RIGHT, TXT_Y_RIGHT+70, "Tracker", SMLSIZE+TXT_ALIGN+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
    lcd.drawText(TXT_X_RIGHT, TXT_Y_RIGHT+82, string.format("%d@",(telemetry.homeAngle - 180) < 0 and telemetry.homeAngle + 180 or telemetry.homeAngle - 180), MIDSIZE+TXT_ALIGN+CUSTOM_COLOR)
    -- HDG
    lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)
    lcd.drawText(TXT_X_RIGHT, TXT_Y_RIGHT+110, "Heading", SMLSIZE+TXT_ALIGN+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
    lcd.drawText(TXT_X_RIGHT, TXT_Y_RIGHT+122, string.format("%d@",telemetry.yaw), MIDSIZE+TXT_ALIGN+CUSTOM_COLOR)
    -- home
    lcd.setColor(CUSTOM_COLOR,COLOR_YELLOW)
    drawLib.drawRArrow(TXT_X_RIGHT+28,TXT_Y_RIGHT+175,22,math.floor(telemetry.homeAngle - telemetry.yaw),CUSTOM_COLOR)
  end
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
#ifdef HUDTIMER
  hudDrawTime = hudDrawTime + (getTime() - hudStart)
  hudDrawCounter = hudDrawCounter + 1
#endif
end

local initDone = false

local function init(utils,level)
  if level ~= lastZoomLevel then
    utils.clearTable(tiles)
    
    utils.clearTable(mapBitmapByPath)
    
    utils.clearTable(posHistory)
    sample = 0
    sampleCount = 0    
    
    world_tiles = tiles_on_level(level)
    tiles_per_radian = world_tiles / (2 * math.pi)
    tile_dim = (40075017/world_tiles) * unitScale -- m or ft
  
    scaleLen = ((unitScale==1 and 1 or 3)*50*(level+3)/tile_dim)*TILES_WIDTH
    scaleLabel = tostring((unitScale==1 and 1 or 3)*50*(level+3))..unitLabel
    
    lastZoomLevel = level
  end
end

local function changeZoomLevel(level)

end

local function draw(myWidget,drawLib,conf,telemetry,status,battery,alarms,frame,utils,customSensors,gpsStatuses,leftPanel,centerPanel,rightPanel)
  -- initialize maps
  init(utils,status.mapZoomLevel)
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
