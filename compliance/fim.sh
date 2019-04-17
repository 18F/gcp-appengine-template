#!/bin/sh
#
# This script will report diffs to running
# app containers (not supporting containers managed by
# Google) from their original images. 
# 
# Can be used for File Integrity Monitoring.
#

# This is a list of regex patterns to exclude so that we don't have
# False Positives.
cat <<EOF > /tmp/excludes.$$
/app/tmp/cache/bootsnap
A /cloudsql$
C /app$
C /app/tmp$
C /app/tmp/cache$
A /app/tmp/restart.txt$
C /var$
C /var/log$
A /var/log/app_engine$
EOF

# Find the differences for all the containers that are not google-appengine
# support containers (like proxies and stackdriver agents, etc).
docker ps --format '{{.Names}}\t{{.Image}}' | grep -v 'gcr.io/google-appengine' | while read -r line ; do
	set $line
	NAME=$1
	IMAGE=$2
	HOST=$(hostname)

	docker diff "$NAME" | grep -vEf /tmp/excludes.$$ > /tmp/diff.$$
	if [ -s /tmp/diff.$$ ] ; then
		# make sure that we escape / so that sed will be happy
		SEDIMAGE=$(echo "$IMAGE" | sed 's/\//\\\//g')
		sed "s/^/found unexpected changes in $NAME $SEDIMAGE on $HOST: /" /tmp/diff.$$
	fi
	rm -f /tmp/diff.$$
done

rm -f /tmp/excludes.$$

