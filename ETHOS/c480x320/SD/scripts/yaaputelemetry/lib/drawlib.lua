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
local HUD_H = 150
local HUD_X = (480 - HUD_W)/2
local HUD_Y = 18

local function getTime()
  -- os.clock() resolution is 0.01 secs
  return os.clock()*100 -- 1/100th
end


local status = nil
local libs = nil

local drawLib = {}
local bitmaps = {}

local yawRibbonPoints = {"N",nil,"NE",nil,"E",nil,"SE",nil,"S",nil,"SW",nil,"W",nil,"NW",nil}


function drawLib.drawPanelSensor(x,y,value,prec,label,unit,font,lfont,ufont,color,lcolor,rightAlign,blink)
  local w,h
  lcd.font(font)
  if value == nil then
    value = 0
    w,h = lcd.getTextSize(value)
  else
    w,h = lcd.getTextSize(string.format("%."..prec.."f",value))
  end

  lcd.font(lfont)
  local lw,lh = lcd.getTextSize(label)
  lcd.font(ufont)
  local uw,uh = lcd.getTextSize(unit)

  if rightAlign == true then
    drawLib.drawText(x,y, label, lfont, lcolor, RIGHT)
    drawLib.drawText(x,y+0.7*lh+0.85*h-uh, unit, ufont, color, RIGHT)
    drawLib.drawNumber(x-uw,y+0.7*lh, value, prec, font, color, RIGHT, blink)
  else
    drawLib.drawText(x,y, label, lfont, lcolor, LEFT)
    drawLib.drawNumber(x,y+0.7*lh, value, prec, font, color, LEFT, blink)
    drawLib.drawText(x+w,y+0.7*lh+0.85*h-uh, unit, ufont, color, LEFT)
  end
end


function drawLib.drawTopBarSensor(widget,x,sensor,label)
  local offset = 0
  if sensor ~= nil then
    lcd.font(FONT_L)
    local w,h = lcd.getTextSize(sensor:stringValue())
    drawLib.drawText(x-w-2, 6, label == nil and sensor:name() or label, FONT_XS, status.colors.barText, RIGHT)
    drawLib.drawText(x-w, 0, sensor:stringValue(), FONT_L, status.colors.barText, LEFT)
    lcd.font(FONT_XS)
    local w2,h2 = lcd.getTextSize(sensor:name())
    return w + w2 + 4
  else
    drawLib.drawText(x, 0, "---", FONT_L, status.colors.barText, RIGHT)
    return 100
  end
end

function drawLib.drawTopBar(widget)
  lcd.color(status.colors.barBackground)
  lcd.pen(SOLID)
  lcd.drawFilledRectangle(0, 0, 480,18)
  drawLib.drawText(0, -2, status.modelString ~= nil and status.modelString or model.name(), FONT_L, status.colors.barText, LEFT)
  local offset = drawLib.drawTopBarSensor(widget, 480, system.getSource({category=CATEGORY_SYSTEM, member=MAIN_VOLTAGE,options=0}), "TX") + -50
  offset = offset + drawLib.drawTopBarSensor(widget, 480 - offset, status.conf.linkQualitySource) + 3
  if status.conf.linkStatusSource2 ~= nil and status.conf.linkStatusSource2:name()  ~= "---" then
    source = status.conf.linkStatusSource2
    offset = offset + drawLib.drawTopBarSensor(widget, 480-offset, status.conf.linkStatusSource2) + 3
  end
  if status.conf.linkStatusSource3 ~= nil  and status.conf.linkStatusSource3:name() ~= "---" then
    offset = offset + drawLib.drawTopBarSensor(widget, 480-offset, status.conf.linkStatusSource3) + 3
  end
  if status.conf.linkStatusSource4 ~= nil and status.conf.linkStatusSource4:name() ~= "---" then
    offset = offset + drawLib.drawTopBarSensor(widget, 480-offset, status.conf.linkStatusSource4) + 3
  end
end


