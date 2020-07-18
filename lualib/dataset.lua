local dataset = {}
local stats = {}
local counter = {}

local stats_last = {
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

local report = {
    state = nil,
    user_count = 1,
    is_distributed = false,
    errors = {},
    counter = {},
    fail_ratio = 0,
    total_rps = 0,
    current_response_time_percentile_50 = nil,
    current_response_time_percentile_95 = nil,
    stats = { [1] = stats_last }
}

function dataset.report()
    return report
end

function dataset.state(state)
    if state then report.state = state end
    return report.state
end

function dataset.incr(name)
    local val = counter[name]
    if not val then 
        counter[name] = 0
        val = 0
    end
    val = val + 1
    counter[name] = val
    return val
end

function dataset.decr(name)
    local val = counter[name]
    if not val then
        counter[name] = 0
        val = 0
    end
    val = val - 1
    counter[name] = val
    return val
end

function dataset.add_sample(type, name, time)
end


return dataset