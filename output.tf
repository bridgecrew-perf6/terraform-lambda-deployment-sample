output "aws_gateway_stage" {
  value       = aws_api_gateway_stage.api_gateway_stage.invoke_url
  description = "aws gateway invoke url."
}
output "aws_api_gateway_deployment" {
  value       = aws_api_gateway_deployment.api_deployment.invoke_url
  description = "endpoint."
}