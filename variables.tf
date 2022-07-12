variable "rediscloud_creds" {
    description = "Access key and Secret key for Redis Cloud account"
}

variable "rediscloud_subscription_name" {
    description = "Name of RedisCloud subscription"
}

##### Subscription Peering

variable "rediscloud_networking_deployment_cidr" {
    description = "the CIDR of your RedisCloud deployment"
}

variable "aws_customer_application_vpc_region" {
    description = "aws_customer_application_vpc_region"
}

variable "aws_customer_application_aws_account_id" {
    description = "aws_customer_application_aws_account_id"
}

variable "aws_customer_application_vpc_id" {
    description = "aws_customer_application_vpc_id"
}

variable "aws_customer_application_vpc_cidr" {
    description = "aws_customer_application_vpc_cidr"
}

### AWS TERRAFORM PROVIDER

variable "aws_vpc_region" {
    description = "AWS region"
    default = "us-east-1"
}

variable "aws_creds" {
    description = "Access key and Secret key for AWS [Access Keys, Secret Key]"
}

variable "aws_vpc_route_table_id" {
    description = "AWS VPC Route Table Id"
}