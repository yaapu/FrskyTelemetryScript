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

local drawLib = {}

local status
local telemetry
local conf
local utils
local libs

-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()
local yawRibbonPoints = {"N",nil,"NE",nil,"E",nil,"SE",nil,"S",nil,"SW",nil,"W",nil,"NW",nil}

if string.find(radio, "x10") and tonumber(maj..minor..rev) < 222 then
  drawLib.drawLine = function(x1,y1,x2,y2,flags1,flags2) lcd.drawLine(LCD_W-x1,LCD_H-y1,LCD_W-x2,LCD_H-y2,flags1,flags2) end
else
  drawLib.drawLine = function(x1,y1,x2,y2,flags1,flags2) lcd.drawLine(x1,y1,x2,y2,flags1,flags2) end
end

function drawLib.init(param_status, param_telemetry, param_conf, param_utils, param_libs)
  status = param_status
  telemetry = param_telemetry
  conf = param_conf
  utils = param_utils
  libs = param_libs
end

function drawLib.drawHArrow(x,y,width,left,right,drawBlinkBitmap)
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
function drawLib.drawVArrow(x,y,top,bottom)
  if top == true then
    utils.drawBlinkBitmap("uparrow",x,y)
  else
    utils.drawBlinkBitmap("downarrow",x,y)
  end
end

function drawLib.drawHomeIcon(x,y)
  lcd.drawBitmap(utils.getBitmap("minihomeorange"),x,y)
end

function drawLib.computeOutCode(x,y,xmin,ymin,xmax,ymax)
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
    return code;
end

local function etxDrawLineWithClipping(x1,y1,x2,y2,style,xmin,xmax,ymin,ymax,color)
  lcd.drawLineWithClipping(x1,y1,x2,y2,xmin,xmax,ymin,ymax,style,color)
end

local function otxDrawLineWithClipping(x1,y1,x2,y2,style,xmin,xmax,ymin,ymax,color)
  local x= {}
  local y = {}
  if not(x1 < xmin and x2 < xmin) and not(x1 > xmax and x2 > xmax) then
    if not(y1 < ymin and y2 < ymin) and not(y1 > ymax and y2 > ymax) then
      x[1]=x1
      y[1]=y1
      x[2]=x2
      y[2]=y2
      for i=1,2
      do
        if x[i] < xmin then
          x[i] = xmin
          y[i] = ((y2-y1)/(x2-x1))*(xmin-x1)+y1
        elseif x[i] > xmax then
          x[i] = xmax
          y[i] = ((y2-y1)/(x2-x1))*(xmax-x1)+y1
        end

        if y[i] < ymin then
          y[i] = ymin
          x[i] = ((x2-x1)/(y2-y1))*(ymin-y1)+x1
        elseif y[i] > ymax then
          y[i] = ymax
          x[i] = ((x2-x1)/(y2-y1))*(ymax-y1)+x1
        end
      end
      if not(x[1] < xmin and x[2] < xmin) and not(x[1] > xmax and x[2] > xmax) then
        drawLib.drawLine(x[1],y[1],x[2],y[2], style, color)
      end
    end
  end
end

if lcd.drawLineWithClipping == nil then
  drawLib.drawLineWithClippingXY = otxDrawLineWithClipping
else
  drawLib.drawLineWithClippingXY = etxDrawLineWithClipping
end

function drawLib.drawLineByOriginAndAngle(ox,oy,angle,len,style,xmin,xmax,ymin,ymax,color,drawDiameter)
  local xx = math.cos(math.rad(angle)) * len * 0.5
  local yy = math.sin(math.rad(angle)) * len * 0.5

  local x0 = ox - xx
  local x1 = ox + xx
  local y0 = oy - yy
  local y1 = oy + yy

  if drawDiameter == false then
    drawLib.drawLineWithClippingXY(ox,oy,x1,y1,style,xmin,xmax,ymin,ymax,color)
  else
    drawLib.drawLineWithClippingXY(x0,y0,x1,y1,style,xmin,xmax,ymin,ymax,color)
  end
end

function drawLib.drawNumberWithDim(x,y,xDim,yDim,number,dim,flags,dimFlags)
  lcd.drawNumber(x, y, number,flags)
  lcd.drawText(xDim, yDim, dim, dimFlags)
end

