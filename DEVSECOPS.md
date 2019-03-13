# DevSecOps Architecture

The architecture of this project lends itself directly to fulfilling the principles found
in https://tech.gsa.gov/guides/dev_sec_ops_guide/.  The overall idea behind this project is
to create a template that people can clone, add their application to, provision some GCP
Projects, and then enable CircleCI
to automatically provision dev/staging/production environments into those GCP Projects
with good secrets management, backups, tests, and other controls that make their project 
automatically use best DevSecOps practices, making it easy for people to get an ATO.

## Platform

The platform that people will be deploying to is Google Cloud Platform (GCP).  This project does not 
directly address how GCP is provisioned and set up, but from discussions with the people within GSA 
ICE who are developing the process, the rough plan is to have a GSA GCP organization account run by
the ICE folks who will, upon receiving an approved request from a Project Owner, set up GCP Project(s)
for the Project Owner with a minimal set of permissions and services provisioned in it.

GCP Projects are fully compartmentalized subdivisions within a GCP organization that are meant to
be used for individual application environments like dev/test/prod.  Access to one GCP Project
does not give you access to any other Project.  Billing is managed on a per-Project basis as well.

### Controls

* The creation of GCP Projects is controlled by GSA ICE.
* Users and service accounts in the GCP Project and their permissions are managed by GSA ICE as well.
* Users are required to use 2fa to get into the GCP Console and use GCP resources.  The current second
  factor that must be used is a U2F/FIDO key.
* Billing is configured by GSA ICE.  

### Logging/Auditing/Visibility

* We believe that GSA ICE will be implementing some level of audit logging and alerting for
  users and permissions changes across the organization, but do not know specifics.
* This project attempts to turn on our own audit logs within the project so that we can listen and alert on
  unusual activity.
* GCP allows billing alerts to be configured, but we do not know if GSA ICE will
  be taking advantage of that.  
* There is a billing dashboard that can be accessed
  by Project Owners as well as GSA ICE.

## Project

The GCP Project is where the Project Owner will build and deploy their infrastructure and application.
The Project Owner will usually request three GCP Projects: dev, staging, production, though they may request
more if they have special deployment pipeline needs.  A terraform service account will be created, and each
GCP Project will then have it's infrastructure configured and deployed with terraform using the 
CircleCI CI/CD system.  Applications will be configured and deployed as well, using gcloud tools within
CircleCI.  CircleCI will watch a set of branches (usually dev/staging/master) and deploy the code in that
branch into the appropriate GCP Project whenever there are changes.

Currently, our project uses Google App Engine to deploy apps which use Google Cloud SQL and KMS.  It also
stores the terraform state in an encrypted Cloud Storage bucket.

### Controls

* Separate GCP Projects can allow for fine-grained access controls so that dev/staging/prod can have
  appropriate sets of users and full to readonly access granted to them.
* Separate GCP Projects provide logical/physical resource separation so that opportunities to lateral 
  from a dev environment into prod are not available.
* The dev/staging/production environments are generally identical except for the data in their
  databases, and perhaps some additional access granted for debugging in the dev environment.
* All changes to the environment and apps are done through a defined gitops-style process with 
  code and automation, so the management of the infrastructure should not require most people to
  have more than readonly access to anything once the infrastructure is bootstrapped.
* All changes to the code can be required to have approvals on them with GitHub Protected Branches, so no
  unilateral unauthorized changes can happen, and all changes that are approved can be reviewed later on
  in case there is a problem.
  GitHub Verified checkins could be made required too for additional levels of assurance.  We would expect most
  projects to allow anybody on the project to push into the dev branch, but require approvals on pull requests
  into the staging and master branches.
* As previously mentioned, audit logs are enabled, so we should be able to see infrastructure changes in the
  GCP Log Viewer.
* All applications are configured through environment variables, so secrets and other config are generally
  ephemeral.  The only place where secrets hit the disk is in the encrypted Cloud Storage bucket where terraform
  stores it's state.
* Terraform generates all secrets used in the system, so there is generally no opportunity for people to
  store this data insecurely, and this also makes it easy to rotate secrets.
* Because the infrastructure is all code, Disaster Recovery into another region should be simple,
  only requiring a change to the terraform to change the region and a restore of a database
  backup from the old region.

### Logging/Auditing/Visibility

* CircleCI can provide logs of what the automation is doing if you are a part of the project.
* GCP Log Viewer provides logs from the other side of what CircleCI is doing with deploys and 
  infrastructure changes, though perhaps without the context that CircleCI access might give you.
* Google Stackdriver provides customizable alerts so that IAM changes or changes to infrastructure
  by something other than the terraform system account can raise alarms.
* GCP has a security console that does anomaly and vulnerability detection, scanning, alerting,
  and other interesting services which should provide good visibility into the security posture of
  the project.

## App

The applications in this project are extremely simple, meant to be examples for people to look at how they
are deployed and perhaps how they have been configured to do basic/OIDC authentication.
They are not in any way useful except as an example.
These apps are deployed whenever changes to particular branches
in github change by the CircleCI CI/CD system.  Whenever such a workflow is triggered, CircleCI will
configure and deploy the app using the gcloud tool, run tests to verify that the app is functional,
run a OWASP ZAP scan against the app to ensure that there are not obvious security vulnerabilities,
and then bring load up on the app.

