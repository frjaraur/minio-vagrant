#!/bin/bash
docker node update --label-add storage=s3 minio-1
docker node update --label-add storage=s3 minio-2
docker node update --label-add storage=s3 minio-3
docker node update --label-add storage=s3 minio-4




  #--publish published=9000,target=9000,mode=host \
docker service create \
  --mode global \
  --name minio \
  -e MINIO_ACCESS_KEY=accesskey \
  -e MINIO_SECRET_KEY=secretkey \
  --mount type=bind,source=/mnt/data,destination=/data \
  --constraint 'node.labels.storage == s3' \
  --network minio \
  minio/minio server \
  http://minio-1/data \
  http://minio-2/data \
  http://minio-3/data \
  http://minio-4/data

docker service create \
  --mode replicated \
  --name minio-nginx \
  --network minio \
