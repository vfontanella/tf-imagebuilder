
provider "aws" {
  region  = "eu-west-1"
  profile = "019415651432_PS-hwpawsrestrictedadmin"
  assume_role {
    role_arn = "arn:aws:iam::019415651432:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_PS-hwpawsrestrictedadmin_9f0753853603f105"
  }
}


module image_builder {
  source = "../../image_builder_module"
  is_image         = true
  vpc_id           = "vpc-8sff3f8sfs8t"

  image_distribution = {
    custom-image = {
      account_id = ["18293494921"]
      region     = "us-east-1"
      enabled    = true
    }
  }

  pipelines = {
    custom-image = {
      enabled      = true
      name         = "custom-image"
    }
  }

  image = {
    custom-image = {
      enabled     = true
      timeouts    = 3600
    }
  }

  image_workflows = {
    image-workflow = {
      enabled     = true
      version     = "1.0.0"
      type        = "BUILD"
      yaml_file   = "./examples/workflows/ami-image-build.yaml"
    }
  }

  container_workflows = {}

  imagebuilder_infrastructure_configuration = {
    docet-infra = {
      instance_types = ["c5.2xlarge"]
      subnet_id      = "subnet-as3jm344bc"
    }
  }

  image_recipes = {
    image-build = {
      enabled      = true
      version      = "1.0.0"
      description  = "image build recipe"
      parent_image = "ami-98sf97sdfsd98sdf"
    }
  }

  container_recipes = {}

  image_components = {
    install-docker = {
      platform    = "Windows"
      version     = "1.0.0"
      yaml_file        = "./examples/components/docker-install.yaml"
      description = "Install Docker"
    }
  }

  container_components = {}
  custom_policy_arn = ""

}

