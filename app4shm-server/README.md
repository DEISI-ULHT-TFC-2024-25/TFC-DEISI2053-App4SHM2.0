# App4SHM Server (Django version)

## Database creation

The application requires an existing database called app4shm and a user app4shm with pass app4shm123

Here's the script to prepare this:

    create database app4shm_db;
    create user 'app4shm'@'localhost' identified by 'app4shm123';
    grant all privileges on app4shm_db.* to 'app4shm'@'localhost';

Create a file called .env on app4shm/settings based on .env.example

After, run this command on project root folder

    python manage.py migrate

Note - In prod:

    python manage.py migrate --settings=app4shm.settings.prod

## Launch server (development)

    python manage.py runserver

Application will be available on localhost:8000

## Create superuser

    python manage.py createsuperuser

## Running tests

    python manage.py test app4shm.apps.core.tests --settings=app4shm.settings.test

## Running the cleanup task in dev (clears all info associated with structure 'Test' in this example)

    python manage.py cleanup Teste --settings=app4shm.settings.local

## Tests in dev

teste / nullnull123

## Notes

* Project structure inspired by https://simpleisbetterthancomplex.com/tutorial/2021/06/27/how-to-start-a-production-ready-django-project.html
* Nice intro do django: https://www.youtube.com/watch?v=ZjAMRnCu-84