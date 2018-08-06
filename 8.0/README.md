Ubuntudoo - Italian version
======

docker run -d -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo --name db postgres:9.4

How to build the image:

docker build -t ubuntudoo-it .

Launch it following the instructions on https://hub.docker.com/_/odoo/

======

To run production on server:

`
./build_and_run.sh
`

To run without front proxy:

`
./build_and_run.sh no_proxy
`
