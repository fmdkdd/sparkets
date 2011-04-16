SRC_FILES := $(wildcard src/*.coffee)

client.js: $(SRC_FILES)
	coffee -jc $(SRC_FILES)
	mv concatenation.js client.js

server.js: src/server.coffee
	coffee -o ./ -c src/server.coffee

clean:
	rm -f client.js server.js