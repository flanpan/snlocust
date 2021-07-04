--[[
* Hint: start the skynet example server first
cd 3rd/skynet
./skynet examples/config

* Hint: 3rd/skynet/examples/main.lua - default watchdog max_client is 64

--]]
package.path = package.path .. "3rd/skynet/examples/?.lua;"
local proto = require "proto"
local sproto = require "sproto"
local util = require "common.util"
local monitor = require "monitor"
local skynet = require "skynet"
local socket = require "skynet.socket"
local sc = require "skynet.socketchannel"

local host, port = util.address()
local sp = sproto.new(proto.s2c):host "package"
local pack = sp:attach(sproto.new(proto.c2s))
local session = 0
local channel
local read_response

read_response = function(sock)
    local sz = socket.header(sock:read(2))
    local data = sock:read(sz)
    local type, session, msg = sp:dispatch(data)
    if type == 'RESPONSE' then
        monitor.endtime(session, sz)
        return session, true, msg
    else 
        --server notification
        local name = session
        monitor.incr(name)
        return read_response(sock)
    end
end

channel = sc.channel({host = host, port = port, nodelay = false, response = read_response})

local function request(type, msg, resp)
	session = session + 1
	local str = pack(type, msg or {}, session)
    local package = string.pack(">s2", str)
    monitor.time('test', type, session)
    return channel:request(package, session)
end

local t = {
    set = function() request("set", { what = "hello", value = "world" }) end,
    get = function() 
        local res = request("get", { what = "hello" })
        -- assert(res.result == 'world')
    end
}

local fweight = {
    set = 1,
    get = 2,
}

function main()
    channel:connect(false)
    request('handshake')
    util.run(t,fweight,2,2)
end