# Common Workflows

## Normal Development Workflow

Normal development is driven by what is in github, so most engineers
would only need access to that, which helps separate duties and reduce the
attack surface for compromised accounts.  It also provides a good audit trail
for all changes, and with protected branches and good tests, makes sure that changes
have oversight and will work.

  * You develop locally, pushing changes up to your own feature/fix branch in github
    and building/running tests locally.  If you are developing code to address
    compliance needs, be sure to update the [compliance documentation](#Compliance-Masonry).
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

## Logging/Debugging

Logs can be watched either by using the [GCP Console](https://console.cloud.google.com/logs/),
or by getting the google cloud SDK going and saying `gcloud app logs tail`
to get all logs from all versions of the apps.

Some frameworks can be debugged in the GCP console without changes.  Others
may require some special libraries.  Consult https://cloud.google.com/debugger/docs/
for more information.

## Infrastructure Update Workflow

Infrastructure updates are driven by circleci and implemented by terraform.
Your infrastructure should probably not be changing very often, but when you
do, you should follow this procedure:
  * Update the terraform code to do what you want it to do.  If you are 
    developing code to address compliance needs, be sure to update the
    [compliance documentation](#Compliance-Masonry).
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

Once you are sure that everything is happy, you can then create a Pull
Request to roll your changes into the staging branch, seek approval, and
then PR your code into the master branch to have it go into production.

## Secrets Rotation Workflow

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
