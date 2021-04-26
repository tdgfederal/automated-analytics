# Automated Analytics Infrastructure as Code

Contains terraform code to automatically stand up analytics environment in aws.

## Getting started

1. clone this repository
2. `cd automated-analytics`
3. run `./run.sh init`
4. run `./run.sh apply`


## Usage
`./run.sh <terraform action> <environment> <region>`  
terraform actions: `init, plan, apply, destroy`
environment: `dev, prod`
region: `us-east-1, us-west-2`

## Remove

1. run `./run.sh destroy`