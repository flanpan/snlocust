local template = require "resty.template"
local runner = require "runner"
local skynet = require "skynet"
local json = require "dkjson"
local dataset = require "dataset"

local SETTING_FILE = 'config/.setting.json'
local HEADER_JSON = {['content-type'] = 'application/json;charset=utf-8'}
local STATE = { READY = 'ready', HATCHING = 'hatching', RUNNING = 'running', STOPPING = 'stopping', STOPPED = 'stopped'}
local route = {}
local state = STATE.READY


local _config
local function config(cfg)
    if not cfg then -- get
        if _config then return _config end
        local f = io.open(SETTING_FILE, 'rb')
        if f then
            _config = json.decode(f:read('*a'))
            f:close()
        end
        _config = _config or {}
        _config.first_id = _config.first_id or 1
        _config.num_users = _config.num_users or 1
        _config.hatch_rate = _config.hatch_rate or 1
        _config.host = _config.host or '127.0.0.1:8888'
        _config.script = _config.script or ''
    else -- set
        _config = _config or {}
        for k, v in pairs(cfg) do
            _config[k] = v
        end
        local f = io.open(SETTING_FILE, 'wb')
        if f then
            f:write(json.encode(_config))
            f:close()
        end
    end
    return _config
end

route['/'] = function()
    local cfg = config()
    local scripts = {}
    local valid_script = false

    for file in lfs.dir('script') do
        if string.sub(file, -4) == '.lua' then
            table.insert(scripts,file)
            if not valid_script and cfg.script == file then 
                valid_script = true 
            end
        end
    end
    if not valid_script and #scripts > 0 then
        cfg.script = scripts[1]
    end

    local options = {
        state = state,
        first_id = cfg.first_id,
        user_count = runner.agent_count(),
        version = 1,
        num_users = cfg.num_users,
        hatch_rate = cfg.hatch_rate,
        host = cfg.host,
        wsport = runner.wsport(),
        scripts = scripts,
        script = cfg.script,
    }
    local html = template.compile('static/index.html')(options)
    return 200, html
end

route['/swarm'] = function(body)
    local cfg = config({
        script = body.script,
        host = body.host,
        first_id = tonumber(body.first_id or 1) // 1,
        num_users = tonumber(body.user_count or 1) // 1,
        hatch_rate = tonumber(body.hatch_rate or 1) // 1
    })
    skynet.fork(function()
        runner.run_agent(cfg.first_id, cfg.num_users, cfg.hatch_rate, 
        cfg.host, cfg.script, function()
            state = STATE.RUNNING
        end)
    end)
    state = STATE.HATCHING
    local res = json.encode({success = true, script = cfg.script})
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