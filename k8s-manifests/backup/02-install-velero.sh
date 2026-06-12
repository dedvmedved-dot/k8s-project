#!/bin/bash
# Установка Velero с MinIO как S3 хранилищем

VELERO_VERSION="v1.14.0"

# Скачиваем и устанавливаем Velero
wget -q https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz
tar -xzf velero-${VELERO_VERSION}-linux-amd64.tar.gz
sudo mv velero-${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/
rm -rf velero-${VELERO_VERSION}*

# Создаём credentials для MinIO
cat > /tmp/velero-credentials << 'CRED'
[default]
aws_access_key_id=minioadmin
aws_secret_access_key=minioadmin
CRED

# Устанавливаем Velero
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.10.0 \
  --bucket velero \
  --secret-file /tmp/velero-credentials \
  --use-volume-snapshots=false \
  --backup-location-config \
    region=us-east-1,s3ForcePathStyle=true,s3Url=http://minio.backup.svc:9000 \
  --namespace velero \
  --wait

# Создаём bucket в MinIO (после установки Velero)
echo "=== Velero установлен ==="
velero version
