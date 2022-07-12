terraform {
 required_providers {
   rediscloud = {
     source = "RedisLabs/rediscloud"
     version = "0.3.0" }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
 }

## RedisCloud TF PROVIDER
 # Configure the rediscloud provider:
provider "rediscloud" {
    api_key = var.rediscloud_creds[0]
    secret_key = var.rediscloud_creds[1]
}

## AWS TF PROVIDER
# AWS region and AWS key pair
provider "aws" {
  region = var.aws_vpc_region
  access_key = var.aws_creds[0]
  secret_key = var.aws_creds[1]
}