One app has been configured to run with an oauth2_proxy in front of it that is configured to authenticate
users from gsa.gov using login.gov.  The workflow here adds a deploy/test of the oauth2_proxy after the app
is up, but is otherwise the same.  This seems like it could be useful for people who do not want to implement
OIDC in their app, but it does require you to be smarter about restricting access on the backend too.  In
this example, we check whether there is an authorized header present from the proxy, and if not we reject
the connection.

General features that apps deployed into this environment should have are:
  * Secrets should be generated by terraform, so that they are assured to be of a good strength/quality,
    as well as easily rotated.
  * Apps should be configured entirely through environment variables.  This means that secrets and other
    config data should be ephemeral and not hit the disk.
  * Authentication should be in front of most applications.  This is a requirement pre-ATO, and probably
    will be important to almost every other application that stores data.
  * Apps should be able to allow the OWASP ZAP scanner in so that it can do a full scan.
  * Apps should either use GCP logging-enabled libraries, or log to stdout/stderr.
  * Apps should implement health checks that are comprehensive.
  * Apps should have comprehensive tests written for them that can be executed during the
    CircleCI deployment pipeline.
  * All data that the apps store should be stored in a database or other storage service.  Local
    files are ephemeral at best, and may not be allowed to happen in some app deployment situations.

### Controls

* All apps/services deployed in Google App Engine are given an SSL cert in the appspot.com domain by default.
  There are provisions for getting a cert for a custom domain as well, which most people will want to
  do for production.
* App Engine instances are ephemeral.  They are restarted weekly by Google.
* App Engine instances are automatically updated/patched/restarted with zero downtime on a weekly basis.
* Logs are collected from stdout/stderr and stored in the Google Stackdriver Log Viewer automatically,
  where they are stored read-only.
* App Engine automatically scales up and down the number of instances according to load.
* Read-only log viewing access can be granted to anybody in the project, so temporary access could be
  granted to a developer or security engineer and then taken away.  We would presume that log access
  would probably be granted at the organization level already, but don't know for sure.
* Health checks are standard for every deployment.  If healthchecks fail, traffic will be routed to other
  healthy instances, and eventually will relaunch the instance.
* Changes to the apps are made through a defined gitops-style process.
* Apps are not fully rolled out unless they pass a suite of tests that are defined by the developer.
* App Engine instances are not generally available for logging into and changing.  It is possible
  to do this for debugging, but this is not a supported workflow, and the changes end up being
  ephemeral, since the instances are relaunched every time there is a deploy or the google-managed
  weekly update.
* The production databases have daily backups automatically scheduled for them, and also are
  configured for HA and failover.

### Logging/Auditing/Visibility

* All logs generated by the apps/services will be pulled into the Google Stackdriver Logs Viewer.
* App events can be alerted on with Google Stackdriver.
* Performance data for app instances can be viewed in the GCP Console.

# Known Issues

There are a few known issues with the project:
  * The GSA ICE team plans on issuing GCP Projects such that the Project Owner only has Editor level
    access.  This means that they will be unable to do things like activate stackdriver alerting, create
    service accounts, access the Security Command Center, etc.  This means that most projects will
    be unable to deploy without having to get them to run commands on the Project Owner's behalf.
    Seems like it would be better to set up good auditing/logging of access control events and let
    the Project Owner set up the environment and manage their users.  Or at least to let them bootstrap
    the environment and get everything set up, and then lower their access once things are going.
  * We need the project owner IAM role added to our user accounts so that we can explore how to
    activate/configure/use Stackdriver alerts and the Security Command Center.
  * Networking is not very customizable in App Engine:
    * Limiting outbound access seems pretty close to impossible with App Engine.  The firewall that
      App Engine does only operates on inbound traffic.  I have hopes that we can set up some sort of
      anomaly detection thing that kills apps if they query outside of the project, but the best
      thing to do would be to ask the GCP people what they expect people to do.
    * Limiting access from the outside world to services protected by the oauth2_proxy seems to be
      hard.  Inbound filtering seems to not be selective enough to apply to a service.
      So app implementers need to check for a properly signed GAP-Authentication header.  This seems
      like an easy thing to forget to do, or do improperly, so it would be good to talk with GCP
      to try to understand if they have better networking controls coming.
  * We really don't have any good guidance on how GSA IT Security would like us to make an SSP
    or get a P-ATO for
    this project.  There seem to be some interesting oscal/opencontrol things that would fill
    this need, but it's feeling a bit unformed right now.
  * We need to look at how long logs in Stackdriver are retained.  We may
    need to set up a storage bucket for log archival and automate that process.
  * We only just got dev/staging/prod environments provisioned for us, so we have not yet
    implemented the full separated environments yet.  Right now, all environments get deployed
    to our "pilot" GCP project.  This should be fixed soon, but it means that some of the
    controls we talk of here are not quite going yet.

