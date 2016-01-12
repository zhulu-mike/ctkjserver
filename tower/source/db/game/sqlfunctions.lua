local skynet = require "skynet"


function sqlloadplayeridsbyaccount(userid)
    local  sql = string.format("SELECT id FROM tbl_user WHERE id=%d",userid)
    local data = skynet.call(dbpool,"lua","query",sql)
    return data
end
--获取用户表中最大的userid
function sqlgetmaxroleid()
    local  sql = "SELECT max(id) as maxroleid FROM tbl_user"
    local data = skynet.call(dbpool,"lua","query",sql)

    if #data > 0 then
        return data[1].maxroleid
    else
        return 0
    end
end

--创建角色
function sqlnewplayer(data)
    local sqls = {}

    local  sql = string.format("INSERT INTO tbl_role(id,userid) VALUES(%d,%d)",data.id,data.userid)
    table.insert(sqls,sql)

    sql = string.format("INSERT INTO tbl_role_status(roleid) VALUES(%d)",data.id)
    table.insert(sqls,sql)

    sql = string.format("INSERT INTO tbl_role_sign(roleid) VALUES(%d)",data.id)
    table.insert(sqls,sql)

    sql = string.format("UPDATE tbl_user SET roleid=%d WHERE id=%d",data.id,data.userid)
    table.insert(sqls,sql)

    skynet.send(dbpool,"lua","execute",sqls)
end