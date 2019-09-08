#include "includes/yaapu_inc.lua"
#include "includes/layout_1_inc.lua"

#define LEFTWIDTH   38
#define RIGHTWIDTH  38

#define HUD_WIDTH 280
#define HUD_HEIGHT 134
#define HUD_X (LCD_W-HUD_WIDTH)/2
#define HUD_Y 18
#define HUD_Y_MID 85

#define VARIO_X 372
#define VARIO_Y HUD_Y + 18
#define VARIO_H HUD_HEIGHT/2
#define VARIO_W 8

-----------------------
-- COMPASS RIBBON
-----------------------
#define YAW_X (LCD_W-260)/2
#define YAW_Y 18
#define YAW_WIDTH 240

#define YAWICON_Y 40
#define YAWTEXT_Y 18
#define YAW_STEPWIDTH 25
#define YAW_SYMBOLS 16
#define YAW_X_MIN (LCD_W-YAW_WIDTH)/2
#define YAW_X_MAX (LCD_W+YAW_WIDTH)/2

#define PITCH_X 248
#define PITCH_Y 90

#define ROLL_X 214
#define ROLL_Y 76


#define R2 21

-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()
#ifdef HUDTIMER
local hudDrawTime = 0
local hudDrawCounter = 0
#endif

local function drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils)
#ifdef HUDTIMER
  local hudStart = getTime()
