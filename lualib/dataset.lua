local skynet = require "skynet"
local snax = require "skynet.snax"

local UPDATE_INTERVAL = 200
local dataset = {}

local stats = {}
local counter = {}
local last_update_time = 0
local counter_addr = {}
local stats_addr = {}

local function new_last_stat()
    return {
        avg_content_length = 0,
        avg_response_time = 0,
        current_fail_per_sec = 0,
        current_rps = 0,
        max_response_time = 0,
        median_response_time = 0,
        method = nil,
        min_response_time = 0,
        name = "Aggregated",
        ninetieth_response_time = 0,
        num_failures = 0,
        num_requests = 0,
        safe_name = "Aggregated",
    }
end

local function new_report()
    return {
        is_distributed = false,
        errors = {},
        counter = {},
        fail_ratio = 0,
        total_rps = 0,
        current_response_time_percentile_50 = nil,
        current_response_time_percentile_95 = nil,
        stats = { [1] = new_last_stat() }
    }
end

local report = new_report()

function dataset.reset()
    for _, s in pairs(counter_addr) do
        snax.kill(s)
    end
    for _, obj in pairs(stats_addr) do
        for _, s in pairs(obj) do
            snax.kill(s)
        end
    end
    stats = {}
    counter = {}
    last_update_time = 0
    counter_addr = {}
    stats_addr = {}
    report = new_report()
end

function dataset.report()
    local now = skynet.now()
    if now - last_update_time < UPDATE_INTERVAL then
        return report
    end
    last_update_time = now
    report.current_response_time_percentile_50 = 0
    report.current_response_time_percentile_95 = 0
    report.fail_ratio = 0
    report.total_rps = 0
    local newstats = {}
    local last = new_last_stat()
    for method, obj in pairs(stats) do
        for name, stat in pairs(obj) do
            last.avg_content_length = last.avg_content_length + stat.avg_content_length
            last.avg_response_time = last.avg_response_time + stat.avg_response_time
            last.current_fail_per_sec = last.current_fail_per_sec + stat.current_fail_per_sec
            last.current_rps = last.current_rps + stat.current_rps
            last.median_response_time = last.median_response_time + stat.median_response_time
            last.ninetieth_response_time = last.ninetieth_response_time + stat.ninetieth_response_time
            last.num_requests = last.num_requests + stat.num_requests
            last.num_failures = last.num_failures + stat.num_failures
            if last.min_response_time == 0 then last.min_response_time = stat.min_response_time end
            if last.min_response_time > stat.min_response_time then last.min_response_time = stat.min_response_time end
            if last.max_response_time < stat.max_response_time then last.max_response_time = stat.max_response_time end
            table.insert(newstats, stat)
        end 
    end
    local size = #newstats
    if size > 0 then
        last.avg_content_length = last.avg_content_length / size
        last.avg_response_time = last.avg_response_time / size
        last.median_response_time = last.median_response_time / size
        last.ninetieth_response_time = last.ninetieth_response_time / size
        report.total_rps = last.current_rps
        report.current_response_time_percentile_50 = last.median_response_time
        report.current_response_time_percentile_95 = last.ninetieth_response_time
        report.fail_ratio = last.num_failures / (last.num_failures + last.num_requests)
    end
    table.insert(newstats, last)
    report.stats = newstats
    return report
end

function dataset.report_counter(name, count)
    report.counter[name] = count
end

function dataset.report_stats(data)
    data.safe_name = data.name
    local method = data.method
    local name = data.name
    if not stats[method] then stats[method] = {} end
    stats[method][name] = data
end

function dataset.counter_service(name)
    local s = counter_addr[name]
    if s then return s.handle end
    local s = snax.newservice('counter', name)
    counter_addr[name] = s
    return s.handle
end

function dataset.stats_service(method, name)
    if not stats_addr[method] then stats_addr[method] = {} end
    local s = stats_addr[method][name]
    if s then return s.handle end
    s = snax.newservice('stats',method, name)
    stats_addr[method][name] = s
    return s.handle
end

return dataset