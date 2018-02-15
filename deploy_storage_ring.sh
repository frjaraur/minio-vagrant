#!/bin/bash

echo "Add label storagebackend=s3 on swarm nodes"

docker node update --label-add storagebackend=s3 minio-1
docker node update --label-add storagebackend=s3 minio-2
docker node update --label-add storagebackend=s3 minio-3
docker node update --label-add storagebackend=s3 minio-4


echo "Create secrets"

MINIO_ACCESS_KEY="accesskey"
MINIO_SECRET_KEY="secretkey"

echo ${MINIO_ACCESS_KEY} | docker secret create access_key -

echo ${MINIO_SECRET_KEY} | docker secret create secret_key -

echo "Deploy Minio-Server Services"
echo "Docker Stacks do not allow Host Networking"

docker service create --name minio-server \
--secret secret_key \
--secret access_key \
--mode global \
--network host \
--constraint 'node.labels.storagebackend==s3' \
--container-label minio-S3-storage \
--mount type=bind,source=/mnt/data,destination=/data \
minio/minio server http://minio-1/data http://minio-2/data http://minio-3/data http://minio-4/data


## Deploying using host entries because we don't use DNS
echo "Deploy Minio-NGINX Service (accesible on port 9001"
docker service create --name minio-nginx \
--publish 9001:9001 \
--host "minio-1:10.10.10.11" \
--host "minio-2:10.10.10.12" \
--host "minio-3:10.10.10.13" \
--host "minio-4:10.10.10.14" \
frjaraur/minio:nginx

