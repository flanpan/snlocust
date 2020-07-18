local skynet = require "skynet"

local function ping()
    skynet.timeout(100, function()
        skynet.error('ping', uid)
        ping()
    end)
end

ping()