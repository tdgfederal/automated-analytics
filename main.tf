terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.12.23"
  backend "s3" {}
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}





###########  EC2 ##############


resource "aws_instance" "app_server" {
  ami           = "ami-0742b4e673072066f"
  instance_type = "t2.micro"

  tags = {
    Name = "Processing App Instance"
    Project = "Automated Analytics"
  }
}



############# RDS  #############

resource "aws_db_subnet_group" "db-subnetgrp" {
  name       = "db-subnetgrp"
  subnet_ids = ["subnet-259b1d7a","subnet-99631c97"]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "aa-mysql" {
  allocated_storage    = 100
  db_subnet_group_name = "db-subnetgrp"
  engine               = "mysql"
  engine_version       = "8.0"
  identifier           = "aa-mysql"
  instance_class       = "db.t2.small"
  password             = "password"
  skip_final_snapshot  = true
  storage_encrypted    = true
  username             = "amysql"

  depends_on = [
     aws_db_subnet_group.db-subnetgrp
  ]
}




############# EMR ##############

#---------------------------------------------------
# AWS EMR cluster
# Credit: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/emr_cluster
#---------------------------------------------------

resource "aws_emr_cluster" "aa-cluster" {

  service_role  = var.emr_cluster_service_role
  name          = var.emr_cluster_name != "" ? var.emr_cluster_name : "${lower(var.name)}-emr-cluster-${lower(var.environment)}"
  release_label = var.emr_cluster_release_label
  
   ec2_attributes {
    subnet_id                         = "subnet-259b1d7a"
    emr_managed_master_security_group = aws_security_group.allow_all.id
    emr_managed_slave_security_group  = aws_security_group.allow_all.id
    instance_profile                  = aws_iam_instance_profile.emr_profile.arn
  }

  master_instance_fleet {
    instance_type_configs {
      instance_type = "m4.large"
    }
    target_on_demand_capacity = 1
  }
  core_instance_fleet {
    instance_type_configs {
      bid_price_as_percentage_of_on_demand_price = 80
      ebs_config {
        size                 = 20
        type                 = "gp2"
        volumes_per_instance = 1
      }
      instance_type     = "m4.large"
      weighted_capacity = 1
    }
    launch_specifications {
      spot_specification {
        allocation_strategy      = "capacity-optimized"
        block_duration_minutes   = 0
        timeout_action           = "SWITCH_TO_ON_DEMAND"
        timeout_duration_minutes = 10
      }
    }
    name                      = "core fleet"
    target_on_demand_capacity = 2
    target_spot_capacity      = 2
  }
}

resource "aws_emr_instance_fleet" "task" {
  cluster_id = aws_emr_cluster.aa-cluster.id
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = 20
      type                 = "gp2"
      volumes_per_instance = 1
    }
    instance_type     = "m4.large"
    weighted_capacity = 1
  }
 
  launch_specifications {
    spot_specification {
      allocation_strategy      = "capacity-optimized"
      block_duration_minutes   = 0
      timeout_action           = "TERMINATE_CLUSTER"
      timeout_duration_minutes = 10
    }
  }
  name                      = "task fleet"
  target_on_demand_capacity = 1
  target_spot_capacity      = 1
}


# IAM Role for EC2 Instance Profile
resource "aws_iam_role" "iam_emr_profile_role" {
  name = "iam_emr_profile_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "emr_profile" {
  name = "emr_profile"
  role = aws_iam_role.iam_emr_profile_role.name
}

resource "aws_iam_role_policy" "iam_emr_profile_policy" {
  name = "iam_emr_profile_policy"
  role = aws_iam_role.iam_emr_profile_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Resource": "*",
        "Action": [
            "cloudwatch:*",
            "dynamodb:*",
            "ec2:Describe*",
            "elasticmapreduce:Describe*",
            "elasticmapreduce:ListBootstrapActions",
            "elasticmapreduce:ListClusters",
            "elasticmapreduce:ListInstanceGroups",
            "elasticmapreduce:ListInstances",
            "elasticmapreduce:ListSteps",
            "kinesis:CreateStream",
            "kinesis:DeleteStream",
            "kinesis:DescribeStream",
            "kinesis:GetRecords",
            "kinesis:GetShardIterator",
            "kinesis:MergeShards",
            "kinesis:PutRecord",
            "kinesis:SplitShard",
            "rds:Describe*",
            "s3:*",
            "sdb:*",
            "sns:*",
            "sqs:*"
        ]
    }]
}
EOF
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow inbound traffic"
  vpc_id      = "vpc-e76fb99a"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.31.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [
      ingress,
      egress,
    ]
  }

  tags = {
    name = "emr_test"
  }
}

# Parameter store value
resource "aws_ssm_parameter" "dev-db-cred" {
  name  = "dev-db-cred"
  type  = "String"
  value = "supersecret"
}