#!/bin/bash

./run_before_image_creation.sh

# postgres
docker rm odoo_data
docker create -v /var/lib/postgresql/data --name odoo_data busybox
docker stop db
docker rm db
docker run -p 5432:5432 -d -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo --name db --volumes-from odoo_data postgres:9.4

# app itself
CONTAINER=odoo8
IMAGE=ubuntudoo-it:8
docker stop $CONTAINER
docker rm $CONTAINER
docker build -t $IMAGE .
docker run -v $(pwd):/etc/odoo -p 80:8069 --name odoo8 --link db:db -t ubuntudoo-it:8

IP=$(echo $(hostname -I) | cut -d' ' -f 1)
echo "App is running on:"
echo "http://$IP/"

