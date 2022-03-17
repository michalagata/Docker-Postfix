#!/bin/bash

echo "[INFO] Setting up container"

export RECIPIENT_DELIMITER
export RELAY_NETWORKS

DEBUG_MODE=${DEBUG_MODE:-false}
ADD_DOMAINS=${ADD_DOMAINS:-}
RECIPIENT_DELIMITER=${RECIPIENT_DELIMITER:-"+"}
RELAY_NETWORKS=${RELAY_NETWORKS:-}

# SSL CERTIFICATES
# ---------------------------------------------------------------------------------------------

export FULLCHAIN="/certs/fullchain1.pem"
export CAFILE="/certs/chain1.pem"
export CERTFILE="/certs/cert1.pem"
export KEYFILE="/certs/privkey1.pem"

# Hosts
destinationsmtp=(${DESTINATION_SMTP})
destinationsmtpip=(${DESTINATION_SMTP_IP})

grep -q "$destinationsmtp" /etc/hosts
if [ $? -ne 0 ]; then
  echo "[INFO] $destinationsmtp entry not found in /etc/hosts, adding..."
  echo "$destinationsmtpip $destinationsmtp" >> /etc/hosts
else
  echo "[INFO] $destinationsmtp entry already present in /etc/hosts, skipping..."
fi


