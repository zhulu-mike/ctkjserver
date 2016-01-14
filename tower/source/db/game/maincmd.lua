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

function saveplayer(uid,data)
	if not data or not uid then
		return NONE
	end

	-- local ruid = roleuids[data.detail.userid]

	-- if not ruid then
	-- 	ruid = -1
	-- end

	-- if uid >= ruid then
	-- 	datapool.saveplayer(data)

	-- 	if uid > ruid then
	-- 		roleuids[data.role.id] = uid
	-- 	end
	-- end

	return NONE
end

function newplayer(data)
	local roleid = rcmd("incr","maxplayerid")
	data.id = roleid
	datapool.newplayer(data)

	local playerdata = {}
	playerdata.roleid = roleid
	playerdata.role = data

	--init detail status
	local fields = redis_role_detail.fields

	for _,field in ipairs(fields) do
		playerdata[field] = {}
	end

	return playerdata
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

function saveserverlog(onlinecount)
	local sql = string.format("INSERT INTO tbl_server_log(rtime,onlinecount) VALUES(FROM_UNIXTIME(%d),%d)",
		os.time(),onlinecount)

	skynet.send(dbpool,"lua","execute",sql)
	return NONE
end

function onloginrole(roleid)
	local loginseq = rcmd("incr","logintimes")

	if not loginseq then
		loginseq = 0
	end
	
	redis_addloginrole(roleid,loginseq)
	return NONE
end

function getloginroles(count)
	local tr = redis_getloginroles(count)

	if not tr then
		return
	end

	local r = {}

	for i,v in ipairs(tr) do
		local role = datapool.getrole(tonumber(v))

		if role then
			table.insert(r,role)
		end
	end

	return r
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

function getrolesinlevel(roleids,level)
	local r = {}

	for _,roleid in ipairs(roleids) do
		local score = redis_getlevelscore(roleid,level)

		if score > 0 then
			local role = datapool.getrole(roleid)

			if role then
				table.insert(r,
				{
					friend =
					{
						roleid = role.id,
						rolename = role.rolename,
						currentFace = role.currentFace,
						passMax = role.maxpass,
						point = role.point,
						towerMax = role.maxtower
					},

					point = score
				})
			end
		end
	end

	return r
end

function getexchangecode(code)
	return redis_getexchangecode(code)
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