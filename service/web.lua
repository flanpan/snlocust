local skynet = require "skynet"

local http_api = require "http_api"
local ws_api = require "ws_api"

local REPORT_STATS_INTERVAL = 100 --1s
local cmds = {}

local stats = {
    start_time = nil,
    user_count = 0,
    msgs = {}-- max, min, sum, count
}
local update_stats = false

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
    dispatch = function(_, address, msg)
        msg = string.format(":%08x: %s", address, msg)
        print(msg)
        ws_api.broadcast('log', msg)
	end
}

-- local function report_stats()
--     if update_stats then 
--         ws_broadcast('stats', stats)
--         update_stats = false
--     end
--     skynet.timeout(REPORT_STATS_INTERVAL, report_stats)
-- end

function cmds.stats(data)
    if not stats.start_time then return end
    update_stats = true
    if data.user_count then stats.user_count = data.user_count end
    local msgs = data.msgs
    if not msgs then return end
    for k,v in pairs(msgs) do
        if not stats[k] then stats[k] = v end
        local obj = stats[k]
        if v.max > obj.max then obj.max = v.max end
        if v.min < obj.min then obj.min = v.min end
        obj.count = obj.count + v.count
        obj.sum = obj.sum + v.sum
    end
end

skynet.start(function()
    http_api.start_http(8001)
    ws_api.start_ws(8002)
    -- skynet.timeout(REPORT_STATS_INTERVAL, report_stats)
    skynet.dispatch("lua", function(session, address, cmd, ...)
        cmd = cmd:lower()
		local f = cmds[cmd]
        if not f then error(string.format("Unknown command %s", tostring(cmd))) end
	    skynet.ret(skynet.pack(f(...)))
    end)
end)
