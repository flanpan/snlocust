local skynet = require "skynet"
local snax = require "skynet.snax"

local REPORT_DELAY = 200
local count = 0
local hold = false
local name
local web

local function report()
    if hold then return end
    hold = true
    skynet.timeout(REPORT_DELAY, function()
        web.post.report_counter(name, count)
        hold = false
    end)
end

function init(_name)
    name = _name
    web = snax.queryservice "web"
end

function response.reset()
    count = 0
    hold = false
end

function accept.incr(num)
    count = count + num
    report()
end

function accept.decr(num)
    count = count - num
    report()
end

function accept.set(num)
    count = num
    report()
end