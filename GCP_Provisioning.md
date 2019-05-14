# GCP Provisioning Notes

For GSA ICE folks who are provisioning the GCP Projects for this system,
the overall architecture is:
![diagram of gcp org, project, apps, and services](gcp_diagram.png)

More details on the template can be found [here](DEVSECOPS.md) as well.

## GCP Project Provisioning

You will need to create three different GCP projects:
* dev
* staging
* prod

It is recommended that you name them something with "dev/staging/prod" in the
names, to help the users know which project they are operating on, but
it is not a requirement.

Once provisioned, you should request that their "In-use IP addresses" quota
be upped to 15 in the us-west region.  You can find this on the
[GCP Quota Page](https://console.cloud.google.com/iam-admin/quotas).
If asked for details, you can say that you have 4 services which may have
up to 3 versions running at once (like during a deploy), requiring at
least 12.  Adding 3 more gives us a bit of breathing room in just in case.

When you provision the Production GCP Project, double this to 30, because you
will be deploying failover instances, thus you'll need at least 2x the IPs.


## Google Groups

It is also recommended that you create google groups for the different types
of users, so that it is easy to enable users for different roles.  The list
of user types are currently:
* Project Owners
* Project Administrators
* Developers with Read/Write access
* Developers with Readonly access

The google group names can be used later on for IAM role provisioning.


## GCP Project Setup

Once everything is set up, you can use the `gcp-appengine-template/gcp_setup/ice_enable_everything.sh`
script to add the service accounts and IAM roles and everything required
for normal operation in each GCP Project.

You can look at the scripts to see what they do, but the main thing that they do
is enable the services that they need to deploy and use App Engine, Cloud SQL,
Cloud KMS, Cloud Storage, and the related build/deploy resources, create the
terraform service account, and then add various IAM roles to the different
groups so that the group members will be able to look at logs, restart things,
etc.

### Setup using GCP Cloud Shell

The easiest way to run the `ice_enable_everything.sh` script is to:
1. Open up a [GCP Console window](https://console.cloud.google.com/) and
   click on the [Cloud Shell](https://cloud.google.com/shell/) icon.
   A cloud shell instance should launch at the bottom of the browser window.
1. `git clone https://github.com/18F/gcp-appengine-template` to clone the repo with the script in it.
1. `cd gcp-appengine-template/gcp_setup` to get into the proper directory
1. Create or copy in a config file for the script.  An example config file can be found in
   `gcp-appengine-template/gcp_setup/ice_enable_everything.cfg.example`.  You will need to
   change all `XXX` instances into something real.

   If you are unfamiliar with editors on unix such as `vi`, consider either using
   `pico yourconfigfile.cfg`, which has good instructions built in, or just editing
   the file locally using your favorite editor and then cut/pasting the contents of
   the file in after typing `cat > yourconfigfile.cfg`, then doing a `^D` (Control-d)
   to end the file creation.
1. `./ice_enable_everything.sh yourconfigfile.cfg` to run the script (adjust
   the path to yourconfigfile.cfg to where you created it).  You may have to say `Y`
   a couple of times.
1. For bootstrapping, you will need to add the `roles/owner` role to the terraform service account
   temporarily.  Once the environment has been bootstrapped with terraform, you can remove this
   role from the terraform service account.  Coordinate with the Project Owner on this.

## Followup

After the Project Owner has gotten their infrastructure bootstrapped, you should be
able to remove the `roles/owner` role from the terraform service account.

It is also possible that the Project Owner may request more people to be added
as developers or admins over time.  They may also need their quotas adjusted
over time as they deploy more apps or have higher usage.

Other than that, the users of this project template should be in operation after
this!
