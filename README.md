# terraform-lambda-deployment-sample
Sample code for configure a lambda function with terraform

## Terraform
- **init**          Prepare your working directory for other commands
- **validate**      Check whether the configuration is valid
- **plan**          Show changes required by the current configuration
- **apply**         Create or update infrastructure
- **destroy**       Destroy previously-created infrastructure

This infra-structure will create a new lambda along with an api gateway connected.


Terraform will keep the state in an s3 bucket under a **state.tfstate** key. In order that to happen we need to set up three environment variables:

```sh
    $ export AWS_SECRET_ACCESS_KEY=...
    $ export AWS_ACCESS_KEY_ID=..
    $ export AWS_DEFAULT_REGION=...
```

Also you can configure the data inside **variables.tf**