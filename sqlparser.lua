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

local function getOperatorArity(opType)
    if opType == nil then
        return nil
    end

    local OperatorType = parserConst.OperatorType

    if opType == OperatorType.None then
        return 0
    end

    if opType == OperatorType.Between then
        return 3
    end

    if opType == OperatorType.Case or
        opType == OperatorType.CaseListElement
    then
        return -1
    end

    if opType >= OperatorType.Plus and
        opType <= OperatorType.Concat
    then
        return 2
    end

    if opType >= OperatorType.Not and
        opType <= OperatorType.Exists
    then
        return 1
    end

    return nil
end

getExpr = function(cdata, params)
    if cdata == nil then
        return nil
    end

    local expr = { }

    local exprType = parserConst.getExprTypeStr(cdata.type)
    expr.type = exprType

    if exprType == "parameter" then
        table.insert(params, expr)
    end

    expr.expr = getExpr(cdata.expr, params)
    expr.expr2 = getExpr(cdata.expr2, params)
    expr.exprList = getExprArr(cdata.exprList, cdata.exprListSize, params)

    expr.select = getSelectStatement(cdata.select, params)

    expr.name = getStr(cdata.name)
    expr.table = getStr(cdata.table)
    expr.alias = getStr(cdata.alias)

    if exprType == "literalFloat" then
        expr.value = tonumber(cdata.fval)
    elseif exprType == "literalString" then
        expr.value = getStr(cdata.name)
    elseif exprType == "literalInt" then
        local n = tonumber(cdata.ival)
        if cdata.isBoolLiteral then
            expr.value = (n ~= 0)
        else
            expr.value = n
        end
    elseif exprType == "literalNull" then
        expr.value = box.NULL
    elseif exprType == "parameter" then
        expr.paramId = tonumber(cdata.ival)
    elseif exprType == "functionRef" then
        expr.distinct = cdata.distinct

        local datetimeField = tonumber(cdata.datetimeField)
        if cdata.datetimeField > 0 then
            expr.datetimeField =
                parserConst.getDatetimeFieldStr(datetimeField)
        end

        local columnType = tonumber(cdata.columnType)
        if columnType > 0 then
            expr.columnType =
                parserConst.getColumnTypeStr(columnType)
        end

        local columnLength = tonumber(cdata.columnLength)
        if columnLength > 0 then
            expr.columnLength = columnLength
        end
    elseif exprType == "operator" then
        local opTypeNum = tonumber(cdata.opType)
        expr.name = parserConst.getOperatorTypeStr(opTypeNum)
        expr.arity = getOperatorArity(opTypeNum)
    elseif exprType == "arrayIndex" then
        expr.index = tonumber(cdata.ival)
    end

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

    joinDefinition.type =
        parserConst.getJoinTypeStr(cdata.type)

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

    tableRef.type = parserConst.getTableRefTypeStr(cdata.type)

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

    setOp.setType = parserConst.getSetTypeStr(cdata.setType)

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

    orderDesc.type = parserConst.getOrderTypeStr(cdata.type)

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

    local statementType =
        parserConst.getStatementTypeStr(cdata.type)

    if statementType == "select" then
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
        return a.paramId < b.paramId
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