function drawLib.drawRVehicle(x,y,r,angle,color,half)
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
  drawLib.drawLine(x1,y1,x2,y2,SOLID,color)
  drawLib.drawLine(x1,y1,x3,y3,SOLID,color)
  if half ~= true then
    drawLib.drawLine(x2,y2,x4,y4,SOLID,color)
    drawLib.drawLine(x3,y3,x4,y4,SOLID,color)
  end
end

function drawLib.drawRArrow(x,y,r1,r2,r3,angle,color)
  local ang = math.rad(angle - 90)
  local x0 = x - r1 * math.cos(ang)
  local y0 = y - r1 * math.sin(ang)
  local x1 = x + r1 * math.cos(ang)
  local y1 = y + r1 * math.sin(ang)

  ang = math.rad(angle - 90 + r3)
  local x2 = x + r2 * math.cos(ang)
  local y2 = y + r2 * math.sin(ang)

  ang = math.rad(angle - 90 - r3)
  local x3 = x + r2 * math.cos(ang)
  local y3 = y + r2 * math.sin(ang)

  drawLib.drawLine(x1,y1,x2,y2,SOLID,color)
  drawLib.drawLine(x1,y1,x3,y3,SOLID,color)
  drawLib.drawLine(x1,y1,x,y,SOLID,color)
  drawLib.drawLine(x,y,x0,y0,SOLID,color)
end

function drawLib.drawFenceStatus(x,y)
  if telemetry.fencePresent == 0 then
    return x
  end
  if telemetry.fenceBreached == 1 then
    utils.drawBlinkBitmap("fence_breach",x,y)
    return x+21
  end
  lcd.drawBitmap(utils.getBitmap("fence_ok"),x,y)
  return x+21
end

function drawLib.drawTerrainStatus(x,y)
  if status.terrainEnabled == 0 then
    return x
  end
  if telemetry.terrainUnhealthy == 1 then
    utils.drawBlinkBitmap("terrain_error",x,y)
    return x+21
  end
  lcd.drawBitmap(utils.getBitmap("terrain_ok"),x,y)
  return x+21
end


function drawLib.drawMinMaxBar(x, y, w, h, color, value, min, max, flags)
  local perc = math.min(math.max(value,min),max)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawFilledRectangle(x,y,w,h,CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,color)
  lcd.drawGauge(x, y,w,h,perc-min,max-min,CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, BLACK)
  local strperc = string.format("%02d%%",value)
  local xOffset = flags==0 and 10 or 17
  local yOffset = flags==0 and 1 or 4
  lcd.drawText(x+w/2-xOffset, y-yOffset, strperc, flags+CUSTOM_COLOR)
end

-- initialize up to 5 bars
local barMaxValues = {}
local barAvgValues = {}
local barSampleCounts = {}

function drawLib.initMapTable(mapTable,name)
  if mapTable[name] == nil then
    mapTable[name] = 0
  end
end

function drawLib.updateBar(name, value)
  -- init
  drawLib.initMapTable(barSampleCounts,name)
  drawLib.initMapTable(barMaxValues,name)
  drawLib.initMapTable(barAvgValues,name)

  -- update metadata
  barSampleCounts[name] = barSampleCounts[name]+1
  barMaxValues[name] = math.max(value,barMaxValues[name])
  -- weighted average on 5 samples
  barAvgValues[name] = barAvgValues[name]*0.9 + value*0.1
end

