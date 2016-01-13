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

	--account data
	self.id = 0 			--用户id
	self.account = nil
	self.lastdeviceid = "" 		--最后设备ID

	--player data
	-- self.playerdata = nil
end
--used
--登陆
function conlineuser:onlogin()
	self.disconnecttime = 0
end
--used
--在线玩家下线时，保存一次数据
function conlineuser:onremove()
	skynet.send(db,"lua","saveuser",self.account)
	allacc.remove(self.id)
end
--used
--当失去链接超过ONLINE_USER_KICKTIME时间后，销毁自身
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

--used
function conlineuser:send( ... )
	local ok,r1,r2,r3 = pcall(cluster.call,self.gate,self.agent,self.agentid,...)
	
	if not ok then
		return -1
	end

	return r1,r2,r3
end

--used
--断开链接
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





