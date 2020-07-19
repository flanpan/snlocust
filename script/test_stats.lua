local util = require('common.util')

local tests = {}

function tests.test1()
    util.log('test1')
end

function tests.test2()
    util.log('test2')
end

local fweight = {
    test1 = 1,
    test2 = 2
}

util.run(tests, fweight, 2, 2)