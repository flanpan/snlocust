local skynet = require "skynet"

function init(uid, script, host)
    _G.agent = {
        uid = uid,
        host = host,
        on_exit = nil
    }
    agent.uid = uid
    agent.host = host
    _G.console = require "console"
    math.randomseed(skynet.now())
    require(script)
end

function exit()
    if type(agent.on_exit) == 'function' then
        agent.on_exit()
    end
end