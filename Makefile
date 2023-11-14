play:
	love src/

love:
	mkdir -p dist
	cd src && zip -r ../dist/AsteroidsRace.love .

js: love
	love.js -c --title="Asteroids Race" ./dist/AsteroidsRace.love ./dist/js