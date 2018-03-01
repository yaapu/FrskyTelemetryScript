--[[

USAGE: pproc <inputFile> [outputFile]

If outputFile is not specified, pproc will write output to this path: inputFile .. ".lua"

]]


local args = {...}

local erf
if shell then
  if shell.writeOutputC then
    erf = function(t)
      shell.writeOutputC(t, 8)
    end
  elseif printError then
    erf = function(t)
      printError(t)
    end
  else
    erf = function(t)
      error(t)
    end
  end
else
  erf = function(t)
    error(t)
  end
end

local outAPI = io

if not args[1] then
  if shell then
    local prog = shell.getRunningProgram()
    erf("Syntax: " .. (prog or "pproc") .. " <input> [outfile]\n")
    return
  else
    erf("Syntax: pproc <input> [outfile]")
  end
end

local setfenv = setfenv
local ifEQ = true

if not setfenv then
  if debug then
    setfenv = function(fn, env)
      local i = 1
      while true do
        local name = debug.getupvalue(fn, i)
        if name == "_ENV" then
          debug.upvaluejoin(fn, i, (function()
            return env
          end), 1)
          break
        elseif not name then
          break
        end

        i = i + 1
      end

      return fn
    end
  else
    erf("No debug library, `if' ppc disabled")
    ifEQ = false
  end
end

local loadStr = loadstring or load

local fn = args[1]

local handle = outAPI.open(fn, "r")
local data = handle:read("*all") .. "\n"
handle:close()

local function trimS(s)
  return s:match("%s*(.+)")
end

local function trimF(s)
  local fp = s:match("%s*(.+)")
  local sp = fp:reverse():match("%s*(.+)")
  return sp:reverse()
end

