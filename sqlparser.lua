#!/usr/bin/env tarantool

local fio = require("fio")
local ffi = require("ffi")
local parserConst = require("sqlparserConst")
local sqlgen = require("sqlgen")

local hFilePath = debug.getinfo(1, "S").source
hFilePath = fio.dirname(hFilePath:sub(2))
hFilePath = fio.pathjoin(hFilePath, "LuaDataTypes.h")

local hFile, err = fio.open(hFilePath, "O_RDONLY")
if hFile == nil then
    error(("Can not open file '%s': %s"):format(hFilePath, tostring(err)))
end

local ok, cDefs = pcall(hFile.read, hFile)
hFile:close()

if not ok then
    error(cDefs)
end

ffi.cdef(cDefs)

ffi.cdef[[
LuaSQLParserResult* parseSql(const char* query);
void finalize(LuaSQLParserResult* result);
]]

local package = package.search("libsqlparser")
local sqlParserLib = ffi.load(package)

local getExpr
local getExprArr
local getJoinDefinition
local getAlias
local getTableRef
local getGroupByDescription
local getSetOperation
local getOrderDescription
local getWithDescription
local getLimitDescription
local getSelectStatement
local getSQLStatement
local getSQLParserResult

local function getArr(cdata, count, getItem, params)
    if cdata == nil then
        return nil
    end

    count = tonumber(count)

    local arr = { }
    for i = 0, count - 1 do
        table.insert(arr, getItem(cdata[i], params))
    end

    return arr
end

local function getStr(cdata)
    if cdata == nil then
        return nil
    end

    return ffi.string(cdata)
end

getExpr = function(cdata, params)
    if cdata == nil then
        return nil
    end

    local expr = { }

    expr.type = tonumber(cdata.type)
    if expr.type == parserConst.ExprType.kExprParameter then
        table.insert(params, expr)
    end

    expr.expr = getExpr(cdata.expr, params)
    expr.expr2 = getExpr(cdata.expr2, params)
    expr.exprList = getExprArr(cdata.exprList, cdata.exprListSize, params)

    expr.select = getSelectStatement(cdata.select, params)

    expr.name = getStr(cdata.name)
    expr.table = getStr(cdata.table)
    expr.alias = getStr(cdata.alias)
    expr.fval = tonumber(cdata.fval)
    expr.ival = tonumber(cdata.ival)
    expr.ival2 = tonumber(cdata.ival2)
    expr.datetimeField = tonumber(cdata.datetimeField)
    expr.isBoolLiteral = cdata.isBoolLiteral

    expr.opType = tonumber(cdata.opType)
    expr.distinct = cdata.distinct

    return expr
end

getExprArr = function(cdata, count, params)
    return getArr(cdata, count, getExpr, params)
end

getJoinDefinition = function(cdata, params)
    if cdata == nil then
        return nil
    end

    local joinDefinition = { }

    joinDefinition.left = getTableRef(cdata.left, params)
    joinDefinition.right = getTableRef(cdata.right, params)
    joinDefinition.condition = getExpr(cdata.condition, params)

    joinDefinition.type = tonumber(cdata.type)

    return joinDefinition
end

getAlias = function(cdata)
    if cdata == nil then
        return nil
    end

    local alias = { }

    alias.name = getStr(cdata.name)

    alias.columns = getArr(cdata.columns, cdata.columnCount, getStr)

    return alias
end

getTableRef = function(cdata, params)
    if cdata == nil then
        return nil
    end

    local tableRef = { }

    tableRef.type = tonumber(cdata.type)

    tableRef.schema = getStr(cdata.schema)
    tableRef.name = getStr(cdata.name)
    tableRef.alias = getAlias(cdata.alias)

    tableRef.select = getSelectStatement(cdata.select, params)

    tableRef.list = getArr(cdata.list, cdata.listSize,
        getTableRef, params)

    tableRef.join = getJoinDefinition(cdata.join, params)

    return tableRef
