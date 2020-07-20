local skynet = require "skynet"
local util = {}

function util.uid() return _G.uid end

function util.host() return _G.host end

function util.log(...) return skynet.error(_G.uid, ...) end

function util.random(a, b)
  if not a then a, b = 0, 1 end
  if not b then b = 0 end
  return a + math.random() * (b - a)
end


function util.weightedchoice(t)
  local sum = 0
  for _, v in pairs(t) do
    assert(v >= 0, "weight value less than zero")
    sum = sum + v
  end
  assert(sum ~= 0, "all weights are zero")
  local rnd = util.random(sum)
  for k, v in pairs(t) do
    if rnd < v then return k end
    rnd = rnd - v
  end
end

function util.run(class, fweight, min_interval, max_interval)
    local funname = util.weightedchoice(fweight)
    local fun = class[funname]
    if type(fun) ~= 'function' then return end
    local interval = math.random(min_interval, max_interval) * 100
    interval = interval // 1
    skynet.timeout(interval, function()
      fun()
      util.run(class, fweight, min_interval, max_interval)
    end)
end

return util