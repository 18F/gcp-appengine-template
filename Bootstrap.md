# Bootstrap Process

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
  2. Get GSA ICE to enable all of the APIs and roles you need for your GCP
     Project.  They should be able to check this repo out and follow the
     instructions on the [GCP Provisioning page](GCP_Provisioning.md).
     Or at least they can look the scripts
     over and understand what needs to be done on their end.
  2. Generate a key for the Terraform service account via
     `Console -> IAM & admin -> Service Accounts -> terraform -> Create Key` in GCP.
  2. Save the JSON credentials to `$HOME/master-gcloud-service-key.json` for
     your production GCP Project, `$HOME/staging-gcloud-service-key.json` for
     your staging GCP Project, or `$HOME/dev-gcloud-service-key.json` for
     your dev GCP Project.

     These files should either be stored securely by the administrators
     of the system, or (even better) deleted after circleci has been seeded with
     it's data.
1. You should be sure to set up master and staging branches as protected branches
   that require approval for PRs to land in this repo.  You should also enable
   as many code analysis integrations as are appropriate within the repo to
   enforce code quality and find vulnerabilities.
1. [Enable circleci on this repo](https://circleci.com/docs/2.0/project-build/),
   then [add some environment variables](https://circleci.com/docs/2.0/env-vars/#setting-an-environment-variable-in-a-project) to it:
   * `GCLOUD_SERVICE_KEY_master`:  Set this to the contents of `$HOME/master-gcloud-service-key.json`
   * `GCLOUD_SERVICE_KEY_staging`:  Set this to the contents of `$HOME/staging-gcloud-service-key.json`
   * `GCLOUD_SERVICE_KEY_dev`:  Set this to the contents of `$HOME/dev-gcloud-service-key.json`
   * `GOOGLE_PROJECT_ID_master`: Set this to your production google project ID
   * `GOOGLE_PROJECT_ID_staging`: Set this to your staging google project ID
   * `GOOGLE_PROJECT_ID_dev`: Set this to your dev google project ID
   * `BASICAUTH_PASSWORD`: Set this to a basic auth password to frontend non-SSO apps with.
     If it is not set, then your non-SSO app will be public.
   * `BASICAUTH_USER`: Set this to the basic auth username you want.
1. Watch as circleci deploys the infrastructure.  Watch the terraform job,
   and approve it when it's plan is complete, then wait until it is done.

   The apps will all fail
   because it takes much longer for the databases to be created than the apps,
   and because you will need to get some info from terraform to make the
   oauth2_proxy work.  This is fine.
1. Go to the failed app deploy workflows in circleci and click on `Rerun`.
   Everything should fully deploy this time, though the rails app SSO proxy jobs
   will fail unless you completed the SSO proxy steps too.  This is fine.
1. You can now find all the apps if you go look at `Console -> App Engine -> Versions` and
   then click on the `Service` popup to find the app you'd like to get to
   (rails and dotnet-example, currently).  You will need to authenticate with
   the basic auth credentials you set above.

## Enabling the SSO proxy in front of the rails example

If you would like to enable the login.gov SSO proxy in front of the rails
example app, you should:

1. Sign up as a developer for [login.gov](https://developers.login.gov/) and
   create dev, staging, and production apps in the login.gov dashboard using their 
   directions and the following guidance:
   1. Look at the output from the `apply_terraform` job for each environment in
      circleci to get the Public Keys.
      Look for the `sso_cert` output.  If you have the gcloud utility working and
      have `jq` installed, you can use this command to get the dev cert, for example:  
      `gsutil cp gs://gcp-terraform-state-$GOOGLE_PROJECT_ID_dev/tf-output.json - | jq -r .sso_cert.value`.
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
   * `IDP_CLIENT_ID_dev`: Set this to the client ID you registered with your IDP for dev.
     (like `urn:gov:gsa:openidconnect:development`)
   * `IDP_CLIENT_ID_staging`: Set this to the client ID you registered with your IDP for staging.
     (like `urn:gov:gsa:openidconnect:staging`)
   * `IDP_CLIENT_ID_master`: Set this to the client ID you registered with your IDP for production.
     (like `urn:gov:gsa:openidconnect:production`)
   * `IDP_EMAIL_DOMAIN`: Set this to either the email domain that you would
   	 like your access restricted to (like `gsa.gov`), or `*`, if you would
   	 not like to restrict who can get in.
   * `IDP_PROFILE_URL`:  Set this to your IDP provider profile URL
     (like https://idp.int.identitysandbox.gov/api/openid_connect/userinfo).
1. You should then be able to go to circleci and click `Rerun` on a `deploy-rails-example`
   workflow, and everything should then deploy fully.  You will then be able to go to
   the frontend URL (something like https://dev-dot-${GOOGLE_PROJECT_ID}.appspot.com/) and experience the SSO login.

## Enabling offsite logging

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
1. Uncomment the `deploy-log-sync` workflow in the `.circleci/config.yml` file and
   push the code to GitHub, which should cause the workflow to deploy
   the service.
1. Check the logs for the logsync service.  You should see a line like
   `2019-04-08 12:39:34.000 PDT
2019/04/08 19:39:34 synced logs from gs://logs-bucket-${GOOGLE_PROJECT_ID} to s3://gsa-logbucket/dev`
   if things are going well.  Otherwise, you should see error messages that
   you can use to diagnose the problem.

