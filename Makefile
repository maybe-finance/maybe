.PHONY: .setup

COMPOSE_PROJECT_NAME ?= maybe
LOCAL_DETACHED ?= true

local: .setup
	COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) \
		docker compose -f docker/docker-compose-local.yml up $(if $(filter true,$(LOCAL_DETACHED)),-d)

stop_local:
	COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) \
		docker compose -f docker/docker-compose-local.yml down

.setup:
	mkdir -p docker/tmp/postgres
