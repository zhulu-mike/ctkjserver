local skynet = require "skynet"

local dbname = skynet.getenv("mysql_db")
local schema = {}

local function get_primary_key(tbname)
    local sql = "select k.column_name " ..
        "from information_schema.table_constraints t " ..
        "join information_schema.key_column_usage k " ..
        "using (constraint_name,table_schema,table_name) " ..
        "where t.constraint_type = 'PRIMARY KEY' " ..
        "and t.table_schema= '".. dbname .. "'" ..
        "and t.table_name = '" .. tbname .. "'"
    
    local t = skynet.call(dbpool, "lua", "query",sql)
    return t[1]["column_name"]
end

local function get_fields(tbname)
    local sql = string.format("select column_name from information_schema.columns where table_schema = '%s' and table_name = '%s'", dbname, tbname)
    local rs = skynet.call(dbpool, "lua", "query", sql)
    local fields = {}

    for _, row in pairs(rs) do
        table.insert(fields, row["column_name"])
    end

    return fields
end

local function get_field_type(tbname, field)
    local sql = string.format("select data_type from information_schema.columns where table_schema='%s' and table_name='%s' and column_name='%s'",dbname, tbname, field)
    local rs = skynet.call(dbpool, "lua", "query", sql)

    return rs[1]["data_type"]
end
local function get_defaults(tbname)
    local sql = string.format("DESCRIBE %s.%s", dbname, tbname)
    local rs = skynet.call(dbpool, "lua", "query", sql)
    local defaults = {}
    for _, row in pairs(rs) do
        defaults[row["Field"]] = row["Default"]
        if LOG_LEVEL > 1 and row["Default"] ~= nil then
            print(row["Field"] .. " default value is：" .. row["Default"])
        elseif LOG_LEVEL > 1 then
            print(row["Field"] .. " default value is：nil")
        end
    end
    return defaults
end

--make sql accroding fields
local function makequerysql(tblname)
    local tbl = schema[tblname]

    if not tbl then
        skynet.error(string.format("can load table[%s] schema",tblname))
        return
    end

    local fields = tbl.fields
    local pkey = tbl.pk

    --select
    local sql = ""

    for field,fi in pairs(fields) do
        if sql ~= "" then
            sql = sql .. ","
        end

        if fi == "date" then
            sql = sql .. string.format("UNIX_TIMESTAMP(%s) as %s",field,field)
        else
            sql = sql .. field
        end
    end

    sql = "SELECT " .. sql .. " FROM " .. tblname .. " WHERE "
    return sql
end

local function makeinsertsql(tblname)
    local tbl = schema[tblname]

    if not tbl then
        skynet.error(string.format("can load table[%s] schema",tblname))
        return
    end

    local fields = tbl.fields
    local pkey = tbl.pk

    --insert
    local sql = ""

    for field,_ in pairs(fields) do
        if sql ~= "" then
            sql = sql .. ","
        end

        sql = sql .. field
    end

    sql = sql .. ") VALUES("

    local sql2 = ""

    for _,fi in pairs(fields) do
        if sql2 ~= "" then
            sql2 = sql2 .. ","
        end

        if fi == "date" then
            sql2 = sql2 .. "FROM_UNIXTIME(%d)"
        elseif fi == "string" then
            sql2 = sql2 .. "\'%s\'"
        else
            sql2 = sql2 .. "%d"
        end
    end

    sql = "INSERT INTO " .. tblname .. "(" .. sql .. sql2 .. ")"
    return sql
end

function makeupdatesql(tblname,fields)
    local tbl = schema[tblname]

    if not tbl then
        skynet.error(string.format("can load table[%s] schema",tblname))
        return
    end

    local tblfields = tbl.fields

    for _,field in pairs(fields) do
        if not tblfields[field] then
            skynet.error(string.format("can load table[%s] field[%s]",tblname,field))
            return
        end
    end

    local pkey = tbl.pk

    --update
    local sql = ""

    for _,field in pairs(fields) do
        if field ~= pkey then
            local fi = tblfields[field]

            if sql ~= "" then
                sql = sql .. ","
            end

            if fi == "date" then
                sql = sql .. string.format("%s=",field) .. "FROM_UNIXTIME(%d)"
            elseif fi == "string" then
                sql = sql .. string.format("%s=",field) .. "\'%s\'"
            else
                sql = sql .. string.format("%s=",field) .. "%d"
            end
        end
    end

    sql = "UPDATE " .. tblname .. " SET " .. sql
    return sql
end

