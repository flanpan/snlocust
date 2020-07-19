local skynet = require "skynet"
local util = require "common.util"
local monitor = require "common.monitor"

local tests = {}

function tests.test1()
    monitor.time('test', 'test1')
    skynet.timeout(20, function()
        monitor.endtime('test','test1', 150)
    end)
end

function tests.test2()
    monitor.time('test', 'test2')
    skynet.timeout(10, function()
        local size = 100
        local failed = math.random(1,5) == 3
        monitor.endtime('test','test2', 100, failed)
    end)
end

local fweight = {
    test1 = 1,
    test2 = 2
}

util.run(tests, fweight, 2, 2)