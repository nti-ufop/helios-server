FROM debian:stretch

RUN apt-get update

RUN apt-get install -y apt-utils vim curl apache2 apache2-utils libapache2-mod-wsgi

RUN apt-get install -y python-virtualenv python-pip unzip libpq-dev python-dev rabbitmq-server libsasl2-dev python-dev libldap2-dev libssl-dev python-ldap gettext 

ADD https://github.com/nti-ufop/helios-server/archive/master.zip /helios/

WORKDIR /helios/

RUN adduser --disabled-login --quiet --gecos Helios helios

RUN chown -Rf helios:helios /helios/

USER helios

RUN unzip master.zip

WORKDIR /helios/helios-server-master/

RUN rm ajuda* -Rf

RUN virtualenv venv

RUN bash -c 'source venv/bin/activate; pip install -r requirements.txt; pip install django ptvsd'

COPY ./settings.py .

USER root

RUN echo "*/10 * * * *  /helios/helios-server-master/check-services.sh >/dev/null 2>&1" | crontab -

ADD ./helios_site.conf /etc/apache2/sites-available/000-default.conf

ADD docker-entrypoint-prod.sh /docker-entrypoint.sh

ENTRYPOINT /docker-entrypoint.sh
