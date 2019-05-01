# GCP Provisioning Notes

For GSA ICE folks who are provisioning the GCP Projects for this system,
the overall architecture is:
![diagram of gcp org, project, apps, and services](https://github.com/18F/gcp-appengine-template/raw/master/gcp_diagram.png)

## GCP Project Provisioning

You will need to create three different GCP projects:
* dev
* staging
* prod

It is recommended that you name them something with "dev/staging/prod" in the
names, to help the users know which project they are operating on, but
it is not a requirement.


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

### Non-windows Platform Usage

To use the `ice_enable_everything.sh` script on a Linux or OS X system, you will need to:
1. Install the [Google Cloud SDK](https://cloud.google.com/sdk/) on your system.
1. `gcloud auth login` to authenticate with GCP
1. `git clone https://github.com/18F/gcp-appengine-template` to clone the repo with the script in it.
1. `cd gcp-appengine-template/gcp_setup` to get into the proper directory
1. Create or copy in a config file for the script.  An example config file can be found in
   `gcp-appengine-template/gcp_setup/ice_enable_everything.cfg.example`.  You will need to
   change all `XXX` instances into something real.
1. `./ice_enable_everything.sh yourconfigfile.cfg` to run the script.  You may have to say `Y`
   a couple of times.
1. For bootstrapping, you will need to add the `roles/owner` role to the terraform service account
   temporarily.  Once the environment has been bootstrapped with terraform, you can remove this
   role from the terraform service account.  Coordinate with the Project Owner on this.


### Windows Platform Usage

Windows machines cannot run the shell scripts, but you should be able to install
[Docker Desktop](https://www.docker.com/products/docker-desktop), which can run
a Linux container on your local system which you can use to do all this.

1. [Install Docker Desktop](https://docs.docker.com/docker-for-windows/install/).  
   You may need to reboot your machine as a part of this.
1. Pull up powershell or whatever command shell you use, and type 
   `docker pull google/cloud-sdk`.
   This should pull down the google cloud SDK images for you to use.
1. `docker run -it google/cloud-sdk`  This should launch the cloud-sdk
   container and give you a shell prompt.
1. `