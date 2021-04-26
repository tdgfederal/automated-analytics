PROJECT="automated-analytics"
DEFAULT_ACTION="plan"
BUCKET="tdg-automated-analytics"
REGION="us-east-1"
DEFAULT_ENV="dev"
DEFAULT_VARFILE="terraform.tfvars"
PROJECT_DIR="./"



[[ $1 = "" ]] && ACTION=$DEFAULT_ACTION || ACTION="$1"
[[ $2 = "" ]] && ENV=$DEFAULT_ENV || ACTION="$2"

function init {
    printf "\e[1;35mRunning Terraform init for $PROJECT $ENV in $REGION with global/$REGION/$VARFILE and $PROJECT_DIR/$ENV/$REGION/$VARFILE\e[0m\n"
    terraform init -backend-config="bucket=$BUCKET" -backend-config="key=$REGION-$PROJECT-$ENV.tfstate" \
                    -backend-config="region=$REGION" -backend=true -get=true -input=false  \
                    -backend-config="encrypt=true" $PROJECT_DIR
}

function plan {
  init
  printf "\e[1;35mRunning Terraform plan\e[0m\n"
  terraform plan
}

function apply {
  plan
  printf "\e[1;35mRunning Terraform apply\e[0m\n"
  terraform apply
}

function destroy {
  plan
  printf "\e[1;31mRunning Terraform destroy\e[0m\n"
  terraform destroy $PROJECT_DIR
}


function usage {
  printf "\033[1;31mArgument(s) error\033[0m\n"
  echo "usage    : ./run.sh <action> <env> <region> "
  echo "         : Default project is live. Action can be init, plan, apply, graph, or destroy."
  echo "example  : ./run.sh init dev"
}

case "$ACTION" in
   "init")     init     ;;
   "plan")     plan     ;;
   "apply")    apply    ;;
   "destroy")  destroy  ;;
   *)          usage    ;;
esac