--user manager pool
local skynet = require "skynet"

local users = {}
local uid = 1
local serverlogtimer = 0

usermanager = {}
setmetatable(usermanager,{__index = _G})
_ENV = usermanager
--used
function genuid()
	uid = uid + 1;
	local  id = ((worldid & 0xFFFF) << 48) | ((os.time() & 0x00000000FFFFFFFF) << 16) | (uid & 0x0000FFFF)

	if allacc.hasaccount(id) then
		skynet.sleep(1)
		return genuid()
	else
		return id
	end
end
--used
function getuserbyaccountandserver(account,bindaccount,serverid,qudaoid)
	local acc = allacc.getbyaccount(account,bindaccount,serverid,qudaoid)
	if not acc then
		return
	end
	return getuser(acc.id)
end
--used
function getuser(id)
	return users[id]
end

function getuserbyrole(roleid)
	if roleid <= 0 then
		return
	end

	local ri = allrole.getrole(roleid)

	if not ri then
		return
	end

	local user = getuser(ri.userid)

	if not user or user.roleid ~= roleid then
		return
	end

	return user
end

function isroleonline(roleid)
	local user = getuserbyrole(roleid)

	if user and user.online then
		return true
	end

	return false
end
--used
function add(user)
	users[user.id] = user
end


function login(user)
	local acc = user.account
	acc.lastlogintime = os.time()

	user:onlogin()

	return true
end
--used
function logout(user)
	users[user.id] = nil
end

function update(delta)
	local count = 0

	for id,user in pairs(users) do
		local ok,r = pcall(user.update,user,delta)

		if not r then
			users[id] = nil
		end

		count = count  + 1
		
		if (count % 1000) == 0 then
			skynet.yield()
		end
	end

	--create server log every 10 min
	serverlogtimer = serverlogtimer + delta
	if serverlogtimer > 600 then
		serverlogtimer = 0
		pcall(skynet.send,db,"lua","saveserverlog",usermanager.onlinecount())
	end
end

function onclose()
	for id,user in pairs(users) do
		user:save()
	end
end

function onlinecount()
	local count = 0

	for _,user in pairs(users) do
		if user.online then
			count = count + 1
		end
	end

	return count
end