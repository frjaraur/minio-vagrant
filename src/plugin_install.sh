#!/bin/bash
export MINIO_ACCESS_KEY="accesskey"
export MINIO_SECRET_KEY="secretkey"
docker plugin install rexray/s3fs \
  S3FS_OPTIONS="allow_other,use_path_request_style,nonempty,url=http://minio-1:9000" \
  S3FS_ENDPOINT="http://minio-1:9000" \
  S3FS_ACCESSKEY="${MINIO_ACCESS_KEY}" \
  S3FS_SECRETKEY="${MINIO_SECRET_KEY}" \
  REXRAY_LOGLEVEL=debug \
--alias s3fs --grant-all-permissions
