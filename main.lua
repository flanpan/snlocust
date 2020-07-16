local skynet = require "skynet"

skynet.start(function()
    skynet.uniqueservice("debug_console",8000)
    skynet.exit()
end)