# Copyright 2021 Splunk, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

.DEFAULT_GOAL = help
BUILD_TIMESTAMP := $(shell ts -n)
AWS_PROFILE ?= rnd
BIN_DIR := $(PWD)/bin
template_files = $(wildcard **/template_*.yaml)

.PHONY: help
help:
	@echo "---------------HELP-----------------"
	@echo "make init - to install all dependencies type "
	@echo "make lint - to lint the project"
	@echo "make release-to-env ENV=test - to upload test versions to s3"
	@echo "make release-to-env ENV=release - to release and publish"
	@echo "make quicklinks ENV=test - to print quicklinks in an env"
	@echo "make taskcat-logs-no-stacksets, make taskcat-logs-stacksets - to run test scenarios"
	@echo "------------------------------------"

init:
	${PIP} install cfn-lint
	${PIP} install pre-commit

.PHONY: lint
lint:
	cfn-lint **/template_*.yaml

.PHONY: $(template_files)
$(template_files):
	mkdir -p $(BIN_DIR)/$(ENV)
	cp -R $@ $(BIN_DIR)/$(ENV)/

.PHONY: publish
release-to-env: $(template_files)
	cd $(BIN_DIR)/$(ENV); ls | xargs sed -i 's/aws-cloudformation-templates\/test/aws-cloudformation-templates\/$(ENV)/g'
	cd $(BIN_DIR)/$(ENV); ls | xargs sed -i '1,2d'
	cd $(BIN_DIR)/$(ENV); ls | xargs -I FILENAME aws s3 --region us-east-1 cp FILENAME s3://o11y-public/aws-cloudformation-templates/$(ENV)/FILENAME
	if [ "$(ENV)" = "release" ] || [ "true" = "$(FORCE_PUBLISH)" ]; then \
  	cd $(BIN_DIR)/$(ENV); \
	ls | xargs -I FILENAME aws s3api --region us-east-1 put-object-acl --bucket o11y-public --key aws-cloudformation-templates/$(ENV)/FILENAME --acl public-read; \
	fi

quicklinks:
	for FILE in $(notdir $(wildcard **/template_*.yaml)); \
	do echo "https://console.aws.amazon.com/cloudformation/home?region=eu-central-1#/stacks/create/review?templateURL=https://o11y-public.s3.amazonaws.com/aws-cloudformation-templates/$(ENV)/$${FILE}"; \
	done

taskcat-logs-no-stacksets:
	@echo "\n=====>Make the test artifact public for a moment so that deployment in integrations can reach it... (won't be needed after release)\n"
	aws s3api --profile rnd --region af-south-1 put-object-acl --bucket o11y-public-af-south-1 --key aws-log-collector/aws-log-collector.release.zip --acl public-read

	@echo "\n=====>Replace iam role name & function name with something unique to the test...\n"
	mkdir .tmp
	cp ./logs/template_logs_per_account.yaml ./.tmp/template_logs_per_account.yaml
	cp ./logs/template_logs_regional.yaml ./.tmp/template_logs_regional.yaml
	sed -i "" "s/RoleName\: splunk-log-collector/RoleName\: splunk-log-collector-$(BUILD_TIMESTAMP)/g" ./.tmp/template_logs_per_account.yaml
	sed -i "" "s/role\/splunk-log-collector/role\/splunk-log-collector-$(BUILD_TIMESTAMP)/g" ./.tmp/template_logs_regional.yaml
	sed -i "" "s/FunctionName\: 'splunk-aws-logs-collector'/FunctionName\: 'splunk-aws-logs-collector-$(BUILD_TIMESTAMP)'/g" ./.tmp/template_logs_regional.yaml

	@echo "\n=====>Deploy once per account template...\n"
	cd logs; taskcat test run -i .taskcat.yml -t logs-once-per-account --no-delete;

	@echo "\n=====>Wait for IAM to propagate to af-south-1...\n"
	sleep 10;

	@echo "\n=====>Deploy regional resources...\n"
	cd logs; taskcat test run -i .taskcat.yml -t logs-regional

	@echo "\n=====>Try to cleanup all taskcat stacks and stuff...\n"
	cd logs; taskcat test clean --aws-profile integrations --region af-south-1 aws-cloudformation-templates

	@echo "\n=====>Remove temporary test artifacts...\n"
	rm -rf ./.tmp

taskcat-logs-stacksets:
	@echo "\n=====>Make test artifacts public for a moment so that deployment in integrations can reach it... (won't be needed after release)\n"
	aws s3api --profile rnd --region eu-south-1 put-object-acl --bucket o11y-public-eu-south-1 --key aws-log-collector/aws-log-collector.release.zip --acl public-read
	aws s3api --profile rnd --region eu-central-1 put-object-acl --bucket o11y-public-eu-central-1 --key aws-log-collector/aws-log-collector.release.zip --acl public-read

	@echo "\n=====>Replace iam role name with something unique to the test...\n"
	cp ./logs/template_logs_per_account.yaml ./.tmp/template_logs_per_account.yaml
	cp ./logs/template_logs_regional.yaml ./.tmp/template_logs_regional.yaml
	sed -i "" "s/RoleName\: splunk-log-collector/RoleName\: splunk-log-collector-$(BUILD_TIMESTAMP)/g" ./.tmp/template_logs_per_account.yaml
	sed -i "" "s/role\/splunk-log-collector/role\/splunk-log-collector-$(BUILD_TIMESTAMP)/g" ./.tmp/template_logs_regional.yaml
	sed -i "" "s/FunctionName\: 'splunk-aws-logs-collector'/FunctionName\: 'splunk-aws-logs-collector-$(BUILD_TIMESTAMP)'/g" ./.tmp/template_logs_regional.yaml
	sleep 10;

	@echo "\n=====>Upload modified templates to s3 and make them public (they are referenced by the combined template)...\n"
	aws s3 --profile rnd --region us-east-1 cp ./.tmp/template_logs_per_account.yaml $(TEMPLATES_PUBLIC_ROOT)/packaged_logs_per_account.test.yaml
	aws s3 --profile rnd --region us-east-1 cp ./.tmp/template_logs_regional.yaml $(TEMPLATES_PUBLIC_ROOT)/packaged_logs_regional.test.yaml
	aws s3api --profile rnd --region us-east-1 put-object-acl --bucket o11y-public --key aws-cloudformation-templates/packaged_logs_per_account.test.yaml --acl public-read
	aws s3api --profile rnd --region us-east-1 put-object-acl --bucket o11y-public --key aws-cloudformation-templates/packaged_logs_regional.test.yaml --acl public-read

	@echo "\n=====>Deploy stackset, eu-central-1 + eu-south-1...\n"
	cd logs; taskcat test run -i .taskcat.yml -t logs-stackset;

	@echo "\n=====>Make artifacts private again...\n"
	aws s3api --profile rnd --region eu-south-1 put-object-acl --bucket o11y-public-eu-south-1 --key aws-log-collector/aws-log-collector.test.zip --acl private
	aws s3api --profile rnd --region eu-central-1 put-object-acl --bucket o11y-public-eu-central-1 --key aws-log-collector/aws-log-collector.test.zip --acl private
	aws s3api --profile rnd --region us-east-1 put-object-acl --bucket o11y-public --key aws-cloudformation-templates/packaged_logs_per_account.test.yaml --acl private
	aws s3api --profile rnd --region us-east-1 put-object-acl --bucket o11y-public --key aws-cloudformation-templates/packaged_logs_regional.test.yaml --acl private

	@echo "\n=====>Remove temporary test artifacts...\n"
	rm -rf ./.tmp
