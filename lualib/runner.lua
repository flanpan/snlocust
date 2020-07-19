local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local websocket = require "http.websocket"
local urllib = require "http.url"
local json = require "dkjson"
local dataset = require "dataset"
local lfs = require "lfs"
local codecache = require "skynet.codecache"
local snax = require "skynet.snax"
require "skynet.manager"

local runner = {}
local agents = {}
local agent_count = 0
local ws_socks = {}
local route
local wsport

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
        if not route then route = require "route" end
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

function runner.broadcast(type, body)
    local msg = json.encode {type = type, body = body}
    for _, sock in pairs(ws_socks) do 
        websocket.write(sock, msg) 
    end
end

function runner.agent_count() return agent_count end

function runner.wsport() return wsport end

function runner.scripts()
    local scripts = {}
    for file in lfs.dir('script') do
        if string.sub(file, -4) == '.lua' then
            table.insert(scripts,file)
        end
    end
    return scripts
end

function runner.stop_agent(cb)
    for id, agent in pairs(agents) do
        snax.kill(agent)
        skynet.error('agent:', id, 'exit.')
    end
    agents = {}
    agent_count = 0
    if cb then cb() end
end

function runner.run_agent(id_start, id_count, per_sec, script, cb)
    runner.stop_agent()
    codecache.clear()
    script = string.sub(script,1,-5) -- cut .lua
    for id = id_start, id_count do
        local timeout = math.abs((id-1) // per_sec)
        agents[id] = snax.newservice('agent', id, timeout, script)
        agent_count = agent_count + 1
    end
    if cb then cb() end
end

function runner.start(port, _wsport)
    local id = socket.listen("0.0.0.0", port)
	skynet.error("Listen web port", port)
    socket.start(id , function(sock, addr) do_http_request(sock, addr) end)
    
    wsport = _wsport
    id = socket.listen("0.0.0.0", wsport)
    socket.start(id , function(sock, addr) 
        local handle = {}
        function handle.connect(sock) ws_socks[sock] = sock end
        function handle.close(sock, code, reason) ws_socks[sock] = nil end
        function handle.error(sock) ws_socks[sock] = nil end
        local ok, err = websocket.accept(sock, handle, 'ws', addr)
        if not ok then skynet.error(err) end
    end)
end

return runner