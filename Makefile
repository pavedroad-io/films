
#-include .env

VERSION := 1.0.0
BUILD := $(shell git rev-parse --short HEAD)
PROJECTNAME := $(shell basename "$(PWD)")
PROJDIR := $(shell pwd)
TARGET := $(PROJECTNAME)

# Go related variables.
GOBASE := $(shell cd ../../;pwd)
GOPATH := $(GOBASE)
GOBIN := $(GOBASE)/bin
GOFILES := $(wildcard *.go)
GOLINT := $(shell which golint)
ASSETS := "$(PROJDIR)/assets/images"
ARTIFACTS := "$(PROJDIR)/artifacts"
DOCS := "$(PROJDIR)/docs"
LOGS := "$(PROJDIR)/logs"
MANIFEST := "$(PROJDIR)/manifests"
K8S = ~"$(PROJDIR)/manifest/kubernetes"
GOCOVERAGE := "$(ARTIFACTS)/coverage.out"
GOLINTREPORT := "$(ARTIFACTS)/lint.out"
GOTESTREPORT := "https://sonarcloud.io/dashboard?id=acme_films"

SHELL := /bin/bash

# Use linker flags to provide version/build settings to the target
LDFLAGS=-ldflags "-X=main.Version=$(VERSION) -X=main.Build=$(BUILD)"

# Redirect error output to a file, so we can show it in development mode.
STDERR := ./$(PROJECTNAME)-stderr.txt

# PID file will keep the process id of the server
PID := /tmp/.$(PROJECTNAME).pid

# Make is verbose in Linux. Make it silent.
# MAKEFLAGS += --silent

.PHONY: check go-build compile sonar-scanner

all: compile check

#.DEFAULT_GOAL: $(TARGET)

## start: Start in development mode. Auto-starts when code changes.
start:
	@bash -c "trap 'make stop' EXIT; $(MAKE) clean compile start-server watch run='make clean compile start-server'"

## stop: Stop development mode.
stop: stop-server

start-server: stop-server
	@echo "  >  $(PROJECTNAME) is available at $(ADDR)"
	@-$(GOBIN)/$(PROJECTNAME) 2>&1 & echo $$! > $(PID)
	@cat $(PID) | sed "/^/s/^/  \>  PID: /"

stop-server:
	@echo "  >  $(PROJECTNAME) shutting down"
	@-touch $(PID)
	@-kill `cat $(PID)` 2> /dev/null || true
	@-rm $(PID)

## watch: Run given command when code changes. e.g; make watch run="echo 'hey'"
watch:
	@echo "  Watch"
	@GOPATH=$(GOPATH) GOBIN=$(GOBIN) yolo -i . -e vendor -e bin -c "$(run)"

restart-server: stop-server start-server

## compile: Compile the binary.
compile: $(LOGS) $(ARTIFACTS) $(ASSETS) $(DOCS)
	@echo "  Compiling"
	@-$(MAKE) -s go-compile

## exec: Run given command, wrapped with custom GOPATH. e.g; make exec run="go test ./..."
exec:
	@echo "  execute $(GOBIN)"
	@GOPATH=$(GOPATH) GOBIN=$(GOBIN) $(run)

## clean: Clean build files. Runs `go clean` internally.
clean:
	@echo "  execute go-clean"
	@-rm $(GOBIN)/$(PROJECTNAME) 2> /dev/null
	@-$(MAKE) go-clean

go-compile: go-get api-doc $(K8S) go-build

go-build:
	@echo "  >  Building binary..."
	@GOPATH=$(GOPATH) GOBIN=$(GOBIN) go build $(LDFLAGS) -o $(GOBIN)/$(PROJECTNAME) $(GOFILES)
	cp $(GOBIN)/$(PROJECTNAME) .
	skaffold run -f manifests/skaffold.yaml

go-generate:
	@echo "  >  Generating dependency files..."
	@GOPATH=$(GOPATH) GOBIN=$(GOBIN) go generate $(generate)
	dep status -dot | dot -T png
	@echo "  >  Generating dependency files..."

Gopkg.toml:
	@echo "  >  initialize dep support..."
	$(shell (export GOPATH=$(GOPATH);dep init))

go-get: Gopkg.toml get-deps $(ASSETS)
	@echo "  >  Creating dependencies graph png..."
	$(shell (export GOPATH=$(GOPATH);dep status -dot | dot -T png -o $(ASSETS)/$(PROJECTNAME).png))

api-doc: $(DOCS)
	@echo "  >  Generate swagger specification..."
	$(shell (export GOPATH=$(GOPATH);swagger generate spec -m -t $(PROJECTNAME) -o docs/api.json))
	@echo "  >  Generate HTML..."
	pretty-swag -i docs/api.json -o docs/api.html
	@echo "  >  Done"

get-deps:
	@echo "  >  dep ensure..."
	$(shell (GOPATH=$(GOPATH);dep ensure $?))

go-install:
	@GOPATH=$(GOPATH) GOBIN=$(GOBIN) go install $(GOFILES)

go-clean:
	@echo "  >  Cleaning build cache"
	@GOPATH=$(GOPATH) GOBIN=$(GOBIN) go clean

# TODO: enable sonar scanner once we get API key
# check: lint sonar-scanner $(ARTIFACTS) $(LOGS) $(ASSETS) $(DOCS)
check: lint $(ARTIFACTS) $(LOGS) $(ASSETS) $(DOCS)
	@echo "  >  Starting cockroach DB..."
	docker-compose -f manifests/docker-db-only.yaml up -d
	@echo "  >  running to tests..."
	go test -coverprofile=$(GOCOVERAGE) -v ./...
	@echo "  >  Stopping cockroach DB..."
	docker-compose -f manifests/docker-db-only.yaml down

sonar-scanner: $(ARTIFACTS)
	sonarcloud.sh

show-coverage:
	go tool cover -html=$(GOCOVERAGE)

show-test:
	xdg-open $(GOTESTREPORT)

show-devkit:
	xdg-open http://localhost:5000/microk8sDevKit.html


lint: $(GOFILES) $(ARTIFACTS)
	@echo "  >  running lint..."
	@echo $?
	$(GOLINT) $? > $(GOLINTREPORT)

$(K8S):
	$(shell mkdir -p manifests/kubernetes)
	$(shell cd manifests/kubernetes;kompose convert -f ../docker-compose.yaml)

fmt: $(GOFILES)
	@gofmt -l -w $?

simplify: $(GOFILES)
	@gofmt -s -l -w $?

help: Makefile
	@echo
	@echo " Choose a command run in "$(PROJECTNAME)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo

$(ASSETS):
	@echo "  >  Creating assets directory"
	$(shell mkdir -p $(ASSETS))

$(ARTIFACTS):
	@echo "  >  Creating artifacts directory"
	$(shell mkdir -p $(ARTIFACTS))

$(DOCS):
	@echo "  >  Creating docs directory"
	$(shell mkdir -p $(DOCS))

$(LOGS):
	@echo "  >  Creating logs directory"
	$(shell mkdir -p $(LOGS))


