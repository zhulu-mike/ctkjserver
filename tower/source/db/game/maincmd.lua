local skynet = require "skynet"

require "json"

local roleuids = {}
--设置当前文件的环境变量为CMD
_ENV = CMD

-----------------------------------------------------------------------------------
function onclose()
	trace("close server")
end

function loaduser(id)
	return datapool.loaduser(id)
end
--根据username加载用户数据
function loaduserbyname(account,serverid,qudaoid)
	return datapool.loaduserbyname(account,serverid,qudaoid)
end
--根据绑定账户加载用户数据
function loaduserbybindaccount(account,serverid,qudaoid)
	return datapool.loaduserbybindaccount(account,serverid,qudaoid)
end

local lsrflag = {}
local lsrlist = {}

function loadsimplerole(id)
	if lsrflag[id] then
		if not lsrlist[id] then
			lsrlist[id] = {}
		end

		table.insert(lsrlist[id],skynet.response())
		return NONE
	else
		lsrflag[id] = true

		local r = datapool.getrole(id)
		local lst = lsrlist[id]

		if lst  then
			for _,item in ipairs(lst) do
				item(true,r)
			end
		end

		lsrlist[id] = nil
		lsrflag[id] = nil
		return r
	end
end

function loadplayer(id)
	local r = datapool.loaduser(id)

	if not r then
		trace("failed to load player ",id)
	else
		redis_removesqlsavelist(id)
		redis_setrole_ttl(id,0)
	end

	return r
end
--保存玩家的数据到redis
function saveplayer(uid,data)
	if not data or not uid then
		return NONE
	end
	--如果玩家数据的版本号变化了，就同步
	local d = data.detail
	if d and d.version > d.lastversion then
		redis_addsqlsavelist(d.userid)
		redisupdate(redis_userdetail,d.userid,d,REDIS_PLAYER_TTL)
	end

	d = data.heros
	if d and d.version > d.lastversion then
		redis_addsqlsavelist(d.userid)
		redisupdate(redis_userheros,d.userid,d,REDIS_PLAYER_TTL)
	end

	d = data.rds
	if d and d.version > d.lastversion then
		redis_addsqlsavelist(d.userid)
		redisupdate(redis_userrounds,d.userid,d,REDIS_PLAYER_TTL)
	end

	d = data.timeinfo
	if d and d.version > d.lastversion then
		redis_addsqlsavelist(d.userid)
		redisupdate(redis_usertime,d.userid,d,REDIS_PLAYER_TTL)
	end

	d = data.store
	if d and d.version > d.lastversion then
		redis_addsqlsavelist(d.userid)
		redisupdate(redis_userstore,d.userid,d,REDIS_PLAYER_TTL)
	end

	d = data.progress
	if d and d.version > d.lastversion then
		redis_addsqlsavelist(d.userid)
		redisupdate(redis_userprogress,d.userid,d,REDIS_PLAYER_TTL)
	end

	d = data.sign
	if d and d.version > d.lastversion then
		redis_addsqlsavelist(d.userid)
		redisupdate(redis_usersign,d.userid,d,REDIS_PLAYER_TTL)
	end

	return NONE
end


--used
--创建一个账户
--@param userid 账户的唯一ID
--@param data 账户的相关资料
function createuser(userid,data)
	data.id = userid
	data.registtime = os.time()
	data.lastlogintime = data.registtime
	data.lastdeviceid = data.deviceid

	return datapool.createuser(data)
end
--used
--保存玩家数据
function saveuser(user)
	if not user.lastlogouttime then
		user.lastlogouttime = 0
	end

	if not user.lastlogintime then
		user.lastlogintime = os.time()
	end

	datapool.saveusertoredis(user)
	return NONE
end

function saverecords(roleid,records)
	skynet.send(dbpool,"lua","saverecords",roleid,records)
end

function savemail(mail)
	datapool.savemail(mail)
	return NONE
end
--used
--定时保存在线人数日志
function saveserverlog(onlinecount)
	datapool.saveserverlog(onlinecount)
	return NONE
end


function getroles(roleids)
	local r = {}

	for _,roleid in ipairs(roleids) do
		local role = datapool.getrole(roleid)

		if role then
			table.insert(r,
			{
				roleid = role.id,
				rolename = role.rolename,
				currentFace = role.currentFace,
				passMax = role.maxpass,
				point = role.point,
				towerMax = role.maxtower
			})
		end
	end

	return r
end


function getranktime(ranktype)
	local key = "ranktime:" .. ranktype
	local v = redis_get(key)

	if not v then
		v = 0
	else
		v = tonumber(v)
	end

	return v
end