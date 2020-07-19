local template = require "resty.template"
local runner = require "runner"
local skynet = require "skynet"
local json = require "dkjson"
local dataset = require "dataset"

local HEADER_JSON = {['content-type'] = 'application/json;charset=utf-8'}
local STATE = { READY = 'ready', HATCHING = 'hatching', RUNNING = 'running', STOPPING = 'stopping', STOPPED = 'stopped'}
local route = {}
local script = ''
local first_id = 1
local num_users = 1
local hatch_rate = 1
local state = STATE.READY

route['/'] = function()
    local options = {
        state = state,
        first_id = first_id,
        user_count = runner.agent_count(),
        version = 1,
        script = script,
        num_users = num_users,
        hatch_rate = hatch_rate,
        wsport = runner.wsport(),
        scripts = runner.scripts()
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
        runner.run_agent(first_id, num_users, hatch_rate, script, function()
            state = STATE.RUNNING
        end)
    end)
    state = STATE.HATCHING
    local res = json.encode({success = true, script = script})
    return 200, res, HEADER_JSON
end

route['/stop'] = function()
    skynet.fork(function()
        runner.stop_agent(function() state = STATE.STOPPED end)
    end)
    state = STATE.STOPPING
    return 200
end

route['/stats/reset'] = function()
    dataset.reset()
    return 200
end

route['/stats/requests/csv'] = function()

    return 200
end

route['/stats/failures/csv'] = function()
    return 200
end

route['/stats/requests'] = function()
    local report = dataset.report()
    report.state = state
    report.user_count = runner.agent_count()
    return 200, json.encode(report), HEADER_JSON
end

route['/exceptions'] = function()
    local exceptions = {}
    return 200, json.encode({exceptions = exceptions}), HEADER_JSON
end

route['/exceptions/csv'] = function()
    return 200
end

return route