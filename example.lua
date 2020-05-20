#!/usr/bin/env tarantool

local log = require("log")
local sqlParser = require("sqlParser")

local result = sqlParser.parse("select a from test;")

log.info(result)
