---handle client messages
local skynet = require "skynet"

--------------------------------------------------------------------------------------------------
--登录验证
MSG[100].on = function(client,input)
	--already logined
	if client.uid then
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

		--server settings
		lastip = client.ip,
		gate = "gate" .. gateid,
		agent = skynet.self() ,
		agentid = client.agentid
	}

	local error,uid,playerdata,lastdeviceid = skynet.call(world,"lua","loginaccount",data)

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
	local respdata = {
		error = 1,
		userid = playerdata.detail.userid,
		systime = os.time(),
		resupdate = 0,
		heroupdate = 0,
		chapterupdate = "",
		prbupdate = 0,
		storeupdate = 0
	}
	
	local resversion = input.resversion
	local herosversion = input.herosversion
	local chaptersversion = input.chaptersversion
	local prbversion = input.prbversion
	local storeversion = input.storeversion
	local update = false
	if lastdeviceid and lastdeviceid ~= "" and lastdeviceid ~= input.deviceid then
		update = true
	end
	-- trace(update)
	-- trace("_" .. input.deviceid)
	local needsenddetail = false
	local needsendheros = false
	local needsendstore = false
	local needsendprogress = false
	if update or playerdata.detail.version > resversion then
		needsenddetail = true
	elseif (playerdata.detail.version < resversion) then
		respdata.resupdate = 1
	end
	if update or playerdata.heros.version > herosversion then
		needsendheros = true
	elseif (playerdata.heros.version < herosversion) then
		respdata.heroupdate = 1
	end
	if update or playerdata.store.version > storeversion then
		needsendstore = true
	elseif (playerdata.store.version < storeversion) then
		respdata.storeupdate = 1
	end
	if update or playerdata.progress.version > prbversion then
		needsendprogress = true
	elseif (playerdata.progress.version < prbversion) then
		respdata.prbupdate = 1
	end
	client:send(200,respdata)
	if needsenddetail then
		client:send(250,{
			userid = playerdata.detail.userid,
			gold = playerdata.detail.gold,
			diamond = playerdata.detail.diamond,
			act = playerdata.detail.energy,
			star = playerdata.detail.star,
			acttime = playerdata.timeinfo.energytime,
			version = playerdata.detail.version
			}
		)
	end
	if needsendstore then
		client:send(253,{
			userid = playerdata.detail.userid,
			store = playerdata.store.store,
			version = playerdata.store.version
			}
		)
	end
	if needsendheros then
		client:send(251,{
			userid = playerdata.detail.userid,
			heros = playerdata.heros.heros,
			version = playerdata.heros.version
			}
		)
	end
	if needsendprogress then
		local userphb = playerdata.progress
		client:send(254,{
			userid = playerdata.detail.userid,
			chapter = userphb.chapter,
			gate = userphb.gate,
			isPlayedAction = userphb.isPlayedAction,
			firstGateGuide = userphb.firstGateGuide,
			secondGateGuide = userphb.secondGateGuide,
			thirdGateGuide = userphb.thirdGateGuide,
			after3rdGateGuide = userphb.after3rdGateGuide,
			eighthGateGuide = userphb.eighthGateGuide,
			roleLayerGuide = userphb.roleLayerGuide,
			firstChapterGuide = userphb.firstChapterGuide,
			isRemindRole = userphb.isRemindRole,
			version = userphb.version
			}
		)
	end
	client:send(102,{
			error = 1
		}
	)
	client.loging = false
end

--同步detail数据
MSG[103].on = function(client,input)
	--trace(type(input.version) .. type(client.data.detail.version))
	if input.version <= client.data.detail.version then
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

	if input.version <= client.data.heros.version then
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

	if input.version <= client.data.rds.version then
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

--同步store关卡数据
MSG[112].on = function(client,input)

	if input.version <= client.data.store.version then
		client:send(212,
		{
			ret = SYN_VERSIONERROR
		})
		return
	end
	local data = client.data.store
	data.store = input.store
	data.version = input.version
	data.invalid = true
	client:send(212,
	{
		ret = EXCUTE_SUCCESS
	})
end
--同步progress关卡数据
MSG[115].on = function(client,input)

	if input.version <= client.data.progress.version then
		client:send(215,
		{
			ret = SYN_VERSIONERROR
		})
		return
	end
	local data = client.data.progress
	data.chapter = input.chapter
	data.gate = input.gate
	data.isPlayedAction = input.isPlayedAction
	data.firstGateGuide = input.firstGateGuide
	data.secondGateGuide = input.secondGateGuide
	data.thirdGateGuide = input.thirdGateGuide
	data.after3rdGateGuide = input.after3rdGateGuide
	data.eighthGateGuide = input.eighthGateGuide
	data.roleLayerGuide = input.roleLayerGuide
	data.firstChapterGuide = input.firstChapterGuide
	data.isRemindRole = input.isRemindRole
	data.version = input.version
	data.invalid = true
	client:send(215,
	{
		ret = EXCUTE_SUCCESS
	})
end

















