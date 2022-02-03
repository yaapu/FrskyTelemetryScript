local panel = {}
local status = nil
local libs = nil

function panel.draw(widget,x)
  lcd.font(ITALIC)
  lcd.color(status.colors.green)
  lcd.drawText(600, 100, "RIGHT 2")

  libs.drawLib.drawText(564, 168, "R2", FONT_XS, lcd.RGB(100,100,100), LEFT)
end

function panel.background(widget)
end

function panel.init(param_status, param_libs)
  status = param_status
  libs = param_libs
  return panel
end

return panel
