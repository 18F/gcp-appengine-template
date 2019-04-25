#!/bin/bash

APILIST=(
appengineflex.googleapis.com
cloudapis.googleapis.com
clouddebugger.googleapis.com
cloudkms.googleapis.com
cloudresourcemanager.googleapis.com
cloudscheduler.googleapis.com
cloudtrace.googleapis.com
iamcredentials.googleapis.com
logging.googleapis.com
monitoring.googleapis.com
oslogin.googleapis.com
sql-component.googleapis.com
sqladmin.googleapis.com
storage-api.googleapis.com
storage-component.googleapis.com
websecurityscanner.googleapis.com
)

for api in "${APILIST[@]}"; do
  if [ $(gcloud services list --filter "${api}" | wc -l) -eq 0 ]; then
    gcloud services enable "${api}"
  fi
done

exit 0
