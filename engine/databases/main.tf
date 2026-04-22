# ------------------------------------------------------------------------------
# DATABASES SUB-ENGINE
# ------------------------------------------------------------------------------

# 0. Load Foundational States
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = lookup(local.config.global, "terraform_state_bucket", null)
    key    = "${local.env}/vpc/terraform.tfstate"
    region = local.region
  }
}

locals {
  infra_vpc_id          = try(data.terraform_remote_state.vpc.outputs.vpc_id, null)
  infra_private_subnets = try(data.terraform_remote_state.vpc.outputs.private_subnets, null)
  infra_vpc_cidr_block  = try(data.terraform_remote_state.vpc.outputs.vpc_cidr_block, null)
}

# 1. RDS
module "rds" {
  count           = try(local.config.rds.enabled, false) ? 1 : 0
  source          = "../../../terraform-module/modules/rds"
  vpc_id          = local.infra_vpc_id
  vpc_cidr_block  = local.infra_vpc_cidr_block
  private_subnets = local.infra_private_subnets
  config_file     = basename(var.config_path)
  global_config   = local.config.global
  tags            = local.tags
}

# 2. ElastiCache
module "elasticache" {
  count           = try(local.config.elasticache.enabled, false) ? 1 : 0
  source          = "../../../terraform-module/modules/elasticache"
  vpc_id          = local.infra_vpc_id
  private_subnets = local.infra_private_subnets
  config_file     = basename(var.config_path)
  global_config   = local.config.global
  tags            = local.tags
}

# 3. DynamoDB
module "dynamodb" {
  count         = try(local.config.dynamodb.enabled, false) ? 1 : 0
  source        = "../../../terraform-module/modules/dynamodb"
  config_file   = basename(var.config_path)
  global_config = local.config.global
  tags          = local.tags
}
