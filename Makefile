include .env

all:
	# Configure SP
	openssl req -x509 -nodes -sha256 -days 365 -newkey rsa:2048 -subj "/C=IT/ST=Italy/L=Rome/O=myservice/CN=localhost" -keyout sp_conf/wp.key -out sp_conf/wp.crt
	chmod o+r sp_conf/wp.key
	envsubst < sp_conf/config.php.tpl > sp_conf/config.php
	# Configure test IdP
	envsubst < idp_conf/config.yaml.tpl > idp_conf/config.yaml
	openssl req -x509 -nodes -sha256 -days 365 -newkey rsa:2048 -subj "/C=IT/ST=Italy/L=Rome/O=myservice/CN=localhost" -keyout idp_conf/idp.key -out idp_conf/idp.crt
	# Needed only to interact with the production IdPs:
	# ../vendor/italia/spid-php-lib/bin/download_idp_metadata.php sp_conf/idp_metadata

post: complete activate refresh

complete:
	wget --spider --timeout=15 --retry-connrefused "${SP_ENTITYID}"
	docker run -it --rm --volumes-from $(shell docker ps -f "ancestor=wordpress" --format "{{.ID}}") --network container:$(shell docker ps -f "ancestor=wordpress" --format "{{.ID}}") wordpress:cli core install  --path="/var/www/html" --url="${SP_ENTITYID}" --title="test1" --admin_user=test2 --admin_password=test3 --admin_email=foo@bar.com

activate:
	docker run -it --rm --volumes-from $(shell docker ps -f "ancestor=wordpress" --format "{{.ID}}") --network container:$(shell docker ps -f "ancestor=wordpress" --format "{{.ID}}") wordpress:cli plugin activate spid-wordpress

refresh:
	curl -o idp_conf/sp_metadata.xml "${SP_ENTITYID}/wp-login.php?sso=spid&metadata"
	wget --spider --timeout=15 --retry-connrefused "${IDP_ENTITYID}"
	curl -o sp_conf/idp_metadata/testenv2.xml "${IDP_ENTITYID}/metadata"
	docker restart $(shell docker ps -f "ancestor=italia/idp_conf" --format "{{.ID}}")

deactivate:
	docker run -it --rm --volumes-from $(shell docker ps -f "ancestor=wordpress" --format "{{.ID}}") --network container:$(shell docker ps -f "ancestor=wordpress" --format "{{.ID}}") wordpress:cli plugin deactivate spid-wordpress

clean:
	rm -f idp_conf/users.json
	rm -f idp_conf/config.yaml
	rm -f idp_conf/idp.key
	rm -f idp_conf/idp.crt
	rm -f .env
	rm -f sp_conf/wp.key
	rm -f sp_conf/wp.crt
	rm -f sp_conf/config.php
	rm -f sp_conf/idp_metadata/*.xml
