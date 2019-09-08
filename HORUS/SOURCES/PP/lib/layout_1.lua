#include "includes/yaapu_inc.lua"
#include "includes/layout_1_inc.lua"

#define SENSOR1_X 80
#define SENSOR1_Y 203
#define SENSOR1_XLABEL 80
#define SENSOR1_YLABEL 193

#define SENSOR2_X 160
#define SENSOR2_Y 203
#define SENSOR2_XLABEL 160
#define SENSOR2_YLABEL 193

#define SENSOR3_X 240
#define SENSOR3_Y 203
#define SENSOR3_XLABEL 240
#define SENSOR3_YLABEL 193

#define SENSOR4_X 320
#define SENSOR4_Y 203
#define SENSOR4_XLABEL 320
#define SENSOR4_YLABEL 193

#define SENSOR5_X 400
#define SENSOR5_Y 203
#define SENSOR5_XLABEL 400
#define SENSOR5_YLABEL 193

#define SENSOR6_X 480
#define SENSOR6_Y 203
#define SENSOR6_XLABEL 480
#define SENSOR6_YLABEL 193

--------------------------
-- CUSTOM SENSORS SUPPORT
--------------------------
#define SENSOR_LABEL 1
#define SENSOR_NAME 2
#define SENSOR_PREC 3
#define SENSOR_UNIT 4
#define SENSOR_MULT 5
#define SENSOR_MAX 6
#define SENSOR_FONT 7
#define SENSOR_WARN 8
#define SENSOR_CRIT 9

local customSensorXY = {
  { SENSOR1_XLABEL, SENSOR1_YLABEL, SENSOR1_X, SENSOR1_Y},
  { SENSOR2_XLABEL, SENSOR2_YLABEL, SENSOR2_X, SENSOR2_Y},
  { SENSOR3_XLABEL, SENSOR3_YLABEL, SENSOR3_X, SENSOR3_Y},
  { SENSOR4_XLABEL, SENSOR4_YLABEL, SENSOR4_X, SENSOR4_Y},
  { SENSOR5_XLABEL, SENSOR5_YLABEL, SENSOR5_X, SENSOR5_Y},
  { SENSOR6_XLABEL, SENSOR6_YLABEL, SENSOR6_X, SENSOR6_Y},
}

local function drawCustomSensors(x,customSensors,utils,status)
    lcd.setColor(CUSTOM_COLOR,COLOR_SENSORS)
    lcd.drawFilledRectangle(0,194,LCD_W,35,CUSTOM_COLOR)
    
    local label,data,prec,mult,flags,sensorConfig
    for i=1,6
    do
      if customSensors.sensors[i] ~= nil then 
        sensorConfig = customSensors.sensors[i]
        
        if sensorConfig[SENSOR_UNIT] == "" then
          label = string.format("%s",sensorConfig[SENSOR_LABEL])
        else
          label = string.format("%s(%s)",sensorConfig[SENSOR_LABEL],sensorConfig[SENSOR_UNIT])
        end
        -- draw sensor label
        lcd.setColor(CUSTOM_COLOR,COLOR_SENSORS_LABEL)
        lcd.drawText(x+customSensorXY[i][1], customSensorXY[i][2],label, SMLSIZE+RIGHT+CUSTOM_COLOR)
        
        mult =  sensorConfig[SENSOR_PREC] == 0 and 1 or ( sensorConfig[SENSOR_PREC] == 1 and 10 or 100 )
        prec =  mult == 1 and 0 or (mult == 10 and 32 or 48)
        
        local sensorName = sensorConfig[SENSOR_NAME]..(status.showMinMaxValues == true and sensorConfig[SENSOR_MAX] or "")
        local sensorValue = getValue(sensorName) 
        local value = (sensorValue+(mult == 100 and 0.005 or 0))*mult*sensorConfig[SENSOR_MULT]        
        
        -- default font size
        flags = sensorConfig[SENSOR_FONT] == 1 and 0 or MIDSIZE
        
        -- for sensor 3,4,5,6 reduce font if necessary
        if math.abs(value)*mult > 99999 then
          flags = 0
        end
        
        local color = COLOR_SENSORS_TEXT
        local sign = sensorConfig[SENSOR_MAX] == "+" and 1 or -1
        -- max tracking, high values are critical
        if math.abs(value) ~= 0 and status.showMinMaxValues == false then
          color = ( sensorValue*sign > sensorConfig[SENSOR_CRIT]*sign and lcd.RGB(255,70,0) or (sensorValue*sign > sensorConfig[SENSOR_WARN]*sign and COLOR_WARN or COLOR_SENSORS_TEXT))
        end
        
        lcd.setColor(CUSTOM_COLOR,color)
        
        local voffset = flags==0 and 6 or 0
        -- if a lookup table exists use it!
        if customSensors.lookups[i] ~= nil and customSensors.lookups[i][value] ~= nil then
          lcd.drawText(x+customSensorXY[i][3], customSensorXY[i][4]+voffset, customSensors.lookups[i][value] or value, flags+RIGHT+CUSTOM_COLOR)
        else
          lcd.drawNumber(x+customSensorXY[i][3], customSensorXY[i][4]+voffset, value, flags+RIGHT+prec+CUSTOM_COLOR)
        end
      end
    end
end

local function draw(myWidget,drawLib,conf,telemetry,status,battery,alarms,frame,utils,customSensors,gpsStatuses,leftPanel,centerPanel,rightPanel)
  lcd.setColor(CUSTOM_COLOR,COLOR_LINES)
  centerPanel.drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils)
  --lcd.setColor(CUSTOM_COLOR,COLOR_YELLOW)
  drawLib.drawRArrow(HOMEDIR_X,HOMEDIR_Y,HOMEDIR_R,math.floor(telemetry.homeAngle - telemetry.yaw),CUSTOM_COLOR)--HomeDirection(telemetry)
  -- with dual battery default is to show aggregate view
  if status.batt2sources.fc or status.batt2sources.vs then
    if status.showDualBattery == false then
      -- dual battery: aggregate view
      rightPanel.drawPane(380,drawLib,conf,telemetry,status,alarms,battery,BATT_IDALL,gpsStatuses,utils)
      -- left pane info
      leftPanel.drawPane(0,drawLib,conf,telemetry,status,alarms,battery,BATT_IDALL,gpsStatuses,utils)
    else
      -- dual battery:battery 1 right pane
      rightPanel.drawPane(380,drawLib,conf,telemetry,status,alarms,battery,BATT_ID1,gpsStatuses,utils)
      -- dual battery:battery 2 left pane
      rightPanel.drawPane(0,drawLib,conf,telemetry,status,alarms,battery,BATT_ID2,gpsStatuses,utils)
    end
  else
    -- battery 1 right pane in single battery mode
    rightPanel.drawPane(380,drawLib,conf,telemetry,status,alarms,battery,BATT_ID1,gpsStatuses,utils)
    -- left pane info  in single battery mode
    leftPanel.drawPane(0,drawLib,conf,telemetry,status,alarms,battery,BATT_IDALL,gpsStatuses,utils)
  end
  utils.drawTopBar()
  local msgRows = 4
  if customSensors ~= nil then
    --utils.drawBottomBar()
    msgRows = 1
    -- draw custom sensors
    drawCustomSensors(0,customSensors,utils,status)
  end
  drawLib.drawStatusBar(msgRows,conf,telemetry,status,battery,alarms,frame,utils,gpsStatuses)
  drawLib.drawFailsafe(telemetry,utils)
  drawLib.drawArmStatus(status,telemetry,utils)
end

return {draw=draw}
