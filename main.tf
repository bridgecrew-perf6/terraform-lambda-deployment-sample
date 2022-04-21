

data "aws_iam_role" "LambdaIAMRole" {
  name = var.iamRole
}

resource "aws_lambda_function" "golang_sample_lambda" {
  filename      = "code.zip"
  function_name = var.lambda_name
  role          = data.aws_iam_role.LambdaIAMRole.arn
  handler       = "code"
  description = "golang sample lambda function"
  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("code.zip")
  memory_size = 500
  runtime = "go1.x"
  timeout = 300
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.golang_sample_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.region}:${var.accountId}:${aws_api_gateway_rest_api.LambdaAccessAPI.id}/*/${aws_api_gateway_method.apiPostMethod.http_method}${aws_api_gateway_resource.e_l_a_api_v1_code_resource.path}"
}
