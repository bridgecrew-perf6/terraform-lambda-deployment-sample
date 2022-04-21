resource "aws_api_gateway_account" "gatewayAccount" {
  cloudwatch_role_arn = aws_iam_role.AWSGatewayAccessIAMRole.arn
}


resource "aws_iam_role" "AWSGatewayAccessIAMRole" {
  name = "AWSGatewayAccessIAMRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "AWSGatewayAccessIAMRole"
  }
}
resource "aws_iam_role_policy" "AWSGatewayAccessIAMRolePolicy" {
  name = "AWSGatewayAccessIAMRolePolicy"
  role = aws_iam_role.AWSGatewayAccessIAMRole.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
  })
}


resource "aws_api_gateway_rest_api" "LambdaAccessAPI" {
  name        = "LambdaAccessAPI"
  description = "Access apis for lambda"
}

resource "aws_api_gateway_resource" "e_l_a_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.LambdaAccessAPI.id
  parent_id   = aws_api_gateway_rest_api.LambdaAccessAPI.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "e_l_a_api_v1_resource" {
  rest_api_id = aws_api_gateway_rest_api.LambdaAccessAPI.id
  parent_id   = aws_api_gateway_resource.e_l_a_api_resource.id
  path_part   = "v1"
}

resource "aws_api_gateway_resource" "e_l_a_api_v1_code_resource" {
  rest_api_id = aws_api_gateway_rest_api.LambdaAccessAPI.id
  parent_id   = aws_api_gateway_resource.e_l_a_api_v1_resource.id
  path_part   = "golang-lambda-sample"
}


resource "aws_api_gateway_method" "apiPostMethod" {
  rest_api_id   = aws_api_gateway_rest_api.LambdaAccessAPI.id
  resource_id   = aws_api_gateway_resource.e_l_a_api_v1_code_resource.id
  http_method   = "POST"
  authorization = "NONE"
}


resource "aws_api_gateway_integration" "RequestIntegration" {
  rest_api_id          = aws_api_gateway_rest_api.LambdaAccessAPI.id
  resource_id          = aws_api_gateway_resource.e_l_a_api_v1_code_resource.id
  http_method          = aws_api_gateway_method.apiPostMethod.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.golang_sample_lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.LambdaAccessAPI.id
  resource_id = aws_api_gateway_resource.e_l_a_api_v1_code_resource.id
  http_method = aws_api_gateway_method.apiPostMethod.http_method
  status_code = "200"
  response_models = {
     "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "IntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.LambdaAccessAPI.id
  resource_id = aws_api_gateway_resource.e_l_a_api_v1_code_resource.id
  http_method = aws_api_gateway_method.apiPostMethod.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
  depends_on = [aws_api_gateway_integration.RequestIntegration]

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/json" = ""
  }

}



resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.LambdaAccessAPI.id
   triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.e_l_a_api_v1_code_resource.id,
      aws_api_gateway_method.apiPostMethod.id,
      aws_api_gateway_integration.RequestIntegration.id,
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.apiPostMethod
  ]
}

resource "aws_api_gateway_stage" "api_gateway_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.LambdaAccessAPI.id
  stage_name    = var.gateway_stage
}

resource "aws_cloudwatch_log_group" "log_group" {
  name    = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.LambdaAccessAPI.id}/${var.gateway_stage}"
}


resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.LambdaAccessAPI.id
  stage_name  = aws_api_gateway_stage.api_gateway_stage.stage_name
  method_path = "*/*"
  depends_on = [
    aws_iam_role.AWSGatewayAccessIAMRole
  ]
  settings {
    metrics_enabled = true
    logging_level   = "ERROR"
  }
}
