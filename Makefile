SHELL = /bin/bash

STACKNAME = $(shell grep -e ^StackName parameters.conf | cut -d"=" -f2)
STACKBUCKET = $(shell grep -e ^StackBucket= parameters.conf | cut -d"=" -f2)
STACKREGION = $(shell grep -e ^StackRegion parameters.conf | cut -d"=" -f2)
CLUSTERNAME = $(shell grep -e ^ClusterName parameters.conf | cut -d"=" -f2)
K8S_VERSION = $(shell grep -e ^K8sVersion parameters.conf | cut -d"=" -f2)
GPU_SUPPORT = $(shell grep -v '^\s*\(\#\|$$\)' parameters.conf | grep NodeGPUSupport | cut -d"=" -f2)
STACBUCKETPREFIX = $(shell grep StackBucketPrefix parameters.conf | cut -d"=" -f2)

.PHONY: package
package: validate
	aws cloudformation package \
		--template ./main.yaml \
		--s3-bucket $(STACKBUCKET) \
		--s3-prefix "$(STACBUCKETPREFIX)" \
		--output-template cfn.yaml \
		--region us-east-1

.PHONY: validate
validate: generate 
	ls | grep -v -e aws-auth | grep -v -e custom-networking | grep .yaml | xargs cfn-lint

.PHONY: generate
generate: clean
	if [[ "$(GPU_SUPPORT)" == "no" || -z "$(GPU_SUPPORT)" ]]; then \
    	sed -e 's,K8S_IMAGE_KEY,1.$(K8S_VERSION)/amazon-linux-2,g' worker.tmpl > worker.yaml; \
    else \
		sed -e 's,K8S_IMAGE_KEY,1.$(K8S_VERSION)/amazon-linux-2-gpu,g' worker.tmpl > worker.yaml; \
	fi

.PHONY: deploy
deploy: package
	aws cloudformation deploy \
		--template-file cfn.yaml \
		--stack-name $(STACKNAME) \
		--region $(STACKREGION) \
		--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
		--parameter-overrides $(shell grep -v '^\s*\(#\|$$\|^Stack\)' parameters.conf);
	
	aws eks update-kubeconfig --name $(CLUSTERNAME) --region $(STACKREGION) --alias $(CLUSTERNAME);
	
	aws cloudformation describe-stacks \
		--stack-name $(STACKNAME) \
		--region $(STACKREGION) \
		--query Stacks[0].Outputs[0].OutputValue \
		--output text > node.role ;
	
	sed -e 's,ROLE_ARN,$(shell grep -e arn node.role),g' aws-auth.tmpl > aws-auth.yaml;
	
	kubectl apply -f aws-auth.yaml;

.PHONY: clean
clean:
	rm -f worker.yaml;
	rm -f cfn.yaml;

.PHONY: delete
delete:
	aws cloudformation delete-stack \
		--stack-name $(STACKNAME) \
		--region $(STACKREGION)

.PHONY: depcheck
.SILENT: depcheck
depcheck:
	echo "aws-cli: $(shell aws --version)";
	echo "kubectl: $(shell kubectl version --client=true --short)";
	echo "cfn-lint: $(shell cfn-lint --version)";
	echo "Current AWS IAM: $(shell aws sts get-caller-identity | jq -r '.Arn')";
	echo;
