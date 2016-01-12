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

	client:onlogin(uid,playerdata)

	client:send(200,
	{
		error = 0,
		userid = playerdata.userid,
		systime = os.time(),
		version = CUR_VERSION
	})

	client.loging = false
end

--查找玩家
MSG[114].on = function(client,input)
	if input.roleid <= 0 then
		return
	end

	local error,data = skynet.call(world,"lua","findplayer",input.roleid)

	client:send(214,
	{
		result = error,
		friendinfo = data
	})
end

--获取好友列表
MSG[109].on = function(client,input)
	local friendids = client.data.friends

	if #friendids == 0 then
		client:send(209,
			{
				friends={}
			})
	else
		--query friend info
		local r = skynet.call(db,"lua","getroles",friendids)
		local lst = {}

		for _,fi in ipairs(r) do
			local gived = client:isenergygived(fi.roleid)
			table.insert(lst,{friends=fi,isSend=gived})
		end

		client:send(209,
			{
				friends=lst
			})
	end
end

--推荐好友
MSG[110].on = function(client,input)
	local r = skynet.call(db,"lua","getloginroles",20)
	local lst = {}

	if r then
		--filter
		local curcount = 0
		local friendids = client.data.friends

		for _,role in ipairs(r) do
			local valid = true

			--是否自己
			if role.id == client.roleid then
				valid = false
			end

			--是否已是好友
			if valid then
				for _,fid in ipairs(friendids) do
					if fid == role.id then
						valid = false
					end	
				end
			end

			--是否已发送申请
			if valid then
				for _,fid in ipairs(client.data.dailyrecord.friendinvitelist) do
					if fid == role.id then
						valid = false
					end	
				end
			end

			if valid then
				curcount = curcount + 1

				table.insert(lst,
				{
					roleid = role.id,
					rolename = role.rolename,
					currentFace = role.currentFace,
					passMax = role.maxpass,
					point = role.point,
					towerMax = role.maxtower
				})

				if curcount >= 6 then
					break
				end
			end
		end
	end

	client:send(210,
			{
				friendlist=lst
			})
end

--添加好友
MSG[107].on = function(client,input)
	local friends = client.data.friends

	if input.friendid == client.roleid then
		return
	end

	--是否超过上限
	if #friends >= MAX_FRIEND_COUNT then
		client:send(207,
			{
				result=GAME_CODE_ERROR_FRIEND_COUNT_OVERFLOW,
				friendid = input.friendid
			})
		return
	end

	--是否已经是好友
	for _,id in ipairs(friends) do
		if id == input.friendid then
			client:send(207,
			{
				result=GAME_CODE_ERROR_HAS_FRIEND,
				friendid = input.friendid
			})
			return
		end
	end

	local errorcode = skynet.call(world,"lua","addfriend",client.id,input.friendid)
	client:addinvited(input.friendid)
	
	if 0 == errorcode then
		client:addfriend(input.friendid)
	end

	client:send(207,
			{
				result=errorcode,
				friendid = input.friendid
			})
end

--删除好友
MSG[108].on = function(client,input)
	if input.friendid == 0 then
		return
	end
	
	client:delfriend(input.friendid)
	skynet.call(world, "lua", "delfriend", client.roleid, input.friendid)

	client:send(208,
	{
		result = 0
	})
end

--查询邮件
MSG[104].on = function(client,input)
	local maillist = client:getmailbytype(input.mtype)
	local mailresp = {}

	if  maillist then
		for _,mail in ipairs(maillist) do
			table.insert(mailresp,
			{
				id = mail.id,
				mtype = mail.mtype,
				sendtime = mail.senddate,
				sendroleid = mail.sendroleid,
				sendname = mail.sendname,
				sendicon = mail.sendresource,
				title = mail.title,
				content = mail.content,
				status = mail.status
			})
		end
	end

	client:send(204, 
		{ 
			mails = mailresp
		})
end

