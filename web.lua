local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local websocket = require "http.websocket"
local urllib = require "http.url"
local table = table
local string = string

local mode, protocol = ...
protocol = protocol or "http"

local function response(id, write, ...)
	local ok, err = httpd.write_response(write, ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		skynet.error(string.format("fd = %d, %s", id, err))
	end
end


local SSLCTX_SERVER = nil
local function gen_interface(protocol, fd)
	if protocol == "http" then
		return {
			init = nil,
			close = nil,
			read = sockethelper.readfunc(fd),
			write = sockethelper.writefunc(fd),
		}
	elseif protocol == "https" then
		local tls = require "http.tlshelper"
		if not SSLCTX_SERVER then
			SSLCTX_SERVER = tls.newctx()
			-- gen cert and key
			-- openssl req -x509 -newkey rsa:2048 -days 3650 -nodes -keyout server-key.pem -out server-cert.pem
			local certfile = skynet.getenv("certfile") or "./server-cert.pem"
			local keyfile = skynet.getenv("keyfile") or "./server-key.pem"
			print(certfile, keyfile)
			SSLCTX_SERVER:set_cert(certfile, keyfile)
		end
		local tls_ctx = tls.newtls("server", SSLCTX_SERVER)
		return {
			init = tls.init_responsefunc(fd, tls_ctx),
			close = tls.closefunc(tls_ctx),
			read = tls.readfunc(fd, tls_ctx),
			write = tls.writefunc(fd, tls_ctx),
		}
	else
		error(string.format("Invalid protocol: %s", protocol))
	end
end

local function do_request(id, addr)
    socket.start(id)
    local interface = gen_interface(protocol, id)
    if interface.init then
        interface.init()
    end
    -- limit request body size to 8192 (you can pass nil to unlimit)
    local code, url, method, header, body = httpd.read_request(interface.read, 8192)
    if code then
        if code ~= 200 then
            response(id, interface.write, code)
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
            response(id, interface.write, code, data)
        end
    else
        if url == sockethelper.socket_error then
            skynet.error("socket closed")
        else
            skynet.error(url)
        end
    end
    socket.close(id)
    if interface.close then
        interface.close()
    end
end

skynet.start(function()
	local protocol = "http"
	local balance = 1
	local id = socket.listen("0.0.0.0", 8001)
	skynet.error(string.format("Listen web port 8001 protocol:%s", protocol))
    socket.start(id , function(id, addr) 
        do_request(id, addr)
    end)

    id = socket.listen("0.0.0.0", 8002)
    socket.start(id , function(id, addr) 
        local handle = {}
        function handle.message(id, msg, msg_type)
            --print('aaaaaaa',id, msg, msg_type)
        end
        local ok, err = websocket.accept(id, handle, 'ws', addr)
        if not ok then skyent.error(err) end
    end)
end)
