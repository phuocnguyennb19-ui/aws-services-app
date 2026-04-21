# ==============================================================================
# PLATFORM ENGINE - APPLICATION LAYER RESOURCES
# ==============================================================================

# 0. Load Foundational States (Atomic Lookups)
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket  = lookup(local.config.global, "terraform_state_bucket", null)
    key     = "${local.env}/vpc/terraform.tfstate"
    region  = local.region
    profile = local.profile
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket  = lookup(local.config.global, "terraform_state_bucket", null)
    key     = "${local.env}/iam/terraform.tfstate"
    region  = local.region
    profile = local.profile
  }
}

data "terraform_remote_state" "compute" {
  backend = "s3"
  config = {
    bucket  = lookup(local.config.global, "terraform_state_bucket", null)
    key     = "${local.env}/compute/terraform.tfstate"
    region  = local.region
    profile = local.profile
  }
}

data "terraform_remote_state" "storage" {
  backend = "s3"
  config = {
    bucket  = lookup(local.config.global, "terraform_state_bucket", null)
    key     = "${local.env}/storage/terraform.tfstate"
    region  = local.region
    profile = local.profile
  }
}

locals {
  infra_vpc_id          = try(data.terraform_remote_state.vpc.outputs.vpc_id, null)
  infra_public_subnets  = try(data.terraform_remote_state.vpc.outputs.public_subnets, null)
  infra_private_subnets = try(data.terraform_remote_state.vpc.outputs.private_subnets, null)
  infra_vpc_cidr_block  = try(data.terraform_remote_state.vpc.outputs.vpc_cidr_block, null)
  infra_ecs_cluster_arn = try(data.terraform_remote_state.compute.outputs.cluster_arn, null)
}

# 8. Load Balancing (ALB)
module "alb" {
  count          = lookup(local.config.alb, "enabled", false) ? 1 : 0
  source         = "../../terraform-module/modules/alb"
  vpc_id         = local.infra_vpc_id
  public_subnets = local.infra_public_subnets
  config_file    = basename(var.config_path)
  global_config  = local.config.global
  tags           = local.tags
}

# 9. Compute (ECS Cluster - Legacy/Bridge)
# Note: Cluster is now managed in Base Compute sub-engine, but we maintain this for local overrides if needed
module "ecs_cluster" {
  count         = lookup(local.config.ecs, "enabled", false) ? 1 : 0
  source        = "../../terraform-module/modules/ecs-cluster"
  vpc_id        = local.infra_vpc_id
  config_file   = basename(var.config_path)
  global_config = local.config.global
  tags          = local.tags
}

# 10. Web Application Firewall
module "waf" {
  count         = lookup(local.config.waf, "enabled", false) ? 1 : 0
  source        = "../../terraform-module/modules/waf"
  config_file   = basename(var.config_path)
  global_config = local.config.global
  tags          = local.tags
}

# 11. Database (RDS)
module "rds" {
  count           = lookup(local.config.rds, "enabled", false) ? 1 : 0
  source          = "../../terraform-module/modules/rds"
  vpc_id          = local.infra_vpc_id
  vpc_cidr_block  = local.infra_vpc_cidr_block
  private_subnets = local.infra_private_subnets
  config_file     = basename(var.config_path)
  global_config   = local.config.global
  tags            = local.tags
}

# 12. Cache (ElastiCache)
module "elasticache" {
  count           = lookup(local.config.elasticache, "enabled", false) ? 1 : 0
  source          = "../../terraform-module/modules/elasticache"
  vpc_id          = local.infra_vpc_id
  private_subnets = local.infra_private_subnets
  config_file     = basename(var.config_path)
  global_config   = local.config.global
  tags            = local.tags
}

# 13. Application Runner (ECS Service)
module "ecs_service" {
  count           = lookup(local.config.service, "enabled", false) ? 1 : 0
  source          = "../../terraform-module/modules/ecs-service"
  vpc_id          = local.infra_vpc_id
  private_subnets = local.infra_private_subnets
  vpc_cidr_block  = local.infra_vpc_cidr_block
  cluster_arn     = local.infra_ecs_cluster_arn != null ? local.infra_ecs_cluster_arn : try(module.ecs_cluster[0].cluster_arn, null)
  listener_arn    = try(module.alb[0].http_tcp_listener_arns[0], null)
  image_tag       = var.image_tag
  config_file     = basename(var.config_path)
  global_config   = local.config.global
  tags            = local.tags
}
