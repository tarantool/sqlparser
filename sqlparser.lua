#!/usr/bin/env tarantool

local fio = require("fio")
local ffi = require("ffi")
local parserConst = require("parserConst")
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

local function getArr(cdata, count, getItem)
    if cdata == nil then
        return nil
    end

    count = tonumber(count)

    local arr = { }
    for i = 0, count - 1 do
        table.insert(arr, getItem(cdata[i]))
    end

    return arr
end

local function getStr(cdata)
    if cdata == nil then
        return nil
    end

    return ffi.string(cdata)
end

getExpr = function(cdata)
    if cdata == nil then
        return nil
    end

    local expr = { }

    expr.type = tonumber(cdata.type)

    expr.expr = getExpr(cdata.expr)
    expr.expr2 = getExpr(cdata.expr2)
    expr.exprList = getExprArr(cdata.exprList, cdata.exprListSize)

    expr.select = getSelectStatement(cdata.select)

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

getExprArr = function(cdata, count)
    return getArr(cdata, count, getExpr)
end

getJoinDefinition = function(cdata)
    if cdata == nil then
        return nil
    end

    local joinDefinition = { }

    joinDefinition.left = getTableRef(cdata.left)
    joinDefinition.right = getTableRef(cdata.right)
    joinDefinition.condition = getExpr(cdata.condition)

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

getTableRef = function(cdata)
    if cdata == nil then
        return nil
    end

    local tableRef = { }

    tableRef.type = tonumber(cdata.type)

    tableRef.schema = getStr(cdata.schema)
    tableRef.name = getStr(cdata.name)
    tableRef.alias = getAlias(cdata.alias)

    tableRef.select = getSelectStatement(cdata.select)

    tableRef.list = getArr(cdata.list, cdata.listSize, getTableRef)

    tableRef.join = getJoinDefinition(cdata.join)

    return tableRef
end

getGroupByDescription = function(cdata)
    if cdata == nil then
        return nil
    end

    local groupBy = { }

    groupBy.columns = getExprArr(cdata.columns, cdata.columnCount)

    groupBy.having = getExpr(cdata.having)

    return groupBy
end

getSetOperation = function(cdata)
    if cdata == nil then
        return nil
    end

    local setOp = { }

    setOp.setType = tonumber(cdata.setType)
    setOp.isAll = cdata.isAll

    setOp.nestedSelectStatement = getSelectStatement(
        cdata.nestedSelectStatement)

    setOp.resultOrder = getArr(cdata.resultOrder, cdata.resultOrderCount,
        getOrderDescription)

    setOp.resultLimit = getLimitDescription(cdata.resultLimit)

    return setOp
end

getOrderDescription = function(cdata)
    if cdata == nil then
        return nil
    end

    local orderDesc = { }

    orderDesc.type = tonumber(cdata.type)
    orderDesc.expr = getExpr(cdata.expr)

    return orderDesc
end

getWithDescription = function(cdata)
    if cdata == nil then
        return nil
    end

    local withDesc = { }

    withDesc.alias = getStr(cdata.alias)
    withDesc.select = getSelectStatement(cdata.select)

    return withDesc
end

getLimitDescription = function(cdata)
    if cdata == nil then
        return nil
    end

    local limitDesc = { }

    limitDesc.limit = getExpr(cdata.limit)
    limitDesc.offset = getExpr(cdata.offset)

    return limitDesc
end

getSelectStatement = function(cdata)
    if cdata == nil then
        return nil
    end

    local statement = { }

    statement.fromTable = getTableRef(cdata.fromTable)

    statement.selectDistinct = cdata.selectDistinct

    statement.selectList = getExprArr(cdata.selectList,
        cdata.selectListSize)

    statement.whereClause = getExpr(cdata.whereClause)

    statement.groupBy = getGroupByDescription(cdata.groupBy)

    statement.setOperations = getArr(cdata.setOperations,
        cdata.setOperationCount, getSetOperation)

    statement.order = getArr(cdata.order, cdata.orderCount,
        getOrderDescription)

    statement.withDescriptions = getArr(cdata.withDescriptions,
        cdata.withDescriptionCount, getWithDescription)

    statement.limit = getLimitDescription(cdata.limit)

    return statement
end

getSQLStatement = function(cdata)
    if cdata == nil then
        return nil
    end

    local statement

    local statementType = tonumber(cdata.type)

    if statementType == parserConst.StatementType.kStmtSelect then
        local cdataEx = ffi.cast("LuaSelectStatement*", cdata)
        statement = getSelectStatement(cdataEx)
    else
        statement = { }
    end

    statement.type = statementType

    statement.stringLength = statement.stringLength

    statement.hints = getExprArr(cdata.hints, cdata.hintCount)

    return statement
end

getSQLParserResult = function(cdata)
    if cdata == nil then
        return nil
    end

    local result = { }

    result.isValid = cdata.isValid

    result.statements = getArr(cdata.statements, cdata.statementCount,
        getSQLStatement)

    result.parameters = getExprArr(cdata.parameters, cdata.parameterCount)

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
