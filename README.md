# Sparkets

Sparkets is a multiplayer space rumble game inspired by [Spacewar!](http://en.wikipedia.org/wiki/Spacewar!) and [Slingshot](http://slingshot.wikispot.org/ "Slingshot website").

![Screenshot](https://raw.githubusercontent.com/fmdkdd/sparkets/next/screen.png)

The multiplayer is supported by [ws](http://einaros.github.io/ws/ "ws website") running on a [node.js](http://nodejs.org "node.js website") server.

# Installation

## Prerequisites

You'll need [node.js](http://nodejs.org) and [npm](http://npmjs.org) installed.

## Building the server

Clone this repository, and use `npm` to install the dependencies and `make` to compile.

	git clone git://github.com/fmdkdd/sparkets.git
	cd sparkets
	npm install
	make

You can run the tests with `make test`.  To start the server, use npm: `npm start`.

## Running the client

Use [Firefox](http://www.mozilla.org/firefox) or [Chrome](http://www.google.com/chrome) and browse to `http://SERVER-IP:PORT` where SERVER-IP is the server IP address, and PORT is the HTTP port of the server (default 12345).
