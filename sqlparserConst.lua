local ExprType = {
    kExprLiteralFloat = 0,
    kExprLiteralString = 1,
    kExprLiteralInt = 2,
    kExprLiteralNull = 3,
    kExprStar = 4,
    kExprParameter = 5,
    kExprColumnRef = 6,
    kExprFunctionRef = 7,
    kExprOperator = 8,
    kExprSelect = 9,
    kExprHint = 10,
    kExprArray = 11,
    kExprArrayIndex = 12,
    kExprDatetimeField = 13
}

local ExprTypeName = {
    "literalFloat",
    "literalString",
    "literalInt",
    "literalNull",
    "star",
    "parameter",
    "columnRef",
    "functionRef",
    "operator",
    "select",
    "hint",
    "array",
    "arrayIndex",
    "datetimeField"
}

local function getExprTypeStr(value)
    value = tonumber(value)

    if value == nil then
        return nil
    end

    local str = ExprTypeName[value + 1]

    if str == nil then
        error("sqlparser: unknown expression type: " ..
            tostring(value))
    end

    return str
end


local DatetimeField = {
    kDatetimeNone = 0,
    kDatetimeSecond = 1,
    kDatetimeMinute = 2,
    kDatetimeHour = 3,
    kDatetimeDay = 4,
    kDatetimeMonth = 5,
    kDatetimeYear = 6
}

local DatetimeFieldName = {
    "second",
    "minute",
    "hour",
    "day",
    "month",
    "year"
}

local function getDatetimeFieldStr(value)
    value = tonumber(value)

    if value == nil then
        return nil
    end

    local str = DatetimeFieldName[value + 1]

    if str == nil then
        error("sqlparser: unknown date-time field: " ..
            tostring(value))
    end

    return str
end


local OperatorType = {
    kOpNone = 0,

    -- Ternary operator
    kOpBetween = 1,

    -- n-nary special case
    kOpCase = 2,
    kOpCaseListElement = 3, -- `WHEN expr THEN expr`

    -- Binary operators.
    kOpPlus = 4,
    kOpMinus = 5,
    kOpAsterisk = 6,
    kOpSlash = 7,
    kOpPercentage = 8,
    kOpCaret = 9,

    kOpEquals = 10,
    kOpNotEquals = 11,
    kOpLess = 12,
    kOpLessEq = 13,
    kOpGreater = 14,
    kOpGreaterEq = 15,
    kOpLike = 16,
    kOpNotLike = 17,
    kOpILike = 18,
    kOpAnd = 19,
    kOpOr = 20,
    kOpIn = 21,
    kOpConcat = 22,

    -- Unary operators.
    kOpNot = 23,
    kOpUnaryMinus = 24,
    kOpIsNull = 25,
    kOpExists = 26
}

local OperatorTypeName = {
    "",

    -- Ternary operator
    "between",

    -- n-nary special case
    "case",
    "when", -- `WHEN expr THEN expr`

    -- Binary operators.
    "+",
    "-",
    "*",
    "/",
    "%",
    "^",

    "=",
    "<>",
    "<",
    "<=",
    ">",
    ">=",
    "like",
    "not like",
    "ilike",
    "and",
    "or",
    "in",
    "||",

    -- Unary operators.
    "not",
    "-",
    "is null",
    "exists"
}

local function getOperatorTypeStr(value)
    value = tonumber(value)

    if value == nil then
        return nil
    end

    local str = OperatorTypeName[value + 1]

    if str == nil then
        error("sqlparser: unknown operator type: " ..
            tostring(value))
    end

    return str
end


local StatementType = {
    kStmtError = 0, -- unused
    kStmtSelect = 1,
    kStmtImport = 2,
    kStmtInsert = 3,
    kStmtUpdate = 4,
    kStmtDelete = 5,
    kStmtCreate = 6,
    kStmtDrop = 7,
    kStmtPrepare = 8,
    kStmtExecute = 9,
    kStmtExport = 10,
    kStmtRename = 11,
    kStmtAlter = 12,
    kStmtShow = 13,
    kStmtTransaction = 14
}

local StatementTypeName = {
    "error", -- unused
    "select",
    "import",
    "insert",
    "update",
    "delete",
    "create",
    "drop",
    "prepare",
    "execute",
    "export",
    "rename",
    "alter",
    "show",
    "transaction"
}

local function getStatementTypeStr(value)
    value = tonumber(value)

    if value == nil then
        return nil
    end

    local str = StatementTypeName[value + 1]

    if str == nil then
        error("sqlparser: unknown statement type: " ..
            tostring(value))
    end

    return str
end


local JoinType = {
    kJoinInner = 0,
    kJoinFull = 1,
    kJoinLeft = 2,
    kJoinRight = 3,
    kJoinCross = 4,
    kJoinNatural = 5
}

local JoinTypeName = {
    "inner",
    "full",
    "left",
    "right",
    "cross",
    "natural"
}

local function getJoinTypeStr(value)
    value = tonumber(value)

    if value == nil then
        return nil
    end

    local str = JoinTypeName[value + 1]

    if str == nil then
        error("sqlparser: unknown join type: " ..
            tostring(value))
    end

    return str
end


local TableRefType = {
    kTableName = 0,
    kTableSelect = 1,
    kTableJoin = 2,
    kTableCrossProduct = 3
}

local TableRefTypeName = {
    "table",
    "select",
    "join",
    "crossProduct"
}

local function getTableRefTypeStr(value)
    value = tonumber(value)

    if value == nil then
        return nil
    end

    local str = TableRefTypeName[value + 1]

    if str == nil then
        error("sqlparser: unknown table reference type: " ..
            tostring(value))
    end

    return str
end


local OrderType = {
    kOrderAsc = 0,
    kOrderDesc = 1
}

local OrderTypeName = {
    "asc",
    "desc"
}

local function getOrderTypeStr(value)
    value = tonumber(value)

    if value == nil then
        return nil
    end

    local str = OrderTypeName[value + 1]

    if str == nil then
        error("sqlparser: unknown ordering type: " ..
            tostring(value))
    end

    return str
end


local SetType = {
    kSetUnion = 0,
    kSetIntersect = 1,
    kSetExcept = 2
}

local SetTypeName = {
    "union",
    "intersect",
    "except"
}

local function getSetTypeStr(value)
    value = tonumber(value)

    if value == nil then
        return nil
    end

    local str = SetTypeName[value + 1]

    if str == nil then
        error("sqlparser: unknown set operation: " ..
            tostring(value))
    end

    return str
end


return {
    ExprType = ExprType,
    DatetimeField = DatetimeField,
    OperatorType = OperatorType,
    StatementType = StatementType,
    JoinType = JoinType,
    TableRefType = TableRefType,
    OrderType = OrderType,
    SetType = SetType,

    getExprTypeStr = getExprTypeStr,
    getDatetimeFieldStr = getDatetimeFieldStr,
    getOperatorTypeStr = getOperatorTypeStr,
    getStatementTypeStr = getStatementTypeStr,
    getJoinTypeStr = getJoinTypeStr,
    getTableRefTypeStr = getTableRefTypeStr,
    getOrderTypeStr = getOrderTypeStr,
    getSetTypeStr = getSetTypeStr
}
