#include "includes/yaapu_inc.lua"
#include "includes/layout_1_inc.lua"

#define ALTASL_X 90
#define ALTASL_Y 37
#define ALTASL_XLABEL 90
#define ALTASL_YLABEL 25

#define HOMEDIST_X 90
#define HOMEDIST_Y 82
#define HOMEDIST_XLABEL 90
#define HOMEDIST_YLABEL 70
#define HOMEDIST_ARROW_WIDTH 8

#define TOTDIST_X 90
#define TOTDIST_Y 129
#define TOTDIST_XLABEL 90
#define TOTDIST_YLABEL 117

local function drawPane(x,drawLib,conf,telemetry,status,alarms,battery,battId,gpsStatuses,utils)
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)   
  if conf.rangeFinderMax > 0 then
    flags = 0
    local rng = telemetry.range
    rng = utils.getMaxValue(rng,MAX_RANGE)
    lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)   
    lcd.drawText(ALTASL_XLABEL, ALTASL_YLABEL, "Range("..UNIT_ALT_LABEL..")", SMLSIZE+CUSTOM_COLOR+RIGHT)
    lcd.setColor(CUSTOM_COLOR,COLOR_RED)       
    if rng > conf.rangeFinderMax and status.showMinMaxValues == false then
      lcd.drawFilledRectangle(ALTASL_X-65, ALTASL_Y+4,65,21,CUSTOM_COLOR)
    end
    lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)       
    lcd.drawText(ALTASL_X, ALTASL_Y, string.format("%.1f",rng*0.01*UNIT_ALT_SCALE), MIDSIZE+RIGHT+CUSTOM_COLOR)
  else
    flags = BLINK
    -- always display gps altitude even without 3d lock
    local alt = telemetry.gpsAlt/10
    if telemetry.gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = utils.getMaxValue(alt,MAX_GPSALT)
    end
    if status.showMinMaxValues == true then
      flags = 0
    end
    lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)       
    lcd.drawText(ALTASL_XLABEL, ALTASL_YLABEL, "AltAsl("..UNIT_ALT_LABEL..")", SMLSIZE+CUSTOM_COLOR+RIGHT)
    local stralt = string.format("%d",alt*UNIT_ALT_SCALE)
    lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)       
    lcd.drawText(ALTASL_X, ALTASL_Y, stralt, MIDSIZE+flags+RIGHT+CUSTOM_COLOR)
  end
  -- LABELS
  lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)       
  drawLib.drawHomeIcon(HOMEDIST_XLABEL - 70, HOMEDIST_YLABEL,utils)
  lcd.drawText(HOMEDIST_XLABEL, HOMEDIST_YLABEL, "Dist("..UNIT_DIST_LABEL..")", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(TOTDIST_XLABEL, TOTDIST_YLABEL, "Travel("..UNIT_DIST_LONG_LABEL..")", SMLSIZE+RIGHT+CUSTOM_COLOR)
  -- VALUES
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)       
  -- home distance
  flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = utils.getMaxValue(telemetry.homeDist,MAX_DIST)
  if status.showMinMaxValues == true then
    flags = 0
  end
  local strdist = string.format("%d",dist*UNIT_DIST_SCALE)
  --lcd.setColor(CUSTOM_COLOR,COLOR_YELLOW) --yellow  
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)  
  lcd.drawText(HOMEDIST_X, HOMEDIST_Y, strdist, MIDSIZE+flags+RIGHT+CUSTOM_COLOR)
  -- total distance
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)  
  lcd.drawNumber(TOTDIST_X, TOTDIST_Y, telemetry.totalDist*UNIT_DIST_LONG_SCALE*100, PREC2+MIDSIZE+RIGHT+CUSTOM_COLOR)
  
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(4, ALTASL_Y + 4,true,false,utils)
    drawLib.drawVArrow(4, HOMEDIST_Y + 4 ,true,false,utils)
  end
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawPane=drawPane,background=background}