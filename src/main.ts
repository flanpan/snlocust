import skynet = require('skynet')

skynet.start(()=>{
	skynet.error("Server start")
	if(!skynet.getenv("daemon")) {
		let console = skynet.newservice("console")
    }
	skynet.newservice("debug_console",8000)
    skynet.exit()
})
