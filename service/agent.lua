local skynet = require "skynet"

local script, host, uid = ...

_G.agent = {
    uid = tonumber(uid),
    host = host
}
_G.console = require "console"

require(script)

local CMD = {}

function CMD.exit()
    if type(_G.exit) == 'function' then
        _G.exit()
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(_,_,cmd)
        local f = CMD[cmd]
        assert(f, cmd)
    end)
    skynet.fork(function()
        if type(_G.main) == "function" then
            _G.main(uid, host)
        end
    end)
end)
