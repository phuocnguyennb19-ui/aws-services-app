# ------------------------------------------------------------------------------
# MONITORING SUB-ENGINE
# ------------------------------------------------------------------------------

# 1. CloudWatch
module "cloudwatch" {
  count         = try(local.config.cloudwatch.enabled, false) ? 1 : 0
  source        = "../../../terraform-module/modules/cloudwatch"
  config_file   = basename(var.config_path)
  global_config = local.config.global
  tags          = local.tags
}
