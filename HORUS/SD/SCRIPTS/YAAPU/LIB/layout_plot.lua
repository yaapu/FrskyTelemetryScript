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

local layout = {}

local conf
local telemetry
local status
local utils
local libs

function layout.init(param_status, param_telemetry, param_conf, param_utils, param_libs)
  status = param_status
  telemetry = param_telemetry
  conf = param_conf
  utils = param_utils
  libs = param_libs
end

local val1Max = -math.huge
local val1Min = math.huge
local val2Max = -math.huge
local val2Min = math.huge
local initialized = false

local function drawMiniHud()
  libs.drawLib.drawArtificialHorizon(22, 22, 48, 36, nil, lcd.RGB(0x7B, 0x9D, 0xFF), lcd.RGB(0x63, 0x30, 0x00), 6, 6.5)
  lcd.drawBitmap(utils.getBitmap("hud_48x48a"), 22-1, 22-10)
end

local function setup(widget)
  if not initialized then
    val1Max = -math.huge
    val1Min = math.huge
    val2Max = -math.huge
    val2Min = math.huge
    libs.drawLib.resetGraph("plot1")
    libs.drawLib.resetGraph("plot2")
    initialized = true
  end
end

function layout.draw(widget, customSensors, leftPanel, centerPanel, rightPanel)
  setup(widget)

  libs.drawLib.drawLeftRightTelemetry(widget)
  -- plot area
  lcd.setColor(CUSTOM_COLOR, lcd.RGB(100,100,100))
  lcd.drawFilledRectangle(90,54,300,170,SOLID+CUSTOM_COLOR)
  local y1,y2,val1,val2
  -- val1
  if conf.plotSource1 > 1 then
    val1 = telemetry[status.plotSources[conf.plotSource1][2]] * status.plotSources[conf.plotSource1][4] * status.unitConversion[status.plotSources[conf.plotSource1][3]]
    val1Min = math.min(val1,val1Min)
    val1Max = math.max(val1,val1Max)
    lcd.setColor(CUSTOM_COLOR, WHITE)
    lcd.drawText(91,38,status.plotSources[conf.plotSource1][1],CUSTOM_COLOR+SMLSIZE)
    lcd.drawText(91,52,string.format("%d", val1Max),CUSTOM_COLOR+SMLSIZE)
    lcd.drawText(91,200,string.format("%d", val1Min),CUSTOM_COLOR+SMLSIZE)
    y1 = libs.drawLib.drawGraph("plot1", 90, 59, 300, 151, utils.colors.darkyellow, val1, false, false, nil, 50)
    if y1 ~= nil then
      lcd.setColor(CUSTOM_COLOR, WHITE)
      lcd.drawText(92,y1-7,string.format("%d", val1),CUSTOM_COLOR+SMLSIZE+INVERS)
    end
  end
  -- val2
  if conf.plotSource2 > 1 then
    val2 = telemetry[status.plotSources[conf.plotSource2][2]] * status.plotSources[conf.plotSource2][4] * status.unitConversion[status.plotSources[conf.plotSource2][3]]
    val2Min = math.min(val2,val2Min)
    val2Max = math.max(val2,val2Max)
    lcd.setColor(CUSTOM_COLOR, WHITE)
    lcd.drawText(389,38,status.plotSources[conf.plotSource2][1],CUSTOM_COLOR+SMLSIZE+RIGHT)
    lcd.drawText(389,52,string.format("%d", val2Max),CUSTOM_COLOR+SMLSIZE+RIGHT)
    lcd.drawText(389,200,string.format("%d", val2Min),CUSTOM_COLOR+SMLSIZE+RIGHT)
    y2 = libs.drawLib.drawGraph("plot2", 90, 59, 300, 151, utils.colors.white, val2, false, false, nil, 50)
    if y2 ~= nil then
      lcd.setColor(CUSTOM_COLOR, WHITE)
      lcd.drawText(388,y2-7,string.format("%d", val2),CUSTOM_COLOR+SMLSIZE+RIGHT+INVERS)
    end
  end

  drawMiniHud()

  utils.drawTopBar()
  libs.drawLib.drawStatusBar(2)
  libs.drawLib.drawArmStatus()
  libs.drawLib.drawFailsafe()
  local nextX = libs.drawLib.drawTerrainStatus(90,20)
  libs.drawLib.drawFenceStatus(nextX,20)
end

function layout.background(widget)
  if status.unitConversion ~= nil then
    if conf.plotSource1 > 1 then
      libs.drawLib.updateGraph("plot1", telemetry[status.plotSources[conf.plotSource1][2]] * status.plotSources[conf.plotSource1][4] * status.unitConversion[status.plotSources[conf.plotSource1][3]], 50)
    end
    if conf.plotSource2 > 1 then
      libs.drawLib.updateGraph("plot2", telemetry[status.plotSources[conf.plotSource2][2]] * status.plotSources[conf.plotSource2][4] * status.unitConversion[status.plotSources[conf.plotSource2][3]], 50)
    end
  end
end

return layout

