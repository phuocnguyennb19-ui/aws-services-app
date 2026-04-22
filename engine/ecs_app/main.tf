# ------------------------------------------------------------------------------
# ECS APPLICATION SUB-ENGINE (ALB, WAF, ECS Service)
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

data "terraform_remote_state" "compute" {
  backend = "s3"
  config = {
    bucket = lookup(local.config.global, "terraform_state_bucket", null)
    key    = "${local.env}/compute/terraform.tfstate"
    region = local.region
  }
}

locals {
  infra_vpc_id          = try(data.terraform_remote_state.vpc.outputs.vpc_id, null)
  infra_public_subnets  = try(data.terraform_remote_state.vpc.outputs.public_subnets, null)
  infra_private_subnets = try(data.terraform_remote_state.vpc.outputs.private_subnets, null)
  infra_vpc_cidr_block  = try(data.terraform_remote_state.vpc.outputs.vpc_cidr_block, null)
  infra_ecs_cluster_arn = try(data.terraform_remote_state.compute.outputs.cluster_arn, null)
}

# 1. Web Application Firewall
module "waf" {
  count         = try(local.config.waf.enabled, false) ? 1 : 0
  source        = "../../../terraform-module/modules/waf"
  config_file   = basename(var.config_path)
  global_config = local.config.global
  tags          = local.tags
}

# 2. ALB
module "alb" {
  count          = try(local.config.alb.enabled, false) ? 1 : 0
  source         = "../../../terraform-module/modules/alb"
  vpc_id         = local.infra_vpc_id
  public_subnets = local.infra_public_subnets
  config_file    = basename(var.config_path)
  global_config  = local.config.global
  tags           = local.tags
}

# 3. ECS Service
module "ecs_service" {
  count           = try(local.config.service.enabled, false) ? 1 : 0
  source          = "../../../terraform-module/modules/ecs_service"
  vpc_id          = local.infra_vpc_id
  private_subnets = local.infra_private_subnets
  vpc_cidr_block  = local.infra_vpc_cidr_block
  cluster_arn     = local.infra_ecs_cluster_arn
  listener_arn    = try(module.alb[0].http_tcp_listener_arns[0], null)
  image_tag       = var.image_tag
  config_file     = basename(var.config_path)
  global_config   = local.config.global
  tags            = local.tags
}
