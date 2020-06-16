#include <cstring>
#include "hyrise/src/SQLParser.h"
#include "LuaSQLParser.h"


LuaExpr* copyExpr(const hsql::Expr* expr);
void freeExpr(LuaExpr* luaExpr);

LuaExpr** copyExprArr(const std::vector<hsql::Expr*>* v);
void freeExprArr(LuaExpr** arr, size_t count);

LuaJoinDefinition* copyJoinDefinition(const hsql::JoinDefinition* joinDef);
void freeJoinDefinition(LuaJoinDefinition* luaJoinDef);

LuaAlias* copyAlias(const hsql::Alias* alias);
void freeAlias(LuaAlias* luaAlias);

LuaTableRef* copyTableRef(const hsql::TableRef* tableRef);
void freeTableRef(LuaTableRef* luaTableRef);

LuaGroupByDescription* copyGroupByDescription(
    const hsql::GroupByDescription* groupBy);
void freeGroupByDescription(LuaGroupByDescription* luaGroupBy);

LuaSetOperation* copySetOperation(const hsql::SetOperation* setOp);
void freeSetOperation(LuaSetOperation* luaSetOp);

LuaOrderDescription* copyOrderDescription(
    const hsql::OrderDescription* orderDesc);
void freeOrderDescription(LuaOrderDescription* luaOrderDesc);

LuaWithDescription* copyWithDescription(
    const hsql::WithDescription* withDesc);
void freeWithDescription(LuaWithDescription* luaWithDesc);

LuaLimitDescription* copyLimitDescription(
    const hsql::LimitDescription* limitDesc);
void freeLimitDescription(LuaLimitDescription* luaLimitDesc);

LuaSelectStatement* copySelectStatement(
    const hsql::SelectStatement* statement);
void freeSelectStatement(LuaSelectStatement* luaStatement);

LuaSQLStatement* copySQLStatement(const hsql::SQLStatement* statement);
void freeSQLStatement(LuaSQLStatement* luaStatement);

LuaSQLParserResult* copySQLParserResult(hsql::SQLParserResult* result);
void freeSQLParserResult(LuaSQLParserResult* result);


template<class ItemSrc, class ItemDst>
ItemDst** copyArr(const std::vector<ItemSrc*>* v,
    ItemDst* (*copyArrItem)(const ItemSrc*))
{
    if (v == 0)
        return 0;

    size_t n = v->size();

    ItemDst** arr = (ItemDst**)std::malloc(
        n * sizeof(ItemDst*));

    for (size_t i = 0; i < n; i++)
        arr[i] = copyArrItem((*v)[i]);

    return arr;
}

template<class Item>
void freeArr(Item** arr, size_t count, void (*freeArrItem)(Item*))
{
    if (arr == 0)
        return;

    for (size_t i = 0; i < count; i++)
        freeArrItem(arr[i]);

    free(arr);
}

char* copyStr(const char* str)
{
    if (str == 0)
        return 0;

    size_t n = strlen(str) + 1;
    char* strCopy = (char*)std::malloc(n);
    std::memcpy(strCopy, str, n);

    return strCopy;
}

inline void freeStr(char* str)
{
    if (str != 0)
        free(str);
}

void freeStrArr(char** arr, size_t count)
{
    freeArr<char>(arr, count, freeStr);
}

LuaExpr* copyExpr(const hsql::Expr* expr)
{
    if (expr == 0)
        return 0;

    LuaExpr* luaExpr = (LuaExpr*)std::malloc(sizeof(LuaExpr));

    luaExpr->type = (ExprType)expr->type;

    luaExpr->expr = copyExpr(expr->expr);
    luaExpr->expr2 = copyExpr(expr->expr2);

    if (expr->exprList != 0)
        luaExpr->exprListSize = expr->exprList->size();
    else
        luaExpr->exprListSize = 0;

    luaExpr->exprList = copyExprArr(expr->exprList);

    luaExpr->select = copySelectStatement(expr->select);

    luaExpr->name = copyStr(expr->name);
    luaExpr->table = copyStr(expr->table);
    luaExpr->alias = copyStr(expr->alias);
    luaExpr->fval = expr->fval;
    luaExpr->ival = expr->ival;
    luaExpr->ival2 = expr->ival2;
    luaExpr->datetimeField = (DatetimeField)expr->datetimeField;
    luaExpr->columnType = (ColumnType)expr->columnType.data_type;
    luaExpr->columnLength = expr->columnType.length;
    luaExpr->isBoolLiteral = expr->isBoolLiteral;

    luaExpr->opType = (OperatorType)expr->opType;
    luaExpr->distinct = expr->distinct;

    return luaExpr;
}

