#!/usr/bin/env tarantool

local log = require("log")
local sqlparser = require("sqlparser")

local result = sqlparser.parse("select a from test;")

log.info(result)