# Add domains from ENV DOMAIN and ADD_DOMAINS
domains=(${DOMAIN})
domains+=(${ADD_DOMAINS//,/ })
destinationsmtp=(${DESTINATION_SMTP})

for domain in "${domains[@]}"; do

grep -q "$domain" /etc/postfix/relay_domains
if [ $? -ne 0 ]; then
  echo "[INFO] $domain entry not found in /etc/postfix/relay_domains, adding..."
  echo "$domain OK" >> /etc/postfix/relay_domains
else
  echo "[INFO] $domain entry already present in /etc/postfix/relay_domains, skipping..."
fi

grep -q "$domain" /etc/postfix/transport
if [ $? -ne 0 ]; then
  echo "[INFO] $domain entry not found in /etc/postfix/transport, adding..."
  echo "$domain smtp:$destinationsmtp" >> /etc/postfix/transport
else
  echo "[INFO] $domain entry already present in /etc/postfix/transport, skipping..."
fi

grep -q "$domain" /etc/postfix/sender_access
if [ $? -ne 0 ]; then
  echo "[INFO] $domain entry not found in /etc/postfix/sender_access, adding..."
  echo "$domain OK" >> /etc/postfix/sender_access
else
  echo "[INFO] $domain entry already present in /etc/postfix/sender_access, skipping..."
fi

grep -q "$domain" /etc/postfix/relay_recipients
if [ $? -ne 0 ]; then
  echo "[INFO] $domain entry not found in /etc/postfix/relay_recipients, adding..."
  echo "@$domain x" >> /etc/postfix/relay_recipients
else
  echo "[INFO] $domain entry already present in /etc/postfix/relay_recipients, skipping..."
fi

done

# REPLACE MAGIC

# Gucci requires files to have .tpl extension
_envtpl() {
  mv "$1" "$1.tpl" && gucci "$1.tpl" > "$1" && rm -f "$1.tpl"
}

_envtpl /etc/postfix/main.cf
_envtpl /etc/postfix/virtual
_envtpl /etc/postfix/header_checks


#sed 's/{{ .DOMAIN }}/'"$DOMAIN"'/' /etc/postfix/main.cf > /tmp/main.cf; cat /tmp/main.cf > /etc/postfix/main.cf
#sed 's/{{ .FQDN }}/'"$FQDN"'/' /etc/postfix/main.cf > /tmp/main.cf; cat /tmp/main.cf > /etc/postfix/main.cf
#sed 's/{{ .FULLCHAIN }}/'"$FULLCHAIN"'/' /etc/postfix/main.cf > /tmp/main.cf; cat /tmp/main.cf > /etc/postfix/main.cf
#sed 's/{{ .KEYFILE }}/'"$KEYFILE"'/' /etc/postfix/main.cf > /tmp/main.cf; cat /tmp/main.cf > /etc/postfix/main.cf
#sed 's/{{ .RECIPIENT_DELIMITER }}/'"$RECIPIENT_DELIMITER"'/' /etc/postfix/main.cf > /tmp/main.cf; cat /tmp/main.cf > /etc/postfix/main.cf
#sed 's/{{ .RELAY_NETWORKS }}/'"$RELAY_NETWORKS"'/' /etc/postfix/main.cf > /tmp/main.cf; cat /tmp/main.cf > /etc/postfix/main.cf

# POSTFIX CUSTOM CONFIG
# ---------------------------------------------------------------------------------------------

# Override Postfix configuration
if [ -f /var/mail/postfix/custom.conf ]; then
  # Ignore blank lines and comments
  sed -e '/^\s*$/d' -e '/^#/d' /var/mail/postfix/custom.conf | \
  while read line; do
    type=${line:0:2}
    value=${line:2}
    if [[ "$type" == 'S|' ]]; then
      postconf -M "$value"
      echo "[INFO] Override service entry in master.cf : ${value}"
    elif [[ "$type" == 'F|' ]]; then
      postconf -F "$value"
      echo "[INFO] Override service field in master.cf : ${value}"
    elif [[ "$type" == 'P|' ]]; then
      postconf -P "$value"
      echo "[INFO] Override service parameter in master.cf : ${value}"
    else
      echo "[INFO] Override parameter in main.cf : ${line}"
      postconf -e "$line"
    fi
  done
  echo "[INFO] Custom Postfix configuration file loaded"
fi

# ENABLE Console Logging
grep -q "postlogd" /etc/postfix/master.cf
if [ $? -ne 0 ]; then
  echo "[INFO] postlogd entry not found in /etc/postfix/master.cf, adding..."
  echo "postlog   unix-dgram n  -       n       -       1       postlogd" >> /etc/postfix/master.cf
else
  echo "[INFO] postlogd entry already present in /etc/postfix/master.cf, skipping..."
fi

# ENABLE / DISABLE MAIL SERVER FEATURES
# ---------------------------------------------------------------------------------------------

# Enable Postfix, Dovecot and Rspamd verbose logging
if [ "$DEBUG_MODE" != false ]; then
  if [[ "$DEBUG_MODE" = *"postfix"* || "$DEBUG_MODE" = true ]]; then
    echo "[INFO] Postfix debug mode is enabled"
    sed -i '/^s.*inet/ s/$/ -v/' /etc/postfix/master.cf
  fi
else
  echo "[INFO] Debug mode is disabled"
fi


# /var/log/mail.log is not needed in production
sed -i '/mail.log/d' /etc/rsyslog/rsyslog.conf

# POSTFIX
# ---------------------------------------------------------------------------------------------

# Create all needed folders in queue directory
for subdir in "" etc dev usr usr/lib usr/lib/sasl2 usr/lib/zoneinfo public maildrop; do
  mkdir -p  /var/mail/postfix/spool/$subdir
  chmod 755 /var/mail/postfix/spool/$subdir
done

# Add etc files to Postfix chroot jail
cp -f /etc/services /var/mail/postfix/spool/etc/services
cp -f /etc/hosts /var/mail/postfix/spool/etc/hosts
cp -f /etc/localtime /var/mail/postfix/spool/etc/localtime

# Build header_checks and virtual index files
postmap hash:/etc/postfix/transport
postmap hash:/etc/postfix/relay_domains
postmap hash:/etc/postfix/sender_access
postmap hash:/etc/postfix/relay_recipients
postmap hash:/etc/postfix/header_checks

# Set permissions
postfix set-permissions &>/dev/null

# MISCELLANEOUS
# ---------------------------------------------------------------------------------------------

# Remove invoke-rc.d warning
sed -i 's|rsyslog-rotate|rsyslog-rotate \&>/dev/null|g' /etc/logrotate.d/rsyslog

# Folders and permissions
chmod +x /usr/local/bin/*

# Ensure that hashes are calculated because Postfix require directory
# to be set up like this in order to find CA certificates.
c_rehash /etc/ssl/certs &>/dev/null

echo "[INFO] Finished container setup"
