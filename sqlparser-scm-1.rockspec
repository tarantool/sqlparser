package = "sqlparser"

version = "scm-1"

source = {
    url = "git+https://github.com/tarantool/sqlparser.git",
    branch = "master"
}

description = {
    summary  = "SQL parser for LuaJIT",
    detailed = [[
    An SQL parser for LuaJIT. It takes an SQL string as an input and returns an AST.
    The project is based on Hyrise SQL parser. It uses FFI to communicate with it.
    ]],
    homepage = "https://github.com/tarantool/sqlparser",
    maintainer = "Mike Siomkin <msiomkin@mail.ru>",
    license = "MIT"
}

dependencies = {
    "lua >= 5.1"
}

build = {
    type = "make",
    install_variables = {
        INST_PREFIX = "$(PREFIX)",
        INST_BINDIR = "$(BINDIR)",
        INST_LIBDIR = "$(LIBDIR)",
        INST_LUADIR = "$(LUADIR)",
        INST_CONFDIR = "$(CONFDIR)"
    }
}
