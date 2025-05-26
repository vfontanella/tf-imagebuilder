locals {
  use_image_recipe     = var.is_image
  use_container_recipe = !var.is_image
}
