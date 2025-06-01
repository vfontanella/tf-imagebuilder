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
  type = map({
    enabled      = bool
    version      = string
    description  = string
    parent_image = string
  })
}

variable container_recipes {
  type = map({
    enabled      = bool
    version      = string
    description  = string
    parent_image = string
    target_repo  = string
  })
}

variable imagebuilder_infrastructure_configuration {
  type = map(object({
    name           = string
    description    = string
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
  type = map(object{{
    enabled      = bool
    name         = string
  }))
}

variable image_distribution {
  type map(object({
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

variable is_image {
  type        = bool
  description = "select, toggle switch to build  AMI image instead"
  default     = true
}

variable "additional_tags" {
  type        = map(string)
  description = "A mapping of additional resource tags"
  default     = {}
}

