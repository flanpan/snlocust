local skynet = require "skynet"
local runner = require "runner"
local dataset = require "dataset"
local queue = require "skynet.queue"

local lock_counter
local lock_stats

function init()
    lock_counter = queue()
    lock_stats = queue()
    local http_port = skynet.getenv('http_port') or 8001
    local ws_port = skynet.getenv('ws_port') or 8002
    runner.start(http_port, ws_port)
end

function accept.broadcast(type, body)
    runner.broadcast(type, body)
end

function response.stats_service(method, name)
    local addr
    lock_stats(function()
    addr = dataset.stats_service(method, name)
    end)
    return addr
end

function response.counter_service(name)
    local addr
    lock_counter(function()
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
