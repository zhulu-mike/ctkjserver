local skynet = require "skynet"

local dbpool = dbpool
local redispool = redispool
local rcmd = rcmd
local urcmd = urcmd

datapool = {}
local rolecahce = {}

setmetatable(datapool,{__index = _G})
_ENV = datapool

require "dbuser"

--used
--从mysql初始化数据到redis
function initfromdb()
	trace("begin init db")
	local mintime = os.time() - 7 * ONE_DAY;
	--取出最近7天登陆的数据备份热数据到redis
	local accounts = sqlconditionquery(tbl_user,"lastlogintime>=%d",mintime)

	if accounts then
		for _,row in ipairs(accounts) do
			if LOG_LEVEL > 2 then
				trace("add tbluser to redis："+row.id)
			end
			redis_adduser(row)
		end
	end

	--载入玩家基本信息，包括userdetail表
	if accounts then
		for _,row in ipairs(accounts) do
			loaduserother(row.id)
		end
	end

	--载入其他数据


	redis_set("dbversion",1)
end

--同步数据从redis到mysql
function saveplayertosql()
	local id = redis_popsqlsavelist()

	if not id then
		return
	end

	trace("save role ",id)
	local dat = redis_getplayer(id)

	if not dat then
		return
	end

	dat.roleid = id
	local role = dat.role

	--save user
	local user = redis_loaduser(role.userid)
	sqlupdate(tbl_user,user)

	sqlupdate(tbl_role,role)
	sqlupdate(tbl_role_status,dat)
	dat.sign.roleid = id
	sqlupdate(tbl_role_sign,dat.sign)

	--mails
	local mails = dat.mails
	sqldel(tbl_role_mail,"recvroleid=%d",role.id)

	for _,mail in ipairs(mails) do
		sqlinsert(tbl_role_mail,mail)
	end

	redis_setrole_ttl(id,REDIS_PLAYER_TTL)
end

function saveplayer(dat)
	local roleid = dat.role.id

	if rolecahce[roleid] then
		rolecahce[roleid] = dat.role
	end

	redis_addplayer(dat)

	--update score
	redis_addlevelscore(roleid,dat.levelinfo)
end



function checksaveroles()
	local roles = rcmd("keys","roledetail:*")

	for _,key in ipairs(roles) do
		local ttl = rcmd("ttl",key)

		if ttl == -1 then
			local x = string.split(key,":")
			redis_addsqlsavelist(x[2])
		end
	end
end


--used
--保存数据到redis
function saveusertoredis(user)
	redis_adduser(user)
end

function savemail(mail)
	redis_addnewmail(mail)
end

function newplayer(data)
	redis_addsimplerole(data)
	sqlnewplayer(data)
end

function onnewday( ... )
	redis_updateloginlist()
	rolecahce = {}
end

return datapool