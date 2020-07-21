local skynet = require "skynet"
local snax = require "skynet.snax"

skynet.start(function()
    local debug_port = skynet.getenv("debug_port") or 2666
    skynet.uniqueservice("debug_console",debug_port)
    local web = snax.uniqueservice "web"
    local logger_addr = skynet.localname ".logger"
    skynet.call(logger_addr, 'lua', 'webservice', web.handle)
    skynet.exit()
end)