local skynet = require "skynet"

local rcmd = rcmd
_ENV = CMD

function rank_create(rankid)
	local key = "rank:" .. rankid
	rcmd("del",key)	
	rcmd("zadd",key,0,0)

	key = "ranktime:" .. rankid
	redis_set(key,os.time())
end

function rank_add(rankid,roleid,score)
	local key = "rank:" .. rankid

	if not rcmd("EXISTS",key) then
		return
	end

	rcmd("zadd",key,score,roleid)
end

function rank_hasrole(rankid,roleid)
	local score = rank_getscore(rankid,roleid)

	if score ~= -1 then
		return true
	else
		return false
	end
end

function rank_remove(rankid,roleid)
	local key = "rank:" .. rankid
	rcmd("zrem",key,roleid)
end

function rank_getscore(rankid,roleid)
	local key = "rank:" .. rankid
	local r = rcmd("ZSCORE",key,roleid)

	if not r then
		r = -1
	end

	return tonumber(r)
end

function rank_getposition(rankid,roleid)
	local key = "rank:" .. rankid
	local r = rcmd("ZREVRANK",key,roleid)

	if not r then
		r = -1
	end

	return tonumber(r)
end

function rank_getrangeandscore(rankid,from,to)
	local key = "rank:" .. rankid
	local t = rcmd("zrevrange",key,from,to,"WITHSCORES")

	if not t then
		return
	end

	local n = #t
	local r = {}
	local rank = 1

	for i=1, n, 2 do
		local x = t[i]
		table.insert(r,{tonumber(x),rank,tonumber(t[i+1])})
		rank = rank + 1
	end
	
	return r
end

function rank_getrange(rankid,from,to)
	local r = rank_getrangeandscore(rankid,from,to)

	if not r then
		return
	end

	for _,v in ipairs(r) do
		local role = datapool.getrole(v[1])

		if role then
			v[4] = role
		end
	end

	return r
end


