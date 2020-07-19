local skynet = require "skynet"
local snax = require "skynet.snax"
local webservice
skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
    dispatch = function(_, address, msg)
        msg = string.format(":%08x: %s", address, msg)
        print(msg)
        if webservice then
            webservice.post.broadcast('log', msg)
        end
	end
}

local function set_webservice(addr)
    webservice = snax.bind(addr, "web")
end

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        if cmd == "webservice" then
            set_webservice(...)
			skynet.ret()
		end
	end)
end)