function drawLib.drawStatusBar(widget, y, maxRows)
  if maxRows ~= nil then
    y = drawLib.drawMessagesBar(widget, maxRows) - 27
  end
  lcd.color(status.colors.barBackground)
  lcd.pen(SOLID)
  lcd.drawFilledRectangle(0,y,480,27)

  -- flight time
  local seconds = model.getTimer("Yaapu"):value()
  local ss = (seconds%3600)%60
  local mm = math.floor(seconds/60)
  drawLib.drawText(480, y-4, string.format("%02.0f:%02.0f",mm,ss), FONT_XXL, status.colors.barText, RIGHT)
  -- flight mode
  if status.strFlightMode ~= nil then
    drawLib.drawText(0, y-4, status.strFlightMode, FONT_XXL, status.colors.barText, LEFT)
  end

  -- gps status, draw coordinatyes if good at least once
  if status.telemetry.lon ~= nil and status.telemetry.lat ~= nil then
    drawLib.drawText(380, y, status.telemetry.strLat, FONT_STD, status.colors.barText, RIGHT)
    drawLib.drawText(380, y+12, status.telemetry.strLon, FONT_STD, status.colors.barText, RIGHT)
  end
  -- gps status
  local hdop = status.telemetry.gpsHdopC
  local strStatus1 = status.gpsStatuses[status.telemetry.gpsStatus][1]
  local strStatus2 = status.gpsStatuses[status.telemetry.gpsStatus][2]
  local prec = 0
  local blink = true
  local flags = BLINK
  local mult = 0.1

  if status.telemetry.gpsStatus  > 2 then
    blink = false
    if status.telemetry.homeAngle ~= -1 then
      prec = 1
    end
    if hdop > 999 then
      hdop = 999
    end
    drawLib.drawNumber(255,y-4, hdop*mult, prec, FONT_XXL, status.colors.barText, LEFT, blink)
    -- SATS
    drawLib.drawText(227,y-4+3, strStatus1, FONT_STD, status.colors.barText, LEFT)
    drawLib.drawText(227,y-4+16, strStatus2, FONT_STD, status.colors.barText, LEFT)

    if status.telemetry.numSats == 15 then
      drawLib.drawNumber(186,y-4, status.telemetry.numSats, 0, FONT_XXL, status.colors.barText)
      drawLib.drawText(226,y-4, "+", FONT_STD, status.colors.white, RIGHT)
    else
      drawLib.drawNumber(186,y-4, status.telemetry.numSats, 0, FONT_XXL, status.colors.barText)
    end
  elseif status.telemetry.gpsStatus == 0 then
    drawLib.drawBlinkBitmap(150,y-4+0, "nogpsicon")
  else
    drawLib.drawBlinkBitmap(150,y-4+0, "nolockicon")
  end
end


