#!/bin/bash

trap "echo TRAPed signal" HUP INT QUIT KILL TERM

rm -Rf /var/run/rabbitmq

/etc/init.d/rabbitmq-server start

#source venv/bin/activate

su -c "source venv/bin/activate; python manage.py syncdb" helios

su -c "source venv/bin/activate; python manage.py migrate" helios

su -c "source venv/bin/activate; python manage.py compilemessages" helios

su -c "source venv/bin/activate; python manage.py celeryd &" helios

apachectl -DFOREGROUND

/etc/init.d/rabbitmq-server stop
