local skynet = require "skynet"
require "skynet.manager"
local agents = {}
local cmds = {}

function cmds.start(id_start, id_count, per_sec)
    cmds.stop()
    for id = id_start, id_count do
        agents[id] = skynet.newservice('agent', id)
    end
end

function cmds.stop()
    for id, addr in pairs(agents) do
        skynet.kill(addr)
        skynet.error('agent:', id, 'exit.')
    end
    agents = {}
end

function cmds.run_script(script)
    for id, addr in pairs(agents) do
        skyent.call(addr, 'lua', 'run_script', script)
    end
end

-- skynet.cache.mode "OFF"

skynet.start(function()
    skynet.newservice("debug_console",8000)
    -- skynet.newservice("web")
	skynet.dispatch("lua", function(session, address, cmd, ...)
        cmd = cmd:lower()
		local f = cmds[cmd]
        if not f then error(string.format("Unknown command %s", tostring(cmd))) end
	    skynet.ret(skynet.pack(f(...)))
	end)
end)