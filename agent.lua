local skynet = require "skynet"
local uid, script = ...

local cmds = {}
log = skynet.error

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        cmd = cmd:lower()
		local f = cmds[cmd]
        if not f then error(string.format("Unknown command %s", tostring(cmd))) end
	    skynet.ret(skynet.pack(f(...)))
    end)
    local f, err = loadfile('script/init.lua', 'bt', _G)
    if err then skynet.error(err) end
    f(uid, script)
end)