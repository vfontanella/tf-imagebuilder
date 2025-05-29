#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "aws_policy" {

  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::*:role/EC2ImageBuilderDistributionCrossAccountRole"]
  }

}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_imagebuilder_component" "image_component" {
  for_each = var.image_components

    name        = "${each.key}-
    platform    = each.value.platform
    version     = each.value.version
    description = each.value.description
    data        = file(each.value.yaml_path)
}

resource "aws_imagebuilder_component" "container_component" {
  for_each = var.container_components

    name        = each.key
    platform    = each.value.platform
    version     = each.value.version
    description = each.value.description
    data        = file(each.value.yaml_path)
}

resource "aws_imagebuilder_image_recipe" "image_recipe" {
  count = var.is_image ? 1 : 0

  name         = var.recipe_name
  version      = var.recipe_version
  parent_image = var.parent_image
  components   = [for k, v in aws_imagebuilder_component.image_component : { component_arn = v.arn }]
  block_device_mapping {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 100
      volume_type = "gp3"
    }
  }
}

resource "aws_imagebuilder_container_recipe" "container_recipe" {
  count = var.is_image ? 0 : 1

  name         = var.recipe_name
  version      = var.recipe_version
  parent_image = var.parent_image
  components   = [for k, v in aws_imagebuilder_component.container_component : { component_arn = v.arn }]
  container_type = "DOCKER"
  target_repository {
    service         = "ECR"
    repository_name = var.target_repo
  }
}

resource "aws_security_group" "imagebuilder_security_group" {
  for_each = { for k in compact([for k, v in var.imagebuilder_security_group: v.enabled ? k : ""]): k => var.imagebuilder_security_group[k] }

  #checkov:skip=CKV2_AWS_5:Security Group is being attached if var create_security_group is true
    name        = "${each.value.name}-sg"
    description = "Security Group for for the EC2 Image Builder Build Instances"
    vpc_id      = data.aws_vpc.selected.id

    tags = var.tags
}

resource "aws_security_group_rule" "sg_https_ingress" {
  for_each = { for k in compact([for k, v in var.imagebuilder_security_group: v.enabled ? k : ""]): k => var.imagebuilder_security_group[k] }

    type              = "ingress"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = [data.aws_vpc.selected.cidr_block]
    security_group_id = aws_security_group.imagebuilder_security_group[each.key].id
    description       = "HTTPS from VPC"
}

resource "aws_security_group_rule" "sg_rdp_ingress" {
  for_each = { for k in compact([for k, v in var.imagebuilder_security_group: v.enabled ? k : ""]): k => var.imagebuilder_security_group[k] }

    type              = "ingress"
    from_port         = 3389
    to_port           = 3389
    protocol          = "tcp"
    cidr_blocks       = var.source_cidr
    security_group_id = aws_security_group.imagebuilder_security_group[each.key].id
    description       = "RDP from the source variable CIDR"
}

resource "aws_security_group_rule" "sg_ssh_ingress" {
  for_each = { for k in compact([for k, v in var.imagebuilder_security_group: v.enabled ? k : ""]): k => var.imagebuilder_security_group[k] }

    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = var.source_cidr
    security_group_id = aws_security_group.imagebuilder_security_group[each.key].id
    description       = "RDP from the source variable CIDR"
}

#tfsec:ignore:aws-vpc-no-public-egress-sgr
resource "aws_security_group_rule" "sg_internet_egress" {
  for_each = { for k in compact([for k, v in var.imagebuilder_security_group: v.enabled ? k : ""]): k => var.imagebuilder_security_group[k] }

    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "all"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.imagebuilder_security_group[each.key].id
    description       = "Access to the internet"
}

resource "aws_imagebuilder_infrastructure_configuration" "imagebuilder_infrastructure_configuration" {
  for_each = { for k in compact([for k, v in var.imagebuilder_infrastructure_configuration: v.enabled ? k : ""]): k => var.imagebuilder_infrastructure_configuration[k] }
    name                          = "${each.key}-imagebuilder-infra"
    instance_types                = var.instance_types
    subnet_id                     = var.subnet_id
    security_group_ids            = [aws_security_group.imagebuilder_security_group[*].id]
    terminate_instance_on_failure = true
    instance_profile_name         = var.instance_profile
}

resource aws_imagebuilder_workflow image_workflow {
  for_each = { for k in compact([for k, v in var.image_workflows: v.enabled ? k : ""]): k => var.image_workflows[k] }

    name = each.key
    version = each.value.version
    type = each.value.type
    data = file(each.value.workflow_file)
}

resource aws_imagebuilder_workflow container_workflow {
  for_each = { for k in compact([for k, v in var.container_workflows: v.enabled ? k : ""]): k => var.container_workflows[k] }

    name = each.key
    version = each.value.version
    type = each.value.type
    data = file(each.value.workflow_file)
}

resource "aws_imagebuilder_image" "imagebuilder_image" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.imagebuilder_image_recipe[0].arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.imagebuilder_infrastructure_configuration[0].arn
  distribution_configuration_arn   = try(aws_imagebuilder_distribution_configuration.imagebuilder_distribution_configuration[0].arn, null)

  # TODO enable tests configuration
  image_tests_configuration {
    image_tests_enabled = false
  }
  tags = var.tags

  timeouts {
    create = var.timeout
  }
}

resource "aws_imagebuilder_image_pipeline" "image_pipeline" {
  for_each = { for k in compact([for k, v in var.pipelines: v.enabled ? k : ""]): k => var.pipelines[k] }
  
    name                             = var.is_image ? "${var.name}-image-pipeline" : "${var.name}-container-pipeline"
    infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.imagebuilder_infrastructure_configuration[0].arn
    image_recipe_arn                 = var.is_image ? aws_imagebuilder_image_recipe.image_recipe[0].arn : null
    container_recipe_arn             = var.is_image ? null : aws_imagebuilder_container_recipe.container_recipe[0].arn
    workflow_arn                     = var.is_image ? aws_imagebuilder_workflow.image_workflow[0].arn : aws_imagebuilder_workflow.container_workflow[0].arn
    dynamic "schedule" {
      for_each = var.pipeline_schedule_type == "manual" ? [] : [1]
        content {
          schedule_expression = var.pipeline_schedule_expression
      }
    }
  status = "ENABLED"
}

resource "aws_iam_role_policy_attachment" "imagebuilder" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
  role       = aws_iam_role.awsserviceroleforimagebuilder.name
}

resource "aws_iam_role_policy_attachment" "ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.awsserviceroleforimagebuilder.name
}

resource "aws_iam_instance_profile" "iam_instance_profile" {
  name = "EC2InstanceProfileImageBuilder-${var.name}"
  role = aws_iam_role.awsserviceroleforimagebuilder.name
}

resource "aws_iam_role_policy_attachment" "custom_policy" {
  count      = var.attach_custom_policy ? 1 : 0
  policy_arn = var.custom_policy_arn
  role       = aws_iam_role.awsserviceroleforimagebuilder.name
}

resource "aws_iam_role_policy" "aws_policy" {
  name = "${var.name}-aws-access"
  role = aws_iam_role.awsserviceroleforimagebuilder.id
  #checkov:skip=CKV_AWS_290:The policy must allow *
  #checkov:skip=CKV_AWS_355:The policy must allow *
  policy = data.aws_iam_policy_document.aws_policy.json
}

