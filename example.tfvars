recipe_name      = "example-recipe"
recipe_version   = "1.0.0"
parent_image     = "arn:aws:imagebuilder:us-east-1:aws:image/amazon-linux-2-x86/x.x.x"
instance_types   = ["t3.medium"]
subnet_id        = "subnet-abc123"
vpc_id           = "vpc-abc123"
instance_profile = "example-instance-profile"
is_image         = true
pipeline_schedule_type = "cron"
pipeline_schedule_expression = "cron(0 0 * * ? *)"

components = {
  install-docker = {
    platform    = "Linux"
    version     = "1.0.0"
    uri         = "s3://bucket/docker-install.yaml"
    description = "Install Docker"
  }
}
