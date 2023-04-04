
build:
	@chmod u+x database-check.php
	@docker-compose build phpservermonitor


test-log: build
	@docker-compose up -d --force-recreate
	@docker-compose logs -f phpservermonitor
