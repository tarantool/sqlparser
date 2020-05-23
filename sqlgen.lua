#!/usr/bin/env tarantool

local parserConst = require("sqlparserConst")

local getOperatorTypeStr
local getExprStr
local getExprArrStr
local getJoinTypeStr
local getJoinDefinitionStr
local getAliasStr
local getTableRefStr
local getGroupByDescriptionStr
local getSetOperationTypeStr
local getSetOperationStr
local getOrderDescriptionStr
local getWithDescriptionStr
local getLimitDescriptionStr
local getSelectStatementStr
local getSQLStatementStr

local operatorTypeToStr = {
    [parserConst.OperatorType.kOpNone] = "",

    -- Ternary operator
    [parserConst.OperatorType.kOpBetween] = "",

    -- n-nary special case
    [parserConst.OperatorType.kOpCase] = "",
    [parserConst.OperatorType.kOpCaseListElement] = "", -- `WHEN expr THEN expr`

    -- Binary operators.
    [parserConst.OperatorType.kOpPlus] = "+",
    [parserConst.OperatorType.kOpMinus] = "-",
    [parserConst.OperatorType.kOpAsterisk] = "*",
    [parserConst.OperatorType.kOpSlash] = "/",
    [parserConst.OperatorType.kOpPercentage] = "%",
    [parserConst.OperatorType.kOpCaret] = "^",

    [parserConst.OperatorType.kOpEquals] = "=",
    [parserConst.OperatorType.kOpNotEquals] = "<>",
    [parserConst.OperatorType.kOpLess] = "<",
    [parserConst.OperatorType.kOpLessEq] = "<=",
    [parserConst.OperatorType.kOpGreater] = ">",
    [parserConst.OperatorType.kOpGreaterEq] = ">=",
    [parserConst.OperatorType.kOpLike] = "like",
    [parserConst.OperatorType.kOpNotLike] = "not like",
    [parserConst.OperatorType.kOpILike] = "ilike",
    [parserConst.OperatorType.kOpAnd] = "and",
    [parserConst.OperatorType.kOpOr] = "or",
    [parserConst.OperatorType.kOpIn] = "in",
    [parserConst.OperatorType.kOpConcat] = "+",

    -- Unary operators.
    [parserConst.OperatorType.kOpNot] = "not",
    [parserConst.OperatorType.kOpUnaryMinus] = "-",
    [parserConst.OperatorType.kOpIsNull] = "is null",
    [parserConst.OperatorType.kOpExists] = "exists"
}

local joinTypeToStr = {
    [parserConst.JoinType.kJoinInner] = "inner join",
    [parserConst.JoinType.kJoinFull] = "full join",
    [parserConst.JoinType.kJoinLeft] = "left join",
    [parserConst.JoinType.kJoinRight] = "right join",
    [parserConst.JoinType.kJoinCross] = "cross join",
    [parserConst.JoinType.kJoinNatural] = "natural join"
}

local setOperationTypeToStr = {
    [parserConst.SetType.kSetUnion] = "union",
    [parserConst.SetType.kSetIntersect] = "intersect",
    [parserConst.SetType.kSetExcept] = "except"
}

local function getArrStr(arr, getItemStr)
    if arr == nil then
        return ""
    end

    local str = ""

    for _, item in ipairs(arr) do
        str = str .. getItemStr(item) .. ", "
    end

    if str:sub(-2) == ", " then
        str = str:sub(1, -3)
    end

    return str
end

local function getOperatorArity(opType)
    assert(opType ~= nil, "sqlparser: operator type is not specified")

    if opType == parserConst.OperatorType.kOpNone then
        return 0
    end

    if opType == parserConst.OperatorType.kOpBetween then
        return 3
    end

    if opType == parserConst.OperatorType.kOpCase or
        opType == parserConst.OperatorType.kOpCaseListElement
    then
        return -1
    end

    if opType >= parserConst.OperatorType.kOpPlus and
        opType <= parserConst.OperatorType.kOpConcat
    then
        return 2
    end

    if opType >= parserConst.OperatorType.kOpNot and
        opType <= parserConst.OperatorType.kOpExists
    then
        return 1
    end

    error("sqlparser: unknown operator type: " ..
        tostring(opType))
end

getOperatorTypeStr = function(operatorType)
    local str = operatorTypeToStr[operatorType]

    assert(str ~= nil, "sqlparser: unknown operator type: " ..
        tostring(operatorType))

    return str
end

