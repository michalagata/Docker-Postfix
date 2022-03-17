# POSTFIX

### Environment variables

| Variable | Description | Type | Default value |
| -------- | ----------- | ---- | ------------- |
| **FQDN** | Set Fully Qualified Domain Name | required | mail.domain.eu
| **DOMAIN** | Set primary domain name| required | domain.eu
| **ADD_DOMAINS** | Add additional domains to the mailserver separated by commas | *optional* | null
| **RELAY_NETWORKS** | Additional IPs or networks the mailserver relays without authentication | required | RELAY_NETWORK_IP_SUBNET/8
| **RECIPIENT_DELIMITER** | RFC 5233 subaddress extension separator (single character only) | *optional* | +
| **DESTINATION_SMTP** | Destination SMTP host, to which whole traffic will be forwarded | required | mail.domain.local
| **DESTINATION_SMTP_IP** | Destination SMTP host IP, to be mapped through hosts file | required | SMTP_IP

### Docker run
`build.sh`

### Running interactive
`docker run -it --name mailserver -p 25:25 -p 143:143 -p 465:465 -p 587:587 -p 993:993 -p 4190:4190 -e FQDN="mail.domain.net" -e RELAY_NETWORKS="RELAY_NETWORK_IP_SUBNET/8" -e DOMAIN="domain.eu" -e RECIPIENT_DELIMITER="+" -e DESTINATION_SMTP="mail.domain.local" -e DESTINATION_SMTP_IP="SMTP_IP" -e ADD_DOMAINS="domain.net,domain.pl" -v /opt/nginx/config/etc/letsencrypt/live/domain.eu:/ssl:ro --rm domain-postfix`

### Running as container
`docker run -d --name mailserver -p 25:25 -p 143:143 -p 465:465 -p 587:587 -p 993:993 -p 4190:4190 -e FQDN="mail.domain.net" -e RELAY_NETWORKS="RELAY_NETWORK_IP_SUBNET/8" -e DOMAIN="domain.eu" -e RECIPIENT_DELIMITER="+" -e DESTINATION_SMTP="mail.domain.local" -e DESTINATION_SMTP_IP="SMTP_IP" -e ADD_DOMAINS="domain.net,domain.pl" -v /opt/nginx/config/etc/letsencrypt/live/domain.eu:/ssl:ro --restart unless-stopped domain-postfix`

### Ports
* 25 : SMTP
* 143 : IMAP (STARTTLS)
* 465 : SMTP (SSL/TLS)
* 587 : SMTP (STARTTLS)
* 993 : IMAP (SSL/TLS)
* 4190 : SIEVE (STARTTLS)