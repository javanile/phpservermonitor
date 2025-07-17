
stop:
	@docker compose stop

build:
	@chmod u+x database-check.php
	@docker-compose build phpservermonitor

push:
	@git add .
	@git commit -am "Update" || true
	@git push

fix:
	@chmod +x deploy.sh

test:
	@docker-compose up -d --force-recreate
	@echo "Visit: http://localhost:58085"

test-log: build
	@docker-compose up -d --force-recreate
	@docker-compose logs -f phpservermonitor

test-cron:
	@docker-compose exec phpservermonitor php cron/status.cron.php

test-backup: build
	@docker-compose run --rm phpservermonitor php cron/backup.cron.php
