#!/bin/sh
# Wire TCAMT to its databases and its mail relay, then start Tomcat.
#
# Everything a deployment differs in comes from the environment here: the
# JNDI datasource the login path authenticates against, the Mongo settings,
# the mail relay and credentials, the Froala key, the version label and the
# connect rewrite. The image itself carries neutral defaults, so a container
# started without these variables serves the application but talks to no
# real database and no real mail relay.
#
# The datasource is the one that cannot be left out: without jdbc/igl_jndi
# every login fails with "Cannot create JDBC driver of class '' for connect
# URL 'null'" while the landing page, the app-info endpoint and every static
# asset still answer 200. So the placeholders are checked after substitution
# and the container refuses to start rather than boot a tool nobody can sign
# into.
set -e

CTX=/usr/local/tomcat/conf/context.xml

if [ -n "${DB_HOST:-}" ]; then
  sed -i "s#container-mysql:3306#${DB_HOST}:${DB_PORT:-3306}#g" "$CTX"
fi
if [ -n "${DB_NAME:-}" ]; then
  sed -i "s#/tcamt_db?#/${DB_NAME}?#g" "$CTX"
fi
if [ -n "${DB_USER:-}" ]; then
  sed -i "s#username=\"tcamt\"#username=\"${DB_USER}\"#g" "$CTX"
fi
if [ -n "${DB_PASSWORD:-}" ]; then
  sed -i "s#password=\"db_password\"#password=\"${DB_PASSWORD}\"#g" "$CTX"
fi

if grep -q 'container-mysql:3306\|password="db_password"' "$CTX"; then
  echo "FATAL: the JNDI datasource still holds build-time placeholders." >&2
  echo "       DB_HOST/DB_NAME/DB_USER/DB_PASSWORD must all be set." >&2
  exit 1
fi

# System properties override app-web-config.properties (the web app
# initializer reads them through the Spring environment), so each runtime
# setting is passed as -D. Values are quoted for the shell only; none of them
# may contain a double quote.
opts="${JAVA_OPTS:-}"
add() { # add <property> <value>: append -Dproperty=value when value is set
  if [ -n "$2" ]; then opts="$opts -D$1=$2"; fi
}

add mongo.host   "${MONGO_HOST:-127.0.0.1}"
add mongo.port   "${MONGO_PORT:-27017}"
add mongo.dbname "${MONGO_DBNAME:-tcamt_mongo}"
if [ -n "${MONGO_USER:-}" ]; then
  add mongo.user       "$MONGO_USER"
  add mongo.password   "${MONGO_PASSWORD:-}"
  add mongo.authsource "${MONGO_AUTHSOURCE:-admin}"
fi

add mail.host            "${MAIL_HOST:-}"
add mail.port            "${MAIL_PORT:-}"
add mail.protocol        "${MAIL_PROTOCOL:-}"
add mail.auth            "${MAIL_AUTH:-}"
add mail.starttls.enable "${MAIL_STARTTLS_ENABLE:-}"
add mail.debug           "${MAIL_DEBUG:-}"
add mail.username        "${MAIL_USERNAME:-}"
add mail.password        "${MAIL_PASSWORD:-}"
add mail.from            "${MAIL_FROM:-}"
add server.email         "${MAIL_FROM:-}"
add admin.email          "${ADMIN_EMAIL:-}"

add froala.key  "${FROALA_KEY:-}"
add app.version "${APP_VERSION:-}"

add connect.serverUrlFrom "${CONNECT_SERVER_URL_FROM:-}"
add connect.serverUrlTo   "${CONNECT_SERVER_URL_TO:-}"

# hbm2ddl defaults to update so a fresh database gets its schema on first
# boot; the bundled default is validate, which dies against an empty database.
add hibernate.hbm2ddl.auto "${HBM2DDL_AUTO:-update}"
add hibernate.dialect      "${HIBERNATE_DIALECT:-org.hibernate.dialect.MySQL5InnoDBDialect}"

JAVA_OPTS="$opts"
export JAVA_OPTS

exec catalina.sh run
