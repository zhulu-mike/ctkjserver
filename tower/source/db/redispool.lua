local skynet = require "skynet"
require "skynet.manager"
local redis = require "redis"

local CMD = {}
local pool = {}

local maxconn
--获取一个redis的线程
--@param uid 线程的标识
--@return redis
local function getconn(uid)
	local db

	if not uid or maxconn == 1 then
		db = pool[1]
	else
		db = pool[uid % (maxconn - 1) + 2]
	end

	return db
end
--初始化maxconn个redis通信线程
function CMD.start()
	maxconn = tonumber(skynet.getenv("redis_maxinst")) or 1
	for i = 1, maxconn do
		local db = redis.connect{
			host = skynet.getenv("redis_host" .. i),
			port = skynet.getenv("redis_port" .. i),
			db = 0,
			auth = skynet.getenv("redis_auth" .. i),
		}

		if db then
			--测试期，清理redis数据
			--db:flushdb()
			table.insert(pool, db)
		else
			skynet.error("redis connect error")
		end
	end

	print("success "..maxconn.." to connect to redis server")
end
--一次设置一组key-value值
--@param uid redis线程标识符
--@param key redis的关键key
--@param t 要存储的数据table
--@return void 
function CMD.hmset(uid, key, t)
	local data = {}
	for k, v in pairs(t) do
		table.insert(data, k)
		table.insert(data, v)
	end

	local db = getconn(uid)
	local result = db:hmset(key, table.unpack(data))

	return result
end
--设置该服务启动时的回调，其实就是设置消息处理接口
skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd,uid,key,...)
		--接到消息后，先去CMD里面找，如果找不到，则直接调用redis的命令。
		local f = CMD[cmd]

		if f then
			skynet.retpack(f(uid,key,...))
		else
			--auto dispath
			local db = getconn(uid)
			local r = db[cmd](db,key,...)
			skynet.retpack(r)
		end	
	end)

	skynet.register(".redispool")
end)
