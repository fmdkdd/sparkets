CLIENT_COFFEE := $(wildcard src/client/*.coffee) $(wildcard src/*.coffee)
CLIENT_JS := $(subst src, build, $(patsubst %.coffee, %.js, $(CLIENT_COFFEE)))
SERVER_COFFEE := $(wildcard src/server/*.coffee) $(wildcard src/*.coffee)
SERVER_JS := $(subst src, build, $(patsubst %.coffee, %.js, $(SERVER_COFFEE)))

TEST_COFFEE := $(wildcard test/src/*.coffee)
TEST_JS := $(subst test/src, test/build, $(patsubst %.coffee, %.js, $(TEST_COFFEE)))

all: $(CLIENT_JS) $(SERVER_JS)

build/%.js: src/%.coffee
	coffee -o $(dir $@) -c $<

test/build/%.js: test/src/%.coffee
	coffee -bo $(dir $@) -c $<

test: all $(TEST_JS)
	vows test/build/*

clean:
	rm -f build/*.js
	rm -f build/client/*.js
	rm -f build/server/*.js
	rm -f test/build/*.js

.PHONY: all clean test
