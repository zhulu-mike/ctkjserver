-----------------------
--login user data

local skynet = require "skynet"
local cluster = require "cluster"

local conlineuser = class("onlineuser")

function conlineuser:ctor()
	--gate data
	self.gate    = ""
	self.agent   = nil
	self.agentid = 0
	self.seq     = 0
	self.online  = false
	self.disconnecttime = 0
	self.uid = 0
	self.roleid = 0

	--account data
	self.id = 0 			--用户id
	self.account = nil
	self.lastdeviceid = "" 		--最后设备ID

	--player data
	self.playerdata = nil
end

function conlineuser:onlogin()
	self.disconnecttime = 0
end

function conlineuser:onremove()
	skynet.send(db,"lua","saveuser",self.account)
	self:save()
	allacc.remove(self.id)
end

function conlineuser:update(delta)
	if not self.online then
		self.disconnecttime = self.disconnecttime + delta

		if self.disconnecttime >= ONLINE_USER_KICKTIME then
			self:onremove()
			return false
		end
	end

	return true
end

function conlineuser:save()
	if self.playerdata then
		skynet.send(db,"lua","saveplayer",self.uid,self.playerdata)
		self.playerdata = nil
	end
end

function conlineuser:send( ... )
	local ok,r1,r2,r3 = pcall(cluster.call,self.gate,self.agent,self.agentid,...)
	
	if not ok then
		return -1
	end

	return r1,r2,r3
end

function conlineuser:ondisconnect()
	self.online = false
	self.disconnecttime = 0

	local acc = self.account

	acc.lastlogouttime = os.time()
	local delta = acc.lastlogouttime - acc.lastlogintime

	if delta > 0 then
		acc.totalonlinetime = acc.totalonlinetime + delta
	end
end

return conlineuser





