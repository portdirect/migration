#!/bin/sh
set -e
if [ "${SECURE_CONFIG}" == "True" ] ; then
  ################################################################################
  echo "${OS_DISTRO}: Sourcing local environment variables"
  ################################################################################
  source /etc/os-container.env
fi


: ${DB_ROOT_PASSWORD:="password"}
: ${DATADIR:=/var/lib/mysql}

MYSQLD_CMD="mysqld_safe"
if [ -z "$(ls /var/lib/mysql)" -a "${MYSQLD_CMD}" = 'mysqld_safe' ]; then
  ################################################################################
  echo "${OS_DISTRO}: Prepping MySQL"
  ################################################################################
  PATH=/usr/libexec:$PATH
  export PATH

  if [ -z "$DB_ROOT_PASSWORD" ]; then
    echo >&2 'error: database is uninitialized and DB_ROOT_PASSWORD not set'
    echo >&2 '  Did you forget to add -e DB_ROOT_PASSWORD=... ?'
    exit 1
  fi

  mysql_install_db --user=mysql --datadir="$DATADIR"

  # These statements _must_ be on individual lines, and _must_ end with
  # semicolons (no line breaks or comments are permitted).
  # TODO proper SQL escaping on ALL the things D:
  TEMP_FILE='/tmp/mysql-first-time.sql'
  cat > "$TEMP_FILE" <<EOSQL
DELETE FROM mysql.user ;
CREATE USER 'root'@'%' IDENTIFIED BY '${DB_ROOT_PASSWORD}' ;
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
DROP DATABASE IF EXISTS test ;
EOSQL

        if [ "$MARIADB_DATABASE" ]; then
                echo "CREATE DATABASE IF NOT EXISTS $MARIADB_DATABASE ;" >> "$TEMP_FILE"
        fi

        if [ "$MARIADB_USER" -a "$MARIADB_PASSWORD" ]; then
                echo "CREATE USER '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PASSWORD' ;" >> "$TEMP_FILE"

                if [ "$MARIADB_DATABASE" ]; then
                        echo "GRANT ALL ON $MARIADB_DATABASE.* TO '$MARIADB_USER'@'%' ;" >> "$TEMP_FILE"
                fi
        fi

        echo 'FLUSH PRIVILEGES ;' >> "$TEMP_FILE"

        MYSQLD_CMD="${MYSQLD_CMD} --init-file="$TEMP_FILE""
fi

chown -R mysql:mysql "$DATADIR"

################################################################################
echo "${OS_DISTRO}: MariaDB: Running Launch Command"
################################################################################
exec ${MYSQLD_CMD}
