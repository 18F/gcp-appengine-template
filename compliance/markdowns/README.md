# Welcome!

This document is meant to collect most of the data that you will need to complete a
GSA LATO package.  Since the documents that you must fill out are all Word documents,
and the requirements may change over time, we believe that it would be more useful
for us to collect the data that you need to fill out the package in a useful way
and let you consult it as you fill the actual templates out.

# GSA LATO SSP Template

As you fill out sections in the GSA LATO SSP Template, you should be able to search for
the section name to receive guidance on how to fill it out.

Not all sections have comments.  Those sections should be relatively
self-explanatory.

## Information System Categorization

You will need to decide for yourself whether your information system and it's data
are classified as Low/Moderate/High sensitivity.  The SSP Template has some guidance
on what documents you can consult for understanding these definitions.  As of this
writing, they are [NIST-800-60 Volume 1](https://csrc.nist.gov/publications/detail/sp/800-60/vol-1-rev-1/final)
and [NIST-800-60 Volume 2](https://csrc.nist.gov/publications/detail/sp/800-60/vol-2-rev-1/final).

The Security Objective Impacts section can be filled out once you consult
[FIPS 199](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.199.pdf)

## E-Authentication Determination

If you use authentication in your app, you will need to look over
[NIST-800-63-2](https://nvlpubs.nist.gov/nistpubs/specialpublications/nist.sp.800-63-2.pdf)
for information on how to fill this section out.

## Information System Owner, Authorizing Official, Other Designated Contacts, Assignment of Security Responsibility

Some good documentation on how to understand the roles can be found in the
[18F ATO documentation](https://before-you-ship.18f.gov/ato/).

## Leveraged Provisional Authorizations

The template does not have a pre-built section here for GCP, but you ought to be able
to fill in the information about the 
[GCP Fedramp Package](https://marketplace.fedramp.gov/#/product/google-services-google-cloud-platform-products-and-underlying-infrastructure?sort=productName&productNameSearch=google)
here.

## General System Description
### Information System Components and Boundaries

You should use content from the
[DevSecOps Architecture Document](https://github.com/18F/gcp-appengine-template/blob/master/DEVSECOPS.md) here.
You will need to remove any example app specific text and add text that describes your application instead, and
maybe create your own diagrams.

### Types of Users

Here are the roles that the template uses:

| Role               | Internal or External | Sensitivity/Background | Priv/Nonpriv Functions | MFA             |
|--------------------|----------------------|------------------------|------------------------|-----------------|
| Users              | ???                  | ???                    | ???                    | ???             |
| Developers         | Internal             | ???                    | Edit rights to code, approval for deploys up to staging, read-only access to production GCP Project, editor access to non-prod GCP Projects. | Yes, GitHub 2fa |
| Admins             | Internal             | ???                    | Edit rights to code, approval for all deploys and infrastructure changes, Editor access to GCP Projects. | Yes, GitHub 2fa and Google FIDO 2-step |
| Project Owners     | Internal             | ???                    | Edit rights to code, approval for all deploys and infrastructure changes, Project Owner access to GCP Projects. | Yes, GitHub 2fa and Google FIDO 2-step |
| GSA GCP Org Admins | Internal             | ???                    | Creation/deletion of GCP Projects and GCP User accounts, Project Owner access to GCP Projects | Yes, Google FIDO 2-step |

If you have more roles required to manage your application, you will need to add them too.