end

getGroupByDescription = function(cdata, params)
    if cdata == nil then
        return nil
    end

    local groupBy = { }

    groupBy.columns = getExprArr(cdata.columns, cdata.columnCount, params)

    groupBy.having = getExpr(cdata.having, params)

    return groupBy
end

getSetOperation = function(cdata, params)
    if cdata == nil then
        return nil
    end

    local setOp = { }

    setOp.setType = tonumber(cdata.setType)
    setOp.isAll = cdata.isAll

    setOp.nestedSelectStatement = getSelectStatement(
        cdata.nestedSelectStatement, params)

    setOp.resultOrder = getArr(cdata.resultOrder, cdata.resultOrderCount,
        getOrderDescription, params)

    setOp.resultLimit = getLimitDescription(cdata.resultLimit, params)

    return setOp
end

getOrderDescription = function(cdata, params)
    if cdata == nil then
        return nil
    end

    local orderDesc = { }

    orderDesc.type = tonumber(cdata.type)
    orderDesc.expr = getExpr(cdata.expr, params)

    return orderDesc
end

getWithDescription = function(cdata, params)
    if cdata == nil then
        return nil
    end

    local withDesc = { }

    withDesc.alias = getStr(cdata.alias)
    withDesc.select = getSelectStatement(cdata.select, params)

    return withDesc
end

getLimitDescription = function(cdata, params)
    if cdata == nil then
        return nil
    end

    local limitDesc = { }

    limitDesc.limit = getExpr(cdata.limit, params)
    limitDesc.offset = getExpr(cdata.offset, params)

    return limitDesc
end

getSelectStatement = function(cdata, params)
    if cdata == nil then
        return nil
    end

    local statement = { }

    statement.fromTable = getTableRef(cdata.fromTable, params)

    statement.selectDistinct = cdata.selectDistinct

    statement.selectList = getExprArr(cdata.selectList,
        cdata.selectListSize, params)

    statement.whereClause = getExpr(cdata.whereClause, params)

    statement.groupBy = getGroupByDescription(cdata.groupBy, params)

    statement.setOperations = getArr(cdata.setOperations,
        cdata.setOperationCount, getSetOperation, params)

    statement.order = getArr(cdata.order, cdata.orderCount,
        getOrderDescription, params)

    statement.withDescriptions = getArr(cdata.withDescriptions,
        cdata.withDescriptionCount, getWithDescription, params)

    statement.limit = getLimitDescription(cdata.limit, params)

    return statement
end

getSQLStatement = function(cdata, params)
    if cdata == nil then
        return nil
    end

    local statement

    local statementType = tonumber(cdata.type)

    if statementType == parserConst.StatementType.kStmtSelect then
        local cdataEx = ffi.cast("LuaSelectStatement*", cdata)
        statement = getSelectStatement(cdataEx, params)
    else
        statement = { }
    end

    statement.type = statementType

    statement.stringLength = statement.stringLength

    statement.hints = getExprArr(cdata.hints, cdata.hintCount, params)

    return statement
end

getSQLParserResult = function(cdata)
    if cdata == nil then
        return nil
    end

    local result = { }

    result.isValid = cdata.isValid

    result.parameters = { }

    result.statements = getArr(cdata.statements, cdata.statementCount,
        getSQLStatement, result.parameters)

    table.sort(result.parameters, function(a, b)
        return a.ival <  b.ival
    end)

    result.errorMsg = getStr(cdata.errorMsg)
    result.errorLine = tonumber(cdata.errorLine)
    result.errorColumn = tonumber(result.errorColumn)

    return result
end


local function parse(query)
    assert(query ~= nil, "sqlparser: SQL query string is not specified")

    local cdata = sqlParserLib.parseSql(query)

    local obj = getSQLParserResult(cdata)

    sqlParserLib.finalize(cdata)

    return obj
end

return {
    parse = parse,
    tostring = sqlgen.generate
}
