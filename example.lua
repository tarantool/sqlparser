#!/usr/bin/env tarantool

local log = require("log")
local parser = require("sqlparser")

local ast = parser.parse("select a from test;")

log.info(ast)

local queries = parser.tostring(ast)

log.info(queries[1])
