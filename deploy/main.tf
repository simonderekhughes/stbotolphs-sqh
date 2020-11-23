/******************************************************************************
 * SPDX-License-Identifier: Apache-2.0
 * Terraform configuration for CEM St Botolphs task.
 *
 *  This file configures the following AWS infrastructure:
 *  - EC2 instance which builds a tag in the stbotolphs repo. The EC2 spins up
 *    the docker container with the CMS webapp.
 *  - S3 bucket used as an object store.
 *  - RDS postrgesql DB instance.
 *  The webapp is configured to connect to AWS SMTP servers.
 *****************************************************************************/

locals {
  inst_git_private_key_pathname = "/home/ubuntu/.ssh/id_ed25519"
  inst_scripts_dir = "/tmp"
  scripts_dir = "scripts"
  server_port_http = 80
  server_port_ssh = 22
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_s3_bucket" "cms_s3_bucket" {
  bucket = "sdh-test-s3-bucket-499797853637-ex-13"
  acl = "private"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cms_s3_bucket_policy" {
  bucket = aws_s3_bucket.cms_s3_bucket.id

  policy = <<-POLICY
            {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "AllObjectActions",
                        "Effect": "Allow",
                        "Principal": "*",
                        "Action": "s3:*Object",
                        "Resource": "arn:aws:s3:::sdh-test-s3-bucket-499797853637-ex-13/*"
                    }
                ]
            }
            POLICY
}

resource "aws_key_pair" "instance_ssh_connection_public_key" {
  key_name   = "deployer-key"
  public_key = file(var.instance_ssh_public_key_path)
}

resource "aws_instance" "cms_instance" {
  // Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
  ami = "ami-05c424d59413a2876"
  instance_type = "c5.4xlarge"
  key_name = "deployer-key"
  vpc_security_group_ids = [aws_security_group.cms_security_group.id, aws_security_group.aws_sg_internal.id]

  tags = {
    Name = "terraform-cms-instance"
  }

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ubuntu"
    private_key = file(var.instance_ssh_private_key_path)
  }

  // Copy the commissioning scripts to the target instance
  provisioner "file" {
    source = local.scripts_dir
    destination = local.inst_scripts_dir
  }

  // Copy the github key to target instance
  provisioner "file" {
    source = var.github_private_key_path
    destination = local.inst_git_private_key_pathname
  }

  // Perform Stage 1 initialisation. Must Log out before performing
  // Stage 2 so that docker user changes take effect. */
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/scripts/aws_ec2_2232_setup_stage_01.sh",
      "/tmp/scripts/aws_ec2_2232_setup_stage_01.sh",
      ]
  }

  //Perform Stage 2 initialisation.
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/scripts/aws_ec2_2232_setup_stage_02.sh",
      "/tmp/scripts/aws_ec2_2232_setup_stage_02.sh",
      ]
  }
  // TODO: This instance must depend on the RDS database resource in the
  // module so the instance can connect to a running DB as part of initialisation.
  // How to accomplish this is currently unknown. A workaround is to sleep in the
  // instance startup scripts to ensure the DB is up. The following has been
  // found not to work.
  // depends_on = [module.db.module.db_instance.aws_db_instance.this[0]]
}

resource "aws_security_group" "cms_security_group" {

  name = "terraform-example-instance"

  ingress {
      from_port = var.server_port
      to_port = var.server_port
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = local.server_port_ssh
      to_port = local.server_port_ssh
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"] // global access! Don't do this for real.
  }

  ingress {
      from_port = local.server_port_http
      to_port = local.server_port_http
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"] // global access! Don't do this for real.
  }
}

resource "aws_security_group" "aws_sg_internal" {
  name = "aws_sg_internal_name"

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
    cidr_blocks = ["172.31.0.0/16"]
  }
}

/******************************************************************************
 * Database support
 *  This is derived from the following code:
 *    https://github.com/terraform-aws-modules/terraform-aws-rds/tree/v2.20.0
 *****************************************************************************/

// Data sources to get VPC, subnets and security group details
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}

module "db" {
  source = "terraform-aws-modules/rds/aws"
  version = "2.20.0"

  identifier = "demodb-postgres"

  engine            = "postgres"
  engine_version    = "9.6.9"
  instance_class    = "db.t2.large"
  allocated_storage = 5
  storage_encrypted = false

  // kms_key_id        = "arm:aws:kms:<region>:<account id>:key/<kms key id>"
  name = "demodb"

  // NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  // "Error creating DB Instance: InvalidParameterValue: MasterUsername
  // user cannot be used as it is a reserved word used by the engine"
  username = "demouser"

  password = "YourPwdShouldBeLongAndSecure!"
  port     = "5432"

  vpc_security_group_ids = [aws_security_group.aws_sg_internal.id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  // disable backups to create DB faster
  backup_retention_period = 0

  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  // DB subnet group
  subnet_ids = data.aws_subnet_ids.all.ids

  // DB parameter group
  family = "postgres9.6"

  // DB option group
  major_engine_version = "9.6"

  // Snapshot name upon DB deletion
  final_snapshot_identifier = "demodb"

  // Database Deletion Protection
  deletion_protection = false
}
