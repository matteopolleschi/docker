Ubuntudoo - Italian version
======

Before building the image:

bash run_before_image_creation.sh 

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