CLIENT_FILES := $(wildcard src/client/*.coffee)
SERVER_FILES := $(wildcard src/server/*.coffee) launch-server.js

all: client.js server.js

client.js: $(CLIENT_FILES)
	coffee -cj client.js $(CLIENT_FILES)

server.js: $(SERVER_FILES)
	coffee -cj server.js $(SERVER_FILES)

clean:
	rm -f client.js server.js