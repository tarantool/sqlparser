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
    "errorLine": 0,
    "statements": [
        {
            "fromTable": {
                "type": "table",
                "name": "test"
            },
            "selectList": [
                {
                    "type": "columnRef",
                    "name": "a"
                }
            ],
            "selectDistinct": false,
            "type": "select"
        }
    ],
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
