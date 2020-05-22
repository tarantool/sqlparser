enum ExprType {
    kExprLiteralFloat,
    kExprLiteralString,
    kExprLiteralInt,
    kExprLiteralNull,
    kExprStar,
    kExprParameter,
    kExprColumnRef,
    kExprFunctionRef,
    kExprOperator,
    kExprSelect,
    kExprHint,
    kExprArray,
    kExprArrayIndex,
    kExprDatetimeField
};

enum DatetimeField {
    kDatetimeNone,
    kDatetimeSecond,
    kDatetimeMinute,
    kDatetimeHour,
    kDatetimeDay,
    kDatetimeMonth,
    kDatetimeYear
};

enum OperatorType {
    kOpNone,

    // Ternary operator
    kOpBetween,

    // n-nary special case
    kOpCase,
    kOpCaseListElement,  // `WHEN expr THEN expr`

    // Binary operators.
    kOpPlus,
    kOpMinus,
    kOpAsterisk,
    kOpSlash,
    kOpPercentage,
    kOpCaret,

    kOpEquals,
    kOpNotEquals,
    kOpLess,
    kOpLessEq,
    kOpGreater,
    kOpGreaterEq,
    kOpLike,
    kOpNotLike,
    kOpILike,
    kOpAnd,
    kOpOr,
    kOpIn,
    kOpConcat,

    // Unary operators.
    kOpNot,
    kOpUnaryMinus,
    kOpIsNull,
    kOpExists
};

enum StatementType {
    kStmtError, // unused
    kStmtSelect,
    kStmtImport,
    kStmtInsert,
    kStmtUpdate,
    kStmtDelete,
    kStmtCreate,
    kStmtDrop,
    kStmtPrepare,
    kStmtExecute,
    kStmtExport,
    kStmtRename,
    kStmtAlter,
    kStmtShow,
    kStmtTransaction
};

enum JoinType {
    kJoinInner,
    kJoinFull,
    kJoinLeft,
    kJoinRight,
    kJoinCross,
    kJoinNatural
};

enum TableRefType {
    kTableName,
    kTableSelect,
    kTableJoin,
    kTableCrossProduct
};

enum OrderType {
    kOrderAsc,
    kOrderDesc
};

enum SetType {
    kSetUnion,
    kSetIntersect,
    kSetExcept
};

struct LuaExpr;
struct LuaAlias;
struct LuaJoinDefinition;
struct LuaTableRef;
struct LuaOrderDescription;
struct LuaLimitDescription;
struct LuaGroupByDescription;
struct LuaWithDescription;
struct LuaSetOperation;
struct LuaSQLStatement;
struct LuaSelectStatement;
struct LuaInsertStatement;
struct LuaUpdateStatement;
struct LuaDeleteStatement;
struct LuaSQLParserResult;

// Represents SQL expressions (i.e. literals, operators, column_refs).
typedef struct LuaExpr {
    enum ExprType type;

    struct LuaExpr* expr;
    struct LuaExpr* expr2;
    size_t exprListSize;
    
    struct LuaExpr** exprList;
    struct LuaSelectStatement* select;

    char* name;
    char* table;
    char* alias;
    double fval;
    int64_t ival;
    int64_t ival2;
    enum DatetimeField datetimeField;
    bool isBoolLiteral;

    enum OperatorType opType;
    bool distinct;
} LuaExpr;

typedef struct LuaTableName {
    char* schema;
    char* name;
} LuaTableName;

typedef struct LuaAlias {
    char* name;
    
    size_t columnCount;
    char** columns;
} LuaAlias;

struct LuaTableRef;

// Definition of a join construct.
typedef struct LuaJoinDefinition {
    struct LuaTableRef* left;
    struct LuaTableRef* right;
    struct LuaExpr* condition;

    enum JoinType type;
} LuaJoinDefinition;

// Holds reference to tables. Can be either table names or a select statement.
typedef struct LuaTableRef {
    enum TableRefType type;

    char* schema;
    char* name;
    struct LuaAlias* alias;

    struct LuaSelectStatement* select;
    
    size_t listSize;
    struct LuaTableRef** list;
    
    struct LuaJoinDefinition* join;
} LuaTableRef;

// Description of the group-by clause within a select statement.
typedef struct LuaGroupByDescription {
    size_t columnCount;
    struct LuaExpr** columns;
    
    struct LuaExpr* having;
} LuaGroupByDescription;

// union, intersect or except
typedef struct LuaSetOperation {
    enum SetType setType;
    bool isAll;

    struct LuaSelectStatement* nestedSelectStatement;
    
    size_t resultOrderCount;
    struct LuaOrderDescription** resultOrder;
    
    struct LuaLimitDescription* resultLimit;
} LuaSetOperation;

// Description of the order by clause within a select statement.
typedef struct LuaOrderDescription {
    enum OrderType type;
    struct LuaExpr* expr;
} LuaOrderDescription;

typedef struct LuaWithDescription {
    char* alias;
    struct LuaSelectStatement* select;
} LuaWithDescription;

// Description of the limit clause within a select statement.
typedef struct LuaLimitDescription {
    struct LuaExpr* limit;
    struct LuaExpr* offset;
} LuaLimitDescription;

typedef struct LuaSQLStatement {
    enum StatementType type;
    size_t stringLength;
    size_t hintCount;
    struct LuaExpr** hints;
} LuaSQLStatement;

// Representation of a full SQL select statement.
typedef struct LuaSelectStatement {
    struct LuaSQLStatement base;

    struct LuaTableRef* fromTable;
    bool selectDistinct;
    
    size_t selectListSize;
    struct LuaExpr** selectList;

    struct LuaExpr* whereClause;

    struct LuaGroupByDescription* groupBy;
    
    size_t setOperationCount;
    struct LuaSetOperation** setOperations;
    
    size_t orderCount;
    struct LuaOrderDescription** order;
    
    size_t withDescriptionCount;
    struct LuaWithDescription** withDescriptions;
    
    struct LuaLimitDescription* limit;
} LuaSelectStatement;

typedef struct LuaInsertStatement {
    // TODO: define members
} LuaInsertStatement;

typedef struct LuaUpdateStatement {
    // TODO: define members
} LuaUpdateStatement;

typedef struct LuaDeleteStatement {
    // TODO: define members
} LuaDeleteStatement;

typedef struct LuaSQLParserResult {
    bool isValid;
    char* errorMsg;
    int errorLine;
    int errorColumn;
    
    size_t statementCount;
    struct LuaSQLStatement** statements;
} LuaSQLParserResult;
