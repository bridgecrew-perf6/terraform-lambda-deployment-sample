# account id
variable "accountId" {
  type = string
  default = "$(AccountID)"
}
# region
variable "region" {
  type = string
  default = "us-east-2"
}

# iam role
variable "iamRole" {
  type = string
  default = "LambdaIAMRole"
}


variable "gateway_stage" {
  type = string
  default = "dev"
}

variable "lambda_name" {
  type = string
  default = "GolangSampleLambda"
}