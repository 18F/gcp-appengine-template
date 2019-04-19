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
C /home$
C /home/logsync$
A /home/logsync/.config$
A /home/logsync/.config/gcloud$
A /home/logsync/.config/gcloud/.last_update_check.json$
A /home/logsync/.config/gcloud/active_config$
A /home/logsync/.config/gcloud/configurations$
A /home/logsync/.config/gcloud/configurations/config_default$
A /home/logsync/.config/gcloud/gce$
A /home/logsync/.gsutil$
A /home/logsync/.gsutil/credstore2.lock$
A /home/logsync/.gsutil/gcecredcache$
A /home/logsync/.gsutil/gcecredcache.lock$
A /home/logsync/.gsutil/tracker-files$
A /home/logsync/.gsutil/credstore2$
C /root$
A /root/.aspnet$
A /root/.aspnet/DataProtection-Keys$
A /root/.aspnet/DataProtection-Keys/key
C /tmp$
A /tmp/clr-debug-pipe-
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

