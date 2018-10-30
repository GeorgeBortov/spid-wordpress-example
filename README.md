# spid-wordpress-example-form

Esempio di sito wordpress con plugin SPID e form precompilato.

Dimostra come è possibile acquisire gli attributi SPID e usarli per precompilare un form, senza usare codice custom, ma solo plugin di largo utilizzo.

Il plugin spid-wordpress quando un utente fa il login con SPID aggiunge (con https://codex.wordpress.org/Function_Reference/update_user_meta o https://codex.wordpress.org/Class_Reference/WP_User#set.28_.24key.2C_.24value_.29) gli attributi SPID nel database di Wordpress.

Ove possibile nei campi standard:
- User’s first name: name
- User’s last name: familyName
- User’s email address: email

i rimanenti e nella tabella `wp_usermeta`, con i nomi seguenti:
- spid_placeOfBirth
- spid_countyOfBirth
- spid_dateOfBirth
- spid_gender
- spid_fiscalNumber
- spid_idCard
- spid_mobilePhone
- spid_address
. spid_expirationDate
- spid_digitalAddress

I primi tre saranno accessibili in CF con l'[opzione default](https://contactform7.com/setting-default-values-to-the-logged-in-user/) rispettivamente come:
- default:user_first_name
- default:user_last_name
- default:user_email

mentre per gli altri usiamo [dynamictext](https://wordpress.org/plugins/contact-form-7-dynamic-text-extension/).

## Attenzione

I campi di CF7 sono modificabili dal client, quindi un utente malintenzionato potrebbe alterare i valori precompilati, vanificando la garanzia di autenticità fornita da SPID.

La soluzione proposta in questo esempio quindi è adeguata solo per formulari non critici.

Per salvare gli attributi SPID in modo sicuro nel backend è necessario inserirli nel form dopo che l'utente ha inviato i campi insicuri.

Una soluzione potrebbe essere sviluppare un plugin custom che si registri all'hook `wpcf7_posted_data`:
```
add_filter( 'wpcf7_posted_data', 'action_wpcf7_posted_data', 10, 1 );
```
vedi: https://stackoverflow.com/a/40005310, e inserendo i dati aggiuntivi nella funzione `action_wpcf7_posted_data`.

## Come iniziare

Testato su: amd64 Debian 9.5 (stretch, current stable) con PHP 7.0.

### Prerequisiti

- WordPress 4.9.8

- [simevo/spid-wordpress](https://github.com/simevo/spid-wordpress) Versione 0.11.0

- [contact-form-7](https://wordpress.org/plugins/contact-form-7/) Versione 5.0.4

- [contact-form-7-dynamic-text-extension](https://wordpress.org/plugins/contact-form-7-dynamic-text-extension/) Versione 2.0.2.1 per precompilare con gli attributi SPID i campidi CF.

- [contact-form-7-to-database-extension](https://wordpress.org/plugins/contact-form-7-database-extension/) Versione 1.2.4, per salvare i form inviati a DB e mostrarli in una tabella.

## Installazione con docker-compose

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

### Demo

Si crea un modulo CF come:
```
<label>Nome: [text name1 default:user_first_name]</label>

<label>Cognome: [text familyName default:user_last_name]</label>

<label>Codice catastale del Comune o della nazione estera di nascita: [dynamictext placeOfBirth "CF7_get_current_user key='spid_placeOfBirth'"]</label>

<label>Sigla della provincia di nascita: [dynamictext countyOfBirth "CF7_get_current_user key='spid_countyOfBirth'"]</label>

<label>Data di nascita: [dynamictext dateOfBirth "CF7_get_current_user key='spid_dateOfBirth'"]</label>

<label>Sesso: [dynamictext gender "CF7_get_current_user key='spid_gender'"]</label>

<label>Codice fiscale: [dynamictext fiscalNumber "CF7_get_current_user key='spid_fiscalNumber'"]</label>

<label>Documento d'identità: [dynamictext idCard "CF7_get_current_user key='spid_idCard'"]</label>

<label>Numero di telefono mobile: [dynamictext mobilePhone "CF7_get_current_user key='spid_mobilePhone'"]</label>

<label>Indirizzo di posta elettronica: [email email default:default:user_email]</label>

<label>Domicilio fisico: [dynamictext address "CF7_get_current_user key='spid_address'"]</label>

<label>Data di scadenza identità: [dynamictext expirationDate "CF7_get_current_user key='spid_expirationDate'"]</label>

<label>Indirizzo casella PEC (posta certificata): [dynamictext digitalAddress "CF7_get_current_user key='spid_digitalAddress'"]
</label>

[submit "Invia formulario"]
```

Può essere utile saltare l'invio della mail, inserendo l'opzione `skip_mail: on` nella tab "Impostazioni Aggiuntive".

Questo screencast mostra cosa dovrebbe succedere se tutto funziona:

![img](images/screencast.gif)

In attesa che spid-wordpress registri nel DB i campi meta necessari, li abbiamo inseriti a mano:
```
export DOCKER_MYSQL=`docker ps -f "ancestor=mysql:5.7" --format "{{.ID}}"`
docker exec -it $DOCKER_MYSQL mysql -pwordpress wordpress -u wordpress
INSERT INTO wp_usermeta(user_id, meta_key, meta_value) VALUES(1, 'spid_placeOfBirth', 'K888');
INSERT INTO wp_usermeta(user_id, meta_key, meta_value) VALUES(1, 'spid_countyOfBirth', 'AT');
INSERT INTO wp_usermeta(user_id, meta_key, meta_value) VALUES(1, 'spid_dateOfBirth', '1955-01-02');
INSERT INTO wp_usermeta(user_id, meta_key, meta_value) VALUES(1, 'spid_gender', 'M');
INSERT INTO wp_usermeta(user_id, meta_key, meta_value) VALUES(1, 'spid_fiscalNumber', 'XXXYYY66J22K888T');
INSERT INTO wp_usermeta(user_id, meta_key, meta_value) VALUES(1, 'spid_idCard', 'XX545434');
INSERT INTO wp_usermeta(user_id, meta_key, meta_value) VALUES(1, 'spid_mobilePhone', '+39 333 5555555');
INSERT INTO wp_usermeta(user_id, meta_key, meta_value) VALUES(1, 'spid_address', 'Via Battilova 8 Torino');
INSERT INTO wp_usermeta(user_id, meta_key, meta_value) VALUES(1, 'spid_expirationDate', '2020-01-01');
INSERT INTO wp_usermeta(user_id, meta_key, meta_value) VALUES(1, 'spid_digitalAddress', 'test@pec.example.com');
^d
```

## Authors

TODO

## License

Copyright (c) 2018, simevo s.r.l.

License: AGPL 3, see [LICENSE](LICENSE) file.
