---handle client messages
local skynet = require "skynet"

--------------------------------------------------------------------------------------------------
--登录验证
MSG[100].on = function(client,input)
	--already logined
	if client.uid then
		return
	end

	--check version
	if input.version < MIN_VERSION then
		client:send(200,
		{
			error = AUTH_RESULT_VERSION
		})
		return
	end

	if client.loging then
		return
	end

	client.loging = true

	local data = 
	{
		binduname = input.bindaccount,
		username = input.deviceid,
		serverid = input.serverid,
		qudao = input.platformid,
		deviceid = input.deviceid,
		version = input.version,

		--server settings
		lastip = client.ip,
		gate = "gate" .. gateid,
		agent = skynet.self() ,
		agentid = client.agentid,
	}

	local error,uid,playerdata = skynet.call(world,"lua","loginaccount",data)

	if not error then
		return
	end

	if error ~= 0 then
		client:send(200,
		{
			error = error
		})

		client.loging = false
		return
	end

	client:onlogin(uid,playerdata.detail)
	client.data = playerdata
	client:send(200,
	{
		error = 0,
		userid = playerdata.detail.userid,
		systime = os.time(),
		version = CUR_VERSION
	})

	client.loging = false
end

--同步detail数据
MSG[103].on = function(client,input)

	if input.version < client.data.detail.version then
		client:send(203,
		{
			ret = SYN_VERSIONERROR
		})
		return
	end
	local detail = client.data.detail
	detail.gold = input.gold
	detail.diamond = input.diamond
	detail.energy = input.act
	detail.star = input.star
	client.data.timeinfo.energytime = input.acttime
	client.data.timeinfo.version = input.version
	detail.version = input.version
	detail.invalid = true
	client.data.timeinfo.invalid = true
	client:send(203,
	{
		ret = EXCUTE_SUCCESS
	})
end
--同步heros英雄数据
MSG[106].on = function(client,input)

	if input.version < client.data.heros.version then
		client:send(206,
		{
			ret = SYN_VERSIONERROR
		})
		return
	end
	local data = client.data.heros
	data.heros = input.heros
	data.version = input.version
	data.invalid = true
	client:send(206,
	{
		ret = EXCUTE_SUCCESS
	})
end
--同步rounds关卡数据
MSG[109].on = function(client,input)

	if input.version < client.data.rds.version then
		client:send(209,
		{
			ret = SYN_VERSIONERROR
		})
		return
	end
	local data = client.data.rds
	data.rounds = input.rounds
	data.version = input.version
	data.invalid = true
	client:send(209,
	{
		ret = EXCUTE_SUCCESS
	})
end

















