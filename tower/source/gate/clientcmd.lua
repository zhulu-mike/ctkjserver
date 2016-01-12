local skynet = require "skynet"

--处理来自其它服务器的请求
function cclient:kick(id)
	self.kicked = true
	skynet.call(dog,"lua","close",self.fd)

	local dat = self:builddata()
	return 0,dat
end

function cclient:friendinvite(mailid,inviteroleid,invitename,inviteicon)
	if not self.running then
		return -1
	end

	local  friends = self.data.friends

	if #friends >= MAX_FRIEND_COUNT then
		return GAME_CODE_ERROR_FRIEND_TARGET_COUNT_OVERFLOW
	end

	self:addfriend(inviteroleid)
	return 0
end

function cclient:senddelfriend(delfriendid)
	if not self.running then
		return -1
	end

	self:delfriend(delfriendid)
	return 0
end

function cclient:acceptfriend(friendid)
	if not self.running then
		return -1
	end
	
	self:addfriend(friendid)
	return 0
end

function cclient:sendmail(mailid,sendroleid,sendname,sendresource,mailtype,title,content,expiredate)
	if not self.running then
		return -1
	end

	if mailtype ~= MAIL_TYPE_COMMON then
		local mail = self:getmailfrom(sendroleid,mailtype)

		--已经有这个类型的邮件，不允许多次发送
		if mail then
			return 0
		end
	end

	self:addmail(mailid,mailtype,sendroleid,sendname,sendresource,title,content,expiredate)
	return 0
end