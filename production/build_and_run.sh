#!/bin/bash

#./run_before_image_creation.sh

# postgres
#docker rm odoo_data
#docker create \
#        -v $(pwd)/postgress-data:/var/lib/postgresql/data \
#        --name odoo_data \
#        busybox

docker stop db
docker rm db
docker run \
        -p 5432 \
        -d \
        -e POSTGRES_DB=postgres \
        -e POSTGRES_USER=odoo \
        -e POSTGRES_PASSWORD=odoo \
        --name db \
        -v $(pwd)/postgress-data/:/var/lib/postgresql/data \
        postgres:10

# app itself
CONTAINER=odoo12
IMAGE=ubuntudoo-it:12
docker stop $CONTAINER
docker rm $CONTAINER
#docker build -t $IMAGE .
#docker build -t odoo12 < Dockerfile
docker build -t odoo12 .

docker run \
        -d \
        -v $(pwd):/etc/odoo \
        -p 80:8069 \
        --name odoo12 \
        --link db:db \
        -t odoo12


#            -v $(pwd)/odoo-data/var_lib_odoo:"/var/lib/odoo" \
#        -v $(pwd)/odoo-data/etc_odoo_addons:"/etc/odoo/addons/" \
#        -v $(pwd)/odoo-data/mnt_extra-addons:"/mnt/extra-addons/" \
#        -v $(pwd)/odoo-data/usr/lib/python3/dist-packages:"/usr/lib/python3/dist-packages/odoo/addons/" \


# front proxy
if [ "$1" != "no_proxy" ]; then
docker stop front_proxy
docker build front_proxy -f front_proxy/Dockerfile -t front_proxy;
docker run -d \
        -v /etc/letsencrypt:/etc/letsencrypt \
        -p 80:80 \
        -p 443:443 \
        --name front_proxy --env-file ./front_proxy/env.list \
        --link odoo12:odoo12 \
        --link db:db \
        --privileged \
        --rm front_proxy
fi

IP=$(echo $(hostname -I) | cut -d' ' -f 1)
echo "App is running on:"
echo "http://$IP/"


docker stop adminer
docker rm adminer
docker run \
        --name adminer \
        --link db:db \
        -d \
        -p 8080:80 \
        dockette/adminer:pgsql

