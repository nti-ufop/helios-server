#!/bin/bash

trap "echo TRAPed signal" HUP INT QUIT KILL TERM

/etc/init.d/rabbitmq-server start

source venv/bin/activate

python manage.py syncdb

python manage.py migrate

python manage.py compilemessages

python manage.py celeryd &

python manage.py runserver 0.0.0.0:8000

/etc/init.d/rabbitmq-server stop