-- draw an horizontal dynamic bar with an average red pointer of the last 5 samples
function drawLib.drawBar(name, x, y, w, h, color, value, flags)
  drawLib.updateBar(name, value)

  lcd.setColor(CUSTOM_COLOR, WHITE)
  lcd.drawFilledRectangle(x,y,w,h,CUSTOM_COLOR)

  -- normalize percentage relative to MAX
  local perc = 0
  local avgPerc = 0
  if barMaxValues[name] > 0 then
    perc = value/barMaxValues[name]
    avgPerc = barAvgValues[name]/barMaxValues[name]
  end
  lcd.setColor(CUSTOM_COLOR, color)
  lcd.drawFilledRectangle(math.max(x,x+w-perc*w),y+1,math.min(w,perc*w),h-2,CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, RED)

  lcd.drawLine(x+w-avgPerc*(w-2),y+1,x+w-avgPerc*(w-2),y+h-2,SOLID,CUSTOM_COLOR)
  lcd.drawLine(1+x+w-avgPerc*(w-2),y+1,1+x+w-avgPerc*(w-2),y+h-2,SOLID,CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, BLACK)
  lcd.drawNumber(x+w-1,y-3,value,CUSTOM_COLOR+flags+RIGHT)
  -- border
  lcd.setColor(CUSTOM_COLOR, BLACK)
  lcd.drawRectangle(x,y,w,h,CUSTOM_COLOR)
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
  local updated = false
  if maxSamples == nil then
    maxSamples = 20
  end
  -- init
  drawLib.initMapTable(graphSampleTime,name)
  drawLib.initMapTable(graphMaxValues,name)
  drawLib.initMapTable(graphMinValues,name)
  drawLib.initMapTable(graphAvgValues,name)
  drawLib.initMapTable(graphSampleCounts,name)

  if graphSamples[name] == nil then
    graphSamples[name] = {}
  end

  if getTime() - graphSampleTime[name] > 100 then
    graphSampleCounts[name] = graphSampleCounts[name]+1
    graphAvgValues[name] = graphAvgValues[name]*0.9 + value*0.1
    graphSamples[name][graphSampleCounts[name]%maxSamples] = value -- 0->49
    graphSampleTime[name] = getTime()
    updated = true
  end

  if graphSampleCounts[name] < 2 then
    return updated
  end
  return updated
end

function drawLib.getGraphMin(name)
  return graphMinValues[name] == math.huge and 0 or graphMinValues[name]
end

function drawLib.getGraphMax(name)
  return graphMaxValues[name] == -math.huge and 0 or graphMaxValues[name]
end

function drawLib.getGraphAvg(name)
  return graphAvgValues[name]
end

function drawLib.drawGraph(name, x ,y ,w , h, color, value, draw_bg, draw_value, unit, maxSamples)
  local updateRequired = drawLib.updateGraph(name, value, maxSamples)

  if maxSamples == nil then
    maxSamples = 20
  end

  if draw_bg == true then
    lcd.setColor(CUSTOM_COLOR, WHITE)
    lcd.drawFilledRectangle(x,y,w,h,CUSTOM_COLOR)
  end

  lcd.setColor(CUSTOM_COLOR, color) -- graph color

  local height = h - 2 -- available height for the graph
  local step = (w-2)/(maxSamples-1)
  local maxY = y + height

  -- scale factor based on current min/max difference
  local minMaxWindow = graphMaxValues[name]-graphMinValues[name]-- max difference between current window min/max
  local scale = minMaxWindow == 0 and 1 or height/minMaxWindow

  -- number of samples we can plot
  local tempMin = math.huge
  local tempMax = -math.huge
  local sampleWindow = math.min(maxSamples-1,graphSampleCounts[name]-1)
  local lastY = nil
  if sampleWindow >= 2 then
    for i=2,sampleWindow
    do
      -- copy samples to sorting array
      local prevSample = graphSamples[name][(i-1+graphSampleCounts[name]-sampleWindow)%maxSamples]
      local curSample =  graphSamples[name][(i+graphSampleCounts[name]-sampleWindow)%maxSamples]

      local x1 = x + (i-1)*step
      local x2 = x + i*step

      local y1 = math.min(maxY,math.max(y,maxY - (prevSample-graphMinValues[name]) * scale))
      local y2 = math.min(math.max(y,maxY - (curSample-graphMinValues[name]) * scale))

      lastY = y2
      lcd.drawLine(x1,y1,x2,y2,SOLID,CUSTOM_COLOR)

      tempMin = math.min(tempMin, curSample)
      tempMax = math.max(tempMax, curSample)
    end
    graphMinValues[name] = tempMin
    graphMaxValues[name] = tempMax
  end

  if lastY ~= lastY then --nan
    lastY = nil
  end

  if lastY ~= nil then
    lcd.setColor(CUSTOM_COLOR, lcd.RGB(180,180,180))
    lcd.drawLine(x+2, lastY, x+w-2, lastY ,DOTTED, CUSTOM_COLOR)
  end

  if draw_bg == true then
    lcd.setColor(CUSTOM_COLOR, BLACK)
    lcd.drawRectangle(x,y,w,h,CUSTOM_COLOR)
  end

  if draw_value == true and lastY ~= nil then
    lcd.setColor(CUSTOM_COLOR, WHITE)
    lcd.drawText(x+2,lastY-6,string.format("%d%s",value,unit),CUSTOM_COLOR+SMLSIZE+INVERS)
  end

  return lastY
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
function drawLib.drawGauge(x, y, image, gx, gy, r1, r2, perc, max, color)
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

  drawLib.drawLine(x1,y1,x2,y2,SOLID,color)
  drawLib.drawLine(x1,y1,x3,y3,SOLID,color)
  drawLib.drawLine(x2,y2,x3,y3,SOLID,color)
