#!/bin/sh
#
# This script is meant to be run periodically by CircleCI.  It will run fim.sh
# on every app engine instance and then turn debug mode back off.  This will
# cause the instances to recycle, but we will schedule this to run at night,
# and HA systems will be fine.
#

INSTANCES=$(gcloud app instances list --format=json)
PROJECT=$(gcloud info --format=json | jq -r .config.project)

echo "${INSTANCES}" | jq -r '.[] | .id + " " +  .service + " " + .version + " " + .instance.vmIp' | while read -r line ; do
	echo ========= doing "$line"
	set $line
	INSTANCE=$1
	SERVICE=$2
	VERSION=$3
	IP=$4

	# This is a bit of a hack.  Collect the ssh key ahead of time automatically, since gcloud cannot:
	# https://stackoverflow.com/questions/51822551/gcloud-app-instances-ssh-command-disable-ssh-host-key-checking
	# Also, the ssh key changes when you turn off debug and it relaunches the instance.
	#    open ssh up with an scp that might fail
	(timeout 20 gcloud -q app instances scp --version="${VERSION}" --service="${SERVICE}" fim.sh "${INSTANCE}":fim.sh) </dev/null
	#    get rid of the old key, if it exists
	ssh-keygen -f ~/.ssh/google_compute_known_hosts -R gae."${PROJECT}"."${INSTANCE}"
	#    collect the current host key and make sure it's named properly
	#    Sometimes it takes a while for ssh to become live, but we will skip the instance if takes too long.
	loopcount=1
	maxloop=10
	loopsleep=2
	break="false"
	until grep "gae.${PROJECT}.${INSTANCE} " ~/.ssh/google_compute_known_hosts >/dev/null ; do
		ssh-keyscan -t ecdsa "${IP}" | sed "s/^${IP} /gae.${PROJECT}.${INSTANCE} /" >> ~/.ssh/google_compute_known_hosts
		if [ "$loopcount" -ge "$maxloop" ] ; then
			((seconds = maxloop * loopsleep))
			echo "could not get ssh key from ${IP} after ${seconds} seconds:  something must be wrong with this instance"
			break="true"
			break
		fi
		sleep "$loopsleep"
	done
	if [ "$break" = "true" ] ; then
		echo "skipping to next instance"
		continue
	fi

	# execute the commands to get the fim.sh script out there and run.
	# The FIM output also gets sent to syslog, so you can look for it in stackdriver.
	(gcloud -q app instances scp --version="${VERSION}" --service="${SERVICE}" fim.sh "${INSTANCE}":fim.sh) </dev/null
	rm -f /tmp/fimout.$$
	(gcloud -q app instances ssh --version="${VERSION}" --service="${SERVICE}" "${INSTANCE}" -- "./fim.sh | logger -sp syslog.crit 2>&1") </dev/null > /tmp/fimout.$$

	if [ -s /tmp/fimout.$$ ] ; then
		echo "========== Found containers with unexpected changes (not recycling container for forensic purposes):"
		cat /tmp/fimout.$$
		touch /tmp/foundfim.$$
	else
		echo "========== Found no unexpected changes for ${INSTANCE}: disabling debug, which will cause the instance to relaunch"
		(gcloud -q app instances disable-debug --version="${VERSION}" --service="${SERVICE}" "${INSTANCE}") </dev/null
	fi
done

if [ -e /tmp/foundfim.$$ ] ; then
	rm -f /tmp/foundfim.$$
	echo  =================== exiting uncleanly because we found unexpected changes in at least one container
	exit 1
else
	exit 0
fi
