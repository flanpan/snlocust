local skynet = require "skynet"
local uid = ...

local env = {
    log = function(...) skynet.error('['..uid..']', ...) end,
    uid = uid,
    req = function() end,
    res = function() end,
}

local cmds = {}
function cmds.run_script(name)
    local f, err = loadfile('script/'..name , 'bt', env)
    if err then skynet.error(err) end
    f()
end

skynet.start(function(id)
    skynet.dispatch("lua", function(session, address, cmd, ...)
        cmd = cmd:lower()
		local f = cmds[cmd]
        if not f then error(string.format("Unknown command %s", tostring(cmd))) end
	    skynet.ret(skynet.pack(f(...)))
    end)
    cmds.run_script('init.lua')
end)