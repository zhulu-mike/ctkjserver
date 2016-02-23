------------client manager
local skynet = require "skynet"
require("json")

--一个用户的数据结构
cclient = class("cclient")
--[[
data{
	detail:{},
	heros:{},
	rds:{},
	timeinfo:{}
}
]]--

function cclient:ctor()
	self.loging = false
	self.data = nil
	self.kicked = false
	self.error = false
	self.disconnect = false
	self.running = false
	self.authtimer = 0
	self.savetimer = 0
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
function cclient:onlogin(uid,detail)
	trace("user [" .. detail.userid .."] login")

	self.uid   = uid
	self.id     = detail.userid
	self.userid = detail.userid
	self.name     = detail.nickname
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
		local data = self:buildalldata()
		--把数据存储到world模块
		if data then
			trace("user " .. self.data.detail.userid .. " ondisconnect, sync data to world:" .. json.encode(data))
			skynet.call(world,"lua","lostclient",self.uid,data)
			self:resetdatastate()
		end
	end
end
--used
--生成玩家全部的数据
function cclient:buildalldata()
	local data = self.data

	if not data or not data.detail.userid then
		return
	end
	return self.data
end
--used
--生成玩家更改过的数据
function cclient:builddata()
	local  curtime = os.time()
	local data = self.data

	if not data or not data.detail.userid then
		return
	end

	--return create player data
	local playerdata = {}
	local flag = false
	if data.detail.invalid then
		flag = true
		playerdata.detail = data.detail
	end
	if data.heros.invalid then
		flag = true
		playerdata.heros = data.heros
	end
	if data.rds.invalid then
		flag = true
		playerdata.rds = data.rds
	end
	if data.timeinfo.invalid then
		flag = true
		playerdata.timeinfo = data.timeinfo
	end
	if flag then
		return playerdata
	else
		return
	end
end
--重置所有数据的状态
function cclient:resetdatastate( )
	self.data.detail.invalid = false
	self.data.detail.lastversion = self.data.detail.version
	self.data.heros.invalid = false
	self.data.heros.lastversion = self.data.heros.version
	self.data.rds.invalid = false
	self.data.rds.lastversion = self.data.rds.version
	self.data.timeinfo.invalid = false
	self.data.timeinfo.lastversion = self.data.timeinfo.version
end
--每天凌晨初始化数据
function cclient:resetdayrecord(dayid)

end

function cclient:onnewday(dayid)
	--reset daily records
	self:resetdayrecord(dayid)
end
--同步数据到db
function cclient:syncdata(data)
	local resp = skynet.send(db,"lua","saveplayer",self.uid,data)
	self:resetdatastate()
	return resp
end

function cclient:update(delta)
	if self.disconnect then
		return
	end
	if self.running then
		self.savetimer = self.savetimer + delta
		--每隔几秒更新一次
		if self.savetimer >= PLAYER_SAVE_INTERVAL then
			local data = self:builddata()
			if not data then
				return
			end
			self.savetimer = 0
			trace("sync data to redis, uid is :" .. self.uid .. ",data is :" .. json.encode(data))
			local ok = self:syncdata(data)
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



