CLIENT_COFFEE := $(wildcard src/client/*.coffee) $(wildcard src/*.coffee)
CLIENT_JS := $(subst src, build, $(patsubst %.coffee, %.js, $(CLIENT_COFFEE)))
SERVER_COFFEE := $(wildcard src/server/*.coffee) $(wildcard src/*.coffee)
SERVER_JS := $(subst src, build, $(patsubst %.coffee, %.js, $(SERVER_COFFEE)))

COFFEE_CMD := ./node_modules/coffee-script/bin/coffee
VOWS_CMD := ./node_modules/vows/bin/vows

all: $(CLIENT_JS) $(SERVER_JS)

build/%.js: src/%.coffee
	$(COFFEE_CMD) -o $(dir $@) -c $<

test/build/%.js: test/src/%.coffee
	$(COFFEE_CMD) -bo $(dir $@) -c $<

test: all
	$(VOWS_CMD) test/*.coffee

clean:
	rm -f build/*.js
	rm -f build/client/*.js
	rm -f build/server/*.js

.PHONY: all clean test
