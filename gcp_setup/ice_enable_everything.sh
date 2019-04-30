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
gcloud config set project "${GOOGLE_PROJECT_ID}"
PROJECT_NUMBER=$(gcloud projects describe "${GOOGLE_PROJECT_ID}" --format=text | awk '/^projectNumber:/ {print $2}')

# make sure we are in the proper directory
if [ ! -f ./enable-roles.sh ] ; then
	echo this script must be run from the gcp_setup directory
	exit 1
fi

# make sure we know who the project owner is
if [ -z "${PROJECT_OWNER}" ] ; then
	echo "the PROJECT_OWNER environment variable has not been set: set this to the GCP Project owner's userid, like username@apps.gsa.gov"
	exit 1
fi

############################################################
echo enabling services/APIs
APILIST="
	appengineflex.googleapis.com
	cloudapis.googleapis.com
	cloudbuild.googleapis.com
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
"
# save the list of services that are actually available
gcloud services list > /tmp/services.$$
for api in ${APILIST} ; do
  # check that the service actually exists before enabling it
  if grep -E "^${api}" "/tmp/services.$$" >/dev/null ; then
    gcloud services enable "${api}"
  fi
done
# clean up
rm /tmp/services.$$

############################################################
echo "enabling appEngine"
gcloud app create --region=us-west2 >/dev/null 2>&1 || true

############################################################
echo enabling audit logs
./enable-audit-logs.sh

############################################################
echo "creating/updating roles:  You may have to say 'Y' a few times for this"
./enable-roles.sh -c

############################################################
if gcloud iam service-accounts describe "terraform@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com" >/dev/null 2>&1 ; then
	echo terraform service account has already been created
else
	echo creating terraform service account
	gcloud iam service-accounts create terraform --display-name "Terraform admin account"
fi

############################################################
# function to add roles to a user/group
# Be sure to set ROLES variable before running
# usage:  add_roles <user|group|serviceAccount> <username or groupname>
# example: ROLES="roles/viewer roles/cloudsql.admin" add_roles group gsa_admin_group
add_roles () {
	for role in ${ROLES} ; do
		echo "  adding $role to $1 $2"
		gcloud projects add-iam-policy-binding "${GOOGLE_PROJECT_ID}" \
		  --member "$1:$2" \
		  --role "$role" >/dev/null
	done
}


############################################################
# enable terraform
echo "attaching roles to terraform"
ROLES="
	roles/viewer
	roles/iam.securityReviewer
	roles/cloudsql.admin
	roles/appengine.appAdmin
	roles/appengine.deployer
	roles/cloudbuild.builds.editor
	roles/cloudbuild.builds.builder
	roles/compute.storageAdmin
	roles/cloudkms.admin
	roles/cloudscheduler.admin
	roles/storage.admin
	roles/logging.admin
"
add_roles serviceAccount "terraform@${GOOGLE_PROJECT_ID}.iam.gserviceaccount.com"

############################################################
# Enable app to do schema migrations 
echo "attaching roles to enable schema migrations"
gcloud projects add-iam-policy-binding "${GOOGLE_PROJECT_ID}" \
  --member "serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role "roles/cloudsql.client" >/dev/null

############################################################
# enable appEngine to use KMS
echo "attaching roles to allow appengine to use KMS"
ROLES="
	roles/cloudkms.admin
	roles/cloudkms.cryptoKeyEncrypterDecrypter
"
add_roles serviceAccount "${GOOGLE_PROJECT_ID}@appspot.gserviceaccount.com"

############################################################
# enable project owner, or the owner group if set.
echo "attaching roles to Project Owners"
ROLES="
	roles/viewer
	roles/monitoring.viewer
	roles/cloudsql.admin
	roles/appengine.appAdmin
	roles/cloudkms.admin
	roles/cloudscheduler.admin
	roles/storage.admin
	roles/logging.admin
	projects/${GOOGLE_PROJECT_ID}/roles/gsa.monitoring.admin
"
if [ -z "${PROJECT_OWNER_GROUP}" ] ; then
	echo "=============> To enable Project Owners as a group, create a google group, add Owners to it, set the PROJECT_OWNER_GROUP environment variable to the name of the google group, and re-run this script."
	add_roles user "${PROJECT_OWNER}"
else
	add_roles group "${PROJECT_OWNER_GROUP}"
fi

############################################################
# Enable project admin
echo "attaching roles to Project Admins"
ROLES="
	roles/viewer
	roles/monitoring.viewer
	roles/cloudsql.admin
	roles/appengine.appAdmin
	roles/cloudkms.admin
	roles/cloudscheduler.admin
	roles/storage.admin
	roles/logging.admin
	projects/${GOOGLE_PROJECT_ID}/roles/gsa.monitoring.admin
"
if [ -z "${PROJECT_ADMIN_GROUP}" ] ; then
	echo "=============> To enable Project Admins, create a google group, add Admins to it, set the PROJECT_ADMIN_GROUP environment variable to the name of the google group, and re-run this script."
else
	add_roles group "${PROJECT_ADMIN_GROUP}"
fi

############################################################
# Enable project dev read/write
echo "attaching roles to Developers who need r/w access"
if [ -z "${PROJECT_DEVRW_GROUP}" ] ; then
	echo "=============> To enable Dev r/w users, create a google group, add Developers to it, set the PROJECT_DEVRW_GROUP environment variable to the name of the google group, and re-run this script."
else
	ROLES="
		roles/viewer
		roles/monitoring.viewer
		roles/cloudsql.admin
		roles/appengine.appAdmin
		roles/cloudkms.admin
		roles/cloudscheduler.admin
		roles/storage.admin
		roles/logging.admin
		projects/${GOOGLE_PROJECT_ID}/roles/gsa.monitoring.admin
	"
	add_roles group "${PROJECT_DEVRW_GROUP}"
fi

############################################################
# Enable project dev readonly
echo "attaching roles to Developers who need readonly access"
if [ -z "${PROJECT_DEV_GROUP}" ] ; then
	echo "=============> To enable Dev readonly users, create a google group, add Developers to it, set the PROJECT_DEV_GROUP environment variable to the name of the google group, and re-run this script."
else
	ROLES="
		roles/viewer
		roles/monitoring.viewer
	"
	add_roles group "${PROJECT_DEV_GROUP}"
fi
