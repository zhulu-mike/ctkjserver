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


-------------wjl----------------
--used
--向redis中添加一条tbl_user的记录
function redis_adduser(dat)
    return redisinsert(redis_user,dat.id,dat,REDIS_PLAYER_TTL)
end
--把一条userdetail数据加载到redis中
function redis_adduserdetail( data )
    return redisinsert(redis_userdetail,data.userid,data,REDIS_PLAYER_TTL)
end
--used
function redis_getuserdetail(id)
    local data = redisquery(redis_userdetail,id,REDIS_PLAYER_TTL)

    if not data then
        return
    end
    convertfields(tbl_userdetail.schema.fields,data)
    return data
end
--used
--获取usertime表的数据
function redis_getusertime(id)
    local data = redisquery(redis_usertime,id,REDIS_PLAYER_TTL)

    if not data then
        return
    end
    convertfields(tbl_usertime.schema.fields,data)
    return data
end
--把一条usertime数据加载到redis中
function redis_addusertime( data )
    return redisinsert(redis_usertime,data.userid,data,REDIS_PLAYER_TTL)
end

--used
--获取userheros表的数据
function redis_getuserheros(id)
    local data = redisquery(redis_userheros,id,REDIS_PLAYER_TTL)

    if not data then
        return
    end
    convertfields(tbl_userheros.schema.fields,data)
    return data
end
--把一条userheros数据加载到redis中
function redis_adduserheros( data )
    return redisinsert(redis_userheros,data.userid,data,REDIS_PLAYER_TTL)
end

--used
--获取userrounds表的数据
function redis_getuserrounds(id)
    local data = redisquery(redis_userrounds,id,REDIS_PLAYER_TTL)

    if not data then
        return
    end
    convertfields(tbl_userrounds.schema.fields,data)
    return data
end
--把一条userrounds数据加载到redis中
function redis_adduserrounds( data )
    return redisinsert(redis_userrounds,data.userid,data,REDIS_PLAYER_TTL)
end