end

function drawLib.drawFailsafe(x,y) --150, 45
  if telemetry.ekfFailsafe > 0 then
    utils.drawBlinkBitmap("ekffailsafe", x, y)
  elseif telemetry.battFailsafe > 0 then
    utils.drawBlinkBitmap("battfailsafe", x, y)
  elseif telemetry.failsafe > 0 then
    utils.drawBlinkBitmap("failsafe", x, y)
  end
end

function drawLib.drawArmStatus(x,y)
  -- armstatus
  if not utils.failsafeActive(telemetry) and status.timerRunning == 0 then
    if telemetry.statusArmed == 1 then
      lcd.drawBitmap(utils.getBitmap("armed"), x, y)
    else
      utils.drawBlinkBitmap("disarmed", x, y)
    end
  end
end

function drawLib.drawFilledRectangle(x,y,w,h,flags)
    if w > 0 and h > 0 then
      lcd.drawFilledRectangle(x,y,w,h,flags)
    end
end

local function fillTriangle(ox, oy, x1, x2, roll, angle,color)
  local step = 2
  --
  local y1 = (oy - ox*angle) + x1*angle
  local y2 = (oy - ox*angle) + x2*angle
  --
  local steps = math.abs(y2-y1) / step
  if (0 < roll and roll <= 90) then
    for s=0,steps
    do
      yy = y1 + s*step
      xx = (yy - (oy - ox*angle))/angle
      lcd.drawRectangle(x1,yy,xx - x1,step,color)
    end
  elseif (90 < roll and roll <= 180) then
    for s=0,steps
    do
      yy = y2 + s*step
      xx = (yy - (oy - ox*angle))/angle
      lcd.drawRectangle(x1,yy,xx - x1,step,color)
    end
  elseif (-90 < roll and roll < 0) then
    for s=0,steps
    do
      yy = y2 + s*step
      xx = (yy - (oy - ox*angle))/angle
      lcd.drawRectangle(xx,yy,x2-xx+1,step,color)
    end
  elseif (-180 < roll and roll <= -90) then
    for s=0,steps
    do
      yy = y1 + s*step
      xx = (yy - (oy - ox*angle))/angle
      lcd.drawRectangle(xx,yy,x2-xx+1,step,color)
    end
  end
end

--[[
  based on olliw's improved version over mine :-)
  https://github.com/olliw42/otxtelemetry
--]]
function drawLib.drawCompassRibbon(y,myWidget,width,xMin,xMax,stepWidth,bigFont,ribbonFont,ribbonColor)
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
              lcd.setColor(CUSTOM_COLOR, WHITE)
              lcd.drawLine(tickX, minY, tickX, y+5, SOLID, CUSTOM_COLOR)
          else
              lcd.setColor(CUSTOM_COLOR, ribbonColor)
              lcd.drawText(tickX, minY-3, yawRibbonPoints[tickIdx+1], CUSTOM_COLOR+CENTER+ribbonFont)
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
    homeOffset = (((angle + 90) % 180)/180  * width) - 3
  elseif angle >= 90 and angle < 180 then
    homeOffset = width - 13
  end
  drawLib.drawHomeIcon(xMin + homeOffset ,minY + (bigFont and 28 or 20),utils)

  -- text box
  local w = 60 -- 3 digits width
  if heading < 0 then heading = heading + 360 end
  if heading < 10 then
      w = 20
  elseif heading < 100 then
      w = 40
  end
  local scale = bigFont and 1 or 0.7
  lcd.setColor(CUSTOM_COLOR, BLACK)
  lcd.drawFilledRectangle(midX - (w/2)*scale, minY-1, w*scale, 28*scale, CUSTOM_COLOR+SOLID)
  lcd.setColor(CUSTOM_COLOR, WHITE)
  lcd.drawNumber(midX, bigFont and minY-6 or minY-2, heading, CUSTOM_COLOR+(bigFont and DBLSIZE or 0)+CENTER)
