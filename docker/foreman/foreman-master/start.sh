#!/bin/bash

# Configures Foreman the first time using the hostname passed via:
#
#    sudo docker run --hostname="foreman.company.com" --name=formeman foreman
#
# Replace "foreman.company.com" with your forman server's real FQDN
# when running 'docker run.
#
# After this script has been run once it will simply execute a tail -f on
# Foreman's production.log file (mostly so that it doesn't just shut down the
# container right away).
#

if [ -f "/etc/foreman/.first_run_completed" ]; then
    exec /bin/bash -c "tail -50f /var/log/foreman/production.log"
    exit 0
fi
echo "FIRST-RUN: Please wait while Foreman is configured..."

# Copy the SSL key/cert for PostgreSQL so we don't get permissions errors
mkdir -p /etc/ssl/postgresql/{private,certs}
cp /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/postgresql/certs/
cp /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/postgresql/private/
chmod 640 /etc/ssl/postgresql/private/ssl-cert-snakeoil.key
chmod 750 /etc/ssl/postgresql/private
chown -R postgres /etc/ssl/postgresql

# Change PostgreSQL's ssl settings to reflect the new locations:
sed -i -e "/ssl_cert_file/s/certs/postgresql\/certs/g" \
    -e "/ssl_key_file/s/private/postgresql\/private/g" \
    /etc/postgresql/9.3/main/postgresql.conf

/etc/init.d/postgresql restart







/etc/foreman/settings.yaml
/etc/foreman/database.yml
sudo -u foreman /usr/share/foreman/extras/dbmigrate
service foreman start


172.17.0.3

/usr/sbin/foreman-installer --foreman-ipa-authentication=true

docker run --name mariadb \
-e MYSQL_ROOT_PASSWORD=my-secret-pw \
-e MYSQL_USER=foreman \
-e MYSQL_PASSWORD=foreman \
-e MYSQL_DATABASE=foreman \
-d \
mariadb:latest














su -s /bin/sh -c "/usr/share/foreman/extras/dbmigrate" foreman
su -s /bin/sh -c "foreman-rake db:migrate" foreman
su -s /bin/sh -c "foreman-rake db:seed" foreman
su -s /bin/sh -c "foreman-rake permissions:reset" foreman

Login credentials: admin / 87HcmHcSkkDfrNGU









foreman-rake db:seed

172.17.0.2
IF NOT EXISTS
CREATE DATABASE foreman;
GRANT ALL PRIVILEGES ON foreman.* TO 'foreman'@'%' IDENTIFIED BY 'foreman';

MYSQL_DATABASE
This variable is optional and allows you to specify the name of a database to be created on image startup. If a user/password was supplied (see below) then that user will be granted superuser access (corresponding to GRANT ALL) to this database.

MYSQL_USER, MYSQL_PASSWORD




--foreman-email-conf          email configuration file, defaults to /etc/foreman/email.yaml (default: "email.yaml")
--foreman-email-delivery-method  can be sendmail or smtp regarding to foreman documentation (default: nil)
--foreman-email-smtp-address  if delivery_method is smtp, this should contain an valid smtp host (default: nil)
--foreman-email-smtp-authentication  authentication settings, can be none or login, defaults to none (default: "none")
--foreman-email-smtp-domain   email domain (default: nil)
--foreman-email-smtp-password  password for mail server auth, if authentication login (default: nil)
--foreman-email-smtp-port     smtp port, defaults to 25 (default: 25)
--foreman-email-smtp-user-name  user_name for mail server auth, if authentication login (default: nil)
--foreman-email-source


--enable-foreman-plugin-docker \
--enable-foreman-compute-ec2 \
--enable-foreman-compute-gce \
--enable-foreman-compute-openstack \
--enable-foreman-compute-rackspace




/usr/sbin/foreman-installer --reset-foreman-db
foreman-rake db:migrate
foreman-rake db:seed
foreman-rake permissions:reset # This will display the admin password; NOTE IT

# Fix the missing idle_timeout value so we don't get logged out after each page
su - postgres <<'EOF'
psql -d foreman -c "update settings set value = 60 where settings.name = 'idle_timeout';"
EOF

# Configure Foreman to start at boot
sed -i -e "s/START=no/START=yes/g" /etc/default/foreman

touch /etc/foreman/.first_run_completed

echo -e "\033[1mMAKE NOTE OF THAT PASSWORD\033[0m"
echo -e "\033[1mNOTE:\033[0m You may have to set the idle_timeout in Administer->Settings to something > 0 (not sure how to set that in this script)."
echo "Now starting a tail -f of the production.log..."
echo -e "\033[1mNOTE:\033[0m If you just ran 'docker run' you can safely ctrl-c now without killing the container."
exec /bin/bash -c "tail -1f /var/log/foreman/production.log"
exit 0
