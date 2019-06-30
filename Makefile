#!/usr/bin/make -f


#--
# list of objects at project root that should be included in artifact
ROOT_OBJECTS=templates *.yml VERSION


#-------------------------------------------------------------------------------
TARGET_DIR=target
ARTIFACT_VERSION=$(shell cat VERSION)
ARTIFACT_NAME=$(shell basename $(shell pwd))

ARTIFACT=${ARTIFACT_NAME}-${ARTIFACT_VERSION}
PACKAGE=${ARTIFACT}.tgz

CFN_BUCKET=fbarmes-cfn-public
CFN_PATH=aws-s3-backup
AWS_S3_TARGET=s3://${CFN_BUCKET}/${CFN_PATH}
AWS_CLI_OPTS=

#--
# use Makefile.env to override any variable
include Makefile.env


#-------------------------------------------------------------------------------
.PHONY: all
all: init package

#-------------------------------------------------------------------------------
.PHONY: help
help:
	@echo ""
	@echo "Available targets are :"
	@echo "  echo: display the value of some variables"
	@echo "  all: package this project"
	@echo "  package: create this project's artifact (in target directory)"
	@echo "  clean: remove the content of the target directory"
	@echo "  publish: copy the files to the cloudformation bucket"
	@echo "  clean-aws: delete the files in the cloudformation bucket"
	@echo ""

#-------------------------------------------------------------------------------
.PHONY: echo
echo:
	@echo
	@echo '---- Project Info ----'
	@echo ARTIFACT=[${ARTIFACT}]
	@echo PACKAGE=[${PACKAGE}]
	@echo TARGET_DIR=[${TARGET_DIR}]
	@echo
	@echo '---- AWS Info ----'
	@echo AWS_CLI_OPTS=[${AWS_CLI_OPTS}]
	@echo CFN_BUCKET=[${CFN_BUCKET}]
	@echo CFN_PATH=[${CFN_PATH}]


#-------------------------------------------------------------------------------
.PHONY: init
init:
	mkdir -p ${TARGET_DIR}

#-------------------------------------------------------------------------------
.PHONY: clean
clean:
	rm -rf target

#-------------------------------------------------------------------------------
.PHONY: clean-aws
clean-aws:
	aws s3 ${AWS_CLI_OPTS} rm \
		--recursive  \
		${AWS_S3_TARGET}

#-------------------------------------------------------------------------------
.PHONY: package
package:
	@#-- make artifact dir
	mkdir -p ${TARGET_DIR}/${ARTIFACT}

	@#-- copy cfn structure to artifact
	cp -r ${ROOT_OBJECTS} ${TARGET_DIR}/${ARTIFACT}

#-------------------------------------------------------------------------------
.PHONY: publish
publish: package
	aws s3 ${AWS_CLI_OPTS} cp \
		--recursive  \
		${TARGET_DIR}/${ARTIFACT} ${AWS_S3_TARGET}
