return {
    ExprType = {
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
    },

    DatetimeField = {
        kDatetimeNone = 0,
        kDatetimeSecond = 1,
        kDatetimeMinute = 2,
        kDatetimeHour = 3,
        kDatetimeDay = 4,
        kDatetimeMonth = 5,
        kDatetimeYear = 6
    },

    OperatorType = {
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
    },

    StatementType = {
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
    },

    JoinType = {
        kJoinInner = 0,
        kJoinFull = 1,
        kJoinLeft = 2,
        kJoinRight = 3,
        kJoinCross = 4,
        kJoinNatural = 5
    },

    TableRefType = {
        kTableName = 0,
        kTableSelect = 1,
        kTableJoin = 2,
        kTableCrossProduct = 3
    },

    OrderType = {
        kOrderAsc = 0,
        kOrderDesc = 1
    },

    SetType = {
        kSetUnion = 0,
        kSetIntersect = 1,
        kSetExcept = 2
    }
}
