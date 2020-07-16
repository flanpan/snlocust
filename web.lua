local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local websocket = require "http.websocket"
local urllib = require "http.url"
local json = require "dkjson"
local lfs = require "lfs"
local codecache = require "skynet.codecache"
require "skynet.manager"

local REPORT_STATS_INTERVAL = 100 --1s
local ws_socks = {}
local cmds = {}
local agents = {}
local stats = {
    start_time = nil,
    user_count = 0,
    msgs = {}-- max, min, sum, count
}
local update_stats = false

local function ws_send(sock, type, body)
    websocket.write(sock, json.encode {type = type, body = body})
end

local function ws_broadcast(type, body)
    local msg = json.encode {type = type, body = body}
    for _, sock in pairs(ws_socks) do 
        websocket.write(sock, msg) 
    end
end

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
    dispatch = function(_, address, msg)
        msg = string.format(":%08x: %s", address, msg)
        print(msg)
        ws_broadcast('log', msg)
	end
}

local function scripts()
    local l = {}
    for file in lfs.dir('script') do
        if string.sub(file, -4) == '.lua' then
            table.insert(l,file)
        end
    end
    return l
end

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
            if path == '/' then path = '/index.html' end
            path = 'static' .. path
            local data = path
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
    else
        if url == sockethelper.socket_error then
            skynet.error("socket closed")
        else
            skynet.error(url)
        end
    end
    socket.close(sock)
end

local function start_http(port)
    local id = socket.listen("0.0.0.0", port)
	skynet.error("Listen web port", port)
    socket.start(id , function(sock, addr) do_http_request(sock, addr) end)
end

local function process_ws_msg(sock, msg)
    local type = msg.type
    local body = msg.body
    if type == 'start' then
        stats.start_time = skynet.now()
        cmds.start(body.id_start, body.id_count, body.per_sec, body.script)
    elseif type == 'stop' then
        stats.start_time = nil
        ws_broadcast('stats', stats)
        cmds.stop()
    end
end

local function start_ws(port)
    local id = socket.listen("0.0.0.0", port)
    socket.start(id , function(sock, addr) 
        local handle = {}
        function handle.connect(sock) ws_socks[sock] = sock end
        function handle.handshake(sock, header, url) ws_send(sock, 'scripts', scripts()) end
        function handle.close(sock, code, reason) ws_socks[sock] = nil end
        function handle.error(sock) ws_socks[sock] = nil end
        function handle.message(sock, msg, msg_type)
            msg = json.decode(msg)
            if not msg then return end
            process_ws_msg(sock, msg)
        end
        local ok, err = websocket.accept(sock, handle, 'ws', addr)
        if not ok then skynet.error(err) end
    end)
end

local function report_stats()
    if update_stats then 
        ws_broadcast('stats', stats)
        update_stats = false
    end
    skynet.timeout(REPORT_STATS_INTERVAL, report_stats)
end

function cmds.stats(data)
    if not stats.start_time then return end
    update_stats = true
    if data.user_count then stats.user_count = data.user_count end
    local msgs = data.msgs
    if not msgs then return end
    for k,v in pairs(msgs) do
        if not stats[k] then stats[k] = v end
        local obj = stats[k]
        if v.max > obj.max then obj.max = v.max end
        if v.min < obj.min then obj.min = v.min end
        obj.count = obj.count + v.count
        obj.sum = obj.sum + v.sum
    end
end

function cmds.start(id_start, id_count, per_sec, script)
    cmds.stop()
    codecache.clear()
    for id = id_start, id_count do
        agents[id] = skynet.newservice('agent', id, script)
    end
end

function cmds.stop()
    for id, addr in pairs(agents) do
        skynet.kill(addr)
        skynet.error('agent:', id, 'exit.')
    end
    agents = {}
end

skynet.start(function()
    start_http(8001)
    start_ws(8002)
    skynet.timeout(REPORT_STATS_INTERVAL, report_stats)
    --[[
    skynet.dispatch("lua", function(session, address, cmd, ...)
        cmd = cmd:lower()
		local f = cmds[cmd]
        if not f then error(string.format("Unknown command %s", tostring(cmd))) end
	    skynet.ret(skynet.pack(f(...)))
    end)
    --]]
end)
