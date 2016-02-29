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
--used
--同步数据从redis到mysql
--每隔5秒钟同步一次
function saveplayertosql()
	local userid = redis_popsqlsavelist()

	if not userid then
		return
	end
	trace("save user to sql:",userid)
	local data = redis_getuserdata(userid, redis_userdetail, tbl_userdetail)
	sqlupdate(tbl_userdetail,data)

	data = redis_getuserdata(userid, redis_usertime, tbl_usertime)
	sqlupdate(tbl_usertime,data)

	data = redis_getuserdata(userid, redis_userheros, tbl_userheros)
	-- trace(data.heros)
	sqlupdate(tbl_userheros,data)

	data = redis_getuserdata(userid, redis_userrounds, tbl_userrounds)
	sqlupdate(tbl_userrounds,data)

	data = redis_getuserdata(userid, redis_userstore, tbl_userstore)
	sqlupdate(tbl_userstore,data)

	data = redis_getuserdata(userid, redis_userprogress, tbl_userprogress)
	sqlupdate(tbl_userprogress,data)

	data = redis_loaduser(userid)
	sqlupdate(tbl_user,data)


end

function saveplayer(dat)

end


--used
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


function onnewday( ... )
	rolecahce = {}
end

function saveserverlog(onlinecount)
	sqlinsert(tbl_server_log,{time=os.time(), online=onlinecount})
end

return datapool