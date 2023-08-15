-- Copyrights

--[[ lua-term
  Copyright (c) 2009 Rob Hoelz <rob@hoelzro.net>

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
]]

--[[ log.lua

  Copyright (c) 2016 rxi

  This library is free software; you can redistribute it and/or modify it
  under the terms of the MIT license. See LICENSE for details.
]]

--[[ serpent.lua
  (C) 2012-18 Paul Kulchenko; MIT License
]]

--[[
  Termoon - A lua library for printing, logging and coloring for the terminal.
  I'll try to put this entire thing into one file, so it's easy to use :)

  includes:
  - lua-term
    - colors
    - cursor
    - clearing
  - serpent
    - pretty printing
    - serialization (dumping)
  - log
    - levels
    - colors
    - file logging

  missing:
  - formatting (also include lume.format)
  - color toggle
  - INPUT
  - color wrapping:
    - "hello %red{world}"

  problems:
  - isatty() comes from C


  function list:
    - termoon.colors.<color>(str)
    - termoon.clear()
    - termoon.cleareol()
    - termoon.cursor.jump(1, 1)
    - termoon.cursor.goup(1)
    - termoon.cursor.godown(1)
    - termoon.cursor.goright(1)
    - termoon.cursor.goleft(1)
    - termoon.cursor.save()
    - termoon.cursor.restore()

    - termoon.serialize()
    - termoon.deserialize()
    - termoon.line()
    - termoon.block()
    - termoon.dump()

    - termoon.log.setlevel(lvl)
    - termoon.log.setfile(file)
    - termoon.log.trace(...)
    - termoon.log.debug(...)
    - termoon.log.info(...)
    - termoon.log.warn(...)
    - termoon.log.error(...)
    - termoon.log.fatal(...)

    - termoon.logf.trace(str, ...)
    - termoon.logf.debug(str, ...)
    - termoon.logf.info(str, ...)
    - termoon.logf.warn(str, ...)
    - termoon.logf.error(str, ...)
    - termoon.logf.fatal(str, ...)

    - termoon.loglf.trace(str, vars)
    - termoon.loglf.debug(str, vars)
    - termoon.loglf.info(str, vars)
    - termoon.loglf.warn(str, vars)
    - termoon.loglf.error(str, vars)
    - termoon.loglf.fatal(str, vars)
    
    - termoon.prinf(str, ...)
    - termoon.prinlf(str, vars)
]]


local termoon = {}
termoon.colored = true

local function maketermfunc(sequence_fmt)
  local func
  func = function(handle, ...)
    if io.type(handle) ~= 'file' then
      return func(io.stdout, handle, ...)
    end
    return handle:write(string.format('\027[' .. sequence_fmt, ...))
  end

  return func
end


-- Colors
termoon.colors = {}

local colormt = {}
function colormt:__tostring()
  return self.value
end

function colormt:__concat(other)
  return tostring(self) .. tostring(other)
end

function colormt:__call(s)
  return self .. s .. termoon.colors.reset
end

local function makecolor(value)
  return setmetatable({ value = string.char(27) .. '[' .. tostring(value) .. 'm' }, colormt)
end

local colorvalues = {
  -- attributes
  reset      = 0,
  clear      = 0,
  default    = 0,
  bright     = 1,
  dim        = 2,
  underscore = 4,
  blink      = 5,
  reverse    = 7,
  hidden     = 8,

  -- foreground
  black      = 30,
  red        = 31,
  green      = 32,
  yellow     = 33,
  blue       = 34,
  magenta    = 35,
  cyan       = 36,
  white      = 37,

  -- background
  onblack    = 40,
  onred      = 41,
  ongreen    = 42,
  onyellow   = 43,
  onblue     = 44,
  onmagenta  = 45,
  oncyan     = 46,
  onwhite    = 47,
}

for c, v in pairs(colorvalues) do
  termoon.colors[c] = makecolor(v)
end

-- Cursor and Clearing
termoon.cursor = {
  jump    = maketermfunc'%d;%dH',
  goup    = maketermfunc'%dA',
  godown  = maketermfunc'%dB',
  goright = maketermfunc'%dC',
  goleft  = maketermfunc'%dD',
  save    = maketermfunc's',
  restore = maketermfunc'u',
}

termoon.clear    = maketermfunc'2J'
termoon.cleareol = maketermfunc'K'
termoon.clearend = maketermfunc'J'

