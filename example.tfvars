is_image = true

image_distribution {
  custom-image = {
    account_id = ["18293494921"]
    region     = "us-east-1"
    enabled    = true
  }
}

pipelines {
  custom-image = {
    enabled      = true
    name         = "custom-image"
  }
}

image {
  custom-image = {
    enabled     = true
    timeouts    = 3600
  }
}

image_workflows {
  image-workflow = {
    enabled     = true
    version     = "1.0.0"
    type        = "BUILD"
    yaml_file   = "./examples/workflows/ami-image-build.yaml"
  }
}

imagebuilder_infrastructure_configuration {
  docet-infra = {
    instance_types = ["c5.2xlarge"]
    subnet_id      = "subnet-as3jm344bc"
  }
}

image_recipes {
  image-build = {
    enabled      = true
    version      = "1.0.0"
    description  = "image build recipe"
    parent_image = "ami-98sf97sdfsd98sdf"
  }
}
components = {
  install-docker = {
    platform    = "Linux"
    version     = "1.0.0"
    yaml_file        = "./examples/components/docker-install.yaml"
    description = "Install Docker"
  }
}
