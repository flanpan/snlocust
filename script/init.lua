local skynet = require "skynet"
local uid, script = ...
skynet.error('agent:', uid, 'login ok.')
require(script)