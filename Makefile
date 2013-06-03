build:
	mkdir -p lib
	rm -rf lib/*
	node_modules/.bin/coffee --compile -m --output lib/ src/

watch:
	node_modules/.bin/coffee --watch --compile --output lib/ src/
	
test:
	node_modules/.bin/mocha
	node_modules/.bin/promises-aplus-tests lib/adapter.js

jumpstart:
	curl -u 'meryn' https://api.github.com/user/repos -d '{"name":"swift-promise", "description":"Fast, Promises/A+ compliant promises.","private":false}'
	mkdir -p src
	touch src/swift-promise.coffee
	mkdir -p test
	touch test/swift-promise.coffee
	npm install
	git init
	git remote add origin git@github.com:meryn/swift-promise
	git add .
	git commit -m "jumpstart commit."
	git push -u origin master

.PHONY: test