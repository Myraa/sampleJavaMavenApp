# ===========================================================================
# Define Statefile parameters such as s3 bucket name, dynamodb table etc. 
# Terraform uses these parameters to maintain & lock state file. 
# ===========================================================================

terraform {
  backend "s3" {
    bucket = "ntt-dcs-infra"
    key    = "terraform/integration/blue/identity/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "ntt-dcs-terraformstatelock"
  }

}
