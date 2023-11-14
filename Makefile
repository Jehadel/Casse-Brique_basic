play:
	love src/

love:
	mkdir -p dist
	cd src && zip -r ../dist/CasseBrique-basic.love .

js: love
	love.js -c --title="Casse-brique" ./dist/CasseBrique-basic.love ./dist/js