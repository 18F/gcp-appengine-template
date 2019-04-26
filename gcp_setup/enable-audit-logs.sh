#!/bin/bash
#
# Set up audit logs on storage and kms accesses
#
set -e

gcloud projects get-iam-policy "$GOOGLE_PROJECT_ID" > "$GOOGLE_PROJECT_ID.iam.policy.yml"

cat <<EOF > "$GOOGLE_PROJECT_ID.iam.policy.yml.new"
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

# find common lines between our new policy and the one already installed
comm -12 "$GOOGLE_PROJECT_ID.iam.policy.yml" "$GOOGLE_PROJECT_ID.iam.policy.yml.new" > "$GOOGLE_PROJECT_ID.iam.policy.yml.common"

# if the common lines and the new policy addition are the same, it's already up there
if cmp "$GOOGLE_PROJECT_ID.iam.policy.yml.new"  "$GOOGLE_PROJECT_ID.iam.policy.yml.common" >/dev/null ; then
	echo auditing policy is already set
else
	cat "$GOOGLE_PROJECT_ID.iam.policy.yml.new" >> "$GOOGLE_PROJECT_ID.iam.policy.yml"
	gcloud projects set-iam-policy "$GOOGLE_PROJECT_ID" "$GOOGLE_PROJECT_ID.iam.policy.yml"
fi

# clean up
rm -f "$GOOGLE_PROJECT_ID.iam.policy.yml" "$GOOGLE_PROJECT_ID.iam.policy.yml.new" "$GOOGLE_PROJECT_ID.iam.policy.yml.common"
