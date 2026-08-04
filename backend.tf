terraform {
  backend "s3" {
    bucket         = "terraform-state-samir-2026"
    key            = "infra/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
