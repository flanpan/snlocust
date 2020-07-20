local skynet = require "skynet"
local util = {}

function util.uid() return agent.uid end

function util.host() return agent.host end

function util.address()
    local host = util.host()
    local pos = string.find(host, ':')
    local ip = string.sub(host, 1, pos - 1)
    local port = string.sub(host, pos + 1)
    return ip, port
end

function util.log(...) return skynet.error(agent.uid, ...) end

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

function util.run(class, fweight, min_interval, max_interval, on_exit)
    local funname = util.weightedchoice(fweight)
    local fun = class[funname]
    if type(fun) ~= 'function' then return end
    local interval = math.random(min_interval, max_interval) * 100
    interval = interval // 1
    skynet.timeout(interval, function()
      fun()
      util.run(class, fweight, min_interval, max_interval)
    end)
    agent.on_exit = on_exit
end

return util