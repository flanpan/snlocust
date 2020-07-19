local skynet = require "skynet"

function init(uid, timeout, script)
    _G.uid = uid
    math.randomseed(skynet.now())
    skynet.timeout(timeout * 100, function() require(script) end)
end
