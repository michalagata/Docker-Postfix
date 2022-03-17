FROM debian:latest

LABEL description "Dockerized Postfix" \
      maintainer="Michael Agata <darkdervish@gmail.com>"

ARG DEBIAN_FRONTEND=noninteractive
ARG GUCCI_VER=1.2.2
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y -q --no-install-recommends \
    postfix postfix-pgsql postfix-mysql postfix-ldap postfix-pcre libsasl2-modules \
    fetchmail libdbi-perl libdbd-pg-perl libdbd-mysql-perl liblockfile-simple-perl \
    clamav clamav-daemon \
    python3-pip python3-setuptools python3-wheel \
    rsyslog dnsutils curl unbound jq rsync \
    inotify-tools wget vim \
 && rm -rf /var/spool/postfix \
 && ln -s /var/mail/postfix/spool /var/spool/postfix \
 && GUCCI_BINARY="gucci-v${GUCCI_VER}-linux-amd64" \
 && wget -q https://github.com/noqcks/gucci/releases/download/${GUCCI_VER}/${GUCCI_BINARY} \
 && chmod +x ${GUCCI_BINARY} \
 && mv ${GUCCI_BINARY} /usr/local/bin/gucci \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/debconf/*-old

EXPOSE 25 143 465 587 993 4190 11334
COPY rootfs /
RUN chmod +x /usr/local/bin/* /services/*/run /services/.s6-svscan/finish
CMD ["run.sh"]
