#!/usr/bin/env tarantool

local fio = require("fio")
local jsonLib = require("json")
local tap = require("tap")
local yamlLib = require("yaml")

package.path = package.path .. ";../?.lua"
package.cpath = package.cpath .. ";../?.so"
local parser = require("sqlparser")


local function readFromFile(path)
    local file, err = fio.open(path, "O_RDONLY")
    if file == nil then
        error(("Can not open file: '%s', error: %s"):format(
            fio.abspath(path), err))
    end

    local ok, data = pcall(file.read, file)
    file:close()

    if not ok then
        error(("Can not read from file: '%s', error: %s"):format(
            fio.abspath(path), data))
    end

    return yamlLib.decode(data)
end

local function testSql(test, queryOrig, queryGen)
    test:plan(2)

    test:diag("Testing query: " .. queryOrig)

    local ast = parser.parse(queryOrig)

    test:diag("AST: " .. jsonLib.encode(ast))
    test:is(ast.isValid, true, "Parsed successfully")

    queryGen = queryGen or queryOrig
    queryGen = queryGen:gsub("%(%s+", "(")

    local queries = parser.tostring(ast)
    local query = queries[1]

    return test:is(query, queryGen, "The generated query coincides with the sample")
end


local breakOnErr = false
local n = #arg
for i = 1, n do
    local a = arg[i]
    if a == "break" or a == "-x" then
        breakOnErr = true
        break
    end
end

local queries = readFromFile("queries.yml")

local test = tap.test("Tarantool SQL Parser Test")

test:plan(#queries)

for _, row in ipairs(queries) do
    test:test(row[1], function(test)
        local passed = testSql(test, row[2], row[3])

        if not passed and breakOnErr then
            os.exit(1)
        end
    end)
end

os.exit(test:check() and 0 or 1)
