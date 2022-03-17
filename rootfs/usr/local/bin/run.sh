#!/bin/bash

export FQDN
export DOMAIN
export DESTINATION_SMTP
export DESTINATION_SMTP_IP

DESTINATION_SMTP_IP=${DESTINATION_SMTP_IP:-}
DESTINATION_SMTP=${DESTINATION_SMTP:-}
FQDN=${FQDN:-$(hostname --fqdn)}
DOMAIN=${DOMAIN:-$(hostname --domain)}

if [ -z "$FQDN" ]; then
  echo "[ERROR] The fully qualified domain name must be set !"
  exit 1
fi

if [ -z "$DOMAIN" ]; then
  echo "[ERROR] The domain name must be set !"
  exit 1
fi

if [ -z "$DESTINATION_SMTP" ]; then
  echo "[ERROR] The DESTINATION_SMTP must be set !"
  exit 1
fi

if [ -z "$DESTINATION_SMTP_IP" ]; then
  echo "[ERROR] The DESTINATION_SMTP_IP must be set !"
  exit 1
fi

if [ -f "/usr/local/bin/certmaintain.sh" ]; then
certmaintain.sh
fi


# SETUP CONFIG FILES
# ---------------------------------------------------------------------------------------------

# Make sure that configuration is only run once
if [ ! -f "/etc/configuration_built" ]; then
  touch "/etc/configuration_built"
  setup.sh
fi

# Unrecoverable errors detection
if [ -f "/etc/setup-error" ]; then
  echo "[ERROR] One or more unrecoverable errors have occurred during initial setup. See above to find the cause."
  exit 1
fi

# LAUNCH ALL SERVICES
# ---------------------------------------------------------------------------------------------

echo "[INFO] Starting services"
postfix start-fg