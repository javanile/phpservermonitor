
start:
	@docker compose up -d --build --remove-orphans --force-recreate
	@echo "Visit: http://localhost:58085"

stop:
	@docker compose stop

build:
	@chmod u+x database-check.php
	@docker-compose build app

shell:
	@docker compose exec app bash

push:
	@git add .
	@git commit -am "Update" || true
	@git push

fix:
	@chmod +x deploy.sh

test:
	@docker-compose up -d --force-recreate --build
	@echo "Visit: http://localhost:58085"

test-log: build
	@docker-compose up -d --force-recreate
	@docker-compose logs -f phpservermonitor

test-cron:
	@docker-compose exec phpservermonitor php cron/status.cron.php

test-backup:
	@docker compose up -d --build --force-recreate app
	@docker-compose exec app php cron/backup.cron.php

test-install:
	@docker compose down -v
	@docker compose up -d --build --remove-orphans --force-recreate
	@echo "Visit: http://localhost:58085"
