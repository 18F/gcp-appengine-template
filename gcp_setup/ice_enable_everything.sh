#!/bin/sh
#
# This is a script that runs all the other scripts and makes sure everything is going.
# It is meant to be used by GSA ICE to set up permissions and users and everything on
# a new GCP project.
#

# make sure that we know what project we are supposed to deploy this to
if [ -z "${GOOGLE_PROJECT_ID}" ] ; then
	echo "the GOOGLE_PROJECT_ID environment variable has not been set: set this to the GCP project ID that you want to add these roles to"
	exit 1
fi

# make sure we are in the proper directory
if [ ! -f ./enable-apis.sh ] ; then
	echo this script must be run from the gcp_setup directory
	exit 1
fi

# make sure we know who the project owner is
if [ -z "${PROJECT_OWNER}" ] ; then
	echo "the PROJECT_OWNER environment variable has not been set: set this to the GCP Project owner's userid, like username@apps.gsa.gov"
	exit 1
fi

echo enabling APIs
./enable-apis.sh

echo enabling audit logs
./enable-audit-logs.sh

echo creating/updating roles
./enable-roles.sh -c

if gcloud iam service-accounts describe "terraform@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com" >/dev/null 2>&1 ; then
	echo terraform service account has already been created
else
	echo creating terraform service service account
	gcloud iam service-accounts create terraform --display-name "Terraform admin account"
fi

echo attaching roles to initial users
gcloud projects add-iam-policy-binding "${GOOGLE_PROJECT_ID}" \
  --member "serviceAccount:terraform@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com" \
  --role "projects/${GOOGLE_PROJECT_ID}/roles/gsa_project_terraform"
gcloud projects add-iam-policy-binding "${GOOGLE_PROJECT_ID}" \
  --member "${PROJECT_OWNER}" \
  --role "projects/${GOOGLE_PROJECT_ID}/roles/gsa_project_owner"
