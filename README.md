# luajit-sql-parser

An SQL parser for LuaJIT based on [Hyrise](https://github.com/hyrise/sql-parser) parser.

Usage:

```Lua
local sqlParser = require("sqlParser")

local result = sqlParser.parse("select a from test;")
```

`result` variable now contains:

```json
{
    "parameters": [],
    "statementCount": 1,
    "errorLine": 0,
    "statements": [
        {
            "setOperationCount": 0,
            "fromTable": {
                "type": 0,
                "name": "test",
                "listSize": 0
            },
            "selectDistinct": false,
            "orderCount": 0,
            "hintCount": 0,
            "selectList": [
                {
                    "ival2": 0,
                    "exprListSize": 0,
                    "distinct": false,
                    "isBoolLiteral": false,
                    "opType": 0,
                    "datetimeField": 0,
                    "type": 6,
                    "ival": 0,
                    "name": "a",
                    "fval": 0
                }
            ],
            "type": 1,
            "withDescriptionCount": 0,
            "selectListSize": 1
        }
    ],
    "parameterCount": 0,
    "isValid": true
}
```
