# Maintainers info

### Tooling
* [pre-commit](https://pre-commit.com/)
* [cfn-lint](https://github.com/aws-cloudformation/cfn-python-lint)
* [taskcat](https://github.com/aws-quickstart/taskcat) (WIP)

You don't have to install any of that locally, but if you do, cfn-lint & pre-commit will make your life easier.
In addition, if you're changing circleci pipelines, `circleci`'s local cli is great for validating config and running pipelines locally  (`circleci config validate`)

### Releasing
We use CircleCi for build process.
* Every commit to each branch will trigger cfn-lint. If you want your commits to automatically publish test version to rnd account in AWS, use a branch name starting with "pipeline". If you push a commit to a branch prefixed with "pipeline", the test artifact will be uploaded to AWS.

* Every commit to the main branch will trigger cfn-lint and publication of the CF templates in the staging version.

* To release a public version, tag a chosen commit with a sem-ver git tag, for example `1.0.0`.

Adding tag `1.0.0` to commit `9fceb02`:
```
git tag -a 1.0.0 9fceb02
git push origin main --tags
```

Deleting tag `1.0.0` if you made a mistake:
 
```
# delete local tag '1.0.0'
git tag -d 1.0.0
# delete remote tag '1.0.0'
git push origin :refs/tags/1.0.0

# alternative approach
git push --delete origin 1.0.0
git tag -d 1.0.0
```

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
`https://console.aws.amazon.com/cloudformation/home?region=<region>#/stacks/create/review?templateURL=<templateUrl>&param_SplunkAccessToken=<accessKey>&param_SplunkIngestUrl=<ingestUrl>`

For example, if you wish to check how the published template in eu-central-1 works, login to AWS console where you want to deploy and go to:

`https://console.aws.amazon.com/cloudformation/home?region=eu-central-1#/stacks/create/review?templateURL=https://o11y-public-eu-central-1.s3.eu-central-1.amazonaws.com/aws-log-collector/packaged.yaml`

(if you don't pass parameter overrides, they will be left empty for you to fill)
