local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local template = require "resty.template"
local json = require "dkjson"
local dataset = require "dataset"
local lfs = require "lfs"
local codecache = require "skynet.codecache"
require "skynet.manager"

local HEADER_JSON = {['content-type'] = 'application/json;charset=utf-8'}
local STATE = { READY = 'ready', HATCHING = 'hatching', RUNNING = 'running', STOPPING = 'stopping', STOPPED = 'stopped'}
local api = {}
local agents = {}
local agent_count = 0
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
    if not code then return socket.close(sock) end
    if code ~= 200 then
        http_response(sock, write, code)
    else
        local path, query = urllib.parse(url)
        if path == '/index.html' then path = '/' end
        local f = route[path]
        if f then 
            http_response(sock, write, f(urllib.parse_query(body))) 
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
    socket.close(sock)
end

local script = ''
local first_id = 1
local num_users = 1
local hatch_rate = 1
----------- process route -------------
route['/'] = function()
    local options = {
        state = dataset.state(),
        first_id = first_id,
        user_count = agent_count,
        version = 1,
        script = script,
        num_users = num_users,
        hatch_rate = hatch_rate,
        scripts = api.scripts()
    }
    local html = template.compile('static/index.html')(options)
    return 200, html
end

route['/swarm'] = function(body)
    if body.script then script = body.script end
    if body.first_id then first_id = (tonumber(body.first_id) or 1) // 1 end
    if body.user_count then num_users = (tonumber(body.user_count) or 1) // 1 end
    if body.hatch_rate then hatch_rate = (tonumber(body.hatch_rate) or 1) // 1 end
    skynet.fork(function()
        api.start(first_id, num_users, hatch_rate, script, function()
            dataset.state(STATE.RUNNING)
        end)
    end)
    dataset.state(STATE.HATCHING)
    local res = json.encode({success = true, script = script})
    return 200, res, HEADER_JSON
end

route['/stop'] = function()
    skynet.fork(function()
        api.stop(function() dataset.state(STATE.STOPPED) end)
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
function api.scripts()
    local scripts = {}
    for file in lfs.dir('script') do
        if string.sub(file, -4) == '.lua' and file ~= 'init.lua' then
            table.insert(scripts,file)
        end
    end
    return scripts
end


function api.stop(cb)
    for id, addr in pairs(agents) do
        skynet.kill(addr)
        skynet.error('agent:', id, 'exit.')
    end
    agents = {}
    agent_count = 0
    if cb then cb() end
end

function api.start(id_start, id_count, per_sec, script, cb)
    api.stop()
    codecache.clear()
    script = string.sub(script,1,-5) -- cut .lua
    for id = id_start, id_count do
        local timeout = math.abs((id-1) // per_sec)
        agents[id] = skynet.newservice('agent', id, timeout, script)
        agent_count = agent_count + 1
    end
    if cb then cb() end
end

function api.start_http(port)
    dataset.state(STATE.READY)
    local id = socket.listen("0.0.0.0", port)
	skynet.error("Listen web port", port)
    socket.start(id , function(sock, addr) do_http_request(sock, addr) end)
end

return api