--初始化数据库表和字段的信息，自动获取所有的表名
function load_dbschemas()
    local sql = "select table_name from information_schema.tables where table_schema='" .. dbname .. "'"
    local rs = skynet.call(dbpool,"lua", "query", sql)

    for _, row in pairs(rs) do
        local tbname =row.table_name
        _G[tbname] = {}
        local deftbl = _G[tbname]

        schema[tbname] = {}
        schema[tbname]["fields"] = {}
        schema[tbname]["pk"] = get_primary_key(tbname)
        schema[tbname]["defaults"] = get_defaults(tbname)

        local fields = get_fields(tbname)

        for _, field in pairs(fields) do
            local field_type = get_field_type(tbname, field)

            if field_type == "char"
              or field_type == "varchar"
              or field_type == "tinytext"
              or field_type == "text"
              or field_type == "mediumtext"
              or field_type == "longtext" then
                schema[tbname]["fields"][field] = "string"
            elseif field_type == "datetime" then
                schema[tbname]["fields"][field] = "date"
            else
                schema[tbname]["fields"][field] = "number"
            end
        end

        deftbl.name = tbname
        deftbl.schema = schema[tbname]

        deftbl.query  = makequerysql(tbname)
        deftbl.insert = makeinsertsql(tbname)
    end
end
--向数据库表中插入一条新记录
--@param tbl load_dbschemas中创建的关于数据表的结构实例
--@param dat 要存储的字段和数值
function sqlinsert(tbl,dat)
    local tblschema = tbl.schema
    local fields = tblschema.fields
    local defaults = tblschema.defaults

    for field,fi in pairs(fields) do
        if not dat[field] then
            if not defaults[field] then
                dat[field] = defaults[field]
            elseif fi == "date" then
                dat[field] = os.time()
            elseif fi == "string" then
                dat[field] = ""
            else
                dat[field] = 0
            end
        end
    end

    local sql = tbl.insert
    local values = {}

    for field,_ in pairs(fields) do
        table.insert(values,dat[field])
    end

    sql = string.format(sql,table.unpack(values))
    skynet.send(dbpool,"lua","execute",sql)
end

--执行有条件的更新sql语句
function sqlupdate(tbl,dat,where,...)
    local tblschema = tbl.schema

    --build query whene first use
    if not tbl.update then
        local fields = {}

        for k,v in pairs(dat) do
            if tblschema.fields[k] then
                table.insert(fields,k)
            end
        end

        tbl.fields = fields
        tbl.update = makeupdatesql(tbl.name,fields)
    end

    --check init fields
    local fields = tbl.fields

    for _,field in ipairs(fields) do
        if not dat[field] then
            local fi = tblschema.fields[field]

            if fi == "date" then
                dat[field] = os.time()
            elseif fi == "string" then
                dat[field] = ""
            else
                dat[field] = 0
            end
        end
    end

    local sql = tbl.update
    local values = {}

    for _,field in ipairs(fields) do
        if field ~= tblschema.pk then
            local v = dat[field]

            if type(v) == "table" then
                v = json.encode(v)
            end

            table.insert(values,v)
        end
    end

    sql = string.format(sql,table.unpack(values))
    local wherestr

    if where then
        wherestr = string.format(where,...)
    else
        local pk = tblschema.pk
        local fi = tblschema.fields[pk]

        if fi == "string" then
            wherestr = string.format("WHERE %s=\'%s\'",pk,dat[pk])
        else
            wherestr = string.format("WHERE %s=%d",pk,dat[pk])
        end
    end

    sql = sql .. " " .. wherestr
    skynet.send(dbpool,"lua","execute",sql)
end

--执行有条件的查询sql语句
function sqlconditionquery(tbl,where,...)
    local wherestr = string.format(where,...)

    local sql = tbl.query .. " " .. wherestr
    return skynet.call(dbpool,"lua","query",sql)
end
--执行有条件的删除sql语句
function sqldel(tbl,id,where,...)
    local sql = "DELETE FROM " .. tbl.name
    local tblschema = tbl.schema
    local wherestr

    if where then
        wherestr = "WHERE " .. string.format(where,...)
    else
        local pk = tblschema.pk
        local fi = tblschema.fields[pk]

        if fi == "string" then
            wherestr = string.format("WHERE %s=\'%s\'",pk,id)
        else
            wherestr = string.format("WHERE %s=%d",pk,id)
        end
    end

    sql = sql .. " " .. wherestr
    skynet.send(dbpool,"lua","execute",sql)
end

function sqlquery(tbl,id)
    local sql = tbl.query
    local tblschema = tbl.schema
    local wherestr

    local pk = tblschema.pk
    local fi = tblschema.fields[pk]

    if fi == "string" then
        wherestr = string.format("%s=\'%s\'",pk,id)
    else
        wherestr = string.format("%s=%d",pk,id)
    end

    sql = sql .. " " .. wherestr
    return skynet.call(dbpool,"lua","query",sql)
end

--used
--从表中获取一条记录
function sqlfetchone(tbl,id)
    local sql = tbl.query
    local tblschema = tbl.schema
    local wherestr

    local pk = tblschema.pk
    local fi = tblschema.fields[pk]

    if fi == "string" then
        wherestr = string.format("%s=\'%s\'",pk,id)
    else
        wherestr = string.format("%s=%d",pk,id)
    end

    sql = sql .. " " .. wherestr
    local rs = skynet.call(dbpool,"lua","query",sql)
    if #rs > 0 then
        return rs[1]
    end
    return nil
end

