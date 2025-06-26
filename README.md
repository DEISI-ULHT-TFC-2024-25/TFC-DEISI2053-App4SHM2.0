# Guia de instalação:

dependências:
java 17 , flutter 3.19.3 , mysql

## Instalaçao do server:

Criar a base de dados em MYSQL
A app requer uma base de dados com o nome app4shm e um utilizador app4shm com palavra-passe app4shm123

Pode ser feito com o seguinte script:

create database app4shm_db;
create user 'app4shm'@'localhost' identified by 'app4shm123';
grant all privileges on app4shm_db.* to 'app4shm'@'localhost';
Criar um ficheiro .env em app4shm/settings baseado em .env.example

Depois disso, correr:

python manage.py migrate
Note - In prod:

python manage.py migrate --settings=app4shm.settings.prod

Correr o server (desenvolvimento)
python manage.py runserver
Ficará disponível em localhost:8000

Criar superuser
python manage.py createsuperuser

## Instalacao Mobile:

fazer pub get

fazer run da app
