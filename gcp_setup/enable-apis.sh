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

# save the list of services that are actually available
gcloud services list > /tmp/services.$$

for api in "${APILIST[@]}"; do
  # check that the service actually exists before enabling it
  if grep -E "^${api}" "/tmp/services.$$" >/dev/null ; then
    gcloud services enable "${api}"
  fi
done

# clean up
rm /tmp/services.$$

exit 0
