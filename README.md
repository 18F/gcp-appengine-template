# GCP App Engine template
This repository contains a couple of example applications and
supporting configuration files for Google App Engine.  It is meant
to be used as a guide to quickly get a lightweight application running
safely and securely in GCP.

We hope to have procurement information and this process approved with a
P-ATO from GSA IT Security to make it so that it would be easy to get
up and running and get an ATO.

## Bootstrap Process

To get the app(s) in this repo going, you will need to:

1. Procure a https://circleci.com/ account.
1. Procure a GCP project and gain access to the GCP console.
1. Fork or copy this repo into your github org.  Make your changes to this
   new repo.
1. Consider your application load on the database and change the
   parameters in `terraform/google_sql.tf` to size your databases
   properly.  The default `db-f1-micro` db size is probably not sufficient
   for most production systems.
1. Create a Terraform service account via
   `Console -> IAM & admin -> Service Accounts` in GCP
1. Save the JSON credentials to `$HOME/gcloud-service-key.json`
   This file should either be stored securely by the administrators
   of the system, or deleted after circleci has been seeded with
   it's data.
1. Go to `Console -> IAM & admin` in GCP, click on `View by: Roles`,
   and then add `Project -> Owner` to the terraform service account.
1. You should be sure to set up master and staging branches as protected branches
   that require approval for PRs to land in this repo.
1. Enable circleci on this repo, then add some environment variables to it:
   * GCLOUD_SERVICE_KEY:  Set this to the contents of `$HOME/gcloud-service-key.json`
   * GOOGLE_PROJECT_ID: Set this to your google project ID
   * BASICAUTH_PASSWORD: Set this to a basic auth password to frontend your app with.
     If it is not set, then your app will be public.
   * BASICAUTH_USER: Set this to the basic auth username you want.
1. Watch as circleci deploys the infrastructure and apps!
   You may need to approve and wait until the terraform run is done, and then
   redeploy the apps the first time in case it takes longer to launch the databases
   than it takes to launch the apps.
1. You can now find all the apps if you go look at `Console -> App Engine -> Versions`.

## Customization For Your Application

The example applications are very simple, and while it is entirely possible for you
to extend them, it seems more likely that you'd want to create your own from scratch
and consult the examples for information on how to do things like use databases or
KMS or share secrets or whatever.

### General Thoughts

  * Google App Engine supports a few frameworks:
    https://cloud.google.com/appengine/docs/flexible/
    Be sure you use a supported version of the framework.
  * You will need to customize the `.circleci/config.yml` file to remove the
    example apps and add yours in.  If you are not using a framework that has
    an example app, you may have to write your own deployment pipeline from
    scratch.  Also, delete the `*-example` directories.
  * We are trying to keep the secrets mostly managed by terraform so that they
    are relatively easy to rotate and are not kept by operators.  These secrets
    and other config are passed into the applications via environment variables
    that are generated by the circleci pipeline and placed into the `app.yaml`
    file that is used to deploy the app.  The circleci pipeline uses
    the branch that it's building to find secrets and other environment-specific
    info in the terraform output.
  * Everything in the database storage and Cloud Storage buckets are all encrypted at
    rest.  You can also use KMS to encrypt things, so if your app requires
    encryption of data, make sure you read up on that:  https://cloud.google.com/kms/
  * The example apps all share the same usernames/passwords for the databases they access.
    This makes the config simpler, but if you happen to have multiple apps running in
    your environment, you probably will want to generate unique accounts for each so that
    they can't read each other's data.  You can do that in the `terraform/google_sql.tf`
    file.

### Domains/SSL

The procedure for mapping a custom domain onto your application can be found here:
https://cloud.google.com/appengine/docs/standard/python/mapping-custom-domains

This is so you can access your app through something like `https://myapp.gsa.gov/`
instead of `https://<projectappnamestring>.appspot.com/`.  Once this is enabled,
GCP should issue a proper SSL cert too.

### Authentication

You will probably need to keep basic auth in front of your application
until you get it mostly going and have your ATO.  These apps are all
public by default.  The example apps have basic auth enabled, so you can use
that as an example on how to do that.

