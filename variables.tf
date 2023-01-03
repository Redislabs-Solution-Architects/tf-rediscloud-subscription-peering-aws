
#### Variables used in modules
##################### AWS Variables

#### Provider variables
variable "aws_creds" {
    description = "Access key and Secret key for AWS [Access Keys, Secret Key]"
}

variable "prefix_name" {
    description = "prefix to AWS resources"
    default = "redisuser"
}

#### Declare the list of subnet CIDR blocks
variable "subnet_cidr_block" {
    description = "subnet_cidr_block"
    default = "10.0.1.0/24"
}

##### Subscription Peering

variable "aws_customer_application_aws_account_id" {
    description = "aws_customer_application_aws_account_id"
}

variable "aws_customer_application_vpc_cidr" {
    description = "aws_customer_application_vpc_cidr"
    default = "10.0.0.0/16"
}

##################### Redis Cloud Variables

variable "rediscloud_creds" {
    description = "Access key and Secret key for Redis Cloud account"
}

variable "cc_type" {
    description = "credit card type"
    default = "Visa"
}

variable "cc_last_4" {
    description = "Last 4 digits for payment method"
}

##### Redis Cloud Subscription Variables

variable "rc_networking_deployment_cidr" {
    description = "the CIDR of your RedisCloud deployment"
    default = "10.1.0.0/24"
}