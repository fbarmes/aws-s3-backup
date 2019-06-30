#!/usr/bin/env bash

#-------------------------------------------------------------------------------
# global setup
#-------------------------------------------------------------------------------
INSTALL_DIR=$(dirname $(readlink -f $0));
SCRIPT_NAME=$(basename $(readlink -f $0));

#-------------------------------------------------------------------------------
# global script behaviour vars
#-------------------------------------------------------------------------------
VERBOSE=false
DRY_RUN=false
MAIN_ACTION=""

#-------------------------------------------------------------------------------
# global functional vars
#-------------------------------------------------------------------------------
AWS_PROFILE=""
AWS_STACK_NAME="s3-backup-stack"
AWS_MASTER_TEMPLATE_FILE="master.yml"

declare -A AWS_CFN_PARAMS
AWS_CFN_PARAMS["CfnBucket"]="fbarmes-cfn-public"
AWS_CFN_PARAMS["CfnPath"]="aws-s3-backup"

declare -a AWS_IAM_CAPABILITIES
AWS_IAM_CAPABILITIES+=("CAPABILITY_IAM")
AWS_IAM_CAPABILITIES+=("CAPABILITY_AUTO_EXPAND")

AWS_MASTER_TEMPLATE_FILE="https://s3.amazonaws.com/${AWS_CFN_PARAMS[CfnBucket]}/${AWS_CFN_PARAMS[CfnPath]}/master.yml"

#-------------------------------------------------------------------------------
# Variable specific to this stack
#-------------------------------------------------------------------------------
AWS_CFN_PARAMS["BucketName"]="fbarmes-s3-backup"

#-------------------------------------------------------------------------------
# usage function
#-------------------------------------------------------------------------------
usage() {
  cat <<END_HELP
Usage: ${SCRIPT_NAME} <action>

Available options:
    -h, --help            : display this help and exit
    -v, --verbose         : verbose output
    -d, --dry-run         : do not execute script, just displays the commands
    -p, --profile         : aws profile to use
Required arguments:
    <action>              : create, update, delete

END_HELP
}

#-------------------------------------------------------------------------------
# handle command line options
#-------------------------------------------------------------------------------
get_options() {
  readonly OPTS_SHORT="h,v,d,p:"
  readonly OPTS_LONG="help,verbose,dry-run,profile:"
  GETOPT_RESULT=`getopt -o ${OPTS_SHORT} --long ${OPTS_LONG} -- $@`
  GETOPT_SUCCESS=$?
  NARGS=1

  if [ $GETOPT_SUCCESS != 0 ]; then
    echo "Failed parsing options"
    usage
    exit 1
  fi

  # replace script argument with those return by getopt
  eval set -- "$GETOPT_RESULT"
  # handle arguments
  while true ; do
    case "$1" in
        -h|--help) usage; shift; exit 0; ;;
        -v|--verbose) VERBOSE=true;         shift;  ;;
        -d|--dry-run) DRY_RUN=true;         shift;  ;;
        -p|--profile) AWS_PROFILE=$2;       shift 2; ;;
        --) shift; break; ;;
        *) echo "Invalid option $1"; exit 1; ;;
    esac
  done

  #-- check non-options parameters
  if [ $# -ne ${NARGS} ] ; then
    usage;
    exit 1
  fi

  #-- command list
  MAIN_ACTION=$1
}


#-------------------------------------------------------------------------------
echo_vars() {
  echo "-----------------------------------------------"
  echo "INSTALL_DIR=${INSTALL_DIR}"
  echo "SCRIPT_NAME=${SCRIPT_NAME}"
  echo "VERBOSE=${VERBOSE}"
  echo "DRY_RUN=${DRY_RUN}"
  echo "MAIN_ACTION=${MAIN_ACTION}"
  echo "AWS_PROFILE=${AWS_PROFILE}"
  echo "-----------------------------------------------"
}


#-------------------------------------------------------------------------------
# aws_create : deploy a new AWS stack from the CFN master template
aws_create() {
  aws_create_or_update create-stack
}

#-------------------------------------------------------------------------------
# aws_update : update the AWS stack
aws_update() {
  aws_create_or_update update-stack
}

#-------------------------------------------------------------------------------
aws_create_or_update() {
  readonly action=$1

  #-- start option string
  AWS_OPTS=""

  #-- add profile if any
  if [ "${AWS_PROFILE:+x}" = "x" ]; then
    AWS_OPTS="${AWS_OPTS} --profile ${AWS_PROFILE}"
  fi
  AWS_OPTS="${AWS_OPTS} --stack-name ${AWS_STACK_NAME}"
  AWS_OPTS="${AWS_OPTS} --template-url ${AWS_MASTER_TEMPLATE_FILE}"
  AWS_OPTS="${AWS_OPTS} --parameters $(get_aws_cfn_parameters)"
  AWS_OPTS="${AWS_OPTS} --capabilities $(get_aws_iam_capabilities)"

  readonly command="aws cloudformation ${action} ${AWS_OPTS}"

  # echo "command = ${command}"
  set -x
  ${command}
  set +x
}

#-------------------------------------------------------------------------------
# aws_delete : delete the AWS stack
aws_delete() {
  readonly action="delete-stack"

  #-- start option string
  AWS_OPTS=""

  #-- add profile if any
  if [ "${AWS_PROFILE:+x}" = "x" ]; then
    AWS_OPTS="${AWS_OPTS} --profile ${AWS_PROFILE}"
  fi
  AWS_OPTS="${AWS_OPTS} --stack-name ${AWS_STACK_NAME}"

  readonly command="aws cloudformation ${action} ${AWS_OPTS}"

  # echo "command = ${command}"
  set -x
  ${command}
  set +x
}


#-------------------------------------------------------------------------------
# build the list of ParameterKey / ParameterValue for
# CloudFormation parameters
#
get_aws_cfn_parameters() {
  result="";
  for key in ${!AWS_CFN_PARAMS[@]}; do
    value=${AWS_CFN_PARAMS[$key]}
    result+=" ParameterKey=${key},ParameterValue=${value}"
  done

  echo ${result}
}

#-------------------------------------------------------------------------------
get_aws_iam_capabilities() {
  result=${AWS_IAM_CAPABILITIES[@]};
  echo ${result}
}

#-------------------------------------------------------------------------------
# main function
#-------------------------------------------------------------------------------
main() {
  get_options $@

  if [ $VERBOSE = true ] ; then
    echo_vars
  fi


  #--
  case  "$MAIN_ACTION" in
    create)
      aws_create
      ;;
    update)
      aws_update
      ;;
    delete)
      aws_delete
      ;;
    get-cfn-parameters)
      echo $(get_aws_cfn_parameters)
      ;;
    get-iam-capabilities)
      echo $(get_aws_iam_capabilities)
      ;;
    *)
      echo ""
      echo "ERROR: Unkonwn action [${MAIN_ACTION}]"
      exit 1;
      ;;
  esac
}


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
main $@
