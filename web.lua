local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local websocket = require "http.websocket"
local urllib = require "http.url"
local json = require "dkjson"

local REPORT_STATS_INTERVAL = 100 --1s
local ws_socks = {}
local cmds = {}
local stats = {
    start_time = 0,
    stop_time = 0,
    user_count = 0,
    msgs = {}-- max, min, sum, count
}
local update_stats = false

local function ws_send(sock, type, msg)
    websocket.write(sock, json.encode {type = type, msg = msg})
end

local function ws_broadcast(type, msg)
    msg = json.encode {type = type, msg = msg}
    for sock, _ in pairs(ws_socks) do websocket.write(sock, msg) end
end

local function scripts()
    local l = {}
    os.execute('ls script')
    return l
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
            local header = {}
            http_response(sock, write, code, data)
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
    if msg.type == 'scripts' then 
        ws_send(sock, {type='scripts', msg = scripts()})
    elseif msg.type == 'reload_scripts' then
        ws_send(sock, {type='scripts', msg = scripts()})
    end
end

local function start_ws(port)
    local id = socket.listen("0.0.0.0", port)
    socket.start(id , function(sock, addr) 
        local handle = {}
        function handle.connect(sock) ws_socks[sock] = sock end
        function handle.close(sock, code, reason) ws_socks[sock] = nil end
        function handle.error(sock) end
        function handle.message(sock, msg, msg_type)
            msg = json.decode(msg)
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
    if stats.end_time or not stats.start_time then return end
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

skynet.start(function()
    start_http(8001)
    start_ws(8002)
    skynet.timeout(REPORT_STATS_INTERVAL, report_stats)
end)
