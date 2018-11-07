include .env

all:
	docker-compose -f $(DOCKER_PWD)/service/traefik.yml config

install:
	echo $(APP_ENV)

build-no-cache:
	docker-compose build --no-cache

start:
	docker-compose -f $(DOCKER_PWD)/service/traefik.yml up -d

stop:
	docker-compose -f $(DOCKER_PWD)/service/traefik.yml down

ps:
	docker-compose -f $(DOCKER_PWD)/service/traefik.yml ps

clean:
	rm -rf .env docker-compose.yml