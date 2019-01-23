#!/bin/bash

APILIST=(
appengine.googleapis.com
appengineflex.googleapis.com
bigquery-json.googleapis.com
cloudapis.googleapis.com
cloudbuild.googleapis.com
clouddebugger.googleapis.com
cloudkms.googleapis.com
cloudresourcemanager.googleapis.com
cloudtrace.googleapis.com
compute.googleapis.com
container.googleapis.com
containerregistry.googleapis.com
datastore.googleapis.com
deploymentmanager.googleapis.com
iap.googleapis.com
logging.googleapis.com
monitoring.googleapis.com
oslogin.googleapis.com
pubsub.googleapis.com
replicapool.googleapis.com
replicapoolupdater.googleapis.com
resourceviews.googleapis.com
servicemanagement.googleapis.com
serviceusage.googleapis.com
sourcerepo.googleapis.com
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
