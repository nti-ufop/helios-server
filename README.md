O objetivo deste projeto era inicialmente atender a [necessidade N.47 do PDTI 2013 do IFSC](http://dtic.ifsc.edu.br/files/pdti2013-revisao02.pdf).

No entanto, logo percebeu-se que outras instituições, especialmente as de ensino, poderiam se beneficiar das melhorias realizadas no projeto original, a fim de atender ao público brasileiro.

Neste repositório encontra-se o código personalizado a partir do original disponível em [https://github.com/benadida/helios-server](https://github.com/benadida/helios-server), assim como um tutorial detalhado de instalação e configuração.

Para saber um pouco mais, acesse:

Tutoriais: 

http://dtic.ifsc.edu.br/sistemas/sistema-de-votacao-on-line-helios/

Publicações:

1) [O uso de um sistema de votação on-line para escolha do conselho universitário](http://dtic.ifsc.edu.br/files/chaves-sbseg14.pdf)

2) [Adoção de modelo controle acesso baseado em atributos em sistema de votação online para ofertá-lo como um serviço de TIC federado](http://sbseg2015.univali.br/anais/WGID/artigoWGID06.pdf)




# Guia de instalação e configuração do Helios

*This README is intended for Portuguese audience.*

Neste tutorial são descritos os principais passos para instalação de um servidor para disponibilização do Helios.
Todo o tutorial considera o sistema operacional Ubuntu (testados em 14.04 e 16.10), embora já tenham sido feitos testes com CentOS.
A execução desse tutorial supõe alguma experiência com administração de sistemas em geral (instalação de pacotes, configuração de serviços, etc).

Pacotes necessários instalar e configurar:

	apache2 e libapache2-mod-wsgi
	postgresql e postgresql-server-dev (testado já em versão 9.3 e 9.6)
	libsasl2-dev
	python-ldap e libldap2-dev (pra utilizar o módulo de autenticação LDAP)
	gettext (para uso das funcionalidade de compilação de mensagens traduzidas)


Para utilizar o login via shibboleth (federação), instalar também o módulo shib para o apache:

	sudo apt-get install libapache2-mod-shib2


Se for baixar e/ou atualizar o código via github:

    sudo apt-get install git 



##Configurações
### Banco

Criar um usuário com senha que possa fazer login no Posgtres, que possa criar a base de dados do helios. 
Esse usuário e senha serão configurados posteriormente no helios, em settings.py.
Normalmente, usando a linha de comando, no cliente psql. Por exemplo, executar os seguintes comandos para essa finalidade:


    create role helios with createdb createrole login;
    
    alter user helios with password 'sua senha';
    

Editar o arquiv **pg_hba.conf** e inserir a linha:

`local   all              helios                         md5` 

logo acima da linha

`local   all             all         peer`

A configuração acima corrige o seguinte erro:

> 
Exception Type: 	OperationalError
Exception Value: 	
FATAL:  Peer authentication failed for user "helios"

Se você quiser gerenciar a base a partir de um cliente como o pgAdmin, pode utilizar um túnel ssh. 
Editar ~/.ssh/config e inserir:


	Host NOMEDOHOST
	User NOMEDOUSER
	Hostname ENDERECODOHOST
	Port PORTASSH
	LocalForward PORTALOCAL 127.0.0.1:PORTAREMOTA


Na configuração do pgAdmin, usar como endereço do host o seu endereço e não esquecer que precisa haver uma conexão ssh aberta com o servidor do banco!

### Obtenção do código-fonte e preparação da aplicação

Você pode baixar um zip com o fonte ou clonar o repositório. Supondo que o código vai ser baixado via git:

*git clone https://github.com/ifsc/helios-server.git*


Não é obrigatório, mas é uma boa prática, criar um ambiente virtual para a disponibilização do Helios, tanto para desenvolvimento quanto para implantação, pois isso permite separar as dependências do projeto e não interferir em outros sistemas na mesma máquina. 

Primeiramente, instale o pip, seguindo as orientações do desenvolvedor:
http://pip.readthedocs.org/en/stable/

Depois, instale o virtualenv, seguindo também as orientações disponíveis em:
http://virtualenv.readthedocs.org/en/latest/

Terminada a instalação do virtualenv,  dentro do diretório onde o helios foi baixado, basta dar o comando 
*virtualenv venv*

(venv é um exemplo, pode ser dado outro nome se necessário).

Para ativar o ambiente virtual, execute
*source venv/bin/activate*

Com o ambiente virtual ativado, instale os requisitos para a execução do helios:

`pip install -r requirements.txt`  

*ATENÇÃO: Utilize o requirements.txt deste repositório, para instalar o pacote django-auth-ldap e outros necessários às customizações realizadas. Lembrando também que apesar de se pretender manter este repositório atualizado com o do Ben Adida, não necessariamente vai ser simultâneo, então se você utilizar o dele, pode haver versões diferentes de pacotes.*

Edite o arquivo settings.py, localize a seção databases e adicione as informações do banco de dados, conforme o exemplo:


	DATABASES = {
	'default': {
	'ENGINE': 'django.db.backends.postgresql_psycopg2',
	'NAME': 'helios',
	'USER': 'helios',
	'HOST': 'localhost',
	'PASSWORD': 'SENHADOHELIOS'
	}}


Agora é possível realizar as devidas execuções de banco de dados (criação de banco, tabelas, etc) executando o script reset.sh:

`$./reset.sh`

Se tiver algum problema rodando o script acima, provavelmente vai ser relacionado à configuração do PostgreSQL e, nesse caso, o *google é seu amigo.*

Para disponibilizar o helios em português, é preciso compilar os arquivos de tradução. Execute o seguinte comando a partir do diretório do Helios:

`python manage.py compilemessages`

Após a compilação, arquivos .mo devem ter sido gerados em locale/pt_BR/LC_MESSAGES

Maiores informações em https://docs.djangoproject.com/en/1.6/ref/django-admin/

Se tudo estiver correto até aqui, agora você pode rodar o servidor de desenvolvimento, distribuído com o django, e testar a instalação básica:

`$python manage.py runserver 0.0.0.0:8000` *# 0.0.0.0 para que fique acessível da rede. Pode executar até runserver, se preferir. Também pode trocar a porta!*

Em outro terminal, coloque o celery para rodar. Essa parte é importante, pois é ele quem vai gravar os votos, enviar emails, processar o arquivo de eleitores, etc!

`python manage.py celeryd`


## Servidor de Produção

O servidor descrito no tópico anterior é apenas para desenvolvimento, não deve ser usado em um ambiente de produção! 

É possível trabalhar com diversos servidores web, porém no caso em questão optou-se pelo [Apache](https://docs.djangoproject.com/en/1.8/topics/install/#install-apache-and-mod-wsgi).

### Configuração apache

Módulos a serem habilitados, para a configuração exemplo:

    sudo a2enmod rewrite

    sudo a2enmod ssl

Para configurar o httpd.conf ou equivalente, siga as instruções em [How to use Django with Apache and mod_wsgi](https://docs.djangoproject.com/en/1.8/howto/deployment/wsgi/modwsgi/).


A parte de servir os arquivos estáticos é a mais trabalhosa. Essa configuração é necessária porque no servidor de desenvolvimento o django serve esses arquivos, porém, na produção, eles precisam ser configurados para serem servidos pelo servidor web.

Os arquivos estáticos não servidos pelo django são os "tradicionais":  css, javascript e imagens, por exemplo. Para coletar esses arquivos, é preciso executar o comando collectstatic, conforme descrito em [Collect static app](https://docs.djangoproject.com/en/1.8/ref/contrib/staticfiles//).

No caso do Helios em particular, há módulos sendo servidos estaticamente (total ou parcial): o heliosbooth e o heliosverifier, os quais também precisam ser configurados.

No estágio atual, com enfoque em desenvolvimento de novas funcionalidades, optou-se por uma solução "feia", mas que simplifica muito: fazer um link simbólico dos arquivos desses módulos para e os demais arquivos que precisam ser servidos estaticamente. E então configurar um *alias* para eles na configuração do apache:

Alias /booth /`<path_to_site>`/sitestatic/booth

Alias /verifier /`<path_to_site>`/sitestatic/verifier

Além desses, todos os demais arquivos a serem servidos diretamente pelo apache, como os do módulo admin do django, apresentado mais adiante, estão com links simbólicos no diretório sitestatic, que está sob controle do git.

Conforme citado anteriormente, o celery (http://www.celeryproject.org/)  precisa estar rodando, pois ele é o enfileirador de tarefas como a de envio de e-mails e registro de votos.

O script check-services.sh foi criado para checar se o serviço está rodando. Ele pode ser adicionado à crontab, como no exemplo abaixo, no qual ele executa de 10 em 10 minutos.

	*/10 * * * *  /var/www/helios-server/check-services.sh >/dev/null 2>&1

Nesse mesmo script, também é verificado o celery beat (http://docs.celeryproject.org/en/latest/userguide/periodic-tasks.html), agendador de tarefas periódicas, como limpar a tabela celery_taskmeta, que guarda log das tarefas e pode crescer bastante.

No settings.py disponível no corrente repositório, colocou-se 60 dias como o prazo para apagar essas tarefas:

CELERYBEAT_SCHEDULER = 'djcelery.schedulers.DatabaseScheduler'
 
CELERY_TASK_RESULT_EXPIRES = 5184000 # 60 days

Após iniciar o celery beat, é possível ver uma tarefa periódica criada através da interface administrativa do django, sob Djecelery, periodic tasks.

Se não for desejado fazer a limpeza da tabela dessa forma, basta não iniciar o celery beat.

#### Configuração módulo apache shibboleth2

Além do módulo de autenticação LDAP, também foi desenvolvido um módulo de autenticação considerando o módulo shibboleth2 para o Apache.
Nesse caso, o helios funciona como um Service Provider - SP, que deve ser liberado no IdP shibboleth de acordo com as configurações necessárias
para que um SP possa se conectar usando o IdP Shibboleth.

Para utilizar essa funcionalidade, deve-se instalar o módulo apache shib (funcionalidade testada com libapache2-mod-shib2) do servidor que vai servir o SP Helios e efetuar
as configurações necessárias do shibboleth. Essas configurações incluem por exemplo o estabelecimento de confiança com o IdP, obtenção de metadados do IdP, envio de metadados do SP para o Idp, etc. Um bom ponto de partida, caso a instituição não costume configurar SPs shibboleth, é pesquisar por tutoriais que auxiliem na configuração de um SP.



#### Administração pelo site de administração do django

Ao rodar o reset.sh, você deve ter sido solicitado a criar um usuário de administração do django. Isso se deve ao fato de aplicação admin estar habilitada no settings.py (django.contrib.admin), pois iremos utilizá-la em algumas customizações feitas para este *fork* do helios.

As configurações descritas nessa seção são para o administrador do serviço Helios.

##### Para autenticação via ldap

Após finalizar a instalação, você deve entrar em http(s)://endereco-do-seu-servidor-helios/admin e se conectar com o usuário e senha de administração, cadastrados no passo descrito anteriormente. Após logar, será disponibilizada uma tela de administração, mostrando diversas apps habilitadas para essa tarefa. Localize a opção `Helios_Auth` e clique em *Users*. Na tela seguinte, escolha o usuário que quer editar, clicando no mesmo. Na tela de edição, marque a opção *Admin_p* e salve, caso você queira que o usuário em questão possa criar eleições ao se conectar no Helios. 

**Atenção**: *o usuário a ser configurado já deve ter se conectado ao menos uma vez  no Helios (na página da aplicação).*

Outra customização disponível, acessível por essa administração, é a opção de listar ou não uma eleição na página pública inicial do sistema. Se você quiser que uma eleição seja listada, na página de administração do Django, localize a opção `Helios` e clique em *Elections*. Na tela seguinte, clique no nome da eleição que você gostaria que fosse listada na página pública e na tela de edição, marque a opção *Featured p* e salve.

##### Para autenticação federada via shibboleth

Para a utilização federada do Helios, diversas personalizações foram efetuadas tanto na página pública, quando na parte de gerenciamento de eleições.

Toda instituição a utilizar o Helios deve ser previamente cadastrada. Esse cadastro é feito na parte administrativa do Django. Acesse http(s)://endereco-do-seu-servidor-helios/admin, procure por *HeliosInstitution* e clique em *Institutions* e então em *Adicionar Institution*. Forneça os dados necessários e clique em salvar.

Para que a instituição possa ser administrada, é necessário fornecer via interface admin do Django ao menos um usuário administrador. Para tal, em *HeliosInstitution*, clique em *Institution user profiles", depois em *Adicionar institution user profiles* . Se o usuário a ser cadastrado já se conectou alguma vez via federação, deve aparecer no campo Helios user. Se não, deixe em branco. No campo django user, é necessário adicionar um novo usuário. Clique no ícone + e informe no campo usuário o email do administrador e em permissões selecione Institution Admin. Clique em salvar. 
No campo institution, selecione a instituição previamente criada.
Em e-mail, informe o e-mail do administrador. Se desejar, informe a data de expiração desse usuário. Deixe o campo active desmarcado (será marcado quando o usuário se conectar no serviço pela primeira vez).

Para maiores informações da aplicação *django admin site*, visite https://docs.djangoproject.com/en/1.8/ref/contrib/admin/

#### Configuração dos módulos de autenticação

##### LDAP

Habilitar o módulo em settings.py:

    AUTH_ENABLED_AUTH_SYSTEMS = get_from_env('AUTH_ENABLED_AUTH_SYSTEMS', 'ldap').split(",")

As configurações de conexão e autenticação LDAP devem ser configuradas caso a caso. 

A documentação da biblioteca utilizada pode ser encontrada em:http://pythonhosted.org/django-auth-ldap/example.html

Ela não é muito completa, mas as configurações principais estão no settings.py e são:

`AUTH_LDAP_SERVER_URI`, `AUTH_LDAP_BIND_PASSWORD`, e `AUTH_LDAP_USER_SEARCH`. 

AUTH_LDAP_BIND_DN e AUTH_LDAP_BIND_PASSWORD vão ter um valor configurado se o servidor LDAP exigir usuário e senha para fazer consultas. Ou seja, a configuração é caso a caso e uma leitura cuidadosa da documentação disponível no link do django-auth-ldap é recomendada, para outras dúvidas.

##### Shibboleth
Habilitar o módulo em settings.py:

AUTH_ENABLED_AUTH_SYSTEMS = get_from_env('AUTH_ENABLED_AUTH_SYSTEMS', 'shibboleth').split(",")

e torná-lo padrão, para que a interface multi-instituição seja utilizada:

AUTH_DEFAULT_AUTH_SYSTEM = get_from_env('AUTH_DEFAULT_AUTH_SYSTEM', 'shibboleth')

Configurar demais atributos em settings.py, na seção # Shibboleth auth settings.

As configurações indicadas aqui supõe que o provedor de serviço (apache, módulo shibboleth e demais configurações) está configurado e funcional.

#### Alguns lembretes:

LEMBRAR DE ALTERAR EM SETTINGS.PY A CONSTANTE DEBUG DE TRUE PRA FALSE!

TROCAR [SECRET_KEY](https://docs.djangoproject.com/en/dev/ref/settings/#std:setting-SECRET_KEY) - não usar a do repositório. Há ferramentas na web pra isso, como a disponível em [http://www.miniwebtool.com/django-secret-key-generator/](http://www.miniwebtool.com/django-secret-key-generator/)

Conforme indicado no settings.py, na configuração de SECURE_URL_HOST, ela não deve ser mudada depois que você criar eleições (ao menos eleições reais), pois senão a URL de depósito de voto na eleição ficará inválida, pois esta informação é utilizada na geração da eleição.

A versão do Django utilizada nesta versão do Helios é a 1.8.18, sendo esta a principal fonte de consulta pra aprendizado sobre esta versão: https://docs.djangoproject.com/en/1.8/

--- Original Readme ---

# Helios Election System

Helios is an end-to-end verifiable voting system.

![Travis Build Status](https://travis-ci.org/benadida/helios-server.svg?branch=master)

[![Stories in Ready](https://badge.waffle.io/benadida/helios-server.png?label=ready&title=Ready)](https://waffle.io/benadida/helios-server)
