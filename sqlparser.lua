#!/usr/bin/env tarantool

local fio = require("fio")
local ffi = require("ffi")
local parserConst = require("parserConst")

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
local sql = ffi.load(package)

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
local getSelectSatement
local getSQLSatement
local getSQLParserResult

local function getArr(cdata, count, getItem)
    if cdata == nil then
        return nil
    end

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

    expr.exprListSize = tonumber(cdata.exprListSize)
    expr.exprList = getExprArr(cdata.exprList, expr.exprListSize)

    expr.select = nil

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

    local alias

    alias.name = getStr(cdata.name)

    alias.columnCount = tonumber(cdata.columnCount)
    alias.columns = getArr(cdata.columns, alias.columnCount, getStr)

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

    tableRef.select = nil

    tableRef.listSize = tonumber(cdata.listSize)
    tableRef.list = getArr(cdata.list, tableRef.listSize, getTableRef)

    tableRef.join = getJoinDefinition(cdata.join)

    return tableRef
end

getGroupByDescription = function(cdata)
    if cdata == nil then
        return nil
    end

    local groupBy = { }

    groupBy.columnCount = tonumber(cdata.columnCount)
    groupBy.columns = getExprArr(cdata.columns, groupBy.columnCount)

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

    setOp.nestedSelectStatement = getSelectSatement(
        cdata.nestedSelectStatement)

    setOp.resultOrderCount = tonumber(cdata.resultOrderCount)
    setOp.resultOrder = getArr(cdata.resultOrder, setOp.resultOrderCount,
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
    withDesc.select = nil

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

getSelectSatement = function(cdata)
    if cdata == nil then
        return nil
    end

    local statement = { }

    statement.fromTable = getTableRef(cdata.fromTable)

    statement.selectDistinct = cdata.selectDistinct

    statement.selectListSize = tonumber(cdata.selectListSize)
    statement.selectList = getExprArr(cdata.selectList,
        statement.selectListSize)

    statement.whereClause = getExpr(cdata.whereClause)

    statement.groupBy = getGroupByDescription(cdata.groupBy)

    statement.setOperationCount = tonumber(cdata.setOperationCount)
    statement.setOperations = getArr(cdata.setOperations,
        statement.setOperationCount, getSetOperation)

    statement.orderCount = tonumber(cdata.orderCount)
    statement.order = getArr(cdata.order, statement.orderCount,
        getOrderDescription)

    statement.withDescriptionCount = tonumber(cdata.withDescriptionCount)
    statement.withDescriptions = getArr(cdata.withDescriptions,
        statement.withDescriptionCount, getWithDescription)

    statement.limit = getLimitDescription(cdata.limit)

    return statement
end

getSQLSatement = function(cdata)
    if cdata == nil then
        return nil
    end

    local statement

    local statementType = tonumber(cdata.type)

    if statementType == parserConst.StatementType.kStmtSelect then
        local cdataEx = ffi.cast("LuaSelectStatement*", cdata)
        statement = getSelectSatement(cdataEx)
    else
        statement = { }
    end

    statement.type = statementType

    statement.stringLength = statement.stringLength

    statement.hintCount = tonumber(cdata.hintCount)
    statement.hints = getExprArr(cdata.hints, statement.hintCount)

    return statement
end

getSQLParserResult = function(cdata)
    if cdata == nil then
        return nil
    end

    local result = { }

    result.isValid = cdata.isValid

    result.statementCount = tonumber(cdata.statementCount)
    result.statements = getArr(cdata.statements, result.statementCount,
        getSQLSatement)

    result.parameterCount = tonumber(cdata.parameterCount)
    result.parameters = getExprArr(cdata.parameters, result.parameterCount)

    result.errorMsg = getStr(cdata.errorMsg)
    result.errorLine = tonumber(cdata.errorLine)
    result.errorColumn = tonumber(result.errorColumn)

    return result
end


local function parse(query)
    local result = sql.parseSql(query)

    local luaResult = getSQLParserResult(result)

    sql.finalize(result)

    return luaResult
end

return {
    parse = parse
}