-- pretty printing and serialization
local snum = {
  [tostring(1 / 0)] = '1/0 --[[math.huge]]',
  [tostring(-1 / 0)] = '-1/0 --[[-math.huge]]',
  [tostring(0 / 0)] = '0/0 --nan'
}
local badtype      = { thread = true, userdata = true, cdata = true }
local getmetatable = debug and debug.getmetatable or getmetatable
local pairs        = function(t) return next, t end
local keyword, globals, G = {}, {}, (_G or _ENV)
for _, k in ipairs({ 'and', 'break', 'do', 'else', 'elseif', 'end', 'false',
  'for', 'function', 'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat',
  'return', 'then', 'true', 'until', 'while' }) do keyword[k] = true end
for k, v in pairs(G) do globals[v] = k end
for _, g in ipairs({ 'coroutine', 'debug', 'io', 'math', 'string', 'table', 'os' }) do
  for k, v in pairs(type(G[g]) == 'table' and G[g] or {}) do globals[v] = g .. '.' .. k end
end

local function serialize(t, opts)
  local name, indent, fatal, maxnum = opts.name, opts.indent, opts.fatal, opts.maxnum
  local sparse, custom, huge = opts.sparse, opts.custom, not opts.nohuge
  local space, maxl = (opts.compact and '' or ' '), (opts.maxlevel or math.huge)
  local maxlen, metatostring = tonumber(opts.maxlength), opts.metatostring
  local iname, comm = '_' .. (name or ''), opts.comment and (tonumber(opts.comment) or math.huge)
  local numformat = opts.numformat or "%.17g"
  local seen, sref, syms, symn = {}, { 'local ' .. iname .. '={}' }, {}, 0
  local function gensym(val)
    return '_' .. (tostring(tostring(val)):gsub("[^%w]", ""):gsub("(%d%w+)",
      function(s)
        if not syms[s] then
          symn = symn + 1; syms[s] = symn
        end
        return tostring(syms[s])
      end))
  end
  local function safestr(s)
    return type(s) == "number" and (huge and snum[tostring(s)] or numformat:format(s))
        or type(s) ~= "string" and tostring(s)
        or ("%q"):format(s):gsub("\010", "n"):gsub("\026", "\\026")
  end
  if opts.fixradix and (".1f"):format(1.2) ~= "1.2" then
    local origsafestr = safestr
    safestr = function(s)
      return type(s) == "number"
          and (nohuge and snum[tostring(s)] or numformat:format(s):gsub(",", ".")) or origsafestr(s)
    end
  end
  local function comment(s, l) return comm and (l or 0) < comm and ' --[[' .. select(2, pcall(tostring, s)) .. ']]' or '' end
  local function globerr(s, l)
    return globals[s] and globals[s] .. comment(s, l) or not fatal
        and safestr(select(2, pcall(tostring, s))) or error("Can't serialize " .. tostring(s))
  end
  local function safename(path, name)
    local n = name == nil and '' or name
    local plain = type(n) == "string" and n:match("^[%l%u_][%w_]*$") and not keyword[n]
    local safe = plain and n or '[' .. safestr(n) .. ']'
    return (path or '') .. (plain and path and '.' or '') .. safe, safe
  end
  local alphanumsort = type(opts.sortkeys) == 'function' and opts.sortkeys or function(k, o, n)
    local maxn, to = tonumber(n) or 12, { number = 'a', string = 'b' }
    local function padnum(d) return ("%0" .. tostring(maxn) .. "d"):format(tonumber(d)) end
    table.sort(k, function(a, b)
      return (k[a] ~= nil and 0 or to[type(a)] or 'z') .. (tostring(a):gsub("%d+", padnum))
          < (k[b] ~= nil and 0 or to[type(b)] or 'z') .. (tostring(b):gsub("%d+", padnum))
    end)
  end
  local function val2str(t, name, indent, insref, path, plainindex, level)
    local ttype, level, mt = type(t), (level or 0), getmetatable(t)
    local spath, sname = safename(path, name)
    local tag = plainindex and
        ((type(name) == "number") and '' or name .. space .. '=' .. space) or
        (name ~= nil and sname .. space .. '=' .. space or '')
    if seen[t] then
      sref[#sref + 1] = spath .. space .. '=' .. space .. seen[t]
      return tag .. 'nil' .. comment('ref', level)
    end

    if type(mt) == 'table' and metatostring ~= false then
      local to, tr = pcall(function() return mt.__tostring(t) end)
      local so, sr = pcall(function() return mt.__serialize(t) end)
      if (to or so) then
        seen[t] = insref or spath
        t = so and sr or tr
        ttype = type(t)
      end
    end
    if ttype == "table" then
      if level >= maxl then return tag .. '{}' .. comment('maxlvl', level) end
      seen[t] = insref or spath
      if next(t) == nil then return tag .. '{}' .. comment(t, level) end
      if maxlen and maxlen < 0 then return tag .. '{}' .. comment('maxlen', level) end
      local maxn, o, out = math.min(#t, maxnum or #t), {}, {}
      for key = 1, maxn do o[key] = key end
      if not maxnum or #o < maxnum then
        local n = #o
        for key in pairs(t) do
          if o[key] ~= key then
            n = n + 1; o[n] = key
          end
        end
      end
      if maxnum and #o > maxnum then o[maxnum + 1] = nil end
      if opts.sortkeys and #o > maxn then alphanumsort(o, t, opts.sortkeys) end
      local sparse = sparse and #o > maxn
      for n, key in ipairs(o) do
        local value, ktype, plainindex = t[key], type(key), n <= maxn and not sparse
        if opts.valignore and opts.valignore[value]
            or opts.keyallow and not opts.keyallow[key]
            or opts.keyignore and opts.keyignore[key]
            or opts.valtypeignore and opts.valtypeignore[type(value)]
            or sparse and value == nil then
        elseif ktype == 'table' or ktype == 'function' or badtype[ktype] then
          if not seen[key] and not globals[key] then
            sref[#sref + 1] = 'placeholder'
            local sname = safename(iname, gensym(key))
            sref[#sref] = val2str(key, sname, indent, sname, iname, true)
          end
          sref[#sref + 1] = 'placeholder'
          local path = seen[t] .. '[' .. tostring(seen[key] or globals[key] or gensym(key)) .. ']'
          sref[#sref] = path .. space .. '=' .. space .. tostring(seen[value] or val2str(value, nil, indent, path))
        else
          out[#out + 1] = val2str(value, key, indent, nil, seen[t], plainindex, level + 1)
          if maxlen then
            maxlen = maxlen - #out[#out]
            if maxlen < 0 then break end
          end
        end
      end
      local prefix = string.rep(indent or '', level)
      local head = indent and '{\n' .. prefix .. indent or '{'
      local body = table.concat(out, ',' .. (indent and '\n' .. prefix .. indent or space))
      local tail = indent and "\n" .. prefix .. '}' or '}'
      return (custom and custom(tag, head, body, tail, level) or tag .. head .. body .. tail) .. comment(t, level)
    elseif badtype[ttype] then
      seen[t] = insref or spath
      return tag .. globerr(t, level)
    elseif ttype == 'function' then
      seen[t] = insref or spath
      if opts.nocode then return tag .. "function() --[[..skipped..]] end" .. comment(t, level) end
      local ok, res = pcall(string.dump, t)
      local func = ok and "((loadstring or load)(" .. safestr(res) .. ",'@serialized'))" .. comment(t, level)
      return tag .. (func or globerr(t, level))
    else
      return tag .. safestr(t)
    end
  end
  local sepr = indent and "\n" or ";" .. space
  local body = val2str(t, name, indent)
  local tail = #sref > 1 and table.concat(sref, sepr) .. sepr or ''
  local warn = opts.comment and #sref > 1 and space .. "--[[incomplete output with shared/self-references skipped]]" or ''
  return name and "do local "..body..sepr..tail.."return "..name..sepr.."end" or body..warn
end

local function deserialize(data, opts)
  local env = (opts and opts.safe == false) and G
      or setmetatable({}, {
        __index = function(t, k) return t end,
        __call = function(t, ...) error("cannot call functions") end
      })
  local f, res = (loadstring or load)('return ' .. data, nil, nil, env)
  if not f then f, res = (loadstring or load)(data, nil, nil, env) end
  if not f then return f, res end
  if setfenv then setfenv(f, env) end
  return pcall(f)
end

local function merge(a, b)
  if b then for k, v in pairs(b) do a[k] = v end end
  return a
end
termoon.serialize   = serialize
termoon.deserialize = deserialize
termoon.line  = function(a, opts) return serialize(a, merge({ sortkeys = true, comment = true }, opts)) end
termoon.block = function(a, opts) return serialize(a, merge({ sortkeys = true, comment = true, indent = '  ' }, opts)) end
termoon.dump  = function(a, opts) return serialize(a, merge({ name = '_', compact = true, sparse = true }, opts)) end

-- logging
termoon.log = {}
termoon.log.outfile = nil
termoon.log.level   = "trace"
termoon.log.setlevel = function(level)
  termoon.log.level = level
end
termoon.log.setoutfile = function(outfile)
  termoon.log.outfile = outfile
end
termoon.logf, termoon.loglf = {}, {}

local modes = {
  { name = "trace", color = "\27[34m", },
  { name = "debug", color = "\27[36m", },
  { name = "info",  color = "\27[32m", },
  { name = "warn",  color = "\27[33m", },
  { name = "error", color = "\27[31m", },
  { name = "fatal", color = "\27[35m", },
}

local levels = {}
for i, v in ipairs(modes) do
  levels[v.name] = i
end

local function lumeformat(str, vars)
  if not vars then
    return str
  end
  local f = function(x)
    local index = tonumber(x)
    if index then
      return tostring(vars[index])
    else
      return tostring(vars[x])
    end
  end
  return str:gsub("{(.-)}", f)
end

local _tostring = function(...)
  local round = function(x, increment)
    increment = increment or 1
    x = x / increment
    return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
  end
  local t = {}
  for i = 1, select('#', ...) do
    local x = select(i, ...)
    if type(x) == "number" then
      x = round(x, .01)
    end
    t[#t + 1] = tostring(x)
  end
  return table.concat(t, " ")
end

for i, x in ipairs(modes) do
  local nameupper = x.name:upper()
  termoon.log[x.name] = function(...)
    -- Return early if we're below the log level
    if i < levels[termoon.log.level] then
      return
    end

    local msg = _tostring(...)
    local info = debug.getinfo(2, "Sl")
    local lineinfo = info.short_src .. ":" .. info.currentline

    -- Output to console
    io.write(string.format(
      "%s[%-6s%s]%s %s: %s\n",
      termoon.colored and x.color or "",
      nameupper,
      os.date("%H:%M:%S"),
      termoon.colored and "\27[0m" or "",
      lineinfo,
      msg
    ))

    -- Output to log file
    if termoon.log.outfile then
      local fp = assert(io.open(termoon.log.outfile, "a"))
      local str = string.format("[%-6s%s] %s: %s\n", nameupper, os.date(), lineinfo, msg)
      fp:write(str)
      fp:close()
    end
  end
  termoon.logf[x.name] = function(str, ...)
    -- Return early if we're below the log level
    if i < levels[termoon.log.level] then
      return
    end

    local msg = string.format(str, ...)
    local info = debug.getinfo(2, "Sl")
    local lineinfo = info.short_src .. ":" .. info.currentline

    -- Output to console
    io.write(string.format(
      "%s[%-6s%s]%s %s: %s\n",
      termoon.colored and x.color or "",
      nameupper,
      os.date("%H:%M:%S"),
      termoon.colored and "\27[0m" or "",
      lineinfo,
      msg
    ))

    -- Output to log file
    if termoon.log.outfile then
      local fp = assert(io.open(termoon.log.outfile, "a"))
      local str = string.format("[%-6s%s] %s: %s\n", nameupper, os.date(), lineinfo, msg)
      fp:write(str)
      fp:close()
    end
  end
  termoon.loglf[x.name] = function(str, vars)
    -- Return early if we're below the log level
    if i < levels[termoon.log.level] then
      return
    end

    local msg = lumeformat(str, vars)
    local info = debug.getinfo(2, "Sl")
    local lineinfo = info.short_src .. ":" .. info.currentline

    -- Output to console
    io.write(string.format(
      "%s[%-6s%s]%s %s: %s\n",
      termoon.colored and x.color or "",
      nameupper,
      os.date("%H:%M:%S"),
      termoon.colored and "\27[0m" or "",
      lineinfo,
      msg
    ))

    -- Output to log file
    if termoon.log.outfile then
      local fp = assert(io.open(termoon.log.outfile, "a"))
      local str = string.format("[%-6s%s] %s: %s\n", nameupper, os.date(), lineinfo, msg)
      fp:write(str)
      fp:close()
    end
  end
end

-- formatting
function termoon.printf(str, ...)
  io.write(string.format(str, ...)..'\n')
end

function termoon.printlf(str, vars)
  io.write(lumeformat(str, vars)..'\n')
end

return termoon