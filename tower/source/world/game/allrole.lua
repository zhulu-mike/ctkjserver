--all roles simple info
local skynet = require "skynet"

allrole = {}
setmetatable(allrole,{__index = _G})
_ENV = allrole

function getrole(id)
	if not id or id <= 0 then
		return
	end
	
	return skynet.call(db,"lua","loadsimplerole",id)
end