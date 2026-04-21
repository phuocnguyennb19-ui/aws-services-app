# ==============================================================================
# PLATFORM ENGINE - APPLICATION LAYER RESOURCES
# ==============================================================================

# 0. Load Infrastructure State
# 0. Load Foundational States
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket  = try(local.config.global.terraform_state_bucket, "sm-terraform-statefile-dev")
    key     = "${local.env}/infrastructure/vpc/terraform.tfstate"
    region  = local.region
    profile = local.profile
  }
}

data "terraform_remote_state" "ecr" {
  backend = "s3"
  config = {
    bucket  = try(local.config.global.terraform_state_bucket, "sm-terraform-statefile-dev")
    key     = "${local.env}/infrastructure/ecr/terraform.tfstate"
    region  = local.region
    profile = local.profile
  }
}

locals {
  infra_vpc_id          = try(data.terraform_remote_state.vpc.outputs.vpc_id, null)
  infra_public_subnets  = try(data.terraform_remote_state.vpc.outputs.public_subnets, null)
  infra_private_subnets = try(data.terraform_remote_state.vpc.outputs.private_subnets, null)
  infra_vpc_cidr_block  = try(data.terraform_remote_state.vpc.outputs.vpc_cidr_block, "10.0.0.0/16")
}

# 8. Load Balancing (ALB) — Wired to Infrastructure VPC
module "alb" {
  count  = try(local.config.alb.enabled, false) ? 1 : 0
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-project.git//modules/alb?ref=master"

  vpc_id         = local.infra_vpc_id
  public_subnets = local.infra_public_subnets
}

# 9. Compute (ECS Cluster) — Wired to Infrastructure VPC
module "ecs_cluster" {
  count  = try(local.config.ecs_cluster.enabled, false) ? 1 : 0
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-project.git//modules/ecs-cluster?ref=master"
  vpc_id = local.infra_vpc_id
}

# 10. Web Application Firewall
module "waf" {
  count  = try(local.config.waf.enabled, false) ? 1 : 0
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-project.git//modules/waf?ref=master"
}

# 11. Database (RDS) — Wired to Infrastructure VPC
module "rds" {
  count  = try(local.config.rds.enabled, false) ? 1 : 0
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-project.git//modules/rds?ref=master"

  vpc_id          = local.infra_vpc_id
  vpc_cidr_block  = local.infra_vpc_cidr_block
  private_subnets = local.infra_private_subnets
}

# 12. Cache (ElastiCache) — Wired to Infrastructure VPC
module "elasticache" {
  count  = try(local.config.elasticache.enabled, false) ? 1 : 0
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-project.git//modules/elasticache?ref=master"

  vpc_id          = local.infra_vpc_id
  private_subnets = local.infra_private_subnets
}

# 13. Application Runner (ECS Service) — Fully Wired
module "ecs_service" {
  count  = try(local.config.service.enabled, false) ? 1 : 0
  source = "git::https://github.com/phuocnguyennb19-ui/terraform-project.git//modules/ecs-service?ref=master"

  vpc_id          = local.infra_vpc_id
  private_subnets = local.infra_private_subnets
  vpc_cidr_block  = local.infra_vpc_cidr_block
  cluster_arn     = try(module.ecs_cluster[0].cluster_arn, null)
  listener_arn    = try(module.alb[0].http_tcp_listener_arns[0], null)
}
