# GCP App Engine template
This repository contains a couple of example applications and
supporting infrastructure and configuration files for Google App Engine.
It is meant to be used by people in the GSA (and other agencies)
as a guide to quickly get a lightweight application running
safely and securely in GCP.

We hope to have procurement information and this process approved with a
P-ATO from GSA IT Security to make it so that it would be easy to get
up and running and get an ATO.

## Bootstrap Process

To get the app(s) in this repo going, you will need to:

1. Procure a [CircleCI](https://circleci.com/) account.
1. Fork or copy this repo into your github org.  Make your changes to this
   new repo.
1. Consider your application load on the database and change the
   parameters in `terraform/google_sql.tf` to size your databases
   properly.  The default `db-f1-micro` db size is probably not sufficient
   for most production systems.
1. Procure three GCP projects and gain access to the [GCP console](https://console.cloud.google.com/)
   on them all.  For each project, do the following:
  1. Create a Terraform service account via
     `Console -> IAM & admin -> Service Accounts` in GCP
  1. Save the JSON credentials to `$HOME/master-gcloud-service-key.json` for
     your production GCP Project, `$HOME/staging-gcloud-service-key.json` for
     your staging GCP Project, or `$HOME/dev-gcloud-service-key.json` for
     your dev GCP Project.

     These files should either be stored securely by the administrators
     of the system, or (even better) deleted after circleci has been seeded with
     it's data.
  1. Go to `Console -> IAM & admin` in GCP, click on `View by: Roles`,
     and then add `Project -> Owner` to the terraform service account.
1. You should be sure to set up master and staging branches as protected branches
   that require approval for PRs to land in this repo.  You should also enable
   as many code analysis integrations as are appropriate within the repo to
   enforce code quality and find vulnerabilities.
1. Enable circleci on this repo, then add some environment variables to it:
   * `GCLOUD_SERVICE_KEY_master`:  Set this to the contents of `$HOME/master-gcloud-service-key.json`
   * `GCLOUD_SERVICE_KEY_staging`:  Set this to the contents of `$HOME/staging-gcloud-service-key.json`
   * `GCLOUD_SERVICE_KEY_dev`:  Set this to the contents of `$HOME/dev-gcloud-service-key.json`
   * `GOOGLE_PROJECT_ID_master`: Set this to your production google project ID
   * `GOOGLE_PROJECT_ID_staging`: Set this to your staging google project ID
   * `GOOGLE_PROJECT_ID_dev`: Set this to your dev google project ID
   * `BASICAUTH_PASSWORD`: Set this to a basic auth password to frontend non-SSO apps with.
     If it is not set, then your non-SSO app will be public.
   * `BASICAUTH_USER`: Set this to the basic auth username you want.
1. Watch as circleci deploys the infrastructure.  The apps will all fail
   because it takes much longer for the databases to be created than the apps,
   and because you will need to get some info from terraform to make the
   oauth2_proxy work.
1. Go to the failed app deploy workflows in circleci and click on `Rerun`.
   Everything should fully deploy this time, though the rails app SSO proxy jobs
   will fail unless you completed the SSO proxy steps too.  This is fine.
1. You can now find all the apps if you go look at `Console -> App Engine -> Versions` and
   then click on the `Service` popup to find the app you'd like to get to
   (rails and dotnet-example, currently).  You will need to authenticate with
   the basic auth credentials you set above.

### Enabling the SSO proxy in front of the rails example

1. Sign up as a developer for [login.gov](https://developers.login.gov/) and
   create dev, staging, and production apps in the login.gov dashboard using their 
   directions and the following guidance:
   1. Look at the output from the `apply_terraform` job in circleci to get the Public Keys.
      Look for the `sso_cert_XXX` outputs.  If you have the gcloud utility working and
      have `jq` installed, you can use this command to get the dev cert, for example:  
      `gsutil cp gs://gcp-terraform-state-$GOOGLE_PROJECT_ID/tf-output.json - | jq -r .sso_cert_dev.value`.
      Change `dev` to `staging` and `production`, and you will have all the certs.
   1. Make the `Return to App URL` be something like `https://dev-dot-${GOOGLE_PROJECT_ID}.appspot.com/oauth2/sign_in`
      for dev, and change dev to `staging` and `production` for those apps too.
   1. Make the `Redirect URIs` be something like `https://dev-dot-${GOOGLE_PROJECT_ID}.appspot.com/oauth2/callback`
      for dev, and change dev to `staging` and `production` for those apps too.
1. Add these environment variables to the circleci repo:
   * `IDP_PROVIDER_URL`: Set this to your IDP provider URL 
     (like https://idp.int.identitysandbox.gov/openid_connect/authorize)
   * `IDP_PUBKEY_URL`: Set this to the URL where you can get the public key that
     can be used to verify your IDP. (like https://idp.int.identitysandbox.gov/api/openid_connect/certs)
   * `IDP_CLIENT_ID_DEV`: Set this to the client ID you registered with your IDP for dev.
     (like `urn:gov:gsa:openidconnect:development`)
   * `IDP_CLIENT_ID_STAGING`: Set this to the client ID you registered with your IDP for staging.
     (like `urn:gov:gsa:openidconnect:staging`)
   * `IDP_CLIENT_ID_PRODUCTION`: Set this to the client ID you registered with your IDP for production.
     (like `urn:gov:gsa:openidconnect:production`)
   * `IDP_EMAIL_DOMAIN`: Set this to either the email domain that you would
   	 like your access restricted to (like `gsa.gov`), or `*`, if you would
   	 not like to restrict who can get in.
   * `IDP_PROFILE_URL`:  Set this to your IDP provider profile URL
     (like https://idp.int.identitysandbox.gov/api/openid_connect/userinfo).
1. You should then be able to go to circleci and click `Rerun` on a `deploy-rails-example`
   workflow, and everything should then deploy fully.  You will then be able to go to
   the frontend URL (something like https://dev-dot-${GOOGLE_PROJECT_ID}.appspot.com/) and experience the SSO login.

### Enabling offsite logging

GSA SecOps has a log sink that gives them visibility into your
systems and lets them generate alerts when unusual activity happens.  Here is
how you turn that on:
1. Get onboarded by GSA SecOps by following the process in the
   [GSA Logging and Audit Compliance Guidance](https://docs.google.com/document/d/1MkaYZr6633vobLkYpNZcqPfQTvCUgR4XNahcmeryXgg/edit)
   document.  As of now, they have a
   [Google Form](https://docs.google.com/a/gsa.gov/forms/d/e/1FAIpQLSdm4kODpvMXbJ5xqxImAIJTtIP6uuVqSzzULuwREq_02ZEP3Q/viewform)
   which you need to fill out.
1. After onboarding, you should have received an S3 bucket and some credentials
   that will allow you to write to that bucket.
1. Add these environment variables to the circleci repo:
   * `LOGTO`: Set this to the S3 bucket that GSA SecOps gives you.
     (like `s3://gsa-logbucket`)  Make sure there is no `/` at the end.
   * `LOGTO_AWS_ACCESS_KEY_ID`: Set this to the Access Key ID that GSA SecOps
     gives you. (like `AKIAXXXXXXXXXX`)
   * `LOGTO_AWS_SECRET_ACCESS_KEY`: Set this to the Secret Access Key ID that
     GSA SecOps gives you.
     (like `asdfasdfasdf+klwjelkjewlkjrweklrj`)
1. Rerun the `deploy-log-sync` workflow for the environments you have set up.
1. Check the logs for the logsync service.  You should see a line like
   `2019-04-08 12:39:34.000 PDT
2019/04/08 19:39:34 synced logs from gs://logs-bucket-${GOOGLE_PROJECT_ID} to s3://gsa-logbucket/dev`
   if things are going well.  Otherwise, you should see error messages that
   you can use to diagnose the problem.


## Customization For Your Application

The example applications are very simple, and while it is entirely possible for you
to extend them, it seems more likely that you'd want to create your own from scratch
and consult the examples for information on how to do things like use databases or
KMS or share secrets or whatever.

### General Thoughts

  * Google App Engine supports a 
    [few frameworks](https://cloud.google.com/appengine/docs/flexible/).
    Be sure you use a supported version of the framework.
  * You will need to customize the `.circleci/config.yml` file to remove the
    example apps and add yours in.  **This is the core of automation in this project.**
    If you are not using a framework that has
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
    rest.  You can also use KMS to encrypt things, so if your app requires more
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

You will probably need to keep authentication in front of your application
until you have your ATO.  The .NET core example app has
basic auth enabled, and the rails example app has an OAuth2 proxy in front of it.
Another option is to implement OAuth2 support directly in your application, though
we do not have an example of that here.

Here are some identity providers you might want to integrate with:
  * [login.gov](https://login.gov/), which has excellent
    [developer documentation](https://developers.login.gov/).
  * [GSA SecureAuth](https://secureauth.gsa.gov/), which seems to have
    no public documentation, but according to the IT Servicedesk, you can
    submit a Single Sign-On Integration Request:
    ```
    1. Go to servicedesk.gsa.gov
	2. Click on "Order Something"
	3. Click on the following options respectively: General Requests > Single Sign-On Integration Request
	(Please refer to the Lightweight Security Authorization Process Form for information on FIPS 199.)

	*All fields marked with a red asterisk must be populated*

	**Your supervisor will receive an email after the request is submitted. That email will give them the option to either approve or deny the request. Failure to approve/deny the request will result in the ticket being cancelled**
    ```
  * [cloud.gov UAA](https://cloud.gov/docs/apps/leveraging-authentication/),
    although this probably is not useful unless you have a cloud.gov
    account, it has some good documentation on the subject.

One thing that you should be aware of if you are using the OAuth2 proxy is
that the application launched behind the proxy needs to ensure that traffic
not originating from the proxy is rejected.  This can be done by checking
the HMAC in the `GAP-Signature` header using the key found in the `SIGNATURE_KEY`
environment variable in the application, and if it does not verify, reject
the request.  This is usually simpler to do than implementing the full OAuth2
control flow.  An example of this can be found in the rails-example 
[application_controller.rb](https://github.com/18F/gcp-appengine-template/blob/master/rails-example/app/controllers/application_controller.rb).
More info on how the proxy is configured to do this, and HMAC in general can be found here:
https://github.com/pusher/oauth2_proxy#request-signatures

### Automated scanning

Circleci will automatically scan the applications upon deploy with 
[OWASP ZAP](https://www.owasp.org/index.php/OWASP_Zed_Attack_Proxy_Project).  One thing to note
is that if your app uses authentication (basic auth or SSO proxy, etc), then you
will need to probably add an authentication header to your app that allows ZAP to
securely scan without doing a login.  You can see how to do this in the `owaspzap-rails` job
in the circleci [config.yml](https://github.com/18F/gcp-appengine-template/blob/master/.circleci/config.yml),
and how you might check this header in the rails-example 
[application_controller.rb](https://github.com/18F/gcp-appengine-template/blob/master/rails-example/app/controllers/application_controller.rb)

You should also probably scan while doing local development, since that is faster to do
than waiting for a deploy.  You can do this by:
  * `docker pull owasp/zap2docker-weekly` to get the OWASP ZAP scanner ready for you to use.
  * Start up your app for local development.  In the case of the rails-example, that would be
    `rails server`.
  * Figure out your computer's local IP address.  While you might access the app over
    http://localhost:3000/, docker cannot, because it has it's own localhost IP.
    For example, your system might have been issued `10.0.1.50` as your local IP on
    your network.
  * `docker run -t owasp/zap2docker-weekly zap-full-scan.py -t http://YOURIPHERE:3000/`, where
    `YOURIPHERE` is your IP address as we discovered in your last step.
  * The scanner should run and issue a report that you can use to understand what sort of
    things might have security problems that require fixing.
  * Be aware that the scanner will try submitting forms many times, so if you have a form
    that sends email or adds entries to a blog or something, that form will be triggered by
    the scanner.  You may need to adjust the scanner to skip certain urls.
    https://github.com/zaproxy/zaproxy/wiki/FAQpreventSpam

More information on how to configure and use the OWASP ZAP scanner in this way
can be found on their wiki:  https://github.com/zaproxy/zaproxy/wiki/ZAP-Full-Scan  

You can also use the proxy on your computer in GUI mode, which is much more like a traditional
app, and thus less tricky to customize than the docker version, which is better for automated 
scans.  More info on that can be found in the 
"Getting Started Guide" on https://github.com/zaproxy/zaproxy/wiki/Downloads.

### Offsite Logging
Logs are collected by [GCP Stackdriver](https://console.cloud.google.com/logs/viewer).
They are exported to a [GCP Cloud Storage](https://console.cloud.google.com/storage/browser)
bucket, which is then periodically synced with an s3 bucket maintained by the GSA
IT Security people, where it is slurped into their logging system.

If you want to customize what logs get exported, then you will want to edit the 
`"google_logging_project_sink" "securitystuff"` resource
in `terraform/google_storage.tf`.  Right now, it just sends the logs that the 
[GSA Logging and Audit Compliance Guidance document](https://docs.google.com/document/d/1MkaYZr6633vobLkYpNZcqPfQTvCUgR4XNahcmeryXgg/edit)
requires.


## ATO and compliance considerations

Every federal information system must be granted an Authority To Operate (ATO)
by an Authorizing Official in order to go into production.  A good overview of
the process can be found in this [excellent ATO overview](https://docs.google.com/presentation/d/1x-Bt8uyW-szHarglY57fFcC6PRCpUGFLe07uOvt93uk/edit#slide=id.g1f710bd7ce_0_847)
and a more in-depth look can be found in [18F's before-you-ship docs](https://before-you-ship.18f.gov/ato/).  There
are currently a few options for getting an ATO:
* A [FedRAMP Tailored](https://tailored.fedramp.gov/) package.
* A full [FedRAMP JAB ATO](https://www.fedramp.gov/jab-authorization/).
* A GSA LATO (Lightweight ATO), which can be found by searching for "Lightweight
  Security Authorization Guide" on 
  [this page](https://insite.gsa.gov/topics/information-technology/security-and-privacy/it-security/it-security-procedural-guides)
* Other agencies may have their own ATO process.

What ATO you get depends on what your project needs.  If you are doing this in
the GSA, you will probably want to follow the GSA LATO process, and most of the
compliance data that we have collected here is aimed at fulfilling that process.
That said, all of these ATO processes all map back to the NIST 800-53 controls,
so if you decide on a different ATO package, you ought to be able to use the
GSA LATO compliance data to help speed your ATO journey along.

### Compliance Masonry

We are using [Compliance Masonry](https://github.com/opencontrol/compliance-masonry) to
document all of the controls and how the different components satisfy them.  Every
component has a `compliance` directory which contains the documentation for that
component.  For example, the `rails-example` app has a
`gcp-appengine-template/rails-example/compliance/component.yaml`
file, and the whole project has a `gcp-appengine-template/compliance` directory
where everything is tied together with an `opencontrol.yaml` file, which
documents all of the components, the certifications (GSA LATO), and the
standards (NIST-800-63) that we use.  Components that do not have opencontrol
documentation are also documented in `gcp-appengine-template/compliance/components`.

The idea is that as you create code, you will also be creating and updating the
compliance documentation at the same time.  You can run the `compliance-masonry diff LATO`
tool while in the `gcp-appengine-template/compliance` directory to understand
what you still need to implement, find controls that are incomplete with
`compliance-masonry info -i partial`, etc.  Consult the 
[compliance-masonry usage docs](https://github.com/opencontrol/compliance-masonry/blob/master/docs/usage.md)
for more info.  

You can also use git tools to see what has changed between releases or
over time to see if changes are worthy of a Significant Change Request or
whatever.  For instance: `git checkout master ; git diff staging $(find . -name compliance -type d)`

Down the road, we would like to think that tools like this will evolve into
a Behaviour Driven Compliance Test suite that can actually test the implementation
of the controls described and let you know where you have gaps, but this is what
we have right now.

### Compliance Documentation

Every ATO package has a different set of documentation that it requires.  This
documentation changes over time, adding/removing controls or getting simpler or
more complex.  Most of the templates are in formats that we cannot emit or
edit in any reasonable way, so we have chosen to instead collect all the compliance
documentation you created with your code in a 
[GitBook](https://github.com/opencontrol/compliance-masonry/blob/master/docs/gitbook.md)
or a [PDF](https://github.com/opencontrol/compliance-masonry/blob/master/docs/gitbook.md#export-as-a-pdf)
that you can consult while filling out your ATO package.

### GSA LATO Process

The process that we are documenting here is aimed at getting a 
"One year Limited ATO" or "Three-year Full ATO", depending on whether your
system is classified as FIPS 199 Moderate or FIPS 199 Low.  There is also an
option to get a 90 day ATO simply by getting pentested, but after that 90 day
ATO expires, you cannot renew it, and must step up to the 1 or 3 year ATO.

Other ATO types can probably roughly follow this process and use the GSA
LATO data to fill out their SSP template.  There will probably be additional
controls that you will need to document for those, as well as different
documents to follow, different Authorizing Officials and other contacts,
etc.  You will have to figure that out.

To apply for a GSA LATO, you should:
1. Download the [Lightweight Security Authorization Guide](https://insite.gsa.gov/cdnstatic/insite/Lightweight_Security_Authorization_Process_%5BCIO_IT_Security_14-68_Rev_6%5D_04-25-2018.docx)
   from [insite](https://insite.gsa.gov/topics/information-technology/security-and-privacy/it-security/it-security-procedural-guides)
   and read it over.  This is the generic process for getting a LATO.
1. Read the 18F [Before You Ship](https://before-you-ship.18f.gov/ato/) document.
   It is much better at explaining what you should do in regular language, but
   has some cloud.gov-specific sections in it that you might need to
   work around, so keep that in mind as you follow the process.  If you are
   not in 18F, you may also have to skip some of the 18F-specific processes,
   and instead use your own local ATO-related processes.
1. Begin following the process outlined in https://before-you-ship.18f.gov/ato/.
1. When selecting controls, you will select the controls contained in Appendix B of the 
   [Lightweight Security Authorization Guide](https://insite.gsa.gov/cdnstatic/insite/Lightweight_Security_Authorization_Process_%5BCIO_IT_Security_14-68_Rev_6%5D_04-25-2018.docx).
1. When documenting the controls, be aware that much of the controls are
   [already documented](#compliance-documentation).  You will only need
   to additionally document the controls relevant to your application that
   you have deployed using this template, as well as any changes to the
   infrastructure (if any).
1. When you get to where you are filling out the [SSP](https://before-you-ship.18f.gov/ato/ssp/),
   you will want to generate the [compliance documentation](#compliance-documentation)
   from your project and use that information to help you understand what/how
   to fill out the different sections.

   A quick summary of how to generate the [GitBook](https://github.com/opencontrol/compliance-masonry/blob/master/docs/gitbook.md)
   that lets you see the controls and other compliance information is:
     2. `cd gcp-appengine-template/compliance && (rm -rf exports ; compliance-masonry get ; compliance-masonry docs gitbook LATO ; npm install -g gitbook-cli ; cd exports ; gitbook serve ; cd ../..)`
     2. Go to http://localhost:4000/ in your web browser.

   Most of the sections in the [SSP Template](https://docs.google.com/document/d/1ye-MUIq_0cmv8-Lkd41Gx_V0adIiLEho96GwYI_H_8g/edit#heading=h.nc0r2rvqrwc4)
   (which you can find in Appendix A of the [Lightweight Security Authorization Guide](https://insite.gsa.gov/cdnstatic/insite/Lightweight_Security_Authorization_Process_%5BCIO_IT_Security_14-68_Rev_6%5D_04-25-2018.docx))
   will have some text in the [GitBook](https://github.com/opencontrol/compliance-masonry/blob/master/docs/gitbook.md)
   that you can copy or use as a guide to fill out the various sections
   and controls, in addition to the more general guidance in the
   [SSP documentation](https://before-you-ship.18f.gov/ato/ssp/).
1. Continue executing the process outlined in the 18F [Before You Ship](https://before-you-ship.18f.gov/ato/)
   document until you have your ATO!

### Continuing Maintenance of GSA LATO

You may need to re-authorize your ATO if you make significant changes to
the system, especially if they change the security posture of the system.
You will also need to renew your ATO once a year.

These processes are also documented at a high level in the
18F [Before You Ship](https://before-you-ship.18f.gov/ato/) document.


## Common Workflows

### Normal Development Workflow

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

### Manual Deploy Workflow

XXX You can run some stuff by hand if you want to.

### Logging/Debugging

Logs can be watched either by using the [GCP Console](https://console.cloud.google.com/logs/),
or by getting the google cloud SDK going and saying `gcloud app logs tail`
to get all logs from all versions of the apps.

Some frameworks can be debugged in the GCP console without changes.  Others
may require some special libraries.  Consult https://cloud.google.com/debugger/docs/
for more information.

### Infrastructure Update Workflow

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

XXX When we can provision more than one GCP Project, we hope to restructure
this so that infrastructure will not be shared, and can be branched just like
the apps, simplifying the infrastructure testing considerably.

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

### Gitops/Infrastructure As Code

This is less a technology, and more of a way of managing a system only using
code.  The idea is that aside from perhaps some one-off startup tasks, almost
everything is managed by checking in code and moving it between branches.
This ensures that all changes to the system are contained in git, and thus
may be rolled back or reconstructed in a Disaster Recovery scenario.

### Google App Engine
App Engine is a simple way to deploy applications that will automatically scale
up and down according to load, collect logs, etc.  https://cloud.google.com/appengine/

### Google Cloud SQL
Cloud SQL is an easy way to provision and manage databases.  We are using PostgreSQL
for our infrastructure, but you can use MySQL if you like.  Our configuration sets the
production database to be HA, with staging/dev non-HA.

### Terraform
Terraform orchestrates the project setup, creating databases, storage,
secrets, etc.  https://www.terraform.io/

### Circle CI
Terraform and the Google Cloud SDK are invoked on commit by Circle CI, which
automates all of the terraform, code deployment, testing and scanning tasks
for each environment.  https://circleci.com/

### OWASP ZAP
ZAP is a proxy that can be used to scan an app for common security vulnerabilities.
https://www.owasp.org/index.php/OWASP_Zed_Attack_Proxy_Project

## Example Applications

### Rails / App Engine
This is a simple app that uses ActiveRecord to store a "blog" in a db.
It is deployed to GCP with an [OAuth2 Proxy](https://github.com/pusher/oauth2_proxy)
in front of it, so to use it properly, you will need an Identity Provider
to configure it with like login.gov.

To test locally, have ruby/bundler installed and 
run `cd rails-example && bundle install && bin/rails server`.  You will be able
to access the application on http://localhost:3000/.

### .NET Core / App Engine
This is a simple app that creates a list of URLs for "blogs" in a database.  
This may change, but for now, you must use the netcoreapp2.1
framework for applications deployed into App Engine.  It uses KMS to store
antiforgery keys, and has basic auth enabled.

To test locally, `cd dotnet-example && dotnet run`.
This will operate on a local `blogging.db` sqlite db.

### Java Spring Boot / App Engine
XXX
