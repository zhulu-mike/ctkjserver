local skynet = require "skynet"

mailmanager = {}
setmetatable(mailmanager,{__index = _G})
_ENV = mailmanager

local uid = 1

function genuid()
	uid = uid + 1;
	local  id = ((worldid & 0xFFFF) << 48) | ((os.time() & 0x00000000FFFFFFFF) << 16) | (uid & 0x0000FFFF)
	return id
end

function hasmail(mails,sendid,mailtype)
	for _,mail in ipairs(mails) do
		if mail.sendroleid == sendid and mail.mtype == mailtype then
			return true
		end
	end
end

function add(sender,mailtype,recvid,title,content,expiredate)
	if not sender then
		sender = 0
	end

	local mail = 
	{
		id = genuid(),
		mtype = mailtype,
		senddate = os.time(),
		sendroleid = sender,
		sendname = "",
		sendresource = "",
		recvroleid = recvid,
		title = title,
		content = content,
		status = MAIL_STATUS_UNREAD,
		expiredate = expiredate,
	}

	if expiredate ~= -1 then
		mail.expiredate = os.time() + expiredate
	else
		mail.expiredate = os.time() + ONE_MONTH * 3
	end

	local user = usermanager.getuserbyrole(recvid)

	if user and user.playerdata then
		local mails = user.playerdata.mails

		if mailtype ~= MAIL_TYPE_COMMON and sender ~= 0 then
			if hasmail(mails,sender,mailtype) then
				return
			end
		end

		table.insert(mails,mail)
	else
		skynet.send(db,"lua","savemail",mail)
	end
end