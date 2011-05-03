CLIENT_FILES := src/client.coffee src/utils.coffee src/ship.coffee src/planet.coffee src/bullet.coffee
SERVER_FILES := src/server.coffee

all: client.js server.js

client.js: $(CLIENT_FILES)
	coffee -cj client.js $(CLIENT_FILES)

server.js: $(SERVER_FILES)
	coffee -cj server.js $(SERVER_FILES)

clean:
	rm -f client.js server.js