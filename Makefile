include .env
export $(shell sed 's/=.*//' .env)

all:
	# Configure SP
	envsubst < sp_conf/config.php.tpl > sp_conf/config.php
	# Configure test IdP
	envsubst < idp_conf/config.yaml.tpl > idp_conf/config.yaml
	openssl req -x509 -nodes -sha256 -days 365 -newkey rsa:2048 -subj "/C=IT/ST=Italy/L=Rome/O=myservice/CN=localhost" -keyout idp_conf/idp.key -out idp_conf/idp.crt

post: complete activate refresh

complete:
	wget --spider --timeout=60 --retry-connrefused "${SP_ENTITYID}"
	docker run -it --rm --volumes-from $(shell docker ps -f "ancestor=wordpress:${WP_VERSION}" --format "{{.ID}}") --network container:$(shell docker ps -f "ancestor=wordpress:${WP_VERSION}" --format "{{.ID}}") wordpress:cli core install  --path="/var/www/html" --url="${SP_ENTITYID}" --title="test1" --admin_user=test2 --admin_password=test3 --admin_email=foo@bar.com

activate:
	docker run -it --rm --volumes-from $(shell docker ps -f "ancestor=wordpress:${WP_VERSION}" --format "{{.ID}}") --network container:$(shell docker ps -f "ancestor=wordpress:${WP_VERSION}" --format "{{.ID}}") wordpress:cli plugin activate spid-wordpress

refresh:
	curl -o idp_conf/sp_metadata.xml "${SP_ENTITYID}/wp-login.php?sso=spid&metadata"
	wget --spider --timeout=60 --retry-connrefused "${IDP_ENTITYID}"
	curl -o sp_conf/idp_metadata/testenv2.xml "${IDP_ENTITYID}/metadata"
	docker restart $(shell docker ps -f "ancestor=italia/spid-testenv2" --format "{{.ID}}")

deactivate:
	docker run -it --rm --volumes-from $(shell docker ps -f "ancestor=wordpress:${WP_VERSION}" --format "{{.ID}}") --network container:$(shell docker ps -f "ancestor=wordpress:${WP_VERSION}" --format "{{.ID}}") wordpress:cli plugin deactivate spid-wordpress

sp_certs:
	openssl req -x509 -nodes -sha256 -days 365 -newkey rsa:2048 -subj "/C=IT/ST=Roma/L=Ostia/O=myservice/OU=My Service/CN=localhost/emailAddress=test@example.com" -keyout sp_conf/wp.key -out sp_conf/wp.crt
	chmod o+r sp_conf/wp.key

download_metadata:
	./spid-wordpress/spid-php-lib/bin/download_idp_metadata.php sp_conf/idp_metadata

test:
	phpunit tests/ConfigurationTest.php 

clean:
	rm -f idp_conf/users.json
	rm -f idp_conf/config.yaml
	rm -f idp_conf/idp.key
	rm -f idp_conf/idp.crt
	rm -f sp_conf/wp.key
	rm -f sp_conf/wp.crt
	rm -f sp_conf/config.php
	rm -f sp_conf/idp_metadata/*.xml
