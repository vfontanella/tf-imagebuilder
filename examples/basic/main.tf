module "image_builder" {
  source = "../../image_builder_module"
  for_each = toset(["default"])

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
