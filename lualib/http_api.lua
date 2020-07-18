local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local template = require "resty.template"
local json = require "dkjson"
local dataset = require "dataset"

local HEADER_JSON = {['content-type'] = 'application/json;charset=utf-8'}
local STATE = { READY = 'ready', HATCHING = 'hatching', RUNNING = 'running', STOPPING = 'stopping', STOPPED = 'stopped'}
local cmds
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

----------- process route -------------
route['/'] = function()
    local options = {
        state = dataset.state(),
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
        is_step_load = false,
        scripts = cmds.scripts()
    }
    local html = template.compile('static/index.html')(options)
    return 200, html
end

route['/swarm'] = function()
    skynet.fork(function()
        cmds.start(function()
            dataset.state(STATE.RUNNING)
        end)
    end)
    dataset.state(STATE.HATCHING)
    return 200
end

route['/stop'] = function()
    skynet.fork(function()
        cmds.stop(function()
            dataset.state(STATE.STOPPED)
        end)
    end)
    dataset.state(STATE.STOPPING)
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
    return 200, json.encode(dataset.report()), HEADER_JSON
end

route['/exceptions'] = function()
    local exceptions = {}
    return 200, json.encode({exceptions = exceptions}), HEADER_JSON
end

route['/exceptions/csv'] = function()
    return 200
end

-------api-------
local api = {}

function api.start_http(_cmds, port)
    cmds = _cmds
    dataset.state(STATE.READY)
    local id = socket.listen("0.0.0.0", port)
	skynet.error("Listen web port", port)
    socket.start(id , function(sock, addr) do_http_request(sock, addr) end)
end

return api