void freeExpr(LuaExpr* luaExpr)
{
    if (luaExpr == 0)
        return;

    freeExpr(luaExpr->expr);
    freeExpr(luaExpr->expr2);

    freeArr<LuaExpr>(luaExpr->exprList, luaExpr->exprListSize, freeExpr);

    freeSelectStatement(luaExpr->select);

    freeStr(luaExpr->name);
    freeStr(luaExpr->table);
    freeStr(luaExpr->alias);

    free(luaExpr);
}

LuaExpr** copyExprArr(const std::vector<hsql::Expr*>* v)
{
    return copyArr<hsql::Expr, LuaExpr>(v, copyExpr);
}

void freeExprArr(LuaExpr** arr, size_t count)
{
    freeArr<LuaExpr>(arr, count, freeExpr);
}

LuaJoinDefinition* copyJoinDefinition(const hsql::JoinDefinition* joinDef)
{
    if (joinDef == 0)
        return 0;

    LuaJoinDefinition* luaJoinDef = (LuaJoinDefinition*)std::malloc(
        sizeof(LuaJoinDefinition));

    luaJoinDef->left = copyTableRef(joinDef->left);
    luaJoinDef->right = copyTableRef(joinDef->right);
    luaJoinDef->condition = copyExpr(joinDef->condition);

    luaJoinDef->type = (JoinType)joinDef->type;

    return luaJoinDef;
}

void freeJoinDefinition(LuaJoinDefinition* luaJoinDef)
{
    if (luaJoinDef == 0)
        return;

    freeTableRef(luaJoinDef->left);
    freeTableRef(luaJoinDef->right);
    freeExpr(luaJoinDef->condition);

    free(luaJoinDef);
}

LuaAlias* copyAlias(const hsql::Alias* alias)
{
    if (alias == 0)
        return 0;

    LuaAlias* luaAlias = (LuaAlias*)std::malloc(
        sizeof(LuaAlias));

    luaAlias->name = copyStr(alias->name);

    if (alias->columns != 0)
        luaAlias->columnCount = alias->columns->size();
    else
        luaAlias->columnCount = 0;

    luaAlias->columns = copyArr<char, char>(alias->columns, copyStr);

    return luaAlias;
}

void freeAlias(LuaAlias* luaAlias)
{
    if (luaAlias == 0)
        return;

    freeStr(luaAlias->name);
    freeStrArr(luaAlias->columns, luaAlias->columnCount);

    free(luaAlias);
}

LuaTableRef* copyTableRef(const hsql::TableRef* tableRef)
{
    if (tableRef == 0)
        return 0;

    LuaTableRef* luaTableRef = (LuaTableRef*)std::malloc(
        sizeof(LuaTableRef));

    luaTableRef->type = (TableRefType)tableRef->type;

    luaTableRef->schema = copyStr(tableRef->schema);
    luaTableRef->name = copyStr(tableRef->name);
    luaTableRef->alias = copyAlias(tableRef->alias);

    luaTableRef->select = copySelectStatement(tableRef->select);

    if (tableRef->list != 0)
        luaTableRef->listSize = tableRef->list->size();
    else
        luaTableRef->listSize = 0;

    luaTableRef->list = copyArr<hsql::TableRef, LuaTableRef>(
        tableRef->list, copyTableRef);

    luaTableRef->join = copyJoinDefinition(tableRef->join);

    return luaTableRef;
}

void freeTableRef(LuaTableRef* luaTableRef)
{
    if (luaTableRef == 0)
        return;

    freeStr(luaTableRef->schema);
    freeStr(luaTableRef->name);
    freeAlias(luaTableRef->alias);

    freeSelectStatement(luaTableRef->select);

    freeArr<LuaTableRef>(luaTableRef->list, luaTableRef->listSize,
        freeTableRef);

    freeJoinDefinition(luaTableRef->join);

    free(luaTableRef);
}

LuaGroupByDescription* copyGroupByDescription(
    const hsql::GroupByDescription* groupBy)
{
    if (groupBy == 0)
        return 0;

    LuaGroupByDescription* luaGroupBy =
        (LuaGroupByDescription*)std::malloc(
            sizeof(LuaGroupByDescription));

    if (groupBy->columns != 0)
        luaGroupBy->columnCount = groupBy->columns->size();
    else
        luaGroupBy->columnCount = 0;

    luaGroupBy->columns = copyExprArr(groupBy->columns);

    luaGroupBy->having = copyExpr(groupBy->having);

    return luaGroupBy;
}

void freeGroupByDescription(LuaGroupByDescription* luaGroupBy)
{
    if (luaGroupBy == 0)
        return;

    freeExprArr(luaGroupBy->columns, luaGroupBy->columnCount);
    freeExpr(luaGroupBy->having);

    free(luaGroupBy);
}

