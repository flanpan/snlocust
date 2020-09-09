local skynet = require "skynet"
local snax = require "skynet.snax"

local CACHE_LASTEST_RES_TIME = 100
local REPORT_DELAY = 100
local web

local hold = false
local reqs = {}
local lastest_res_time = {}
local total_response_time = 0
local total_content_length = 0
local tmp_fail = 0
local tmp_reqs = 0
local data = {}

local function newdata()
    return {
        method = data.method,
        name = data.name,
        safe_name = data.safe_name,
        num_requests = 0,
        num_failures = 0,
        min_response_time = 0,
        max_response_time = 0,
        avg_response_time = 0,
        median_response_time = 0,
        ninetieth_response_time = 0,
        avg_content_length = 0,
        current_fail_per_sec = 0,
        current_rps = 0,
    }
end

local function reset()
    data = newdata()
    hold = false
    reqs = {}
    lastest_res_time = {}
    total_response_time = 0
    total_content_length = 0
    tmp_fail = 0
    tmp_reqs = 0
end

local function report()
    if hold then return end
    hold = true
    skynet.timeout(REPORT_DELAY, function()
        data.current_rps = tmp_reqs
        data.current_fail_per_sec = tmp_fail
        tmp_reqs = 0
        tmp_fail = 0
        local tmp = {}
        local size = #lastest_res_time
        for i = 1, size do table.insert(tmp,lastest_res_time[i]) end
        table.sort(tmp)
        local idx = math.ceil(size*0.5)
        data.median_response_time = tmp[idx] or 0
        idx = math.ceil(size*0.95)
        data.ninetieth_response_time = tmp[idx] or 0
        web.post.report_stats(data)
        hold = false
    end)
end

local function key(uid,id) return uid..'-'..id end

function init(_type, _name)
    reset()
    data.name = _name
    data.method = _type
    -- data.safe_name = _name
    web = snax.queryservice "web"
end

function response.reset()
    reset()
end

function accept.time(uid, id)
    reqs[key(uid,id)] = skynet.now()
end

function accept.endtime(uid, id, size, failed)
    local key = key(uid, id)
    local time = reqs[key]
    if not time then return skynet.error(data.method, data.name, uid, id, 'no request data.') end
    local delay = skynet.now() - time
    total_response_time = total_response_time + delay
    if data.min_response_time > delay then data.min_response_time = delay end
    if data.max_response_time < delay then data.max_response_time = delay end
    if failed then 
        data.num_failures = data.num_failures + 1
        tmp_fail = tmp_fail + 1
    else 
        data.num_requests = data.num_requests + 1
    end
    local total_res = data.num_failures + data.num_requests
    data.avg_response_time = total_response_time / total_res
    total_content_length = total_content_length + (size or 0)
    data.avg_content_length = total_content_length / total_res
    tmp_reqs = tmp_reqs + 1
    table.insert(lastest_res_time, delay)
    if #lastest_res_time > CACHE_LASTEST_RES_TIME then table.remove(lastest_res_time, 1) end
    report()
end
