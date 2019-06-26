Ubuntudoo - Italian version
===========================

To run production on server:

1. Introduction

OpenERP is a full-featured business application suite, with more than 700 modules. Despite the complexity of technical work and the importance of the community members in the development of such a huge project, our goal is to make software that is easy to use, user friendly, and consistent while remaining fully open.

1.1. What is docker container?

A container is a standard unit of software that packages up code and all its dependencies so the application runs quickly and reliably from one computing environment to another. A Docker container image is a lightweight, standalone, executable package of software that includes everything needed to run an application: code, runtime, system tools, system libraries and settings.

Container images become containers at runtime and in the case of Docker containers - images become containers when they run on Docker Engine. Available for both Linux and Windows-based applications, containerized software will always run the same, regardless of the infrastructure. Containers isolate software from its environment and ensure that it works uniformly despite differences for instance between development and staging.

2. The Development, Staging, and Production Model

There are three different environments that you'll probably deal with at some point. Each environment has its own properties and uses and it's important to use them accordingly. Once you know what the environments are used for it'll make since why we have so many of them.

The main three environments are: development, stage, and production. 

2.1 Development

This is the environment that's on your computer. Here is where you'll do all of your code updates. It's where all of your commits and branches live along with those of your co-workers. The development environment is usually configured differently from the environment that users work in.

A lot of preliminary testing will happen in this environment. You don't want to release your code before you make sure it works locally at least. Go through your code as thoroughly as you can so that you limit the bugs that squeak through to the next environment.

2.2. Staging

The stage environment is as similar to the production environment as it can be. You'll have all of the code on a server this time instead of a local machine. It'll connect to as many services as it can without touching the production environment.

All of the hard core testing happens here. Any database migrations will be tested here and so will any configuration changes. When you have to do major version updates, the stage environment helps you find and fix any issues that come up too.

Stage server also can be used as Test server, User Acceptance Test (UAT), and Demo server.

3.3. Production

The production environment is where users access the final code after all of the updates and testing. Of all the environments, this one is the most important.

This is where companies make their money so you can't have any crippling mistakes here. That's why you have to go through the other two environments with all of the testing first. Once you're in production, any bugs or errors that remain will be found by a user and you can only hope it's something minor.

4. Enveronment praparation stages

4.1 Configuration files

4.1.1 .odoo.config

Each enveronment has own configuration file.

odoo released version, example of release dates (released) at: http://nightly.odoo.com/12.0/nightly/deb/
ODOO_VERSION=12.0

Never setup production RELEASE enveronment as latest, because each time you build the server, the enveronment would be different. Test staeble release release, ask collegues, or experts which version best suites to your installation. Recomended to play with latest on development enveronment.
ODOO_RELEASE=latest
or
ODOO_RELEASE=20190609

setup docker's image name, should be different on dev, staging and production if you host them on the same server
ODOO_IMAGE=odoo12prod

odoo's container name, should be different for dev, staging, and production environment. You can use this name to reference to docker's container, check logs, start and stop container.
ODOO_CONTAINER=odoo12-production

odoo's port, should be different for dev, staging, and production environment
ODOO_PORT=8091

odoo's database name, should be different for dev, staging, and production environment
ODOO_DATABASE=master

odoo's user with rights to access database, could be different for dev, staging, and production environment.
ODOO_USER=odoo
ODOO_PASSWORD=odoo


Production enveronment is usually configured to export data to staging enveronment, Staging is configured to export data to production after tests. Development enveronment configured to export data to staging enveronment, EXPORT_DB represents the name of database to be replaced in SQL file.
Export path directory could be on local or remote filesystem
EXPORT_PATH=/home/root/Code/odoo/it/ubuntudoo-it/production/import
EXPORT_PATH=10.0.0.60:/root/ubuntudoo-it/staging/import

name of database and directories on server to export database to
EXPORT_DB=staging_db

All admin's actions and script's feedback are stored in this log file. Do not forget to rotate and/or clean this file.
MAINTENANCE_LOG_FILE=.odoo_maintenance.log


4.1.2 Build/Dockerfile

if you do not set up in enviromnet those vaiables, defauld values would be used.

ARG ODOO_VERSION=12.0
ARG ODOO_RELEASE=20190108

4.1.3 Build/run_before_image_creation.sh

That script runs each time when required to prebuild addons.

Check very important feature. During prebuilding of addons, you can reference special revision (commit) of code, to be sure that Odoo's revision is working well with Odoo's module revision. In that case you need to identify commit's ID, then cd to diretory and perform git checkout. 

Example of code for special revision of l10n-italy code:
* (echo "Checkout to commit" && cd l10n-italy && git checkout 31e23cf74fad99a90b82c909fcb7ed51ae19d9d6)


4.2. choose which enveronment to use


cd dev

cd staging

cd production

original images are stored in 12.0, 11.0, and 8.0 directories


4.3 Prebuild addons

./odoo-docker.sh -p prebuild

4.4 Build odoo server

./odoo-docker.sh -p build

4.5 Start application

./odoo-docker.sh -p startall

4.6 Import/Export and Backup/Restore 

Exprort all data to $EXPORT_PATH
./odoo-docker.sh -p export

Move to the server via ssh or cd  where data is exported
./odoo-docker.sh -p import

Backup existing server to the volume backup/[name of of db]/
./odoo-docker.sh -p backup

Restore existing server to the volume backup/[name of of db]/
./odoo-docker.sh -p restore

4.7. Check log file of Odoo server
./odoo-docker.sh -p log

4.8 Check statis of the Odoo server
./odoo-docker.sh -p status

4.9 Stop the Odoo server
./odoo-docker.sh -p stopall