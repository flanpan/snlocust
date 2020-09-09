local console = require "console"

function main()
    -- open the chrome devtools to show result
    console.time('test')
    console.log('aaa', {a=1,b={b=2},c='ccc'}, 111)
    console.table {{id=1,name='aaa'},{id=2,name='bbb'}}
    console.timeEnd('test')
end