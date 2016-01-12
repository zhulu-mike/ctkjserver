local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"

require "skynet.manager"	-- import skynet.register

local running = true
local CMD = {}
local SOCKET = {}
local gate
local agents = {}
local agentpool = {}
local agentpoolsize = 0

local slaves = {}
local balance = 1
local instance = 8
local agentid  = 0

local incomingconnections = {}
--收到gate的链接通知后，进入到这里
--@param fd 客户端链接的句柄
--@param addr 客户端链接的地址
function SOCKET.open(fd, addr)
	if not running then
		skynet.call(gate, "lua", "kick", fd)
		return
	end

	dprint("New client from : " .. addr)

	local s = slaves[balance]
	balance = balance + 1

	if balance > #slaves then
		balance = 1
	end

	incomingconnections[fd] = {interval = 3000}
	local ok, secret = skynet.call(s, "lua",  fd, addr)
	incomingconnections[fd]  = nil

	if ok then
		socket.write(fd, "200\n")

		--let agent do remain works
		local poolidx = (agentid % agentpoolsize) + 1
		agents[fd] = agentpool[poolidx]
		agentid = agentid + 1
		--新的用户使用一个新agent，并调用start方法。
		skynet.call(agents[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() ,ip = addr,id = agentid})
	else
		skynet.call(gate, "lua", "kick", fd)
	end
end

local function close_agent(fd)
	local a = agents[fd]
	agents[fd] = nil

	if a then
		skynet.call(a, "lua", "disconnect",fd)
		skynet.call(gate, "lua", "kick", fd)
	end
end

function SOCKET.close(fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	close_agent(fd)
end

function SOCKET.data(fd, msg)
end

function CMD.start(conf)
	skynet.call(gate, "lua", "open" , conf)
end

function CMD.close(fd)
	close_agent(fd)
end

function CMD.onclose()
	running = false
	skynet.call(gate,"lua","close")
end

function CMD.broadcast(msg,data)
	for _,agent in pairs(agents) do
		skynet.send(agent,"lua","broadcast",msg,data)
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

	skynet.register ".watchdog"

	--watchdog verify service
	for i=1,instance do
		table.insert(slaves, skynet.newservice("clientverify"))
	end

	--precreate agents,预创建agentcachecount个代理agent
	local  precreatecount = tonumber(skynet.getenv("agentcachecount"))

	for i = 1,precreatecount do
		table.insert(agentpool, skynet.newservice("agent"))
	end

	agentpoolsize = precreatecount

	--connect timeout list，创建一个子进场定时器，处理每日凌晨事务
	skynet.fork(function()
		local oldday = datetime(os.time())

		while running do
			--把一些错误的链接清除掉
			for fd,fdinfo in pairs(incomingconnections) do
				if fdinfo.interval > 0 then
					fdinfo.interval = fdinfo.interval  - 500

					if fdinfo.interval <= 0 then
						--kick out client
						pcall(skynet.call,gate,"lua", "kick", fd)
					end
				end
			end

			--check new day，凌晨初始化玩家数据,暂时用不到
			-- local curday = datetime(os.time())

			-- if curday > oldday then
			-- 	for fd,agent in pairs(agents) do
			-- 		pcall(skynet.send,agent,"lua","newday",curday)
			-- 	end
			-- end

			-- oldday = curday
			skynet.sleep(500)
		end
	end)

	world = skynet.localname(".world")
	gate = skynet.uniqueservice("gate")
end)
