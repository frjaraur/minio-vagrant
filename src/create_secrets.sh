#!/bin/bash
export MINIO_ACCESS_KEY="accesskey"
export MINIO_SECRET_KEY="secretkey"

echo ${MINIO_ACCESS_KEY} | docker secret create access_key -

echo ${MINIO_SECRET_KEY} | docker secret create secret_key -