#endif

  local r = -telemetry.roll
  local cx,cy,dx,dy,ccx,ccy,cccx,cccy
  local yPos = TOPBAR_Y + TOPBAR_HEIGHT + 8
  -----------------------
  -- artificial horizon
  -----------------------
  -- no roll ==> segments are vertical, offsets are multiples of R2
  if ( telemetry.roll == 0 or math.abs(telemetry.roll) == 180) then
    dx=0
    dy=telemetry.pitch * 1.85
    cx=0
    cy=R2
    ccx=0
    ccy=2*R2
    cccx=0
    cccy=3*R2
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -telemetry.pitch
    dy = math.sin(math.rad(90 - r)) * telemetry.pitch * 1.85
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * R2
    cy = math.sin(math.rad(90 - r)) * R2
  end
  local rollX = math.floor(HUD_X + HUD_WIDTH/2)
  -----------------------
  -- dark color for "ground"
  -----------------------
  -- 140x90
  local minY = HUD_Y
  local maxY = HUD_Y + HUD_HEIGHT
  
  local minX = HUD_X 
  local maxX = HUD_X + HUD_WIDTH
  
  local ox = HUD_X + HUD_WIDTH/2 + dx
  local oy = HUD_Y_MID + dy
  local yy = 0
  
  -- HUD
  #include "includes/hud_algo_inc.lua"
  
  -- parallel lines above and below horizon
  local linesMaxY = maxY-2
  local linesMinY = minY+10
  lcd.setColor(CUSTOM_COLOR,COLOR_WHITE)
  -- +/- 90 deg
  for dist=1,8
  do
    drawLib.drawLineWithClipping(rollX + dx - dist*cx,dy + HUD_Y_MID + dist*cy,r,(dist%2==0 and 80 or 40),DOTTED,HUD_X+2,HUD_X+HUD_WIDTH-2,linesMinY,linesMaxY,CUSTOM_COLOR,radio,rev)
    drawLib.drawLineWithClipping(rollX + dx + dist*cx,dy + HUD_Y_MID - dist*cy,r,(dist%2==0 and 80 or 40),DOTTED,HUD_X+2,HUD_X+HUD_WIDTH-2,linesMinY,linesMaxY,CUSTOM_COLOR,radio,rev)
  end
  
  -- hashmarks
  local startY = minY + 1
  local endY = maxY - 10
  local step = 18
  -- hSpeed 
  local roundHSpeed = math.floor((telemetry.hSpeed*UNIT_HSPEED_SCALE*0.1/5)+0.5)*5;
  local offset = math.floor((telemetry.hSpeed*UNIT_HSPEED_SCALE*0.1-roundHSpeed)*0.2*step);
  local ii = 0;  
  local yy = 0  
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(120,120,120))
  for j=roundHSpeed+20,roundHSpeed-20,-5
  do
      yy = startY + (ii*step) + offset - 14
      if yy >= startY and yy < endY then
        lcd.drawLine(HUD_X, yy+9, HUD_X + 4, yy+9, SOLID, CUSTOM_COLOR)
        lcd.drawNumber(HUD_X + 7,  yy, j, SMLSIZE+CUSTOM_COLOR)
      end
      ii=ii+1;
  end
  -- altitude 
  local roundAlt = math.floor((telemetry.homeAlt*UNIT_ALT_SCALE/5)+0.5)*5;
  offset = math.floor((telemetry.homeAlt*UNIT_ALT_SCALE-roundAlt)*0.2*step);
  ii = 0;  
  yy = 0
  for j=roundAlt+20,roundAlt-20,-5
  do
      yy = startY + (ii*step) + offset - 14
      if yy >= startY and yy < endY then
        lcd.drawLine(HUD_X + HUD_WIDTH - 14, yy+8, HUD_X + HUD_WIDTH-10 , yy+8, SOLID, CUSTOM_COLOR)
        lcd.drawNumber(HUD_X + HUD_WIDTH - 16,  yy, j, SMLSIZE+RIGHT+CUSTOM_COLOR)
      end
      ii=ii+1;
  end
  lcd.setColor(CUSTOM_COLOR,COLOR_WHITE)
  
  -------------------------------------
  -- hud bitmap
  -------------------------------------
  lcd.drawBitmap(utils.getBitmap("hud_280x134"),(LCD_W-HUD_WIDTH)/2,HUD_Y) --160x90
  
  -------------------------------------
  -- vario
  -------------------------------------
  local varioMax = 5
  local varioSpeed = math.min(math.abs(0.1*telemetry.vSpeed),5)
  local varioH = varioSpeed/varioMax*52
  --varioH = varioH + (varioH > 0 and 1 or 0)
  if telemetry.vSpeed > 0 then
    varioY = 19 + (52 - varioH)
  else
    varioY = 85 + 15
  end
  --00ae10
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 0xce, 0)) --yellow
  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(00, 0xED, 0x32)) --green
  -- lcd.setColor(CUSTOM_COLOR,lcd.RGB(50, 50, 50)) --dark grey
  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 255, 255)) --white
  lcd.drawFilledRectangle(VARIO_X, varioY, VARIO_W, varioH, CUSTOM_COLOR, 0)  
  
  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- DATA
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(00, 0xED, 0x32)) --green
  -- altitude
  local alt = utils.getMaxValue(telemetry.homeAlt,MINMAX_ALT) * UNIT_ALT_SCALE
  if math.abs(alt) > 999 or alt < -99 then
    lcd.drawNumber(HUD_X+HUD_WIDTH+1,HUD_Y_MID-16,alt,MIDSIZE+CUSTOM_COLOR+RIGHT)
  elseif math.abs(alt) >= 10 then
    lcd.drawNumber(HUD_X+HUD_WIDTH+1,HUD_Y_MID-20,alt,DBLSIZE+CUSTOM_COLOR+RIGHT)
  else
    lcd.drawNumber(HUD_X+HUD_WIDTH+1,HUD_Y_MID-20,alt*10,DBLSIZE+PREC1+CUSTOM_COLOR+RIGHT)
  end
  -- telemetry.hSpeed is in dm/s
  local hSpeed = utils.getMaxValue(telemetry.hSpeed,MAX_HSPEED) * 0.1 * UNIT_HSPEED_SCALE
  if (math.abs(hSpeed) >= 10) then
    lcd.drawNumber(HUD_X+2,HUD_Y_MID-20,hSpeed,DBLSIZE+CUSTOM_COLOR)
  else
    lcd.drawNumber(HUD_X+2,HUD_Y_MID-20,hSpeed*10,DBLSIZE+CUSTOM_COLOR+PREC1)
  end
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)  
  -- min/max arrows
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(HUD_X+68, HUD_Y_MID-12,true,false,utils)
    drawLib.drawVArrow(HUD_X+HUD_WIDTH-79, HUD_Y_MID-12,true,false,utils)
  end
  
  -- vspeed box
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)  
  
  local vSpeed = utils.getMaxValue(telemetry.vSpeed,MAX_VSPEED) * 0.1 -- m/s
  
  local xx = math.abs(vSpeed*UNIT_VSPEED_SCALE) > 999 and 4 or 3
  xx = xx + (vSpeed*UNIT_VSPEED_SCALE < 0 and 1 or 0)
  
  if math.abs(vSpeed*UNIT_VSPEED_SCALE*10) > 99 then -- 
    lcd.drawNumber((LCD_W)/2 + (xx/2)*12, 127, vSpeed*UNIT_VSPEED_SCALE, MIDSIZE+CUSTOM_COLOR+RIGHT)
  else
    lcd.drawNumber((LCD_W)/2 + (xx/2)*12, 127, vSpeed*UNIT_VSPEED_SCALE*10, MIDSIZE+CUSTOM_COLOR+RIGHT+PREC1)
  end
  
  -- compass ribbon
  drawLib.drawCompassRibbon(YAW_Y,myWidget,conf,telemetry,status,battery,utils,YAW_WIDTH,YAW_X_MIN,YAW_X_MAX,YAW_STEPWIDTH,true)
  
  -- pitch and roll
  lcd.setColor(CUSTOM_COLOR,COLOR_YELLOW)  
  local xoffset =  math.abs(telemetry.pitch) > 99 and 6 or 0
  lcd.drawNumber(PITCH_X+xoffset,PITCH_Y,telemetry.pitch,CUSTOM_COLOR+SMLSIZE+RIGHT)
  lcd.drawNumber(ROLL_X,ROLL_Y,telemetry.roll,CUSTOM_COLOR+SMLSIZE+RIGHT)
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)  
#ifdef HUDTIMER
  hudDrawTime = hudDrawTime + (getTime() - hudStart)
  hudDrawCounter = hudDrawCounter + 1
#endif
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawHud=drawHud,background=background}