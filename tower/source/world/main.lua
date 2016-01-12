local skynet = require "skynet"
local cluster = require "cluster"

CMD = {}
setmetatable(CMD,{__index = _G})

require "skynet.manager"	-- import skynet.register
require "json"
require "utils"
require "allacc"
require "allrole"
require "onlineuser"
require "onlineusermanager"
require "maincmd"
require "mail"

local running = true
local serverstart = false
gates= {}
local registergates = {}

function CMD.registergate(id)
	cluster.reload()
	
	gates[id] = cluster.proxy("gate" .. id,".gate")

	if serverstart then
		return true
	else
		table.insert(registergates,skynet.response())
		return NONE
	end
end

function returnwarp(r,...)
	if r ~= NONE then
		skynet.ret(skynet.pack(r,...))
	end
end

function broadcast(msg,data)
	for _,sgate in pairs(gates) do
		skynet.call(sgate,"lua","broadcast",msg,data)
	end
end

skynet.start(function()
	local serverid = math.tointeger(os.getenv("ID"))

	if DEBUG then
		local console = skynet.newservice("console")
	end
	
	skynet.newservice("debug_console",40000 + serverid * 100  + 5)

	cluster.open("world")
	db = cluster.proxy("db",".db")

	skynet.dispatch("lua", function(session, source, cmd,...)
		local f = assert(CMD[cmd])
		returnwarp(f(...))
	end)

	skynet.register(".world")
	print("wait for db to start")

	--等待DB启动完成
	while true do
		local ok,r = pcall(skynet.call,db,"lua","startdb")

		if ok and r then
			break
		else
			skynet.sleep(100)
		end
	end

	print("db is ok")
	worldid = skynet.getenv("worldid")
	
	skynet.fork(function()
		while running do
			-- usermanager.update(1)
			skynet.sleep(100)
		end
	end)
	
	--检测关服指令
	skynet.fork(function()
		while running do
			local r = os.remove("../close.cmd")

			if r then
				--通知gates关闭服务器
				for _,sgate in pairs(gates) do
					skynet.call(sgate,"lua","onclose")
				end

				--保存所有数据到DB
				usermanager.onclose()

				--通知DB关闭
				skynet.call(db,"lua","onclose")
			else
				skynet.sleep(100)
			end
		end
	end)

	--无尽模式排行
	-- local srank = skynet.newservice("rank")
	-- skynet.call(srank,"lua","start",db,RANK_ENDLESS,50)

	--其他排行榜
	-- for i = 2,12 do
		-- srank = skynet.newservice("rank")
		-- skynet.call(srank,"lua","start",db,i,50)
	-- end

	------------------------------------------------------------------------------------
	serverstart = true

	for _,rgate in ipairs(registergates) do
		rgate(true,true)
	end

	registergates = {}
	print("world server started")
end)
