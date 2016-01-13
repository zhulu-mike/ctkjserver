-------------------------------------------------------------------------
--DB SERVER

-------------------------------------------------------------------------

local skynet = require "skynet"
local cluster = require "cluster"

CMD = {}
--set the metatable of CMD and set the  metamethod of CMD
setmetatable(CMD,{__index = _G})

require "redisfields"
require "sqlmaker"
require "sqlfunctions"
require "rediscore"
require "redisfunctions"
require "skynet.manager"	-- import skynet.register

local running = true
local serverstart = false
--与redis池服务进行通信，默认设置uid为0
function rcmd(cmd,...)
	return skynet.call(redispool, "lua", cmd,0,...)
end
--与redis池服务进行通信，设置uid
function urcmd(uid,cmd,...)
	if not uid then
		uid = 0
	end

	return skynet.call(redispool, "lua", cmd,uid,...)
end

require "maincmd"
require "rank"
--返回当前服务是否已经开启
--@return bool
function CMD.startdb()
	return serverstart
end

function returnwarp(r,...)
	if r ~= NONE then
		skynet.ret(skynet.pack(r,...))
	end
end
--主循环，可能是每隔多少时间保存一次玩家数据到数据库
local function mainupdate(isnewday)
	datapool.saveplayertosql()

	if isnewday then
		datapool.onnewday()
	end
end

skynet.start(function()
	local serverid = math.tointeger(os.getenv("ID"))

	math.randomseed(os.time())
	skynet.dispatch("lua", function(session, source, cmd,...)
		local f = assert(CMD[cmd])
		returnwarp(f(...))
	end)
	--注册当前服务的标识符为db
	skynet.register(".db")
	--在集群上打开当前节点db
	cluster.open("db")

	if DEBUG then
		local console = skynet.newservice("console")
	end
	
	skynet.newservice("debug_console",40000 + serverid * 100  + 1)
	--创建一个dbpool服务
	dbpool = skynet.newservice("dbpool")
	load_dbschemas()
	--创建一个全局共享独一无二的redis池服务
	redispool = skynet.uniqueservice("redispool")
	--发送redis池初始化消息
	skynet.call(redispool, "lua", "start")

	local _datapool = require "datapool"
	local version = rcmd("get","dbversion")
	
	if not version then
		version = 0
	end

	if version == 0 then
		_datapool.initfromdb()
	end

	_datapool.checksaveroles()

	local r = sqlgetmaxroleid()

	if not r or r == 0 then
		r = 1 * 1000000
	end

	redis_set("maxplayerid",r)

	local oldday = datetime(os.time())
	local newday = false
	--创建一个子进程定时器，每5秒跑一次，新的一天调用mainupdate接口。
	skynet.fork(function()
		while running do
			local curday = datetime(os.time())

			if curday > oldday then
				newday = true
			end

			pcall(mainupdate,newday)
			oldday = curday
			newday=false
			skynet.sleep(500)
		end
	end)

	trace("serverstart")
	serverstart = true
end)