resource "aws_iam_role" "imagebuilder_lifecycle_policy_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "imagebuilder.${data.aws_partition.current.dns_suffix}"
      }
    }]
  })
  name = "imagebuilder_lifecycle_policy_role"
}

resource "aws_iam_role_policy_attachment" "imagebuilder_lifecycle_policy_role_attachment" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/EC2ImageBuilderLifecycleExecutionPolicy"
  role       = aws_iam_role.imagebuilder_lifecycle_policy_role.name
}

