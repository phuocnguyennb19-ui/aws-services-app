locals {
  # Load and merge config files
  common_config  = var.common_config_path != "" ? yamldecode(file(var.common_config_path)) : {}
  service_config = yamldecode(file(var.config_path))
  config         = merge(local.common_config, local.service_config)

  # 1. Global Context (Strict mapping from config.yml)
  env     = lookup(local.config.global, "environment", null)
  region  = lookup(local.config.global, "region", null)
  project = lookup(local.config.global, "project", null)
  profile = lookup(local.config.global, "aws_profile", null)

  # 2. Standard Tags
  tags = merge(
    {
      Environment = local.env
      Project     = local.project
      ManagedBy   = "DylanDevOps"
      Terraform   = "true"
    },
    lookup(local.config.global, "tags", {})
  )
}
