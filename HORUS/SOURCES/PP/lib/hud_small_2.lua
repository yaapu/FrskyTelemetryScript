#include "includes/yaapu_inc.lua"
#include "includes/layout_2_inc.lua"

#define VARIO_X 275
#define VARIO_Y 20

#define LEFTWIDTH   38
#define RIGHTWIDTH  38

#define HUD_Y 30
#define HUD_HEIGHT 70
#define HUD_WIDTH 92
#define HUD_X (LCD_W-HUD_WIDTH)/2
#define HUD_Y_MID HUD_Y+HUD_HEIGHT/2

-----------------------
-- COMPASS RIBBON
-----------------------
#define YAW_X (LCD_W-140)/2
#define YAW_Y 115
#define YAW_WIDTH 140

#define YAWICON_Y 3
#define YAWTEXT_Y 16
#define YAW_STEPWIDTH 15
#define YAW_SYMBOLS 16
#define YAW_X_MIN (LCD_W-YAW_WIDTH)/2
#define YAW_X_MAX (LCD_W+YAW_WIDTH)/2

#define R2 11


-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()

#ifdef HUDTIMER
local hudDrawTime = 0
local hudDrawCounter = 0
#endif

local function drawHud(myWidget,drawLib,conf,telemetry,status,battery,utils)--getMaxValue,getBitmap,drawBlinkBitmap)
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
  if ( telemetry.roll == 0) then
    dx=0
    dy=telemetry.pitch
    cx=0
    cy=R2
    ccx=0
    ccy=2*R2
    cccx=0
    cccy=3*R2
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -telemetry.pitch
    dy = math.sin(math.rad(90 - r)) * telemetry.pitch
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * R2
    cy = math.sin(math.rad(90 - r)) * R2
    -- 2nd line offsets
    ccx = math.cos(math.rad(90 - r)) * 2 * R2
    ccy = math.sin(math.rad(90 - r)) * 2 * R2
    -- 3rd line offsets
    cccx = math.cos(math.rad(90 - r)) * 3 * R2
    cccy = math.sin(math.rad(90 - r)) * 3 * R2
  end
  local rollX = math.floor(HUD_X + HUD_WIDTH/2)
  -----------------------
  -- dark color for "ground"
  -----------------------
  -- 90x70
  local minY = HUD_Y
  local maxY = HUD_Y+HUD_HEIGHT
  --
  local minX = HUD_X
  local maxX = HUD_X + HUD_WIDTH
  --
  local ox = HUD_X + HUD_WIDTH/2 + dx
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
  lcd.setColor(CUSTOM_COLOR,COLOR_WHITE)
  -- +/- 90 deg
  for dist=1,8
  do
    drawLib.drawLineWithClipping(rollX + dx - dist*cx,dy + HUD_Y_MID + dist*cy,r,(dist%2==0 and 40 or 20),DOTTED,HUD_X+2,HUD_X+HUD_WIDTH-2,linesMinY,linesMaxY,CUSTOM_COLOR,radio,rev)
    drawLib.drawLineWithClipping(rollX + dx + dist*cx,dy + HUD_Y_MID - dist*cy,r,(dist%2==0 and 40 or 20),DOTTED,HUD_X+2,HUD_X+HUD_WIDTH-2,linesMinY,linesMaxY,CUSTOM_COLOR,radio,rev)
  end
  -------------------------------------
  -- hud bitmap
  -------------------------------------
  lcd.drawBitmap(utils.getBitmap("hud_90x70a"),(LCD_W-106)/2,HUD_Y-10) --106x90
  -------------------------------------
  -- vario bitmap
  -------------------------------------
  local varioMax = 5
  local varioSpeed = math.min(math.abs(0.1*telemetry.vSpeed),5)
  local varioH = 0
  if telemetry.vSpeed > 0 then
    varioY = VARIO_Y+46 - varioSpeed/varioMax*40
  else
    varioY = VARIO_Y+45
  end
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 0xce, 0))
  lcd.drawFilledRectangle(VARIO_X+26, varioY, 7, varioSpeed/varioMax*39, CUSTOM_COLOR, 0)  
  lcd.drawBitmap(utils.getBitmap("variogauge_90"),VARIO_X,VARIO_Y)
  
  if telemetry.vSpeed > 0 then
    lcd.drawBitmap(utils.getBitmap("varioline"),VARIO_X+21,varioY-1)
  else
    lcd.drawBitmap(utils.getBitmap("varioline"),VARIO_X+21,VARIO_Y+44 + varioSpeed/varioMax*39)
  end
#ifdef HUDTIMER
  hudDrawTime = hudDrawTime + (getTime() - hudStart)
  hudDrawCounter = hudDrawCounter + 1
#endif
  -- compass ribbon
  drawLib.drawCompassRibbon(YAW_Y,myWidget,conf,telemetry,status,battery,utils,YAW_WIDTH,YAW_X_MIN,YAW_X_MAX,YAW_STEPWIDTH)
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawHud=drawHud,background=background}