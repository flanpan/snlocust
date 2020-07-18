local skynet = require "skynet"
uid, script = ...
skynet.error('agent:', uid, 'login ok.')
require(script)