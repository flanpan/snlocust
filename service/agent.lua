local skynet = require "skynet"

function init(uid, timeout, script, host)
    _G.agent = {
        uid = uid,
        host = host,
        on_exit = nil
    }
    agent.uid = uid
    agent.host = host
    math.randomseed(skynet.now())
    skynet.timeout(timeout * 100, function() require(script) end)
end

function exit()
    if type(agent.on_exit) == 'function' then
        agent.on_exit()
    end
end