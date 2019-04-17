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
	set $line
	INSTANCE=$1
	SERVICE=$2
	VERSION=$3
	IP=$4

	# This is a bit of a hack.  Collect the ssh key ahead of time automatically, since gcloud cannot:
	# https://stackoverflow.com/questions/51822551/gcloud-app-instances-ssh-command-disable-ssh-host-key-checking
	# Also, the ssh key changes when you turn off debug and it relaunches the instance.
	ssh-keygen -f ~/.ssh/google_compute_known_hosts -R gae."${PROJECT}"."${INSTANCE}"
	ssh -o StrictHostKeyChecking=no "$(whoami)"@"${IP}" -o CheckHostIP=no -o HostKeyAlias=gae."${PROJECT}"."${INSTANCE}" -o IdentitiesOnly=yes -o UserKnownHostsFile=~/.ssh/google_compute_known_hosts hostname </dev/null

	# execute the commands to get the fim.sh script out there and run.
	gcloud -q beta app instances scp --version="${VERSION}" --service="${SERVICE}" fim.sh "${INSTANCE}":fim.sh
	rm -f /tmp/fimout.$$
	gcloud -q app instances ssh --version="${VERSION}" --service="${SERVICE}" "${INSTANCE}" -- "./fim.sh | logger -sp syslog.crit 2>&1" > /tmp/fimout.$$

	if [ -s /tmp/fimout.$$ ] ; then
		echo "========== Found containers with unexpected changes (not recycling container for forensic purposes):"
		cat /tmp/fimout.$$
		touch /tmp/foundfim.$$
	else
		echo "========== Found no unexpected changes for ${INSTANCE}: disabling debug, which will cause the instance to relaunch"
		gcloud -q app instances disable-debug --version="${VERSION}" --service="${SERVICE}" "${INSTANCE}"
	fi
done

if [ -e /tmp/foundfim.$$ ] ; then
	rm -f /tmp/foundfim.$$
	echo  =================== exiting uncleanly because we found unexpected changes in at least one container
	exit 1
else
	exit 0
fi
