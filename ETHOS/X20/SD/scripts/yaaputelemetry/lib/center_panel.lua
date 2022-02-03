local panel = {}
local status = nil
local libs = nil

function panel.draw(widget)
  libs.hudLib.drawHud(widget)
end

function panel.background(widget)
end

function panel.init(param_status, param_libs)
  status = param_status
  libs = param_libs
  return panel
end

return panel
