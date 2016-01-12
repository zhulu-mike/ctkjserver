local skynet = require "skynet"
local cluster = require "cluster"

require "skynet.manager"	-- import skynet.register

local CMD = {}
local running = true

--关服处理
function CMD.onclose()
	print("closeserver ...")

	skynet.call(".watchdog","lua","onclose")
	running = false
end

--广播事件
function CMD.broadcast(msg,data)
	skynet.call(".watchdog","lua","broadcast",msg,data)
end

skynet.start(function()
	local serverid = math.tointeger(os.getenv("ID"))
	local  gateid = skynet.getenv("gateid")
	
	if DEBUG then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",40000 + serverid * 100  + 6 + gateid)

	--cluster connection，创建一个db的代理
	skynet.name(".db",cluster.proxy("db",".db"))
	--创建一个world的代理
	local world = cluster.proxy("world",".world")
	skynet.name(".world",world)
	cluster.open("gate" .. gateid)

	skynet.dispatch("lua", function(session, source, cmd,...)
		local f = assert(CMD[cmd])
		skynet.ret(skynet.pack(f(...)))
	end)
	
	local gateport   = 10000 + (serverid - 1) * 100 + gateid
	local maxclient	= skynet.getenv("maxconnection")
	
	--注册当前gate
	skynet.fork(function()
		while running do
			local ok,r = pcall(cluster.call,"world",".world","registergate",gateid)

			if ok and r then
				--start server now，通知网关底层，绑定端口号。
				local watchdog = skynet.newservice("watchdog")
				--该消息的后续处理在snax的gateserver.lua里面。
				skynet.call(watchdog, "lua", "start", 
				{
					port = gateport,
					maxclient = tonumber(maxclient),
					nodelay = true,
				})

				print("Watchdog listen on ", gateport)
				break
			end

			skynet.sleep(100)
		end
	end)

	skynet.register(".gate")
end)
