--all accounts info
local skynet = require "skynet"

local accounts = {}
local usersbyaccount = {}
local usersbybindaccount = {}

allacc = {}
setmetatable(allacc,{__index = _G})
_ENV = allacc

function bind(data)
	accounts[data.user.id] = data

	--by accountname
	local key = data.user.username
	if key ~= "" then
		local t = usersbyaccount[key]

		if not t then
			usersbyaccount[key] = data
		end
	end

	if not data.bindaccount then
		data.bindaccount = ""
	end
	key = data.user.binduname
	--by bindaccount
	if key ~= "" then
		local t = usersbybindaccount[key]

		if not t then
			usersbybindaccount[key] = data
		end
	end
end

function getaccount(id)
	if not id or id <= 0 then
		return
	end

	local user = accounts[id]

	if not user then
		user = skynet.call(db,"lua","loaduser",id)

		if not user then
			return
		else
			bind(user)
		end
	end

	return 	user
end

function hasaccount(id)
	if accounts[id] ~= nil then
		return true
	else
		return false
	end
end

--使用绑定账户登陆
local function getbybindaccount(accountname,serverid,qudaoid)
	local key = table.implode({accountname,qudaoid,serverid},"_");
	local account = usersbybindaccount[key]

	if account then
		return account
	end
	local account = skynet.call(db,"lua","loaduserbybindaccount",accountname,serverid,qudaoid)
	-- if account then
	-- 	print("allacc.getbybindaccount." .. table.serialize(account))
	-- else
	-- 	print("getbybindaccount no account")
	end
	if account then
		bind(account)
	end
	return account
end
--使用用户名登陆
local function getbyaccountname(accountname,serverid,qudaoid)
	local key = table.implode({accountname,qudaoid,serverid},"_");
	local account = usersbyaccount[key]

	if account then
		return account
	end

	local account = skynet.call(db,"lua","loaduserbyname",accountname,serverid,qudaoid)

	if account then

		bind(account)
	end
	return account
end
--获取用户账户数据
function getbyaccount(accountname,bindaccount,serverid,qudaoid)
	if not bindaccount or bindaccount == 0 then
		bindaccount = ""
	end
	local acc
	--使用绑定账户登陆
	if bindaccount ~= "" then
		acc = getbybindaccount(bindaccount,serverid,qudaoid)
	end

	if acc then 
		return acc
	end
	--使用用户名登陆
	acc = getbyaccountname(accountname,serverid,qudaoid)

	if not acc then
		return
	end

	if bindaccount ~= "" then
		--帐号是否已绑定
		if acc.user.binduname and accc.user.binduname ~= "" then
			if accc.user.binduname ~= bindaccount  then
				return
			end
		end

		accc.user.binduname = bindaccount
		bind(acc)
	end

	return acc
end

function add(userid,data)
	bind(data)
	return data
end

function remove(id)
	local user = accounts[id]

	if not user then
		return
	end

	usersbyaccount[user.user.username] = nil
	usersbybindaccount[user.user.binduname] = nil
	accounts[id] = nil
end