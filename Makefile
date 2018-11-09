include .env

all:
	docker-compose $(PROJECT_SERVICES) config

install:
	echo $(APP_ENV)

build-no-cache:
	docker-compose build --no-cache

start:
	docker-compose -f $(SERVISE_PWD)/traefik.yml up -d

stop:
	docker-compose -f $(SERVISE_PWD)/traefik.yml down

ps:
	docker-compose -f $(SERVISE_PWD)/traefik.yml ps

clean:
	rm -rf .env docker-compose.yml