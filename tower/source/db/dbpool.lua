local skynet = require "skynet"
local mysql = require "mysql"
local json = require "json"

require "skynet.manager"

local dbpool  = {}
local CMD      = {}
local balance = 1
local running = true

local index = 3
local maxconn
--返回一个标识符为channel的mysql连接线程
local function getconn(channel)
    local db

    if channel ~= 0 then
        --write db connnection
        db = dbpool[channel]
    else
        db = dbpool[index]
        index = index + 1

        if index > maxconn then
            index = 3
        end
    end

    return db
end
--执行一句sql查询语句
function monitor(db,sql)
    local  rslt = db:query(sql)

    if DEBUG == 0 then
        if not rslt.err then
            return rslt
        else
            return {}
        end
    else
        if rslt.err then
            skynet.error(rslt.err,sql)
            return {}
        else
            return rslt
        end
    end
end

function CMD.query(sql)
    local db = getconn(0)
    return monitor(db,sql)
end
--默认使用第一次db线程执行查询语句或者语句组
--@param sql table或者string
function CMD.execute(sql)
    local db = getconn(1)

    if type(sql) == "table" then
         for _,v in ipairs(sql) do
            monitor(db,v)
        end
    else    
        monitor(db,sql)
    end
end
--保存玩家的记录
function CMD.saverecords(roleid,records)
    local db = getconn(2)

    if #records == 0 then
        return
    end

    for _,record in ipairs(records) do
        --save item log
        local ritem = record.opitem

        if ritem and #ritem > 0 then
            for _,log in ipairs(ritem) do
                local sql = string.format("INSERT INTO tbl_props_log(rtime,roleid,dataid,count,source) VALUES(FROM_UNIXTIME(%d),%d,%d,%d,%d)",
                    log.time,roleid,log.dataid,log.count,log.from)
                
                monitor(db,sql)
            end
        end
    end
end
--断开所有的db线程
function CMD.stop()
    running = false

    for _, db in pairs(dbpool) do
        db:disconnect()
    end
    dbpool = {}
end

skynet.start(function()
    maxconn = tonumber(skynet.getenv("mysql_maxconn")) + 1

    local host = skynet.getenv("mysql_host")
    local port = tonumber(skynet.getenv("mysql_port"))
    local db = skynet.getenv("mysql_db")
    local user = skynet.getenv("mysql_user")
    local password = skynet.getenv("mysql_pwd")

    local function on_connect(db)
        db:query("set charset utf8");
    end
    --初始化maxconn个db线程
    for i = 1, maxconn do
        local dbcon=mysql.connect{
                            host=host,
		  port=port,
		  database=db,
		  user=user,
		  password=password,
		  max_packet_size = 1024 * 1024,
                            on_connect = on_connect}

          if not dbcon then
                skynet.error("mysql connect error")
          else
                table.insert(dbpool, dbcon)
          end
    end

    trace("success to connect to mysql server",host,port)

    skynet.dispatch("lua", function(session, source, cmd,...)
        local f = assert(CMD[cmd], cmd .. "not found")

        if cmd == "query" then
            skynet.ret(skynet.pack(f(...)))
        else
            f(...)
        end
    end)

    --db heartbeat timer，10分钟同步一次所有查询到数据库
    skynet.fork(function()
        local sql = "SELECT max(auto_id) as id FROM tbl_server_log"

        while running do
            for i,db in ipairs(dbpool) do
                db:query(sql)
            end

            skynet.sleep(TEN_MINUTE * 100)
        end
    end)
    --注册当前服务名为dbpool
    skynet.register(".dbpool")
end)