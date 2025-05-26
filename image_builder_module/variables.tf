variable "components" {
  type = map(object({
    platform    = string
    version     = string
    data        = optional(string)
    uri         = optional(string)
    description = optional(string)
  }))
  description = "Map of components to include."
}

variable "recipe_name" {
  type        = string
  description = "Name of the recipe"
}

variable "recipe_version" {
  type        = string
  description = "Version of the recipe"
}

variable "parent_image" {
  type        = string
  description = "Parent image to use"
}

variable "target_repo" {
  type        = string
  description = "ECR repo name for docker targets"
  default     = null
}

variable "instance_types" {
  type        = list(string)
  description = "Instance types for infra config"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for EC2"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "instance_profile" {
  type        = string
  description = "IAM Instance profile name"
}

variable "is_image" {
  type        = bool
  description = "Toggle for using EC2 image recipe. False means use Docker."
}

variable "pipeline_schedule_type" {
  type        = string
  description = "Schedule type for the pipeline: 'manual', 'cron', or 'expression'"
  default     = "manual"
}

variable "pipeline_schedule_expression" {
  type        = string
  description = "Schedule expression if using 'cron' or 'expression'"
  default     = "cron(0 0 * * ? *)"
}
