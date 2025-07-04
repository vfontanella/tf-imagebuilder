resource "aws_imagebuilder_component" "image_component" {
  for_each = var.image_components

    name        = "${each.key}-image-component"
    platform    = each.value.platform
    version     = each.value.version
    description = each.value.description
    data        = file(each.value.yaml_file)
}

resource "aws_imagebuilder_component" "container_component" {
  for_each = var.container_components

    name        = "${each.key}-container-component"
    platform    = each.value.platform
    version     = each.value.version
    description = each.value.description
    data        = file(each.value.yaml_file)
}

resource "aws_imagebuilder_image_recipe" "image_recipe" {
  for_each = { for k in compact([for k, v in var.image_recipes: v.enabled ? k : ""]): k => var.image_recipes[k] }

  name         = each.key
  version      = each.value.version
  parent_image = each.value.parent_image
  dynamic component {
    for_each = {
      for k, v in aws_imagebuilder_component.image_component : v.arn => v
    }
    content {
        component_arn = component.value
    }
  } 
  block_device_mapping {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 100
      volume_type = "gp3"
    }
  }
}

resource "aws_imagebuilder_container_recipe" "container_recipe" {
  for_each = { for k in compact([for k, v in var.container_recipes: v.enabled ? k : ""]): k => var.container_recipes[k] }

  name         = each.key
  version      = each.value.version
  parent_image = each.value.parent_image
  dynamic component {
    for_each = {
      for k, v in aws_imagebuilder_component.container_component : v.arn => v
    }
    content {
        component_arn = component.value
    }
  }  
  container_type = "DOCKER"
  target_repository {
    service         = "ECR"
    repository_name = each.value.target_repo
  }
  dockerfile_template_data = each.value.dockerfile_template_data
}

resource "aws_security_group" "imagebuilder_security_group" {
  #checkov:skip=CKV2_AWS_5:Security Group is being attached if var create_security_group is true
    name        = "${var.imagebuilder_security_group}-sg"
    description = "Security Group for for the EC2 Image Builder Build Instances"
    vpc_id      = var.vpc_id !="" ? var.vpc_id : data.aws_vpc.selected.id

    tags =  merge(
    var.additional_tags,
    {
      OwneddBy = "DOCET"
    },
  )
}

resource "aws_security_group_rule" "sg_https_ingress" {

    type              = "ingress"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = [var.source_cidr !="" ? var.source_cidr : data.aws_vpc.selected.cidr_block]
    security_group_id = aws_security_group.imagebuilder_security_group.id
    description       = "HTTPS from VPC"
}

resource "aws_security_group_rule" "sg_rdp_ingress" {

    type              = "ingress"
    from_port         = 3389
    to_port           = 3389
    protocol          = "tcp"
    cidr_blocks       = [var.source_cidr !="" ? var.source_cidr : data.aws_vpc.selected.cidr_block]
    security_group_id = aws_security_group.imagebuilder_security_group.id
    description       = "RDP from the source variable CIDR"
}

resource "aws_security_group_rule" "sg_ssh_ingress" {

    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = [var.source_cidr !="" ? var.source_cidr : data.aws_vpc.selected.cidr_block]
    security_group_id = aws_security_group.imagebuilder_security_group.id
    description       = "RDP from the source variable CIDR"
}

#tfsec:ignore:aws-vpc-no-public-egress-sgr
resource "aws_security_group_rule" "sg_internet_egress" {

    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "all"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.imagebuilder_security_group.id
    description       = "Access to the internet"
}

resource "aws_imagebuilder_infrastructure_configuration" "imagebuilder_infrastructure_configuration" {
  for_each = { for k in compact([for k, v in var.imagebuilder_infrastructure_configuration: v.enabled ? k : ""]): k => var.imagebuilder_infrastructure_configuration[k] }
    name                          = "${each.key}-imagebuilder-infra"
    description                   = each.value.description
    instance_types                = each.value.instance_types
    subnet_id                     = each.value.subnet_id
    security_group_ids            = [aws_security_group.imagebuilder_security_group.id]
    terminate_instance_on_failure = true
    instance_profile_name         = aws_iam_instance_profile.iam_instance_profile.name
}

resource aws_imagebuilder_workflow image_workflow {
  for_each = { for k in compact([for k, v in var.image_workflows: v.enabled ? k : ""]): k => var.image_workflows[k] }

    name = each.key
    version = each.value.version
    type = each.value.type
    data = file(each.value.yaml_file)
}

resource aws_imagebuilder_workflow container_workflow {
  for_each = { for k in compact([for k, v in var.container_workflows: v.enabled ? k : ""]): k => var.container_workflows[k] }

    name = each.key
    version = each.value.version
    type = each.value.type
    data = file(each.value.yaml_file)
}

