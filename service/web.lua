local skynet = require "skynet"
local runner = require "runner"
local dataset = require "dataset"
local queue = require "skynet.queue"

local lock

function init()
    lock = queue()
    runner.start(8001, 8002)
end

function accept.broadcast(type, body)
    runner.broadcast(type, body)
end

function response.stats_service(method, name)
    local addr
    lock(function()
    addr = dataset.stats_service(method, name)
    end)
    return addr
end

function response.counter_service(name)
    local addr
    lock(function()
    addr = dataset.counter_service(name)
    end)
    return addr
end

function accept.report_stats(...)
    dataset.report_stats(...)
end

function accept.report_counter(...)
    dataset.report_counter(...)
end
