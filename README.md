# Overview

These are CloudFormation templates to deploy customer side AWS infrastructure required to utilize the Splunk-managed metric streams feature offered by the Splunk Observability Cloud AWS integration.

Deployment of this template is a single step when setting up AWS integration in Splunk Observability. There are more steps required to successfully send metrics via AWS metric streams to Splunk Observability. Refer to the [Splunk Observability documentation](https://help.splunk.com/en/splunk-observability-cloud/manage-data/connect-to-your-cloud-service-provider/connect-to-aws/connect-with-splunk-managed-metrics-streams) for more details.

## AWS StackSets
Some of our templates utilize StackSets, which allow for deployment of resources across a few regions with a single StackSet deployment.
 
StackSets require [prerequisites](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacksets-prereqs-self-managed.html) to be configured. (this is required one time per AWS account). 
 
Unfortunately, not all regions support StackSets (not every region can be a "parent" region of a StackSet). If you try to open a template containing StackSet in a region which does not support it you will see an error similar to:
![Screenshot of an error in AWS Console](./resources/aws_error.png)
 

## Choosing the right template

We recommend the usage of [the template_metric_streams.yaml](https://console.aws.amazon.com/cloudformation/home?region=eu-central-1#/stacks/create/review?templateURL=https://o11y-public.s3.amazonaws.com/aws-cloudformation-templates/release/template_metric_streams.yaml) which uses StackSets to deploy across all regions.

The template utilizes StackSets to help deploy infrastructure for collecting metrics utilizing AWS CloudWatch Metric Streams.
You can safely deploy this template - unused infrastructure will not generate costs.

In order to use StackSets, make sure to configure the [prerequisites](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacksets-prereqs-self-managed.html) (this is required one time per AWS account).

If you don't want to deploy across all regions please use the regional template.

| Template        (do not deploy; use only for source inspection)                                           | Deployment type |  QuickLink (click and adjust the region in AWS Console) | Hosted template link
| --------------------------------------------------------- | --------------- | ----------|----------------------|
| [metric streams (using StackSets)](metric-streams/template_metric_streams.yaml)     | once per account (utilizing StackSets)|[deploy this](https://console.aws.amazon.com/cloudformation/home?region=eu-central-1#/stacks/create/review?templateURL=https://o11y-public.s3.amazonaws.com/aws-cloudformation-templates/release/template_metric_streams.yaml)|https://o11y-public.s3.amazonaws.com/aws-cloudformation-templates/release/template_metric_streams.yaml|
| [metric streams](metric-streams/template_metric_streams_regional.yaml)    | in each region|[deploy this in every region](https://console.aws.amazon.com/cloudformation/home?region=eu-central-1#/stacks/create/review?templateURL=https://o11y-public.s3.amazonaws.com/aws-cloudformation-templates/release/template_metric_streams_regional.yaml)|https://o11y-public.s3.amazonaws.com/aws-cloudformation-templates/release/template_metric_streams_regional.yaml|


