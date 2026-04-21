variable "config_path" {
  description = "Path to the service-specific config.yml file"
  type        = string
  default     = "./config.yml"
}

variable "common_config_path" {
  description = "Path to the common environment config.yml file"
  type        = string
  default     = "" # Optional
}
