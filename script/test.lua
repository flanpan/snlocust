local skynet = require "skynet"
skynet.timeout(100, function()
    skynet.error('ping', uid)
end)