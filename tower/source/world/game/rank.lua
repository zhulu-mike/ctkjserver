local skynet = require "skynet"

require "skynet.manager"	-- import skynet.register

local CMD  = {}
local running = true

local db
local rankid = 0
local rankcount = 100
local rankstarttime = 0

function checknewrank()
	--每周末凌晨4点重置
	local t = os.time()
	local tab = os.date("*t",t)
	tab.day = tab.day - tab.wday + 1
	tab.hour = 4
	tab.min = 0
	tab.sec = 0
	local t2 = os.time(tab)

	if rankstarttime > t then
		return true
	end

	if rankstarttime < t2 and t >= t2 then
		rankstarttime = t2
		return true
	else
		return false
	end
end

function CMD.start(pdb,id,count)
	db = pdb
	rankid = id
	rankcount = count
	rankstarttime = skynet.call(db,"lua","getranktime",id)
	loadranks()
	return true
end

function CMD.close()
	running = false
end

local updating = false

function loadranks()
	if updating then
		return
	end

	updating = true
	local ranks = skynet.call(db,"lua","rank_getrange",rankid,0,rankcount - 1)

	if not ranks then
		ranks = {}
	end

	skynet.send(world,"lua","updateranks",rankid,ranks)
	updating = false
end

function reward(roleid,order,score)
	if score <= 0 then
		return
	end
	
	skynet.send(world,"lua","notifymail",rankid,MAIL_TYPE_RANK_REWARD,roleid,"排名奖励",tostring(order),ONE_WEEK)
end

function newrank()
	local roles = skynet.call(db,"lua","rank_getrangeandscore",rankid,0,9)

	if roles then
		for _,rank in ipairs(roles) do
			reward(rank[1],rank[2],rank[3])
		end
	end

	skynet.call(db,"lua","rank_create",rankid)
end

function returnwarp(r,...)
	if r ~= nil then
		skynet.ret(skynet.pack(r,...))
	end
end

function updaterank()
	if rankid == 0 then
		return
	end

	loadranks()

	if checknewrank() then
		print("new rank")
		newrank()
	end
end

skynet.start(function()
	world = skynet.localname(".world")
	
	skynet.dispatch("lua", function(session, source, cmd,...)
		local f = assert(CMD[cmd])
		returnwarp(f(...))
	end)

	skynet.fork(function()
		while running do
			pcall(updaterank)
			skynet.sleep(500)
		end
	end)

	skynet.register(".rank")
end)