For other identity providers, you will need to use OAuth2 or SAML in your app.
Here are some providers you might want to integrate with:
  * [login.gov](https://developers.login.gov/)
  * [GSA SecureAuth](https://secureauth.gsa.gov/)
  * [cloud.gov UAA](https://cloud.gov/docs/apps/leveraging-authentication/),
    although this probably is not useful unless you have a cloud.gov
    account, it has some good documentation on the subject.

Another option is putting an [OAuth2 proxy](https://github.com/18F/oauth2_proxy)
in front of your application.  We currently have no examples on how to do this,
but the documentation on how to get registered with a number of identity providers
may be useful.

## ATO and launching considerations

XXX

## Common Workflows

### Normal Development Workflow

The normal way that development for an app happens is:
  * You develop locally, pushing changes up to your own feature/fix branch in github.
  * Once you have something that is tested and worthy of going out, you can Pull Request
    (PR) it into the dev branch, where it will be automatically deployed to the dev
    version of the app in gcp and have it's tests run against it.
  * When you have your changes in a releasable form, your changes should be PR'ed
    into the staging branch, where they will be approved by another person, and then
    they will automatically be rolled out into the staging version of the app in GCP.
  * After staging has been validated through UAT or other automated testing, your 
    changes should be PR'ed into the master branch and approved by somebody else,
    where they will be automatically rolled out into production.
  * **NOTE:**  The example apps will run db migrations before doing the promotion to 
    production, so make sure that your old version of the app is forward-compatible
    one release, or you might cause problems with the old version of the app
    accessing/adding data using the old code/schema/etc.  This is something that
    you could change in the circleci pipelines or your app code.

### Manual Deploy Workflow

XXX

### Logging/Debugging

Logs can be watched either by using the GCP Console (`XXX`), or by getting the google
cloud SDK going and saying `gcloud app logs tail` to get all logs from all versions
of the apps.

Some frameworks can be debugged in the GCP console without changes.  Others
may require some special libraries.  Consult https://cloud.google.com/debugger/docs/
for more information.

### Infrastructure Update Workflow

Infrastructure updates are driven by circleci and implemented by terraform.
Your infrastructure should probably not be changing very often, but when you
do, you should follow this procedure:
  * go to `Workflows -> gcp-appengine-template -> dev` and look for a
    `dev/terraform` workflow that is "On Hold".
  * Click on that workflow and click on the plan_terraform step.
  * Carefully examine the plan and make sure it's not going to do anything
    dangerous!  Important things to look for are resources like databases
    being recreated because a name changed or something.  If you see something
    like this, make sure that you are ABSOLUTELY SURE that this is what you want
    to happen.  Losing data is hard.
  * Once you are confident that it is changing what you want, approve the
    rollout by clicking on the `hold_terraform`.
  * You can watch the rollout by looking at the `apply_terraform` step once
    it gets going.

 **Be aware!  Infrastructure updates are common to _all_ environments.  If
 you make a change to terraform, that change could impact production.  There
 is just one infrastructure into which dev/staging/prod is deployed.**

If you would like to test out a new, potentially dangerous infrastructure
change, you could:
  * Create a new repo from the existing one, preferably by forking it.
  * Procure a new GCP project and bootstrap it using the new repo.
    If production is using large instance sizes or other expensive
    options, you might want to make them smaller before you do this.
  * Make sure that everything works, load example data, etc.
  * Make your changes to the new repo and test rolling them out.
  * When done, you should delete everything to save $$.  **Be sure that
    you delete everything in the _new_ GCP project, not the real
    production one.**

### Secrets Rotation Workflow

The main secret in the system is the gcloud-service-key.json file.  This key can be
used to create/delete infrastructure, access the terraform secrets, etc.  It can be
rotated by:
  * Go to `Console -> IAM & admin -> Service Accounts` in GCP.
  * Click on the terraform service account.
  * Make a note of the old key ID that is active.  There should only be one.
  * Click on `Edit` at the top
  * Click on `+ CREATE KEY`
  * Select JSON format and create the key.  It should download a json file.
  * Update the GCLOUD_SERVICE_KEY variable in circleci to be the contents of
    that json file.
  * Try doing a dev or staging deploy to make sure the new key works.
  * Once verified, delete the old key ID noted above, as well as the json file.

The Basic Auth credential can be rotated simply by choosing a new username/password
and updating the BASICAUTH_USER and BASICAUTH_PASSWORD environment variables in
circleci and doing a deploy.

Application secrets (such as the rails secret) can be updated like so:
  * Change the terraform `random_string` length (making it larger is never bad) for
    the secret(s) you wish rotated.
  * Do an infrastructure update.  Examine the plan carefully to make sure it's
    not deleting and recreating some important bit of infrastructure (like 
    databases) because of this change.
  * Do a deploy of the app(s).
  * **Be aware! Some things may break until the deploy of the app(s) are done
    because you updated the secret, but the apps are still running with
    the old secret.  Database passwords, in particular, will be a problem.**
    This is a good thing to do during a maintenance window.

## Technologies used

### Google App Engine
App Engine is a simple way to deploy applications that will automatically scale
up and down according to load.  https://cloud.google.com/appengine/

### Terraform
Terraform orchestrates the project setup, creating databases, storage,
secrets, etc.  https://www.terraform.io/

### Circle CI
Terraform and the Google Cloud SDK are invoked on commit by Circle CI, which
enables required APIs, creates a Terraform plan, and waits for operator approval
prior to changing production.  https://circleci.com/

## Example Applications

### Rails / App Engine
This is a simple app that uses ActiveRecord to store a "blog" in a db.

To test locally, have ruby/bundler installed and 
run `cd rails-example && bundle install && bin/rails server`.

### .NET Core / App Engine
This is a simple app that creates a list of URLs for "blogs" in a database.  
This may change, but for now, you must use the netcoreapp2.1
framework for applications deployed into App Engine.  It uses KMS to store
antiforgery keys, and has basic auth enabled.

To test locally, `cd dotnet-example && dotnet run`.
This will operate on a local `blogging.db` sqlite db.

### Java Spring Boot / App Engine
XXX