LuaSetOperation* copySetOperation(const hsql::SetOperation* setOp)
{
    if (setOp == 0)
        return 0;

    LuaSetOperation* luaSetOp = (LuaSetOperation*)std::malloc(
        sizeof(LuaSetOperation));

    luaSetOp->setType = (SetType)setOp->setType;
    luaSetOp->isAll = setOp->isAll;

    luaSetOp->nestedSelectStatement = copySelectStatement(
        setOp->nestedSelectStatement);

    if (setOp->resultOrder != 0)
        luaSetOp->resultOrderCount = setOp->resultOrder->size();
    else
        luaSetOp->resultOrderCount = 0;

    luaSetOp->resultOrder =
        copyArr<hsql::OrderDescription, LuaOrderDescription>(
            setOp->resultOrder, copyOrderDescription);

    luaSetOp->resultLimit = copyLimitDescription(setOp->resultLimit);

    return luaSetOp;
}

void freeSetOperation(LuaSetOperation* luaSetOp)
{
    if (luaSetOp == 0)
        return;

    freeSelectStatement(luaSetOp->nestedSelectStatement);

    freeArr<LuaOrderDescription>(luaSetOp->resultOrder,
        luaSetOp->resultOrderCount, freeOrderDescription);

    freeLimitDescription(luaSetOp->resultLimit);

    free(luaSetOp);
}

LuaOrderDescription* copyOrderDescription(
    const hsql::OrderDescription* orderDesc)
{
    if (orderDesc == 0)
        return 0;

    LuaOrderDescription* luaOrderDesc = (LuaOrderDescription*)std::malloc(
        sizeof(LuaOrderDescription));

    luaOrderDesc->type = (OrderType)orderDesc->type;
    luaOrderDesc->expr = copyExpr(orderDesc->expr);

    return luaOrderDesc;
}

void freeOrderDescription(LuaOrderDescription* luaOrderDesc)
{
    if (luaOrderDesc == 0)
        return;

    freeExpr(luaOrderDesc->expr);

    free(luaOrderDesc);
}

LuaWithDescription* copyWithDescription(const hsql::WithDescription* withDesc)
{
    if (withDesc == 0)
        return 0;

    LuaWithDescription* luaWithDesc = (LuaWithDescription*)std::malloc(
        sizeof(LuaWithDescription));

    luaWithDesc->alias = copyStr(withDesc->alias);
    luaWithDesc->select = copySelectStatement(withDesc->select);

    return luaWithDesc;
}

void freeWithDescription(LuaWithDescription* luaWithDesc)
{
    if (luaWithDesc == 0)
        return;

    freeStr(luaWithDesc->alias);
    freeSelectStatement(luaWithDesc->select);

    free(luaWithDesc);
}

LuaLimitDescription* copyLimitDescription(
    const hsql::LimitDescription* limitDesc)
{
    if (limitDesc == 0)
        return 0;

    LuaLimitDescription* luaLimitDesc = (LuaLimitDescription*)std::malloc(
        sizeof(LuaLimitDescription));

    luaLimitDesc->limit = copyExpr(limitDesc->limit);
    luaLimitDesc->offset = copyExpr(limitDesc->offset);

    return luaLimitDesc;
}

void freeLimitDescription(LuaLimitDescription* luaLimitDesc)
{
    if (luaLimitDesc == 0)
        return;

    freeExpr(luaLimitDesc->limit);
    freeExpr(luaLimitDesc->offset);

    free(luaLimitDesc);
}

void fillSQLStatement(const hsql::SQLStatement* statement,
    LuaSQLStatement* luaStatement)
{
    luaStatement->type = (StatementType)statement->type();

    luaStatement->stringLength = statement->stringLength;

    if (statement->hints != 0)
        luaStatement->hintCount = statement->hints->size();
    else
        luaStatement->hintCount = 0;

    luaStatement->hints = copyExprArr(statement->hints);
}

LuaSelectStatement* copySelectStatement(const hsql::SelectStatement* statement)
{
    if (statement == 0)
        return 0;

    LuaSelectStatement* luaStatement = (LuaSelectStatement*)std::malloc(
        sizeof(LuaSelectStatement));

    fillSQLStatement(statement, &luaStatement->base);

    luaStatement->fromTable = copyTableRef(statement->fromTable);

    luaStatement->selectDistinct = statement->selectDistinct;

    if (statement->selectList != 0)
        luaStatement->selectListSize = statement->selectList->size();
    else
        luaStatement->selectListSize = 0;

    luaStatement->selectList = copyExprArr(statement->selectList);
    
    luaStatement->whereClause = copyExpr(statement->whereClause);

    luaStatement->groupBy = copyGroupByDescription(statement->groupBy);

    if (statement->setOperations != 0)
        luaStatement->setOperationCount = statement->setOperations->size();
    else
        luaStatement->setOperationCount = 0;

    luaStatement->setOperations =
        copyArr<hsql::SetOperation, LuaSetOperation>(
            statement->setOperations, copySetOperation);

    if (statement->order != 0)
        luaStatement->orderCount = statement->order->size();
    else
        luaStatement->orderCount = 0;

    luaStatement->order =
        copyArr<hsql::OrderDescription, LuaOrderDescription>(
            statement->order, copyOrderDescription);

    if (statement->withDescriptions != 0)
        luaStatement->withDescriptionCount =
            statement->withDescriptions->size();
    else
        luaStatement->withDescriptionCount = 0;

    luaStatement->withDescriptions =
        copyArr<hsql::WithDescription, LuaWithDescription>(
            statement->withDescriptions, copyWithDescription);

    luaStatement->limit = copyLimitDescription(statement->limit);

    return luaStatement;
}

