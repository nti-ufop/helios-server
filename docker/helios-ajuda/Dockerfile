FROM nginx:alpine

ADD https://github.com/nti-ufop/helios-server/archive/master.zip /helios/

WORKDIR /helios/

RUN unzip master.zip

WORKDIR /helios/helios-server-master/

RUN mv ajuda-src/site /usr/share/nginx/html/ajuda

RUN mv ajuda-gestor-src/site /usr/share/nginx/html/ajuda-gestor

WORKDIR /

RUN rm /helios/helios-server-master/ -Rf
