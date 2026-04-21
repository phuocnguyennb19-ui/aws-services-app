locals {
  # Load and merge config files
  common_config  = var.common_config_path != "" ? yamldecode(file(var.common_config_path)) : {}
  service_config = yamldecode(file(var.config_path))
  config         = merge(local.common_config, local.service_config)

  # Global Context
  env     = try(local.config.global.environment, "dev")
  region  = try(local.config.global.region, "us-east-1")
  project = try(local.config.global.project, "SM-Platform")
  profile = try(local.config.global.aws_profile, "personal-dev")

  # Standard Tags
  tags = {
    Environment = local.env
    Project     = local.project
    ManagedBy   = "DylanDevOps"
    Terraform   = "true"
  }
}
