#!/bin/bash
set -e

gcloud projects get-iam-policy $GOOGLE_PROJECT_ID > $GOOGLE_PROJECT_ID.iam.policy.yml

cat <<EOF >> $GOOGLE_PROJECT_ID.iam.policy.yml
auditConfigs:
- auditLogConfigs:
  - logType: DATA_WRITE
  - logType: DATA_READ
  service: storage.googleapis.com
- auditLogConfigs:
  - logType: DATA_WRITE
  - logType: DATA_READ
  service: cloudkms.googleapis.com
EOF

gcloud projects set-iam-policy $GOOGLE_PROJECT_ID $GOOGLE_PROJECT_ID.iam.policy.yml
