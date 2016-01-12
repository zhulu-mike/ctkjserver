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
		data.detail = other.detail
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
		data.detail = other.detail
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

	local detail = {userid=input.id, nickname=""}
	sqlinsert(tbl_userdetail,detail);
	data.detail = redisinsert(redis_userdetail,detail.userid,detail)

	local usertime = {userid=input.id, energytime=0}
	sqlinsert(tbl_usertime,usertime);
	redisinsert(redis_usertime,usertime.userid,usertime)

	--继续插入表，如果需要

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
	local detail = loaduserdetail(id, true)
	if not detail then
		return
	end
	data.detail = detail
	--get new mails，获取邮件数据
	-- local nmails = redis_fetchnewmails(id)
	-- table.merge(r.mails,nmails)
	return data
end

--used
--加载一个玩家的数据，凡是加载，包括从sql读数据和把数据存入redis
function loaduserother(id)
	--先加载tbl_userdetail的数据
	local detail = loaduserdetail(id, true)

	if not detail then
		return
	end

	--get new mails，获取邮件数据
	-- local nmails = redis_fetchnewmails(id)
	-- table.merge(r.mails,nmails)
	return {detail=detail}
end

--used
--载入玩家数据
function loaduserdetail(id, autords)
	--先尝试从redis中读取detail数据
	local r = redis_getuserdetail(id)

	if r then
		return r
	end
	--从mysql中读取userdetail数据
	if (LOG_LEVEL > 0) then
		dprint("load userdetail from sql ",id)
	end
	local detail = sqlfetchone(tbl_userdetail,id)
	return redis_adduserdetail(detail);
end