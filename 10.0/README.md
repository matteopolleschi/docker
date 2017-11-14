Ubuntudoo - Italian version
======

Before building the image:

bash run_before_image_creation.sh 

How to build the image:

docker build -t ubuntudoo-it .

Launch it following the instructions on https://hub.docker.com/_/odoo/

docker run -d -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo --name db postgres:9.4

or

docker run -p 5432:5432 -d -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo --name db postgres:9.4

docker run -p 8069:8069 --name odoo --link db:db -t ubuntudoo-it

