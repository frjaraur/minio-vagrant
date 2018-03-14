#!/bin/bash

echo "Add label storagebackend=s3 on swarm nodes"

docker node update --label-add storagebackend=s3 minio-1
docker node update --label-add storagebackend=s3 minio-2
docker node update --label-add storagebackend=s3 minio-3
docker node update --label-add storagebackend=s3 minio-4


echo "Create secrets"

export MINIO_ACCESS_KEY="accesskey"
export MINIO_SECRET_KEY="secretkey"

echo ${MINIO_ACCESS_KEY} | docker secret create access_key -

echo ${MINIO_SECRET_KEY} | docker secret create secret_key -

echo "Create Certs for TLS deployment"
openssl genrsa -out private.key 2048

echo "
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = ES
L = Minio
O = Minio
OU = Storage
CN = minios3

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1   = minio.labs
DNS.2   = minio-1
DNS.3   = minio-2
DNS.4   = minio-3
DNS.5   = minio-4

" > ssl.conf

openssl req -x509 -nodes -days 730 -newkey rsa:2048 \
-keyout private.key \
-out public.crt -config ssl.conf

docker config create private.key private.key
docker config create public.crt public.crt

echo "Deploy Minio-Server Services"
echo "Docker Stacks do not allow Host Networking"

docker service create --name minio-server \
--secret secret_key \
--secret access_key \
--config source=private.key,target=/root/.minio/certs/private.key,mode=0440 \
--config source=public.crt,target=/root/.minio/certs/public.crt,mode=0440 \
--mode global \
--network host \
--constraint 'node.labels.storagebackend==s3' \
--container-label minio-S3-storage \
--mount type=bind,source=/mnt/data,destination=/data \
minio/minio server http://minio-1/data http://minio-2/data http://minio-3/data http://minio-4/data


## Deploying using host entries because we don't use DNS
# echo "Deploy Minio-NGINX Service (accesible on port 9001"
# docker service create --name minio-nginx \
# --publish 9001:9001 \
# --host "minio-1:10.10.10.11" \
# --host "minio-2:10.10.10.12" \
# --host "minio-3:10.10.10.13" \
# --host "minio-4:10.10.10.14" \
# frjaraur/minio:nginx



# TESTING
# docker run -p 9000:9000 --name minio1 \
# -v /tmp/data:/data \
# -v /tmp/certs:/root/.minio/certs \
# minio/minio server /data
