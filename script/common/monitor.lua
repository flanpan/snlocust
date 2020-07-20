local snax = require "skynet.snax"

local monitor = {}
local stats_service = {}
local counter_service = {}
local sessions = {}
local function queryservice(name, type)
    local s
    if type then
        if not stats_service[type] then stats_service[type] = {} end
        s = stats_service[type][name]
        if not s then
            local web = snax.uniqueservice 'web'
            local addr = web.req.stats_service(type, name)
            s = snax.bind(addr, 'stats')
            stats_service[type][name] = s
        end
        return s
    end
    s = counter_service[name]
    if s then return s end
    local web = snax.uniqueservice 'web'
    local addr = web.req.counter_service(name)
    s = snax.bind(addr, 'counter')
    counter_service[name] = s
    return s
end

function monitor.incr(name)
    local s = queryservice(name)
    s.post.incr()
end

function monitor.decr(name)
    local s = queryservice(name)
    s.post.decr()
end

function monitor.time(type, name, session)
    sessions[session] = {type = type, name = name}
    local s = queryservice(name, type)
    s.post.time(agent.uid, session)
end

function monitor.endtime(session, size, is_failed)
    local info = sessions[session]
    assert(info, 'session not record.')
    sessions[session] = nil
    local s = queryservice(info.name, info.type)
    s.post.endtime(agent.uid, session, size, is_failed)
end

return monitor