--操作邮件
MSG[106].on = function(client,input)
	if input.mtype == MAIL_TYPE_COMMON then
		--直接设置邮件为已读
		mail.status = MAIL_STATUS_ACCEPT
		mail.expiredate = os.time()
	else
		local okmailids = {}

		--处理所有邮件
		if input.mailid == 0 then
			local mails = client:getmailbytype(input.mtype)

			if not mails then
				return
			end

			for _,mail in ipairs(mails) do
				if client:dowithmail(mail,input.operate) then
					table.insert(okmailids,mail.id)
				end
			end
		else
			local mail = client:getmailbyid(input.mailid)

			if not mail then
				return
			end

			if client:dowithmail(mail,input.operate) then
				table.insert(okmailids,mail.id)
			end
		end

		client:send(206, 
		{ 
			mailids = okmailids
		})
	end
end

--签到
MSG[103].on  = function(client,input)
	local  sign = client.data.sign

	--查询签到信息
	if input.operate == SIGN_QUERY then
		local signflag = 2
		local days = sign.totaldays

		if  isdifferentday(sign.lastsignindate,os.time()) then
			signflag = 1
			
			if days > 20 then
				days = 7
			end
		end

		if signflag == 1 then
			days = days + 1
		end

		client:send(203, 
		{ 
			result = 0,
			status = signflag,
			totaldays = sign.totalcount,
			signindex = days
		})
	else
		--今天是否签到
		if  not isdifferentday(sign.lastsignindate,os.time()) then
			client:send(203, 
			{
				result = GAME_CODE_ERROR_SIGN_IN_REPEATE,
			})

			return
		end

		if sign.totaldays > 20 then
			sign.totaldays = 7
		end

		sign.lastsignindate = os.time()
		sign.totaldays = sign.totaldays + 1
		sign.totalcount = sign.totalcount + 1

		client:send(203, 
		{ 
			result = 0,
			status = 1,
			totaldays = sign.totalcount,
			signindex = sign.totaldays 
		})
	end
end

-- item.update
MSG[134].on = function(client,input)
	local props = {}

	for _,prop in pairs(input.items) do
		if prop.itemcount > 0 then
			table.insert(props,{prop.itemid,prop.itemcount})
		end
	end

	client.data.props = props
    
    	client:send(234,
	{
		result = 0,
	})
end

-- item.refresh
MSG[135].on = function(client,input)
	local props = client.data.props
	local iteminfo = {}

	for _,v in ipairs(props) do
		table.insert(iteminfo, {itemid=v[1], itemcount=v[2]})
	end
	
	client:send(235, {items = iteminfo, version = 0})
end

--pass.update
MSG[136].on = function(client,input)
	local levels = {}

    for _,v in ipairs(input.passinfo) do
		if v.point > 0 then
			table.insert(levels,{v.passid,v.point,v.star})
		end
	end

	client.data.levelinfo = levels
	client:send(236, {result = 0,})
end

--pass.refresh
MSG[137].on = function(client,input)
	local levels = client.data.levelinfo
	local passinfo = {}

    	for _,v in ipairs(levels) do
		table.insert(passinfo, {passid=v[1], point=v[2], star=v[3]})
	end

    	client:send(237, {passinfo = passinfo})
end

--task.update
MSG[138].on = function(client,input)
	local tasks = {}

    for _,v in ipairs(input.taskinfo) do
		table.insert(tasks,{v.taskid,v.isSubmission,v.isGetAward})
	end

	client.data.tasks = tasks
	client:send(238, {result = 0,})
end

--task.refresh
MSG[139].on = function(client,input)
	local tasks = client.data.tasks
    	local taskinfo = {}

   	 for _,v in ipairs(tasks) do
		table.insert(taskinfo, {taskid=v[1], isSubmission=v[2], isGetAward=v[3]})
	end

	client:send(239, {taskinfo = taskinfo, taskindex = 0})
end

