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

-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()

local lastProcessCycle = getTime()
local processCycle = 0


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

local val1Max = -math.huge
local val1Min = math.huge
local val2Max = -math.huge
local val2Min = math.huge
local initialized = false

local function init(myWidget,drawLib,conf,telemetry,status,battery,alarms,frame,utils,customSensors,leftPanel,centerPanel,rightPanel)
  if not initialized then
    val1Max = -math.huge
    val1Min = math.huge
    val2Max = -math.huge
    val2Min = math.huge
    drawLib.resetGraph("plot1")
    drawLib.resetGraph("plot2")
    initialized = true
  end
end

local function draw(myWidget,drawLib,conf,telemetry,status,battery,alarms,frame,utils,customSensors,leftPanel,centerPanel,rightPanel)
  init(myWidget,drawLib,conf,telemetry,status,battery,alarms,frame,utils,customSensors,leftPanel,centerPanel,rightPanel)

  drawLib.drawLeftRightTelemetry(myWidget,conf,telemetry,status,battery,utils)
  -- plot area
  lcd.setColor(CUSTOM_COLOR, lcd.RGB(100,100,100))
  lcd.drawFilledRectangle(90,54,300,170,SOLID+CUSTOM_COLOR)
  local y1,y2,val1,val2
  -- val1
  if conf.plotSource1 > 1 then
    val1 = telemetry[status.plotSources[conf.plotSource1][2]] * status.plotSources[conf.plotSource1][4] * status.unitConversion[status.plotSources[conf.plotSource1][3]]
    val1Min = math.min(val1,val1Min)
    val1Max = math.max(val1,val1Max)
    lcd.setColor(CUSTOM_COLOR, 0xFE60)
    lcd.drawText(91,38,status.plotSources[conf.plotSource1][1],CUSTOM_COLOR+SMLSIZE)
    lcd.drawText(91,52,string.format("%d", val1Max),CUSTOM_COLOR+SMLSIZE)
    lcd.drawText(91,200,string.format("%d", val1Min),CUSTOM_COLOR+SMLSIZE)
    y1 = drawLib.drawGraph("plot1", 90, 59, 300, 151, 0xFE60, val1, false, false, nil, 50)
  end
  -- val2
  if conf.plotSource2 > 1 then
    val2 = telemetry[status.plotSources[conf.plotSource2][2]] * status.plotSources[conf.plotSource2][4] * status.unitConversion[status.plotSources[conf.plotSource2][3]]
    val2Min = math.min(val2,val2Min)
    val2Max = math.max(val2,val2Max)
    lcd.setColor(CUSTOM_COLOR, 0xFFFF)
    lcd.drawText(389,38,status.plotSources[conf.plotSource2][1],CUSTOM_COLOR+SMLSIZE+RIGHT)
    lcd.drawText(389,52,string.format("%d", val2Max),CUSTOM_COLOR+SMLSIZE+RIGHT)
    lcd.drawText(389,200,string.format("%d", val2Min),CUSTOM_COLOR+SMLSIZE+RIGHT)
    y2 = drawLib.drawGraph("plot2", 90, 59, 300, 151, 0xFFFF, val2, false, false, nil, 50)
  end
  -- draw floating values on top
  if conf.plotSource1 > 1 then
    if y1 ~= nil then
      lcd.drawText(92,y1-7,string.format("%d", val1),SMLSIZE+INVERS)
    end
  end
  if conf.plotSource2 > 1 then
    if y2 ~= nil then
      lcd.drawText(388,y2-7,string.format("%d", val2),SMLSIZE+RIGHT+INVERS)
    end
  end
  drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils)

  utils.drawTopBar()
  drawLib.drawStatusBar(2,conf,telemetry,status,battery,alarms,frame,utils)
  drawLib.drawArmStatus(status,telemetry,utils)
  drawLib.drawFailsafe(telemetry,utils)
  local nextX = drawLib.drawTerrainStatus(utils,status,telemetry,90,20)
  drawLib.drawFenceStatus(utils,status,telemetry,nextX,20)
end

local function background(myWidget,conf,telemetry,status,utils,drawLib)
  if status.unitConversion ~= nil then
    if conf.plotSource1 > 1 then
      drawLib.updateGraph("plot1", telemetry[status.plotSources[conf.plotSource1][2]] * status.plotSources[conf.plotSource1][4] * status.unitConversion[status.plotSources[conf.plotSource1][3]], 50)
    end
    if conf.plotSource2 > 1 then
      drawLib.updateGraph("plot2", telemetry[status.plotSources[conf.plotSource2][2]] * status.plotSources[conf.plotSource2][4] * status.unitConversion[status.plotSources[conf.plotSource2][3]], 50)
    end
  end
end

return {draw=draw, background=background}

