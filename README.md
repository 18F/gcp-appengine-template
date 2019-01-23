GCP App Engine template
=======================
This repository contains a sample application and supporting configuration files
for Google App Engine to be tested and evaluated.

Terraform
=========
Terraform orchestrates the project setup, creating databases, storage,
secrets, etc.

Circle CI
=========
Terraform and the Google Cloud SDK are invoked on commit by Circle CI, which
enables required APIs, creates a Terraform plan, and waits for operator approval
prior to changing production.

Rails / App Engine
=============================
This is a simple app that uses ActiveRecord to store a "blog" in a db.

To test locally, run `cd rails-example && bundle install && bin/rails server`.

.NET Core / App Engine
======================
This is a simple app that creates a list of URLs for "blogs" in a database.  
This may change, but for now, you must use the netcoreapp2.1
framework for applications deployed into App Engine.

To test locally, `cd dotnet-example && dotnet run`.
This will operate on a local `blogging.db` sqlite db.

Java Spring Boot / App Engine
=============================
XXX

Bootstrap Process
=================

1. Create a Terraform service account via
   `Console -> IAM & admin -> Service Accounts` in GCP
1. Save the JSON credentials to `$HOME/gcloud-service-key.json`
1. Go to `Console -> IAM & admin` in GCP, click on `View by: Roles`,
   and then add `Project -> Owner` to the terraform service account.
1. Enable circleci on this repo, then add some environment variables in circleci:
   * GCLOUD_SERVICE_KEY:  Set this to the contents of `$HOME/gcloud-service-key.json`
   * GOOGLE_PROJECT_ID: Set this to your google project ID
   * BASICAUTH_PASSWORD: Set this to a basic auth password to frontend your app with.
     If it is not set, then your app will be public.
   * BASICAUTH_USER: Set this to the basic auth username you want.


You should be sure to set up master and staging branches as protected branches
that require approval for PRs to land in your repo.

Normal Operation Workflows
==========================

The normal way that development for an app happens is:
  * You develop locally, pushing changes up to your own feature/fix branch in github.
  * Once you have something that is tested and worthy of going out, you can Pull Request
    (PR) it into the dev branch, where it will be automatically deployed to the dev
    version of the app in gcp and have it's tests run against it.
  * When you have your changes in a releasable form, your changes should be PR'ed
    into the staging branch, where they will be approved by another person, and then
    they will automatically be rolled out into the staging version of the app in GCP.
  * After staging has been validated, your changes should be PR'ed into the
    master branch and approved by somebody else, where they will be automatically
    rolled out into production.

Things to note:
  * The deploy will run db migrations before doing the promotion to production, so
    make sure that your old version of the app is forward-compatible one release, or
    you might cause problems with the old version of the app accessing/adding data
    using the old code/schema/etc.
  * Infrastructure updates that get rolled out by terraform currently only are applied
    when they are manually approved in circleci.  Before
    doing such an approval, you should check the terraform plan output to see what is
    changed, in case your change actually does something that you did not expect, like
    delete resources instead of rename them.  Be careful!  This applies to _all_
    infrastructure, production/staging/dev/etc.
  * These example apps all use the same username/password for each of the dev/staging/prod
  	databases.  In real life, you'd create separate username/passwords for each database
  	that you create, so that the apps in prod can't query each others' databases.
