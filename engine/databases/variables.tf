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

variable "image_tag" {
  description = "Dynamic image tag for ECS services"
  type        = string
  default     = ""
}
