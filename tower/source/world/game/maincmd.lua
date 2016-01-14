local skynet = require "skynet"
local cluster = require "cluster"
local conlineuser = require "onlineuser"

local uid = 1
local ranks = {}
local rankscores = {}

_ENV = CMD

local function dologinaccount(input)
	--先尝试能否从在线列表中获取用户
	local user = usermanager.getuserbyaccountandserver(input.username,input.binduname,input.serverid,input.qudao)
	--如果不能，则创建一个在线实例存储玩家
	if not user then
		user = conlineuser.new()
		--用户不在线，判断是否是新建帐号
		local account = allacc.getbyaccount(input.username,input.binduname,input.serverid,input.qudao)
		--没有角色，创建账户
		if not account then
			local userid = usermanager.genuid()
			local data = skynet.call(db,"lua","createuser",userid,input)
			user.id = userid

			account = allacc.add(userid,data)
		else
			if account.state == 1 then
				return AUTH_RESULT_FORBIDDEN
			end
			--不知为何要合并
			-- table.merge(user,account)
		end
		user.account = account.user
		user.playerdata = account.playerdata
	else
		local kickoldplayer = true
		--处于在线列表中，先杀死旧的登陆信息，防止账号重复登陆
		if not user.online or (user.agentid == input.agentid and user.gate == input.gate) then
			kickoldplayer = false
		end

		if kickoldplayer then
			usermanager.logout(user)

			--kick
			local ok,data = user:send("kick",user.agentid)

			if ok ~= 0 then
				return CODE_FAILED
			end

			-- if data then
			-- 	user.playerdata = data
			-- end
		end
	end

	usermanager.add(user)

	if not usermanager.login(user) then
		return CODE_FAILED
	end

	-- local playerdata

	-- if not user.playerdata then
	-- 	playerdata = skynet.call(db,"lua","loadplayer",user.account.roleid)

	-- 	if not playerdata then
	-- 		return CODE_FAILED
	-- 	end
	-- else
	-- 	playerdata = user.playerdata
	-- 	user.playerdata = nil
	-- end

	local acc = user.account

	acc.lastip = input.ip 		--最后登录ip
	acc.lastlogintime = os.time()
	acc.lastdeviceid   = input.deviceid

	uid = uid + 1
	user.gate = input.gate
	user.agent = input.agent
	user.agentid = input.agentid
	user.uid = uid
	user.online = true
	user.disconnecttime = 0
	user.name = user.playerdata.detail.nickname

	return 0,uid,user.playerdata
end

local loginflags = {}
--玩家登录账户
function loginaccount(input)
	--获取玩家的唯一标示符
	local userkey = table.implode({input.binduname,input.username,input.qudao,input.serverid},"_")
	if loginflags[userkey] then
		return AUTH_RESULT_LOGIN_ING,0,nil
	end

	loginflags[userkey] = true
	local r,errorcode,uid,playerdata  = pcall(dologinaccount,input)
	loginflags[userkey] = nil
	return errorcode,uid,playerdata
end
--used
--客户端断开链接时
function lostclient(uid,input)
	local user = usermanager.getuser(input.detail.userid)

	if user then
		if user.uid > uid then
			return
		end

		user:ondisconnect()
		user.playerdata = input
	else
		--save to db
		skynet.call(db,"lua","saveplayer",uid,input)
	end
end



--体力申请
function energyrequest(roleid,targetid)
	local sender = allrole.getrole(roleid)

	if not sender then
		return CODE_FAILED
	end

	local recvuser = usermanager.getuserbyrole(targetid)
	local ok = false

	--发往玩家邮件数据池
	if recvuser and recvuser.online then
		local mailid = mailmanager.genuid()
		ok = recvuser:send("sendmail",mailid,roleid,sender.rolename,sender.roleresource,MAIL_TYPE_ENERGY_REQUEST,"体力请求","",ONE_WEEK)
	end

	--收入邮件管理器
	if ok ~= 0 then
		mailmanager.add(roleid,MAIL_TYPE_ENERGY_REQUEST,targetid,"体力请求","",ONE_WEEK)
	end

	return 0
end



--更新排行榜缓存
function updateranks(type,data)
	ranks[type] = {}
	rankscores[type] = {}

	for id,v in ipairs(data) do
		local roleid = v[1]
		local order = v[2]
		local score = v[3]
		local role = v[4]

		if role and score > 0 then
			local  r = 
			{
				roleid		= role.id,
				rolename	= role.rolename,
				currentFace	= role.currentFace,
				passMax	= role.maxpass,
				point		= role.point,
			}

			table.insert(ranks[type],r)
			table.insert(rankscores[type],score)
		end
	end

	return NONE
end

--查询排行榜
function getranks(type,from,to)
	return ranks[type]
end

function getrankscores(type,from,to)
	return rankscores[type]
end

--查询玩家
function findplayer(roleid)
	local role = allrole.getrole(roleid)

	if not role then
		return GAME_CODE_ERROR_ROLE_NOT_FIND
	end

	local data = 
	{
		roleid = roleid,
		rolename = role.rolename,
		roleresource = role.roleresource,
		score = role.maxscore,
		distance = role.maxdistance
	}

	return 0,data
end

