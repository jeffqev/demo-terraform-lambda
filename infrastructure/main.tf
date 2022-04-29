terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.9.0"
    }
  }
  backend "s3" {
    bucket = "demo-tfstate-bucket-birthday"
    key    = "terraform/state/birthday_lambda.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  region     = var.REGION
  access_key = var.ACCESS_KEY
  secret_key = var.SECRET_KEY
  token      = var.TOKEN
}


data "aws_secretsmanager_secret" "secret" {
  name = "birthday_bot"
}

data "aws_secretsmanager_secret_version" "creds" {
  secret_id = data.aws_secretsmanager_secret.secret.id
}

locals {
  secret = jsondecode(
    data.aws_secretsmanager_secret_version.creds.secret_string
  )
}


module "lambda_function_container_image" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "demo-terraform-lambda-ecr"
  description   = "My awesome lambda using terraform and github actions"

  create_package = false

  environment_variables = {
    NAME = local.secret.UTC_HOUR_OFFSET
  }

  image_uri    = "873843263579.dkr.ecr.us-east-2.amazonaws.com/demo-terraform:latest"
  package_type = "Image"
}


resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "every-minute"
  description         = "At every minute"
  schedule_expression = "cron(0/1 * * * ? *)"
}


resource "aws_cloudwatch_event_target" "check_schedule" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "schedule_lambda"
  arn       = module.lambda_function_container_image.lambda_function_arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function_container_image.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}
