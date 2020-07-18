local skynet = require "skynet"
local websocket = require "http.websocket"
local json = require "dkjson"
local socket = require "skynet.socket"

local api = {}
local ws_socks = {}

local function send(sock, type, body)
    websocket.write(sock, json.encode {type = type, body = body})
end

local function broadcast(type, body)
    local msg = json.encode {type = type, body = body}
    for _, sock in pairs(ws_socks) do 
        websocket.write(sock, msg) 
    end
end
local function process_ws_msg(sock, msg)
    local type = msg.type
    local body = msg.body
    if type == 'start' then
        stats.start_time = skynet.now()
        cmds.start(body.id_start, body.id_count, body.per_sec, body.script)
    elseif type == 'stop' then
        stats.start_time = nil
        broadcast('stats', stats)
        cmds.stop()
    end
end

function api.start_ws(port)
    local id = socket.listen("0.0.0.0", port)
    socket.start(id , function(sock, addr) 
        local handle = {}
        function handle.connect(sock) ws_socks[sock] = sock end
        function handle.handshake(sock, header, url) send(sock, 'scripts', scripts()) end
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

api.broadcast = broadcast

return api