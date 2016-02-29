--redis工具库
local skynet = require "skynet"

function make_pairs_table(t, fields)
    local data = {}
    local t2 = {}
    for i=1, #t, 2 do
        t2[t[i]] = t[i+1]
    end
    if fields then
        for i=1, #fields do
            data[fields[i]] = t2[fields[i]]
        end
    else
        data = t2
    end

    return data
end

local function redis_makeindexkey(dat, index)
    local rediskey = ""
    local fields = string.split(index, "_")

    for i, field in pairs(fields) do
        local fvalue = dat[field]
        
        if not fvalue or fvalue == "" then
            return
        end

        if i == 1 then
            rediskey = fvalue
        else
            rediskey = rediskey .. ":" .. fvalue
        end
    end

    return ":" .. rediskey
end

function convertfields(fieldtypes,data)
    for field,ftype in pairs(fieldtypes) do
        if ftype ~= "string" then
            data[field] = tonumber(data[field])
        end
    end
end

function redisquery(tbl,id,ttl)
    local fields = tbl.fields
    local key = makerediskey(tbl.name, id)
    -- local r = urcmd(id,"hmget",key,table.unpack(fields))
    local r = urcmd(id,"hgetall",key)

    if table.empty(r) then
        return
    end
    if ttl and ttl > 0 then
        urcmd(id,"expire",key,ttl)
    end
    return make_pairs_table(r,fields)
end



function redisindexquery(tbl,index,indexdat)
    local fields = tbl.fields
    local indexkey = makeredisindexkey(tbl.name ,index ,redis_makeindexkey(indexdat,index))

    local pks = rcmd("zrange", indexkey, 0, -1)
    local datas

    for _, pk in pairs(pks) do
        -- local r = urcmd(pk,"hmget", makerediskey(tbl.name,pk),table.unpack(fields))
        local r = urcmd(pk,"hgetall", makerediskey(tbl.name,pk))
        if not table.empty(r) then
            if not datas then
                datas = {}
            end
            table.insert(datas,make_pairs_table(r,fields))
        end
    end

    return datas
end
--生成redis的某个表的完整索引
--@param rdstblname string redis中表的name，see redisfields.lua中的stuct的name属性
--@param indexorgstring string 该索引的原始字符串，see redisfields.lua中的struct的index中的元素
--@param rdsindexkey string 调用redis_makeindexkey接口处理indexorgstring后的字符串
function makeredisindexkey(rdstblname, indexorgstring, rdsindexkey)
	return rdstblname .. ":index:" .. indexorgstring  .. rdsindexkey
end
--生成redis的某个表的唯一key
function makerediskey(rdstblname, id)
	return rdstblname .. ":" .. id
end
--used
--向redis中插入一条数据
--@param tbl 要插入的数据结构，参照redisfield.lua
--@param id 关键id
--@param dat 数据table
--@param ttl 失效时间，单位秒
function redisinsert(tbl,id,dat,ttl)
    --check fields
    local fields = tbl.fields
    local defaults = tbl.defaults
    local key = makerediskey(tbl.name,id)

    local tdat = {}

    for _,field in ipairs(fields) do
        local v = dat[field]

        if v then
            tdat[field] = v
            --trace("field ".. field .. " value is " .. v)
        elseif defaults[field] then
            tdat[field] = defaults[field]
            --trace("field ".. field .. " type is " .. type(defaults[field]))
            --有默认值就设置默认值
        end
        if type(tdat[field]) == "table" then
            tdat[field] = json.encode(tdat[field])
        end
    end

    urcmd(id,"hmset",key,tdat)

    if ttl and ttl > 0 then
        urcmd(id,"expire",key,ttl)
    end

    --make index key，把索引信息放到一个数组里，因为一个索引对应的数据可能有N条
    if tbl.index then
        for _,index in ipairs(tbl.index) do
            local indexvalue = redis_makeindexkey(dat,index)

            if indexvalue then
                local indexkey = makeredisindexkey(tbl.name,index, indexvalue)
                rcmd("zadd",indexkey,0,id)
            end
        end
    end

    return tdat
end
--used
--向redis中更新一条数据
--@param tbl 要更新的数据结构，参照redisfield.lua
--@param id 关键id
--@param dat 数据table
--@param ttl 失效时间，单位秒
function redisupdate(tbl,id,dat,ttl)
    --check fields
    local fields = tbl.fields
    local defaults = tbl.defaults
    local key = makerediskey(tbl.name,id)

    local tdat = {}

    for _,field in ipairs(fields) do
        local v = dat[field]

        if v then
            tdat[field] = v
        elseif defaults[field] then
            tdat[field] = defaults[field]
            --有默认值就设置默认值
        end
        if type(tdat[field]) == "table" then
            tdat[field] = json.encode(tdat[field])
        end
    end

    urcmd(id,"hmset",key,tdat)

    if ttl and ttl > 0 then
        urcmd(id,"expire",key,ttl)
    end

    return tdat
end

function redis_get(key)
    return rcmd("get",key)
end

function redis_set(key,value)
    rcmd("set",key,value)
end

