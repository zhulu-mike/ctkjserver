local skynet = require "skynet"
require "rediscore"



--used
function redis_loaduser(id)
    local r = redisquery(redis_user,id)

    if r then
        convertfields(tbl_user.schema.fields,r)
    end

    return r
end
--used
function redis_loaduserbyname(account,serverid,qudaoid)
    local r = redisindexquery(redis_user,redis_user.index[1],
        {
            username = account,
            serverid = serverid,
            qudao = qudaoid
        })

    if r and #r > 0 then
        r = r[1]
        convertfields(tbl_user.schema.fields,r)
    end

    return r
end
--used
function redis_loaduserbybindaccount(account,serverid,qudaoid)
    local r = redisindexquery(redis_user,redis_user.index[2],
        {
            binduname = account,
            serverid = serverid,
            qudao = qudaoid
        })

    if r and #r > 0 then
        r = r[1]
        convertfields(tbl_user.schema.fields,r)
    end

    return r
end


function redis_addsimplerole(dat)
    redisinsert(redis_role,dat.id,dat)
end


function redis_setrole_ttl(id,ttl)
    local key = redis_role_detail.name .. ":" .. id

    if ttl == 0 then
        urcmd(id,"PERSIST",key)
    else
        urcmd(id,"EXPIRE",key,ttl)
    end
end

function redis_getsimplerole(id)
    local r = redisquery(redis_role,id)

    --auto convert
    if r then
        convertfields(tbl_role.schema.fields,r)
    end

    return r
end


function redis_fetchnewmails(id)
    local tbl = redis_role_offlinemail
    local r = redisindexquery(tbl,tbl.index[1],
        {
            recvroleid = id
        })

    if not r then
        r = {}
    else
        --clear newmails
        local indexkey = tbl.name .. ":index:recvroleid:" .. id
        local delkeys = {indexkey}

        for _,mail in ipairs(r) do
            convertfields(tbl_role_mail.schema.fields,mail)
            table.insert(delkeys,redis_role_offlinemail.name .. ":" .. mail.id)
        end

        rcmd("DEL",table.unpack(delkeys))
    end

    return r
end

function redis_addnewmail(mail)
    local ttl

    if mail.expiredate ~= -1 then
        ttl = mail.expiredate - os.time()
    end
    
    redisinsert(redis_role_offlinemail,mail.id,mail,ttl)
end

function redis_addsqlsavelist(id)
    rcmd("sadd","player_savelist",id)
end

function redis_removesqlsavelist(id)
    rcmd("srem","player_savelist",id)
end

function redis_popsqlsavelist()
    local r = rcmd("spop","player_savelist")

    if r then
        r = tonumber(r)
    end

    return r
end

function redis_addloginrole(roleid,logintime)
    rcmd("zadd","loginlist",logintime,roleid)
end

function redis_updateloginlist()
    rcmd("ZREMRANGEBYRANK","loginlist",0,-201)
end

function redis_getloginroles(count)
    local n = rcmd("ZCARD","loginlist")

    if n == 0 then
        return
    end

    local r

    if n <= count then
        r = rcmd("ZREVRANGE","loginlist",0,-1)
    else
        local offset = math.random(0,n - count)
        r = rcmd("ZREVRANGE","loginlist",offset,offset + count - 1)
    end

    return r
end

function redis_addlevelscore(roleid,levelinfo)
    local t = {}

    for _,li in ipairs(levelinfo) do
        local score = li[2]

        if score > 0 then
            t[li[1]] = score
        end
    end

    if table.empty(t) then
        return
    end

    local key = "rolelevelscore:" .. roleid
    rcmd("hmset",key,t)
end

function redis_getlevelscore(roleid,level)
    local key = "rolelevelscore:" .. roleid
    local score = rcmd("hget",key,level)

    if not score then
        score = 0
    end

    return tonumber(score)
end

function redis_getexchangecode(code)
    local key = "exchangecode"
    local index = rcmd("hget",key,code)

    if not index then
        return
    end

    rcmd("hdel",key,code)
    rcmd("sadd","exchangecodeused",code)
    return tonumber(index)
end

-------------wjl----------------
--used
--向redis中添加一条tbl_user的记录
function redis_adduser(dat)
    return redisinsert(redis_user,dat.id,dat)
end
--把一条userdetail数据加载到redis中
function redis_adduserdetail( data )
    return redisinsert(redis_userdetail,data.userid,data)
end
--used
function redis_getuserdetail(id)
    local data = redisquery(redis_userdetail,id)

    if not data then
        return
    end
    convertfields(tbl_userdetail.schema.fields,data)
    return detail
end
--used
--获取usertime表的数据
function redis_getusertime(id)
    local data = redisquery(redis_usertime,id)

    if not data then
        return
    end
    convertfields(tbl_usertime.schema.fields,data)
    return data
end
--把一条usertime数据加载到redis中
function redis_addusertime( data )
    return redisinsert(redis_usertime,data.userid,data)
end

--used
--获取userheros表的数据
function redis_getuserheros(id)
    local data = redisquery(redis_userheros,id)

    if not data then
        return
    end
    convertfields(tbl_userheros.schema.fields,data)
    return data
end
--把一条userheros数据加载到redis中
function redis_adduserheros( data )
    return redisinsert(redis_userheros,data.userid,data)
end

--used
--获取userrounds表的数据
function redis_getuserrounds(id)
    local data = redisquery(redis_userrounds,id)

    if not data then
        return
    end
    convertfields(tbl_userrounds.schema.fields,data)
    return data
end
--把一条userrounds数据加载到redis中
function redis_adduserrounds( data )
    return redisinsert(redis_userrounds,data.userid,data)
end
