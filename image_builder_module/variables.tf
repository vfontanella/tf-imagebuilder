variable "image_components" {
  type = map(object({
    platform    = string
    version     = string
    description = optional(string)
    yaml_file   = optional(string)
  }))
  description = "Map of image components to include."
}

variable "container_components" {
  type = map(object({
    platform    = string
    version     = string
    description = optional(string)
    yaml_file   = optional(string)
  }))
  description = "Map of image components to include."
}

variable image_recipes {
  type = map(object({
    enabled      = bool
    version      = string
    description  = string
    parent_image = string
  }))
}

variable container_recipes {
  type = map(object({
    enabled      = bool
    version      = string
    description  = string
    parent_image = string
    target_repo  = string
  }))
}

variable imagebuilder_infrastructure_configuration {
  type = map(object({
    name           = optional(string)
    description    = optional(string)
    instance_types = list(string)
    subnet_id      = string
  }))
  description = "Map of infrastructure configuration."
}

variable image_workflows {
  type = map(object({
    enabled     = bool
    version     = string
    type        = optional(string)
    yaml_file   = optional(string)
  }))
  description = "Map of image workflows to include."
}

variable container_workflows {
  type = map(object({
    enabled     = bool
    version     = string
    type        = optional(string)
    yaml_file   = optional(string)
  }))
  description = "Map of image workflows to include."
}

variable image {
  type = map(object({
    enabled     = bool
    timeouts    = string
  }))
}

variable pipelines {
  type = map(object({
    enabled      = bool
    name         = string
  }))
}

variable image_distribution {
  type         = map(object({
    name       = optional(string)
    account_id = list(string)
    region     = string
    enabled    = bool
  }))
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

variable "is_image" {
  type        = bool
  description = "select, toggle switch to build  AMI image instead"
  default     = true
}

variable "additional_tags" {
  type        = map(string)
  description = "A mapping of additional resource tags"
  default     = {}
}

variable attach_custom_policy {
  type = bool
  description = "attach custom policy to imagebuilder role"
  default = false
}

variable custom_policy_arn {
  type = string
  description = "Image builder custom policy"
}

variable imagebuilder_security_group {
  type = string
  description = "Imagebuilder security group name"
  default = "imagebuilder"
}

variable vpc_id {
  type = string
  description = "VPC where the Imagebuilder infrastructure will be created"
}

variable source_cidr {
  type = string
  description = "CIDR to be allowed ingress into the imagebuilder instance"
  default = ""
}

