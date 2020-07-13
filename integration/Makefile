all: lint tests

.PHONY: build build-tests tests flake8 pylint

build:
	./docker-compose build > /dev/null

build-tests:
	./docker-compose build tests-base > /dev/null

clean:
	find -name "*.py[oc]" -delete

tests: build
	./all.sh

lint: build-tests
	./run lint
