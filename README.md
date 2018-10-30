# spid-wordpress-example

Demo WordPress site with SPID plugin

## Installation with con docker-compose

The quickest way to start an instance of the WordPress with the **SPID WordPress** plugin and the [SPID test Identity Provider spid-testenv2](https://github.com/italia/spid-testenv2) all configured and set up is using Docker Compose.

You will need:
- Docker CE
- Docker Compose
- git, wget, curl, make and openssl
- on macOS to make sure the `envsubst` command [is available](https://stackoverflow.com/questions/23620827/envsubst-command-not-found-on-mac-os-x-10-8):
    ```sh
    brew install gettext
    brew link --force gettext
    ```

To make the image building process faster, pull in advance the required docker images (this may take some time):
```sh
docker-compose pull
docker pull wordpress:cli
```

Before starting up, edit the `.env` file if you wish to change the host names.

To start up clone the 2 repos one inside the other:
```sh
git clone https://github.com/simevo/spid-wordpress-example-form
cd spid-wordpress-example-form
git clone https://github.com/simevo/spid-wordpress.git spid-wordpress
make
docker-compose up --build
```

Wait until messages stop, then in a separate shell issue the command:
```sh
make post
```

Your brand new wordpress site will be at: http://localhost:8099; log in as admin with user = `test2` and password = `test3`.

Your SPID test IdP will be at: http://localhost:8088

To deactivate / reactivate the plugin use:
```sh
make activate
make deactivate
```

To refresh the SP metadata to the IdP and vice versa use:
```sh
make refresh
```

To remove the containers and default network, but preserve the database: `docker-compose down`

To remove all: `docker-compose down --volumes`

## Authors

TODO

## License

Copyright (c) 2018, simevo s.r.l.

License: AGPL 3, see [LICENSE](LICENSE) file.