end


--------------------------
-- CUSTOM SENSORS SUPPORT
--------------------------

function drawLib.drawCustomSensors(customSensors, customSensorXY, colorLabel)
  if #customSensorXY == 0 then
    return
  end
  if customSensorXY.boxY ~= nil then
    lcd.setColor(CUSTOM_COLOR,utils.colors.black)
    lcd.drawFilledRectangle(0,customSensorXY.boxY,LCD_W,35,CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.grey)
    lcd.drawLine(1,customSensorXY.boxY+35,LCD_W-2,customSensorXY.boxY+35,SOLID,CUSTOM_COLOR)
  end

  local label,data,prec,mult,flags,sensorConfig
  for i=1,#customSensorXY
  do
    if customSensors.sensors[i] ~= nil then
      sensorConfig = customSensors.sensors[i]

      if sensorConfig[4] == "" then
        label = string.format("%s",sensorConfig[1])
      else
        label = string.format("%s(%s)",sensorConfig[1],sensorConfig[4])
      end
      -- draw sensor label
      lcd.setColor(CUSTOM_COLOR,customSensorXY[i][5] == nil and colorLabel or customSensorXY[i][5])
      lcd.drawText(customSensorXY[i][1], customSensorXY[i][2],label, SMLSIZE+RIGHT+CUSTOM_COLOR)

      mult =  sensorConfig[3] == 0 and 1 or ( sensorConfig[3] == 1 and 10 or 100 )
      prec =  mult == 1 and 0 or (mult == 10 and 32 or 48)

      local sensorName = sensorConfig[2]..(status.showMinMaxValues == true and sensorConfig[6] or "")
      local sensorValue = getValue(sensorName)
      local value = (sensorValue+(mult == 100 and 0.005 or 0))*mult*sensorConfig[5]

      local sign = sensorConfig[6] == "+" and 1 or -1
      flags = sensorConfig[7] == 1 and 0 or MIDSIZE

      if sensorConfig[10] == true then
      -- RED lcd.RGB(255,0, 0)
      -- GREEN lcd.RGB(0, 255, 0)
      -- YELLOW lcd.RGB(255, 204, 0)
        local color = lcd.RGB(255,0, 0)
        -- min/max tracking
        if math.abs(value) ~= 0 then
          color = ( sensorValue*sign > sensorConfig[9]*sign and lcd.RGB(255, 0, 0) or (sensorValue*sign > sensorConfig[8]*sign and lcd.RGB(255, 204, 0) or lcd.RGB(0, 255, 0)))
        end
        drawLib.drawMinMaxBar(customSensorXY[i][3]-sensorConfig[11],customSensorXY[i][4]+5,sensorConfig[11],sensorConfig[12],color,value,sensorConfig[13],sensorConfig[14],flags)
      else
        -- default font size
        local color = utils.colors.white
        -- min/max tracking
        if math.abs(value) ~= 0 and status.showMinMaxValues == false then
          color = ( sensorValue*sign > sensorConfig[9]*sign and lcd.RGB(255,70,0) or (sensorValue*sign > sensorConfig[8]*sign and utils.colors.yellow or utils.colors.white))
        end
        lcd.setColor(CUSTOM_COLOR,color)
        local voffset = flags==0 and 6 or 0
        -- if a lookup table exists use it!
        if customSensors.lookups[i] ~= nil and customSensors.lookups[i][value] ~= nil then
          lcd.drawText(customSensorXY[i][3], customSensorXY[i][4]+voffset, customSensors.lookups[i][value] or value, flags+RIGHT+CUSTOM_COLOR)
        else
          lcd.drawNumber(customSensorXY[i][3], customSensorXY[i][4]+voffset, value, flags+RIGHT+prec+CUSTOM_COLOR)
        end
      end
    end
  end
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

  lcd.drawLine(x1,y1,x2,y2,SOLID,color)
  lcd.drawLine(x1,y1,x3,y3,SOLID,color)
end

