local skynet = require "skynet"

function init(uid, timeout, script, host)
    _G.uid = uid
    _G.host = host
    math.randomseed(skynet.now())
    skynet.timeout(timeout * 100, function() require(script) end)
end
