# Maintainers info

### Release process 

* This repo uses `pre-commit` to run `cfn-lint`.
* Commits pushed to any branch will result in the upload of the test templates internal S3 location.
* All commits to `main` branch will result in the upload of the templates in stage version to internal S3 location.
* To release templates to publicly accessible location, tag the commit in `main` branch with a sem-ver git tag, for example `1.0.0`.

### E2E testing using TaskCat

These scripts make sure to use unique IAM role & lambda function names.
They will create temporary templates in .tmp. 
You will find detailed output in taskcat_outputs.

`make taskcat-logs-no-stacksets`

`make taskcat-logs-stacksets`
 
## Quick links.

### To generate available quick links: 

`make quicklinks ENV=test`

`make quicklinks ENV=stage`

`make quicklinks ENV=release`

### Details

Quick link, when opened in AWS console, will present you with a form to deploy a template which you passed as a parameter.

The quick link format is:
`https://console.aws.amazon.com/cloudformation/home?region=<region>#/stacks/create/review?templateURL=<templateUrl>&param_IntegrationId=<integrationId>&param_SplunkAPIKey=<accessKey>&param_SplunkLogIngestUrl=<logIngestUrl>&param_SplunkMetricIngestUrl=<metricIngestUrl>`

For example, if you wish to check how the published template in eu-central-1 works, login to AWS console where you want to deploy and go to:

`https://console.aws.amazon.com/cloudformation/home?region=eu-central-1#/stacks/create/review?templateURL=https://o11y-public-eu-central-1.s3.eu-central-1.amazonaws.com/aws-log-collector/packaged.yaml`

(if you don't pass parameter overrides, they will be left empty for you to fill)
