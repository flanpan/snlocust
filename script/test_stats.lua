local skynet = require "skynet"
local util = require "common.util"
local monitor = require "common.monitor"

local session = 0
local function get_session()
    session = session + 1
    return session
end

local tests = {}

function tests.test1()
    local s = get_session()
    monitor.time('test', 'test1', s)
    skynet.timeout(20, function()
        monitor.endtime(s, 150)
    end)
end

function tests.test2()
    local s = get_session()
    monitor.time('test', 'test2', s)
    skynet.timeout(10, function()
        local size = 100
        local failed = math.random(1,5) == 3
        monitor.endtime(s, 100, failed)
    end)
end

local fweight = {
    test1 = 1,
    test2 = 2
}

util.run(tests, fweight, 2, 2)