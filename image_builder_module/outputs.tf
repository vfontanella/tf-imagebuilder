output "pipeline_arn" {
  value = aws_imagebuilder_image_pipeline.image_pipeline[*].arn
}
