terraform {
  backend "s3" {
    # Passed via -backend-config in CI pipeline
    # bucket         = "blujay-tms-tfstate"
    # key            = "blujay-tms/terraform.tfstate"
    # region         = "ap-south-1"
    # dynamodb_table = "blujay-tms-tf-lock"
    encrypt = true
  }
}
