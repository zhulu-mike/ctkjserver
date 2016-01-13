------------client manager
local skynet = require "skynet"

local function checkmailexpired(mail,curtime)
	if mail.expiredate <= 0 then
		return false
	end

	if mail.expiredate <= curtime then
		return true
	end

	return false
end
--一个用户的数据结构
cclient = class("cclient")

function cclient:ctor()
	self.props = {}			--包裹中的物品
	self.loging = false
	self.data = nil
	self.kicked = false
	self.error = false
	self.disconnect = false
	self.running = false
	self.authtimer = 0
	self.savetimer = 0
	self.roleid = 0
	self.fd = 0
	self.agentid=0
	self.ip = ""
end
--used
function cclient:send(...)
	if 0 == self.fd or self.disconnect then
		return
	end

	sendpackage(self.fd,...)
end
--used
--登陆
function cclient:onlogin(uid,data)
	trace("user [" .. data.userid .."] login")

	self.uid   = uid
	self.data = data
	self.id     = data.userid
	self.userid = data.userid
	self.name     = data.nickname
	self.running = true

	local  curtime = os.time()

	--check daily record
	--[[local  dayrc = self.data.dailyrecord
	local curday = datetime(curtime)

	if dayrc.dayid ~= curday then
		self:resetdayrecord(curday)
	end]]--

	--处理离线操作
	--[[local mails = {}
	local mailcount = #data.mails
	local giftmailcount = 0

	for i = mailcount,1,-1 do
		local mail = data.mails[i]

		if not checkmailexpired(mail,curtime) then
			if mail.mtype == MAIL_TYPE_FRIEND_ADD then
				if not self:isfriend(mail.sendroleid) then
					table.insert(self.data.friends,mail.sendroleid)
				end
			elseif mail.mtype == MAIL_TYPE_FRIEND_DEL then
				if self:isfriend(mail.sendroleid) then
					table.removebyvalue(self.data.friends,mail.sendroleid)
				end
			elseif mail.mtype == MAIL_TYPE_ENERGY_GIVE then
				if giftmailcount < MAX_GIFT_COUNT then
					table.insert(mails,mail)
				end

				giftmailcount = giftmailcount + 1
			else
				table.insert(mails,mail)
			end
		end
	end

	data.mails = mails]]--
end

function cclient:ondisconnect()
	self.running = false
	self.disconnect = true

	if not self.kicked then
		if not self.uid then
			return
		end
		
		--通知世界服务器保存数据
		local data = self:builddata()

		if data then
			skynet.call(world,"lua","lostclient",self.uid,data)
		end
	end
end

function cclient:builddata()
	local  curtime = os.time()
	local data = self.data

	if not data or not data.role then
		return
	end

	local mails = {}

	for _,mail in ipairs(data.mails) do
		if not checkmailexpired(mail,curtime) and mail.status == MAIL_STATUS_UNREAD then
			table.insert(mails,mail)
		end
	end

	--return create player data
	local playerdata = 
	{
		--基础数据
		role = data.role,

		--角色
		 actors = data.actors,

		 --好友
		 friends = data.friends,

		 --邮件
		 mails = mails,

		 --每日数据
		 dailyrecord = data.dailyrecord,

		 --签到
		 sign = data.sign,

		 towerinfo = data.towerinfo,
		 storyData = data.storyData,
		 teachData = data.teachData,
		 faceList = data.faceList,
		 levelinfo = data.levelinfo,
		 props = data.props,
		 tasks = data.tasks
	}

	playerdata.role.maxpass = #data.levelinfo
	local maxtower = 0

	for _,v in ipairs(data.towerinfo) do
		if maxtower < v[2] then
			maxtower = v[2]
		end
	end

	playerdata.role.maxtower = maxtower
	return playerdata
end
--每天凌晨初始化数据
function cclient:resetdayrecord(dayid)
	local  dayrc = self.data.dailyrecord

	dayrc.dayid = dayid
	dayrc.energyroleids = {}
	dayrc.energyreceivedcount = 0
	dayrc.energygiveroleids = {}
	dayrc.mallbuyinfo = {}
	dayrc.userbuyinfo = {}
	dayrc.taskrefresh = false
	dayrc.friendinvitelist = {}