local function otxDrawHudRectangle(pitch, roll, minX, maxX, minY, maxY, color, ox, oy, dx, dy, scale)
  local r = -roll
  -- angle of the line passing on point(ox,oy)
  local angle = math.tan(math.rad(-roll))
  -- prevent divide by zero
  if roll == 0 then
    libs.drawLib.drawFilledRectangle(minX,math.max(minY,dy+minY+(maxY-minY)/2),maxX-minX,math.max(0,math.min(maxY-minY,(maxY-minY)/2-dy+(math.abs(dy) > 0 and 1 or 0))),CUSTOM_COLOR)
  elseif math.abs(roll) >= 180 then
    libs.drawLib.drawFilledRectangle(minX,minY,maxX-minX,math.min(maxY-minY,(maxY-minY)/2+dy),CUSTOM_COLOR)
  else  -- true if flying inverted
    local inverted = math.abs(roll) > 90
    -- true if part of the hud can be filled in one pass with a rectangle
    local fillNeeded = false
    local yRect = inverted and 0 or LCD_H

    local step = 2
    local steps = (maxY - minY)/step - 1
    local yy = 0

    if 0 < roll and roll < 180 then
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
    elseif -180 < roll and roll < 0 then
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
      lcd.drawFilledRectangle(minX, yMin, maxX-minX, height ,CUSTOM_COLOR)
    end
  end
end

local function etxDrawHudRectangle(pitch, roll, minX, maxX, minY, maxY, color, ox, oy, dx, dy, scale)
  lcd.drawHudRectangle(pitch, roll+0.001, minX, maxX, minY, maxY, color)
end

local drawHudRectangle = etxDrawHudRectangle
if lcd.drawHudRectangle == nil then
  drawHudRectangle = otxDrawHudRectangle
end

function drawLib.drawArtificialHorizon(x, y, w, h, bgBitmapName, colorSky, colorTerrain, lineCount, lineOffset, scale)
  local r = -telemetry.roll
  local cx,cy,dx,dy
  --local scale = 1.85 -- 1.85
  -- no roll ==> segments are vertical, offsets are multiples of R2
  if telemetry.roll == 0 or math.abs(telemetry.roll) == 180 then
    dx=0
    dy=telemetry.pitch * scale
    cx=0
    cy=lineOffset
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -telemetry.pitch
    dy = math.sin(math.rad(90 - r)) * telemetry.pitch * scale
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * lineOffset
    cy = math.sin(math.rad(90 - r)) * lineOffset
  end

  local rollX = math.floor(x+w/2) -- math.floor(HUD_X + HUD_WIDTH/2)

  local minY = y
  local maxY = y + h

  local minX = x
  local maxX = x + w

  local ox = x + w/2 + dx
  local oy = y + h/2 + dy
  local yy = 0

  if bgBitmapName == nil then
    lcd.setColor(CUSTOM_COLOR,colorSky)
    lcd.drawFilledRectangle(x,y,w,h,CUSTOM_COLOR)
  else
    lcd.drawBitmap(utils.getBitmap(bgBitmapName),x, y)
  end

  -- HUD drawn using horizontal bars of height 2
  lcd.setColor(CUSTOM_COLOR,colorTerrain)
  drawHudRectangle(telemetry.pitch, telemetry.roll, minX, maxX, minY, maxY, CUSTOM_COLOR, ox, oy, dx, dy, scale)
  -- parallel lines above and below horizon
  lcd.setColor(CUSTOM_COLOR, WHITE)
  -- +/- 90 deg
  for dist=1,lineCount
  do
    libs.drawLib.drawLineByOriginAndAngle(rollX + dx - dist*cx, oy + dist*cy, r, (dist%2==0 and 80 or 40), DOTTED, minX+2, maxX-2, minY+2, maxY-2, CUSTOM_COLOR)
    libs.drawLib.drawLineByOriginAndAngle(rollX + dx + dist*cx, oy - dist*cy, r, (dist%2==0 and 80 or 40), DOTTED, minX+2, maxX-2, minY+2, maxY-2, CUSTOM_COLOR)
  end

  --[[
  -- horizon line
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(160,160,160))
  libs.drawLib.drawLineByOriginAndAngle(rollX + dx, oy, r, 200, SOLID, minX+2, maxX-2, minY+2, maxY-2, CUSTOM_COLOR)
  --]]
end

return drawLib
