# Tarantool SQL Parser

An SQL parser for LuaJIT. It takes an SQL string as an input and returns an AST.
The project is based on [Hyrise SQL parser](https://github.com/hyrise/sql-parser). It uses FFI to communicate with it.

## Requirements:

- gcc 5+ or clang 5+

## Installation:

```shell
tarantoolctl rocks install sqlparser
```

## Usage:

```Lua
local parser = require("sqlparser")

local ast = parser.parse("select a from test;")
```

`ast` variable now contains:

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

And backwards:

```Lua
local queries = parser.tostring(ast)
```

`queries[1]` is:

```
select "a" from "test";
```
