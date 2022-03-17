#!/bin/bash

mkdir -p /certs
cp -u /ssl/*.pem /certs/
chown -R postfix:postfix /certs/
chmod 0660 /certs/*.pem
echo "[INFO] Certificates maintained"