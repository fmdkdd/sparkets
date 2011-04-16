CLIENT_FILES := src/client.coffee src/utils.coffee src/ship.coffee src/planet.coffee src/bullet.coffee
SERVER_FILES := src/server.coffee

client.js: $(CLIENT_FILES)
	coffee -jc $(CLIENT_FILES)
	mv concatenation.js client.js

server.js: $(SERVER_FILES)
	coffee -jc $(SERVER_FILES)
	mv concatenation.js server.js

clean:
	rm -f client.js server.js