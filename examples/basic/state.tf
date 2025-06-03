terraform {
  backend "s3" {
    bucket = "docet-lab-infra-terraform-state"
    key    = "imagebuilder/terraform.tfstate"
    region = "eu-west-1"
    profile = "019415651432_PS-hwpawsrestrictedadmin"
  }
}
