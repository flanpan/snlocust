/** @noSelfInFile */
/** skynet模块*/
declare module "skynet" {
    var PTYPE_TEXT: number
	var PTYPE_RESPONSE: number
	var PTYPE_MULTICAST: number
	var PTYPE_CLIENT: number
	var PTYPE_SYSTEM: number
	var PTYPE_HARBOR: number
	var PTYPE_SOCKET: number
	var PTYPE_ERROR: number
	var PTYPE_QUEUE: number	// used in deprecated mqueue, use skynet.queue instead
	var PTYPE_DEBUG: number
	var PTYPE_LUA: number
	var PTYPE_SNAX: number
	var PTYPE_TRACE: number	// use for debug trace
    function exit(): void
    function start(start_func: VoidFunction): void
    function call(...args: any[]): void
    function error(...args: any[]): void
    function newservice(name: String, ...args: any[]): number
    function uniqueservice(name: String, ...args: any[]): number
    function getenv(key: String): String
}