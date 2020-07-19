
local util = require('common.util')

local tests = {}

function tests.log1()
    util.log('test1')
end

function tests.log2()
    util.log('test2')
end

local fweight = {
    log1 = 1,
    log2 = 2
}

util.run(tests, fweight, 2, 2)

-- log will show in web dev console