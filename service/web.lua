local skynet = require "skynet"
local runner = require "runner"
local dataset = require "dataset"

function init()
    runner.start(8001, 8002)
end

function accept.broadcast(type, body)
    runner.broadcast(type, body)
end

function response.stats_service(...)
    return dataset.stats_service(...)
end

function response.counter_service(...)
    return dataset.counter_service(...)
end

function accept.report_stats(...)
    dataset.report_stats(...)
end

function accept.report_counter(...)
    dataset.report_counter(...)
end
