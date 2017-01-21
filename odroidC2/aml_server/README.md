docker build . -t aml_server

docker run -d --name aml_encrypt_gbx aml_server
