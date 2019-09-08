#include "includes/yaapu_inc.lua"
#include "includes/layout_2_inc.lua"

local function drawExtendedStatusBar(drawLib,conf,telemetry,status,battery,alarms,frame,utils,gpsStatuses)
  -- LEFT label
  lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)  
  lcd.drawText(ALT_XLABEL,ALT_YLABEL,"Alt("..UNIT_ALT_LABEL..")",SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.drawText(VSPEED_XLABEL,VSPEED_YLABEL,"VSI("..UNIT_VSPEED_LABEL..")",SMLSIZE+CUSTOM_COLOR+RIGHT)
  
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)  
  -- altitude
  local alt = utils.getMaxValue(telemetry.homeAlt,MINMAX_ALT) * UNIT_ALT_SCALE
  if math.abs(alt) > 999 then
    lcd.drawNumber(ALT_X,ALT_Y,alt,ALT_FLAGS+CUSTOM_COLOR)
  elseif math.abs(alt) >= 10 then
    lcd.drawNumber(ALT_X,ALT_Y,alt,ALT_FLAGS+CUSTOM_COLOR)
  else
    lcd.drawNumber(ALT_X,ALT_Y,alt*10,ALT_FLAGS+PREC1+CUSTOM_COLOR)
  end
  -- vertical speed
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)  
  local vSpeed = utils.getMaxValue(telemetry.vSpeed,MAX_VSPEED) * 0.1 * UNIT_VSPEED_SCALE
  if (math.abs(telemetry.vSpeed) >= 10) then
    lcd.drawNumber(VSPEED_X,VSPEED_Y, vSpeed ,VSPEED_FLAGS+CUSTOM_COLOR)
  else
    lcd.drawNumber(VSPEED_X,VSPEED_Y,vSpeed*10,VSPEED_FLAGS+PREC1+CUSTOM_COLOR)
  end
  -- min/max arrows
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(3, ALT_Y + 3,true,false,utils)
    drawLib.drawVArrow(VSPEED_X-70, VSPEED_Y + 3,true,false,utils)
  end
  
end

local function draw(myWidget,drawLib,conf,telemetry,status,battery,alarms,frame,utils,customSensors,gpsStatuses,leftPanel,centerPanel,rightPanel)
  if leftPanel ~= nil and centerPanel ~= nil and rightPanel ~= nil then
    lcd.setColor(CUSTOM_COLOR,COLOR_LINES)
    drawLib.drawRArrow(HOMEDIR_X,HOMEDIR_Y,HOMEDIR_R,math.floor(telemetry.homeAngle - telemetry.yaw),CUSTOM_COLOR)--HomeDirection(telemetry)
    centerPanel.drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils,customSensors)
    -- with dual battery default is to show aggregate view
    if status.batt2sources.fc or status.batt2sources.vs then
      if status.showDualBattery == false then
        -- dual battery: aggregate view
        rightPanel.drawPane(285,drawLib,conf,telemetry,status,alarms,battery,BATT_IDALL,gpsStatuses,utils,customSensors)
        -- left panel
        leftPanel.drawPane(0,drawLib,conf,telemetry,status,alarms,battery,BATT_IDALL,gpsStatuses,utils,customSensors)
      else
        -- dual battery:battery 1 right pane
        rightPanel.drawPane(285,drawLib,conf,telemetry,status,alarms,battery,BATT_ID1,gpsStatuses,utils,customSensors)
        -- dual battery:battery 2 left pane
        rightPanel.drawPane(-37,drawLib,conf,telemetry,status,alarms,battery,BATT_ID2,gpsStatuses,utils,customSensors)
      end
    else
      -- battery 1 right pane in single battery mode
      rightPanel.drawPane(285,drawLib,conf,telemetry,status,alarms,battery,BATT_ID1,gpsStatuses,utils,customSensors)
        -- left panel
      leftPanel.drawPane(0,drawLib,conf,telemetry,status,alarms,battery,BATT_IDALL,gpsStatuses,utils,customSensors)
    end
  end
  drawLib.drawStatusBar(3,conf,telemetry,status,battery,alarms,frame,utils,gpsStatuses)
  drawExtendedStatusBar(drawLib,conf,telemetry,status,battery,alarms,frame,utils,gpsStatuses)
  utils.drawTopBar()
  drawLib.drawFailsafe(telemetry,utils)
  drawLib.drawArmStatus(status,telemetry,utils)
end

return {draw=draw}