resource "aws_imagebuilder_image" "imagebuilder_image" {
  for_each = { for k in compact([for k, v in var.image: v.enabled ? k : ""]): k => var.image[k] }
    image_recipe_arn                 = aws_imagebuilder_image_recipe.image_recipe[0].arn
    infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.imagebuilder_infrastructure_configuration[0].arn
    distribution_configuration_arn   = try(aws_imagebuilder_distribution_configuration.image_distribution[0].arn, null)

    # TODO enable tests configuration
    image_tests_configuration {
      image_tests_enabled = false
    }
    tags =  merge(
    var.additional_tags,
      {
        OwnedBy = "DOCET"
      },
    )

    timeouts {
      create = each.value.timeout
    }
}

resource "aws_imagebuilder_lifecycle_policy" "imagebuilder_lifecycle_policy" {
  for_each       = var.image
  name           = "${each.key}-lifecycle-policy"
  description    = "${each.key} Imagebuilder lifecycle Policy"
  execution_role = aws_iam_role.imagebuilder_lifecycle_policy_role.arn
  resource_type  = var.is_image ? "AMI_IMAGE" : "DOCKER_IMAGE"
  policy_detail {
    action {
      type = each.value.lifecycle_policy_action_type
    }
    filter {
      type            = each.value.lifecycle_policy_filter_type
      value           = each.value.lifecycle_policy_filter_value
      retain_at_least = each.value.lifecycle_policy_filter_retain
      unit            = each.value.lifecycle_policy_filter_unit
    }
  }
    resource_selection {
      tag_map = each.value.lifecycle_policy_tags
  }
  depends_on = [aws_iam_role_policy_attachment.imagebuilder_lifecycle_policy_role_attachment]
}

resource "aws_imagebuilder_image_pipeline" "image_pipeline" {
  for_each = { for k in compact([for k, v in var.pipelines: v.enabled ? k : ""]): k => var.pipelines[k] }
  
    name                             = var.is_image ? "${each.value.name}-image-pipeline" : "${each.value.name}-container-pipeline"
    infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.imagebuilder_infrastructure_configuration["${each.key}"].arn
    image_recipe_arn                 = var.is_image ? aws_imagebuilder_image_recipe.image_recipe["${each.key}"].arn : null
    container_recipe_arn             = var.is_image ? null : aws_imagebuilder_container_recipe.container_recipe["${each.key}"].arn
    workflow {
      workflow_arn                     = var.is_image ? aws_imagebuilder_workflow.image_workflow["${each.key}"].arn : aws_imagebuilder_workflow.container_workflow["${each.key}"].arn
    }
    dynamic "schedule" {
      for_each = var.pipeline_schedule_type == "manual" ? [] : [1]
        content {
          schedule_expression = var.pipeline_schedule_expression
      }
    }
  status = "ENABLED"
}

resource aws_imagebuilder_distribution_configuration image_distribution {
  for_each = { for k in compact([for k, v in var.image_distribution: v.enabled ? k : ""]): k => var.image_distribution[k] }
  name = "${each.key}-image-distribution"

  distribution {
    ami_distribution_configuration {
      ami_tags = {
        OwnedBy = "DOCET"
      }

      name = "${each.value.name}-{{ imagebuilder:buildDate }}"

      launch_permission {
        user_ids = each.value.account_id
      }
    }

    region = each.value.region
  }
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "aws_policy" {

  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::*:role/EC2ImageBuilderDistributionCrossAccountRole"]
  }
}

resource aws_iam_role DocetEC2ImageBuilderRole {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = false
  max_session_duration = 3600
  name                 = "EC2InstanceProfileForImageBuilder"
  path                 = "/"
  tags                 =  merge(
    var.additional_tags,
    {
      OwnedBy = "DOCET"
    },
  )
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

resource "aws_iam_role_policy_attachment" "manageds3fullaccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.DocetEC2ImageBuilderRole.name
}

resource "aws_iam_role_policy_attachment" "managedssminstancecore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.DocetEC2ImageBuilderRole.name
}

resource "aws_iam_role_policy_attachment" "imagebuilder" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
  role       = aws_iam_role.DocetEC2ImageBuilderRole.name
}

resource "aws_iam_instance_profile" "iam_instance_profile" {
  name       = "EC2InstanceProfileImageBuilder"
  role       = aws_iam_role.DocetEC2ImageBuilderRole.id
}

resource "aws_iam_role_policy_attachment" "custom_policy" {
  count      = var.attach_custom_policy ? 1 : 0
  policy_arn = var.custom_policy_arn
  role       = aws_iam_role.DocetEC2ImageBuilderRole.name
}

resource "aws_iam_role_policy" "aws_policy" {
  name       = "imagebuilder-aws-access"
  role       = aws_iam_role.DocetEC2ImageBuilderRole.name
  # checkov:skip=CKV_AWS_290:The policy must allow *
  # checkov:skip=CKV_AWS_355:The policy must allow *
  policy    = data.aws_iam_policy_document.aws_policy.json
}