end

function cclient:onnewday(dayid)
	--reset daily records
	self:resetdayrecord(dayid)
end

function cclient:update(delta)
	if self.disconnect then
		return
	end

	if self.running then
		self.savetimer = self.savetimer + delta

		if self.savetimer >= PLAYER_SAVE_INTERVAL then
			self.savetimer = 0
			local ok = skynet.send(db,"lua","saveplayer",self.uid,self:builddata())

			if not ok then
				skynet.call(dog,"lua","close",self.fd)
			end
		end
	else
		self.authtimer = self.authtimer + delta

		--1分后断开未验证连接
		if self.authtimer >= 60 then
			trace("authtimeout")
			self.disconnect = true
			skynet.call(dog,"lua","close",self.fd)
		end
	end
end

function cclient:addmail(mailid,mailtype,sendroleid,sendname,sendresource,title,content,expiredate)
	local mail = 
	{
		id = mailid,
		mtype = mailtype,
		senddate = os.time(),
		sendroleid = sendroleid,
		sendname = sendname,
		sendresource = sendresource,
		recvroleid = self.id,
		title = title,
		content = content,
		status = MAIL_STATUS_UNREAD,
	}

	if expiredate ~= -1 then
		mail.expiredate = os.time() + expiredate
	else
		mail.expiredate = os.time() + ONE_DAY * 360 * 10
	end

	local data = self.data
	table.insert(data.mails,mail)

	trace("receive mail from",sendroleid,"title",title)
	return mail
end

function cclient:getmailfrom(sendid,mailtype)
	local curtime = os.time()
	local  mails = self.data.mails

	for _,mail in ipairs(mails) do
		if not checkmailexpired(mail,curtime) then
			if mail.mtype == mailtype and mail.sendroleid == sendid then
				return mail
			end
		end
	end
end

function cclient:getmailbytype(mailtype)
	local curtime = os.time()
	local  mails = self.data.mails
	local maillist = {}

	for _,mail in ipairs(mails) do
		if not checkmailexpired(mail,curtime) then
			if mail.mtype == mailtype and mail.status == MAIL_STATUS_UNREAD then
				table.insert(maillist,mail)
			end
		end
	end

	return maillist
end

function cclient:getmailcount(mailtype)
	local curtime = os.time()
	local mails = self.data.mails
	local count = 0

	for _,mail in ipairs(mails) do
		if not checkmailexpired(mail,curtime) then
			if mail.mtype == mailtype and mail.status == MAIL_STATUS_UNREAD then
				count = count + 1
			end
		end
	end

	return count
end

function cclient:getmailbytypeandsender(mailtype,sender)
	local mails = self:getmailbytype(mailtype)
	local r = {}

	for _,mail in ipairs(mails) do
		if mail.sendroleid == sender then
			table.insert(r,mail)
		end
	end

	return r
end

function cclient:removemailbytype(mailtype)
	local curtime = os.time()
	local  mails = self.data.mails

	for _,mail in ipairs(mails) do
		if mail.mtype == mailtype and mail.status == MAIL_STATUS_UNREAD then
			mail.status = MAIL_STATUS_ACCEPT
			mail.expiredate = curtime
		end
	end
end

function cclient:removemails(mails)
	local curtime = os.time()

	for _,mail in ipairs(mails) do
		if mail.status == MAIL_STATUS_UNREAD then
			mail.status = MAIL_STATUS_ACCEPT
			mail.expiredate = curtime
		end
	end
end

function cclient:hasmailbytype(mailtype)
	local curtime = os.time()
	local  mails = self.data.mails

	for _,mail in ipairs(mails) do
		if not checkmailexpired(mail,curtime) then
			if mail.mtype == mailtype and mail.status == MAIL_STATUS_UNREAD then
				return true
			end
		end
	end

	return false
end

function cclient:getmailbyid(mailid)
	local curtime = os.time()
	local  mails = self.data.mails

	for _,mail in ipairs(mails) do
		if not checkmailexpired(mail,curtime) then
			if mail.id == mailid and mail.status == MAIL_STATUS_UNREAD then
				return mail
			end
		end
	end
end

