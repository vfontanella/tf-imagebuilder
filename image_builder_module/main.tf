resource "aws_imagebuilder_component" "this" {
  for_each = var.components

  name        = each.key
  platform    = each.value.platform
  version     = each.value.version
  data        = each.value.data
  uri         = each.value.uri
  description = each.value.description
}

resource "aws_imagebuilder_image_recipe" "this" {
  count = var.is_image ? 1 : 0

  name         = var.recipe_name
  version      = var.recipe_version
  parent_image = var.parent_image
  components   = [for k, v in aws_imagebuilder_component.this : { component_arn = v.arn }]
  block_device_mapping {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }
}

resource "aws_imagebuilder_container_recipe" "this" {
  count = var.is_image ? 0 : 1

  name         = var.recipe_name
  version      = var.recipe_version
  parent_image = var.parent_image
  components   = [for k, v in aws_imagebuilder_component.this : { component_arn = v.arn }]
  container_type = "DOCKER"
  target_repository {
    service         = "ECR"
    repository_name = var.target_repo
  }
}

resource "aws_security_group" "image_builder_sg" {
  name        = "image-builder-sg"
  description = "Security group for EC2 Image Builder"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_imagebuilder_infrastructure_configuration" "this" {
  name                          = "image-builder-infra"
  instance_types                = var.instance_types
  subnet_id                     = var.subnet_id
  security_group_ids            = [aws_security_group.image_builder_sg.id]
  terminate_instance_on_failure = true
  instance_profile_name         = var.instance_profile
}

resource "aws_imagebuilder_image_pipeline" "this" {
  name                             = "image-builder-pipeline"
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.this.arn
  image_recipe_arn                 = var.is_image ? aws_imagebuilder_image_recipe.this[0].arn : null
  container_recipe_arn             = var.is_image ? null : aws_imagebuilder_container_recipe.this[0].arn
  dynamic "schedule" {
    for_each = var.pipeline_schedule_type == "manual" ? [] : [1]
    content {
      schedule_expression = var.pipeline_schedule_expression
    }
  }
  status = "ENABLED"
}