--tower.update
MSG[141].on = function(client,input)
	local towers = {}

    	for _,v in ipairs(input.towerinfo) do
		table.insert(towers,{v.towerid,v.point,v.layer})
		skynet.call(db,"lua","rank_add",v.towerid + 1,client.roleid,v.layer)
	end

	client.data.towerinfo = towers

    	client:send(241,
	{
		result = 0,
	})
end

--tower.refresh
MSG[140].on = function(client,input)
	local towers = client.data.towerinfo
    	local towerinfo = {}

    	for _,v in ipairs(towers) do
		table.insert(towerinfo, {towerid=v[1], point=v[2], layer=v[3]})
	end

    	client:send(240, {towerinfo = towerinfo})
end

--role.update
MSG[143].on = function(client,input)
	local role = client.data.role
	local oldversion = role.version

	if input.version < oldversion then
		client:send(243,
			{
				result = 0,

			})

		return
	end

	local pointchanged = false

	if input.point > role.point then
		pointchanged = true
	end

	role.rolename = input.rolename
	role.version = input.version
	role.coins = input.coins
	role.isFirst = input.isFirst
	role.currentFace = input.currentFace
	role.point = input.point
	role.rmb = input.yuanbao

	client.data.storyData = input.storyData
	client.data.teachData = input.teachData
	client.data.faceList = input.faceList

	client:send(243,
			{
				result = 0,

			})

	if pointchanged and role.point > 0 then
		skynet.call(db,"lua","rank_add",RANK_ENDLESS,client.roleid,role.point)
	end
end

--role.refresh
MSG[142].on = function(client,input)
	local role = client.data.role

	local output = {}
	output.roleid = role.id
	output.version = role.version
	output.rolename = role.rolename
	output.coins = role.coins
	output.isFirst = role.isFirst
	output.currentFace = role.currentFace
	output.point = role.point
	output.yuanbao = role.rmb
	output.storyData = role.storyData
	output.teachData = role.teachData
	output.faceList = role.faceList

	client:send(242, output)
end

--rank.query
MSG[144].on = function(client,input)
	local ranks = skynet.call(world,"lua","getranks",1,0,-1)

	if not ranks then
		return
	end

	local ranklist = {}

	for _,rank in ipairs(ranks) do
		local isfriend = client:isfriend(rank.roleid)
		table.insert(ranklist, {friend = rank, isFriend = isfriend})
	end

	client:send(244, 
		{
			ranklist = ranklist
		})
end

--friend.get_point
MSG[145].on = function(client,input)
	local friendids = client.data.friends

	if table.empty(friendids) then
		client:send(245,{result = 0,passid = input.passid,friendPoint = {},})
		return
	end

	--query friend info
	local list = skynet.call(db,"lua","getrolesinlevel",friendids,input.passid)
	
	client:send(245,
	{
		result = 0,
		passid = input.passid,
		friendPoint = list,
	})
end

--task.refresh_everyday
MSG[146].on = function(client,input)
	local dr = client.data.dailyrecord
	local r = false

	if not dr.taskrefresh then
		dr.taskrefresh = true
		r = true
	end

  	client:send(246, {result = 0, isFresh = r })
end

--friend.send_item
MSG[147].on = function(client,input)
	--判断是否可以送物品
	if not client:cangiveenergy(input.friendid) then
		client:send(247, {result = 1, friendid = input.friendid})
		return
	end

	client:addenergygived(input.friendid)
	skynet.call(world,"lua","energygive",client.id,input.friendid)
	client:send(247, {result = 0, friendid = input.friendid})
end

--获得好友赠送道具
MSG[148].on = function(client,input)
	local maillist = client:getmailbytype(MAIL_TYPE_ENERGY_GIVE)
	local roleids = {}

	for _,mail in ipairs(maillist) do
		table.insert(roleids,mail.sendroleid)
	end

	local r = {}

	if not table.empty(roleids) then
	    	r = skynet.call(db, "lua", "getroles", roleids)

	    	--remove local mails
	    	client:removemailbytype(MAIL_TYPE_ENERGY_GIVE)
	end

    	client:send(248, {result = 0, friendlist = r})
end

