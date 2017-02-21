FROM ubuntu:16.04
MAINTAINER odoohost.cn

# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8

#Install and setup postgresql
RUN set -x; \
        apt-get update \
        && apt-get install -y postgresql
USER postgres
RUN /etc/init.d/postgresql start  && psql --command "CREATE USER root WITH SUPERUSER CREATEDB REPLICATION;"
USER root

# Install some deps, lessc and less-plugin-clean-css
# Cannot install wkhtmltopdf,default in ubuntu without header&footer
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            sudo \
            ca-certificates \
            curl \
            node-less \
            npm \
            python-gevent \
            python-pip \
            python-pyinotify \
            python-renderpm

#Install wkhtmltopdf
RUN set -x; \
        curl -o wkhtmltox.deb -SL http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb \
        && dpkg --force-depends -i wkhtmltox.deb \
        && apt-get update \
        && apt-get -y install -f --no-install-recommends

#Install Odoo
RUN set -x; \
        curl -o odoo.deb -SL http://nightly.odoo.com/10.0/nightly/deb/odoo_10.0.latest_all.deb \
        && dpkg --force-depends -i odoo.deb \
        && apt-get update \
        && apt-get -y install -f --no-install-recommends

# Copy startup script and Odoo configuration file
# odoo.conf will be modified after set DATABASE MANAGE PASSWORD
COPY ./startup.sh /
COPY ./odoo.conf /etc/odoo/
RUN chmod 755 /startup.sh
RUN chmod 777 /etc/odoo/odoo.conf

RUN mkdir -p /mnt/extra-addons \
        && chown -R root /mnt/extra-addons
RUN mkdir -p /mnt/backups \
        && chown -R root /mnt/backups
        
VOLUME ["/mnt/extra-addons","/mnt/backups","/usr/lib/python2.7/dist-packages/odoo/addons","/var/lib/odoo","/etc/odoo","/var/lib/postgresql/data"]

EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

ENTRYPOINT ["/bin/bash","/startup.sh"]
