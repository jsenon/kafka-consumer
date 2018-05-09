#-----------------------------------------------------------------------------
# Global Variables
#-----------------------------------------------------------------------------

DOCKER_USER ?= $(DOCKER_USER)
DOCKER_PASS ?= 

DOCKER_BUILD_ARGS := --build-arg HTTP_PROXY=$(http_proxy) --build-arg HTTPS_PROXY=$(https_proxy)

APP_VERSION := latest

#-----------------------------------------------------------------------------
# PRE REQUISITE
#-----------------------------------------------------------------------------

.PHONY: prerequisite

prerequisite:
	git clone https://github.com/edenhill/librdkafka.git
	cd librdkafka && ./configure --prefix /usr && make && sudo make install


#-----------------------------------------------------------------------------
# BUILD
#-----------------------------------------------------------------------------

.PHONY: default build test publish build_local lint
default: depend test lint build 

depend:
	go get -u github.com/golang/dep
	dep ensure
test:
	go test -v ./...
build_local:
	go build 
build:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build
	docker build $(DOCKER_BUILD_ARGS) -t $(DOCKER_USER)/kafka-consumer:$(APP_VERSION)  .
lint:
	go get -u github.com/alecthomas/gometalinter
	gometalinter --install
	gometalinter ./... --exclude=vendor --deadline=60s

#-----------------------------------------------------------------------------
# PUBLISH
#-----------------------------------------------------------------------------

.PHONY: publish 

publish: 
	docker push $(DOCKER_USER)/kafka-consumer:$(APP_VERSION)

#-----------------------------------------------------------------------------
# CLEAN
#-----------------------------------------------------------------------------

.PHONY: clean 

clean:
	rm -rf kafka-consumer
	cd librdkafka && make clean && make distclean
	rm -rf librdkafka
