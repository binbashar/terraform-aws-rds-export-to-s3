# -----------------------------------------------------------------------------
# Providers
# -----------------------------------------------------------------------------

#region1
provider "aws" {
  region = "eu-west-2"
}

#region2
provider "aws" {
  region = "us-east-1"
  alias  = "region2"
}

# -----------------------------------------------------------------------------
# local variables
# -----------------------------------------------------------------------------

locals {
  bucket_name_region1 = "example-rds-exported-snapshots-region1"
  bucket_name_region2 = "example-rds-exported-snapshots-region2"
  tags_region1 = {
    Name      = "example"
    Terraform = "true"
    Region    = "eu-west-2"
  }
  tags_region2 = {
    Name      = "example"
    Terraform = "true"
    Region    = "us-east-1"
  }

}

# -----------------------------------------------------------------------------
# RDS Export To S3 functions
# -----------------------------------------------------------------------------
module "rds_export_to_s3_region1" {
  source = "../../"

  # AWS Provider/alias. Multi-regions support via provider alias. e.g. 'aws.region2'
  #providers = {
  #  aws = aws
  #}

  # Set a prefix for naming resources. '<prefix>resouce-name'. 
  #prefix = "binbashar"

  # Set a postfix for naming resources. 'resouce-name-<postfix>'. Default is current region (${data.aws_region.current.name}).
  #postfix = "<region>"

  # Which RDS snapshots should be exported?
  database_names = "test1-aurora-mysql-cluster, test2-aurora-mysql-cluster"

  # Which bucket will store the exported snapshots?
  snapshots_bucket_name = module.bucket-region1.s3_bucket_id
  #snapshots_bucket_name = "export-bucket-name"

  # To group objects in a bucket, S3 uses a prefix before object names. The forward slash (/) in the prefix represents a folder.
  snapshots_bucket_prefix = "rds_snapshots/"

  # Which RDS snapshots events should be included (RDS Aurora or/and RDS non-Aurora)?
  #rds_event_ids = "RDS-EVENT-0091, RDS-EVENT-0169"

  # Create customer managed key or use default AWS S3 managed key. If set to 'false', then 'customer_kms_key_arn' is used.
  create_customer_kms_key = true

  # Provide CMK if 'create_customer_kms_key = false'
  #customer_kms_key_arn = "arn:aws:kms:eu-west-2:123456789:alias/kms-rds"

  # SNS topic for export monitor notifications
  create_notifications_topic = true

  # Which topic should receive notifications about exported snapshots events? Only required if 'create_notifications_topic = false'
  #notifications_topic_arn = "arn:aws:sns:us-east-1:000000000000:sns-topic-slack-notifications"

  # Set the logging level
  # log_level = "DEBUG"

  tags = local.tags_region1
  #tags = { Deployment = "binbachar-export-region-1" }
}


module "rds_export_to_s3_region2" {
  source = "../../"

  # AWS Provider/alias. Multi-regions support via provider alias. e.g. 'aws.us-east-1'.
  providers = {
    aws = aws.region2
  }

  # Set a prefix for naming resources. '<prefix>resouce-name'.
  #prefix = "binbashar"

  # Set a postfix for naming resources. 'resouce-name-<postfix>'. Default is current region (${data.aws_region.current}).
  #postfix = "<region>"

  # Which RDS snapshots should be exported?
  database_names = "test3-aurora-mysql-cluster, test4-aurora-mysql-cluster"

  # Which bucket will store the exported snapshots?
  snapshots_bucket_name = module.bucket-region2.s3_bucket_id
  #snapshots_bucket_name = "export-bucket-name"

  # To group objects in a bucket, S3 uses a prefix before object names. The forward slash (/) in the prefix represents a folder.
  snapshots_bucket_prefix = "rds_snapshots/"

  # Which RDS snapshots events should be included (RDS Aurora or/and RDS non-Aurora)?
  #rds_event_ids = "RDS-EVENT-0091, RDS-EVENT-0169"

  # Create customer managed key or use default AWS S3 managed key. If set to 'false', then 'customer_kms_key_arn' is used.
  create_customer_kms_key = false

  # Provide CMK if 'create_customer_kms_key = false'
  customer_kms_key_arn = "arn:aws:kms:us-east-1:123456789:alias/kms-rds"

  # SNS topic for export monitor notifications
  create_notifications_topic = true

  # Which topic should receive notifications about exported snapshots events? Only required if 'create_notifications_topic = false'
  #notifications_topic_arn = "arn:aws:sns:us-east-1:000000000000:sns-topic-slack-notifications"

  # Set the logging level
  # log_level = "DEBUG"

  tags = local.tags_region1
  #tags = { Deployment = "binbachar-export-region2" }
}


# -----------------------------------------------------------------------------
# This bucket will be used for storing the exported RDS snapshots.
# -----------------------------------------------------------------------------
module "bucket-region1" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v2.6.0"

  #main provider
  #provider = aws

  bucket        = local.bucket_name_region1
  acl           = "private"
  force_destroy = true

  attach_deny_insecure_transport_policy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.tags_region1
}


module "bucket-region2" {
  source = "github.com/binbashar/terraform-aws-s3-bucket.git?ref=v2.6.0"

  #provider with alias, different region
  provider = aws.region2

  bucket        = local.bucket_name_region2
  acl           = "private"
  force_destroy = true

  attach_deny_insecure_transport_policy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = local.tags_region1
}

