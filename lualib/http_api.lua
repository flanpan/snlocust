local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local template = require "resty.template"
local json = require "dkjson"

local HEADER_JSON = {['content-type'] = 'application/json;charset=utf-8'}

local api = {}
local route = {}
local function http_response(id, write, ...)
	local ok, err = httpd.write_response(write, ...)
	if not ok then skynet.error(string.format("fd = %d, %s", id, err)) end
end

local function do_http_request(sock, addr)
    socket.start(sock)
    local read = sockethelper.readfunc(sock)
	local write = sockethelper.writefunc(sock)
    local code, url, method, header, body = httpd.read_request(read, 8192)
    if code then
        if code ~= 200 then
            http_response(sock, write, code)
        else
            local path, query = urllib.parse(url)
            if path == '/index.html' then path = '/' end
            local f = route[path]
            if f then 
                http_response(sock, write, f()) 
            else
                local data
                path = '.' .. path
                local f = io.open(path, 'rb')
                if f then
                    data = f:read('*a')
                    f:close()
                else 
                    code = 404
                end
                local header
                if string.sub(path,-4) == '.css' then
                    header = {['Content-Type']='text/css;charset=utf-8'}
                end
                http_response(sock, write, code, data, header)
            end
        end
    else
        if url == sockethelper.socket_error then
            skynet.error("socket closed")
        else
            skynet.error(url)
        end
    end
    socket.close(sock)
end

function api.start_http(port)
    local id = socket.listen("0.0.0.0", port)
	skynet.error("Listen web port", port)
    socket.start(id , function(sock, addr) do_http_request(sock, addr) end)
end

----------- process route -------------

route['/'] = function()
    local options = {
        state = 'ready', --["ready", "hatching", "running", "cleanup", "stopping", "stopped", "missing"]
        is_distributed = false,
        user_count = 1,
        version = 1,
        host = 'localhost',
        override_host_warning = true,
        num_users = 1,
        hatch_rate = 1,
        step_users = 1,
        step_time = 1,
        worker_count = 0,
        is_step_load = false
    }
    local html = template.compile('static/index.html')(options)
    return 200, html
end

route['/swarm'] = function()

    return 200
end

route['/stop'] = function()

    return 200
end

route['/stats/reset'] = function()
    return 200
end

route['/stats/requests/csv'] = function()

    return 200
end

route['/stats/failures/csv'] = function()
    return 200
end

route['/stats/requests'] = function()
    local report = {
        state = 'ready',
        user_count = 1,
        is_distributed = false,
        stats = {},
        errors = {},
        fail_ratio = 0,
        total_rps = 0,
        current_response_time_percentile_50 = nil,
        current_response_time_percentile_95 = nil,
    }
    table.insert(report.stats, {
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
        safe_name = "Aggregated"
    })
    return 200, json.encode(report), HEADER_JSON
end

route['/exceptions'] = function()
    local exceptions = {}
    return 200, json.encode({exceptions = exceptions}), HEADER_JSON
end

route['/exceptions/csv'] = function()
    return 200
end

return api