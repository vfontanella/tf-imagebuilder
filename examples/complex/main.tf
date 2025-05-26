variable "environments" {
  default = ["dev", "prod"]
}

module "image_builder" {
  source = "../../image_builder_module"
  for_each = toset(var.environments)

  recipe_name      = "image-${each.key}"
  recipe_version   = "1.0.${each.key == "prod" ? "1" : "0"}"
  parent_image     = "arn:aws:imagebuilder:us-east-1:aws:image/amazon-linux-2-x86/x.x.x"
  instance_types   = ["t3.medium"]
  subnet_id        = "subnet-${each.key}"
  vpc_id           = "vpc-${each.key}"
  instance_profile = "profile-${each.key}"
  is_image         = true
  components = {
    setup-${each.key} = {
      platform    = "Linux"
      version     = "1.0.0"
      uri         = "s3://bucket/${each.key}-install.yaml"
      description = "Install ${each.key} tools"
    }
  }
  pipeline_schedule_type = "cron"
  pipeline_schedule_expression = "cron(0 10 * * ? *)"
}