function cclient:dowithmail(mail,operator)
	local ok = false

	if mail.mtype == MAIL_TYPE_COMMON then
		ok = true
	else
		--接受邮件
		if operator == 1 then
			ok = self:acceptmail(mail)
		else
			--拒绝
			ok = self:rejectmail(mail)
		end
	end

	if ok then
		mail.status 	 = MAIL_STATUS_ACCEPT
		mail.expiredate = os.time() 
	end

	return ok
end

function cclient:acceptmail(mail)
	if mail.sendroleid == self.id then
		return
	end

	local  dayrc = self.data.dailyrecord

	--体力请求邮件
	if mail.mtype == MAIL_TYPE_ENERGY_REQUEST then
		local  gived = false

		for _,id in ipairs(dayrc.energygiveroleids) do
			if id == mail.sendroleid then
				gived = true
				break
			end
		end

		if not gived then
			--发送体力邮件
			skynet.call(world,"lua","sendmail",self.id,MAIL_TYPE_ENERGY_GIVE,mail.sendroleid,"领取体力","",ONE_WEEK)
			table.insert(dayrc.energygiveroleids,mail.sendroleid)
		end

		return true
	end

	--体力领取
	if mail.mtype == MAIL_TYPE_ENERGY_GIVE then
		if dayrc.energyreceivedcount >= MAX_ENERGYGET_BYDAY then
			return
		end

		dayrc.energyreceivedcount = dayrc.energyreceivedcount + 1
		return true
	end

	--同意好友添加请求
	if mail.mtype == MAIL_TYPE_FRIEND_ADD then
		self:addfriend(mail.sendroleid)

		--通知发送方添加好友
		skynet.call(world,"lua","acceptfriend",self.id,mail.sendroleid)
		return true
	end

	--自动添加好友
	if mail.mtype == MAIL_TYPE_FRIEND_ACCEPT then
		if not self:isfriend(mail.sendroleid) then
			table.insert(self.data.friends,mail.sendroleid)
		end

		return true
	end

	--排行榜奖励
	if mail.mtype == MAIL_TYPE_RANK_REWARD then
		return true
	end

	return false
end

function cclient:rejectmail(mail)
	return true
end

function cclient:isfriend(id)
	if id == self.id then
		return false
	end

	for _,fid in ipairs(self.data.friends) do
		if id == fid then
			return true
		end
	end

	return false
end

function cclient:delfriend(id)
	if not self:isfriend(id) then
		return
	end

	table.removebyvalue(self.data.friends,id)

	--notify client friend change
	self:send(208, 
		{ 
			result = 0,
			friendid = id,
		})
end

function cclient:addfriend(id)
	if id == self.id then
		return false
	end

	for _,fid in ipairs(self.data.friends) do
		if id == fid then
			return false
		end
	end

	table.insert(self.data.friends,id)

	--notify client friend change
	self:send(207, 
		{ 
			result = 0,
			friendid = id,
		})

	return true
end

function cclient:isenergyrequested(id)
	local ids = self.data.dailyrecord.energyroleids

	for _,tid in ipairs(ids) do
		if tid == id then
			return true
		end
	end
end

function cclient:cangiveenergy(id)
	if not self:isfriend(id) then
		return false
	end

	local ids = self.data.dailyrecord.energygiveroleids

	if #ids >= MAX_ENERGYGIVE_BYDAY then
		return false
	end

	for _,tid in ipairs(ids) do
		if tid == id then
			return false
		end
	end

	return true
end

function cclient:addenergygived(id)
	table.insert(self.data.dailyrecord.energygiveroleids,id)
end

function cclient:delenergygived(id)
	table.removebyvalue(self.data.dailyrecord.energygiveroleids,id)
end

function cclient:isenergygived(id)
	for _,tid in ipairs(self.data.dailyrecord.energygiveroleids) do
		if id == tid then
			return true
		end
	end

	return false
end

function cclient:addinvited(addroleid)
	local dayrc = self.data.dailyrecord
	local lst = dayrc.friendinvitelist
	local founded = false

	for _,v in ipairs(lst) do
		if v == addroleid then
			founded = true
			break
		end
	end

	if not founded then
		table.insert(lst,addroleid)
	end
end