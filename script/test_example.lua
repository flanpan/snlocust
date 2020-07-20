--[[
* Hint: start the skynet example server first
cd 3rd/skynet
./skynet examples/config
--]]

package.path = package.path .. '3rd/skynet/examples/?.lua'
local socket = require "client.socket"
local proto = require "proto"
local sproto = require "sproto"
local util = require "common.util"
local monitor = require "common.monitor"
local skynet = require "skynet"

local host = sproto.new(proto.s2c):host "package"
local request = host:attach(sproto.new(proto.c2s))

local fd = assert(socket.connect(util.address()))

local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	socket.send(fd, package)
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

local function recv_package(last)
	local result
	result, last = unpack_package(last)
	if result then
		return result, last
	end
	local r = socket.recv(fd)
	if not r then
		return nil, last
	end
	if r == "" then
		error "Server closed"
	end
	return unpack_package(last .. r)
end

local session = 0

local function send_request(name, args)
	session = session + 1
	local str = request(name, args, session)
    send_package(fd, str)
    monitor.time('test', name, session)
end

local last = ""

local function dispatch_package()
	while true do
		local v
		v, last = recv_package(last)
		if not v then
			break
        end
        local size = #v
        local type, session = host:dispatch(v)
        if type == 'RESPONSE' then
            monitor.endtime(session, size)
        else
            local name = session
            monitor.incr(name)
        end
	end
end

local t = {}

function t.set()
    send_request("set", { what = "hello", value = "world" })
end

function t.get()
    send_request("get", { what = "hello" })
end

function t.recv()
    dispatch_package()
end

skynet.timeout(0, function()
    send_request("handshake")
end)

local fweight = {
    set = 1,
    get = 2,
    recv = 10
}
util.run(t,fweight,0,1)