--获取排行榜奖励
MSG[149].on = function(client,input)
	local maillist = client:getmailbytypeandsender(MAIL_TYPE_RANK_REWARD,1)
	local r = {}

	if not table.empty(maillist) then
		for _,mail in ipairs(maillist) do
			table.insert(r,tonumber(mail.content))
		end

		client:removemails(maillist)
	end

	client:send(249, {result = 0, ranking = r})
end

--清空排行分数
MSG[150].on = function(client,input)
	local ret = false
	local r = skynet.call(db, "lua", "rank_hasrole",RANK_ENDLESS,client.roleid)
	
	if not r then
		ret = true
		
		--add to rank
		skynet.call(db, "lua", "rank_add",RANK_ENDLESS,client.roleid,0)
	end

	client:send(250, {result = 0, isClear = ret})
end

--领取兑换码
MSG[151].on = function(client,input)
	local r = skynet.call(db, "lua", "getexchangecode",input.id)

	if not r then
		client:send(251, {result = 1, index = 0})
	else
		client:send(251, {result = 0, index = r})
	end
end

--rank2.query
MSG[152].on = function(client,input)
	local ranks = skynet.call(world,"lua","getranks",input.type + 1,0,-1)
	local rankscores = skynet.call(world,"lua","getrankscores",input.type + 1,0,-1)

	if not ranks then
		return
	end

	local ranklist = {}

	for i,rank in ipairs(ranks) do
		local isfriend = client:isfriend(rank.roleid)
		table.insert(ranklist, {friend = rank, isFriend = isfriend,score=rankscores[i]})
	end

	client:send(252, 
		{
			type = input.type,
			ranklist = ranklist
		})
end

--获取排行榜奖励
MSG[153].on = function(client,input)
	local maillist = client:getmailbytypeandsender(MAIL_TYPE_RANK_REWARD,input.type + 1)
	local r = {}

	if not table.empty(maillist) then
		for _,mail in ipairs(maillist) do
			table.insert(r,tonumber(mail.content))
		end

		client:removemails(maillist)
	end

	client:send(253, {type = input.type,result = 0, ranking = r})
end

--清空排行分数
MSG[154].on = function(client,input)
	local ret = false
	local r = skynet.call(db, "lua", "rank_hasrole",input.type + 1,client.roleid)
	
	if not r then
		ret = true
		
		--add to rank
		skynet.call(db, "lua", "rank_add",input.type + 1,client.roleid,0)
	end

	client:send(254, {type = input.type,result = 0, isClear = ret})
end

-------------------------------------------------------------------------------------
--rank3
MSG[155].on = function(client,input)
	local ranks = skynet.call(world,"lua","getranks",12,0,-1)
	local rankscores = skynet.call(world,"lua","getrankscores",12,0,-1)

	if not ranks then
		return
	end

	local ranklist = {}

	for i,rank in ipairs(ranks) do
		local isfriend = client:isfriend(rank.roleid)
		table.insert(ranklist, {friend = rank, isFriend = isfriend,level=rankscores[i]})
	end

	client:send(255, 
		{
			ranklist = ranklist
		})
end

MSG[156].on = function(client,input)
	local maillist = client:getmailbytypeandsender(MAIL_TYPE_RANK_REWARD,12)
	local r = {}

	if not table.empty(maillist) then
		for _,mail in ipairs(maillist) do
			table.insert(r,tonumber(mail.content))
		end

		client:removemails(maillist)
	end

	client:send(256, {result = 0, ranking = r})
end

--清空排行分数
MSG[157].on = function(client,input)
	local ret = false
	local r = skynet.call(db, "lua", "rank_hasrole",12,client.roleid)
	
	if not r then
		ret = true
		
		--add to rank
		skynet.call(db, "lua", "rank_add",12,client.roleid,0)
	end

	client:send(257, {result = 0, isClear = ret})
end

MSG[158].on = function(client,input)
	skynet.call(db,"lua","rank_add",12,client.roleid,input.level)
	client:send(258, {result = 0})
end