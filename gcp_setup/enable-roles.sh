#!/bin/sh
#
# This script pulls together all of the roles needed for the project.
# It will place the role yaml in /tmp/ for you to review.
#
# Execute this like "./enable-roles.sh -c" to create/update the roles
# automatically.
# 
# You will need to have GOOGLE_PROJECT_ID set to the project ID that
# you want to create these roles in.  Do something like this:
# export GOOGLE_PROJECT_ID=my-project-id
#

# make sure that we know what project we are supposed to deploy this to
if [ -z "${GOOGLE_PROJECT_ID}" ] ; then
	echo "the GOOGLE_PROJECT_ID environment variable has not been set: set this to the GCP project ID that you want to add these roles to"
	exit 1
fi

# These are bad permissions that need to be filtered out because they
# exist in a source role, but cannot be added to a custom role for some
# reason.  Suspect that stackdriver isn't quite enabled, and we aren't
# allowed project listing because we are part of an org.
BADPERMS="
resourcemanager.projects.list
stackdriver.projects.edit
serviceusage.services.enable
"
echo "${BADPERMS}" | sed '/^$/d' > /tmp/badperms.$$

# This is the function that pulls down the base policies, removes the
# permissions that are improper, and creates/updates the custom policies in the
# GCP Project
create_policy () {
	rm -f /tmp/iam_permissions.$$

	for i in ${ROLES} ; do
		gcloud iam roles describe "$i" | grep -v serviceusage.services.enable | grep -v -Ff /tmp/badperms.$$ | grep -E '^- ' >> /tmp/iam_permissions.$$
	done

	rm -f /tmp/new_role.$$
	cat <<EOF > /tmp/new_role.$$
title: ${TITLE}
description: ${DESCRIPTION}
stage: GA
includedPermissions:
EOF
	sort -u /tmp/iam_permissions.$$ >> /tmp/new_role.$$
	rm -f /tmp/iam_permissions.$$

	if [ "$1" = "-c" ] ; then
		# update the role if it exists, otherwise create it
		if gcloud iam roles describe "$NAME" --project "${GOOGLE_PROJECT_ID}" >/dev/null 2>&1 ; then
			gcloud iam roles update "$NAME" --project "${GOOGLE_PROJECT_ID}" --file /tmp/new_role.$$
		else
			gcloud iam roles create "$NAME" --project "${GOOGLE_PROJECT_ID}" --file /tmp/new_role.$$
		fi
		rm -f /tmp/new_role.$$
	else
		# let the user review the policies
		mv /tmp/new_role.$$ "/tmp/${NAME}.yaml"
		echo "created /tmp/${NAME}.yaml role for your review, but did not create/update it in GCP"
	fi
}

####################################################
# create the monitoring.admin role
ROLES="
 roles/monitoring.admin
"
TITLE="GSA Project Monitoring Admin"
DESCRIPTION=$(echo "$ROLES without serviceusage.services.enable" | tr -d '\n' )
NAME=gsa.monitoring.admin
create_policy "$1"
