local skynet = require "skynet"
local dbpool = dbpool
local redispool = redispool
local rcmd = rcmd
local urcmd = urcmd

_ENV = datapool

--使用username加载用户数据
function loaduserbyname(account,serverid,qudaoid)
	local r = redis_loaduserbyname(account,serverid,qudaoid)
	local data = nil
	--redis中没有找到，则去mysql中找
	if not r then
		local tr = sqlconditionquery(tbl_user,"username=\'%s\' AND serverid=%d AND qudao=%d",account,serverid,qudaoid)

		if #tr > 0 then
			r = tr[1]
		end

		if r then
			data = {}
			data.user = redis_adduser(r)
		end
	else
		data = {}
		data.user = r
	end
	if r then
		local other = loaduserother(data.user.id)
		local playerdata = {}
		playerdata.detail = other.detail
		playerdata.heros = other.heros
		playerdata.rds = other.rds
		playerdata.timeinfo = other.timeinfo
		data.playerdata = playerdata
	end
	return data
end
--使用绑定账户加载用户数据
function loaduserbybindaccount(account,serverid,qudaoid)
	local r = redis_loaduserbybindaccount(account,serverid,qudaoid)
	local data = nil
	if not r then
		local tr = sqlconditionquery(tbl_user,"binduname=\'%s\' AND serverid=%d AND qudao=%d",account,serverid,qudaoid)

		if #tr > 0 then
			r = tr[1]
		end
		if r then
			data = {}
			data.user = redis_adduser(r)
		end
	else
		data = {}
		data.user = r
	end
	if r then
		local other = loaduserother(data.user.id)
		local playerdata = {}
		playerdata.detail = other.detail
		playerdata.heros = other.heros
		playerdata.rds = other.rds
		playerdata.timeinfo = other.timeinfo
		data.playerdata = playerdata
	end
	return data
end

--used
--创建一个玩家账户
function createuser(input)

	local data = {}
	--插入到mysql
	sqlinsert(tbl_user,input);
	--插入到redis
	data.user = redis_adduser(input);
	local playerdata = {}

	local detail = {userid=input.id, nickname=""}
	sqlinsert(tbl_userdetail,detail);
	playerdata.detail = redisinsert(redis_userdetail,detail.userid,detail)

	local usertime = {userid=input.id, energytime=0}
	sqlinsert(tbl_usertime,usertime);
	playerdata.timeinfo = redisinsert(redis_usertime,usertime.userid,usertime)

	local heros = {userid=input.id, heros=""}
	sqlinsert(tbl_userheros,heros);
	playerdata.heros = redisinsert(redis_userheros,heros.userid,heros)

	local rds = {userid=input.id, rounds=""}
	sqlinsert(tbl_userrounds,rds);
	playerdata.rds = redisinsert(redis_userrounds,rds.userid,rds)

	--继续插入表，如果需要
	data.playerdata = playerdata
	return data
end

--used
--加载一个玩家的数据，凡是加载，包括从sql读数据和把数据存入redis
function loaduser(id)
	local data = {}

	local user = redis_loaduser(id)
	if not user then 
		return
	end
	data.user = user
	--加载tbl_userdetail的数据
	local other = loaduserother(id)
	if not other then
		return
	end
	local playerdata = {}
	playerdata.detail = other.detail
	playerdata.timeinfo = other.timeinfo
	playerdata.heros = other.heros
	playerdata.rds = other.rds
	data.playerdata = playerdata
	--get new mails，获取邮件数据
	-- local nmails = redis_fetchnewmails(id)
	-- table.merge(r.mails,nmails)
	return data
end

--used
--加载一个玩家的数据，凡是加载，包括从sql读数据和把数据存入redis
function loaduserother(id)
	--先加载tbl_userdetail的数据
	local ret = {}
	--资源数据
	local data = loaduserdetail(id, true)
	data.lastversion = data.version
	ret.detail = data
	--时间数据
	data = loadusertime(id,true)
	data.lastversion = data.version
	ret.timeinfo = data
	--英雄数据
	data = loaduserheros(id,true)
	data.lastversion = data.version
	ret.heros = data
	--关卡数据
	data = loaduserrounds(id,true)
	data.lastversion = data.version
	ret.rds = data
	--get new mails，获取邮件数据
	-- local nmails = redis_fetchnewmails(id)
	-- table.merge(r.mails,nmails)
	return ret
end

--used
--载入玩家数据
--@param id 玩家的userid
--@param autords bool 从sql中读取数据后是否自动添加到redis中
function loaduserdetail(id, autords)
	--先尝试从redis中读取detail数据
	local r = redis_getuserdetail(id)

	if r then
		return r
	end
	--从mysql中读取userdetail数据
	if (LOG_LEVEL > 0) then
		trace("load userdetail from sql ",id)
	end
	local detail = sqlfetchone(tbl_userdetail,id)
	return redis_adduserdetail(detail);
end
--used
--载入玩家数据
--@param id 玩家的userid
--@param autords bool 从sql中读取数据后是否自动添加到redis中
function loadusertime(id, autords)
	--先尝试从redis中读取detail数据
	local r = redis_getusertime(id)

	if r then
		return r
	end
	--从mysql中读取userdetail数据
	if (LOG_LEVEL > 0) then
		trace("load usertime from sql ",id)
	end
	local data = sqlfetchone(tbl_usertime,id)
	return redis_addusertime(data);
end
--used
--载入玩家数据
--@param id 玩家的userid
--@param autords bool 从sql中读取数据后是否自动添加到redis中
function loaduserheros(id, autords)
	--先尝试从redis中读取detail数据
	local r = redis_getuserheros(id)

	if r then
		return r
	end
	--从mysql中读取userdetail数据
	if (LOG_LEVEL > 0) then
		trace("load userheros from sql ",id)
	end
	local data = sqlfetchone(tbl_userheros,id)
	return redis_adduserheros(data);
end

--used
--载入玩家数据
--@param id 玩家的userid
--@param autords bool 从sql中读取数据后是否自动添加到redis中
function loaduserrounds(id, autords)
	--先尝试从redis中读取detail数据
	local r = redis_getuserrounds(id)

	if r then
		return r
	end
	--从mysql中读取userdetail数据
	if (LOG_LEVEL > 0) then
		trace("load userrounds from sql ",id)
	end
	local data = sqlfetchone(tbl_userrounds,id)
	return redis_adduserrounds(data);
end