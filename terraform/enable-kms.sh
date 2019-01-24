#!/bin/bash
#
# This script makes it so that AppEngine can use KMS
# 
set -e

APPENGINE=$(gcloud iam service-accounts list --format=json | jq -r '.[] | select(.displayName == "App Engine default service account").email')
ROLES="roles/cloudkms.admin roles/cloudkms.cryptoKeyEncrypterDecrypter"

for role in $ROLES ; do
	echo adding $role to serviceAccount:$APPENGINE
	gcloud projects add-iam-policy-binding $GOOGLE_PROJECT_ID \
		--member serviceAccount:$APPENGINE --role $role
done
