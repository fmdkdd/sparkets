CLIENT_COFFEE := $(wildcard src/client/*.coffee) $(wildcard src/*.coffee)
CLIENT_JS := $(subst src, build, $(patsubst %.coffee, %.js, $(CLIENT_COFFEE)))
SERVER_COFFEE := $(wildcard src/server/*.coffee) $(wildcard src/*.coffee)
SERVER_JS := $(subst src, build, $(patsubst %.coffee, %.js, $(SERVER_COFFEE)))

all: $(CLIENT_JS) $(SERVER_JS)

build/%.js: src/%.coffee
	coffee -o $(dir $@) -c $<

clean:
	rm -f build/*.js
	rm -f build/client/*.js
	rm -f build/server/*.js
