# EC2 Image Builder Terraform Module

This Terraform module provisions an AWS EC2 Image Builder pipeline using either EC2 image recipes or Docker container recipes.

## Features

- Support for EC2 AMI or Docker image pipeline
- Dynamic component inclusion
- Custom schedule for image builds
- Infrastructure setup with security group and instance profile

## Usage

### Basic Example

```hcl
module "image_builder" {
  source = "../../image_builder_module"

  recipe_name      = var.recipe_name
  recipe_version   = var.recipe_version
  parent_image     = var.parent_image
  instance_types   = var.instance_types
  subnet_id        = var.subnet_id
  vpc_id           = var.vpc_id
  instance_profile = var.instance_profile
  is_image         = var.is_image
  components       = var.components
  pipeline_schedule_type = var.pipeline_schedule_type
  pipeline_schedule_expression = var.pipeline_schedule_expression
}
```

### Variable File

```hcl
# example.tfvars
recipe_name      = "example-recipe"
recipe_version   = "1.0.0"
parent_image     = "arn:aws:imagebuilder:region:aws:image/amazon-linux-2-x86/x.x.x"
instance_types   = ["t3.medium"]
subnet_id        = "subnet-abc123"
vpc_id           = "vpc-abc123"
instance_profile = "example-instance-profile"
is_image         = true
components = {
  install-docker = {
    platform    = "Linux"
    version     = "1.0.0"
    uri         = "s3://bucket/docker-install.yaml"
    description = "Install Docker"
  }
}
```

## Inputs

See `variables.tf`.

## Outputs

- `pipeline_arn`: ARN of the image builder pipeline

## Requirements

- AWS CLI credentials configured
- Terraform >= 1.0.0

---

## License

MIT
