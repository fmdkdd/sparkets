CLIENT_FILES := $(wildcard src/client/*.coffee) src/utils.coffee
SERVER_COFFEE := $(wildcard src/server/*.coffee) src/utils.coffee
SERVER_JS := $(subst src, build, $(patsubst %.coffee, %.js, $(SERVER_COFFEE)))

all: build/client.js $(SERVER_JS)

build/client.js: $(CLIENT_FILES)
	coffee -cj build/client.js $(CLIENT_FILES)

build/%.js: src/%.coffee
	coffee -o $(dir $@) -c $<

clean:
	rm -f build/*.js
	rm -f build/server/*.js
