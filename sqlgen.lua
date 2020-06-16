#!/usr/bin/env tarantool

local getExprStr
local getExprArrStr
local getJoinDefinitionStr
local getAliasStr
local getTableRefStr
local getGroupByDescriptionStr
local getSetOperationStr
local getOrderDescriptionStr
local getWithDescriptionStr
local getLimitDescriptionStr
local getSelectStatementStr
local getSQLStatementStr

local function getArrStr(arr, getItemStr, ...)
    if arr == nil then
        return ""
    end

    local str = ""

    for _, item in ipairs(arr) do
        str = str .. getItemStr(item, ...) .. ", "
    end

    if str:sub(-2) == ", " then
        str = str:sub(1, -3)
    end

    return str
end

getExprStr = function(expr, allowAlias)
    assert(expr ~= nil, "sqlparser: expression is not specified")

    local exprType = expr.type

    local str

    if exprType == "literalFloat" then
        str = tostring(expr.value)
    elseif exprType == "literalString" then
        str = "'" .. expr.value:gsub("'", "''") .. "'"
    elseif exprType == "literalInt" then
        str = tostring(expr.value)
    elseif exprType == "literalNull" then
        str = "null"
    elseif exprType == "star" then
        str = "*"
    elseif exprType == "parameter" then
        str = "?"
    elseif exprType == "columnRef" then
        str = '"' .. expr.name .. '"'
    elseif exprType == "functionRef" then
        if expr.datetimeField ~= nil then
            if string.lower(expr.name) == "extract" then
                str = "extract(" ..
                    expr.datetimeField .. " from " ..
                    getExprStr(expr.expr) .. ")"
            else
                error("sqlparser: unknown date-time function: " ..
                    tostring(expr.name))
            end
        elseif expr.columnType ~= nil then
            if string.lower(expr.name) == "cast" then
                local columnType = expr.columnType
                if expr.columnLength ~= nil then
                    columnType = columnType .. "(" ..
                        tostring(expr.columnLength) .. ")"
                end
                str = "cast(" .. getExprStr(expr.expr) ..
                    " as " .. columnType .. ")"
            else
                error("sqlparser: unknown type casting function: " ..
                    tostring(expr.name))
            end
        elseif expr.distinct then
            str = expr.name .. "(distinct " ..
                getExprArrStr(expr.exprList) .. ")"
        else
            str = expr.name .. "(" .. getExprArrStr(expr.exprList) .. ")"
        end
    elseif exprType == "operator" then
        local op = expr.name
        local arity = expr.arity

        if arity == 1 then
            if op == "not" then
                str = "not " .. getExprStr(expr.expr)
            elseif op == "-" then
                str = "-" .. getExprStr(expr.expr)
            elseif op == "is null" then
                str = getExprStr(expr.expr) .. " is null"
            elseif op == "exists" then
                str = "exists(" .. getSelectStatementStr(expr.select) .. ")"
            else
                error("sqlparser: unknown unary operator type: " ..
                    tostring(expr.op))
            end
        elseif arity == 2 then
            str = getExprStr(expr.expr) .. " " .. op .. " "

            if op == "in" then
                str = str .. "(" .. getExprArrStr(expr.exprList) .. ")"
            elseif expr.expr2 ~= nil then
                str = str .. getExprStr(expr.expr2)
            else
                error("sqlparser: the second operand of a binary operator is not set: " ..
                    tostring(op))
            end
        elseif arity == 3 then
            if op == "between" then
                str = getExprStr(expr.expr) .. " between " ..
                    getExprStr(expr.exprList[1]) .. " and " ..
                    getExprStr(expr.exprList[2])
            else
                error("sqlparser: unknown ternary operator type: " ..
                    tostring(expr.op))
            end
        elseif arity == -1 then
            if op == "case" then
                str = "case"

                for _, e in ipairs(expr.exprList) do
                    str = str .. getExprStr(e)
                end

                if expr.expr2 ~= nil then
                    str = str .. " else " .. getExprStr(expr.expr2)
                end

                str = str .. " end"
            elseif op == "when" then
                str = " when " .. getExprStr(expr.expr) ..
                    " then " .. getExprStr(expr.expr2)
            else
                error("sqlparser: unknown n-ary operator type: " ..
                    tostring(op))
            end
        elseif arity == 0 then
            error("sqlparser: unhandled operator type: " ..
                tostring(op))
        else
            error("sqlparser: unhandled operator arity: " ..
                tostring(arity))
        end
    elseif exprType == "select" then
        str = "(" .. getSelectStatementStr(expr.select) .. ")"
    elseif exprType == "hint" then
        error("sqlparser: unhandled expression type: " .. tostring(exprType))
    elseif exprType == "array" then
        str = "array [" .. getExprArrStr(expr.exprList) .. "]"
    elseif exprType == "arrayIndex" then
        str = getExprStr(expr.expr) .. "[" .. tostring(expr.index) .. "]"
    elseif exprType == "datetimeField" then
        str = expr.datetimeField
    else
        error("sqlparser: unknown expression type: " .. tostring(exprType))
    end

    if expr.table ~= nil then
        str = '"' .. expr.table .. '"' .. "." .. str
    end

    if allowAlias and expr.alias ~= nil then
        str = str .. " as " .. '"' .. expr.alias .. '"'
    end

    return str
end

getExprArrStr = function(arr, allowAlias)
    assert(arr ~= nil, "sqlparser: expressions list is not specified")

    return getArrStr(arr, getExprStr, allowAlias)
end

