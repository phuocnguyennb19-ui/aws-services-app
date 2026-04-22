# ------------------------------------------------------------------------------
# MESSAGING SUB-ENGINE
# ------------------------------------------------------------------------------

# 1. SQS
module "sqs" {
  count         = try(local.config.sqs.enabled, false) ? 1 : 0
  source        = "../../../terraform-module/modules/sqs"
  config_file   = basename(var.config_path)
  global_config = local.config.global
  tags          = local.tags
}

# 2. SNS
module "sns" {
  count         = try(local.config.sns.enabled, false) ? 1 : 0
  source        = "../../../terraform-module/modules/sns"
  config_file   = basename(var.config_path)
  global_config = local.config.global
  tags          = local.tags
}
