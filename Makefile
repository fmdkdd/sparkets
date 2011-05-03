CLIENT_FILES := $(wildcard src/client/*.coffee) src/utils.coffee
SERVER_FILES := $(wildcard src/server/*.coffee) src/utils.coffee

all: client.js server.js

client.js: $(CLIENT_FILES)
	coffee -cj client.js $(CLIENT_FILES)

server.js: $(SERVER_FILES)
	coffee -cj server.js $(SERVER_FILES) src/server/launch-server.js

clean:
	rm -f client.js server.js