void freeSelectStatement(LuaSelectStatement* luaStatement)
{
    if (luaStatement == 0)
        return;

    freeTableRef(luaStatement->fromTable);
    freeExprArr(luaStatement->selectList, luaStatement->selectListSize);
    freeExpr(luaStatement->whereClause);
    freeGroupByDescription(luaStatement->groupBy);

    freeArr<LuaSetOperation>(luaStatement->setOperations,
        luaStatement->setOperationCount, freeSetOperation);

    freeArr<LuaOrderDescription>(luaStatement->order,
        luaStatement->orderCount, freeOrderDescription);

    freeArr<LuaWithDescription>(luaStatement->withDescriptions,
        luaStatement->withDescriptionCount, freeWithDescription);

    freeLimitDescription(luaStatement->limit);

    free(luaStatement);
}

LuaSQLStatement* copySQLStatement(const hsql::SQLStatement* statement)
{
    if (statement == 0)
        return 0;

    LuaSQLStatement* luaStatement;

    hsql::StatementType statementType = statement->type();

    switch (statementType) {
        case StatementType::kStmtSelect:
            luaStatement = (LuaSQLStatement*)copySelectStatement(
                (hsql::SelectStatement*)statement);
            break;
        // case StatementType::kStmtInsert:
        //     // TODO: copy insert statement
        //     break;
        // case StatementType::kStmtUpdate:
        //     // TODO: copy update statement
        //     break;
        // case StatementType::kStmtDelete:
        //     // TODO: copy delete statement
        //     break;
        default:
            luaStatement = (LuaSQLStatement*)std::malloc(
                sizeof(LuaSQLStatement));
            fillSQLStatement(statement, luaStatement);
            break;
    }

    return luaStatement;
}

void freeSQLStatement(LuaSQLStatement* luaStatement)
{
    if (luaStatement == 0)
        return;

    freeExprArr(luaStatement->hints, luaStatement->hintCount);

    StatementType statementType = luaStatement->type;

    switch (statementType) {
        case StatementType::kStmtSelect:
            freeSelectStatement((LuaSelectStatement*)luaStatement);
            break;
        // case StatementType::kStmtInsert:
        //     // TODO: free insert statement
        //     break;
        // case StatementType::kStmtUpdate:
        //     // TODO: free update statement
        //     break;
        // case StatementType::kStmtDelete:
        //     // TODO: free delete statement
        //     break;
        default:
            free(luaStatement);
            break;
    }
}

LuaSQLParserResult* copySQLParserResult(hsql::SQLParserResult* result)
{
    if (result == 0)
        return 0;

    LuaSQLParserResult* luaResult = (LuaSQLParserResult*)std::malloc(
        sizeof(LuaSQLParserResult));
    luaResult->errorMsg = 0;
    luaResult->errorLine = 0;
    luaResult->errorColumn = 0;
    luaResult->statementCount = 0;
    luaResult->statements = 0;

    bool isValid = result->isValid();
    luaResult->isValid = isValid;

    if (isValid) {
        const std::vector<hsql::SQLStatement*>& statements =
            result->getStatements();

        luaResult->statementCount = result->size();
        luaResult->statements =
            copyArr<hsql::SQLStatement, LuaSQLStatement>(
                &statements, copySQLStatement);
    }
    else {
        luaResult->errorMsg = copyStr(result->errorMsg());
        luaResult->errorLine = result->errorLine();
        luaResult->errorColumn = result->errorColumn();
    }

    return luaResult;
}

void freeSQLParserResult(LuaSQLParserResult* luaResult)
{
    if (luaResult == 0)
        return;

    freeArr<LuaSQLStatement>(luaResult->statements,
        luaResult->statementCount, freeSQLStatement);

    freeStr(luaResult->errorMsg);

    free(luaResult);
}

LuaSQLParserResult* parseSql(const char* query)
{
    hsql::SQLParserResult result;
    hsql::SQLParser::parse(std::string(query), &result);

    LuaSQLParserResult* luaResult = copySQLParserResult(&result);
    return luaResult;
}

void finalize(LuaSQLParserResult* result)
{
    freeSQLParserResult(result);
}