getJoinDefinitionStr = function(joinDefinition)
    assert(joinDefinition ~= nil, "sqlparser: join definition is not specified")

    local strJoin = joinDefinition.type .. " join"

    local strLeft = getTableRefStr(joinDefinition.left)

    local strRight = getTableRefStr(joinDefinition.right)

    local str = strLeft .. " " .. strJoin .. " " .. strRight

    if joinDefinition.condition ~= nil then
        local strCond = getExprStr(joinDefinition.condition)
        str = str .. " on " .. strCond
    end

    return str
end

getAliasStr = function(alias)
    assert(alias ~= nil, "sqlparser: alias is not specified")

    return alias.name
end

getTableRefStr = function(tableRef)
    assert(tableRef ~= nil, "sqlparser: table reference is not specified")

    local str

    local tableRefType = tableRef.type

    if tableRefType == "table" then
        str = '"' .. tableRef.name .. '"'

        if tableRef.schema ~= nil then
            str = '"' .. tableRef.schema .. '"' .. "." .. str
        end
    elseif tableRefType == "select" then
        str = "(" .. getSelectStatementStr(tableRef.select) .. ")"
    elseif tableRefType == "join" then
        str = getJoinDefinitionStr(tableRef.join)
    elseif tableRefType == "crossProduct" then
        str = getArrStr(tableRef.list, getTableRefStr)
    else
        error("sqlparser: unknown table reference type: " ..
            tostring(tableRefType))
    end

    if tableRef.alias ~= nil then
        str = str .. " as " .. '"' .. getAliasStr(tableRef.alias) .. '"'
    end

    return str
end

getGroupByDescriptionStr = function(groupBy)
    assert(groupBy ~= nil,
        "sqlparser: group by description is not specified")

    local str = " group by " .. getExprArrStr(groupBy.columns)

    if groupBy.having ~= nil then
        str = str .. " having " .. getExprStr(groupBy.having)
    end

    return str
end

getSetOperationStr = function(setOp)
    assert(setOp ~= nil,
        "sqlparser: 'set' operation description is not specified")

    local str = " " .. setOp.setType .. " "

    if setOp.isAll then
        str = " all "
    end

    str = str .. "(" .. getSelectStatementStr(setOp.nestedSelectStatement) .. ")"

    if setOp.resultOrder ~= nil then
        str = str .. getOrderDescriptionStr(setOp.resultOrder)
    end

    if setOp.resultLimit ~= nil then
        str = str .. getLimitDescriptionStr(setOp.resultLimit)
    end

    return str
end

getOrderDescriptionStr = function(orderBy)
    assert(orderBy ~= nil,
        "sqlparser: order by description is not specified")

    local str = getArrStr(orderBy, function(item)
        local s = getExprStr(item.expr)

        if item.type == "desc" then
            s = s .. " desc"
        end

        return s
    end)

    if str ~= "" then
        str = " order by " .. str
    end

    return str
end

getWithDescriptionStr = function(withDesc)
    assert(withDesc ~= nil,
        "sqlparser: 'with' clause description is not specified")

    local strSelect = getSelectStatementStr(withDesc.select)

    local str = withDesc.alias .. " as (" .. strSelect .. ")"

    return str
end

getLimitDescriptionStr = function(limitDesc)
    assert(limitDesc ~= nil,
        "sqlparser: limit description is not specified")

    local str = ""

    if limitDesc.limit ~= nil then
        str = " limit " .. getExprStr(limitDesc.limit)
    end

    if limitDesc.offset ~= nil then
        str = str .. " offset " .. getExprStr(limitDesc.offset)
    end

    return str
end

getSelectStatementStr = function(selectStatement)
    assert(selectStatement ~= nil,
        "sqlparser: select statement is not specified")

    local str

    if not selectStatement.selectDistinct then
        str = "select "
    else
        str = "select distinct "
    end

    str = str .. getExprArrStr(selectStatement.selectList, true)

    if selectStatement.fromTable ~= nil then
        str = str .. " from " .. getTableRefStr(selectStatement.fromTable)
    end

    if selectStatement.whereClause ~= nil then
        str = str .. " where " .. getExprStr(selectStatement.whereClause)
    end

    if selectStatement.groupBy ~= nil then
        str = str .. getGroupByDescriptionStr(selectStatement.groupBy)
    end

    if selectStatement.order ~= nil then
        str = str .. getOrderDescriptionStr(selectStatement.order)
    end

    if selectStatement.limit ~= nil then
        str = str .. getLimitDescriptionStr(selectStatement.limit)
    end

    if selectStatement.withDescriptions ~= nil then
        local withDescs = getArrStr(selectStatement.withDescriptions,
            getWithDescriptionStr)

        if withDescs ~= "" then
            str = "with " .. withDescs .. " " .. str
        end
    end

    if selectStatement.setOperations ~= nil then
        local n = #selectStatement.setOperations
        if n > 0 then
            str = "(" .. str .. ")"

            for i = 1, n - 1 do
                local setOp = selectStatement.setOperations[i]
                str = "(" .. str .. getSetOperationStr(setOp) .. ")"
            end

            local setOp = selectStatement.setOperations[n]
            str = str .. getSetOperationStr(setOp)
        end
    end

    return str
end

getSQLStatementStr = function(SQLStatement)
    assert(SQLStatement ~= nil,
        "sqlparser: SQL statement is not specified")

    local str

    if SQLStatement.type == "select" then
        str = getSelectStatementStr(SQLStatement)
    else
        error(("Generating of an SQL query string for statement type '%s' is not implemented"):format(
            SQLStatement.type))
    end

    return str .. ";"
end

local function generate(ast)
    assert(ast ~= nil, "sqlparser: AST is not specified")

    assert(ast.isValid, "sqlparser: AST is not valid")

    local queries = { }

    for _, statement in ipairs(ast.statements) do
        local query = getSQLStatementStr(statement)
        table.insert(queries, query)
    end

    return queries
end

return {
    generate = generate
}