getExprStr = function(expr)
    assert(expr ~= nil, "sqlparser: expression is not specified")

    local exprType = expr.type

    local str

    if exprType == parserConst.ExprType.kExprLiteralFloat then
        str = tostring(expr.fval)
    elseif exprType == parserConst.ExprType.kExprLiteralString then
        str = "'" .. expr.name:gsub("'", "''") .. "'"
    elseif exprType == parserConst.ExprType.kExprLiteralInt then
        if not expr.isBoolLiteral then
            str = tostring(expr.ival)
        else
            if expr.ival == 0 then
                str = "false"
            else
                str = "true"
            end
        end
    elseif exprType == parserConst.ExprType.kExprLiteralNull then
        str = "null"
    elseif exprType == parserConst.ExprType.kExprStar then
        str = "*"
    elseif exprType == parserConst.ExprType.kExprParameter then
        str = "?"
    elseif exprType == parserConst.ExprType.kExprColumnRef then
        str = '"' .. expr.name .. '"'
    elseif exprType == parserConst.ExprType.kExprFunctionRef then
        str = expr.name .. "(" .. getExprArrStr(expr.exprList) .. ")"
    elseif exprType == parserConst.ExprType.kExprOperator then
        local strOp = getOperatorTypeStr(expr.opType)

        local arity = getOperatorArity(expr.opType)

        if arity == 1 then
            if expr.opType == parserConst.OperatorType.kOpNot then
                str = strOp .. " " .. getExprStr(expr.expr)
            elseif expr.opType == parserConst.OperatorType.kOpUnaryMinus then
                str = strOp .. getExprStr(expr.expr)
            elseif expr.opType == parserConst.OperatorType.kOpIsNull then
                str = getExprStr(expr.expr) .. " " .. strOp
            elseif expr.opType == parserConst.OperatorType.kOpExists then
                str = strOp .. "(" .. getSelectStatementStr(expr.select) .. ")"
            end
        elseif arity == 2 then
            str = getExprStr(expr.expr) .. " " .. strOp .. " "

            if expr.expr2 ~= nil then
                str = str .. getExprStr(expr.expr2)
            elseif expr.exprList ~= nil then
                str = str .. "(" .. getExprArrStr(expr.exprList) .. ")"
            else
                error("sqlparser: the second operand of a binary operator is not set: " ..
                    strOp)
            end
        elseif arity == 3  then
            str = getExprStr(expr.expr) .. " between " ..
                getExprStr(expr.exprList[1]) .. " and " ..
                getExprStr(expr.exprList[2])
        elseif arity == -1 then
            if expr.opType == parserConst.OperatorType.kOpCase then
                str = "case"

                for _, expr in ipairs(expr.exprList) do
                    str = str .. getExprStr(expr)
                end

                if expr.expr2 ~= nil then
                    str = str .. " else " .. getExprStr(expr.expr2)
                end

                str = str .. " end"
            elseif expr.opType == parserConst.OperatorType.kOpCaseListElement then
                str = " when " .. getExprStr(expr.expr) ..
                    " then " .. getExprStr(expr.expr2)
            else
                error("sqlparser: unknown n-ary operator type: " ..
                    tostring(expr.opType))
            end
        elseif arity == 0 then
            error("sqlparser: unhandled operator type (NOOP): " ..
                tostring(expr.opType))
        else
            error("sqlparser: unhandled operator arity: " ..
                tostring(arity))
        end
    elseif exprType == parserConst.ExprType.kExprSelect then
        str = "(" .. getSelectStatementStr(expr.select) .. ")"
    elseif exprType == parserConst.ExprType.kExprHint then

    elseif exprType == parserConst.ExprType.kExprArray then

    elseif exprType == parserConst.ExprType.kExprArrayIndex then

    elseif exprType == parserConst.ExprType.kExprDatetimeField then

    else
        error("sqlparser: unknown expression type: " .. tostring(exprType))
    end

    if expr.table ~= nil then
        str = '"' .. expr.table .. '"' .. "." .. str
    end

    if expr.alias ~= nil then
        str = str .. " as " .. '"' .. expr.alias .. '"'
    end

    return str
end

getExprArrStr = function(arr)
    assert(arr ~= nil, "sqlparser: expressions list is not specified")

    return getArrStr(arr, getExprStr)
end

getJoinTypeStr = function(joinType)
    local str = joinTypeToStr[joinType]

    assert(str ~= nil, "sqlparser: unknown join type: " ..
        tostring(joinType))

    return str
end

getJoinDefinitionStr = function(joinDefinition)
    assert(joinDefinition ~= nil, "sqlparser: join definition is not specified")

    local strJoin = getJoinTypeStr(joinDefinition.type)

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

    if tableRefType == parserConst.TableRefType.kTableName then
        str = '"' .. tableRef.name .. '"'

        if tableRef.schema ~= nil then
            str = '"' .. tableRef.schema .. '"' .. "." .. str
        end
    elseif tableRefType == parserConst.TableRefType.kTableSelect then
        str = "(" .. getSelectStatementStr(tableRef.select) .. ")"
    elseif tableRefType == parserConst.TableRefType.kTableJoin then
        str = getJoinDefinitionStr(tableRef.join)
    elseif tableRefType == parserConst.TableRefType.kTableCrossProduct then
        str = getArrStr(tableRef.list, getTableRefStr)
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

getSetOperationTypeStr = function(setOperationType)
    local str = setOperationTypeToStr[setOperationType]

    assert(str ~= nil, "sqlparser: unknown set operation type: " ..
        tostring(setOperationType))

    return str
end

getSetOperationStr = function(setOp)
    assert(setOp ~= nil,
        "sqlparser: 'set' operation description is not specified")

    local strSetOp = getSetOperationTypeStr(setOp.setType)

    local str = " " .. strSetOp .. " "

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

        if item.type == parserConst.OrderType.kOrderDesc then
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

    str = str .. getExprArrStr(selectStatement.selectList)

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

    if SQLStatement.type == parserConst.StatementType.kStmtSelect then
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
