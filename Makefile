all: library

#######################################
############# Directories #############
#######################################
BIN        = hyrise/bin
SRC        = hyrise/src
SRCPARSER  = hyrise/src/parser

INSTALL     = /usr/local

######################################
############ Compile Mode ############
######################################
# Set compile mode to -g or -O3.
# Debug mode: make mode=debug

mode ?= release
MODE_LOG = ""
OPT_FLAG =
ifeq ($(mode), debug)
	OPT_FLAG = -g
	MODE_LOG = "Building in \033[1;31mdebug\033[0m mode"
else
	OPT_FLAG = -O3
	MODE_LOG = "Building in \033[0;32mrelease\033[0m mode ('make mode=debug' for debug mode)"
endif

GMAKE = make mode=$(mode)



#######################################
############### Library ###############
#######################################
NAME := sqlparser
PARSER_CPP = $(SRCPARSER)/bison_parser.cpp  $(SRCPARSER)/flex_lexer.cpp
PARSER_H   = $(SRCPARSER)/bison_parser.h    $(SRCPARSER)/flex_lexer.h
LIB_CFLAGS = -std=c++1z -Wall -Werror $(OPT_FLAG)

static ?= no
ifeq ($(static), yes)
	LIB_BUILD  = lib$(NAME).a
	LIBLINKER = $(AR)
	LIB_LFLAGS = rs
else
	LIB_BUILD  = lib$(NAME).so
	LIBLINKER = $(CXX)
	LIB_CFLAGS  +=  -fPIC
	LIB_LFLAGS = -shared -o
endif
LIB_CPP    = $(sort $(shell find $(SRC) -name '*.cpp' -not -path "$(SRCPARSER)/*") $(PARSER_CPP)) LuaSQLParser.cpp
LIB_H      = $(shell find $(SRC) -name '*.h' -not -path "$(SRCPARSER)/*") $(PARSER_H) LuaSQLParser.h
LIB_ALL    = $(shell find $(SRC) -name '*.cpp' -not -path "$(SRCPARSER)/*") $(shell find $(SRC) -name '*.h' -not -path "$(SRCPARSER)/*") LuaSQLParser.cpp LuaSQLParser.cpp
LIB_OBJ    = $(LIB_CPP:%.cpp=%.o)

library: $(LIB_BUILD)

$(LIB_BUILD): $(LIB_OBJ)
	$(LIBLINKER) $(LIB_LFLAGS) $(LIB_BUILD) $(LIB_OBJ)

$(SRCPARSER)/flex_lexer.o: $(SRCPARSER)/flex_lexer.cpp $(SRCPARSER)/bison_parser.cpp
	$(CXX) $(LIB_CFLAGS) -c -o $@ $< -Wno-sign-compare -Wno-unneeded-internal-declaration -Wno-register

%.o: %.cpp $(PARSER_CPP) $(LIB_H)
	$(CXX) $(LIB_CFLAGS) -c -o $@ $<

$(SRCPARSER)/bison_parser.cpp:
	$(GMAKE) -C $(SRCPARSER)/ bison_parser.cpp

$(SRCPARSER)/flex_lexer.cpp:
	$(GMAKE) -C $(SRCPARSER)/ flex_lexer.cpp

$(SRCPARSER)/bison_parser.h: $(SRCPARSER)/bison_parser.cpp
$(SRCPARSER)/flex_lexer.h: $(SRCPARSER)/flex_lexer.cpp

clean:
	rm -f lib$(NAME).a lib$(NAME).so
	rm -rf $(BIN)
	find $(SRC) -type f -name '*.o' -delete

cleanparser:
	$(GMAKE) -C $(SRCPARSER)/ clean

cleanall: clean cleanparser

install:
	cp libsqlparser.so $(INST_LIBDIR)
	cp sqlgen.lua $(INST_LUADIR)
	cp sqlparser.lua $(INST_LUADIR)
	cp sqlparserConst.lua $(INST_LUADIR)
	cp LuaDataTypes.h $(INST_LUADIR)



#######################################
############## Benchmark ##############
#######################################
BM_BUILD  = $(BIN)/benchmark
BM_CFLAGS = -std=c++17 -Wall -Isrc/ -L./ $(OPT_FLAG)
BM_PATH   = hyrise/benchmark
BM_CPP    = $(shell find $(BM_PATH)/ -name '*.cpp')
BM_ALL    = $(shell find $(BM_PATH)/ -name '*.cpp' -or -name '*.h')

benchmark: $(BM_BUILD)

run_benchmarks: benchmark
	./$(BM_BUILD) --benchmark_counters_tabular=true
	# --benchmark_filter="abc

save_benchmarks: benchmark
	./$(BM_BUILD) --benchmark_format=csv > benchmarks.csv

$(BM_BUILD): $(BM_ALL) $(LIB_BUILD)
	@mkdir -p $(BIN)/
	$(CXX) $(BM_CFLAGS) $(BM_CPP) -o $(BM_BUILD) -lbenchmark -lpthread -lsqlparser -lstdc++ -lstdc++fs



########################################
############ Test & Example ############
########################################
TEST_BUILD   = $(BIN)/tests
TEST_CFLAGS   = -std=c++1z -Wall -Werror -Ihyrise/src/ -Ihyrise/test/ -L./ $(OPT_FLAG)
TEST_CPP     = $(shell find hyrise/test/ -name '*.cpp')
TEST_ALL     = $(shell find hyrise/test/ -name '*.cpp') $(shell find hyrise/test/ -name '*.h')
EXAMPLE_SRC  = $(shell find example/ -name '*.cpp') $(shell find example/ -name '*.h')

.PHONY: test
test:
	cd test && ./test.lua

.PHONY: test-example
test-example:
	./example.lua


########################################
################# Misc #################
########################################

format:
	astyle --options=astyle.options $(LIB_ALL)
	astyle --options=astyle.options $(TEST_ALL)
	astyle --options=astyle.options $(EXAMPLE_SRC)

log_mode:
	@echo $(MODE_LOG)

