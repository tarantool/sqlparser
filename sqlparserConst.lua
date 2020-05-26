local ExprTypeStr = {
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

    local str = ExprTypeStr[value + 1]

    if str == nil then
        error("sqlparser: unknown expression type: " ..
            tostring(value))
    end

    return str
end


local DatetimeFieldStr = {
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

    local str = DatetimeFieldStr[value + 1]

    if str == nil then
        error("sqlparser: unknown date-time field: " ..
            tostring(value))
    end

    return str
end


local OperatorType = {
    None = 0,

    -- Ternary operator
    Between = 1,

    -- n-nary special case
    Case = 2,
    CaseListElement = 3, -- `WHEN expr THEN expr`

    -- Binary operators.
    Plus = 4,
    Minus = 5,
    Asterisk = 6,
    Slash = 7,
    Percentage = 8,
    Caret = 9,

    Equals = 10,
    NotEquals = 11,
    Less = 12,
    LessEq = 13,
    Greater = 14,
    GreaterEq = 15,
    Like = 16,
    NotLike = 17,
    iLike = 18,
    And = 19,
    Or = 20,
    In = 21,
    Concat = 22,

    -- Unary operators.
    Not = 23,
    UnaryMinus = 24,
    IsNull = 25,
    Exists = 26
}

local OperatorTypeStr = {
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

    local str = OperatorTypeStr[value + 1]

    if str == nil then
        error("sqlparser: unknown operator type: " ..
            tostring(value))
    end

    return str
end


local StatementTypeStr = {
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

    local str = StatementTypeStr[value + 1]

    if str == nil then
        error("sqlparser: unknown statement type: " ..
            tostring(value))
    end

    return str
end


local JoinTypeStr = {
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

    local str = JoinTypeStr[value + 1]

    if str == nil then
        error("sqlparser: unknown join type: " ..
            tostring(value))
    end

    return str
end


local TableRefTypeStr = {
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

    local str = TableRefTypeStr[value + 1]

    if str == nil then
        error("sqlparser: unknown table reference type: " ..
            tostring(value))
    end

    return str
end


local OrderTypeStr = {
    "asc",
    "desc"
}

local function getOrderTypeStr(value)
    value = tonumber(value)

    if value == nil then
        return nil
    end

    local str = OrderTypeStr[value + 1]

    if str == nil then
        error("sqlparser: unknown ordering type: " ..
            tostring(value))
    end

    return str
end


local SetTypeStr = {
    "union",
    "intersect",
    "except"
}

local function getSetTypeStr(value)
    value = tonumber(value)

    if value == nil then
        return nil
    end

    local str = SetTypeStr[value + 1]

    if str == nil then
        error("sqlparser: unknown set operation: " ..
            tostring(value))
    end

    return str
end


return {
    OperatorType = OperatorType,

    getExprTypeStr = getExprTypeStr,
    getDatetimeFieldStr = getDatetimeFieldStr,
    getOperatorTypeStr = getOperatorTypeStr,
    getStatementTypeStr = getStatementTypeStr,
    getJoinTypeStr = getJoinTypeStr,
    getTableRefTypeStr = getTableRefTypeStr,
    getOrderTypeStr = getOrderTypeStr,
    getSetTypeStr = getSetTypeStr
}
