local util = require "common.util"
local monitor = require "monitor"
local tests = {}

function tests.incr1()
    monitor.incr('test1')
end

function tests.decr1()
    monitor.decr('test1')
end

function tests.incr2()
    monitor.incr('test2')
end

function tests.decr2()
    monitor.decr('test2')
end

local fweight = {
    incr1 = 1,
    decr1 = 2,
    incr2 = 2,
    decr2 = 1
}

util.run(tests, fweight, 1, 2)