local function sw(str, swr)
  return str:sub(1, #swr) == swr
end

local function parenfind(str)
  local first = str:find("%(")
  if not first then
    return
  end

  local rest = str:sub(first + 1)
  local last

  local embed = 0
  for i = 1, #rest do
    local c = rest:sub(i, i)
    if c == "(" then
      embed = embed + 1
    elseif c == ")" then
      embed = embed - 1
      if embed == -1 then
        last = i
        break
      end
    end
  end

  if last then
    return first, first + last, str:sub(first, first + last)
  else
    return
  end
end

local final = ""

local scope = {}
local multiline = false
local lineI = 0

local function attemptSub(line)
  local lineP = ""

  while #line > 0 do
    local c = line:sub(1, 1); line = line:sub(2)
    local p = line:sub(1, 1)

    if c == "\"" or c == "'" then
      lineP = lineP .. c

      local escaping = false
      for char in line:gmatch(".") do
        lineP = lineP .. char
        line = line:sub(2)
        if char == c and not escaping then  
          break
        elseif char == "\\" then
          escaping = true
        else
          escaping = false
        end
      end
    elseif c == "[" and p == "[" then
      multiline = true

      local endS = line:find("]]")
      if endS then
        lineP = lineP .. line:sub(1, endS + 1)
        line = line:sub(endS + 2)
        multiline = false
      else
        lineP = lineP .. c .. line
        line = ""
      end
    else
      local nextS = line:find("[\"']")
      local nextM = line:find("%[%[")
      local next = math.min(nextS or #line + 1, nextM or #line + 1)

      local safe = c .. line:sub(1, next - 1)
      local safeOff = 0

      while #safe > 0 do
        local nextPKW, endPKW, Pstr = safe:find("([%a_][%w_]*)")
        if nextPKW then
          lineP = lineP .. safe:sub(1, nextPKW - 1)
          safe = safe:sub(endPKW + 1)
          safeOff = safeOff + endPKW
          
          local found = false
          for i = 1, #scope do
            if scope[i][1] == Pstr then
              if scope[i][3] then
                local s, e, tinner = parenfind(line:sub(safeOff))

                if e then 
                  next = safeOff + e
                  safe = line:sub(safeOff + e, next - 1)
                  safeOff = safeOff + e
                end

                if s == 1 then
                  local paramsS = tinner:sub(2, #tinner - 1)
                  local params = {}

                  for param in paramsS:gmatch("[^%,]+") do
                    params[#params + 1] = trimF(param)
                  end

                  local modded = {}
                  local tempHold = {}
                  for k = 1, #scope[i][3] do
                    local v = scope[i][3][k]

                    local indTA = #scope + 1
                    for j = 1, #scope do
                      if v == scope[j][1] then
                        tempHold[j] = {scope[j][1], scope[j][2], scope[j][3]}
                        indTA = j
                        break
                      end
                    end

                    scope[indTA] = {v, params[k]}
                    modded[#modded + 1] = indTA
                  end

                  lineP = lineP .. attemptSub(scope[i][2])

                  for p = 1, #modded do
                    local indER = modded[p]
                    if tempHold[indER] then
                      scope[indER] = tempHold[indER]
                    else
                      scope[indER] = nil
                    end
                  end

                  found = true
                  break
                else
                  erf("PP WARN: (Line " .. lineI .. ")\n`" .. Pstr .. "' is a macro function, but is not called\n")
                  lineP = lineP .. attemptSub(scope[i][2])
                  found = true
                  break
                end
              else
                lineP = lineP .. attemptSub(scope[i][2])
                found = true
                break
              end
            end
          end

          if not found then
            lineP = lineP .. Pstr
          end
        else
          lineP = lineP .. safe
          safe = ""
        end
      end

      line = line:sub(next)
    end
  end

  return lineP
end

local skipBlock = 0
local openInner = 0
local lines = {}
for line in data:gmatch("([^\n]*)\n") do
  lines[#lines + 1] = line
end

while #lines > 0 do
  local line = table.remove(lines, 1)
  lineI = lineI + 1
  
  if skipBlock > 0 then
    local trim = trimS(line) or ""
    if trim:sub(1, 1) == "#" then
      -- Preprocessor instruction
      local inst = trimS(trim:sub(2))

      if sw(inst, "else") then
        if openInner == 0 then
          skipBlock = skipBlock - 1
        end
      elseif sw(inst, "endif") then
        if openInner == 0 then
          skipBlock = skipBlock - 1
        else
          openInner = openInner - 1
        end
      elseif sw(inst, "ifndef") or sw(inst, "ifdef") then
        openInner = openInner + 1
      end
    end
  else
    if multiline then
      local endS = line:find("]]")
      if endS then
        final = final .. line:sub(1, endS + 1)
        line = line:sub(endS + 2)
        multiline = false
      else
        final = final .. line .. "\n"
        line = ""
      end
    else
      local trim = trimS(line) or ""
      if trim:sub(1, 1) == "#" then
        -- Preprocessor instruction
        local inst = trimS(trim:sub(2))

        if sw(inst, "include") then
          local command = trimS(inst:sub(3))
          local inStr = command:match("%b\"\"")
          if inStr then
            local fn = inStr:sub(2, #inStr - 1)
            local Ihandle = io.open(fn, "rb")
            if Ihandle then
              local Idata = Ihandle:read("*all") .. "\n"
              local Ilines = {}

              for Iline in Idata:gmatch("([^\n]*)\n") do
                Ilines[#Ilines + 1] = Iline
              end

              for r = 1, #lines do
                  Ilines[#Ilines + 1] = lines[r]
              end

              lines = Ilines
            else
              erf("Preprocessor parse error: (Line " .. lineI .. ")\nCannot find `" .. fn .. "'\n")
            end
          else
            erf("Preprocessor parse error: (Line " .. lineI .. ")\nUnknown include strategy\n")
          end
        elseif sw(inst, "define") then
          local command = trimS(inst:sub(7))
          local name = command:match("%S+")
          local nameCMD = command:match("%S+%b()")
          if nameCMD then
            name = nameCMD
          end
          local fnSt, fnEnd, inner = name:find("(%b())")

          local rest = command:sub(#name + 2)

          local params
          if fnSt then
            name = name:sub(1, fnSt - 1)
            rest = command:sub(fnEnd + 2)

            local paramsS = inner:sub(2, #inner - 1)
            params = {}

            for param in paramsS:gmatch("[^%,%s]+") do
              params[#params + 1] = param
            end
          end

          scope[#scope + 1] = {name, rest, params}
        elseif sw(inst, "undef") then
          local command = trimS(inst:sub(6))
          local name = command:match("%S+")

          for i = 1, #scope do
            if scope[i][1] == name then
              table.remove(scope, i)
              break
            end
          end
        elseif sw(inst, "ifdef") then
          local command = trimS(inst:sub(6))
          local name = command:match("%S+")

          local found = false
          for i = 1, #scope do
            if scope[i][1] == name then
              found = true
              break
            end
          end

          if not found then
            skipBlock = skipBlock + 1
          end
        elseif sw(inst, "ifndef") then
          local command = trimS(inst:sub(7))
          local name = command:match("%S+")

          local found = false
          for i = 1, #scope do
            if scope[i][1] == name then
              found = true
              break
            end
          end

          if found then
            skipBlock = skipBlock + 1
          end
        elseif sw(inst, "if") then
          if not ifEQ then
            erf("Preprocessor parse error: (Line " .. lineI .. ")\n`if' ppc is disabled\n")
          else
            local command = trimS(inst:sub(3))
            local fn, er = loadStr("return (" .. command .. ")")

            if not fn then
              er = er and er:sub(er:find(":") + 4) or "Invalid conditional"
              erf("Preprocessor parse error: (Line " .. lineI .. ")\n" .. er .. "\n")
            else
              local fscope = {}
              for i = 1, #scope do
                local val = scope[i][2]
                if tonumber(val) then val = tonumber(scope[i][2]) end
                fscope[scope[i][1]] = val
              end
              setfenv(fn, fscope)

              local succ, sret = pcall(fn)

              if not succ then
                sret = sret and sret:sub(sret:find(":") + 4) or "Invalid conditional"
                erf("Preprocessor parse error: (Line " .. lineI .. ")\n" .. sret .. "\n")
                skipBlock = skipBlock + 1
              elseif not sret then
                skipBlock = skipBlock + 1
              end
            end
          end
        elseif sw(inst, "else") then
          skipBlock = skipBlock + 1
        elseif sw(inst, "endif") then
          -- Doesn't affect flow, only applicable to helping blocks
        else
          erf("Preprocessor parse error: (Line " .. lineI .. ")\nUnknown instruction `" .. inst:match("%S+") .. "'\n")
        end
      else
        local lineP = attemptSub(line)

        final = final .. lineP .. "\n"
      end
    end
  end

  
end

local outFN = args[2] or (args[1] .. ".lua")
local outHandle = outAPI.open(outFN, "w")
if outHandle then
  outHandle:write(final)
  outHandle:close()
end