function drawLib.drawMessagesBar(widget,maxRows)
  local yDelta = 2 + maxRows*12
  lcd.color(status.colors.barBackground)
  lcd.pen(SOLID)
  lcd.drawFilledRectangle(0,320-yDelta,480, yDelta)
  -- messages
  lcd.font(FONT_STD)
  local offset = math.min(maxRows,#status.messages+1)
  for i=0,offset-1 do
    local msg = status.messages[(status.messageCount + i - offset) % (#status.messages+1)]
    lcd.color(status.mavSeverity[msg[2]][2])
    lcd.drawText(1,320 - yDelta + (12*i), msg[1])
  end
  return 320 - yDelta
end

function drawLib.drawFailsafe(widget)
  if status.telemetry.ekfFailsafe > 0 then
    drawLib.drawBlinkBitmap(244, 80, "ekffailsafe")
  elseif status.telemetry.battFailsafe > 0 then
    drawLib.drawBlinkBitmap(244, 80, "battfailsafe")
  elseif status.telemetry.failsafe > 0 then
    drawLib.drawBlinkBitmap(244, 80, "failsafe")
  end
end


function drawLib.drawNoTelemetryData(widget)
  if not libs.utils.telemetryEnabled() then
    lcd.color(RED)
    lcd.drawFilledRectangle(40,70, 400, 140)
    lcd.color(WHITE)
    lcd.drawRectangle(40,70, 400, 140,3)
    lcd.font(FONT_XXL)
    lcd.drawText(240, 87, "NO TELEMETRY", CENTERED)
    lcd.font(FONT_STD)
    lcd.drawText(240, 152, "Yaapu Telemetry Widget 1.3.0".."("..'fc8f523'..")", CENTERED)
  end
end

function drawLib.drawWidgetPaused(widget)
  lcd.color(status.colors.yellow)
  lcd.drawFilledRectangle(40,70, 400, 140)
  lcd.color(BLACK)
  lcd.drawRectangle(40,70, 400, 140,3)
  lcd.font(FONT_XXL)
  lcd.drawText(240, 87, "WIDGET PAUSED", CENTERED)
  lcd.font(FONT_STD)
  lcd.drawText(240, 152, "Yaapu Telemetry Widget 1.3.0".."("..'fc8f523'..")", CENTERED)
end

function drawLib.drawFenceStatus(x,y)
  if status.telemetry.fencePresent == 0 then
    return x
  end
  if status.telemetry.fenceBreached == 1 then
    drawLib.drawBlinkBitmap(x,y,"fence_breach")
    return x+20
  end
  drawLib.drawBitmap(x,y,"fence_ok")
  return x+20
end

function drawLib.drawTerrainStatus(x,y)
  if status.terrainEnabled == 0 then
    return x
  end
  if status.telemetry.terrainUnhealthy == 1 then
    drawLib.drawBlinkBitmap(x,y,"terrain_error")
    return x+20
  end
  drawLib.drawBitmap(x,y,"terrain_ok")
  return x+20
end

function drawLib.drawText(x, y, txt, font, color, flags, blink)
  lcd.font(font)
  lcd.color(color)
  if status.blinkon == true or blink == nil or blink == false then
    lcd.drawText(x, y, txt, flags)
  end
end

function drawLib.drawNumber(x, y, num, precision, font, color, flags, blink)
  lcd.font(font)
  lcd.color(color)
  if status.blinkon == true or blink == nil or blink == false then
    lcd.drawNumber(x, y, num, nil, precision, flags)
  end
end

--[[
  based on olliw's improved version over mine :-)
  https://github.com/olliw42/otxtelemetry
--]]
function drawLib.drawCompassRibbon(y,widget,width,xMin,xMax,font_1, font_2, boxWidth, boxHeight)
  local minY = y+1
  local heading = status.telemetry.yaw
  local minX = xMin
  local maxX = xMax
  local midX = (xMax + xMin)/2
  local tickNo = 4 --number of ticks on one side
  local stepCount = (maxX - minX -24)/(2*tickNo)
  local closestHeading = math.floor(heading/22.5) * 22.5
  local closestHeadingX = midX + (closestHeading - heading)/22.5 * stepCount
  local tickIdx = (closestHeading/22.5 - tickNo) % 16
  local tickX = closestHeadingX - tickNo*stepCount
  lcd.pen(SOLID)
  lcd.color(status.colors.white)
  lcd.font(font_1)
  for i = 1,10 do
      if tickX >= minX and tickX < maxX then
          if yawRibbonPoints[tickIdx+1] == nil then
              --lcd.drawLine(tickX, minY, tickX, y+10)
              lcd.drawFilledRectangle(tickX-1,minY, 2, 10)
          else
              lcd.drawText(tickX, minY-3, yawRibbonPoints[tickIdx+1], CENTERED)
          end
      end
      tickIdx = (tickIdx + 1) % 16
      tickX = tickX + stepCount
  end
  -- home icon
  local homeOffset = 0
  local angle = status.telemetry.homeAngle - status.telemetry.yaw
  if angle < 0 then angle = angle + 360 end
  if angle > 270 or angle < 90 then
    homeOffset = ((angle + 90) % 180)/180  * width * 0.9
  elseif angle >= 90 and angle < 180 then
    homeOffset = width * 0.9
  end
  -- text box
  lcd.color(status.colors.black)
  lcd.drawFilledRectangle(midX - boxWidth/2, minY-1, boxWidth, boxHeight)
  drawLib.drawNumber(midX,minY-2,heading,0,font_2,status.colors.white,CENTERED)

  drawLib.drawHomeIcon(xMin + homeOffset,minY + boxHeight)
end

function drawLib.drawRArrow(x,y,r,angle,color)
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
  lcd.pen(SOLID)
  lcd.color(color)
  lcd.drawLine(x1,y1,x2,y2)
  lcd.drawLine(x1,y1,x3,y3)
  lcd.drawLine(x2,y2,x4,y4)
  lcd.drawLine(x3,y3,x4,y4)
end

-- initialize up to 5 bars
local barMaxValues = {}
local barAvgValues = {}
local barSampleCounts = {}

local function initMap(map,name)
  if map[name] == nil then
    map[name] = 0
  end
end

function drawLib.updateBar(name, value)
  -- init
  initMap(barSampleCounts,name)
  initMap(barMaxValues,name)
  initMap(barAvgValues,name)

  -- update metadata
  barSampleCounts[name] = barSampleCounts[name]+1
  barMaxValues[name] = math.max(value,barMaxValues[name])
  -- weighted average on 10 samples
  barAvgValues[name] = barAvgValues[name]*0.9 + value*0.1
end

-- draw an horizontal dynamic bar with an average red pointer of the last 5 samples
function drawLib.drawBar(name, x, y, w, h, color, value, font)
  drawLib.updateBar(name, value)

  lcd.color(status.colors.white)
  lcd.pen(SOLID)
  lcd.drawFilledRectangle(x,y,w,h)

  -- normalize percentage relative to MAX
  local perc = 0
  local avgPerc = 0
  if barMaxValues[name] > 0 then
    perc = value/barMaxValues[name]
    avgPerc = barAvgValues[name]/barMaxValues[name]
  end
  lcd.color(color)
  lcd.drawFilledRectangle(math.max(x,x+w-perc*w),y+1,math.min(w,perc*w),h-2)
  lcd.color(status.colors.red)

  lcd.drawLine(x+w-avgPerc*(w-2),y+1,x+w-avgPerc*(w-2),y+h-2)
  lcd.drawLine(1+x+w-avgPerc*(w-2),y+1,1+x+w-avgPerc*(w-2),y+h-2)
  drawLib.drawNumber(x+w-2,y-2,value,0,font,status.colors.black,RIGHT)
  -- border
  lcd.drawRectangle(x,y,w,h)
end

function drawLib.drawMessages(widget, y, maxScreenMessages)
  -- each new message scrolls all messages to the end (offset is absolute)
  if status.messageAutoScroll == true then
    status.messageOffset = math.max(0, status.messageCount - maxScreenMessages)
  end
  local row = 0
  local offsetStart = status.messageOffset
  local offsetEnd = math.min(status.messageCount-1, status.messageOffset + maxScreenMessages - 1)
  --print("MSG",status.messageCount,offsetStart,offsetEnd,maxScreenMessages )
  lcd.font(FONT_STD)
  for i=offsetStart,offsetEnd  do
    lcd.color(status.mavSeverity[status.messages[i % 200][2]][2])
    lcd.drawText(0, y + 18*row, status.messages[i % 200][1])
    row = row + 1
  end
end

function drawLib.resetBacklightTimeout()
  system.resetBacklightTimeout()
end

function drawLib.getBitmap(name)
  if bitmaps[name] == nil then
    bitmaps[name] = lcd.loadBitmap("bitmaps/"..name..".png")
  end
  return bitmaps[name]
end

function drawLib.unloadBitmap(name)
  if bitmaps[name] ~= nil then
    bitmaps[name] = nil
    -- force call to luaDestroyBitmap()
    collectgarbage()
    collectgarbage()
  end
end

function drawLib.drawBlinkRectangle(x,y,w,h,t)
  if status.blinkon == true then
      lcd.drawRectangle(x,y,w,h,t)
  end
end

function drawLib.drawBitmap(x, y, bitmap, w, h)
  lcd.drawBitmap(x, y, drawLib.getBitmap(bitmap), w, h)
end

function drawLib.drawBlinkBitmap(x, y, bitmap, w, h)
  if status.blinkon == true then
      lcd.drawBitmap(x, y, drawLib.getBitmap(bitmap), w, h)
  end
end

function drawLib.drawMinMaxBar(x, y, w, h, color, val, min, max, showValue)
  local range = max - min
  local value = math.min(math.max(val,min),max) - min
  local perc = value/range
  lcd.color(status.colors.white)
  lcd.pen(SOLID)
  lcd.drawFilledRectangle(x,y,w,h)
  lcd.color(color)
  lcd.pen(SOLID)
  lcd.drawRectangle(x,y,w,h,2)
  lcd.drawFilledRectangle(x,y,w*perc,h)
  lcd.color(status.colors.black)
  lcd.font(XL)
  if showValue == true then
    local strperc = string.format("%02d%%",math.floor(val+0.5))
    lcd.drawText(x+w/2, y, strperc, CENTERED)
  end
end

local CS_INSIDE = 0
local CS_LEFT = 1
local CS_RIGHT = 2
local CS_BOTTOM = 4
local CS_TOP = 8

function drawLib.computeOutCode(x,y,xmin,ymin,xmax,ymax)
    local code = CS_INSIDE; --initialised as being inside of hud
    if x < xmin then --to the left of hud
        code = code | CS_LEFT
    elseif x > xmax then --to the right of hud
        code = code | CS_RIGHT
    end
    if y < ymin then --below the hud
        code = code | CS_TOP
    elseif y > ymax then --above the hud
        code = code | CS_BOTTOM
    end
    return code
end

function drawLib.isInside(x,y,xmin,ymin,xmax,ymax)
  --print("INSIDE",x,y,xmin,ymin,xmax,ymax)
  return drawLib.computeOutCode(x,y,xmin,ymin,xmax,ymax) == CS_INSIDE
end

function drawLib.drawLineWithClipping(x0, y0, x1, y1, xmin, ymin, xmax, ymax)
  lcd.setClipping(xmin, ymin, xmax-xmin, ymax-ymin)
  lcd.drawLine(x0,y0,x1,y1)
  local w,h = lcd.getWindowSize()
  lcd.setClipping(0,0,w,h)
end

-- draw a line centered on (ox,oy) with angle and len, clipped
function drawLib.drawLineByOriginAndAngle(ox, oy, angle, len, xmin, ymin, xmax, ymax, drawDiameter)
  local xx = math.cos(math.rad(angle)) * len * 0.5
  local yy = math.sin(math.rad(angle)) * len * 0.5

  local x0 = ox - xx
  local x1 = ox + xx
  local y0 = oy - yy
  local y1 = oy + yy

  if drawDiameter == nil then
    drawLib.drawLineWithClipping(x0,y0,x1,y1,xmin,ymin,xmax,ymax)
  else
    drawLib.drawLineWithClipping(ox,oy,x1,y1,xmin,ymin,xmax,ymax)
  end
end


function drawLib.drawArmingStatus(widget)
  -- armstatus
  if not libs.utils.failsafeActive(widget) and status.timerRunning == 0 then
    if status.telemetry.statusArmed == 1 then
      drawLib.drawBitmap( 150, 48, "armed")
    else
      drawLib.drawBlinkBitmap(150, 48, "disarmed")
    end
  end
end

function drawLib.drawHomeIcon(x,y)
  drawLib.drawBitmap(x,y,"minihomeorange")
end

function drawLib.drawWindArrow(x,y,r1,r2,arrow_angle, angle, skew, color)
  local a = math.rad(angle - 90)
  local ap = math.rad(angle + arrow_angle/2 - 90)
  local am = math.rad(angle - arrow_angle/2 - 90)

  local x1 = x + r1 * math.cos(a) * skew
  local y1 = y + r1 * math.sin(a)
  local x2 = x + r2 * math.cos(ap) * skew
  local y2 = y + r2 * math.sin(ap)
  local x3 = x + r2 * math.cos(am) * skew
  local y3 = y + r2 * math.sin(am)

  lcd.color(color)
  lcd.pen(SOLID)
  lcd.drawLine(x1,y1,x2,y2)
  lcd.drawLine(x1,y1,x3,y3)
end

local function drawFilledRectangle(x,y,w,h)
    if w > 0 and h > 0 then
      lcd.drawFilledRectangle(x,y,w,h)
    end
end

function drawLib.drawArtificialHorizon(x, y, w, h, colorSky, colorTerrain, lineCount, lineOffset)
  local r = -status.telemetry.roll
  local cx,cy,dx,dy
  local scale = 1.85 -- 1.85
  -----------------------
  -- artificial horizon
  -----------------------
  -- no roll ==> segments are vertical, offsets are multiples of R2
  if ( status.telemetry.roll == 0 or math.abs(status.telemetry.roll) == 180) then
    dx=0
    dy=status.telemetry.pitch * scale
    cx=0
    cy=lineOffset
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -status.telemetry.pitch
    dy = math.sin(math.rad(90 - r)) * status.telemetry.pitch * scale
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * lineOffset
    cy = math.sin(math.rad(90 - r)) * lineOffset
  end

  local rollX = math.floor(x+w/2) -- math.floor(HUD_X + HUD_WIDTH/2)
  -----------------------
  -- dark color for "ground"
  -----------------------
  local minX = x
  local minY = y

  local maxX = x + w
  local maxY = y + h


  local ox = x + w/2 + dx
  local oy = y + h/2 + dy

  -- background
  lcd.color(colorSky)
  lcd.pen(SOLID)
  lcd.drawFilledRectangle(x, y, w, h)

  -- HUD
  lcd.color(colorTerrain)
  lcd.pen(SOLID)

  -- angle of the line passing on point(ox,oy)
  local angle = math.tan(math.rad(-status.telemetry.roll))
  -- prevent divide by zero
  if status.telemetry.roll == 0 then
    drawFilledRectangle(minX,math.max(minY,dy+minY+(maxY-minY)/2),maxX-minX,math.min(maxY-minY,(maxY-minY)/2-dy+(math.abs(dy) > 0 and 1 or 0)))
  elseif math.abs(status.telemetry.roll) >= 180 then
    drawFilledRectangle(minX,minY,maxX-minX,math.min(maxY-minY,(maxY-minY)/2+dy))
  else
    -- HUD drawn using horizontal bars of height 2
    -- true if flying inverted
    local inverted = math.abs(status.telemetry.roll) > 90
    -- true if part of the hud can be filled in one pass with a rectangle
    local fillNeeded = false
    local yRect = inverted and 0 or 480

    local step = 2
    local steps = (maxY - minY)/step - 1
    local yy = 0

    if 0 < status.telemetry.roll and status.telemetry.roll < 180 then
      for s=0,steps
      do
        yy = minY + s*step
        xx = ox + (yy-oy)/angle
        if xx >= minX and xx <= maxX then
          lcd.drawFilledRectangle(xx, yy, maxX-xx+1, step)
        elseif xx < minX then
          yRect = inverted and math.max(yy,yRect)+step or math.min(yy,yRect)
          fillNeeded = true
        end
      end
    elseif -180 < status.telemetry.roll and status.telemetry.roll < 0 then
      for s=0,steps
      do
        yy = minY + s*step
        xx = ox + (yy-oy)/angle
        if xx >= minX and xx <= maxX then
          lcd.drawFilledRectangle(minX, yy, xx-minX, step)
        elseif xx > maxX then
          yRect = inverted and math.max(yy,yRect)+step or math.min(yy,yRect)
          fillNeeded = true
        end
      end
    end

    if fillNeeded then
      local yMin = inverted and minY or yRect
      local height = inverted and yRect - minY or maxY-yRect
      lcd.drawFilledRectangle(minX, yMin, maxX-minX, height)
    end
  end

  lcd.color(status.colors.hudLines)
  lcd.pen(SOLID)
  for dist=1,lineCount
  do
    libs.drawLib.drawLineByOriginAndAngle(rollX + dx - dist*cx, dy + y + h/2 + dist*cy, r, (dist%2==0 and 80 or 40), minX+2, minY+2, maxX-2, maxY-2)
    libs.drawLib.drawLineByOriginAndAngle(rollX + dx + dist*cx, dy + y + h/2 - dist*cy, r, (dist%2==0 and 80 or 40), minX+2, minY+2, maxX-2, maxY-2)
  end
  --[[
  -- horizon line
  lcd.color(160,160,160)
  lcd.pen(SOLID)
  libs.drawLib.drawLineByOriginAndAngle(rollX + dx,dy + HUD_MID_Y,r,200,HUD_MIN_X,linesMinY,HUD_MAX_X,linesMaxY)
  --]]
end


-- max is 20 samples every 1 sec
local graphSampleTime = {}
local graphMaxValues = {}
local graphMinValues = {}
local graphAvgValues = {}
local graphSampleCounts = {}
local graphSamples = {}

function drawLib.resetGraph(name)
  graphSampleTime[name] = 0
  graphMaxValues[name] = 0
  graphMinValues[name] = 0
  graphAvgValues[name] = 0
  graphSampleCounts[name] = 0
  graphSamples[name] = {}
end

function drawLib.updateGraph(name, value, maxSamples)
  if maxSamples == nil then
    maxSamples = 20
  end
  -- init
  initMap(graphSampleTime,name)
  initMap(graphMaxValues,name)
  initMap(graphMinValues,name)
  initMap(graphAvgValues,name)
  initMap(graphSampleCounts,name)

  if graphSamples[name] == nil then
    graphSamples[name] = {}
  end

  if getTime() - graphSampleTime[name] > 100 then
    graphAvgValues[name] = graphAvgValues[name]*0.9 + value*0.1
    graphSampleCounts[name] = graphSampleCounts[name]+1
    graphSamples[name][graphSampleCounts[name]%maxSamples] = value -- 0->49
    graphSampleTime[name] = getTime()
    graphMinValues[name] = math.min(value, graphMinValues[name])
    graphMaxValues[name] = math.max(value, graphMaxValues[name])
  end
  if graphSampleCounts[name] < 2 then
    return
  end
end

function drawLib.drawGraph(name, x ,y ,w , h, color, value, draw_bg, draw_value, unit, maxSamples)
  drawLib.updateGraph(name, value, maxSamples)

  if maxSamples == nil then
    maxSamples = 20
  end

  if draw_bg == true then
    lcd.color(COLOR_WHITE)
    lcd.drawFilledRectangle(x,y,w,h)
  end

  local height = h - 5 -- available height for the graph
  local step = (w-2)/(maxSamples-1)
  local maxY = y + h - 3

  local minMaxWindow = graphMaxValues[name] - graphMinValues[name] -- max difference between current window min/max

  -- scale factor based on current min/max difference
  local scale = height/minMaxWindow

  -- number of samples we can plot
  local sampleWindow = math.min(maxSamples-1,graphSampleCounts[name]-1)

   -- graph color
  lcd.color(color)
  lcd.pen(SOLID)

  local lastY = nil
  for i=1,sampleWindow
  do
    local prevSample = graphSamples[name][(i-1+graphSampleCounts[name]-sampleWindow)%maxSamples]
    local curSample =  graphSamples[name][(i+graphSampleCounts[name]-sampleWindow)%maxSamples]

    local x1 = x + (i-1)*step
    local x2 = x + i*step

    local y1 = maxY - (prevSample-graphMinValues[name])*scale
    local y2 = maxY - (curSample-graphMinValues[name])*scale
    lastY = y2
    lcd.drawLine(x1,y1,x2,y2)
  end

  if lastY ~= nil then
    lcd.pen(DOTTED)
    lcd.setColor(CUSTOM_COLOR, lcd.RGB(150,150,150))
    lcd.drawLine(x, lastY, x+w, lastY ,DOTTED, CUSTOM_COLOR)
  end

  if draw_bg == true then
    lcd.pen(SOLID)
    lcd.color(BLACK)
    lcd.drawRectangle(x,y,w,h)
  end

  if draw_value == true and lastY ~= nil then
    lcd.color(WHITE)
    lcd.font(FONT_L)
    lcd.drawText(x+2,lastY-6,string.format("%d%s",value,unit))
  end

  return lastY
end

function drawLib.init(param_status, param_libs)
  status = param_status
  libs = param_libs
  return drawLib
end

return drawLib
