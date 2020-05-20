#include <cstddef>
#include <cstdint>
#include "LuaDataTypes.h"

extern "C" LuaSQLParserResult* parseSql(const char* query);
extern "C" void finalize(LuaSQLParserResult* result);
